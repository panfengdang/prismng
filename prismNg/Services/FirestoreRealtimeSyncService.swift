//
//  FirestoreRealtimeSyncService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Firestore Realtime Sync Service
@MainActor
class FirestoreRealtimeSyncService: ObservableObject {
    @Published var isConnected = false
    @Published var syncStatus: RealtimeSyncStatus = .disconnected
    @Published var lastSyncTime: Date?
    @Published var pendingOperations: [FirestoreSyncOperation] = []
    @Published var errorMessage: String?
    
    private let firebaseManager: FirebaseManager
    private var modelContext: ModelContext?
    private var listeners: [String: Any] = [:] // Store Firestore listeners
    private var cancellables = Set<AnyCancellable>()
    private let syncQueue = DispatchQueue(label: "firestore.sync", qos: .userInitiated)
    
    // Collection paths
    private let thoughtNodesCollection = "thoughtNodes"
    private let connectionsCollection = "connections"
    private let userConfigCollection = "userConfig"
    private let aiAnalysisCollection = "aiAnalysis"
    
    init(firebaseManager: FirebaseManager = FirebaseManager.shared) {
        self.firebaseManager = firebaseManager
        setupFirebaseObservers()
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Connection Management
    
    private func setupFirebaseObservers() {
        // Observe authentication state
        firebaseManager.$isAuthenticated
            .sink { [weak self] isAuth in
                if isAuth {
                    Task { await self?.startRealtimeSync() }
                } else {
                    Task { await self?.stopRealtimeSync() }
                }
            }
            .store(in: &cancellables)
        
        firebaseManager.$currentUser
            .sink { [weak self] user in
                if user != nil {
                    Task { await self?.startRealtimeSync() }
                }
            }
            .store(in: &cancellables)
    }
    
    func startRealtimeSync() async {
        guard firebaseManager.isAuthenticated,
              let userId = firebaseManager.currentUser?.uid,
              let modelContext = modelContext else {
            syncStatus = .error("Not authenticated or model context missing")
            return
        }
        
        syncStatus = .connecting
        
        do {
            // Start listening to all collections
            await setupRealtimeListeners(userId: userId)
            
            // Perform initial sync
            await performInitialSync(userId: userId)
            
            syncStatus = .connected
            isConnected = true
            lastSyncTime = Date()
            
        } catch {
            syncStatus = .error(error.localizedDescription)
            errorMessage = error.localizedDescription
        }
    }
    
    func stopRealtimeSync() async {
        // Remove all listeners
        for (_, listener) in listeners {
            // In real implementation, would call listener.remove()
            print("Removing listener: \(listener)")
        }
        listeners.removeAll()
        
        syncStatus = .disconnected
        isConnected = false
    }
    
    // MARK: - Realtime Listeners
    
    private func setupRealtimeListeners(userId: String) async {
        // Listen to ThoughtNodes changes
        await setupThoughtNodesListener(userId: userId)
        
        // Listen to Connections changes
        await setupConnectionsListener(userId: userId)
        
        // Listen to User Configuration changes
        await setupUserConfigListener(userId: userId)
        
        // Listen to AI Analysis results
        await setupAIAnalysisListener(userId: userId)
    }
    
    private func setupThoughtNodesListener(userId: String) async {
        // In real implementation, this would be a Firestore listener
        // For now, simulate with periodic polling
        let listener = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                await self.syncThoughtNodesFromFirestore(userId: userId)
            }
        }
        listeners["thoughtNodes"] = listener
    }
    
    private func setupConnectionsListener(userId: String) async {
        let listener = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                await self.syncConnectionsFromFirestore(userId: userId)
            }
        }
        listeners["connections"] = listener
    }
    
    private func setupUserConfigListener(userId: String) async {
        let listener = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task { @MainActor in
                await self.syncUserConfigFromFirestore(userId: userId)
            }
        }
        listeners["userConfig"] = listener
    }
    
    private func setupAIAnalysisListener(userId: String) async {
        let listener = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
            Task { @MainActor in
                await self.syncAIAnalysisFromFirestore(userId: userId)
            }
        }
        listeners["aiAnalysis"] = listener
    }
    
    // MARK: - Initial Sync
    
    private func performInitialSync(userId: String) async {
        guard let modelContext = modelContext else { return }
        
        do {
            // Upload local data to Firestore
            await uploadLocalThoughtNodes(userId: userId)
            await uploadLocalConnections(userId: userId)
            await uploadLocalUserConfig(userId: userId)
            
            // Download remote data from Firestore
            await syncThoughtNodesFromFirestore(userId: userId)
            await syncConnectionsFromFirestore(userId: userId)
            await syncUserConfigFromFirestore(userId: userId)
            
            try? modelContext.save()
            
        } catch {
            syncStatus = .error("Initial sync failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Upload to Firestore
    
    private func uploadLocalThoughtNodes(userId: String) async {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<ThoughtNode>()
            let localNodes = try modelContext.fetch(descriptor)
            
            for node in localNodes {
                let nodeDTO = ThoughtNodeDTO(from: node)
                let operation = FirestoreSyncOperation(
                    type: .upload,
                    collection: thoughtNodesCollection,
                    documentId: node.id.uuidString,
                    data: nodeDTO
                )
                await executeSyncOperation(operation, userId: userId)
            }
        } catch {
            print("Failed to upload thought nodes: \(error)")
        }
    }
    
    private func uploadLocalConnections(userId: String) async {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<NodeConnection>()
            let localConnections = try modelContext.fetch(descriptor)
            
            for connection in localConnections {
                let connectionDTO = NodeConnectionDTO(from: connection)
                let operation = FirestoreSyncOperation(
                    type: .upload,
                    collection: connectionsCollection,
                    documentId: connection.id.uuidString,
                    data: connectionDTO
                )
                await executeSyncOperation(operation, userId: userId)
            }
        } catch {
            print("Failed to upload connections: \(error)")
        }
    }
    
    private func uploadLocalUserConfig(userId: String) async {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<UserConfiguration>()
            let configs = try modelContext.fetch(descriptor)
            
            if let config = configs.first {
                let configDTO = UserConfigurationDTO(from: config)
                let operation = FirestoreSyncOperation(
                    type: .upload,
                    collection: userConfigCollection,
                    documentId: userId,
                    data: configDTO
                )
                await executeSyncOperation(operation, userId: userId)
            }
        } catch {
            print("Failed to upload user config: \(error)")
        }
    }
    
    // MARK: - Download from Firestore
    
    private func syncThoughtNodesFromFirestore(userId: String) async {
        // Simulate fetching from Firestore
        // In real implementation, this would be triggered by Firestore listeners
        
        // For MVP, we'll simulate receiving some remote changes
        if Bool.random() && modelContext != nil {
            // Simulate a remote change occasionally
            print("📥 Simulating remote ThoughtNode update")
        }
    }
    
    private func syncConnectionsFromFirestore(userId: String) async {
        // Simulate connection sync from Firestore
        if Bool.random() && modelContext != nil {
            print("📥 Simulating remote Connection update")
        }
    }
    
    private func syncUserConfigFromFirestore(userId: String) async {
        // Simulate user config sync from Firestore
        if Bool.random() && modelContext != nil {
            print("📥 Simulating remote UserConfig update")
        }
    }
    
    private func syncAIAnalysisFromFirestore(userId: String) async {
        // Simulate AI analysis results sync
        if Bool.random() && modelContext != nil {
            print("📥 Simulating remote AI Analysis update")
        }
    }
    
    // MARK: - Individual Sync Operations
    
    func syncNodeToFirestore(_ node: ThoughtNode) async {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        let nodeDTO = ThoughtNodeDTO(from: node)
        let operation = FirestoreSyncOperation(
            type: .upload,
            collection: thoughtNodesCollection,
            documentId: node.id.uuidString,
            data: nodeDTO
        )
        
        await executeSyncOperation(operation, userId: userId)
    }
    
    func syncConnectionToFirestore(_ connection: NodeConnection) async {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        let connectionDTO = NodeConnectionDTO(from: connection)
        let operation = FirestoreSyncOperation(
            type: .upload,
            collection: connectionsCollection,
            documentId: connection.id.uuidString,
            data: connectionDTO
        )
        
        await executeSyncOperation(operation, userId: userId)
    }
    
    func deleteNodeFromFirestore(_ nodeId: UUID) async {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        let operation = FirestoreSyncOperation(
            type: .delete,
            collection: thoughtNodesCollection,
            documentId: nodeId.uuidString,
            data: nil
        )
        
        await executeSyncOperation(operation, userId: userId)
    }
    
    // MARK: - Operation Execution
    
    private func executeSyncOperation(_ operation: FirestoreSyncOperation, userId: String) async {
        pendingOperations.append(operation)
        
        do {
            let collectionPath = "users/\(userId)/\(operation.collection)"
            
            switch operation.type {
            case .upload:
                if let data = operation.data {
                    _ = try await firebaseManager.saveDocument(
                        data,
                        to: collectionPath,
                        documentId: operation.documentId
                    )
                    print("✅ Uploaded \(operation.collection)/\(operation.documentId)")
                }
                
            case .delete:
                try await firebaseManager.deleteFirestoreDocument(
                    from: collectionPath,
                    documentId: operation.documentId
                )
                print("🗑️ Deleted \(operation.collection)/\(operation.documentId)")
                
            case .download:
                // Handle download operations
                break
            }
            
            // Remove completed operation
            pendingOperations.removeAll { $0.id == operation.id }
            
        } catch {
            syncStatus = .error("Sync operation failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveConflict<T: Codable>(local: T, remote: T, type: T.Type) async -> T {
        // For MVP, use last-write-wins strategy
        // In production, implement more sophisticated conflict resolution
        return remote
    }
    
    // MARK: - Manual Sync
    
    func forceSync() async {
        guard let userId = firebaseManager.currentUser?.uid else {
            syncStatus = .error("Not authenticated")
            return
        }
        
        syncStatus = .syncing
        await performInitialSync(userId: userId)
        syncStatus = .connected
        lastSyncTime = Date()
    }
    
    // MARK: - Batch Operations
    
    func batchSyncNodes(_ nodes: [ThoughtNode]) async {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        for node in nodes {
            await syncNodeToFirestore(node)
        }
    }
    
    func batchSyncConnections(_ connections: [NodeConnection]) async {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        for connection in connections {
            await syncConnectionToFirestore(connection)
        }
    }
}

// MARK: - Supporting Types

enum RealtimeSyncStatus: Equatable {
    case disconnected
    case connecting
    case connected
    case syncing
    case error(String)
    
    var displayText: String {
        switch self {
        case .disconnected:
            return "未连接"
        case .connecting:
            return "连接中..."
        case .connected:
            return "已连接"
        case .syncing:
            return "同步中..."
        case .error(let message):
            return "错误: \(message)"
        }
    }
}

struct FirestoreSyncOperation: Identifiable {
    let id = UUID()
    let type: FirestoreSyncOperationType
    let collection: String
    let documentId: String
    let data: Codable?
    let timestamp = Date()
}

enum FirestoreSyncOperationType {
    case upload
    case download
    case delete
}

// MARK: - Extensions

extension FirebaseManager {
    func deleteFirestoreDocument(from collection: String, documentId: String) async throws {
        // Simulate Firestore document deletion
        print("🗑️ Deleting document: \(collection)/\(documentId)")
        
        // In real implementation, this would call Firestore delete API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
    }
}

// MARK: - Realtime Sync Settings View

struct RealtimeSyncSettingsView: View {
    @ObservedObject var syncService: FirestoreRealtimeSyncService
    @State private var showingDetails = false
    
    var body: some View {
        Section("实时同步状态") {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(syncService.syncStatus.displayText)
                    .font(.callout)
                
                Spacer()
                
                if syncService.syncStatus == .connected {
                    Text("实时")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            if let lastSync = syncService.lastSyncTime {
                HStack {
                    Text("最后同步")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !syncService.pendingOperations.isEmpty {
                HStack {
                    Text("待同步")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(syncService.pendingOperations.count) 项")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            if let error = syncService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }
            
            // Manual sync button
            if syncService.syncStatus != .syncing && syncService.syncStatus != .connecting {
                Button {
                    Task {
                        await syncService.forceSync()
                    }
                } label: {
                    Label("立即同步", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            
            Button {
                showingDetails.toggle()
            } label: {
                Label("同步详情", systemImage: "info.circle")
            }
        }
        .sheet(isPresented: $showingDetails) {
            RealtimeSyncDetailsView(syncService: syncService)
        }
    }
    
    private var statusColor: Color {
        switch syncService.syncStatus {
        case .connected:
            return .green
        case .connecting, .syncing:
            return .orange
        case .error:
            return .red
        case .disconnected:
            return .gray
        }
    }
}

// MARK: - Sync Details View

struct RealtimeSyncDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var syncService: FirestoreRealtimeSyncService
    
    var body: some View {
        NavigationView {
            List {
                Section("同步状态") {
                    HStack {
                        Text("连接状态")
                        Spacer()
                        Text(syncService.isConnected ? "已连接" : "未连接")
                            .foregroundColor(syncService.isConnected ? .green : .red)
                    }
                    
                    if let lastSync = syncService.lastSyncTime {
                        HStack {
                            Text("最后同步时间")
                            Spacer()
                            Text(lastSync, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("待处理操作") {
                    if syncService.pendingOperations.isEmpty {
                        Text("无待处理操作")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(syncService.pendingOperations) { operation in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(operation.type) - \(operation.collection)")
                                    .font(.callout)
                                Text(operation.documentId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(operation.timestamp, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("同步控制") {
                    Button {
                        Task {
                            await syncService.forceSync()
                        }
                    } label: {
                        Label("强制同步", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Button {
                        Task {
                            await syncService.stopRealtimeSync()
                        }
                    } label: {
                        Label("停止同步", systemImage: "stop.circle")
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("同步详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}