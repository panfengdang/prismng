//
//  PersistenceService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftData
import Foundation

@MainActor
class PersistenceService: ObservableObject {
    
    // MARK: - Node Operations
    func saveNode(_ node: ThoughtNode, in context: ModelContext) throws {
        context.insert(node)
        try context.save()
    }
    
    func updateNode(_ node: ThoughtNode, in context: ModelContext) throws {
        node.updatedAt = Date()
        try context.save()
    }
    
    func deleteNode(_ node: ThoughtNode, in context: ModelContext) throws {
        context.delete(node)
        try context.save()
    }
    
    func fetchNodes(in context: ModelContext) throws -> [ThoughtNode] {
        let descriptor = FetchDescriptor<ThoughtNode>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func fetchNode(by id: UUID, in context: ModelContext) throws -> ThoughtNode? {
        let descriptor = FetchDescriptor<ThoughtNode>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }
    
    // MARK: - Connection Operations
    func saveConnection(_ connection: NodeConnection, in context: ModelContext) throws {
        context.insert(connection)
        try context.save()
    }
    
    func fetchConnections(for nodeId: UUID, in context: ModelContext) throws -> [NodeConnection] {
        let descriptor = FetchDescriptor<NodeConnection>(
            predicate: #Predicate { connection in
                connection.fromNodeId == nodeId || connection.toNodeId == nodeId
            }
        )
        return try context.fetch(descriptor)
    }
    
    func fetchAllConnections(in context: ModelContext) throws -> [NodeConnection] {
        let descriptor = FetchDescriptor<NodeConnection>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    // MARK: - AI Task Operations
    func saveAITask(_ task: AITask, in context: ModelContext) throws {
        context.insert(task)
        try context.save()
    }
    
    func updateAITask(_ task: AITask, in context: ModelContext) throws {
        try context.save()
    }
    
    func fetchPendingAITasks(in context: ModelContext) throws -> [AITask] {
        let descriptor = FetchDescriptor<AITask>(
            predicate: #Predicate { $0.status.rawValue == "pending" },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
    
    func fetchRunningAITasks(in context: ModelContext) throws -> [AITask] {
        let descriptor = FetchDescriptor<AITask>(
            predicate: #Predicate { $0.status.rawValue == "running" },
            sortBy: [SortDescriptor(\.startedAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }
    
    // MARK: - User Configuration Operations
    func saveUserConfiguration(_ config: UserConfiguration, in context: ModelContext) throws {
        context.insert(config)
        try context.save()
    }
    
    func fetchUserConfiguration(in context: ModelContext) throws -> UserConfiguration? {
        let descriptor = FetchDescriptor<UserConfiguration>()
        return try context.fetch(descriptor).first
    }
    
    func updateUserConfiguration(_ config: UserConfiguration, in context: ModelContext) throws {
        config.updatedAt = Date()
        try context.save()
    }
    
    // MARK: - Batch Operations
    func batchDeleteNodes(ids: [UUID], in context: ModelContext) throws {
        let descriptor = FetchDescriptor<ThoughtNode>(
            predicate: #Predicate { ids.contains($0.id) }
        )
        let nodesToDelete = try context.fetch(descriptor)
        
        for node in nodesToDelete {
            context.delete(node)
        }
        
        try context.save()
    }
    
    func batchUpdateNodePositions(updates: [(UUID, Position)], in context: ModelContext) throws {
        for (nodeId, position) in updates {
            if let node = try fetchNode(by: nodeId, in: context) {
                node.position = position
                node.updatedAt = Date()
            }
        }
        try context.save()
    }
    
    // MARK: - Search Operations
    func searchNodes(content: String, in context: ModelContext) throws -> [ThoughtNode] {
        let descriptor = FetchDescriptor<ThoughtNode>(
            predicate: #Predicate { node in
                node.content.localizedStandardContains(content)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func fetchNodesByType(_ type: NodeType, in context: ModelContext) throws -> [ThoughtNode] {
        let descriptor = FetchDescriptor<ThoughtNode>(
            predicate: #Predicate { $0.nodeType.rawValue == type.rawValue },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    func fetchAIGeneratedNodes(in context: ModelContext) throws -> [ThoughtNode] {
        let descriptor = FetchDescriptor<ThoughtNode>(
            predicate: #Predicate { $0.isAIGenerated == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
    
    // MARK: - Analytics & Statistics
    func getNodeStatistics(in context: ModelContext) throws -> NodeStatistics {
        let allNodes = try fetchNodes(in: context)
        
        let totalCount = allNodes.count
        let nodeTypeCounts = Dictionary(
            grouping: allNodes,
            by: { $0.nodeType }
        ).mapValues { $0.count }
        
        let aiGeneratedCount = allNodes.filter { $0.isAIGenerated }.count
        let nodesWithEmbeddings = allNodes.filter { $0.hasEmbedding }.count
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let nodesByDate = Dictionary(
            grouping: allNodes,
            by: { dateFormatter.string(from: $0.createdAt) }
        ).mapValues { $0.count }
        
        return NodeStatistics(
            totalNodes: totalCount,
            nodeTypeDistribution: nodeTypeCounts,
            aiGeneratedNodes: aiGeneratedCount,
            nodesWithEmbeddings: nodesWithEmbeddings,
            nodesByDate: nodesByDate
        )
    }
    
    // MARK: - Data Migration & Cleanup
    func migrateFromLegacyItems(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Item>()
        let legacyItems = try context.fetch(descriptor)
        
        for item in legacyItems {
            let thoughtNode = ThoughtNode(
                content: "Migrated: \(item.timestamp)",
                nodeType: .thought,
                position: Position(x: 0, y: 0)
            )
            context.insert(thoughtNode)
            context.delete(item)
        }
        
        try context.save()
    }
    
    func cleanupOldAITasks(olderThanDays days: Int, in context: ModelContext) throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<AITask>(
            predicate: #Predicate { task in
                task.createdAt < cutoffDate && (task.status.rawValue == "success" || task.status.rawValue == "failed")
            }
        )
        
        let oldTasks = try context.fetch(descriptor)
        for task in oldTasks {
            context.delete(task)
        }
        
        try context.save()
    }
}

// MARK: - Supporting Types
struct NodeStatistics {
    let totalNodes: Int
    let nodeTypeDistribution: [NodeType: Int]
    let aiGeneratedNodes: Int
    let nodesWithEmbeddings: Int
    let nodesByDate: [String: Int]
}