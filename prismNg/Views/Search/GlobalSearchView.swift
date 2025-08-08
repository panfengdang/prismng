//
//  GlobalSearchView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP2-4: Global Search View - 全局深度搜索界面
//

import SwiftUI
import Charts

// MARK: - Global Search View

/// 全局深度搜索主界面
struct GlobalSearchView: View {
    @ObservedObject var searchService: VertexAIVectorSearchService
    @ObservedObject var storeKitService: StoreKitService
    @State private var searchQuery = ""
    @State private var selectedSearchMode: SearchMode = .semantic
    @State private var showingAdvancedOptions = false
    @State private var showingSearchHistory = false
    @State private var selectedResult: VectorSearchResult?
    @State private var showingResultDetail = false
    
    // Advanced search options
    @State private var selectedEmotionalTag: EmotionalTag?
    @State private var selectedNodeTypes: Set<NodeType> = []
    @State private var selectedDateRange: DateInterval?
    
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search header
                SearchHeaderView(
                    searchQuery: $searchQuery,
                    selectedSearchMode: $selectedSearchMode,
                    isSearchFieldFocused: $isSearchFieldFocused,
                    showingAdvancedOptions: $showingAdvancedOptions,
                    onSearch: performSearch,
                    onClear: clearSearch
                )
                
                Divider()
                
                // Main content
                if searchService.isProFeature {
                    if showingAdvancedOptions {
                        AdvancedSearchOptions(
                            selectedEmotionalTag: $selectedEmotionalTag,
                            selectedNodeTypes: $selectedNodeTypes,
                            selectedDateRange: $selectedDateRange
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    if searchService.isSearching {
                        SearchingView()
                    } else if !searchService.searchResults.isEmpty {
                        SearchResultsView(
                            results: searchService.searchResults,
                            onResultSelected: { result in
                                selectedResult = result
                                showingResultDetail = true
                            }
                        )
                    } else if searchQuery.isEmpty {
                        EmptySearchView(
                            searchHistory: searchService.searchHistory,
                            onHistoryItemSelected: { item in
                                searchQuery = item.query
                                performSearch()
                            },
                            onShowAllHistory: {
                                showingSearchHistory = true
                            }
                        )
                    } else {
                        NoResultsView(query: searchQuery)
                    }
                } else {
                    ProFeaturePrompt(storeKitService: storeKitService)
                }
                
                Spacer()
            }
            .navigationTitle("全局搜索")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSearchHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingSearchHistory) {
                SearchHistoryView(searchService: searchService)
            }
            .sheet(isPresented: $showingResultDetail) {
                if let result = selectedResult {
                    SearchResultDetailView(result: result, searchService: searchService)
                }
            }
        }
        .animation(.easeInOut, value: showingAdvancedOptions)
    }
    
    private func performSearch() {
        Task {
            if showingAdvancedOptions {
                // Multi-modal search
                await searchService.performMultiModalSearch(
                    textQuery: searchQuery.isEmpty ? nil : searchQuery,
                    emotionalFilter: selectedEmotionalTag,
                    timeRange: selectedDateRange,
                    nodeTypes: selectedNodeTypes.isEmpty ? nil : selectedNodeTypes
                )
            } else {
                // Simple search
                await searchService.performGlobalSearch(searchQuery, searchMode: selectedSearchMode)
            }
        }
        
        isSearchFieldFocused = false
    }
    
    private func clearSearch() {
        searchQuery = ""
        searchService.clearSearchResults()
        selectedEmotionalTag = nil
        selectedNodeTypes = []
        selectedDateRange = nil
    }
}

// MARK: - Search Header

struct SearchHeaderView: View {
    @Binding var searchQuery: String
    @Binding var selectedSearchMode: SearchMode
    @FocusState.Binding var isSearchFieldFocused: Bool
    @Binding var showingAdvancedOptions: Bool
    let onSearch: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索您的思想空间...", text: $searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        onSearch()
                    }
                
                if !searchQuery.isEmpty {
                    Button(action: onClear) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: onSearch) {
                    Text("搜索")
                        .fontWeight(.medium)
                }
                .disabled(searchQuery.isEmpty && !showingAdvancedOptions)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Search mode selector
            HStack {
                SearchModePicker(selectedMode: $selectedSearchMode)
                
                Spacer()
                
                Button {
                    withAnimation {
                        showingAdvancedOptions.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showingAdvancedOptions ? "chevron.up" : "chevron.down")
                            .font(.caption)
                        Text("高级选项")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .padding()
    }
}

struct SearchModePicker: View {
    @Binding var selectedMode: SearchMode
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(SearchMode.allCases, id: \.self) { mode in
                    SearchModeChip(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        onTap: { selectedMode = mode }
                    )
                }
            }
        }
    }
}

struct SearchModeChip: View {
    let mode: SearchMode
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.caption)
                Text(mode.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Advanced Search Options

struct AdvancedSearchOptions: View {
    @Binding var selectedEmotionalTag: EmotionalTag?
    @Binding var selectedNodeTypes: Set<NodeType>
    @Binding var selectedDateRange: DateInterval?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Emotional filter
            VStack(alignment: .leading, spacing: 8) {
                Text("情感筛选")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        EmotionalTagChip(
                            tag: nil,
                            isSelected: selectedEmotionalTag == nil,
                            onTap: { selectedEmotionalTag = nil }
                        )
                        
                        ForEach(EmotionalTag.allCases, id: \.self) { tag in
                            EmotionalTagChip(
                                tag: tag,
                                isSelected: selectedEmotionalTag == tag,
                                onTap: { selectedEmotionalTag = tag }
                            )
                        }
                    }
                }
            }
            
            // Node type filter
            VStack(alignment: .leading, spacing: 8) {
                Text("节点类型")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(NodeType.allCases, id: \.self) { type in
                        NodeTypeChip(
                            type: type,
                            isSelected: selectedNodeTypes.contains(type),
                            onTap: {
                                if selectedNodeTypes.contains(type) {
                                    selectedNodeTypes.remove(type)
                                } else {
                                    selectedNodeTypes.insert(type)
                                }
                            }
                        )
                    }
                }
            }
            
            // Date range filter
            DateRangeSelector(selectedDateRange: $selectedDateRange)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

struct EmotionalTagChip: View {
    let tag: EmotionalTag?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag?.rawValue ?? "全部")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.orange : Color(.systemGray5))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NodeTypeChip: View {
    let type: NodeType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.caption)
                Text(type.rawValue)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .blue : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DateRangeSelector: View {
    @Binding var selectedDateRange: DateInterval?
    @State private var showingDatePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间范围")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button {
                showingDatePicker = true
            } label: {
                HStack {
                    Image(systemName: "calendar")
                    
                    if let range = selectedDateRange {
                        Text("\(range.start, style: .date) - \(range.end, style: .date)")
                            .font(.caption)
                    } else {
                        Text("选择时间范围")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if selectedDateRange != nil {
                        Button {
                            selectedDateRange = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingDatePicker) {
            // Date range picker view
            Text("日期选择器占位")
        }
    }
}

// MARK: - Search States

struct SearchingView: View {
    @State private var loadingDots = 0
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            HStack(spacing: 4) {
                Text("正在搜索")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ForEach(0..<3) { index in
                    Text(".")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .opacity(loadingDots > index ? 1 : 0.3)
                }
            }
            .onAppear {
                animateLoadingDots()
            }
            
            Text("使用 Vertex AI 深度分析您的思想空间")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func animateLoadingDots() {
        withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
            loadingDots = (loadingDots + 1) % 4
        }
    }
}

struct NoResultsView: View {
    let query: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("未找到相关结果")
                .font(.headline)
            
            Text("尝试使用不同的搜索词或调整搜索模式")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Search suggestions
            VStack(alignment: .leading, spacing: 8) {
                Text("搜索建议:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Label("使用更通用的词汇", systemImage: "lightbulb")
                    Label("尝试语义搜索模式", systemImage: "brain")
                    Label("检查拼写是否正确", systemImage: "textformat.abc")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptySearchView: View {
    let searchHistory: [SearchHistoryItem]
    let onHistoryItemSelected: (SearchHistoryItem) -> Void
    let onShowAllHistory: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Search tips
                SearchTipsCard()
                
                // Recent searches
                if !searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("最近搜索")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("查看全部") {
                                onShowAllHistory()
                            }
                            .font(.caption)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(searchHistory.prefix(5)) { item in
                                SearchHistoryRow(
                                    item: item,
                                    onTap: { onHistoryItemSelected(item) }
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct SearchTipsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("搜索技巧")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                SearchTipRow(
                    icon: "brain",
                    title: "语义搜索",
                    description: "使用自然语言描述您要查找的内容"
                )
                
                SearchTipRow(
                    icon: "quote.bubble",
                    title: "精确匹配",
                    description: "使用引号包围词组进行精确搜索"
                )
                
                SearchTipRow(
                    icon: "cube",
                    title: "多模态搜索",
                    description: "结合情感、时间和类型进行高级筛选"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding()
    }
}

struct SearchTipRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Search Results

struct SearchResultsView: View {
    let results: [VectorSearchResult]
    let onResultSelected: (VectorSearchResult) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(results) { result in
                    SearchResultCard(
                        result: result,
                        onTap: { onResultSelected(result) }
                    )
                }
            }
            .padding()
        }
    }
}

struct SearchResultCard: View {
    let result: VectorSearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    NodeTypeIndicator(type: result.metadata.nodeType)
                    
                    Spacer()
                    
                    RelevanceScore(score: result.relevanceScore)
                }
                
                // Content preview
                Text(result.highlightedContent)
                    .font(.callout)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                // Context snippet
                if !result.contextSnippet.isEmpty {
                    Text(result.contextSnippet)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Metadata
                HStack {
                    // Emotional tags
                    if !result.metadata.emotionalTags.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.caption2)
                                .foregroundColor(.pink)
                            
                            Text(result.metadata.emotionalTags.first?.rawValue ?? "")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Date
                    Text(result.metadata.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Explanation
                if !result.explanation.isEmpty {
                    Text(result.explanation)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NodeTypeIndicator: View {
    let type: NodeType
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: nodeTypeIcon)
                .font(.caption)
            
            Text(type.rawValue)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(nodeTypeColor.opacity(0.2))
        )
        .foregroundColor(nodeTypeColor)
    }
    
    private var nodeTypeIcon: String {
        switch type {
        case .thought: return "bubble.left"
        case .insight: return "lightbulb"
        case .question: return "questionmark.circle"
        case .conclusion: return "checkmark.seal"
        case .contradiction: return "exclamationmark.triangle"
        case .structure: return "square.grid.3x3"
        }
    }
    
    private var nodeTypeColor: Color {
        switch type {
        case .thought: return .blue
        case .insight: return .yellow
        case .question: return .purple
        case .conclusion: return .green
        case .contradiction: return .red
        case .structure: return .indigo
        }
    }
}

struct RelevanceScore: View {
    let score: Double
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(Double(index) < score * 5 ? .yellow : .gray.opacity(0.3))
            }
            
            Text(String(format: "%.0f%%", score * 100))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Search History

struct SearchHistoryRow: View {
    let item: SearchHistoryItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.query)
                        .font(.callout)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(item.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("·")
                            .foregroundColor(.secondary)
                        
                        Text("\(item.resultCount) 个结果")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search History View

struct SearchHistoryView: View {
    @ObservedObject var searchService: VertexAIVectorSearchService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(searchService.searchHistory) { item in
                    SearchHistoryDetailRow(item: item) {
                        // Perform search with this query
                        dismiss()
                    }
                }
                .onDelete { indexSet in
                    // Delete history items
                }
            }
            .navigationTitle("搜索历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("清除") {
                        searchService.clearSearchHistory()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

struct SearchHistoryDetailRow: View {
    let item: SearchHistoryItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.query)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Label("\(item.resultCount) 个结果", systemImage: "doc.text.magnifyingglass")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(item.timestamp, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Result Detail

struct SearchResultDetailView: View {
    let result: VectorSearchResult
    @ObservedObject var searchService: VertexAIVectorSearchService
    @Environment(\.dismiss) private var dismiss
    @State private var similarNodes: [VectorSearchResult] = []
    @State private var isLoadingSimilar = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Result content
                    ResultContentCard(result: result)
                    
                    // Metadata
                    ResultMetadataCard(result: result)
                    
                    // Related nodes
                    if !result.relatedNodes.isEmpty {
                        RelatedNodesCard(nodeIds: result.relatedNodes)
                    }
                    
                    // Similar nodes
                    SimilarNodesCard(
                        similarNodes: similarNodes,
                        isLoading: isLoadingSimilar
                    )
                }
                .padding()
            }
            .navigationTitle("搜索结果详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // Open in canvas
                    } label: {
                        Image(systemName: "arrow.up.forward.square")
                    }
                }
            }
            .onAppear {
                loadSimilarNodes()
            }
        }
    }
    
    private func loadSimilarNodes() {
        // Load similar nodes
    }
}

struct ResultContentCard: View {
    let result: VectorSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NodeTypeIndicator(type: result.metadata.nodeType)
            
            Text(result.content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
            
            if !result.explanation.isEmpty {
                Text(result.explanation)
                    .font(.callout)
                    .foregroundColor(.blue)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

struct ResultMetadataCard: View {
    let result: VectorSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("元数据")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetadataItem(
                    icon: "calendar",
                    title: "创建时间",
                    value: result.metadata.createdAt.formatted()
                )
                
                MetadataItem(
                    icon: "percent",
                    title: "相似度",
                    value: String(format: "%.1f%%", result.similarity * 100)
                )
                
                MetadataItem(
                    icon: "link",
                    title: "连接数",
                    value: "\(result.metadata.connectionCount)"
                )
                
                MetadataItem(
                    icon: "star",
                    title: "相关性",
                    value: String(format: "%.1f%%", result.relevanceScore * 100)
                )
            }
            
            if !result.metadata.emotionalTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("情感标签")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(result.metadata.emotionalTags, id: \.self) { tag in
                                Text(tag.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.pink.opacity(0.2))
                                    )
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct MetadataItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.callout)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

struct RelatedNodesCard: View {
    let nodeIds: [UUID]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("相关节点")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(nodeIds, id: \.self) { nodeId in
                        // Placeholder for related node preview
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 120, height: 80)
                            .overlay(
                                Text("节点预览")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            )
                    }
                }
            }
        }
    }
}

struct SimilarNodesCard: View {
    let similarNodes: [VectorSearchResult]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("相似节点")
                    .font(.headline)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if similarNodes.isEmpty && !isLoading {
                Text("暂无相似节点")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 8) {
                    ForEach(similarNodes.prefix(5)) { node in
                        // Similar node preview
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(node.content)
                                    .font(.caption)
                                    .lineLimit(2)
                                
                                HStack {
                                    Text("相似度: \(Int(node.similarity * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(node.metadata.createdAt, style: .date)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Pro Feature Prompt

struct ProFeaturePrompt: View {
    @ObservedObject var storeKitService: StoreKitService
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolEffect(.pulse)
            
            Text("全局深度搜索")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("使用 Vertex AI 的强大向量搜索能力，在您的所有思想节点中进行语义搜索")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                GlobalSearchFeatureRow(icon: "brain", text: "基于语义理解的智能搜索")
                GlobalSearchFeatureRow(icon: "sparkles", text: "多模态搜索：文本、情感、时间")
                GlobalSearchFeatureRow(icon: "bolt.fill", text: "毫秒级响应的向量检索")
                GlobalSearchFeatureRow(icon: "link.circle", text: "自动发现相关联的思想")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
            
            Button {
                // Navigate to subscription
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("升级到高级版")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 40)
    }
}

struct GlobalSearchFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.callout)
            
            Spacer()
        }
    }
}

#Preview {
    GlobalSearchView(
        searchService: VertexAIVectorSearchService(
            firebaseAIService: FirebaseFunctionsAIService(),
            storeKitService: StoreKitService(),
            creditsService: AICreditsService(
                userId: "preview",
                storeKitService: StoreKitService(),
                quotaService: QuotaManagementService()
            )
        ),
        storeKitService: StoreKitService()
    )
}