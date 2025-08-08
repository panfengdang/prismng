//
//  VectorDBService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation

// MARK: - Vector Database Protocol
protocol VectorDBServiceProtocol {
    func addVector(_ vector: [Float], for nodeId: UUID) async throws
    func removeVector(for nodeId: UUID) async throws
    func findSimilar(to nodeId: UUID, limit: Int) async throws -> [UUID]
    func findSimilarByVector(_ vector: [Float], limit: Int) async throws -> [LocalVectorSearchResult]
    func updateVector(_ vector: [Float], for nodeId: UUID) async throws
}

// MARK: - Main Vector Database Service
@MainActor
class VectorDBService: VectorDBServiceProtocol {
    
    // MARK: - Properties
    internal var vectorStore: [UUID: [Float]] = [:]
    internal let queue = DispatchQueue(label: "vector-db-queue", qos: .utility)
    private let persistenceKey = "VectorStore"
    
    // MARK: - Initialization
    init() {
        loadVectorStore()
    }
    
    // MARK: - Vector Operations
    func addVector(_ vector: [Float], for nodeId: UUID) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: VectorDBError.serviceUnavailable)
                    return
                }
                
                do {
                    self.vectorStore[nodeId] = vector
                    self.saveVectorStore()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func removeVector(for nodeId: UUID) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: VectorDBError.serviceUnavailable)
                    return
                }
                
                self.vectorStore.removeValue(forKey: nodeId)
                self.saveVectorStore()
                continuation.resume()
            }
        }
    }
    
    func updateVector(_ vector: [Float], for nodeId: UUID) async throws {
        try await addVector(vector, for: nodeId)
    }
    
    // MARK: - Search Operations
    func findSimilar(to nodeId: UUID, limit: Int = 5) async throws -> [UUID] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: VectorDBError.serviceUnavailable)
                    return
                }
                
                guard let targetVector = self.vectorStore[nodeId] else {
                    continuation.resume(throwing: VectorDBError.vectorNotFound)
                    return
                }
                
                let results = self.computeSimilarities(to: targetVector, excluding: nodeId)
                let topResults = Array(results.prefix(limit))
                let nodeIds = topResults.map { $0.nodeId }
                
                continuation.resume(returning: nodeIds)
            }
        }
    }
    
    func findSimilarByVector(_ vector: [Float], limit: Int = 5) async throws -> [LocalVectorSearchResult] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: VectorDBError.serviceUnavailable)
                    return
                }
                
                let results = self.computeSimilarities(to: vector, excluding: nil)
                let topResults = Array(results.prefix(limit))
                
                continuation.resume(returning: topResults)
            }
        }
    }
    
    // MARK: - Similarity Computation
    private func computeSimilarities(to targetVector: [Float], excluding excludeId: UUID?) -> [LocalVectorSearchResult] {
        var results: [LocalVectorSearchResult] = []
        
        for (nodeId, vector) in vectorStore {
            if let excludeId = excludeId, nodeId == excludeId {
                continue
            }
            
            let similarity = cosineSimilarity(targetVector, vector)
            results.append(LocalVectorSearchResult(nodeId: nodeId, similarity: similarity))
        }
        
        // Sort by similarity (descending)
        results.sort { $0.similarity > $1.similarity }
        
        return results
    }
    
    internal func cosineSimilarity(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        guard vectorA.count == vectorB.count else { return 0.0 }
        
        let dotProduct = zip(vectorA, vectorB).reduce(0.0) { result, pair in
            result + pair.0 * pair.1
        }
        let magnitudeA = sqrt(vectorA.reduce(0.0) { $0 + $1 * $1 })
        let magnitudeB = sqrt(vectorB.reduce(0.0) { $0 + $1 * $1 })
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    // MARK: - Persistence
    private func loadVectorStore() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            if let data = UserDefaults.standard.data(forKey: self.persistenceKey),
               let decoded = try? JSONDecoder().decode([String: [Float]].self, from: data) {
                
                // Convert string keys back to UUIDs
                for (uuidString, vector) in decoded {
                    if let uuid = UUID(uuidString: uuidString) {
                        self.vectorStore[uuid] = vector
                    }
                }
            }
        }
    }
    
    private func saveVectorStore() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Convert UUID keys to strings for JSON serialization
            let stringKeyedStore = Dictionary(
                uniqueKeysWithValues: self.vectorStore.map { (key, value) in
                    (key.uuidString, value)
                }
            )
            
            if let encoded = try? JSONEncoder().encode(stringKeyedStore) {
                UserDefaults.standard.set(encoded, forKey: self.persistenceKey)
            }
        }
    }
    
    // MARK: - Utility Methods
    func getVectorCount() async -> Int {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                continuation.resume(returning: self?.vectorStore.count ?? 0)
            }
        }
    }
    
    func hasVector(for nodeId: UUID) async -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async { [weak self] in
                continuation.resume(returning: self?.vectorStore[nodeId] != nil)
            }
        }
    }
    
    func clearAllVectors() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: VectorDBError.serviceUnavailable)
                    return
                }
                
                self.vectorStore.removeAll()
                UserDefaults.standard.removeObject(forKey: self.persistenceKey)
                continuation.resume()
            }
        }
    }
    
    // MARK: - Advanced Search Operations
    func findClusters(minSimilarity: Float = 0.7) async throws -> [VectorCluster] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: VectorDBError.serviceUnavailable)
                    return
                }
                
                var clusters: [VectorCluster] = []
                var processed: Set<UUID> = []
                
                for (nodeId, vector) in self.vectorStore {
                    if processed.contains(nodeId) { continue }
                    
                    var clusterNodes: [UUID] = [nodeId]
                    processed.insert(nodeId)
                    
                    // Find similar nodes for this cluster
                    for (otherNodeId, otherVector) in self.vectorStore {
                        if processed.contains(otherNodeId) { continue }
                        
                        let similarity = self.cosineSimilarity(vector, otherVector)
                        if similarity >= minSimilarity {
                            clusterNodes.append(otherNodeId)
                            processed.insert(otherNodeId)
                        }
                    }
                    
                    if clusterNodes.count > 1 {
                        clusters.append(VectorCluster(
                            id: UUID(),
                            nodeIds: clusterNodes,
                            centerVector: vector,
                            averageSimilarity: minSimilarity
                        ))
                    }
                }
                
                continuation.resume(returning: clusters)
            }
        }
    }
    
    func findOutliers(threshold: Float = 0.3) async throws -> [UUID] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: VectorDBError.serviceUnavailable)
                    return
                }
                
                var outliers: [UUID] = []
                
                for (nodeId, vector) in self.vectorStore {
                    let similarities = self.computeSimilarities(to: vector, excluding: nodeId)
                    let maxSimilarity = similarities.first?.similarity ?? 0.0
                    
                    if maxSimilarity < threshold {
                        outliers.append(nodeId)
                    }
                }
                
                continuation.resume(returning: outliers)
            }
        }
    }
}

// MARK: - Enhanced Vector Database Service
class EnhancedVectorDBService: VectorDBService {
    
    // MARK: - Properties
    private var index: VectorIndex?
    private var indexType: VectorIndexType = .flat
    private let indexUpdateThreshold = 100 // Rebuild index after this many changes
    private var changesSinceIndexBuild = 0
    
    // MARK: - Advanced Features
    func performApproximateNearestNeighborSearch(
        vector: [Float],
        limit: Int,
        approximationFactor: Float = 0.1
    ) async throws -> [LocalVectorSearchResult] {
        // Use index-based search if available
        if let index = index {
            return try await index.search(vector: vector, limit: limit, approximationFactor: approximationFactor)
        }
        
        // Implement LSH-based approximate search
        return try await performLSHSearch(vector: vector, limit: limit, approximationFactor: approximationFactor)
    }
    
    private func performLSHSearch(vector: [Float], limit: Int, approximationFactor: Float) async throws -> [LocalVectorSearchResult] {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: VectorDBError.serviceUnavailable)
                    return
                }
                
                // Create hash buckets for LSH
                let numHashFunctions = max(1, Int(10 * approximationFactor))
                let buckets = self.createLSHBuckets(numHashFunctions: numHashFunctions)
                
                // Find candidate set using LSH
                let targetHashes = self.computeLSHHashes(vector: vector, numFunctions: numHashFunctions)
                var candidates = Set<UUID>()
                
                for hash in targetHashes {
                    if let bucket = buckets[hash] {
                        candidates.formUnion(bucket)
                    }
                }
                
                // Compute exact similarities for candidates only
                var results: [LocalVectorSearchResult] = []
                for nodeId in candidates {
                    if let candidateVector = self.vectorStore[nodeId] {
                        let similarity = self.cosineSimilarity(vector, candidateVector)
                        results.append(LocalVectorSearchResult(nodeId: nodeId, similarity: similarity))
                    }
                }
                
                // Sort and limit results
                results.sort { $0.similarity > $1.similarity }
                let topResults = Array(results.prefix(limit))
                
                continuation.resume(returning: topResults)
            }
        }
    }
    
    private func createLSHBuckets(numHashFunctions: Int) -> [Int: Set<UUID>] {
        var buckets: [Int: Set<UUID>] = [:]
        
        for (nodeId, vector) in vectorStore {
            let hashes = computeLSHHashes(vector: vector, numFunctions: numHashFunctions)
            for hash in hashes {
                buckets[hash, default: Set()].insert(nodeId)
            }
        }
        
        return buckets
    }
    
    private func computeLSHHashes(vector: [Float], numFunctions: Int) -> [Int] {
        var hashes: [Int] = []
        
        for i in 0..<numFunctions {
            // Simple random projection LSH
            var hash = 0
            for (j, value) in vector.enumerated() {
                let randomProjection = Float(j + i * 1000).truncatingRemainder(dividingBy: 2.0) - 1.0
                if value * randomProjection > 0 {
                    hash = hash | (1 << (j % 32))
                }
            }
            hashes.append(hash)
        }
        
        return hashes
    }
    
    func createIndex(indexType: VectorIndexType = .ivf) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: VectorDBError.serviceUnavailable)
                    return
                }
                
                self.indexType = indexType
                
                switch indexType {
                case .flat:
                    self.index = FlatIndex(vectorStore: self.vectorStore)
                case .ivf:
                    self.index = IVFIndex(vectorStore: self.vectorStore, numClusters: 10)
                case .hnsw:
                    self.index = HNSWIndex(vectorStore: self.vectorStore, m: 16, efConstruction: 200)
                }
                
                self.changesSinceIndexBuild = 0
                print("✅ Created vector index of type: \(indexType)")
                continuation.resume()
            }
        }
    }
    
    override func addVector(_ vector: [Float], for nodeId: UUID) async throws {
        try await super.addVector(vector, for: nodeId)
        
        // Update index if needed
        changesSinceIndexBuild += 1
        if changesSinceIndexBuild > indexUpdateThreshold {
            try await createIndex(indexType: indexType)
        }
    }
    
    func getDimensionality() async -> Int {
        return await withCheckedContinuation { continuation in
            self.queue.async { [weak self] in
                let firstVector = self?.vectorStore.values.first
                continuation.resume(returning: firstVector?.count ?? 0)
            }
        }
    }
}

// MARK: - Supporting Types

struct LocalVectorSearchResult {
    let nodeId: UUID
    let similarity: Float
}

struct VectorCluster {
    let id: UUID
    let nodeIds: [UUID]
    let centerVector: [Float]
    let averageSimilarity: Float
}

enum VectorIndexType {
    case flat       // Exhaustive search
    case ivf        // Inverted file index
    case hnsw       // Hierarchical Navigable Small World
}

// MARK: - Vector Index Protocol
protocol VectorIndex {
    func search(vector: [Float], limit: Int, approximationFactor: Float) async throws -> [LocalVectorSearchResult]
}

// MARK: - Flat Index Implementation
class FlatIndex: VectorIndex {
    private let vectorStore: [UUID: [Float]]
    
    init(vectorStore: [UUID: [Float]]) {
        self.vectorStore = vectorStore
    }
    
    func search(vector: [Float], limit: Int, approximationFactor: Float) async throws -> [LocalVectorSearchResult] {
        var results: [LocalVectorSearchResult] = []
        
        for (nodeId, storedVector) in vectorStore {
            let similarity = cosineSimilarity(vector, storedVector)
            results.append(LocalVectorSearchResult(nodeId: nodeId, similarity: similarity))
        }
        
        results.sort { $0.similarity > $1.similarity }
        return Array(results.prefix(limit))
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        let dot = zip(a, b).reduce(0.0) { result, pair in result + pair.0 * pair.1 }
        let magA = sqrt(a.reduce(0.0) { $0 + $1 * $1 })
        let magB = sqrt(b.reduce(0.0) { $0 + $1 * $1 })
        return magA > 0 && magB > 0 ? dot / (magA * magB) : 0.0
    }
}

// MARK: - IVF Index Implementation
class IVFIndex: VectorIndex {
    private let vectorStore: [UUID: [Float]]
    private let numClusters: Int
    private var clusters: [VectorCluster] = []
    private var nodeToCluster: [UUID: Int] = [:]
    
    init(vectorStore: [UUID: [Float]], numClusters: Int) {
        self.vectorStore = vectorStore
        self.numClusters = numClusters
        buildClusters()
    }
    
    private func buildClusters() {
        // Simple k-means clustering
        guard !vectorStore.isEmpty else { return }
        
        let nodeIds = Array(vectorStore.keys)
        let k = min(numClusters, nodeIds.count)
        
        // Initialize cluster centers randomly
        var centers: [[Float]] = []
        for i in 0..<k {
            let randomNode = nodeIds[i % nodeIds.count]
            centers.append(vectorStore[randomNode]!)
        }
        
        // Assign nodes to nearest clusters
        for (nodeId, vector) in vectorStore {
            var bestCluster = 0
            var bestSimilarity: Float = -1
            
            for (i, center) in centers.enumerated() {
                let similarity = cosineSimilarity(vector, center)
                if similarity > bestSimilarity {
                    bestSimilarity = similarity
                    bestCluster = i
                }
            }
            
            nodeToCluster[nodeId] = bestCluster
        }
        
        // Create cluster objects
        for i in 0..<k {
            let clusterNodes = nodeIds.filter { nodeToCluster[$0] == i }
            if !clusterNodes.isEmpty {
                clusters.append(VectorCluster(
                    id: UUID(),
                    nodeIds: clusterNodes,
                    centerVector: centers[i],
                    averageSimilarity: 0.7
                ))
            }
        }
    }
    
    func search(vector: [Float], limit: Int, approximationFactor: Float) async throws -> [LocalVectorSearchResult] {
        // Find nearest clusters
        let numClustersToSearch = max(1, Int(Float(clusters.count) * approximationFactor))
        
        var clusterSimilarities: [(Int, Float)] = []
        for (i, cluster) in clusters.enumerated() {
            let similarity = cosineSimilarity(vector, cluster.centerVector)
            clusterSimilarities.append((i, similarity))
        }
        
        clusterSimilarities.sort { $0.1 > $1.1 }
        let clustersToSearch = Array(clusterSimilarities.prefix(numClustersToSearch))
        
        // Search within selected clusters
        var results: [LocalVectorSearchResult] = []
        for (clusterIdx, _) in clustersToSearch {
            let cluster = clusters[clusterIdx]
            for nodeId in cluster.nodeIds {
                if let nodeVector = vectorStore[nodeId] {
                    let similarity = cosineSimilarity(vector, nodeVector)
                    results.append(LocalVectorSearchResult(nodeId: nodeId, similarity: similarity))
                }
            }
        }
        
        results.sort { $0.similarity > $1.similarity }
        return Array(results.prefix(limit))
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        let dot = zip(a, b).reduce(0.0) { result, pair in result + pair.0 * pair.1 }
        let magA = sqrt(a.reduce(0.0) { $0 + $1 * $1 })
        let magB = sqrt(b.reduce(0.0) { $0 + $1 * $1 })
        return magA > 0 && magB > 0 ? dot / (magA * magB) : 0.0
    }
}

// MARK: - HNSW Index Implementation
class HNSWIndex: VectorIndex {
    private let vectorStore: [UUID: [Float]]
    private let m: Int // Number of connections per node
    private let efConstruction: Int // Size of dynamic candidate list
    private var layers: [Int: [UUID: Set<UUID>]] = [:] // Layer -> Node -> Neighbors
    private var nodeLayer: [UUID: Int] = [:]
    
    init(vectorStore: [UUID: [Float]], m: Int, efConstruction: Int) {
        self.vectorStore = vectorStore
        self.m = m
        self.efConstruction = efConstruction
        buildIndex()
    }
    
    private func buildIndex() {
        for (nodeId, _) in vectorStore {
            // Assign layer with exponential decay probability
            let layer = selectLayer()
            nodeLayer[nodeId] = layer
            
            // Add connections at each layer
            for l in 0...layer {
                if layers[l] == nil {
                    layers[l] = [:]
                }
                layers[l]![nodeId] = Set()
                
                // Connect to M nearest neighbors at this layer
                let neighbors = findNearestAtLayer(nodeId: nodeId, layer: l, k: m)
                for neighbor in neighbors {
                    layers[l]![nodeId]!.insert(neighbor)
                    layers[l]![neighbor, default: Set()].insert(nodeId)
                }
            }
        }
    }
    
    private func selectLayer() -> Int {
        var layer = 0
        while Double.random(in: 0...1) < 0.5 && layer < 16 {
            layer += 1
        }
        return layer
    }
    
    private func findNearestAtLayer(nodeId: UUID, layer: Int, k: Int) -> [UUID] {
        guard let targetVector = vectorStore[nodeId] else { return [] }
        
        var candidates: [(UUID, Float)] = []
        for (otherNodeId, _) in layers[layer] ?? [:] {
            if otherNodeId != nodeId, let otherVector = vectorStore[otherNodeId] {
                let similarity = cosineSimilarity(targetVector, otherVector)
                candidates.append((otherNodeId, similarity))
            }
        }
        
        candidates.sort { $0.1 > $1.1 }
        return Array(candidates.prefix(k).map { $0.0 })
    }
    
    func search(vector: [Float], limit: Int, approximationFactor: Float) async throws -> [LocalVectorSearchResult] {
        var visited = Set<UUID>()
        var candidates: [(UUID, Float)] = []
        var w: [(UUID, Float)] = []
        
        // Start from entry point (highest layer)
        let maxLayer = layers.keys.max() ?? 0
        guard let entryPoints = layers[maxLayer]?.keys.first else { return [] }
        
        // Search from top layer to bottom
        for layer in (0...maxLayer).reversed() {
            candidates = searchLayer(vector: vector, entryPoints: [entryPoints], layer: layer, ef: efConstruction)
            
            if layer == 0 {
                // Final layer - return results
                w = candidates
            }
        }
        
        // Convert to results
        let results = w.map { LocalVectorSearchResult(nodeId: $0.0, similarity: $0.1) }
            .sorted { $0.similarity > $1.similarity }
        
        return Array(results.prefix(limit))
    }
    
    private func searchLayer(vector: [Float], entryPoints: [UUID], layer: Int, ef: Int) -> [(UUID, Float)] {
        var visited = Set<UUID>()
        var candidates = [(UUID, Float)]()
        var w = [(UUID, Float)]()
        
        for ep in entryPoints {
            if let epVector = vectorStore[ep] {
                let similarity = cosineSimilarity(vector, epVector)
                candidates.append((ep, similarity))
                w.append((ep, similarity))
                visited.insert(ep)
            }
        }
        
        while !candidates.isEmpty {
            candidates.sort { $0.1 < $1.1 } // Min heap by distance (1 - similarity)
            let (current, currentSim) = candidates.removeFirst()
            
            if currentSim < w.min(by: { $0.1 < $1.1 })?.1 ?? 0 {
                break
            }
            
            // Check neighbors
            for neighbor in layers[layer]?[current] ?? [] {
                if !visited.contains(neighbor), let neighborVector = vectorStore[neighbor] {
                    visited.insert(neighbor)
                    let similarity = cosineSimilarity(vector, neighborVector)
                    
                    if similarity > w.min(by: { $0.1 < $1.1 })?.1 ?? 0 || w.count < ef {
                        candidates.append((neighbor, similarity))
                        w.append((neighbor, similarity))
                        
                        if w.count > ef {
                            w.sort { $0.1 > $1.1 }
                            w.removeLast()
                        }
                    }
                }
            }
        }
        
        return w
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        let dot = zip(a, b).reduce(0.0) { result, pair in result + pair.0 * pair.1 }
        let magA = sqrt(a.reduce(0.0) { $0 + $1 * $1 })
        let magB = sqrt(b.reduce(0.0) { $0 + $1 * $1 })
        return magA > 0 && magB > 0 ? dot / (magA * magB) : 0.0
    }
}

// MARK: - Errors
enum VectorDBError: Error {
    case serviceUnavailable
    case vectorNotFound
    case dimensionMismatch
    case indexNotBuilt
    case persistenceError
    
    var localizedDescription: String {
        switch self {
        case .serviceUnavailable:
            return "Vector database service unavailable"
        case .vectorNotFound:
            return "Vector not found"
        case .dimensionMismatch:
            return "Vector dimensions do not match"
        case .indexNotBuilt:
            return "Vector index has not been built"
        case .persistenceError:
            return "Error persisting vector data"
        }
    }
}

// MARK: - Mock SimilaritySearchKit Compatibility Layer
// This provides compatibility with the planned SimilaritySearchKit integration
extension VectorDBService {
    
    func addToSimilaritySearchKit(_ vector: [Float], for nodeId: UUID) async throws {
        // In the future, this would integrate with actual SimilaritySearchKit
        try await addVector(vector, for: nodeId)
    }
    
    func searchWithSimilaritySearchKit(vector: [Float], k: Int) async throws -> [LocalVectorSearchResult] {
        // In the future, this would use SimilaritySearchKit's optimized search
        return try await findSimilarByVector(vector, limit: k)
    }
}