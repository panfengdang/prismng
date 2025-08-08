//
//  CoreMLEmbeddingService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import CoreML
import NaturalLanguage
import Accelerate

// MARK: - Core ML Embedding Service
@MainActor
class CoreMLEmbeddingService: ObservableObject {
    
    // MARK: - Properties
    @Published var isModelLoaded = false
    @Published var isProcessing = false
    @Published var embeddingDimension = 384 // Default dimension
    
    private var embeddingModel: NLEmbedding?
    private let textProcessor = NLTextProcessor()
    private let embeddingCache = NSCache<NSString, NSData>()
    
    // MARK: - Initialization
    init() {
        Task {
            await loadModel()
        }
    }
    
    // MARK: - Model Loading
    private func loadModel() async {
        // For MVP, use Apple's built-in word embeddings
        // In production, we would load a custom Core ML model for sentence embeddings
        embeddingModel = NLEmbedding.wordEmbedding(for: .english)
        
        if embeddingModel != nil {
            isModelLoaded = true
            print("✅ Core ML embedding model loaded successfully")
        } else {
            print("❌ Failed to load Core ML embedding model")
        }
    }
    
    // MARK: - Embedding Generation
    func generateEmbedding(for text: String) async -> [Float]? {
        // Check cache first
        let cacheKey = text as NSString
        if let cachedData = embeddingCache.object(forKey: cacheKey),
           let embedding = try? JSONDecoder().decode([Float].self, from: cachedData as Data) {
            return embedding
        }
        
        guard isModelLoaded, let model = embeddingModel else {
            print("❌ Model not loaded, cannot generate embedding")
            return nil
        }
        
        isProcessing = true
        defer { isProcessing = false }
        
        // Preprocess text
        let processedText = textProcessor.preprocess(text)
        
        // Generate embedding
        let embedding = await generateSentenceEmbedding(for: processedText, using: model)
        
        // Cache the result
        if let embedding = embedding,
           let data = try? JSONEncoder().encode(embedding) {
            embeddingCache.setObject(data as NSData, forKey: cacheKey)
        }
        
        return embedding
    }
    
    // MARK: - Sentence Embedding Generation
    private func generateSentenceEmbedding(for text: String, using model: NLEmbedding) async -> [Float]? {
        // Tokenize text into words
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
        
        guard !words.isEmpty else { return nil }
        
        // Get embeddings for each word
        var wordEmbeddings: [[Float]] = []
        var weights: [Float] = []
        
        for (index, word) in words.enumerated() {
            if let vector = model.vector(for: word) {
                // Convert to Float array
                let floatVector = (0..<vector.count).map { Float(vector[$0]) }
                wordEmbeddings.append(floatVector)
                
                // Use position-aware weighting
                let weight = computeWordWeight(word: word, position: index, totalWords: words.count)
                weights.append(weight)
            }
        }
        
        guard !wordEmbeddings.isEmpty else { return nil }
        
        // Compute weighted average of word embeddings
        let sentenceEmbedding = computeWeightedAverage(embeddings: wordEmbeddings, weights: weights)
        
        // Normalize the embedding
        return normalizeVector(sentenceEmbedding)
    }
    
    // MARK: - Helper Methods
    private func computeWordWeight(word: String, position: Int, totalWords: Int) -> Float {
        // Simple TF-IDF inspired weighting
        var weight: Float = 1.0
        
        // Common words get lower weight
        let commonWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "from", "as", "is", "was", "are", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "can", "shall"])
        
        if commonWords.contains(word) {
            weight *= 0.3
        }
        
        // Position-based weighting (beginning and end of sentence more important)
        let positionWeight = 1.0 + 0.2 * exp(-pow(Float(position - totalWords/2), 2) / Float(totalWords))
        weight *= positionWeight
        
        return weight
    }
    
    private func computeWeightedAverage(embeddings: [[Float]], weights: [Float]) -> [Float] {
        guard let firstEmbedding = embeddings.first else { return [] }
        let dimension = firstEmbedding.count
        
        var result = Array(repeating: Float(0), count: dimension)
        var totalWeight: Float = 0
        
        for (embedding, weight) in zip(embeddings, weights) {
            for i in 0..<dimension {
                result[i] += embedding[i] * weight
            }
            totalWeight += weight
        }
        
        // Normalize by total weight
        if totalWeight > 0 {
            for i in 0..<dimension {
                result[i] /= totalWeight
            }
        }
        
        return result
    }
    
    private func normalizeVector(_ vector: [Float]) -> [Float] {
        let magnitude = sqrt(vector.reduce(0) { $0 + $1 * $1 })
        guard magnitude > 0 else { return vector }
        return vector.map { $0 / magnitude }
    }
    
    // MARK: - Batch Processing
    func generateEmbeddings(for texts: [String]) async -> [UUID: [Float]] {
        var results: [UUID: [Float]] = [:]
        
        await withTaskGroup(of: (UUID, [Float]?).self) { group in
            for text in texts {
                let id = UUID()
                group.addTask {
                    let embedding = await self.generateEmbedding(for: text)
                    return (id, embedding)
                }
            }
            
            for await (id, embedding) in group {
                if let embedding = embedding {
                    results[id] = embedding
                }
            }
        }
        
        return results
    }
    
    // MARK: - Similarity Calculation
    func calculateSimilarity(between embedding1: [Float], and embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else { return 0.0 }
        
        // Use Accelerate framework for optimized computation
        var similarity: Float = 0
        vDSP_dotpr(embedding1, 1, embedding2, 1, &similarity, vDSP_Length(embedding1.count))
        
        return similarity
    }
}

// MARK: - Text Processor
class NLTextProcessor {
    
    func preprocess(_ text: String) -> String {
        var processed = text
        
        // Remove extra whitespace
        processed = processed.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Remove special characters but keep sentence structure
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(.punctuationCharacters)
        processed = processed.components(separatedBy: allowedCharacters.inverted).joined()
        
        // Trim
        processed = processed.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Limit length to prevent excessive processing
        if processed.count > 1000 {
            processed = String(processed.prefix(1000))
        }
        
        return processed
    }
    
    func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text
        
        var keywords: [String] = []
        let range = text.startIndex..<text.endIndex
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag,
               tag == .noun || tag == .verb || tag == .adjective {
                let word = String(text[tokenRange])
                keywords.append(word.lowercased())
            }
            return true
        }
        
        return Array(Set(keywords)) // Remove duplicates
    }
}

// MARK: - Embedding Manager
class EmbeddingManager: ObservableObject {
    @Published var embeddingService: CoreMLEmbeddingService
    @Published var vectorDB: VectorDBService
    @Published var isIndexing = false
    @Published var indexedNodeCount = 0
    
    init(embeddingService: CoreMLEmbeddingService, vectorDB: VectorDBService) {
        self.embeddingService = embeddingService
        self.vectorDB = vectorDB
    }
    
    // MARK: - Node Indexing
    func indexNode(_ node: ThoughtNode) async {
        guard !node.content.isEmpty else { return }
        
        if let embedding = await embeddingService.generateEmbedding(for: node.content) {
            do {
                try await vectorDB.addVector(embedding, for: node.id)
                node.hasEmbedding = true
                node.embeddingVersion = "coreml-v1"
            } catch {
                print("❌ Failed to index node \(node.id): \(error)")
            }
        }
    }
    
    func indexNodes(_ nodes: [ThoughtNode]) async {
        isIndexing = true
        defer { isIndexing = false }
        
        var indexed = 0
        
        for node in nodes {
            if !node.hasEmbedding {
                await indexNode(node)
                indexed += 1
                indexedNodeCount = indexed
            }
        }
    }
    
    // MARK: - Semantic Search
    func semanticSearch(query: String, limit: Int = 10) async -> [VectorSearchResult] {
        guard let queryEmbedding = await embeddingService.generateEmbedding(for: query) else {
            return []
        }
        
        do {
            let localResults = try await vectorDB.findSimilarByVector(queryEmbedding, limit: limit)
            // Convert LocalVectorSearchResult to VectorSearchResult
            return localResults.map { result in
                VectorSearchResult(
                    id: UUID(),
                    nodeId: result.nodeId,
                    content: "", // Content will need to be loaded separately
                    similarity: Double(result.similarity),
                    relevanceScore: Double(result.similarity),
                    highlightedContent: AttributedString(""),
                    contextSnippet: "",
                    explanation: "Semantic similarity: \(String(format: "%.2f", result.similarity * 100))%",
                    relatedNodes: [],
                    metadata: VectorMetadata(
                        from: ThoughtNode(content: "")
                    )
                )
            }
        } catch {
            print("❌ Semantic search failed: \(error)")
            return []
        }
    }
    
    func findSimilarNodes(to node: ThoughtNode, limit: Int = 5) async -> [UUID] {
        do {
            return try await vectorDB.findSimilar(to: node.id, limit: limit)
        } catch {
            print("❌ Failed to find similar nodes: \(error)")
            return []
        }
    }
    
    // MARK: - Real-time Indexing
    func startRealtimeIndexing(for nodes: [ThoughtNode]) {
        Task {
            // Index existing nodes without embeddings
            let unindexedNodes = nodes.filter { !$0.hasEmbedding }
            if !unindexedNodes.isEmpty {
                await indexNodes(unindexedNodes)
            }
        }
    }
}