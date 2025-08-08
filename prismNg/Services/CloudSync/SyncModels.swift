//
//  SyncModels.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Sync-Compatible Data Transfer Objects

// These DTOs are used for Firebase sync operations and conform to Codable
// They mirror the SwiftData models but can be serialized/deserialized

struct ThoughtNodeDTO: Codable, Identifiable {
    let id: UUID
    let content: String
    let nodeType: NodeType
    let position: Position
    let createdAt: Date
    let updatedAt: Date
    
    // AI Attribution Chain
    let sourceNodeIds: [UUID]
    let isAIGenerated: Bool
    
    // Emotional Metadata
    let emotionalTags: [EmotionalTag]
    let emotionalIntensity: Double
    
    // Context Metadata
    let location: String?
    let weather: String?
    let deviceContext: String?
    
    // Vector Search Support
    let hasEmbedding: Bool
    let embeddingVersion: String?
    
    // Visual Properties
    let color: String?
    let size: NodeSize
    let opacity: Double
    
    // Firestore metadata
    let syncVersion: Int
    let lastSynced: Date
    
    init(from thoughtNode: ThoughtNode) {
        self.id = thoughtNode.id
        self.content = thoughtNode.content
        self.nodeType = thoughtNode.nodeType
        self.position = thoughtNode.position
        self.createdAt = thoughtNode.createdAt
        self.updatedAt = thoughtNode.updatedAt
        self.sourceNodeIds = thoughtNode.sourceNodeIds
        self.isAIGenerated = thoughtNode.isAIGenerated
        self.emotionalTags = thoughtNode.emotionalTags
        self.emotionalIntensity = thoughtNode.emotionalIntensity
        self.location = thoughtNode.location
        self.weather = thoughtNode.weather
        self.deviceContext = thoughtNode.deviceContext
        self.hasEmbedding = thoughtNode.hasEmbedding
        self.embeddingVersion = thoughtNode.embeddingVersion
        self.color = thoughtNode.color
        self.size = thoughtNode.size
        self.opacity = thoughtNode.opacity
        self.syncVersion = 1
        self.lastSynced = Date()
    }
    
    func toThoughtNode() -> ThoughtNode {
        let node = ThoughtNode(
            content: content,
            nodeType: nodeType,
            position: position,
            isAIGenerated: isAIGenerated,
            sourceNodeIds: sourceNodeIds
        )
        // Note: Cannot set id directly with SwiftData @Model
        // The sync process should handle ID mapping
        return node
    }
}

struct NodeConnectionDTO: Codable, Identifiable {
    let id: UUID
    let fromNodeId: UUID
    let toNodeId: UUID
    let connectionType: ConnectionType
    let strength: Double
    let isAIGenerated: Bool
    let sourceNodeIds: [UUID]
    let createdAt: Date
    
    // Firestore metadata
    let syncVersion: Int
    let lastSynced: Date
    
    init(from connection: NodeConnection) {
        self.id = connection.id
        self.fromNodeId = connection.fromNodeId
        self.toNodeId = connection.toNodeId
        self.connectionType = connection.connectionType
        self.strength = connection.strength
        self.isAIGenerated = connection.isAIGenerated
        self.sourceNodeIds = connection.sourceNodeIds
        self.createdAt = connection.createdAt
        self.syncVersion = 1
        self.lastSynced = Date()
    }
    
    func toNodeConnection() -> NodeConnection {
        return NodeConnection(
            fromNodeId: fromNodeId,
            toNodeId: toNodeId,
            connectionType: connectionType,
            strength: strength,
            isAIGenerated: isAIGenerated,
            sourceNodeIds: sourceNodeIds
        )
    }
}

struct UserConfigurationDTO: Codable, Identifiable {
    let id: UUID
    let userId: String?
    let interactionMode: InteractionMode
    let cognitiveGear: CognitiveGear
    let aiQuotaUsed: Int
    let aiQuotaLimit: Int
    let lastQuotaReset: Date
    let subscriptionTier: SubscriptionTier
    let preferences: [String: String]
    let createdAt: Date
    let updatedAt: Date
    
    // Firestore metadata
    let syncVersion: Int
    let lastSynced: Date
    
    init(from config: UserConfiguration) {
        self.id = config.id
        self.userId = config.userId
        self.interactionMode = config.interactionMode
        self.cognitiveGear = config.cognitiveGear
        self.aiQuotaUsed = config.aiQuotaUsed
        self.aiQuotaLimit = config.aiQuotaLimit
        self.lastQuotaReset = config.lastQuotaReset
        self.subscriptionTier = config.subscriptionTier
        self.preferences = config.preferences
        self.createdAt = config.createdAt
        self.updatedAt = config.updatedAt
        self.syncVersion = 1
        self.lastSynced = Date()
    }
    
    func toUserConfiguration() -> UserConfiguration {
        let config = UserConfiguration()
        // Note: SwiftData models can't have custom initializers with all properties
        // The sync process should handle property mapping
        return config
    }
}

struct AITaskDTO: Codable, Identifiable {
    let id: UUID
    let taskType: AITaskType
    let status: TaskStatus
    let inputNodeIds: [UUID]
    let outputNodeIds: [UUID]
    let error: String?
    let createdAt: Date
    let startedAt: Date?
    let completedAt: Date?
    let metadata: [String: String]
    
    // Firestore metadata
    let syncVersion: Int
    let lastSynced: Date
    
    init(from task: AITask) {
        self.id = task.id
        self.taskType = task.taskType
        self.status = task.status
        self.inputNodeIds = task.inputNodeIds
        self.outputNodeIds = task.outputNodeIds
        self.error = task.error
        self.createdAt = task.createdAt
        self.startedAt = task.startedAt
        self.completedAt = task.completedAt
        self.metadata = task.metadata
        self.syncVersion = 1
        self.lastSynced = Date()
    }
    
    func toAITask() -> AITask {
        return AITask(taskType: taskType, inputNodeIds: inputNodeIds)
    }
}

struct EmotionalMarkerDTO: Codable, Identifiable {
    let id: UUID
    let nodeId: UUID
    let emotionalTag: EmotionalTag
    let intensity: Double
    let createdAt: Date
    let userNote: String?
    
    // Firestore metadata
    let syncVersion: Int
    let lastSynced: Date
    
    init(from marker: EmotionalMarker) {
        self.id = marker.id
        self.nodeId = marker.nodeId
        self.emotionalTag = marker.emotionalTag
        self.intensity = marker.intensity
        self.createdAt = marker.createdAt
        self.userNote = marker.userNote
        self.syncVersion = 1
        self.lastSynced = Date()
    }
    
    func toEmotionalMarker() -> EmotionalMarker {
        return EmotionalMarker(
            nodeId: nodeId,
            emotionalTag: emotionalTag,
            intensity: intensity,
            userNote: userNote
        )
    }
}

// MARK: - Sync Metadata

struct SyncMetadata: Codable {
    let lastFullSync: Date
    let lastIncrementalSync: Date
    let syncVersion: Int
    let deviceId: String
    let appVersion: String
    
    init() {
        self.lastFullSync = Date()
        self.lastIncrementalSync = Date()
        self.syncVersion = 1
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

// MARK: - Conflict Resolution

struct ConflictResolution<T: Codable> {
    let localVersion: T
    let remoteVersion: T
    let conflictType: ConflictType
    let resolution: ResolutionStrategy
    
    enum ConflictType {
        case contentChanged
        case deleted
        case moved
        case metadataChanged
    }
    
    enum ResolutionStrategy {
        case keepLocal
        case keepRemote
        case merge
        case askUser
    }
}

// MARK: - Sync Operations

enum SyncOperation: String, Codable {
    case create = "create"
    case update = "update"
    case delete = "delete"
    case move = "move"
}

struct SyncChange: Codable {
    let id: UUID
    let operation: SyncOperation
    let collection: String
    let timestamp: Date
    let data: Data? // Serialized object data
    let checksum: String
    
    init<T: Codable>(id: UUID, operation: SyncOperation, collection: String, object: T) throws {
        self.id = id
        self.operation = operation
        self.collection = collection
        self.timestamp = Date()
        self.data = try JSONEncoder().encode(object)
        self.checksum = try Self.calculateChecksum(for: object)
    }
    
    private static func calculateChecksum<T: Codable>(for object: T) throws -> String {
        let data = try JSONEncoder().encode(object)
        return data.sha256Hash
    }
}

// MARK: - Extensions

extension Data {
    var sha256Hash: String {
        // Simple hash implementation for demo
        // In production, use CryptoKit
        return "\(hashValue)"
    }
}