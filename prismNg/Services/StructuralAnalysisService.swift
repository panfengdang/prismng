//
//  StructuralAnalysisService.swift
//  prismNg
//
//  Structural analysis service for thought networks
//

import Foundation
import SwiftData

// MARK: - Structural Analysis Types

struct StructuralAnalysisResult {
    let centralNode: ThoughtNode
    let clusters: [ThoughtCluster]
    let relationships: [RelationshipAnalysis]
    let insights: [String]
    let confidence: Double
    let suggestedActions: [AnalysisAction]
}

struct ThoughtCluster {
    let id = UUID()
    let name: String
    let nodes: [ThoughtNode]
    let centralTheme: String
    let coherenceScore: Double
}

struct RelationshipAnalysis {
    let fromNode: ThoughtNode
    let toNode: ThoughtNode
    let relationshipType: RelationshipType
    let strength: Double
    let explanation: String
}

enum RelationshipType: String, CaseIterable {
    case supports = "支撑"
    case contradicts = "矛盾"
    case causes = "因果"
    case similar = "相似"
    case complements = "补充"
    case questions = "质疑"
    
    var color: String {
        switch self {
        case .supports: return "green"
        case .contradicts: return "red"
        case .causes: return "orange"
        case .similar: return "purple"
        case .complements: return "blue"
        case .questions: return "yellow"
        }
    }
}

struct AnalysisAction {
    let id = UUID()
    let type: ActionType
    let description: String
    let targetNodes: [ThoughtNode]
    let priority: Priority
    
    enum ActionType {
        case createConnection
        case splitCluster
        case mergeNodes
        case addMissingContext
        case resolveContradiction
    }
    
    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
}

// MARK: - Structural Analysis Service

@MainActor
class StructuralAnalysisService: ObservableObject {
    
    @Published var isAnalyzing = false
    @Published var currentAnalysis: StructuralAnalysisResult?
    @Published var analysisHistory: [StructuralAnalysisResult] = []
    
    private let aiService: AIService
    private let embeddingService: LocalEmbeddingService
    
    init() {
        self.aiService = AIService()
        self.embeddingService = LocalEmbeddingService()
    }
    
    // MARK: - Main Analysis Function
    
    func analyzeStructure(
        centerNode: ThoughtNode,
        relatedNodes: [ThoughtNode],
        connections: [NodeConnection]
    ) async throws -> StructuralAnalysisResult {
        
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Step 1: Generate embeddings for all nodes
        let nodeEmbeddings = try await generateNodeEmbeddings(nodes: [centerNode] + relatedNodes)
        
        // Step 2: Identify clusters using similarity
        let clusters = identifyClusters(nodes: relatedNodes, embeddings: nodeEmbeddings)
        
        // Step 3: Analyze relationships
        let relationships = try await analyzeRelationships(
            centerNode: centerNode,
            nodes: relatedNodes,
            existingConnections: connections,
            embeddings: nodeEmbeddings
        )
        
        // Step 4: Generate insights
        let insights = generateInsights(
            clusters: clusters,
            relationships: relationships,
            connections: connections
        )
        
        // Step 5: Suggest actions
        let suggestedActions = generateSuggestedActions(
            centerNode: centerNode,
            clusters: clusters,
            relationships: relationships,
            existingConnections: connections
        )
        
        // Step 6: Calculate confidence
        let confidence = calculateConfidence(
            clusters: clusters,
            relationships: relationships,
            nodeCount: relatedNodes.count
        )
        
        let result = StructuralAnalysisResult(
            centralNode: centerNode,
            clusters: clusters,
            relationships: relationships,
            insights: insights,
            confidence: confidence,
            suggestedActions: suggestedActions
        )
        
        // Save to history
        analysisHistory.append(result)
        currentAnalysis = result
        
        return result
    }
    
    // MARK: - Embedding Generation
    
    private func generateNodeEmbeddings(nodes: [ThoughtNode]) async throws -> [UUID: [Float]] {
        var embeddings: [UUID: [Float]] = [:]
        
        for node in nodes {
            if let embedding = await embeddingService.generateEmbedding(for: node.content) {
                embeddings[node.id] = embedding
            }
        }
        
        return embeddings
    }
    
    // MARK: - Cluster Identification
    
    private func identifyClusters(
        nodes: [ThoughtNode],
        embeddings: [UUID: [Float]]
    ) -> [ThoughtCluster] {
        
        guard nodes.count > 2 else {
            // Too few nodes for clustering
            return [ThoughtCluster(
                name: "主要思维群",
                nodes: nodes,
                centralTheme: "核心想法",
                coherenceScore: 1.0
            )]
        }
        
        // Simple clustering based on similarity threshold
        var clusters: [ThoughtCluster] = []
        var clusteredNodes = Set<UUID>()
        let similarityThreshold: Float = 0.7
        
        for node in nodes {
            if clusteredNodes.contains(node.id) { continue }
            
            var clusterNodes = [node]
            clusteredNodes.insert(node.id)
            
            guard let nodeEmbedding = embeddings[node.id] else { continue }
            
            // Find similar nodes
            for otherNode in nodes {
                if clusteredNodes.contains(otherNode.id) { continue }
                guard let otherEmbedding = embeddings[otherNode.id] else { continue }
                
                let similarity = cosineSimilarity(nodeEmbedding, otherEmbedding)
                if similarity > similarityThreshold {
                    clusterNodes.append(otherNode)
                    clusteredNodes.insert(otherNode.id)
                }
            }
            
            // Create cluster if it has multiple nodes
            if clusterNodes.count > 1 {
                let theme = extractTheme(from: clusterNodes)
                let coherence = calculateClusterCoherence(nodes: clusterNodes, embeddings: embeddings)
                
                clusters.append(ThoughtCluster(
                    name: "群组 \(clusters.count + 1)",
                    nodes: clusterNodes,
                    centralTheme: theme,
                    coherenceScore: coherence
                ))
            }
        }
        
        // Add unclustered nodes as individual clusters
        for node in nodes {
            if !clusteredNodes.contains(node.id) {
                clusters.append(ThoughtCluster(
                    name: "独立节点",
                    nodes: [node],
                    centralTheme: String(node.content.prefix(20)),
                    coherenceScore: 1.0
                ))
            }
        }
        
        return clusters
    }
    
    // MARK: - Relationship Analysis
    
    private func analyzeRelationships(
        centerNode: ThoughtNode,
        nodes: [ThoughtNode],
        existingConnections: [NodeConnection],
        embeddings: [UUID: [Float]]
    ) async throws -> [RelationshipAnalysis] {
        
        var relationships: [RelationshipAnalysis] = []
        
        // Analyze relationship with center node
        for node in nodes {
            let relationship = analyzeNodePair(
                from: centerNode,
                to: node,
                embeddings: embeddings
            )
            relationships.append(relationship)
        }
        
        // Analyze relationships between related nodes
        for i in 0..<nodes.count {
            for j in (i+1)..<nodes.count {
                let relationship = analyzeNodePair(
                    from: nodes[i],
                    to: nodes[j],
                    embeddings: embeddings
                )
                
                // Only include strong relationships
                if relationship.strength > 0.5 {
                    relationships.append(relationship)
                }
            }
        }
        
        return relationships
    }
    
    private func analyzeNodePair(
        from: ThoughtNode,
        to: ThoughtNode,
        embeddings: [UUID: [Float]]
    ) -> RelationshipAnalysis {
        
        // Calculate similarity
        let similarity: Float
        if let fromEmb = embeddings[from.id],
           let toEmb = embeddings[to.id] {
            similarity = cosineSimilarity(fromEmb, toEmb)
        } else {
            similarity = 0.5
        }
        
        // Determine relationship type based on content analysis
        let relationshipType = determineRelationshipType(from: from, to: to, similarity: similarity)
        let explanation = generateRelationshipExplanation(
            from: from,
            to: to,
            type: relationshipType,
            similarity: similarity
        )
        
        return RelationshipAnalysis(
            fromNode: from,
            toNode: to,
            relationshipType: relationshipType,
            strength: Double(similarity),
            explanation: explanation
        )
    }
    
    private func determineRelationshipType(
        from: ThoughtNode,
        to: ThoughtNode,
        similarity: Float
    ) -> RelationshipType {
        
        // Simple heuristic-based relationship determination
        let fromWords = Set(from.content.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let toWords = Set(to.content.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        // Check for contradiction indicators
        let contradictionWords = Set(["但是", "however", "不", "not", "相反", "opposite"])
        if !fromWords.intersection(contradictionWords).isEmpty ||
           !toWords.intersection(contradictionWords).isEmpty {
            return .contradicts
        }
        
        // Check for causal indicators
        let causalWords = Set(["因为", "所以", "because", "therefore", "导致", "cause"])
        if !fromWords.intersection(causalWords).isEmpty ||
           !toWords.intersection(causalWords).isEmpty {
            return .causes
        }
        
        // Check for question indicators
        let questionWords = Set(["?", "？", "为什么", "why", "how", "什么", "what"])
        if !toWords.intersection(questionWords).isEmpty {
            return .questions
        }
        
        // Based on similarity
        if similarity > 0.8 {
            return .similar
        } else if similarity > 0.6 {
            return .complements
        } else {
            return .supports
        }
    }
    
    private func generateRelationshipExplanation(
        from: ThoughtNode,
        to: ThoughtNode,
        type: RelationshipType,
        similarity: Float
    ) -> String {
        
        switch type {
        case .supports:
            return "这个想法为另一个提供了支持和补充"
        case .contradicts:
            return "这两个想法存在潜在的矛盾或对立"
        case .causes:
            return "存在因果关系或逻辑推导"
        case .similar:
            return "高度相似的内容，相似度: \(Int(similarity * 100))%"
        case .complements:
            return "互补的观点，从不同角度描述相关主题"
        case .questions:
            return "提出了需要解答的问题"
        }
    }
    
    // MARK: - Insight Generation
    
    private func generateInsights(
        clusters: [ThoughtCluster],
        relationships: [RelationshipAnalysis],
        connections: [NodeConnection]
    ) -> [String] {
        
        var insights: [String] = []
        
        // Cluster insights
        if clusters.count > 1 {
            insights.append("发现 \(clusters.count) 个主题群组，思维呈现多样化特征")
        }
        
        let highCoherenceClusters = clusters.filter { $0.coherenceScore > 0.8 }
        if !highCoherenceClusters.isEmpty {
            insights.append("有 \(highCoherenceClusters.count) 个高度聚合的思维群组，主题明确")
        }
        
        // Relationship insights
        let contradictions = relationships.filter { $0.relationshipType == .contradicts }
        if !contradictions.isEmpty {
            insights.append("检测到 \(contradictions.count) 个潜在矛盾，需要进一步思考和澄清")
        }
        
        let strongRelationships = relationships.filter { $0.strength > 0.8 }
        if strongRelationships.count > relationships.count / 2 {
            insights.append("思维网络高度关联，整体一致性强")
        }
        
        // Connection density insight
        let possibleConnections = clusters.reduce(0) { sum, cluster in
            sum + (cluster.nodes.count * (cluster.nodes.count - 1) / 2)
        }
        if possibleConnections > 0 {
            let connectionDensity = Double(connections.count) / Double(possibleConnections)
            if connectionDensity < 0.3 {
                insights.append("连接密度较低 (\(Int(connectionDensity * 100))%)，建议探索更多关联")
            }
        }
        
        return insights
    }
    
    // MARK: - Action Suggestions
    
    private func generateSuggestedActions(
        centerNode: ThoughtNode,
        clusters: [ThoughtCluster],
        relationships: [RelationshipAnalysis],
        existingConnections: [NodeConnection]
    ) -> [AnalysisAction] {
        
        var actions: [AnalysisAction] = []
        
        // Suggest connections for strong relationships without existing connections
        for relationship in relationships where relationship.strength > 0.7 {
            let connectionExists = existingConnections.contains { conn in
                (conn.fromNodeId == relationship.fromNode.id && conn.toNodeId == relationship.toNode.id) ||
                (conn.fromNodeId == relationship.toNode.id && conn.toNodeId == relationship.fromNode.id)
            }
            
            if !connectionExists {
                actions.append(AnalysisAction(
                    type: .createConnection,
                    description: "建议连接：\(relationship.explanation)",
                    targetNodes: [relationship.fromNode, relationship.toNode],
                    priority: relationship.strength > 0.85 ? .high : .medium
                ))
            }
        }
        
        // Suggest resolving contradictions
        let contradictions = relationships.filter { $0.relationshipType == .contradicts }
        for contradiction in contradictions {
            actions.append(AnalysisAction(
                type: .resolveContradiction,
                description: "解决矛盾：需要澄清这两个想法之间的关系",
                targetNodes: [contradiction.fromNode, contradiction.toNode],
                priority: .high
            ))
        }
        
        // Suggest adding context for isolated nodes
        let isolatedClusters = clusters.filter { $0.nodes.count == 1 }
        for cluster in isolatedClusters {
            actions.append(AnalysisAction(
                type: .addMissingContext,
                description: "添加上下文：这个节点较为孤立，可以补充相关想法",
                targetNodes: cluster.nodes,
                priority: .low
            ))
        }
        
        return actions.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Helper Functions
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0 }
        
        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0
        
        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }
        
        guard normA > 0 && normB > 0 else { return 0 }
        return dotProduct / (sqrt(normA) * sqrt(normB))
    }
    
    private func extractTheme(from nodes: [ThoughtNode]) -> String {
        // Simple theme extraction based on common words
        var wordFrequency: [String: Int] = [:]
        
        for node in nodes {
            let words = node.content.lowercased()
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count > 2 }
            
            for word in words {
                wordFrequency[word, default: 0] += 1
            }
        }
        
        let topWords = wordFrequency.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        return topWords.isEmpty ? "综合主题" : topWords.joined(separator: ", ")
    }
    
    private func calculateClusterCoherence(
        nodes: [ThoughtNode],
        embeddings: [UUID: [Float]]
    ) -> Double {
        
        guard nodes.count > 1 else { return 1.0 }
        
        var totalSimilarity: Float = 0
        var pairCount = 0
        
        for i in 0..<nodes.count {
            for j in (i+1)..<nodes.count {
                if let emb1 = embeddings[nodes[i].id],
                   let emb2 = embeddings[nodes[j].id] {
                    totalSimilarity += cosineSimilarity(emb1, emb2)
                    pairCount += 1
                }
            }
        }
        
        return pairCount > 0 ? Double(totalSimilarity / Float(pairCount)) : 0.5
    }
    
    private func calculateConfidence(
        clusters: [ThoughtCluster],
        relationships: [RelationshipAnalysis],
        nodeCount: Int
    ) -> Double {
        
        // Base confidence on multiple factors
        var confidence: Double = 0.5
        
        // Factor 1: Cluster quality
        let avgCoherence = clusters.reduce(0.0) { $0 + $1.coherenceScore } / Double(clusters.count)
        confidence += avgCoherence * 0.2
        
        // Factor 2: Relationship strength
        if !relationships.isEmpty {
            let avgStrength = relationships.reduce(0.0) { $0 + $1.strength } / Double(relationships.count)
            confidence += avgStrength * 0.2
        }
        
        // Factor 3: Data sufficiency
        if nodeCount >= 5 {
            confidence += 0.1
        }
        
        return min(1.0, confidence)
    }
}

// MARK: - Visualization Support

extension StructuralAnalysisResult {
    
    func generateVisualizationData() -> VisualizationData {
        var nodes: [VisualizationNode] = []
        var edges: [VisualizationEdge] = []
        
        // Add central node
        nodes.append(VisualizationNode(
            id: centralNode.id.uuidString,
            label: String(centralNode.content.prefix(30)),
            group: "center",
            size: 30
        ))
        
        // Add cluster nodes
        for (index, cluster) in clusters.enumerated() {
            for node in cluster.nodes {
                nodes.append(VisualizationNode(
                    id: node.id.uuidString,
                    label: String(node.content.prefix(30)),
                    group: "cluster\(index)",
                    size: 20
                ))
            }
        }
        
        // Add relationship edges
        for relationship in relationships {
            edges.append(VisualizationEdge(
                from: relationship.fromNode.id.uuidString,
                to: relationship.toNode.id.uuidString,
                label: relationship.relationshipType.rawValue,
                weight: relationship.strength,
                color: relationship.relationshipType.color
            ))
        }
        
        return VisualizationData(nodes: nodes, edges: edges)
    }
}

struct VisualizationData {
    let nodes: [VisualizationNode]
    let edges: [VisualizationEdge]
}

struct VisualizationNode {
    let id: String
    let label: String
    let group: String
    let size: Int
}

struct VisualizationEdge {
    let from: String
    let to: String
    let label: String
    let weight: Double
    let color: String
}