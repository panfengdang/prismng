//
//  Item.swift
//  prismNg
//
//  Created by suntiger on 2025/8/5.
//

import Foundation
import SwiftData

// MARK: - Core Node Model
@Model
final class ThoughtNode: Identifiable {
    @Attribute(.unique) var id: UUID
    var content: String
    var nodeType: NodeType
    var position: Position
    var createdAt: Date
    var updatedAt: Date
    
    // AI Attribution Chain - 思想归因链协议
    var sourceNodeIds: [UUID]  // AI生成节点的来源节点ID列表
    var isAIGenerated: Bool
    
    // Emotional Metadata - 情感元数据
    var emotionalTags: [EmotionalTag]
    var emotionalIntensity: Double  // 0.0 - 1.0
    
    // Context Metadata - 情景元数据
    var location: String?
    var weather: String?
    var deviceContext: String?
    
    // Vector Search Support - 向量搜索支持
    var hasEmbedding: Bool
    var embeddingVersion: String?
    
    // Visual Properties - 视觉属性
    var color: String?
    var size: NodeSize
    var opacity: Double
    
    init(content: String, 
         nodeType: NodeType = .thought,
         position: Position = Position(x: 0, y: 0),
         isAIGenerated: Bool = false,
         sourceNodeIds: [UUID] = []) {
        self.id = UUID()
        self.content = content
        self.nodeType = nodeType
        self.position = position
        self.createdAt = Date()
        self.updatedAt = Date()
        self.sourceNodeIds = sourceNodeIds
        self.isAIGenerated = isAIGenerated
        self.emotionalTags = []
        self.emotionalIntensity = 0.0
        self.hasEmbedding = false
        self.embeddingVersion = nil
        self.size = .medium
        self.opacity = 1.0
    }
}

// MARK: - Connection Model
@Model
final class NodeConnection {
    @Attribute(.unique) var id: UUID 
    var fromNodeId: UUID
    var toNodeId: UUID
    var connectionType: ConnectionType
    var strength: Double  // 0.0 - 1.0 连接强度
    var isAIGenerated: Bool
    var sourceNodeIds: [UUID]  // AI生成连接的来源
    var createdAt: Date
    
    init(fromNodeId: UUID, 
         toNodeId: UUID, 
         connectionType: ConnectionType,
         strength: Double = 0.5,
         isAIGenerated: Bool = false,
         sourceNodeIds: [UUID] = []) {
        self.id = UUID()
        self.fromNodeId = fromNodeId
        self.toNodeId = toNodeId
        self.connectionType = connectionType
        self.strength = strength
        self.isAIGenerated = isAIGenerated
        self.sourceNodeIds = sourceNodeIds
        self.createdAt = Date()
    }
}

// MARK: - AI Task Model
@Model
final class AITask {
    @Attribute(.unique) var id: UUID
    var taskType: AITaskType
    var status: TaskStatus
    var inputNodeIds: [UUID]
    var outputNodeIds: [UUID]
    var error: String?
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var metadata: [String: String]
    
    init(taskType: AITaskType, inputNodeIds: [UUID] = []) {
        self.id = UUID()
        self.taskType = taskType
        self.status = .pending
        self.inputNodeIds = inputNodeIds
        self.outputNodeIds = []
        self.createdAt = Date()
        self.metadata = [:]
    }
}

// MARK: - User Configuration Model
@Model
final class UserConfiguration {
    @Attribute(.unique) var id: UUID
    var userId: String?  // Firebase User ID
    var interactionMode: InteractionMode
    var cognitiveGear: CognitiveGear
    var aiQuotaUsed: Int
    var aiQuotaLimit: Int
    var lastQuotaReset: Date
    var subscriptionTier: SubscriptionTier
    var preferences: [String: String]
    var createdAt: Date
    var updatedAt: Date
    
    init() {
        self.id = UUID()
        self.interactionMode = .traditional
        self.cognitiveGear = .capture
        self.aiQuotaUsed = 0
        self.aiQuotaLimit = 2  // 免费层每日2次
        self.lastQuotaReset = Date()
        self.subscriptionTier = .free
        self.preferences = [:]
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Supporting Enums and Structs

enum NodeType: String, Codable, CaseIterable {
    case thought = "thought"           // 普通思想节点
    case insight = "insight"          // 顿悟节点  
    case question = "question"        // 问题节点
    case conclusion = "conclusion"    // AI生成的结论节点
    case contradiction = "contradiction" // AI发现的矛盾点
    case structure = "structure"      // 结构化分析节点
    
    var displayName: String {
        switch self {
        case .thought: return "思想"
        case .insight: return "洞见"
        case .question: return "问题"
        case .conclusion: return "结论"
        case .contradiction: return "矛盾"
        case .structure: return "结构"
        }
    }
}

enum ConnectionType: String, Codable, CaseIterable {
    case strongSupport = "strongSupport"     // 强支撑
    case weakAssociation = "weakAssociation" // 弱关联
    case contradiction = "contradiction"      // 矛盾
    case causality = "causality"             // 因果关系
    case similarity = "similarity"           // 相似性
    case resonance = "resonance"             // 共鸣瞬现
}

enum EmotionalTag: String, Codable, CaseIterable {
    case excited = "excited"       // 激动
    case calm = "calm"            // 平静
    case confused = "confused"    // 困惑
    case inspired = "inspired"    // 受启发
    case frustrated = "frustrated" // 沮丧
    case curious = "curious"      // 好奇
    case confident = "confident"  // 自信
    case uncertain = "uncertain"  // 不确定
}

enum NodeSize: String, Codable, CaseIterable {
    case small = "small"
    case medium = "medium" 
    case large = "large"
}

enum InteractionMode: String, Codable, CaseIterable {
    case traditional = "traditional"  // 传统UI轨道
    case gesture = "gesture"         // 手势驱动轨道
    case adaptive = "adaptive"       // 自适应切换
}

// CognitiveGear is defined in CognitiveGearService.swift

enum AITaskType: String, Codable, CaseIterable {
    case generateEmbedding = "generateEmbedding"
    case findAssociations = "findAssociations"
    case structureAnalysis = "structureAnalysis"
    case identitySimulation = "identitySimulation"
    case evolutionSummary = "evolutionSummary"
    case incubation = "incubation"
    case forgettingScore = "forgettingScore"
}

enum TaskStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case running = "running"
    case success = "success"
    case failed = "failed"
}

enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"           // 永久免费层
    case explorer = "explorer"   // 探索层 $2.99
    case advanced = "advanced"   // 进阶层 $14.99
    case professional = "professional" // 专业层 $49.99
}

struct Position: Codable {
    var x: Double
    var y: Double
    
    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

// MARK: - Emotional Marker Model
@Model
final class EmotionalMarker {
    @Attribute(.unique) var id: UUID
    var nodeId: UUID
    var emotionalTag: EmotionalTag
    var intensity: Double
    var createdAt: Date
    var userNote: String?
    
    init(nodeId: UUID, emotionalTag: EmotionalTag, intensity: Double = 0.5, userNote: String? = nil) {
        self.id = UUID()
        self.nodeId = nodeId
        self.emotionalTag = emotionalTag
        self.intensity = intensity
        self.createdAt = Date()
        self.userNote = userNote
    }
}

// Legacy Item class for migration compatibility
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
