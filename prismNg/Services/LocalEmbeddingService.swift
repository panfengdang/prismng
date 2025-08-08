//
//  LocalEmbeddingService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import CoreML
import NaturalLanguage

// MARK: - Local Embedding Service
class LocalEmbeddingService {
    
    // MARK: - Properties
    private var embeddingModel: NLEmbedding?
    private var modelLoadingTask: Task<Void, Never>?
    
    // Cache for embeddings
    private var embeddingCache: [String: [Float]] = [:]
    private let cacheLimit = 1000
    
    // MARK: - Initialization
    
    init() {
        loadModel()
    }
    
    // MARK: - Model Loading
    
    private func loadModel() {
        modelLoadingTask = Task {
            // Load Apple's built-in word embedding model
            // Note: NLEmbedding supports word embeddings, not sentence embeddings
            embeddingModel = NLEmbedding.wordEmbedding(for: .english)
            if embeddingModel != nil {
                print("Loaded word embedding model for English")
            } else {
                print("Failed to load embedding model")
            }
        }
    }
    
    // MARK: - Embedding Generation
    
    func generateEmbedding(for text: String) async -> [Float]? {
        // Check cache first
        if let cached = embeddingCache[text] {
            return cached
        }
        
        // Wait for model to load
        await modelLoadingTask?.value
        
        guard let model = embeddingModel else {
            print("Embedding model not available")
            return nil
        }
        
        // Generate embedding
        guard let vector = model.vector(for: text.lowercased()) else {
            // If sentence embedding fails, try averaging word embeddings
            return generateWordAverageEmbedding(for: text, using: model)
        }
        
        // Convert to Float array
        let embedding = (0..<vector.count).map { Float(vector[$0]) }
        
        // Cache the result
        cacheEmbedding(embedding, for: text)
        
        return embedding
    }
    
    private func generateWordAverageEmbedding(for text: String, using model: NLEmbedding) -> [Float]? {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        guard !words.isEmpty else { return nil }
        
        var sumVector: [Float]?
        var validWordCount = 0
        
        for word in words {
            if let wordVector = model.vector(for: word.lowercased()) {
                if sumVector == nil {
                    sumVector = Array(repeating: 0.0, count: wordVector.count)
                }
                
                for i in 0..<wordVector.count {
                    sumVector![i] += Float(wordVector[i])
                }
                validWordCount += 1
            }
        }
        
        guard let sum = sumVector, validWordCount > 0 else { return nil }
        
        // Average the vectors
        return sum.map { $0 / Float(validWordCount) }
    }
    
    // MARK: - Similarity Calculation
    
    func calculateSimilarity(between embedding1: [Float], and embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else { return 0.0 }
        
        // Cosine similarity
        var dotProduct: Float = 0.0
        var norm1: Float = 0.0
        var norm2: Float = 0.0
        
        for i in 0..<embedding1.count {
            dotProduct += embedding1[i] * embedding2[i]
            norm1 += embedding1[i] * embedding1[i]
            norm2 += embedding2[i] * embedding2[i]
        }
        
        let denominator = sqrt(norm1) * sqrt(norm2)
        guard denominator > 0 else { return 0.0 }
        
        return dotProduct / denominator
    }
    
    // MARK: - Batch Processing
    
    func generateEmbeddings(for texts: [String]) async -> [String: [Float]] {
        var results: [String: [Float]] = [:]
        
        // Process in parallel with limited concurrency
        await withTaskGroup(of: (String, [Float]?).self) { group in
            for text in texts {
                group.addTask {
                    let embedding = await self.generateEmbedding(for: text)
                    return (text, embedding)
                }
            }
            
            for await (text, embedding) in group {
                if let embedding = embedding {
                    results[text] = embedding
                }
            }
        }
        
        return results
    }
    
    // MARK: - Cache Management
    
    private func cacheEmbedding(_ embedding: [Float], for text: String) {
        // Implement LRU cache if needed
        if embeddingCache.count >= cacheLimit {
            // Remove oldest entry (simple implementation)
            if let firstKey = embeddingCache.keys.first {
                embeddingCache.removeValue(forKey: firstKey)
            }
        }
        
        embeddingCache[text] = embedding
    }
    
    func clearCache() {
        embeddingCache.removeAll()
    }
    
    // MARK: - Preprocessing
    
    func preprocessText(_ text: String) -> String {
        // Basic text preprocessing
        let processed = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return processed
    }
}

// MARK: - Local Vector Search
class LocalVectorSearch {
    
    struct SearchResult {
        let nodeId: UUID
        let similarity: Float
        let content: String
    }
    
    private let embeddingService: LocalEmbeddingService
    private var nodeEmbeddings: [UUID: [Float]] = [:]
    
    init(embeddingService: LocalEmbeddingService) {
        self.embeddingService = embeddingService
    }
    
    // MARK: - Index Management
    
    func indexNode(_ node: ThoughtNode) async {
        let processedContent = embeddingService.preprocessText(node.content)
        
        if let embedding = await embeddingService.generateEmbedding(for: processedContent) {
            nodeEmbeddings[node.id] = embedding
            
            // Mark node as having embedding
            node.hasEmbedding = true
            node.embeddingVersion = "local-v1"
        }
    }
    
    func indexNodes(_ nodes: [ThoughtNode]) async {
        await withTaskGroup(of: Void.self) { group in
            for node in nodes {
                group.addTask {
                    await self.indexNode(node)
                }
            }
        }
    }
    
    func removeNode(_ nodeId: UUID) {
        nodeEmbeddings.removeValue(forKey: nodeId)
    }
    
    // MARK: - Search
    
    func search(query: String, limit: Int = 10) async -> [SearchResult] {
        let processedQuery = embeddingService.preprocessText(query)
        
        guard let queryEmbedding = await embeddingService.generateEmbedding(for: processedQuery) else {
            return []
        }
        
        return searchByEmbedding(queryEmbedding, limit: limit)
    }
    
    func searchByEmbedding(_ queryEmbedding: [Float], limit: Int = 10) -> [SearchResult] {
        var results: [(UUID, Float)] = []
        
        for (nodeId, embedding) in nodeEmbeddings {
            let similarity = embeddingService.calculateSimilarity(
                between: queryEmbedding,
                and: embedding
            )
            results.append((nodeId, similarity))
        }
        
        // Sort by similarity descending
        results.sort { $0.1 > $1.1 }
        
        // Return top results
        return results.prefix(limit).compactMap { nodeId, similarity in
            SearchResult(
                nodeId: nodeId,
                similarity: similarity,
                content: "" // Content would be fetched from node
            )
        }
    }
    
    func findSimilar(to nodeId: UUID, limit: Int = 5) -> [SearchResult] {
        guard let embedding = nodeEmbeddings[nodeId] else {
            return []
        }
        
        var results = searchByEmbedding(embedding, limit: limit + 1)
        
        // Remove the query node itself
        results.removeAll { $0.nodeId == nodeId }
        
        return Array(results.prefix(limit))
    }
    
    // MARK: - Clustering
    
    func findClusters(minSimilarity: Float = 0.7) -> [[UUID]] {
        var clusters: [[UUID]] = []
        var assigned: Set<UUID> = []
        
        for (nodeId, embedding) in nodeEmbeddings {
            if assigned.contains(nodeId) { continue }
            
            var cluster = [nodeId]
            assigned.insert(nodeId)
            
            // Find all similar nodes
            for (otherId, otherEmbedding) in nodeEmbeddings {
                if otherId == nodeId || assigned.contains(otherId) { continue }
                
                let similarity = embeddingService.calculateSimilarity(
                    between: embedding,
                    and: otherEmbedding
                )
                
                if similarity >= minSimilarity {
                    cluster.append(otherId)
                    assigned.insert(otherId)
                }
            }
            
            if cluster.count > 1 {
                clusters.append(cluster)
            }
        }
        
        return clusters
    }
}

// MARK: - Similarity Search Kit Integration (Future)
// Note: SimilaritySearchKit will be integrated in a future update
// For now, we use our local vector search implementation

/*
import SimilaritySearchKit
import SimilaritySearchKitDistanceMetrics
*/

class SimilaritySearchService {
    private var index: Any? // SimilarityIndex?
    private let embeddingService: LocalEmbeddingService
    
    init(embeddingService: LocalEmbeddingService) {
        self.embeddingService = embeddingService
    }
    
    func createIndex(dimensions: Int) {
        // Future implementation with SimilaritySearchKit
        /*
        index = SimilarityIndex(
            name: "thoughts",
            dimensions: dimensions,
            metric: CosineSimilarity(),
            indexType: .hnsw(m: 16, ef: 200, efConstruction: 200, seed: 42)
        )
        */
        print("SimilaritySearchKit index creation will be implemented in future update")
    }
    
    func addItem(_ nodeId: UUID, embedding: [Float]) {
        // Future implementation with SimilaritySearchKit
        /*
        guard let index = index else { return }
        
        let item = SimilarityIndex.Item(
            id: nodeId.uuidString,
            text: nil,
            embedding: embedding
        )
        
        index.addItem(item)
        */
        print("SimilaritySearchKit item addition will be implemented in future update")
    }
    
    func search(embedding: [Float], limit: Int = 10) -> [(String, Float)] {
        // Future implementation with SimilaritySearchKit
        /*
        guard let index = index else { return [] }
        
        let results = index.search(
            embedding,
            topK: limit,
            filterIds: nil
        )
        
        return results.map { ($0.id, $0.score) }
        */
        return []
    }
}