//
//  iCloudSyncService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import CloudKit
import SwiftUI
import Combine

// MARK: - iCloud Sync Service
@MainActor
class iCloudSyncService: ObservableObject, SyncServiceProtocol {
    @Published var iCloudAvailable: Bool = false
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    
    private var container: CKContainer?
    private var privateDatabase: CKDatabase?
    private var subscriptions: Set<AnyCancellable> = []
    
    // Record types
    private let thoughtNodeRecordType = "ThoughtNode"
    private let connectionRecordType = "NodeConnection"
    
    init() {
        // Defer CloudKit initialization to avoid crashes
        setupCloudKit()
        checkiCloudAvailability()
        setupSubscriptions()
    }
    
    private func setupCloudKit() {
        // Check if running in simulator
        #if targetEnvironment(simulator)
        print("⚠️ Running in simulator - CloudKit may have limited functionality")
        #endif
        
        // Safely initialize CloudKit container
        do {
            container = CKContainer.default()
            privateDatabase = container?.privateCloudDatabase
        } catch {
            print("❌ Failed to initialize CloudKit container: \(error)")
            iCloudAvailable = false
        }
    }
    
    // MARK: - iCloud Availability
    
    private func checkiCloudAvailability() {
        guard let container = container else {
            iCloudAvailable = false
            return
        }
        
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                self?.iCloudAvailable = (status == .available)
                
                if let error = error {
                    print("iCloud account status error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Sync Operations
    
    // MARK: - SyncServiceProtocol
    var isAuthenticated: Bool { iCloudAvailable }
    
    func setup(modelContext: ModelContext) { /* no-op for iCloud */ }
    
    func syncNode(_ node: ThoughtNode) async throws {
        guard iCloudAvailable, let privateDatabase = privateDatabase else {
            throw iCloudError.notAvailable
        }
        
        let record = createRecord(from: node)
        
        do {
            _ = try await privateDatabase.save(record)
            lastSyncDate = Date()
        } catch {
            throw iCloudError.syncFailed(error.localizedDescription)
        }
    }
    
    func fetchThoughtNodes() async throws -> [ThoughtNode] {
        guard iCloudAvailable, let privateDatabase = privateDatabase else {
            throw iCloudError.notAvailable
        }
        
        let query = CKQuery(recordType: thoughtNodeRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        
        do {
            let result = try await privateDatabase.records(matching: query)
            let nodes = result.matchResults.compactMap { _, result in
                try? result.get()
            }.compactMap { record in
                createThoughtNode(from: record)
            }
            
            return nodes
        } catch {
            throw iCloudError.fetchFailed(error.localizedDescription)
        }
    }

    func startRealtimeSync() async throws { /* TODO: CloudKit subscriptions */ }
    func stopRealtimeSync() { /* TODO: cancel subscriptions */ }
    
    func deleteThoughtNode(_ nodeId: UUID) async throws {
        guard iCloudAvailable, let privateDatabase = privateDatabase else {
            throw iCloudError.notAvailable
        }
        
        let recordId = CKRecord.ID(recordName: nodeId.uuidString)
        
        do {
            _ = try await privateDatabase.deleteRecord(withID: recordId)
        } catch {
            throw iCloudError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - CloudKit Record Conversion
    
    private func createRecord(from node: ThoughtNode) -> CKRecord {
        let recordId = CKRecord.ID(recordName: node.id.uuidString)
        let record = CKRecord(recordType: thoughtNodeRecordType, recordID: recordId)
        
        record["content"] = node.content
        record["nodeType"] = node.nodeType.rawValue
        record["positionX"] = node.position.x
        record["positionY"] = node.position.y
        record["createdAt"] = node.createdAt
        record["updatedAt"] = node.updatedAt
        record["emotionalIntensity"] = node.emotionalIntensity
        record["emotionalTags"] = node.emotionalTags.map { $0.rawValue }
        record["isAIGenerated"] = node.isAIGenerated ? 1 : 0
        record["sourceNodeIds"] = node.sourceNodeIds.map { $0.uuidString }
        
        // Optional fields
        if let location = node.location {
            record["location"] = location
        }
        if let weather = node.weather {
            record["weather"] = weather
        }
        
        return record
    }
    
    private func createThoughtNode(from record: CKRecord) -> ThoughtNode? {
        guard let content = record["content"] as? String,
              let nodeTypeRaw = record["nodeType"] as? String,
              let nodeType = NodeType(rawValue: nodeTypeRaw),
              let positionX = record["positionX"] as? Double,
              let positionY = record["positionY"] as? Double,
              let createdAt = record["createdAt"] as? Date,
              let updatedAt = record["updatedAt"] as? Date else {
            return nil
        }
        
        let node = ThoughtNode(
            content: content,
            nodeType: nodeType,
            position: Position(x: positionX, y: positionY)
        )
        
        // Set additional properties
        node.createdAt = createdAt
        node.updatedAt = updatedAt
        
        if let emotionalIntensity = record["emotionalIntensity"] as? Double {
            node.emotionalIntensity = emotionalIntensity
        }
        
        if let emotionalTagsRaw = record["emotionalTags"] as? [String] {
            node.emotionalTags = emotionalTagsRaw.compactMap { EmotionalTag(rawValue: $0) }
        }
        
        if let isAIGenerated = record["isAIGenerated"] as? Int {
            node.isAIGenerated = isAIGenerated == 1
        }
        
        if let sourceNodeIdsRaw = record["sourceNodeIds"] as? [String] {
            node.sourceNodeIds = sourceNodeIdsRaw.compactMap { UUID(uuidString: $0) }
        }
        
        node.location = record["location"] as? String
        node.weather = record["weather"] as? String
        
        return node
    }
    
    // MARK: - Push Notifications / Subscriptions
    
    private func setupSubscriptions() {
        // TODO: Setup CloudKit subscriptions for real-time sync
        // This would notify the app when changes occur in iCloud
    }
}

// MARK: - iCloud Error
enum iCloudError: LocalizedError {
    case notAvailable
    case syncFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "iCloud 不可用，请检查设置"
        case .syncFailed(let message):
            return "同步失败: \(message)"
        case .fetchFailed(let message):
            return "获取数据失败: \(message)"
        case .deleteFailed(let message):
            return "删除失败: \(message)"
        }
    }
}

// MARK: - iCloud Sync Configuration View
struct iCloudSyncConfigView: View {
    @ObservedObject var syncService: iCloudSyncService
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        Section("iCloud 同步") {
            HStack {
                Label("iCloud 状态", systemImage: "icloud")
                Spacer()
                if syncService.iCloudAvailable {
                    Label("已启用", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Label("不可用", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if syncService.iCloudAvailable {
                Button {
                    Task {
                        do {
                            let nodes = try await syncService.fetchThoughtNodes()
                            alertMessage = "成功同步 \(nodes.count) 个节点"
                            showingAlert = true
                        } catch {
                            alertMessage = error.localizedDescription
                            showingAlert = true
                        }
                    }
                } label: {
                    Label("立即同步", systemImage: "arrow.triangle.2.circlepath")
                }
                
                if let lastSync = syncService.lastSyncDate {
                    LabeledContent("上次同步") {
                        Text(lastSync, style: .relative)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("请在系统设置中启用 iCloud")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .alert("同步结果", isPresented: $showingAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}
