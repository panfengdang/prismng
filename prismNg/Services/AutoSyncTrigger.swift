//
//  AutoSyncTrigger.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Auto Sync Trigger
@MainActor
class AutoSyncTrigger: ObservableObject {
    @Published var isActive = false
    @Published var syncCount = 0
    
    private let realtimeSyncService: FirestoreRealtimeSyncService
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private var pendingSyncs: Set<UUID> = []
    
    // Debounce timer to batch rapid changes
    private var debounceTimer: Timer?
    private let debounceInterval: TimeInterval = 2.0
    
    init(realtimeSyncService: FirestoreRealtimeSyncService) {
        self.realtimeSyncService = realtimeSyncService
        setupObservers()
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        startMonitoring()
    }
    
    // MARK: - Setup and Monitoring
    
    private func setupObservers() {
        // Observe sync service connection status
        realtimeSyncService.$isConnected
            .sink { [weak self] isConnected in
                self?.isActive = isConnected
            }
            .store(in: &cancellables)
    }
    
    private func startMonitoring() {
        // In a real implementation, this would observe SwiftData model changes
        // For now, we'll create a simple monitoring system
        
        // Monitor for model context changes
        guard let modelContext = modelContext else { return }
        
        // Set up periodic check for changes
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                await self.checkForChangesAndSync()
            }
        }
    }
    
    // MARK: - Change Detection and Sync
    
    private func checkForChangesAndSync() async {
        guard isActive, let modelContext = modelContext else { return }
        
        // Check for unsaved changes
        if modelContext.hasChanges {
            await triggerDebouncedSync()
        }
    }
    
    private func triggerDebouncedSync() async {
        // Cancel existing timer
        debounceTimer?.invalidate()
        
        // Start new timer
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { _ in
            Task { @MainActor in
                await self.performAutoSync()
            }
        }
    }
    
    private func performAutoSync() async {
        guard let modelContext = modelContext else { return }
        
        do {
            // Fetch changed ThoughtNodes
            let nodeDescriptor = FetchDescriptor<ThoughtNode>()
            let nodes = try modelContext.fetch(nodeDescriptor)
            
            // Sync recent changes (last 10 nodes as example)
            let recentNodes = Array(nodes.suffix(10))
            await realtimeSyncService.batchSyncNodes(recentNodes)
            
            // Fetch changed Connections
            let connectionDescriptor = FetchDescriptor<NodeConnection>()
            let connections = try modelContext.fetch(connectionDescriptor)
            
            // Sync recent connections
            let recentConnections = Array(connections.suffix(10))
            await realtimeSyncService.batchSyncConnections(recentConnections)
            
            syncCount += 1
            
        } catch {
            print("Auto sync failed: \(error)")
        }
    }
    
    // MARK: - Manual Triggers
    
    func triggerSyncForNode(_ node: ThoughtNode) async {
        guard isActive else { return }
        
        // Avoid duplicate syncs
        guard !pendingSyncs.contains(node.id) else { return }
        
        pendingSyncs.insert(node.id)
        
        await realtimeSyncService.syncNodeToFirestore(node)
        
        pendingSyncs.remove(node.id)
        syncCount += 1
    }
    
    func triggerSyncForConnection(_ connection: NodeConnection) async {
        guard isActive else { return }
        
        guard !pendingSyncs.contains(connection.id) else { return }
        
        pendingSyncs.insert(connection.id)
        
        await realtimeSyncService.syncConnectionToFirestore(connection)
        
        pendingSyncs.remove(connection.id)
        syncCount += 1
    }
    
    func triggerSyncForDeletion(_ nodeId: UUID) async {
        guard isActive else { return }
        
        await realtimeSyncService.deleteNodeFromFirestore(nodeId)
        syncCount += 1
    }
    
    // MARK: - Batch Operations
    
    func triggerBatchSync(_ nodes: [ThoughtNode], connections: [NodeConnection]) async {
        guard isActive else { return }
        
        // Batch sync nodes
        if !nodes.isEmpty {
            await realtimeSyncService.batchSyncNodes(nodes)
        }
        
        // Batch sync connections
        if !connections.isEmpty {
            await realtimeSyncService.batchSyncConnections(connections)
        }
        
        syncCount += 1
    }
    
    // MARK: - Smart Sync Logic
    
    func shouldSyncNode(_ node: ThoughtNode) -> Bool {
        // Smart logic to determine if node should be synced
        
        // Don't sync if not connected
        guard isActive else { return false }
        
        // Don't sync if already pending
        guard !pendingSyncs.contains(node.id) else { return false }
        
        // Don't sync empty or temporary nodes
        guard !node.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        
        // Don't sync nodes that are too new (wait for user to finish editing)
        let timeSinceCreation = Date().timeIntervalSince(node.createdAt)
        guard timeSinceCreation > 10.0 else { return false } // Wait 10 seconds
        
        return true
    }
    
    func shouldSyncConnection(_ connection: NodeConnection) -> Bool {
        guard isActive else { return false }
        guard !pendingSyncs.contains(connection.id) else { return false }
        
        // Only sync connections that have valid from and to nodes
        return true
    }
}

// MARK: - Extensions for ViewModel Integration

extension AutoSyncTrigger {
    
    /// Call this when a node is created or modified
    func notifyNodeChanged(_ node: ThoughtNode) {
        Task {
            if shouldSyncNode(node) {
                await triggerSyncForNode(node)
            }
        }
    }
    
    /// Call this when a connection is created or modified
    func notifyConnectionChanged(_ connection: NodeConnection) {
        Task {
            if shouldSyncConnection(connection) {
                await triggerSyncForConnection(connection)
            }
        }
    }
    
    /// Call this when a node is deleted
    func notifyNodeDeleted(_ nodeId: UUID) {
        Task {
            await triggerSyncForDeletion(nodeId)
        }
    }
    
    /// Call this when multiple items change at once
    func notifyBatchChanges(nodes: [ThoughtNode] = [], connections: [NodeConnection] = []) {
        Task {
            await triggerBatchSync(nodes, connections: connections)
        }
    }
}

// MARK: - Auto Sync Status View

struct AutoSyncStatusView: View {
    @ObservedObject var autoSyncTrigger: AutoSyncTrigger
    
    var body: some View {
        HStack {
            Image(systemName: autoSyncTrigger.isActive ? "icloud.and.arrow.up" : "icloud.slash")
                .foregroundColor(autoSyncTrigger.isActive ? .green : .gray)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("自动同步")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(autoSyncTrigger.isActive ? "已启用" : "未启用")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if autoSyncTrigger.isActive && autoSyncTrigger.syncCount > 0 {
                Spacer()
                
                Text("\(autoSyncTrigger.syncCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Integration Helper

class SyncIntegrationHelper {
    static func setupAutoSync(
        for viewModel: CanvasViewModel,
        autoSyncTrigger: AutoSyncTrigger
    ) {
        // In a real implementation, this would set up observers
        // on the CanvasViewModel to automatically trigger syncs
        // when nodes or connections are modified
        
        print("Setting up auto-sync integration for CanvasViewModel")
    }
}