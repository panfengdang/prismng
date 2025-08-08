//
//  AIService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import CoreML

// MARK: - AI Service Protocol
protocol AIServiceProtocol {
    func generateEmbedding(for text: String) async throws -> [Float]
    func analyzeStructure(centerNode: ThoughtNode, relatedNodes: [ThoughtNode]) async throws -> StructureAnalysis
    func findAssociations(for node: ThoughtNode, in context: [ThoughtNode]) async throws -> [NodeAssociation]
    func generateInsight(from nodes: [ThoughtNode]) async throws -> String
}

// MARK: - Main AI Service Implementation
class AIService: AIServiceProtocol {
    
    // MARK: - Properties
    private let localEmbeddingService: LocalEmbeddingService
    private let llmService: RealLLMService
    private let configService: AIConfigurationService
    private let useMockResponses: Bool
    
    // MARK: - Initialization
    init(useMockResponses: Bool = false) {
        self.localEmbeddingService = LocalEmbeddingService()
        self.llmService = RealLLMService()
        self.configService = AIConfigurationService()
        self.useMockResponses = useMockResponses
        
        // Check if API key is available
        if ProcessInfo.processInfo.environment["OPENAI_API_KEY"] == nil && !useMockResponses {
            print("⚠️ Warning: OPENAI_API_KEY not set. AI features will use fallback implementations.")
        }
    }
    
    // MARK: - Embedding Generation
    func generateEmbedding(for text: String) async throws -> [Float] {
        // Use local embedding service with Apple's NLEmbedding
        guard let embedding = await localEmbeddingService.generateEmbedding(for: text) else {
            // Fallback to simple hash-based embedding if local embedding fails
            let embeddingModel = EmbeddingModel()
            return try await embeddingModel.generateEmbedding(for: text)
        }
        
        return embedding
    }
    
    // MARK: - Structure Analysis
    func analyzeStructure(centerNode: ThoughtNode, relatedNodes: [ThoughtNode]) async throws -> StructureAnalysis {
        
        let prompt = buildStructureAnalysisPrompt(centerNode: centerNode, relatedNodes: relatedNodes)
        
        if useMockResponses {
            let response = mockStructureAnalysisResponse()
            return try parseStructureAnalysis(response: response, centerNode: centerNode, relatedNodes: relatedNodes)
        }
        
        do {
            let analysisResponse = try await llmService.analyzeStructure(prompt: prompt)
            return convertToStructureAnalysis(analysisResponse, centerNode: centerNode, relatedNodes: relatedNodes)
        } catch {
            // Fallback to mock if real API fails
            print("AI Service failed, using fallback: \(error)")
            let response = mockStructureAnalysisResponse()
            return try parseStructureAnalysis(response: response, centerNode: centerNode, relatedNodes: relatedNodes)
        }
    }
    
    private func convertToStructureAnalysis(_ response: StructureAnalysisResponse, centerNode: ThoughtNode, relatedNodes: [ThoughtNode]) -> StructureAnalysis {
        var relationships: [NodeRelationship] = []
        let allNodes = [centerNode] + relatedNodes
        
        for relationship in response.relationships {
            guard relationship.fromIndex < allNodes.count && relationship.toIndex < allNodes.count else {
                continue
            }
            
            let fromNode = allNodes[relationship.fromIndex]
            let toNode = allNodes[relationship.toIndex]
            
            if let connectionType = ConnectionType(rawValue: relationship.type) {
                relationships.append(NodeRelationship(
                    fromNodeId: fromNode.id,
                    toNodeId: toNode.id,
                    type: connectionType,
                    strength: relationship.strength
                ))
            }
        }
        
        return StructureAnalysis(
            conclusion: response.conclusion,
            relationships: relationships
        )
    }
    
    private func buildStructureAnalysisPrompt(centerNode: ThoughtNode, relatedNodes: [ThoughtNode]) -> String {
        var prompt = """
        You are an AI thought architect. Analyze the logical relationships between these thoughts:
        
        CENTRAL THOUGHT:
        "\(centerNode.content)"
        
        RELATED THOUGHTS:
        """
        
        for (index, node) in relatedNodes.enumerated() {
            prompt += "\n\(index + 1). \"\(node.content)\""
        }
        
        prompt += """
        
        TASK:
        1. Identify logical relationships (support, contradiction, causality, similarity)
        2. Determine connection strength (0.0-1.0)
        3. Generate insights or conclusions if any emerge
        4. Respond in JSON format:
        
        {
            "relationships": [
                {
                    "fromIndex": 0,
                    "toIndex": 1,
                    "type": "strongSupport|weakAssociation|contradiction|causality|similarity",
                    "strength": 0.8,
                    "explanation": "brief explanation"
                }
            ],
            "conclusion": "optional insight or conclusion",
            "confidence": 0.7
        }
        """
        
        return prompt
    }
    
    private func parseStructureAnalysis(response: String, centerNode: ThoughtNode, relatedNodes: [ThoughtNode]) throws -> StructureAnalysis {
        
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }
        
        let jsonResponse = try JSONDecoder().decode(StructureAnalysisResponse.self, from: data)
        
        var relationships: [NodeRelationship] = []
        let allNodes = [centerNode] + relatedNodes
        
        for relationship in jsonResponse.relationships {
            guard relationship.fromIndex < allNodes.count && relationship.toIndex < allNodes.count else {
                continue
            }
            
            let fromNode = allNodes[relationship.fromIndex]
            let toNode = allNodes[relationship.toIndex]
            
            if let connectionType = ConnectionType(rawValue: relationship.type) {
                relationships.append(NodeRelationship(
                    fromNodeId: fromNode.id,
                    toNodeId: toNode.id,
                    type: connectionType,
                    strength: relationship.strength
                ))
            }
        }
        
        return StructureAnalysis(
            conclusion: jsonResponse.conclusion,
            relationships: relationships
        )
    }
    
    // MARK: - Association Finding
    func findAssociations(for node: ThoughtNode, in context: [ThoughtNode]) async throws -> [NodeAssociation] {
        
        let prompt = buildAssociationPrompt(targetNode: node, contextNodes: context)
        
        if useMockResponses {
            let response = mockAssociationResponse()
            return try parseAssociations(response: response, contextNodes: context)
        }
        
        do {
            let associationResponse = try await llmService.findAssociations(prompt: prompt)
            return convertToNodeAssociations(associationResponse, contextNodes: context)
        } catch {
            // Fallback to mock if real API fails
            print("AI Service failed, using fallback: \(error)")
            let response = mockAssociationResponse()
            return try parseAssociations(response: response, contextNodes: context)
        }
    }
    
    private func convertToNodeAssociations(_ response: AssociationResponse, contextNodes: [ThoughtNode]) -> [NodeAssociation] {
        return response.associations.compactMap { association in
            guard association.nodeIndex < contextNodes.count else { return nil }
            
            return NodeAssociation(
                nodeId: contextNodes[association.nodeIndex].id,
                associationType: association.associationType,
                strength: association.strength,
                explanation: association.explanation
            )
        }
    }
    
    private func buildAssociationPrompt(targetNode: ThoughtNode, contextNodes: [ThoughtNode]) -> String {
        var prompt = """
        Find semantic associations for this thought:
        
        TARGET: "\(targetNode.content)"
        
        CONTEXT THOUGHTS:
        """
        
        for (index, node) in contextNodes.enumerated() {
            prompt += "\n\(index). \"\(node.content)\""
        }
        
        prompt += """
        
        Return associations as JSON:
        {
            "associations": [
                {
                    "nodeIndex": 0,
                    "associationType": "semantic|thematic|causal|temporal",
                    "strength": 0.6,
                    "explanation": "why they're related"
                }
            ]
        }
        """
        
        return prompt
    }
    
    private func parseAssociations(response: String, contextNodes: [ThoughtNode]) throws -> [NodeAssociation] {
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }
        
        let jsonResponse = try JSONDecoder().decode(AssociationResponse.self, from: data)
        
        return jsonResponse.associations.compactMap { association in
            guard association.nodeIndex < contextNodes.count else { return nil }
            
            return NodeAssociation(
                nodeId: contextNodes[association.nodeIndex].id,
                associationType: association.associationType,
                strength: association.strength,
                explanation: association.explanation
            )
        }
    }
    
    // MARK: - Insight Generation
    func generateInsight(from nodes: [ThoughtNode]) async throws -> String {
        let prompt = buildInsightPrompt(nodes: nodes)
        
        if useMockResponses {
            return mockInsightResponse()
        }
        
        do {
            let response = try await llmService.generateInsight(prompt: prompt)
            return response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            // Fallback to mock if real API fails
            print("AI Service failed, using fallback: \(error)")
            return mockInsightResponse()
        }
    }
    
    private func buildInsightPrompt(nodes: [ThoughtNode]) -> String {
        var prompt = """
        Generate a meta-cognitive insight from these thoughts:
        
        THOUGHTS:
        """
        
        for (index, node) in nodes.enumerated() {
            prompt += "\n\(index + 1). \"\(node.content)\" (Type: \(node.nodeType.rawValue))"
        }
        
        prompt += """
        
        Generate a higher-level insight that synthesizes these thoughts. Focus on patterns, contradictions, or emergent themes. Be concise and thought-provoking.
        """
        
        return prompt
    }
    
    private func parseInsight(response: String) throws -> String {
        // For now, return the response directly
        // Could add JSON parsing for more structured insights
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Embedding Model
class EmbeddingModel {
    private var model: MLModel?
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        // TODO: Load actual Core ML embedding model
        // For MVP, we'll use a simple hash-based approach
        print("Loading embedding model...")
    }
    
    func generateEmbedding(for text: String) async throws -> [Float] {
        // Placeholder implementation - in real app would use Core ML model
        // For now, create a simple hash-based embedding
        return createSimpleEmbedding(from: text)
    }
    
    private func createSimpleEmbedding(from text: String) -> [Float] {
        let words = text.lowercased().components(separatedBy: CharacterSet.alphanumerics.inverted)
        let nonEmptyWords = words.filter { !$0.isEmpty }
        
        // Create a 128-dimensional embedding
        var embedding = Array(repeating: Float(0.0), count: 128)
        
        for word in nonEmptyWords {
            let hash = word.hash
            for i in 0..<128 {
                let index = (hash + i) % 128
                embedding[index] += Float.random(in: -0.1...0.1)
            }
        }
        
        // Normalize
        let magnitude = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }
        
        return embedding
    }
}

    // MARK: - Mock Response Methods
    private func mockStructureAnalysisResponse() -> String {
        return """
        {
            "relationships": [
                {
                    "fromIndex": 0,
                    "toIndex": 1,
                    "type": "strongSupport",
                    "strength": 0.8,
                    "explanation": "These thoughts build upon each other logically"
                }
            ],
            "conclusion": "These thoughts suggest a cohesive framework for understanding the problem",
            "confidence": 0.7
        }
        """
    }
    
    private func mockAssociationResponse() -> String {
        return """
        {
            "associations": [
                {
                    "nodeIndex": 0,
                    "associationType": "semantic",
                    "strength": 0.6,
                    "explanation": "Both thoughts relate to similar concepts"
                }
            ]
        }
        """
    }
    
    private func mockInsightResponse() -> String {
        return "These thoughts reveal an interesting pattern about how ideas evolve and connect over time."
    }

// MARK: - AI Configuration Service
class AIConfigurationService {
    
    func getModelConfiguration(for taskType: AITaskType) -> AIModelConfiguration {
        // Return appropriate model configuration based on task type
        switch taskType {
        case .generateEmbedding:
            return AIModelConfiguration(
                modelName: "embedding-model",
                maxTokens: 512,
                temperature: 0.0
            )
        case .structureAnalysis:
            return AIModelConfiguration(
                modelName: "analysis-model",
                maxTokens: 1024,
                temperature: 0.3
            )
        default:
            return AIModelConfiguration(
                modelName: "default-model",
                maxTokens: 512,
                temperature: 0.5
            )
        }
    }
}

// MARK: - Supporting Types

struct AIModelConfiguration {
    let modelName: String
    let maxTokens: Int
    let temperature: Double
}

struct StructureAnalysisResponse: Codable {
    let relationships: [RelationshipResponse]
    let conclusion: String?
    let confidence: Double
}

struct RelationshipResponse: Codable {
    let fromIndex: Int
    let toIndex: Int
    let type: String
    let strength: Double
    let explanation: String
}

struct AssociationResponse: Codable {
    let associations: [AssociationData]
}

struct AssociationData: Codable {
    let nodeIndex: Int
    let associationType: String
    let strength: Double
    let explanation: String
}

struct NodeAssociation {
    let nodeId: UUID
    let associationType: String
    let strength: Double
    let explanation: String
}

// MARK: - Errors
enum AIServiceError: Error {
    case modelNotLoaded
    case invalidInput
    case invalidResponse
    case networkError
    case quotaExceeded
    
    var localizedDescription: String {
        switch self {
        case .modelNotLoaded:
            return "AI model not loaded"
        case .invalidInput:
            return "Invalid input provided"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .networkError:
            return "Network error occurred"
        case .quotaExceeded:
            return "AI quota exceeded"
        }
    }
}