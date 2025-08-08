//
//  FirebaseSyncService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import Combine
import SwiftData
import AuthenticationServices

// MARK: - Sync Status
enum SyncStatus: Equatable {
    case idle
    case syncing
    case error(String)
    case success
}

// MARK: - Sync Configuration
struct SyncConfiguration {
    let enableAutoSync: Bool
    let syncInterval: TimeInterval
    let conflictResolution: ConflictResolutionStrategy
    
    enum ConflictResolutionStrategy {
        case lastWriteWins
        case mergeChanges
        case askUser
    }
    
    static let `default` = SyncConfiguration(
        enableAutoSync: true,
        syncInterval: 300, // 5 minutes
        conflictResolution: .lastWriteWins
    )
}

// MARK: - Firebase Sync Service
@MainActor
class FirebaseSyncService: ObservableObject, SyncServiceProtocol {
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var pendingChanges: Int = 0
    @Published var isAuthenticated: Bool = false
    
    private var configuration = SyncConfiguration.default
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let firebaseManager = FirebaseManager.shared
    private var modelContext: ModelContext?
    
    // Mock user ID for now (will be replaced with actual Firebase Auth)
    private var userId: String? = nil
    
    init() {
        setupAutoSync()
        setupFirebaseObservers()
    }
    
    // MARK: - SyncServiceProtocol
    var isAuthenticated: Bool { isAuthenticatedBacking }
    private var isAuthenticatedBacking: Bool = false

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Firebase Integration
    
    private func setupFirebaseObservers() {
        // Observe Firebase authentication state
        firebaseManager.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                self?.isAuthenticatedBacking = isAuth
                if isAuth {
                    Task {
                        await self?.performSync()
                    }
                } else {
                    self?.handleSignOut()
                }
            }
            .store(in: &cancellables)
        
        firebaseManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.userId = user?.uid
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication
    
    func signIn(with email: String, password: String) async throws {
        syncStatus = .syncing
        do {
            _ = try await firebaseManager.signIn(withEmail: email, password: password)
            // Authentication state will be handled by observers
        } catch {
            syncStatus = .error("Authentication failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signInWithApple(authorization: ASAuthorization) async throws {
        syncStatus = .syncing
        do {
            _ = try await firebaseManager.signInWithApple(authorization: authorization)
            // Authentication state will be handled by observers
        } catch {
            syncStatus = .error("Apple Sign-In failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() async throws {
        do {
            try await firebaseManager.signOut()
            handleSignOut()
        } catch {
            syncStatus = .error("Sign out failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func handleSignOut() {
        userId = nil
        isAuthenticated = false
        syncTimer?.invalidate()
        syncTimer = nil
        syncStatus = .idle
    }
    
    // MARK: - Sync Operations
    
    func performSync() async {
        guard isAuthenticated, let userId = userId, let modelContext = modelContext else { 
            syncStatus = .error("Not ready for sync")
            return 
        }
        
        syncStatus = .syncing
        
        do {
            // Sync ThoughtNodes
            try await syncThoughtNodes(userId: userId, modelContext: modelContext)
            
            // Sync NodeConnections  
            try await syncNodeConnections(userId: userId, modelContext: modelContext)
            
            // Sync UserConfiguration
            try await syncUserConfiguration(userId: userId, modelContext: modelContext)
            
            lastSyncDate = Date()
            pendingChanges = 0
            syncStatus = .success
            
            // Reset to idle after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.syncStatus = .idle
            }
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }
    
    private func syncThoughtNodes(userId: String, modelContext: ModelContext) async throws {
        // Fetch all local nodes
        let descriptor = FetchDescriptor<ThoughtNode>()
        let localNodes = try modelContext.fetch(descriptor)
        
        // Convert to DTOs and upload each node to Firestore
        for node in localNodes {
            let nodeDTO = ThoughtNodeDTO(from: node)
            let docId = try await firebaseManager.saveDocument(
                nodeDTO, 
                to: "\(FirebaseCollections.users)/\(userId)/\(FirebaseCollections.thoughtNodes)", 
                documentId: node.id.uuidString
            )
            print("📤 Synced ThoughtNode: \(docId)")
        }
    }
    
    private func syncNodeConnections(userId: String, modelContext: ModelContext) async throws {
        // Fetch all local connections
        let descriptor = FetchDescriptor<NodeConnection>()
        let localConnections = try modelContext.fetch(descriptor)
        
        // Convert to DTOs and upload each connection to Firestore
        for connection in localConnections {
            let connectionDTO = NodeConnectionDTO(from: connection)
            let docId = try await firebaseManager.saveDocument(
                connectionDTO,
                to: "\(FirebaseCollections.users)/\(userId)/\(FirebaseCollections.connections)",
                documentId: connection.id.uuidString
            )
            print("📤 Synced NodeConnection: \(docId)")
        }
    }
    
    private func syncUserConfiguration(userId: String, modelContext: ModelContext) async throws {
        // Fetch user configuration
        let descriptor = FetchDescriptor<UserConfiguration>()
        let configs = try modelContext.fetch(descriptor)
        
        if let config = configs.first {
            let configDTO = UserConfigurationDTO(from: config)
            let docId = try await firebaseManager.saveDocument(
                configDTO,
                to: FirebaseCollections.users,
                documentId: userId
            )
            print("📤 Synced UserConfiguration: \(docId)")
        }
    }
    
    func syncNode(_ node: ThoughtNode) async throws {
        guard isAuthenticated, let userId = userId else {
            throw SyncError.notAuthenticated
        }
        
        let nodeDTO = ThoughtNodeDTO(from: node)
        _ = try await firebaseManager.saveDocument(
            nodeDTO,
            to: "\(FirebaseCollections.users)/\(userId)/\(FirebaseCollections.thoughtNodes)",
            documentId: node.id.uuidString
        )
        
        pendingChanges = max(0, pendingChanges - 1)
    }

    func fetchThoughtNodes() async throws -> [ThoughtNode] {
        guard isAuthenticated, let userId = userId else {
            throw SyncError.notAuthenticated
        }
        let nodes = try await firebaseManager.fetchDocuments(
            from: "\(FirebaseCollections.users)/\(userId)/\(FirebaseCollections.thoughtNodes)",
            as: ThoughtNodeDTO.self
        )
        return nodes.map { $0.toThoughtNode() }
    }

    func startRealtimeSync() async throws { /* TODO: attach listeners */ }
    func stopRealtimeSync() { /* TODO: detach listeners */ }
    
    func syncConnection(_ connection: NodeConnection) async throws {
        guard isAuthenticated, let userId = userId else {
            throw SyncError.notAuthenticated
        }
        
        let connectionDTO = NodeConnectionDTO(from: connection)
        _ = try await firebaseManager.saveDocument(
            connectionDTO,
            to: "\(FirebaseCollections.users)/\(userId)/\(FirebaseCollections.connections)",
            documentId: connection.id.uuidString
        )
        
        pendingChanges = max(0, pendingChanges - 1)
    }
    
    // MARK: - Auto Sync
    
    private func setupAutoSync() {
        guard configuration.enableAutoSync else { return }
        
        syncTimer = Timer.scheduledTimer(withTimeInterval: configuration.syncInterval, repeats: true) { _ in
            Task { @MainActor in
                if self.isAuthenticated && self.pendingChanges > 0 {
                    await self.performSync()
                }
            }
        }
    }
    
    // MARK: - Conflict Resolution
    
    func resolveConflict<T: Codable>(_ local: T, _ remote: T, type: T.Type) async -> T {
        switch configuration.conflictResolution {
        case .lastWriteWins:
            // Compare timestamps if available
            if let localDTO = local as? ThoughtNodeDTO,
               let remoteDTO = remote as? ThoughtNodeDTO {
                return localDTO.updatedAt > remoteDTO.updatedAt ? local : remote
            }
            return remote
            
        case .mergeChanges:
            // For now, prefer local changes
            // In production, implement proper merge logic
            return local
            
        case .askUser:
            // For now, keep local
            // In production, present UI for user to choose
            return local
        }
    }
    
    // MARK: - Download Operations
    
    func downloadRemoteData() async throws {
        guard isAuthenticated, let userId = userId, let modelContext = modelContext else {
            throw SyncError.notAuthenticated
        }
        
        syncStatus = .syncing
        
        do {
            // Download ThoughtNodes
            let remoteNodes = try await firebaseManager.fetchDocuments(
                from: "\(FirebaseCollections.users)/\(userId)/\(FirebaseCollections.thoughtNodes)",
                as: ThoughtNodeDTO.self
            )
            
            // Download NodeConnections
            let remoteConnections = try await firebaseManager.fetchDocuments(
                from: "\(FirebaseCollections.users)/\(userId)/\(FirebaseCollections.connections)",
                as: NodeConnectionDTO.self
            )
            
            // Merge with local data
            await mergeRemoteData(nodes: remoteNodes, connections: remoteConnections, modelContext: modelContext)
            
            syncStatus = .success
        } catch {
            syncStatus = .error("Download failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func mergeRemoteData(nodes: [ThoughtNodeDTO], connections: [NodeConnectionDTO], modelContext: ModelContext) async {
        // Merge nodes
        for remoteNode in nodes {
            let descriptor = FetchDescriptor<ThoughtNode>(
                predicate: #Predicate { $0.id == remoteNode.id }
            )
            
            if let existingNodes = try? modelContext.fetch(descriptor),
               let existingNode = existingNodes.first {
                // Update existing node if remote is newer
                if remoteNode.updatedAt > existingNode.updatedAt {
                    existingNode.content = remoteNode.content
                    existingNode.nodeType = remoteNode.nodeType
                    existingNode.position = remoteNode.position
                    existingNode.updatedAt = remoteNode.updatedAt
                }
            } else {
                // Create new node
                let newNode = remoteNode.toThoughtNode()
                modelContext.insert(newNode)
            }
        }
        
        // Merge connections
        for remoteConnection in connections {
            let descriptor = FetchDescriptor<NodeConnection>(
                predicate: #Predicate { $0.id == remoteConnection.id }
            )
            
            if (try? modelContext.fetch(descriptor))?.first == nil {
                // Create new connection if it doesn't exist
                let newConnection = remoteConnection.toNodeConnection()
                modelContext.insert(newConnection)
            }
        }
        
        try? modelContext.save()
    }
}

// MARK: - Sync Error
enum SyncError: LocalizedError {
    case notAuthenticated
    case networkError
    case serverError(String)
    case conflictError
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "请先登录以启用云同步"
        case .networkError:
            return "网络连接错误"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .conflictError:
            return "同步冲突"
        }
    }
}

// MARK: - Sync Status View
// SyncStatusView is now defined in Views/SyncStatusView.swift
