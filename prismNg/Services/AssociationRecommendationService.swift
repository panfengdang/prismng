//
//  AssociationRecommendationService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftData

// MARK: - Association Recommendation Service
@MainActor
class AssociationRecommendationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var recommendedAssociations: [AssociationRecommendation] = []
    @Published var isAnalyzing: Bool = false
    
    // MARK: - Private Properties
    private let vectorService = VectorDBService()
    private let aiService = AIService()
    private var modelContext: ModelContext?
    
    // Thresholds for different types of associations
    private let strongAssociationThreshold: Float = 0.8
    private let moderateAssociationThreshold: Float = 0.6
    private let weakAssociationThreshold: Float = 0.4
    
    // MARK: - Setup
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Main Recommendation Methods
    
    /// Analyzes a selected node and provides real-time association recommendations
    func analyzeNodeAssociations(for node: ThoughtNode, in allNodes: [ThoughtNode]) async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        do {
            // Generate embedding for the current node if it doesn't exist
            if !node.hasEmbedding {
                try await generateEmbeddingForNode(node)
            }
            
            // Find similar nodes using vector search
            let similarNodes = try await findSimilarNodes(to: node, in: allNodes)
            
            // Analyze contextual relationships
            let contextualAssociations = await analyzeContextualRelationships(for: node, in: allNodes)
            
            // Analyze temporal relationships
            let temporalAssociations = await analyzeTemporalRelationships(for: node, in: allNodes)
            
            // Analyze emotional relationships
            let emotionalAssociations = await analyzeEmotionalRelationships(for: node, in: allNodes)
            
            // Combine and rank all recommendations
            let allRecommendations = combinedRecommendations([
                similarNodes,
                contextualAssociations,
                temporalAssociations,
                emotionalAssociations
            ])
            
            // Update published recommendations
            recommendedAssociations = allRecommendations
            
        } catch {
            print("Error analyzing associations: \(error)")
            recommendedAssociations = []
        }
    }
    
    /// Clears current recommendations
    func clearRecommendations() {
        recommendedAssociations = []
    }
    
    /// Accept a recommendation (user action)
    func acceptRecommendation(_ recommendation: AssociationRecommendation) {
        // Remove from recommendations
        recommendedAssociations.removeAll { $0.id == recommendation.id }
        
        // TODO: Track user feedback for learning
        print("User accepted recommendation: \(recommendation.reasoning)")
    }
    
    /// Reject a recommendation (user action)
    func rejectRecommendation(_ recommendation: AssociationRecommendation) {
        // Remove from recommendations
        recommendedAssociations.removeAll { $0.id == recommendation.id }
        
        // TODO: Track user feedback for learning
        print("User rejected recommendation: \(recommendation.reasoning)")
    }
    
    /// Compatibility property for other components
    var recommendations: [AssociationRecommendation] {
        return recommendedAssociations
    }
    
    // MARK: - Vector-based Association Analysis
    
    private func findSimilarNodes(to targetNode: ThoughtNode, in allNodes: [ThoughtNode]) async throws -> [AssociationRecommendation] {
        let similarNodeIds = try await vectorService.findSimilar(to: targetNode.id, limit: 10)
        
        var recommendations: [AssociationRecommendation] = []
        
        for nodeId in similarNodeIds {
            guard let node = allNodes.first(where: { $0.id == nodeId }) else { continue }
            
            // Get similarity score
            let results = try await vectorService.findSimilarByVector(
                await getNodeEmbedding(targetNode), 
                limit: allNodes.count
            )
            
            if let result = results.first(where: { $0.nodeId == nodeId }) {
                let associationType = classifyAssociationType(similarity: result.similarity)
                let recommendation = AssociationRecommendation(
                    id: UUID(),
                    targetNodeId: targetNode.id,
                    associatedNodeId: nodeId,
                    associationType: associationType,
                    confidence: result.similarity,
                    reasoning: generateSemanticReasoning(similarity: result.similarity),
                    recommendationType: .semantic
                )
                recommendations.append(recommendation)
            }
        }
        
        return recommendations
    }
    
    // MARK: - Contextual Analysis
    
    private func analyzeContextualRelationships(for node: ThoughtNode, in allNodes: [ThoughtNode]) async -> [AssociationRecommendation] {
        var recommendations: [AssociationRecommendation] = []
        
        // Location-based associations
        if let nodeLocation = node.location {
            let locationMatches = allNodes.filter { otherNode in
                otherNode.id != node.id && otherNode.location == nodeLocation
            }
            
            for match in locationMatches.prefix(3) {
                recommendations.append(AssociationRecommendation(
                    id: UUID(),
                    targetNodeId: node.id,
                    associatedNodeId: match.id,
                    associationType: .contextual,
                    confidence: 0.7,
                    reasoning: "Same location context: \(nodeLocation)",
                    recommendationType: .contextual
                ))
            }
        }
        
        // Weather-based associations
        if let nodeWeather = node.weather {
            let weatherMatches = allNodes.filter { otherNode in
                otherNode.id != node.id && otherNode.weather == nodeWeather
            }
            
            for match in weatherMatches.prefix(2) {
                recommendations.append(AssociationRecommendation(
                    id: UUID(),
                    targetNodeId: node.id,
                    associatedNodeId: match.id,
                    associationType: .contextual,
                    confidence: 0.5,
                    reasoning: "Similar weather context: \(nodeWeather)",
                    recommendationType: .contextual
                ))
            }
        }
        
        return recommendations
    }
    
    // MARK: - Temporal Analysis
    
    private func analyzeTemporalRelationships(for node: ThoughtNode, in allNodes: [ThoughtNode]) async -> [AssociationRecommendation] {
        var recommendations: [AssociationRecommendation] = []
        
        let timeWindow: TimeInterval = 3600 // 1 hour
        let nodeTime = node.createdAt
        
        // Find nodes created around the same time
        let temporallyCloseNodes = allNodes.filter { otherNode in
            otherNode.id != node.id &&
            abs(otherNode.createdAt.timeIntervalSince(nodeTime)) <= timeWindow
        }
        
        for closeNode in temporallyCloseNodes.prefix(5) {
            let timeDifference = abs(closeNode.createdAt.timeIntervalSince(nodeTime))
            let confidence = Float(1.0 - (timeDifference / timeWindow)) * 0.6
            
            recommendations.append(AssociationRecommendation(
                id: UUID(),
                targetNodeId: node.id,
                associatedNodeId: closeNode.id,
                associationType: .temporal,
                confidence: confidence,
                reasoning: "Created within \(Int(timeDifference / 60)) minutes",
                recommendationType: .temporal
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Emotional Analysis
    
    private func analyzeEmotionalRelationships(for node: ThoughtNode, in allNodes: [ThoughtNode]) async -> [AssociationRecommendation] {
        var recommendations: [AssociationRecommendation] = []
        
        guard !node.emotionalTags.isEmpty else { return recommendations }
        
        // Find nodes with overlapping emotional tags
        let emotionallyRelatedNodes = allNodes.filter { otherNode in
            otherNode.id != node.id &&
            !Set(otherNode.emotionalTags).intersection(Set(node.emotionalTags)).isEmpty
        }
        
        for relatedNode in emotionallyRelatedNodes {
            let commonTags = Set(node.emotionalTags).intersection(Set(relatedNode.emotionalTags))
            let emotionalSimilarity = Float(commonTags.count) / Float(max(node.emotionalTags.count, relatedNode.emotionalTags.count))
            
            // Also consider emotional intensity similarity
            let intensityDifference = abs(Float(node.emotionalIntensity - relatedNode.emotionalIntensity))
            let intensitySimilarity = 1.0 - intensityDifference
            
            let overallConfidence = (emotionalSimilarity * 0.7 + intensitySimilarity * 0.3) * 0.8
            
            if overallConfidence > 0.3 {
                recommendations.append(AssociationRecommendation(
                    id: UUID(),
                    targetNodeId: node.id,
                    associatedNodeId: relatedNode.id,
                    associationType: .emotional,
                    confidence: overallConfidence,
                    reasoning: "Shared emotional context: \(commonTags.map { $0.rawValue }.joined(separator: ", "))",
                    recommendationType: .emotional
                ))
            }
        }
        
        return recommendations.sorted { $0.confidence > $1.confidence }.prefix(3).map { $0 }
    }
    
    // MARK: - Recommendation Combination and Ranking
    
    private func combinedRecommendations(_ recommendationGroups: [[AssociationRecommendation]]) -> [AssociationRecommendation] {
        var allRecommendations: [AssociationRecommendation] = []
        var nodeRecommendationMap: [UUID: AssociationRecommendation] = [:]
        
        // Flatten all recommendations
        for group in recommendationGroups {
            allRecommendations.append(contentsOf: group)
        }
        
        // Combine recommendations for the same node, keeping the highest confidence
        for recommendation in allRecommendations {
            let nodeId = recommendation.associatedNodeId
            
            if let existing = nodeRecommendationMap[nodeId] {
                // Keep the recommendation with higher confidence
                if recommendation.confidence > existing.confidence {
                    nodeRecommendationMap[nodeId] = recommendation
                }
            } else {
                nodeRecommendationMap[nodeId] = recommendation
            }
        }
        
        // Sort by confidence and return top recommendations
        return Array(nodeRecommendationMap.values)
            .sorted { $0.confidence > $1.confidence }
            .prefix(8)
            .map { $0 }
    }
    
    // MARK: - Helper Methods
    
    private func generateEmbeddingForNode(_ node: ThoughtNode) async throws {
        let embedding = try await aiService.generateEmbedding(for: node.content)
        try await vectorService.addVector(embedding, for: node.id)
        
        // Update node metadata
        if let modelContext = modelContext {
            node.hasEmbedding = true
            node.embeddingVersion = "1.0"
            try modelContext.save()
        }
    }
    
    private func getNodeEmbedding(_ node: ThoughtNode) async throws -> [Float] {
        if node.hasEmbedding,
           let results = try? await vectorService.findSimilarByVector([0.0], limit: 1),
           results.isEmpty {
            // Try to get existing embedding
            return try await aiService.generateEmbedding(for: node.content)
        } else {
            return try await aiService.generateEmbedding(for: node.content)
        }
    }
    
    private func classifyAssociationType(similarity: Float) -> AssociationType {
        if similarity >= strongAssociationThreshold {
            return .strongSupport
        } else if similarity >= moderateAssociationThreshold {
            return .weakAssociation
        } else {
            return .similarity
        }
    }
    
    private func generateSemanticReasoning(similarity: Float) -> String {
        if similarity >= strongAssociationThreshold {
            return "Very similar semantic content"
        } else if similarity >= moderateAssociationThreshold {
            return "Moderate semantic similarity"
        } else {
            return "Weak semantic connection"
        }
    }
}

// MARK: - Supporting Types

struct AssociationRecommendation: Identifiable, Hashable {
    let id: UUID
    let targetNodeId: UUID
    let associatedNodeId: UUID
    let associationType: AssociationType
    let confidence: Float
    let reasoning: String
    let recommendationType: RecommendationType
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(associatedNodeId)
    }
    
    static func == (lhs: AssociationRecommendation, rhs: AssociationRecommendation) -> Bool {
        lhs.id == rhs.id && lhs.associatedNodeId == rhs.associatedNodeId
    }
}

// Type alias for compatibility
typealias RecommendedAssociation = AssociationRecommendation

enum AssociationType {
    case strongSupport
    case weakAssociation
    case similarity
    case contextual
    case temporal
    case emotional
    
    var displayName: String {
        switch self {
        case .strongSupport:
            return "Strong Support"
        case .weakAssociation:
            return "Related"
        case .similarity:
            return "Similar"
        case .contextual:
            return "Contextual"
        case .temporal:
            return "Temporal"
        case .emotional:
            return "Emotional"
        }
    }
    
    var color: String {
        switch self {
        case .strongSupport:
            return "green"
        case .weakAssociation:
            return "blue"
        case .similarity:
            return "purple"
        case .contextual:
            return "orange"
        case .temporal:
            return "cyan"
        case .emotional:
            return "pink"
        }
    }
}

enum RecommendationType {
    case semantic
    case contextual
    case temporal
    case emotional
    
    var priority: Int {
        switch self {
        case .semantic: return 4
        case .emotional: return 3
        case .contextual: return 2
        case .temporal: return 1
        }
    }
}