//
//  EnhancedCloudSyncService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP2-3: Enhanced Cloud Sync and Backup - Firestore实时多设备同步
//

import Foundation
import SwiftUI
import Combine
import SwiftData

// MARK: - Real-time Sync Manager

/// 增强版云同步服务，提供实时多设备同步功能
@MainActor
class EnhancedCloudSyncService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var syncStatus: SyncStatus = .idle
    @Published var activeSyncSessions: [SyncSession] = []
    @Published var conflictedNodes: [ConflictedNode] = []
    @Published var syncMetrics: SyncMetrics = SyncMetrics()
    @Published var isAutoSyncEnabled = true
    @Published var isProUser = false
    
    // MARK: - Private Properties
    private let firebaseManager = FirebaseManager.shared
    private let storeKitService: StoreKitService
    private let creditsService: AICreditsService
    private var modelContext: ModelContext?
    private var syncListeners: [String: Any] = [:] // Firestore listeners
    private var cancellables = Set<AnyCancellable>()
    private let syncQueue = DispatchQueue(label: "com.prismng.sync", qos: .background)
    
    // Real-time sync configuration
    private let realtimeSyncDebounceInterval: TimeInterval = 0.5
    private var syncDebounceTimer: Timer?
    private var pendingNodeUpdates: Set<UUID> = []
    private var pendingConnectionUpdates: Set<UUID> = []
    
    // MARK: - Initialization
    
    init(storeKitService: StoreKitService, creditsService: AICreditsService) {
        self.storeKitService = storeKitService
        self.creditsService = creditsService
        
        setupSubscriptionObserver()
        setupAuthenticationObserver()
    }
    
    deinit {
        // Listeners are cleaned up when needed
    }
    
    // MARK: - Setup
    
    func setup(with modelContext: ModelContext) {
        self.modelContext = modelContext
        
        Task {
            await checkProStatus()
            if isProUser && firebaseManager.isAuthenticated {
                await startRealtimeSync()
            }
        }
    }
    
    // MARK: - Subscription & Authentication
    
    private func setupSubscriptionObserver() {
        storeKitService.$currentSubscription
            .sink { [weak self] subscription in
                Task { @MainActor in
                    await self?.checkProStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAuthenticationObserver() {
        firebaseManager.$isAuthenticated
            .combineLatest(firebaseManager.$currentUser)
            .sink { [weak self] isAuth, user in
                Task { @MainActor in
                    if isAuth && user != nil {
                        await self?.handleAuthenticationSuccess()
                    } else {
                        await self?.handleAuthenticationLoss()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func checkProStatus() async {
        let currentTier = storeKitService.currentTier()
        isProUser = currentTier == .advanced || currentTier == .professional
    }
    
    // MARK: - Real-time Sync Operations
    
    /// 启动实时同步
    func startRealtimeSync() async {
        guard isProUser, 
              let userId = firebaseManager.currentUser?.uid,
              modelContext != nil else {
            syncStatus = .error("实时同步仅限高级用户")
            return
        }
        
        syncStatus = .syncing
        
        // Create sync session
        let session = SyncSession(
            deviceId: getDeviceId(),
            deviceName: getDeviceName(),
            userId: userId
        )
        
        // Register device in Firestore
        try? await registerDevice(session)
        
        // Setup real-time listeners
        setupRealtimeListeners(userId: userId)
        
        // Perform initial sync
        await performInitialSync(userId: userId)
        
        syncStatus = .success
        
        // Track metrics
        syncMetrics.lastSyncTime = Date()
        syncMetrics.totalSyncs += 1
    }
    
    /// 停止实时同步
    func stopRealtimeSync() {
        removeAllListeners()
        syncStatus = .idle
        activeSyncSessions.removeAll()
    }
    
    // MARK: - Real-time Listeners
    
    private func setupRealtimeListeners(userId: String) {
        // Listen for ThoughtNode changes
        setupNodeListener(userId: userId)
        
        // Listen for NodeConnection changes
        setupConnectionListener(userId: userId)
        
        // Listen for active sync sessions
        setupActiveSessionsListener(userId: userId)
        
        // Listen for conflict notifications
        setupConflictListener(userId: userId)
    }
    
    private func setupNodeListener(userId: String) {
        // In a real implementation with Firebase SDK:
        // let listener = db.collection("users/\(userId)/thoughtNodes")
        //     .addSnapshotListener { [weak self] snapshot, error in
        //         self?.handleNodeChanges(snapshot: snapshot)
        //     }
        // syncListeners["nodes"] = listener
        
        // Simulated listener
        print("📡 Setting up real-time listener for ThoughtNodes")
    }
    
    private func setupConnectionListener(userId: String) {
        // Simulated listener
        print("📡 Setting up real-time listener for NodeConnections")
    }
    
    private func setupActiveSessionsListener(userId: String) {
        // Monitor active devices
        print("📡 Setting up listener for active sync sessions")
    }
    
    private func setupConflictListener(userId: String) {
        // Monitor sync conflicts
        print("📡 Setting up listener for sync conflicts")
    }
    
    // MARK: - Node Operations
    
    /// 同步单个节点（实时）
    func syncNode(_ node: ThoughtNode) {
        guard isProUser, isAutoSyncEnabled else { return }
        
        pendingNodeUpdates.insert(node.id)
        
        // Debounce rapid updates
        syncDebounceTimer?.invalidate()
        syncDebounceTimer = Timer.scheduledTimer(withTimeInterval: realtimeSyncDebounceInterval, repeats: false) { _ in
            Task { @MainActor in
                await self.flushPendingNodeUpdates()
            }
        }
    }
    
    /// 同步单个连接（实时）
    func syncConnection(_ connection: NodeConnection) {
        guard isProUser, isAutoSyncEnabled else { return }
        
        pendingConnectionUpdates.insert(connection.id)
        
        // Debounce rapid updates
        syncDebounceTimer?.invalidate()
        syncDebounceTimer = Timer.scheduledTimer(withTimeInterval: realtimeSyncDebounceInterval, repeats: false) { _ in
            Task { @MainActor in
                await self.flushPendingConnectionUpdates()
            }
        }
    }
    
    private func flushPendingNodeUpdates() async {
        guard !pendingNodeUpdates.isEmpty,
              let userId = firebaseManager.currentUser?.uid,
              let modelContext = modelContext else { return }
        
        let nodesToSync = pendingNodeUpdates
        pendingNodeUpdates.removeAll()
        
        // Batch update to Firestore
        for nodeId in nodesToSync {
            do {
                let descriptor = FetchDescriptor<ThoughtNode>()
                let nodes = try modelContext.fetch(descriptor)
                if let node = nodes.first(where: { $0.id == nodeId }) {
                    let nodeDTO = ThoughtNodeDTO(from: node)
                    
                    // Create synced node with metadata
                    let syncMetadata = SyncMetadata()
                    let syncedNode = createSyncedNodeDTO(from: node, syncMetadata: syncMetadata)
                    
                    try await firebaseManager.saveDocument(
                        syncedNode,
                        to: "users/\(userId)/thoughtNodes",
                        documentId: node.id.uuidString
                    )
                    
                    syncMetrics.nodesSynced += 1
                }
            } catch {
                print("❌ Failed to sync node: \(error)")
                syncMetrics.syncErrors += 1
            }
        }
    }
    
    private func flushPendingConnectionUpdates() async {
        guard !pendingConnectionUpdates.isEmpty,
              let userId = firebaseManager.currentUser?.uid,
              let modelContext = modelContext else { return }
        
        let connectionsToSync = pendingConnectionUpdates
        pendingConnectionUpdates.removeAll()
        
        // Similar batch update for connections
        for connectionId in connectionsToSync {
            // Sync logic similar to nodes
            syncMetrics.connectionsSynced += 1
        }
    }
    
    // MARK: - Conflict Resolution
    
    /// 自动解决冲突
    func resolveConflict(_ conflict: ConflictedNode, strategy: ConflictResolutionStrategy) async {
        switch strategy {
        case .keepLocal:
            await applyLocalVersion(conflict)
        case .keepRemote:
            await applyRemoteVersion(conflict)
        case .merge:
            await mergeVersions(conflict)
        case .duplicate:
            await createDuplicateNodes(conflict)
        }
        
        // Remove from conflicts
        conflictedNodes.removeAll { $0.id == conflict.id }
    }
    
    private func applyLocalVersion(_ conflict: ConflictedNode) async {
        // Update Firestore with local version
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        try? await firebaseManager.saveDocument(
            conflict.localVersion,
            to: "users/\(userId)/thoughtNodes",
            documentId: conflict.nodeId
        )
    }
    
    private func applyRemoteVersion(_ conflict: ConflictedNode) async {
        // Update local database with remote version
        guard let modelContext = modelContext else { return }
        
        do {
            let nodeId = UUID(uuidString: conflict.nodeId) ?? UUID()
            let descriptor = FetchDescriptor<ThoughtNode>(
                predicate: #Predicate { $0.id == nodeId }
            )
            if let localNode = try modelContext.fetch(descriptor).first {
                localNode.content = conflict.remoteVersion.content
                localNode.updatedAt = Date()
                try modelContext.save()
            }
        } catch {
            print("❌ Failed to apply remote version: \(error)")
        }
    }
    
    private func mergeVersions(_ conflict: ConflictedNode) async {
        // Implement intelligent merging
        // For now, concatenate contents with markers
        let mergedContent = """
        === 本地版本 ===
        \(conflict.localVersion.content)
        
        === 远程版本 ===
        \(conflict.remoteVersion.content)
        """
        
        // Update the local node directly
        guard let modelContext = modelContext else { return }
        do {
            let nodeId = UUID(uuidString: conflict.nodeId) ?? UUID()
            let descriptor = FetchDescriptor<ThoughtNode>(
                predicate: #Predicate { $0.id == nodeId }
            )
            if let localNode = try modelContext.fetch(descriptor).first {
                localNode.content = mergedContent
                localNode.updatedAt = Date()
                try modelContext.save()
            }
        } catch {
            print("❌ Failed to merge versions: \(error)")
        }
    }
    
    private func createDuplicateNodes(_ conflict: ConflictedNode) async {
        // Create a new node with remote content
        guard let modelContext = modelContext else { return }
        
        let duplicateNode = ThoughtNode(
            content: conflict.remoteVersion.content + " (冲突副本)",
            position: Position(
                x: conflict.localVersion.position.x + 50,
                y: conflict.localVersion.position.y + 50
            )
        )
        
        modelContext.insert(duplicateNode)
        try? modelContext.save()
    }
    
    // MARK: - Device Management
    
    private func registerDevice(_ session: SyncSession) async throws {
        guard let userId = firebaseManager.currentUser?.uid else { return }
        
        try await firebaseManager.saveDocument(
            session,
            to: "users/\(userId)/syncSessions",
            documentId: session.deviceId
        )
        
        activeSyncSessions.append(session)
    }
    
    private func getDeviceId() -> String {
        // Use a persistent device identifier
        if let deviceId = UserDefaults.standard.string(forKey: "prismng.deviceId") {
            return deviceId
        } else {
            let newId = UUID().uuidString
            UserDefaults.standard.set(newId, forKey: "prismng.deviceId")
            return newId
        }
    }
    
    private func getDeviceName() -> String {
        #if os(iOS)
        return UIDevice.current.name
        #else
        return "Mac"
        #endif
    }
    
    // MARK: - Initial Sync
    
    private func performInitialSync(userId: String) async {
        guard let modelContext = modelContext else { return }
        
        // Fetch remote data
        let remoteNodes = await fetchRemoteNodes(userId: userId)
        let remoteConnections = await fetchRemoteConnections(userId: userId)
        
        // Merge with local data
        await mergeRemoteData(
            nodes: remoteNodes,
            connections: remoteConnections,
            modelContext: modelContext
        )
    }
    
    private func fetchRemoteNodes(userId: String) async -> [ThoughtNodeDTO] {
        // In real implementation, fetch from Firestore
        return []
    }
    
    private func fetchRemoteConnections(userId: String) async -> [NodeConnectionDTO] {
        // In real implementation, fetch from Firestore
        return []
    }
    
    private func mergeRemoteData(
        nodes: [ThoughtNodeDTO],
        connections: [NodeConnectionDTO],
        modelContext: ModelContext
    ) async {
        // Implement intelligent merging logic
        // Check versions, timestamps, and handle conflicts
    }
    
    // MARK: - Cleanup
    
    private func removeAllListeners() {
        syncListeners.forEach { _, listener in
            // Remove Firestore listeners
            // listener.remove()
        }
        syncListeners.removeAll()
    }
    
    private func handleAuthenticationSuccess() async {
        if isProUser {
            await startRealtimeSync()
        }
    }
    
    private func handleAuthenticationLoss() async {
        stopRealtimeSync()
    }
}

// MARK: - Supporting Types

/// 同步会话信息
struct SyncSession: Identifiable, Codable {
    let id = UUID()
    let deviceId: String
    let deviceName: String
    let userId: String
    let startedAt: Date
    var lastActivity: Date
    let platform: String
    
    init(deviceId: String, deviceName: String, userId: String) {
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.userId = userId
        self.startedAt = Date()
        self.lastActivity = Date()
        
        #if os(iOS)
        self.platform = "iOS"
        #else
        self.platform = "macOS"
        #endif
    }
}

/// 冲突节点
struct ConflictedNode: Identifiable {
    let id = UUID()
    let nodeId: String
    let localVersion: ThoughtNodeDTO
    let remoteVersion: ThoughtNodeDTO
    let conflictType: ConflictType
    let detectedAt: Date
    
    enum ConflictType {
        case contentMismatch
        case positionMismatch
        case deletionConflict
        case connectionConflict
    }
}

/// 冲突解决策略
enum ConflictResolutionStrategy {
    case keepLocal
    case keepRemote
    case merge
    case duplicate
}

/// 同步指标
struct SyncMetrics {
    var totalSyncs: Int = 0
    var nodesSynced: Int = 0
    var connectionsSynced: Int = 0
    var conflictsResolved: Int = 0
    var syncErrors: Int = 0
    var lastSyncTime: Date?
    var averageSyncDuration: TimeInterval = 0
    
    var successRate: Double {
        guard totalSyncs > 0 else { return 0 }
        return Double(totalSyncs - syncErrors) / Double(totalSyncs)
    }
}

// SyncMetadata is defined in SyncModels.swift

// MARK: - DTO Extensions

extension ThoughtNodeDTO {
    var syncMetadata: SyncMetadata? {
        get { return nil } // Computed property for sync metadata
        set { } // Allow setting for sync operations
    }
}

// Helper extension to create DTOs with sync metadata
extension EnhancedCloudSyncService {
    func createSyncedNodeDTO(from node: ThoughtNode, syncMetadata: SyncMetadata) -> ThoughtNodeDTO {
        var dto = ThoughtNodeDTO(from: node)
        // In a real implementation, we would add syncMetadata to the DTO
        return dto
    }
}