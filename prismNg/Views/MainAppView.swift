//
//  MainAppView.swift
//  prismNg
//
//  Main app container with navigation
//

import SwiftUI
import SwiftData

struct MainAppView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var thoughtNodes: [ThoughtNode]
    @Query private var userConfig: [UserConfiguration]
    
    @EnvironmentObject private var quotaService: QuotaManagementService
    @StateObject private var cloudSyncManager = CloudSyncManager()
    @StateObject private var interactionService = InteractionPreferenceService()
    @StateObject private var forgettingService = MemoryForgettingService()
    @StateObject private var canvasViewModel = CanvasViewModel()
    @StateObject private var emotionalService = EmotionalComputingService()
    @StateObject private var appleSignInService = AppleSignInService()
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var realtimeSyncService = FirestoreRealtimeSyncService()
    
    // GrowthOptimizationService needs to be initialized later with quotaService
    @State private var growthOptimizationService: GrowthOptimizationService?
    
    @State private var showingSidebar = false
    @State private var showingSettings = false
    @State private var showingMemoryManagement = false
    @State private var showingSubscription = false
    @State private var showingSearch = false
    @State private var showingEmotionalInsights = false
    @State private var showingStructuralAnalysis = false
    @State private var selectedView = AppView.canvas
    
    enum AppView: String, CaseIterable {
        case canvas = "思维画布"
        case memory = "记忆海"
        case insights = "洞察"
        case collaboration = "协作"
        
        var icon: String {
            switch self {
            case .canvas: return "brain.head.profile"
            case .memory: return "memories"
            case .insights: return "lightbulb"
            case .collaboration: return "person.2"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content with navigation bar
                VStack(spacing: 0) {
                    // Custom navigation bar
                    navigationBar
                        .frame(height: 60)
                        .background(Color(UIColor.systemBackground))
                        .zIndex(100)
                    
                    // Content
                    detailContent
                }
                
                // Sidebar overlay
                if showingSidebar {
                    sidebarOverlay
                        .zIndex(200)
                        .transition(.move(edge: .leading))
                }
            }
        }
        .environmentObject(quotaService)
        .environmentObject(cloudSyncManager)
        .environmentObject(interactionService)
        .environmentObject(appleSignInService)
        .environmentObject(firebaseManager)
        .environmentObject(realtimeSyncService)
        .environmentObject(emotionalService)
        .environmentObject(canvasViewModel)
        .environmentObject(forgettingService)
        .onAppear {
            if growthOptimizationService == nil {
                growthOptimizationService = GrowthOptimizationService(quotaService: quotaService)
            }
            // Ensure ViewModel uses the global quota service instance
            canvasViewModel.quotaService = quotaService
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView(
                    interactionService: interactionService,
                    quotaService: quotaService,
                    cloudSyncManager: cloudSyncManager
                )
                .environmentObject(appleSignInService)
                .environmentObject(firebaseManager)
                .environmentObject(realtimeSyncService)
                .environmentObject(growthOptimizationService ?? GrowthOptimizationService(quotaService: quotaService))
            }
        }
        .sheet(isPresented: $showingSubscription) {
            NavigationView {
                SubscriptionView(quotaService: quotaService)
            }
        }
        .sheet(isPresented: $showingMemoryManagement) {
            NavigationView {
                MemoryManagementView(
                    forgettingService: forgettingService,
                    canvasViewModel: canvasViewModel
                )
            }
        }
        .sheet(isPresented: $showingEmotionalInsights) {
            NavigationView {
                EmotionalInsightsView(emotionalService: emotionalService)
            }
        }
        .sheet(isPresented: $showingStructuralAnalysis) {
            NavigationView {
                StructuralAnalysisViewDetail()
            }
        }
        .searchable(text: .constant(""), isPresented: $showingSearch)
    }
    
    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack(spacing: 16) {
            // Menu button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSidebar.toggle()
                }
            }) {
                Image(systemName: showingSidebar ? "xmark" : "line.3.horizontal")
                    .font(.system(size: 22))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            // Title
            Text(selectedView.rawValue)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Search button
            Button(action: {
                showingSearch = true
            }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }
            
            // Add button (only for canvas)
            if selectedView == .canvas {
                Button(action: createNewNode) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Sidebar Overlay
    private var sidebarOverlay: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("PrismNg")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSidebar = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Search bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search", text: .constant(""))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        .padding()
                        
                        // Workspace section
                        sectionHeader("工作空间")
                        
                        ForEach(AppView.allCases, id: \.self) { view in
                            menuButton(
                                title: view.rawValue,
                                icon: view.icon,
                                isSelected: selectedView == view
                            ) {
                                selectedView = view
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSidebar = false
                                }
                            }
                        }
                        
                        Divider().padding(.vertical)
                        
                        // Tools section
                        sectionHeader("工具")
                        
                        menuButton(title: "搜索", icon: "magnifyingglass") {
                            showingSearch = true
                            showingSidebar = false
                        }
                        
                        menuButton(title: "情感分析", icon: "heart.text.square") {
                            showingEmotionalInsights = true
                            showingSidebar = false
                        }
                        
                        menuButton(title: "结构分析", icon: "chart.xyaxis.line") {
                            showingStructuralAnalysis = true
                            showingSidebar = false
                        }
                        
                        Divider().padding(.vertical)
                        
                        // System section
                        sectionHeader("系统")
                        
                        menuButton(title: "设置", icon: "gearshape") {
                            showingSettings = true
                            showingSidebar = false
                        }
                        
                        menuButton(title: "订阅", icon: "creditcard") {
                            showingSubscription = true
                            showingSidebar = false
                        }
                        
                        menuButton(title: "存储管理", icon: "internaldrive") {
                            showingMemoryManagement = true
                            showingSidebar = false
                        }
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.75)
            .background(Color(UIColor.systemBackground))
            .shadow(radius: 5)
            
            // Tap to dismiss area
            Color.black.opacity(0.3)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSidebar = false
                    }
                }
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .padding(.horizontal)
            .padding(.top, 8)
    }
    
    private func menuButton(
        title: String,
        icon: String,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 30)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if title == "情感分析" || title == "结构分析" {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(8)
            .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Detail Content
    @ViewBuilder
    private var detailContent: some View {
        switch selectedView {
        case .canvas:
            ModernCanvasMainView()
                .environmentObject(canvasViewModel)
                .environmentObject(quotaService)
                .environmentObject(emotionalService)
                .environmentObject(interactionService)
        case .memory:
            MemorySeaView()
                .environmentObject(forgettingService)
                .environmentObject(canvasViewModel)
        case .insights:
            InsightsViewDetail()
                .environmentObject(quotaService)
        case .collaboration:
            CollaborationView()
                .environmentObject(cloudSyncManager)
        }
    }
    
    // MARK: - Actions
    private func createNewNode() {
        let node = ThoughtNode(
            content: "新想法",
            nodeType: .thought,
            position: Position(x: 0, y: 0)
        )
        modelContext.insert(node)
        try? modelContext.save()
    }
}

// MARK: - Memory Sea View
struct MemorySeaView: View {
    @Query private var nodes: [ThoughtNode]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 16) {
                    ForEach(nodes) { node in
                        MemoryCard(node: node)
                    }
                }
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}

struct MemoryCard: View {
    let node: ThoughtNode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: node.nodeType.icon)
                    .foregroundColor(node.nodeType.color)
                Text(node.nodeType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(node.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(node.content)
                .lineLimit(3)
                .font(.body)
            
            if !node.emotionalTags.isEmpty {
                HStack {
                    ForEach(node.emotionalTags, id: \.self) { tag in
                        Text(tag.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Insights View
struct InsightsViewDetail: View {
    @Query private var nodes: [ThoughtNode]
    @State private var insights: [String] = []
    @State private var isAnalyzing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Spacer()
                    
                    Button(action: generateInsights) {
                        Label(isAnalyzing ? "分析中..." : "生成洞察", 
                              systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAnalyzing)
                    .padding()
                }
                
                if insights.isEmpty && !isAnalyzing {
                    ContentUnavailableView(
                        "暂无洞察",
                        systemImage: "lightbulb",
                        description: Text("点击生成洞察来分析您的思维")
                    )
                    .frame(maxWidth: .infinity, minHeight: 400)
                } else {
                    ForEach(insights, id: \.self) { insight in
                        InsightCardDetail(insight: insight)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    private func generateInsights() {
        Task {
            isAnalyzing = true
            // Mock insight generation
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            insights.append("基于您最近的思考，您似乎对技术创新特别感兴趣。")
            insights.append("您的思维模式显示出强烈的创造性倾向。")
            isAnalyzing = false
        }
    }
}

struct InsightCardDetail: View {
    let insight: String
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.title2)
            
            Text(insight)
                .font(.body)
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

// MARK: - Collaboration View
struct CollaborationView: View {
    var body: some View {
        ContentUnavailableView(
            "协作功能即将推出",
            systemImage: "person.2.fill",
            description: Text("与团队成员共同构建思维网络")
        )
    }
}

// MARK: - Structural Analysis View
struct StructuralAnalysisViewDetail: View {
    @Query private var nodes: [ThoughtNode]
    @Query private var connections: [NodeConnection]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Statistics
                HStack(spacing: 20) {
                    StatCardDetail(
                        title: "节点总数", 
                        value: "\(nodes.count)", 
                        icon: "circle.hexagongrid",
                        color: .blue
                    )
                    StatCardDetail(
                        title: "连接数", 
                        value: "\(connections.count)", 
                        icon: "link",
                        color: .green
                    )
                    StatCardDetail(
                        title: "平均连接度", 
                        value: String(format: "%.1f", avgConnections), 
                        icon: "network",
                        color: .purple
                    )
                }
                .padding(.horizontal)
                
                // Node type distribution
                VStack(alignment: .leading) {
                    Text("节点类型分布")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(NodeType.allCases, id: \.self) { type in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundColor(type.color)
                            Text(type.displayName)
                            Spacer()
                            Text("\(nodeCount(for: type))")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("结构分析")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }
    
    private var avgConnections: Double {
        guard !nodes.isEmpty else { return 0 }
        return Double(connections.count * 2) / Double(nodes.count)
    }
    
    private func nodeCount(for type: NodeType) -> Int {
        nodes.filter { $0.nodeType == type }.count
    }
}

struct StatCardDetail: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.title)
                .bold()
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}