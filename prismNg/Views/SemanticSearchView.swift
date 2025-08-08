//
//  SemanticSearchView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import SwiftData

struct SemanticSearchView: View {
    @ObservedObject var canvasViewModel: CanvasViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchQuery = ""
    @State private var searchResults: [VectorSearchResult] = []
    @State private var isSearching = false
    @State private var selectedSearchMode: SearchMode = .semantic
    
    enum SearchMode: String, CaseIterable {
        case semantic = "语义搜索"
        case keyword = "关键词搜索"
        case hybrid = "混合搜索"
        
        var icon: String {
            switch self {
            case .semantic: return "brain"
            case .keyword: return "textformat"
            case .hybrid: return "sparkles"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Mode Picker
                Picker("Search Mode", selection: $selectedSearchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Label(mode.rawValue, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜索你的思想...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            performSearch()
                        }
                    
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            searchResults.removeAll()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button("搜索") {
                        performSearch()
                    }
                    .disabled(searchQuery.isEmpty)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Results List
                if isSearching {
                    ProgressView("正在搜索...")
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchQuery.isEmpty {
                    ContentUnavailableView(
                        "没有找到结果",
                        systemImage: "magnifyingglass",
                        description: Text("尝试使用不同的搜索词")
                    )
                } else {
                    List(searchResults, id: \.nodeId) { result in
                        SemanticSearchResultRow(
                            result: result,
                            canvasViewModel: canvasViewModel,
                            onSelect: {
                                selectNode(result.nodeId)
                            }
                        )
                    }
                    .listStyle(.plain)
                }
                
                Spacer()
            }
            .navigationTitle("智能搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showSearchHelp()
                        } label: {
                            Label("搜索帮助", systemImage: "questionmark.circle")
                        }
                        
                        Button {
                            showAdvancedOptions()
                        } label: {
                            Label("高级选项", systemImage: "slider.horizontal.3")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else { return }
        
        isSearching = true
        searchResults.removeAll()
        
        Task {
            switch selectedSearchMode {
            case .semantic:
                let results = await canvasViewModel.embeddingManager.semanticSearch(
                    query: searchQuery,
                    limit: 20
                )
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
                
            case .keyword:
                // Perform traditional keyword search
                let results = performKeywordSearch()
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
                
            case .hybrid:
                // Combine semantic and keyword search
                async let semanticResults = canvasViewModel.embeddingManager.semanticSearch(
                    query: searchQuery,
                    limit: 10
                )
                let keywordResults = performKeywordSearch()
                
                let semantic = await semanticResults
                let combined = combineResults(semantic: semantic, keyword: keywordResults)
                
                await MainActor.run {
                    searchResults = combined
                    isSearching = false
                }
            }
        }
    }
    
    private func performKeywordSearch() -> [VectorSearchResult] {
        let lowercasedQuery = searchQuery.lowercased()
        let matchingNodes = canvasViewModel.thoughtNodes.filter { node in
            node.content.lowercased().contains(lowercasedQuery)
        }
        
        return matchingNodes.map { node in
            VectorSearchResult(
                id: UUID(),
                nodeId: node.id,
                content: node.content,
                similarity: Double(calculateKeywordSimilarity(query: lowercasedQuery, content: node.content.lowercased())),
                relevanceScore: Double(calculateKeywordSimilarity(query: lowercasedQuery, content: node.content.lowercased())),
                highlightedContent: AttributedString(node.content),
                contextSnippet: String(node.content.prefix(100)),
                explanation: "Keyword match",
                relatedNodes: [],
                metadata: VectorMetadata(from: node)
            )
        }.sorted { $0.similarity > $1.similarity }
    }
    
    private func calculateKeywordSimilarity(query: String, content: String) -> Float {
        let queryWords = Set(query.split(separator: " ").map(String.init))
        let contentWords = Set(content.split(separator: " ").map(String.init))
        
        let intersection = queryWords.intersection(contentWords)
        let union = queryWords.union(contentWords)
        
        guard !union.isEmpty else { return 0 }
        
        return Float(intersection.count) / Float(union.count)
    }
    
    private func combineResults(semantic: [VectorSearchResult], keyword: [VectorSearchResult]) -> [VectorSearchResult] {
        var combined: [UUID: Double] = [:]
        var nodeContent: [UUID: String] = [:]
        
        // Add semantic results with weight
        for result in semantic {
            combined[result.nodeId] = result.similarity * 0.7
            nodeContent[result.nodeId] = result.content
        }
        
        // Add keyword results with weight
        for result in keyword {
            if let existing = combined[result.nodeId] {
                combined[result.nodeId] = existing + (result.similarity * 0.3)
            } else {
                combined[result.nodeId] = result.similarity * 0.3
            }
            nodeContent[result.nodeId] = result.content
        }
        
        // Convert back to array and sort
        return combined.map { 
            VectorSearchResult(
                id: UUID(),
                nodeId: $0.key,
                content: nodeContent[$0.key] ?? "",
                similarity: $0.value,
                relevanceScore: $0.value,
                highlightedContent: AttributedString(nodeContent[$0.key] ?? ""),
                contextSnippet: String((nodeContent[$0.key] ?? "").prefix(100)),
                explanation: "Combined search result",
                relatedNodes: [],
                metadata: VectorMetadata(from: ThoughtNode(content: nodeContent[$0.key] ?? ""))
            )
        }.sorted { $0.similarity > $1.similarity }
    }
    
    private func selectNode(_ nodeId: UUID) {
        canvasViewModel.selectedNodeId = nodeId
        
        // Focus on the node in the canvas
        if let scene = canvasViewModel.scene {
            scene.focusOnNode(nodeId: nodeId)
        }
        
        dismiss()
    }
    
    private func showSearchHelp() {
        // Show search help sheet
    }
    
    private func showAdvancedOptions() {
        // Show advanced options sheet
    }
}

// MARK: - Search Result Row
struct SemanticSearchResultRow: View {
    let result: VectorSearchResult
    @ObservedObject var canvasViewModel: CanvasViewModel
    let onSelect: () -> Void
    
    @State private var node: ThoughtNode?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let node = node {
                    Text(node.content)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack {
                        Label(node.nodeType.rawValue.capitalized, systemImage: nodeTypeIcon(node.nodeType))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Similarity score
                        Text("\(Int(result.similarity * 100))% 匹配")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    // Emotional tags
                    if !node.emotionalTags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(node.emotionalTags.prefix(3), id: \.self) { emotion in
                                Image(systemName: emotion.icon)
                                    .font(.caption)
                                    .foregroundColor(emotion.color)
                            }
                        }
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .onAppear {
            loadNode()
        }
    }
    
    private func loadNode() {
        node = canvasViewModel.thoughtNodes.first { $0.id == result.nodeId }
    }
    
    private func nodeTypeIcon(_ type: NodeType) -> String {
        switch type {
        case .thought: return "bubble.left"
        case .insight: return "lightbulb"
        case .question: return "questionmark.circle"
        case .conclusion: return "checkmark.circle"
        case .contradiction: return "exclamationmark.triangle"
        case .structure: return "square.grid.3x3"
        }
    }
}

#Preview {
    SemanticSearchView(canvasViewModel: CanvasViewModel())
}