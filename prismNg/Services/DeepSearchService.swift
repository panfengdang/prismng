//
//  DeepSearchService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Deep Search Result
struct DeepSearchResult: Identifiable {
    let id = UUID()
    let node: ThoughtNode
    let relevanceScore: Double
    let matchType: MatchType
    let highlights: [TextHighlight]
    let semanticContext: String?
    
    enum MatchType {
        case exact
        case semantic
        case conceptual
        case associative
    }
    
    struct TextHighlight {
        let range: Range<String.Index>
        let importance: Double
    }
}

// MARK: - Deep Search Service
@MainActor
class DeepSearchService: ObservableObject {
    @Published var isSearching = false
    @Published var searchResults: [DeepSearchResult] = []
    @Published var searchProgress: Double = 0.0
    @Published var error: Error?
    @Published var searchInsights: SearchInsights?
    
    private let quotaService: QuotaManagementService
    private let coreMLService: CoreMLEmbeddingService
    private let vectorService: VectorDBService
    private var searchTask: Task<Void, Never>?
    
    init(quotaService: QuotaManagementService, coreMLService: CoreMLEmbeddingService, vectorService: VectorDBService) {
        self.quotaService = quotaService
        self.coreMLService = coreMLService
        self.vectorService = vectorService
    }
    
    // MARK: - Public Methods
    
    func performDeepSearch(query: String, nodes: [ThoughtNode]) async {
        // Cancel any existing search
        searchTask?.cancel()
        
        // Check if Pro feature
        guard quotaService.subscriptionTier != .free else {
            error = DeepSearchError.proFeatureRequired
            return
        }
        
        isSearching = true
        searchResults = []
        searchProgress = 0.0
        error = nil
        
        searchTask = Task {
            do {
                // Phase 1: Local semantic search
                searchProgress = 0.2
                let localResults = try await performLocalSemanticSearch(query: query, nodes: nodes)
                
                // Phase 2: Deep conceptual analysis
                searchProgress = 0.5
                let conceptualResults = try await performConceptualAnalysis(query: query, nodes: nodes)
                
                // Phase 3: Cross-reference and association mining
                searchProgress = 0.8
                let associativeResults = try await performAssociativeMining(query: query, baseResults: localResults + conceptualResults)
                
                // Combine and rank results
                searchProgress = 0.9
                let allResults = combineAndRankResults(
                    local: localResults,
                    conceptual: conceptualResults,
                    associative: associativeResults
                )
                
                // Generate search insights
                searchInsights = generateSearchInsights(results: allResults, query: query)
                
                searchResults = allResults
                searchProgress = 1.0
                isSearching = false
                
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    isSearching = false
                }
            }
        }
    }
    
    func cancelSearch() {
        searchTask?.cancel()
        isSearching = false
        searchProgress = 0.0
    }
    
    // MARK: - Private Search Methods
    
    private func performLocalSemanticSearch(query: String, nodes: [ThoughtNode]) async throws -> [DeepSearchResult] {
        // Generate query embedding
        guard let queryEmbedding = await coreMLService.generateEmbedding(for: query) else {
            throw DeepSearchError.embeddingGenerationFailed
        }
        
        // Search in vector database
        let searchResults = try await vectorService.findSimilarByVector(queryEmbedding, limit: 20)
        
        // Convert to DeepSearchResult
        return searchResults.compactMap { result -> DeepSearchResult? in
            guard let node = nodes.first(where: { $0.id == result.nodeId }) else { 
                return nil
            }
            
            return DeepSearchResult(
                node: node,
                relevanceScore: Double(result.similarity),
                matchType: .semantic,
                highlights: extractHighlights(from: node.content, query: query),
                semanticContext: generateSemanticContext(node: node, query: query)
            )
        }
    }
    
    private func performConceptualAnalysis(query: String, nodes: [ThoughtNode]) async throws -> [DeepSearchResult] {
        // Extract concepts from query
        let queryConcepts = extractConcepts(from: query)
        
        // Find nodes with related concepts
        var conceptualResults: [DeepSearchResult] = []
        
        for node in nodes {
            let nodeConcepts = extractConcepts(from: node.content)
            let conceptOverlap = calculateConceptOverlap(queryConcepts, nodeConcepts)
            
            if conceptOverlap > 0.3 {
                conceptualResults.append(
                    DeepSearchResult(
                        node: node,
                        relevanceScore: conceptOverlap,
                        matchType: .conceptual,
                        highlights: [],
                        semanticContext: "Conceptual match: \(nodeConcepts.intersection(queryConcepts).joined(separator: ", "))"
                    )
                )
            }
        }
        
        return conceptualResults
    }
    
    private func performAssociativeMining(query: String, baseResults: [DeepSearchResult]) async throws -> [DeepSearchResult] {
        // Find nodes connected to base results
        var associativeResults: [DeepSearchResult] = []
        let processedNodeIds = Set(baseResults.map { $0.node.id })
        
        // This would normally check actual connections in the database
        // For now, we'll simulate by finding nodes with similar emotional tags
        for result in baseResults {
            let connectedNodes = findAssociatedNodes(to: result.node, excluding: processedNodeIds)
            
            for node in connectedNodes {
                associativeResults.append(
                    DeepSearchResult(
                        node: node,
                        relevanceScore: result.relevanceScore * 0.7, // Reduced score for indirect match
                        matchType: .associative,
                        highlights: [],
                        semanticContext: "Associated through: \(result.node.content.prefix(50))..."
                    )
                )
            }
        }
        
        return associativeResults
    }
    
    // MARK: - Helper Methods
    
    private func extractHighlights(from content: String, query: String) -> [DeepSearchResult.TextHighlight] {
        var highlights: [DeepSearchResult.TextHighlight] = []
        let queryWords = query.lowercased().split(separator: " ")
        let contentLowercased = content.lowercased()
        
        for word in queryWords {
            if let range = contentLowercased.range(of: String(word)) {
                highlights.append(
                    DeepSearchResult.TextHighlight(
                        range: range,
                        importance: 1.0
                    )
                )
            }
        }
        
        return highlights
    }
    
    private func generateSemanticContext(node: ThoughtNode, query: String) -> String {
        // In a real implementation, this would use AI to generate context
        return "Semantic similarity found in conceptual space"
    }
    
    private func extractConcepts(from text: String) -> Set<String> {
        // Simplified concept extraction
        let words = text.lowercased().split(separator: " ")
        let stopWords: Set<String> = ["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for"]
        
        return Set(words.map(String.init).filter { !stopWords.contains($0) && $0.count > 3 })
    }
    
    private func calculateConceptOverlap(_ concepts1: Set<String>, _ concepts2: Set<String>) -> Double {
        guard !concepts1.isEmpty && !concepts2.isEmpty else { return 0 }
        
        let intersection = concepts1.intersection(concepts2)
        let union = concepts1.union(concepts2)
        
        return Double(intersection.count) / Double(union.count)
    }
    
    private func findAssociatedNodes(to node: ThoughtNode, excluding: Set<UUID>) -> [ThoughtNode] {
        // This is a placeholder - in real implementation, would query actual connections
        return []
    }
    
    private func combineAndRankResults(local: [DeepSearchResult], conceptual: [DeepSearchResult], associative: [DeepSearchResult]) -> [DeepSearchResult] {
        let allResults = local + conceptual + associative
        
        // Remove duplicates, keeping highest score
        var uniqueResults: [UUID: DeepSearchResult] = [:]
        for result in allResults {
            if let existing = uniqueResults[result.node.id] {
                if result.relevanceScore > existing.relevanceScore {
                    uniqueResults[result.node.id] = result
                }
            } else {
                uniqueResults[result.node.id] = result
            }
        }
        
        // Sort by relevance
        return uniqueResults.values.sorted { $0.relevanceScore > $1.relevanceScore }
    }
    
    private func generateSearchInsights(results: [DeepSearchResult], query: String) -> SearchInsights {
        let matchTypes = Dictionary(grouping: results, by: { $0.matchType })
        
        return SearchInsights(
            totalResults: results.count,
            semanticMatches: matchTypes[.semantic]?.count ?? 0,
            conceptualMatches: matchTypes[.conceptual]?.count ?? 0,
            associativeMatches: matchTypes[.associative]?.count ?? 0,
            topConcepts: extractTopConcepts(from: results),
            searchPatterns: identifySearchPatterns(results: results, query: query)
        )
    }
    
    private func extractTopConcepts(from results: [DeepSearchResult]) -> [String] {
        // Extract top 5 concepts from results
        var conceptCounts: [String: Int] = [:]
        
        for result in results.prefix(10) {
            let concepts = extractConcepts(from: result.node.content)
            for concept in concepts {
                conceptCounts[concept, default: 0] += 1
            }
        }
        
        return conceptCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    private func identifySearchPatterns(results: [DeepSearchResult], query: String) -> [String] {
        var patterns: [String] = []
        
        // Check temporal patterns
        let sortedByDate = results.sorted { $0.node.createdAt < $1.node.createdAt }
        if sortedByDate.count > 3 {
            let recentCount = sortedByDate.suffix(3).count
            if recentCount == 3 {
                patterns.append("最近的思考集中在这个主题")
            }
        }
        
        // Check emotional patterns
        let emotionalNodes = results.filter { !$0.node.emotionalTags.isEmpty }
        if emotionalNodes.count > results.count / 2 {
            patterns.append("这个主题带有强烈的情感色彩")
        }
        
        return patterns
    }
}

// MARK: - Search Insights
struct SearchInsights {
    let totalResults: Int
    let semanticMatches: Int
    let conceptualMatches: Int
    let associativeMatches: Int
    let topConcepts: [String]
    let searchPatterns: [String]
}

// MARK: - Deep Search Error
enum DeepSearchError: LocalizedError {
    case proFeatureRequired
    case embeddingGenerationFailed
    case searchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .proFeatureRequired:
            return "深度搜索是 Pro 功能，请升级订阅"
        case .embeddingGenerationFailed:
            return "无法生成搜索向量"
        case .searchFailed(let message):
            return "搜索失败: \(message)"
        }
    }
}

// MARK: - Deep Search View
struct DeepSearchView: View {
    @StateObject private var searchService: DeepSearchService
    @State private var searchQuery = ""
    @State private var selectedResult: DeepSearchResult?
    @Environment(\.dismiss) private var dismiss
    
    let nodes: [ThoughtNode]
    let onNodeSelected: (UUID) -> Void
    
    init(quotaService: QuotaManagementService, coreMLService: CoreMLEmbeddingService, vectorService: VectorDBService, nodes: [ThoughtNode], onNodeSelected: @escaping (UUID) -> Void) {
        self._searchService = StateObject(wrappedValue: DeepSearchService(
            quotaService: quotaService,
            coreMLService: coreMLService,
            vectorService: vectorService
        ))
        self.nodes = nodes
        self.onNodeSelected = onNodeSelected
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("深度搜索你的想法...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if searchService.isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            searchService.searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray6))
                )
                .padding()
                
                if searchService.isSearching {
                    // Progress View
                    VStack(spacing: 20) {
                        ProgressView(value: searchService.searchProgress)
                            .progressViewStyle(.linear)
                            .padding(.horizontal)
                        
                        Text(progressText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.top, 40)
                } else if !searchService.searchResults.isEmpty {
                    // Results List
                    ScrollView {
                        // Search Insights
                        if let insights = searchService.searchInsights {
                            SearchInsightsCard(insights: insights)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                        
                        // Results
                        LazyVStack(spacing: 12) {
                            ForEach(searchService.searchResults) { result in
                                DeepSearchResultCard(result: result)
                                    .onTapGesture {
                                        selectedResult = result
                                        onNodeSelected(result.node.id)
                                        dismiss()
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else if searchQuery.isEmpty {
                    // Empty State
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("深度搜索")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("使用 AI 深入理解和搜索你的想法\n发现隐藏的关联和模式")
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                } else {
                    // No Results
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("未找到结果")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text("试试使用不同的关键词或表述")
                            .font(.callout)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.top, 60)
                }
                
                if let error = searchService.error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("深度搜索 Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                if searchService.isSearching {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("停止") {
                            searchService.cancelSearch()
                        }
                    }
                }
            }
        }
    }
    
    private var progressText: String {
        let progress = searchService.searchProgress
        if progress < 0.3 {
            return "正在进行语义分析..."
        } else if progress < 0.6 {
            return "正在进行概念匹配..."
        } else if progress < 0.9 {
            return "正在挖掘关联模式..."
        } else {
            return "正在整理结果..."
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        Task {
            await searchService.performDeepSearch(query: searchQuery, nodes: nodes)
        }
    }
}

// MARK: - Search Result Card
struct DeepSearchResultCard: View {
    let result: DeepSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Match Type & Score
            HStack {
                Label(matchTypeText, systemImage: matchTypeIcon)
                    .font(.caption)
                    .foregroundColor(matchTypeColor)
                
                Spacer()
                
                // Relevance Score
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: "circle.fill")
                            .font(.system(size: 6))
                            .foregroundColor(
                                Double(index) < result.relevanceScore * 5 ? .orange : .gray.opacity(0.3)
                            )
                    }
                }
            }
            
            // Content
            Text(result.node.content)
                .font(.callout)
                .lineLimit(3)
                .foregroundColor(.primary)
            
            // Semantic Context
            if let context = result.semanticContext {
                Text(context)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            // Metadata
            HStack {
                Image(systemName: nodeTypeIcon)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(result.node.nodeType.rawValue.capitalized)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(result.node.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var matchTypeText: String {
        switch result.matchType {
        case .exact: return "精确匹配"
        case .semantic: return "语义匹配"
        case .conceptual: return "概念匹配"
        case .associative: return "关联匹配"
        }
    }
    
    private var matchTypeIcon: String {
        switch result.matchType {
        case .exact: return "equal.circle"
        case .semantic: return "brain"
        case .conceptual: return "lightbulb"
        case .associative: return "link"
        }
    }
    
    private var matchTypeColor: Color {
        switch result.matchType {
        case .exact: return .green
        case .semantic: return .blue
        case .conceptual: return .purple
        case .associative: return .orange
        }
    }
    
    private var nodeTypeIcon: String {
        switch result.node.nodeType {
        case .thought: return "lightbulb"
        case .insight: return "star"
        case .question: return "questionmark.circle"
        case .conclusion: return "checkmark.seal"
        case .contradiction: return "exclamationmark.triangle"
        case .structure: return "grid"
        }
    }
}

// MARK: - Search Insights Card
struct SearchInsightsCard: View {
    let insights: SearchInsights
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("搜索洞察", systemImage: "lightbulb.fill")
                .font(.headline)
            
            // Match Statistics
            HStack(spacing: 16) {
                StatItem(title: "总结果", value: "\(insights.totalResults)", color: .blue)
                StatItem(title: "语义", value: "\(insights.semanticMatches)", color: .green)
                StatItem(title: "概念", value: "\(insights.conceptualMatches)", color: .purple)
                StatItem(title: "关联", value: "\(insights.associativeMatches)", color: .orange)
            }
            
            // Top Concepts
            if !insights.topConcepts.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("核心概念")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        ForEach(insights.topConcepts.prefix(3), id: \.self) { concept in
                            Text(concept)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                    }
                }
            }
            
            // Search Patterns
            if !insights.searchPatterns.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(insights.searchPatterns, id: \.self) { pattern in
                        HStack {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text(pattern)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
