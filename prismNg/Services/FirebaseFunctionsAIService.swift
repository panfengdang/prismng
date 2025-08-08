//
//  FirebaseFunctionsAIService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import Combine

// MARK: - Firebase Functions AI Service
@MainActor
class FirebaseFunctionsAIService: ObservableObject {
    @Published var isProcessing = false
    @Published var lastError: String?
    
    private let firebaseManager: FirebaseManager
    private let baseURL = "https://us-central1-prismng-app.cloudfunctions.net"
    
    init(firebaseManager: FirebaseManager? = nil) {
        self.firebaseManager = firebaseManager ?? FirebaseManager.shared
    }
    
    // MARK: - AI Processing Methods
    
    /// 处理思维节点分析请求
    func analyzeThoughtNode(_ node: ThoughtNode, context: [ThoughtNode]) async throws -> CloudAIAnalysisResult {
        isProcessing = true
        defer { isProcessing = false }
        
        let request = AIAnalysisRequest(
            nodeId: node.id.uuidString,
            content: node.content,
            nodeType: node.nodeType.rawValue,
            context: context.map { contextNode in
                ContextNode(
                    id: contextNode.id.uuidString,
                    content: contextNode.content,
                    type: contextNode.nodeType.rawValue
                )
            }
        )
        
        return try await callFunction("analyzeThought", with: request, returning: CloudAIAnalysisResult.self)
    }
    
    /// 生成智能关联建议
    func generateAssociations(for node: ThoughtNode, in context: [ThoughtNode]) async throws -> [AIAssociation] {
        isProcessing = true
        defer { isProcessing = false }
        
        let request = AssociationRequest(
            targetNode: ContextNode(
                id: node.id.uuidString,
                content: node.content,
                type: node.nodeType.rawValue
            ),
            contextNodes: context.map { contextNode in
                ContextNode(
                    id: contextNode.id.uuidString,
                    content: contextNode.content,
                    type: contextNode.nodeType.rawValue
                )
            }
        )
        
        let result = try await callFunction("generateAssociations", with: request, returning: AssociationResult.self)
        return result.associations
    }
    
    /// 生成认知洞察
    func generateInsight(from nodes: [ThoughtNode]) async throws -> AIInsight {
        isProcessing = true
        defer { isProcessing = false }
        
        let request = InsightRequest(
            nodes: nodes.map { node in
                ContextNode(
                    id: node.id.uuidString,
                    content: node.content,
                    type: node.nodeType.rawValue
                )
            }
        )
        
        return try await callFunction("generateInsight", with: request, returning: AIInsight.self)
    }
    
    /// 语义向量嵌入生成
    func generateEmbedding(for text: String) async throws -> [Float] {
        isProcessing = true
        defer { isProcessing = false }
        
        let request = EmbeddingRequest(text: text)
        let result = try await callFunction("generateEmbedding", with: request, returning: EmbeddingResult.self)
        
        return result.embedding
    }
    
    /// 情感计算分析
    func analyzeEmotionalState(_ nodes: [ThoughtNode]) async throws -> EmotionalAnalysis {
        isProcessing = true
        defer { isProcessing = false }
        
        let request = EmotionalAnalysisRequest(
            nodes: nodes.map { node in
                ContextNode(
                    id: node.id.uuidString,
                    content: node.content,
                    type: node.nodeType.rawValue
                )
            }
        )
        
        return try await callFunction("analyzeEmotionalState", with: request, returning: EmotionalAnalysis.self)
    }
    
    // MARK: - Private Helper Methods
    
    private func callFunction<T: Codable, R: Codable>(
        _ functionName: String,
        with request: T,
        returning: R.Type
    ) async throws -> R {
        
        // Check if user is authenticated
        guard firebaseManager.isAuthenticated else {
            throw FirebaseFunctionsError.notAuthenticated
        }
        
        // Prepare URL
        guard let url = URL(string: "\(baseURL)/\(functionName)") else {
            throw FirebaseFunctionsError.invalidURL
        }
        
        // Prepare request
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication token if available
        if let user = firebaseManager.currentUser {
            // In real implementation, get the actual Firebase ID token
            urlRequest.setValue("Bearer \(user.id)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode request body
        do {
            let requestData = try JSONEncoder().encode(request)
            urlRequest.httpBody = requestData
        } catch {
            throw FirebaseFunctionsError.encodingError(error)
        }
        
        // Perform request
        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Check HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw FirebaseFunctionsError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                // Try to parse error message
                if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = errorData["error"] as? String {
                    throw FirebaseFunctionsError.serverError(errorMessage)
                }
                throw FirebaseFunctionsError.httpError(httpResponse.statusCode)
            }
            
            // Decode response
            do {
                let result = try JSONDecoder().decode(R.self, from: data)
                return result
            } catch {
                throw FirebaseFunctionsError.decodingError(error)
            }
            
        } catch {
            if error is FirebaseFunctionsError {
                await MainActor.run {
                    self.lastError = error.localizedDescription
                }
                throw error
            }
            await MainActor.run {
                self.lastError = "Network error: \(error.localizedDescription)"
            }
            throw FirebaseFunctionsError.networkError(error)
        }
    }
}

// MARK: - Request/Response Models

struct AIAnalysisRequest: Codable {
    let nodeId: String
    let content: String
    let nodeType: String
    let context: [ContextNode]
}

struct CloudAIAnalysisResult: Codable {
    let nodeId: String
    let analysis: String
    let confidence: Double
    let suggestions: [String]
    let relationshipScore: Double
}

struct AssociationRequest: Codable {
    let targetNode: ContextNode
    let contextNodes: [ContextNode]
}

struct AssociationResult: Codable {
    let associations: [AIAssociation]
}

struct AIAssociation: Codable {
    let targetNodeId: String
    let relatedNodeId: String
    let associationType: String
    let strength: Double
    let explanation: String
    let confidence: Double
}

struct InsightRequest: Codable {
    let nodes: [ContextNode]
}

struct AIInsight: Codable {
    let insight: String
    let theme: String
    let confidence: Double
    let supportingNodeIds: [String]
}

struct EmbeddingRequest: Codable {
    let text: String
}

struct EmbeddingResult: Codable {
    let embedding: [Float]
    let dimensions: Int
}

struct EmotionalAnalysisRequest: Codable {
    let nodes: [ContextNode]
}

struct EmotionalAnalysis: Codable {
    let overallValence: Double // -1.0 to 1.0
    let arousal: Double // 0.0 to 1.0
    let dominantEmotion: String
    let emotionalTrajectory: [EmotionalPoint]
    let confidence: Double
}

struct EmotionalPoint: Codable {
    let nodeId: String
    let valence: Double
    let arousal: Double
    let emotion: String
}

struct ContextNode: Codable {
    let id: String
    let content: String
    let type: String
}

// MARK: - Error Types

enum FirebaseFunctionsError: Error, LocalizedError {
    case notAuthenticated
    case invalidURL
    case encodingError(Error)
    case decodingError(Error)
    case networkError(Error)
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User must be authenticated to use AI services"
        case .invalidURL:
            return "Invalid Firebase Functions URL"
        case .encodingError(let error):
            return "Request encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Response decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Firebase Functions Integration

extension FirebaseFunctionsAIService {
    
    /// 批量处理多个节点
    func batchProcessNodes(_ nodes: [ThoughtNode]) async throws -> [CloudAIAnalysisResult] {
        isProcessing = true
        defer { isProcessing = false }
        
        let batchRequest = BatchAnalysisRequest(
            nodes: nodes.map { node in
                ContextNode(
                    id: node.id.uuidString,
                    content: node.content,
                    type: node.nodeType.rawValue
                )
            }
        )
        
        let result = try await callFunction("batchAnalyze", with: batchRequest, returning: BatchAnalysisResult.self)
        return result.results
    }
    
    /// 实时流式AI对话
    func startStreamingChat(with prompt: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = StreamChatRequest(prompt: prompt)
                    
                    // In a real implementation, this would establish a WebSocket or Server-Sent Events connection
                    // For now, simulate streaming by chunking a response
                    let response = try await callFunction("streamChat", with: request, returning: StreamChatResponse.self)
                    
                    // Simulate streaming by yielding chunks
                    let chunks = response.content.components(separatedBy: " ")
                    for chunk in chunks {
                        continuation.yield(chunk + " ")
                        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

// MARK: - Additional Models

struct BatchAnalysisRequest: Codable {
    let nodes: [ContextNode]
}

struct BatchAnalysisResult: Codable {
    let results: [CloudAIAnalysisResult]
}

struct StreamChatRequest: Codable {
    let prompt: String
}

struct StreamChatResponse: Codable {
    let content: String
    let conversationId: String
}