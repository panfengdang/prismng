//
//  HybridAIService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI

// MARK: - Hybrid AI Service
/// Combines local AI processing with Firebase Functions for optimal performance
@MainActor
class HybridAIService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastError: String?
    @Published var networkStatus: NetworkStatus = .unknown
    
    private let localAIService: AIService
    private let cloudAIService: FirebaseFunctionsAIService
    private let quotaService: QuotaManagementService
    
    init(quotaService: QuotaManagementService) {
        self.localAIService = AIService()
        self.cloudAIService = FirebaseFunctionsAIService()
        self.quotaService = quotaService
        
        // Monitor network status
        Task {
            await checkNetworkStatus()
        }
    }
    
    // MARK: - Smart AI Processing
    
    /// Intelligently routes AI requests between local and cloud processing
    func processThoughtAnalysis(
        _ node: ThoughtNode, 
        context: [ThoughtNode]
    ) async throws -> LocalAIAnalysisResult {
        
        // Check quota first
        guard quotaService.canUseAI() else {
            throw AIServiceError.quotaExceeded
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let result: LocalAIAnalysisResult
            
            // Decide between local vs cloud processing
            if shouldUseCloudProcessing(for: .analysis, nodeCount: context.count + 1) {
                let cloudResult = try await cloudAIService.analyzeThoughtNode(node, context: context)
                result = LocalAIAnalysisResult(
                    nodeId: cloudResult.nodeId,
                    analysis: cloudResult.analysis,
                    confidence: cloudResult.confidence,
                    suggestions: cloudResult.suggestions,
                    relationshipScore: cloudResult.relationshipScore
                )
                _ = quotaService.incrementQuotaUsage() // Consume quota for cloud usage
            } else {
                // Use local processing with quota consideration
                let localResult = try await localAIService.analyzeStructure(
                    centerNode: node, 
                    relatedNodes: context
                )
                
                // Convert local result to unified format
                result = LocalAIAnalysisResult(
                    nodeId: node.id.uuidString,
                    analysis: localResult.conclusion ?? "Local analysis completed",
                    confidence: 0.7,
                    suggestions: generateSuggestions(for: node, from: localResult),
                    relationshipScore: calculateRelationshipScore(from: localResult)
                )
                
                // Local processing uses less quota
                if context.count > 3 {
                    _ = quotaService.incrementQuotaUsage()
                }
            }
            
            return result
            
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    /// Generate semantic associations with hybrid approach
    func generateAssociations(
        for node: ThoughtNode,
        in context: [ThoughtNode]
    ) async throws -> [AIAssociation] {
        
        guard quotaService.canUseAI() else {
            throw AIServiceError.quotaExceeded
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            if shouldUseCloudProcessing(for: .associations, nodeCount: context.count) {
                let associations = try await cloudAIService.generateAssociations(for: node, in: context)
                _ = quotaService.incrementQuotaUsage()
                return associations
            } else {
                // Use local association finding
                let localAssociations = try await localAIService.findAssociations(for: node, in: context)
                
                // Convert to cloud format
                let associations = localAssociations.map { local in
                    AIAssociation(
                        targetNodeId: node.id.uuidString,
                        relatedNodeId: local.nodeId.uuidString,
                        associationType: local.associationType,
                        strength: local.strength,
                        explanation: local.explanation,
                        confidence: 0.6
                    )
                }
                
                return associations
            }
            
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    /// Generate meta-cognitive insights
    func generateInsight(from nodes: [ThoughtNode]) async throws -> AIInsight {
        
        guard quotaService.canUseAI() else {
            throw AIServiceError.quotaExceeded
        }
        
        isProcessing = true  
        defer { isProcessing = false }
        
        do {
            if shouldUseCloudProcessing(for: .insights, nodeCount: nodes.count) {
                let insight = try await cloudAIService.generateInsight(from: nodes)
                _ = quotaService.incrementQuotaUsage()
                return insight
            } else {
                // Use local insight generation
                let localInsight = try await localAIService.generateInsight(from: nodes)
                
                return AIInsight(
                    insight: localInsight,
                    theme: "Local Analysis",
                    confidence: 0.6,
                    supportingNodeIds: nodes.prefix(2).map { $0.id.uuidString }
                )
            }
            
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    /// Generate embeddings efficiently
    func generateEmbedding(for text: String) async throws -> [Float] {
        
        // Embeddings prefer local processing for speed
        if networkStatus == .offline || text.count < 100 {
            return try await localAIService.generateEmbedding(for: text)
        } else {
            // Use cloud for complex embeddings
            guard quotaService.canUseAI() else {
                return try await localAIService.generateEmbedding(for: text)
            }
            
            do {
                let embedding = try await cloudAIService.generateEmbedding(for: text)
                if text.count > 200 {
                    _ = quotaService.incrementQuotaUsage()
                }
                return embedding
            } catch {
                // Fallback to local
                return try await localAIService.generateEmbedding(for: text)
            }
        }
    }
    
    /// Emotional analysis with hybrid approach
    func analyzeEmotionalState(_ nodes: [ThoughtNode]) async throws -> EmotionalAnalysis {
        
        guard quotaService.canUseAI() else {
            throw AIServiceError.quotaExceeded
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            if shouldUseCloudProcessing(for: .emotional, nodeCount: nodes.count) {
                let analysis = try await cloudAIService.analyzeEmotionalState(nodes)
                _ = quotaService.incrementQuotaUsage()
                return analysis
            } else {
                // Simplified local emotional analysis
                return EmotionalAnalysis(
                    overallValence: 0.0,
                    arousal: 0.5,
                    dominantEmotion: "contemplative",
                    emotionalTrajectory: nodes.map { node in
                        EmotionalPoint(
                            nodeId: node.id.uuidString,
                            valence: analyzeLocalValence(node.content),
                            arousal: 0.5,
                            emotion: "reflective"
                        )
                    },
                    confidence: 0.5
                )
            }
            
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Processing Decision Logic
    
    private func shouldUseCloudProcessing(for taskType: HybridAITaskType, nodeCount: Int) -> Bool {
        // Factors for decision making:
        
        // 1. Network connectivity
        guard networkStatus == .online else { return false }
        
        // 2. User subscription tier
        let subscriptionTier = quotaService.subscriptionTier
        
        // 3. Task complexity
        let isComplexTask = nodeCount > 5 || taskType == .insights
        
        // 4. Available quota
        guard quotaService.canUseAI() else { return false }
        
        // Decision matrix
        switch subscriptionTier {
        case .free:
            // Free users: only use cloud for complex tasks when quota available
            return isComplexTask && nodeCount <= 3
            
        case .explorer:
            // Explorer: use cloud for medium complexity tasks
            return nodeCount > 2 || taskType == .insights
            
        case .advanced, .professional:
            // Premium users: prefer cloud processing for better results
            return true
        }
    }
    
    // MARK: - Helper Methods
    
    private func generateSuggestions(for node: ThoughtNode, from analysis: StructureAnalysis) -> [String] {
        var suggestions: [String] = []
        
        if analysis.relationships.isEmpty {
            suggestions.append("Consider connecting this thought to related ideas")
        }
        
        if node.content.count < 50 {
            suggestions.append("Expand on this thought with more detail")
        }
        
        suggestions.append("Explore the implications of this idea")
        
        return suggestions
    }
    
    private func calculateRelationshipScore(from analysis: StructureAnalysis) -> Double {
        if analysis.relationships.isEmpty {
            return 0.2
        }
        
        let averageStrength = analysis.relationships.reduce(0.0) { $0 + $1.strength } / Double(analysis.relationships.count)
        return averageStrength
    }
    
    private func analyzeLocalValence(_ text: String) -> Double {
        // Simple local sentiment analysis
        let positiveWords = ["good", "great", "amazing", "wonderful", "excited", "happy", "love"]
        let negativeWords = ["bad", "terrible", "awful", "sad", "angry", "hate", "worried"]
        
        let lowercased = text.lowercased()
        let positiveCount = positiveWords.reduce(0) { lowercased.contains($1) ? $0 + 1 : $0 }
        let negativeCount = negativeWords.reduce(0) { lowercased.contains($1) ? $0 + 1 : $0 }
        
        if positiveCount > negativeCount {
            return 0.3
        } else if negativeCount > positiveCount {
            return -0.3
        }
        return 0.0
    }
    
    private func checkNetworkStatus() async {
        // Simple network check
        do {
            let url = URL(string: "https://www.google.com")!
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200 {
                networkStatus = .online
            } else {
                networkStatus = .offline
            }
        } catch {
            networkStatus = .offline
        }
    }
}

// MARK: - Supporting Types

enum NetworkStatus {
    case online
    case offline 
    case unknown
}

enum HybridAITaskType: String {
    case analysis = "analysis"
    case associations = "associations"
    case insights = "insights"
    case emotional = "emotional"
    case embeddings = "embeddings"
}

// MARK: - Batch Processing Extension

extension HybridAIService {
    
    /// Process multiple nodes efficiently with batching
    func batchProcessNodes(_ nodes: [ThoughtNode]) async throws -> [LocalAIAnalysisResult] {
        guard quotaService.canUseAI() else {
            throw AIServiceError.quotaExceeded
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Batch size optimization based on subscription
        let batchSize = quotaService.subscriptionTier == .professional ? 20 : 10
        
        if shouldUseCloudProcessing(for: .analysis, nodeCount: nodes.count) && nodes.count > 5 {
            // Use cloud batch processing
            let batches = nodes.chunked(into: batchSize)
            var allResults: [LocalAIAnalysisResult] = []
            
            for batch in batches {
                let cloudResults = try await cloudAIService.batchProcessNodes(Array(batch))
                let localResults = cloudResults.map { cloudResult in
                    LocalAIAnalysisResult(
                        nodeId: cloudResult.nodeId,
                        analysis: cloudResult.analysis,
                        confidence: cloudResult.confidence,
                        suggestions: cloudResult.suggestions,
                        relationshipScore: cloudResult.relationshipScore
                    )
                }
                allResults.append(contentsOf: localResults)
                _ = quotaService.incrementQuotaUsage()
            }
            
            return allResults
            
        } else {
            // Process locally with parallel execution
            return try await withThrowingTaskGroup(of: LocalAIAnalysisResult.self) { group in
                for node in nodes {
                    group.addTask {
                        return try await self.processThoughtAnalysis(node, context: [])
                    }
                }
                
                var results: [LocalAIAnalysisResult] = []
                for try await result in group {
                    results.append(result)
                }
                return results
            }
        }
    }
}

// MARK: - Local Analysis Result Type

struct LocalAIAnalysisResult {
    let nodeId: String
    let analysis: String
    let confidence: Double
    let suggestions: [String]
    let relationshipScore: Double
}

// MARK: - Array Extension for Batching

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}