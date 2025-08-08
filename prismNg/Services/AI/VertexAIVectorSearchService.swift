//
//  VertexAIVectorSearchService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP2-4: Vertex AI Vector Search - 专属高级功能全局深度搜索
//

import Foundation
import SwiftUI
import Combine
import SwiftData

// MARK: - Vector Search Service

/// Vertex AI Vector Search服务，为Pro用户提供全局深度搜索功能
@MainActor
class VertexAIVectorSearchService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isSearching = false
    @Published var searchResults: [VectorSearchResult] = []
    @Published var searchHistory: [SearchHistoryItem] = []
    @Published var searchMetrics: SearchMetrics = SearchMetrics()
    @Published var errorMessage: String?
    @Published var isProFeature = true
    
    // MARK: - Private Properties
    private let firebaseAIService: FirebaseFunctionsAIService
    private let storeKitService: StoreKitService
    private let creditsService: AICreditsService
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    // Search configuration
    private let maxResultsPerSearch = 50
    private let minSimilarityThreshold = 0.7
    private let searchDebounceInterval: TimeInterval = 0.3
    private var searchDebounceTimer: Timer?
    
    // Vector index metadata
    private var indexMetadata: VectorIndexMetadata?
    private let vectorDimensions = 768 // Gemini embedding dimensions
    
    // MARK: - Initialization
    
    init(firebaseAIService: FirebaseFunctionsAIService,
         storeKitService: StoreKitService,
         creditsService: AICreditsService) {
        self.firebaseAIService = firebaseAIService
        self.storeKitService = storeKitService
        self.creditsService = creditsService
        
        setupSubscriptionObserver()
        loadSearchHistory()
    }
    
    func setup(with modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await initializeVectorIndex()
        }
    }
    
    // MARK: - Subscription Observer
    
    private func setupSubscriptionObserver() {
        storeKitService.$currentSubscription
            .sink { [weak self] _ in
                self?.checkProAccess()
            }
            .store(in: &cancellables)
    }
    
    private func checkProAccess() {
        let tier = storeKitService.currentTier()
        isProFeature = tier == .advanced || tier == .professional
    }
    
    // MARK: - Vector Index Management
    
    /// 初始化向量索引
    private func initializeVectorIndex() async {
        guard isProFeature else { return }
        
        do {
            // Check if index exists in Vertex AI
            indexMetadata = await checkOrCreateVectorIndex()
            
            // Index local nodes if needed
            if let metadata = indexMetadata, metadata.needsReindexing {
                await indexLocalNodes()
            }
        } catch {
            errorMessage = "初始化向量索引失败: \(error.localizedDescription)"
        }
    }
    
    /// 检查或创建向量索引
    private func checkOrCreateVectorIndex() async -> VectorIndexMetadata? {
        // In real implementation, this would call Vertex AI to check/create index
        return VectorIndexMetadata(
            indexId: "prismng-vector-index",
            vectorCount: 0,
            lastUpdated: Date(),
            needsReindexing: true
        )
    }
    
    /// 索引本地节点
    private func indexLocalNodes() async {
        guard let modelContext = modelContext else { return }
        
        do {
            let descriptor = FetchDescriptor<ThoughtNode>()
            let nodes = try modelContext.fetch(descriptor)
            
            // Batch process nodes for embedding generation
            for batch in nodes.chunked(into: 10) {
                await indexNodeBatch(batch)
            }
            
            searchMetrics.totalIndexedNodes = nodes.count
            indexMetadata?.needsReindexing = false
        } catch {
            errorMessage = "索引节点失败: \(error.localizedDescription)"
        }
    }
    
    private func indexNodeBatch(_ nodes: [ThoughtNode]) async {
        for node in nodes {
            guard !node.hasEmbedding else { continue }
            
            do {
                // Generate embedding via Firebase Functions
                let embedding = try await firebaseAIService.generateEmbedding(for: node.content)
                
                // Store embedding in Vertex AI Vector Search
                await storeEmbedding(
                    nodeId: node.id,
                    embedding: embedding,
                    metadata: VectorMetadata(from: node)
                )
                
                // Update node to mark as indexed
                node.hasEmbedding = true
                node.embeddingVersion = "gemini-1.5-pro"
                
                searchMetrics.embeddingsGenerated += 1
            } catch {
                print("❌ Failed to index node \(node.id): \(error)")
            }
        }
        
        try? modelContext?.save()
    }
    
    // MARK: - Search Operations
    
    /// 执行全局深度搜索
    func performGlobalSearch(_ query: String, searchMode: SearchMode = .semantic) async {
        guard isProFeature else {
            errorMessage = "全局深度搜索是高级功能"
            return
        }
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        do {
            // Check AI credits
            let creditsCost = searchMode == .hybrid ? 10 : 8
            guard creditsService.canAfford(feature: "deep_search") else {
                throw SearchError.insufficientCredits
            }
            
            // Generate query embedding
            let queryEmbedding = try await firebaseAIService.generateEmbedding(for: query)
            
            // Perform vector search
            let results = try await performVectorSearch(
                embedding: queryEmbedding,
                query: query,
                mode: searchMode
            )
            
            // Process and rank results
            let rankedResults = await processSearchResults(results, query: query)
            
            // Update UI
            searchResults = rankedResults
            
            // Consume credits
            try await creditsService.consumeCredits(for: "deep_search", amount: creditsCost)
            
            // Add to search history
            addToSearchHistory(query: query, resultCount: rankedResults.count)
            
            // Update metrics
            searchMetrics.totalSearches += 1
            searchMetrics.averageResultCount = 
                (searchMetrics.averageResultCount * Double(searchMetrics.totalSearches - 1) + Double(rankedResults.count)) 
                / Double(searchMetrics.totalSearches)
            
        } catch {
            errorMessage = error.localizedDescription
            searchResults = []
        }
        
        isSearching = false
    }
    
    /// 执行向量搜索
    private func performVectorSearch(embedding: [Float], query: String, mode: SearchMode) async throws -> [RawSearchResult] {
        // In real implementation, this would call Vertex AI Vector Search API
        
        // Simulate search results
        guard let modelContext = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<ThoughtNode>()
        let allNodes = try modelContext.fetch(descriptor)
        
        // For demo, return random nodes as results
        let sampleResults = allNodes.prefix(20).map { node in
            RawSearchResult(
                nodeId: node.id,
                content: node.content,
                similarity: Double.random(in: 0.7...0.95),
                metadata: VectorMetadata(from: node)
            )
        }
        
        return sampleResults
    }
    
    /// 处理搜索结果
    private func processSearchResults(_ rawResults: [RawSearchResult], query: String) async -> [VectorSearchResult] {
        var processedResults: [VectorSearchResult] = []
        
        for rawResult in rawResults {
            // Enhance with AI analysis
            let analysis = await analyzeSearchResult(rawResult, query: query)
            
            let result = VectorSearchResult(
                id: UUID(),
                nodeId: rawResult.nodeId,
                content: rawResult.content,
                similarity: rawResult.similarity,
                relevanceScore: calculateRelevanceScore(rawResult, analysis: analysis),
                highlightedContent: generateHighlightedContent(rawResult.content, query: query),
                contextSnippet: analysis.contextSnippet,
                explanation: analysis.explanation,
                relatedNodes: analysis.relatedNodeIds,
                metadata: rawResult.metadata
            )
            
            processedResults.append(result)
        }
        
        // Sort by relevance score
        return processedResults.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    private func analyzeSearchResult(_ result: RawSearchResult, query: String) async -> SearchResultAnalysis {
        // In real implementation, this would use AI to analyze relevance
        return SearchResultAnalysis(
            contextSnippet: String(result.content.prefix(100)) + "...",
            explanation: "该节点与搜索查询 '\(query)' 高度相关",
            relatedNodeIds: []
        )
    }
    
    private func calculateRelevanceScore(_ result: RawSearchResult, analysis: SearchResultAnalysis) -> Double {
        // Combine similarity score with other factors
        let baseScore = result.similarity
        let recencyBoost = result.metadata.recencyScore * 0.1
        let emotionalBoost = result.metadata.hasEmotionalMarker ? 0.05 : 0
        
        return min(baseScore + recencyBoost + emotionalBoost, 1.0)
    }
    
    private func generateHighlightedContent(_ content: String, query: String) -> AttributedString {
        var attributed = AttributedString(content)
        
        // Simple keyword highlighting
        if let range = content.range(of: query, options: .caseInsensitive) {
            let nsRange = NSRange(range, in: content)
            if let attributedRange = Range(nsRange, in: attributed) {
                attributed[attributedRange].backgroundColor = .yellow.opacity(0.3)
                attributed[attributedRange].font = .body.bold()
            }
        }
        
        return attributed
    }
    
    // MARK: - Advanced Search Features
    
    /// 多模态搜索（文本+情感+时间）
    func performMultiModalSearch(
        textQuery: String?,
        emotionalFilter: EmotionalTag?,
        timeRange: DateInterval?,
        nodeTypes: Set<NodeType>?
    ) async {
        guard isProFeature else {
            errorMessage = "多模态搜索是高级功能"
            return
        }
        
        isSearching = true
        
        // Build composite query
        var compositeQuery = CompositeSearchQuery(
            textQuery: textQuery,
            emotionalFilter: emotionalFilter,
            timeRange: timeRange,
            nodeTypes: nodeTypes
        )
        
        do {
            // Generate embeddings for each modality
            if let text = textQuery {
                compositeQuery.textEmbedding = try await firebaseAIService.generateEmbedding(for: text)
            }
            
            // Perform multi-modal vector search
            let results = try await performMultiModalVectorSearch(compositeQuery)
            
            // Process results
            searchResults = await processSearchResults(results, query: textQuery ?? "多模态搜索")
            
            // Consume credits
            try await creditsService.consumeCredits(for: "deep_search", amount: 15)
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isSearching = false
    }
    
    private func performMultiModalVectorSearch(_ query: CompositeSearchQuery) async throws -> [RawSearchResult] {
        // Complex multi-modal search implementation
        return []
    }
    
    /// 搜索相似节点
    func findSimilarNodes(to node: ThoughtNode, limit: Int = 10) async -> [VectorSearchResult] {
        guard isProFeature else { return [] }
        
        do {
            // Get or generate embedding for the node
            let embedding: [Float]
            if node.hasEmbedding {
                // Fetch from vector store
                embedding = await fetchEmbedding(for: node.id) ?? []
            } else {
                // Generate new embedding
                embedding = try await firebaseAIService.generateEmbedding(for: node.content)
            }
            
            // Search for similar vectors
            let results = try await performVectorSearch(
                embedding: embedding,
                query: node.content,
                mode: .semantic
            )
            
            // Filter out the source node
            let filteredResults = results.filter { $0.nodeId != node.id }
            
            // Process results
            return await processSearchResults(Array(filteredResults.prefix(limit)), query: "相似节点")
            
        } catch {
            print("❌ Failed to find similar nodes: \(error)")
            return []
        }
    }
    
    // MARK: - Search History
    
    private func addToSearchHistory(query: String, resultCount: Int) {
        let historyItem = SearchHistoryItem(
            query: query,
            timestamp: Date(),
            resultCount: resultCount,
            searchMode: .semantic
        )
        
        searchHistory.insert(historyItem, at: 0)
        
        // Keep only recent 50 searches
        if searchHistory.count > 50 {
            searchHistory = Array(searchHistory.prefix(50))
        }
        
        saveSearchHistory()
    }
    
    private func loadSearchHistory() {
        // Load from UserDefaults or local storage
        searchHistory = []
    }
    
    private func saveSearchHistory() {
        // Save to UserDefaults or local storage
    }
    
    // MARK: - Helper Methods
    
    private func storeEmbedding(nodeId: UUID, embedding: [Float], metadata: VectorMetadata) async {
        // Store in Vertex AI Vector Search
        // This would make API call to Vertex AI
        print("📊 Storing embedding for node \(nodeId)")
    }
    
    private func fetchEmbedding(for nodeId: UUID) async -> [Float]? {
        // Fetch from Vertex AI Vector Search
        return nil
    }
    
    func clearSearchResults() {
        searchResults = []
    }
    
    func clearSearchHistory() {
        searchHistory = []
        saveSearchHistory()
    }
}

// MARK: - Supporting Types

/// 搜索模式
enum SearchMode: String, CaseIterable {
    case semantic = "semantic"      // 纯语义搜索
    case keyword = "keyword"        // 关键词搜索
    case hybrid = "hybrid"          // 混合搜索
    case multiModal = "multiModal"  // 多模态搜索
    
    var displayName: String {
        switch self {
        case .semantic: return "语义搜索"
        case .keyword: return "关键词搜索"
        case .hybrid: return "混合搜索"
        case .multiModal: return "多模态搜索"
        }
    }
    
    var icon: String {
        switch self {
        case .semantic: return "brain"
        case .keyword: return "magnifyingglass"
        case .hybrid: return "square.stack.3d.up"
        case .multiModal: return "cube"
        }
    }
}

/// 向量搜索结果
struct VectorSearchResult: Identifiable {
    let id: UUID
    let nodeId: UUID
    let content: String
    let similarity: Double
    let relevanceScore: Double
    let highlightedContent: AttributedString
    let contextSnippet: String
    let explanation: String
    let relatedNodes: [UUID]
    let metadata: VectorMetadata
}

/// 原始搜索结果
struct RawSearchResult {
    let nodeId: UUID
    let content: String
    let similarity: Double
    let metadata: VectorMetadata
}

/// 搜索结果分析
struct SearchResultAnalysis {
    let contextSnippet: String
    let explanation: String
    let relatedNodeIds: [UUID]
}

/// 向量元数据
struct VectorMetadata {
    let nodeType: NodeType
    let createdAt: Date
    let hasEmotionalMarker: Bool
    let emotionalTags: [EmotionalTag]
    let connectionCount: Int
    let recencyScore: Double
    
    init(from node: ThoughtNode) {
        self.nodeType = node.nodeType
        self.createdAt = node.createdAt
        self.hasEmotionalMarker = !node.emotionalTags.isEmpty
        self.emotionalTags = node.emotionalTags
        self.connectionCount = 0 // Would be calculated from connections
        
        // Calculate recency score (0-1, where 1 is most recent)
        let daysSinceCreation = Date().timeIntervalSince(node.createdAt) / 86400
        self.recencyScore = max(0, 1 - (daysSinceCreation / 365))
    }
}

/// 复合搜索查询
struct CompositeSearchQuery {
    let textQuery: String?
    let emotionalFilter: EmotionalTag?
    let timeRange: DateInterval?
    let nodeTypes: Set<NodeType>?
    var textEmbedding: [Float]?
}

/// 搜索历史项
struct SearchHistoryItem: Identifiable {
    let id: UUID
    let query: String
    let timestamp: Date
    let resultCount: Int
    let searchMode: SearchMode
    
    init(query: String, timestamp: Date = Date(), resultCount: Int, searchMode: SearchMode) {
        self.id = UUID()
        self.query = query
        self.timestamp = timestamp
        self.resultCount = resultCount
        self.searchMode = searchMode
    }
}

/// 搜索指标
struct SearchMetrics {
    var totalSearches: Int = 0
    var totalIndexedNodes: Int = 0
    var embeddingsGenerated: Int = 0
    var averageSearchTime: TimeInterval = 0
    var averageResultCount: Double = 0
    var popularQueries: [String: Int] = [:]
}

/// 向量索引元数据
struct VectorIndexMetadata {
    let indexId: String
    var vectorCount: Int
    var lastUpdated: Date
    var needsReindexing: Bool
}

/// 搜索错误
enum SearchError: LocalizedError {
    case notProUser
    case insufficientCredits
    case indexNotReady
    case searchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notProUser:
            return "全局深度搜索是高级功能，请升级到Pro版本"
        case .insufficientCredits:
            return "AI积分不足，无法执行搜索"
        case .indexNotReady:
            return "搜索索引正在初始化，请稍后再试"
        case .searchFailed(let message):
            return "搜索失败: \(message)"
        }
    }
}

// Array.chunked extension is defined in HybridAIService.swift