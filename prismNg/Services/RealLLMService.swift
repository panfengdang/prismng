//
//  RealLLMService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/6.
//

import Foundation

// MARK: - Real LLM Service Implementation
class RealLLMService {
    
    // MARK: - Properties
    private let apiKey: String
    private let baseURL: String
    private let session = URLSession.shared
    private let maxRetries = 3
    private let defaultModel = "gpt-4o-mini"
    
    // MARK: - Initialization
    init() {
        // Load API key from environment or keychain
        self.apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        self.baseURL = "https://api.openai.com/v1"
        
        if apiKey.isEmpty {
            print("⚠️ OpenAI API key not found. Set OPENAI_API_KEY environment variable.")
        }
    }
    
    // MARK: - Main API Call
    func callLLM(prompt: String, taskType: AITaskType, model: String? = nil) async throws -> String {
        let selectedModel = model ?? getModelForTask(taskType)
        let temperature = getTemperatureForTask(taskType)
        let maxTokens = getMaxTokensForTask(taskType)
        
        let request = try buildRequest(
            prompt: prompt,
            model: selectedModel,
            temperature: temperature,
            maxTokens: maxTokens,
            responseFormat: taskType.requiresJSON ? "json_object" : "text"
        )
        
        return try await executeRequestWithRetry(request, retries: maxRetries)
    }
    
    // MARK: - Structured API Calls
    func analyzeStructure(prompt: String) async throws -> StructureAnalysisResponse {
        let systemPrompt = """
        You are an AI thought architect specializing in analyzing logical relationships between ideas.
        Always respond in valid JSON format.
        """
        
        let fullPrompt = systemPrompt + "\n\n" + prompt
        let response = try await callLLM(prompt: fullPrompt, taskType: .structureAnalysis)
        
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }
        
        return try JSONDecoder().decode(StructureAnalysisResponse.self, from: data)
    }
    
    func findAssociations(prompt: String) async throws -> AssociationResponse {
        let systemPrompt = """
        You are an AI assistant specialized in finding semantic and thematic associations between thoughts.
        Always respond in valid JSON format.
        """
        
        let fullPrompt = systemPrompt + "\n\n" + prompt
        let response = try await callLLM(prompt: fullPrompt, taskType: .findAssociations)
        
        guard let data = response.data(using: .utf8) else {
            throw AIServiceError.invalidResponse
        }
        
        return try JSONDecoder().decode(AssociationResponse.self, from: data)
    }
    
    func generateInsight(prompt: String) async throws -> String {
        let systemPrompt = """
        You are a meta-cognitive analyst who generates profound insights by synthesizing multiple thoughts.
        Focus on identifying patterns, contradictions, and emergent themes.
        Be concise and thought-provoking.
        """
        
        let fullPrompt = systemPrompt + "\n\n" + prompt
        return try await callLLM(prompt: fullPrompt, taskType: .evolutionSummary)
    }
    
    // MARK: - Embedding Generation
    func generateEmbedding(text: String) async throws -> [Float] {
        let url = URL(string: "\(baseURL)/embeddings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "input": text,
            "model": "text-embedding-3-small",
            "encoding_format": "float"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AIServiceError.networkError
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let dataArray = json?["data"] as? [[String: Any]],
              let firstData = dataArray.first,
              let embedding = firstData["embedding"] as? [NSNumber] else {
            throw AIServiceError.invalidResponse
        }
        
        return embedding.map { Float($0.floatValue) }
    }
    
    // MARK: - Helper Methods
    private func buildRequest(
        prompt: String,
        model: String,
        temperature: Double,
        maxTokens: Int,
        responseFormat: String
    ) throws -> URLRequest {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": temperature,
            "max_tokens": maxTokens
        ]
        
        if responseFormat == "json_object" {
            body["response_format"] = ["type": "json_object"]
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
    
    private func executeRequestWithRetry(_ request: URLRequest, retries: Int) async throws -> String {
        var lastError: Error?
        
        for attempt in 0..<retries {
            do {
                if attempt > 0 {
                    // Exponential backoff
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
                
                let (data, response) = try await session.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        return try parseResponse(data)
                    case 429:
                        // Rate limited, wait and retry
                        if let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After"),
                           let seconds = Double(retryAfter) {
                            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                        }
                        lastError = AIServiceError.networkError
                        continue
                    case 401:
                        throw AIServiceError.invalidAPIKey
                    case 400:
                        throw AIServiceError.invalidInput
                    default:
                        lastError = AIServiceError.networkError
                        continue
                    }
                }
            } catch {
                lastError = error
                if attempt == retries - 1 {
                    throw error
                }
            }
        }
        
        throw lastError ?? AIServiceError.networkError
    }
    
    private func parseResponse(_ data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return content
    }
    
    private func getModelForTask(_ taskType: AITaskType) -> String {
        switch taskType {
        case .generateEmbedding:
            return "text-embedding-3-small"
        case .structureAnalysis, .findAssociations:
            return "gpt-4o-mini"
        case .evolutionSummary, .identitySimulation:
            return "gpt-4o"
        default:
            return defaultModel
        }
    }
    
    private func getTemperatureForTask(_ taskType: AITaskType) -> Double {
        switch taskType {
        case .generateEmbedding, .structureAnalysis:
            return 0.3
        case .findAssociations:
            return 0.5
        case .evolutionSummary, .identitySimulation:
            return 0.7
        default:
            return 0.5
        }
    }
    
    private func getMaxTokensForTask(_ taskType: AITaskType) -> Int {
        switch taskType {
        case .generateEmbedding:
            return 512
        case .structureAnalysis, .findAssociations:
            return 1024
        case .evolutionSummary, .identitySimulation:
            return 2048
        default:
            return 1024
        }
    }
}

// MARK: - AITaskType Extension
extension AITaskType {
    var requiresJSON: Bool {
        switch self {
        case .structureAnalysis, .findAssociations:
            return true
        default:
            return false
        }
    }
}

// MARK: - Additional Error Cases
extension AIServiceError {
    static let invalidAPIKey = AIServiceError.networkError
}