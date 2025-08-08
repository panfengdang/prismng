//
//  MemoryManagementView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import Charts

struct MemoryManagementView: View {
    @ObservedObject var forgettingService: MemoryForgettingService
    @ObservedObject var canvasViewModel: CanvasViewModel
    @State private var selectedTab = 0
    @State private var showParameterSettings = false
    @State private var selectedNode: ThoughtNode?
    @State private var showForgottenDetail = false
    @State private var selectedForgottenNode: ForgottenNode?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selection
                Picker("View", selection: $selectedTab) {
                    Text("记忆健康").tag(0)
                    Text("节点评分").tag(1)
                    Text("遗忘之舟").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case 0:
                    MemoryHealthView(
                        forgettingService: forgettingService,
                        canvasViewModel: canvasViewModel
                    )
                case 1:
                    NodeScoreListView(
                        forgettingService: forgettingService,
                        canvasViewModel: canvasViewModel,
                        selectedNode: $selectedNode
                    )
                case 2:
                    ForgottenNodesView(
                        forgettingService: forgettingService,
                        selectedForgottenNode: $selectedForgottenNode,
                        showDetail: $showForgottenDetail
                    )
                default:
                    EmptyView()
                }
            }
            .navigationTitle("记忆管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showParameterSettings = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await analyzeMemory()
                        }
                    } label: {
                        if forgettingService.isAnalyzing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(forgettingService.isAnalyzing)
                }
            }
        }
        .sheet(isPresented: $showParameterSettings) {
            ForgettingParametersView(forgettingService: forgettingService)
        }
        .sheet(item: $selectedNode) { node in
            NodeMemoryDetailView(
                node: node,
                memoryScore: forgettingService.memoryScores[node.id],
                forgettingService: forgettingService
            )
        }
        .sheet(isPresented: $showForgottenDetail) {
            if let forgottenNode = selectedForgottenNode {
                ForgottenNodeDetailView(
                    forgottenNode: forgottenNode,
                    forgettingService: forgettingService
                )
            }
        }
    }
    
    private func analyzeMemory() async {
        await forgettingService.analyzeMemoryScores(for: canvasViewModel.thoughtNodes)
    }
}

// MARK: - Memory Health View
struct MemoryHealthView: View {
    @ObservedObject var forgettingService: MemoryForgettingService
    @ObservedObject var canvasViewModel: CanvasViewModel
    
    var stats: MemoryHealthStats {
        forgettingService.memoryHealthStats
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall Health Score
                HealthScoreCard(score: stats.averageMemoryScore)
                
                // Statistics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(
                        title: "总节点数",
                        value: "\(stats.totalNodes)",
                        icon: "circle.grid.3x3.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "健康节点",
                        value: "\(stats.healthyNodes)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "风险节点",
                        value: "\(stats.atRiskNodes)",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "可遗忘节点",
                        value: "\(stats.forgettableNodes)",
                        icon: "minus.circle.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                // Memory Score Distribution Chart
                if !forgettingService.memoryScores.isEmpty {
                    MemoryScoreDistributionChart(scores: forgettingService.memoryScores)
                        .frame(height: 200)
                        .padding()
                }
                
                // Last Analysis Info
                if let lastAnalysis = forgettingService.lastAnalysisDate {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text("上次分析: \(lastAnalysis, formatter: relativeDateFormatter)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
        }
    }
}

// MARK: - Health Score Card
struct HealthScoreCard: View {
    let score: Double
    
    var healthStatus: (text: String, color: Color) {
        switch score {
        case 0.8...1.0:
            return ("优秀", .green)
        case 0.6..<0.8:
            return ("良好", .blue)
        case 0.4..<0.6:
            return ("一般", .orange)
        default:
            return ("需要关注", .red)
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("记忆健康度")
                .font(.headline)
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score))
                    .stroke(healthStatus.color, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1), value: score)
                
                VStack {
                    Text("\(Int(score * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(healthStatus.text)
                        .font(.caption)
                        .foregroundColor(healthStatus.color)
                }
            }
            .frame(width: 150, height: 150)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 5)
        )
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Memory Score Distribution Chart
struct MemoryScoreDistributionChart: View {
    let scores: [UUID: MemoryScore]
    
    var distribution: [(range: String, count: Int)] {
        let bins: [(Range<Double>, String)] = [
            (0.0..<0.2, "0-20%"),
            (0.2..<0.4, "20-40%"),
            (0.4..<0.6, "40-60%"),
            (0.6..<0.8, "60-80%")
        ]
        
        let lastBin: (ClosedRange<Double>, String) = (0.8...1.0, "80-100%")
        
        var results = bins.map { range, label in
            let count = scores.values.filter { range.contains($0.overallScore) }.count
            return (label, count)
        }
        
        // Add the last bin
        let lastCount = scores.values.filter { lastBin.0.contains($0.overallScore) }.count
        results.append((lastBin.1, lastCount))
        
        return results
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("记忆分数分布")
                .font(.headline)
                .padding(.bottom, 8)
            
            Chart(distribution, id: \.range) { item in
                BarMark(
                    x: .value("Range", item.range),
                    y: .value("Count", item.count)
                )
                .foregroundStyle(Color.blue.gradient)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Node Score List View
struct NodeScoreListView: View {
    @ObservedObject var forgettingService: MemoryForgettingService
    @ObservedObject var canvasViewModel: CanvasViewModel
    @Binding var selectedNode: ThoughtNode?
    @State private var sortOrder: SortOrder = .score
    @State private var filterType: FilterType = .all
    
    enum SortOrder {
        case score, time, name
    }
    
    enum FilterType: String, CaseIterable {
        case all = "全部"
        case healthy = "健康"
        case atRisk = "风险"
        case forgettable = "可遗忘"
    }
    
    var filteredNodes: [(ThoughtNode, MemoryScore)] {
        let nodes = canvasViewModel.thoughtNodes.compactMap { node -> (ThoughtNode, MemoryScore)? in
            guard let score = forgettingService.memoryScores[node.id] else { return nil }
            
            switch filterType {
            case .all:
                return (node, score)
            case .healthy:
                return score.overallScore > 0.7 ? (node, score) : nil
            case .atRisk:
                return score.overallScore > 0.3 && score.overallScore <= 0.7 ? (node, score) : nil
            case .forgettable:
                return score.shouldForget ? (node, score) : nil
            }
        }
        
        switch sortOrder {
        case .score:
            return nodes.sorted { $0.1.overallScore > $1.1.overallScore }
        case .time:
            return nodes.sorted { $0.0.createdAt > $1.0.createdAt }
        case .name:
            return nodes.sorted { $0.0.content < $1.0.content }
        }
    }
    
    var body: some View {
        VStack {
            // Filter and Sort Controls
            HStack {
                Picker("Filter", selection: $filterType) {
                    ForEach(FilterType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                
                Spacer()
                
                Menu {
                    Button("按分数") { sortOrder = .score }
                    Button("按时间") { sortOrder = .time }
                    Button("按名称") { sortOrder = .name }
                } label: {
                    Label("排序", systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            
            // Node List
            List(filteredNodes, id: \.0.id) { node, score in
                NodeScoreRow(
                    node: node,
                    score: score,
                    onTap: {
                        selectedNode = node
                    },
                    onForget: {
                        Task {
                            await forgettingService.forgetNode(node)
                        }
                    }
                )
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Node Score Row
struct NodeScoreRow: View {
    let node: ThoughtNode
    let score: MemoryScore
    let onTap: () -> Void
    let onForget: () -> Void
    
    var scoreColor: Color {
        switch score.overallScore {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(node.content)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Label(node.nodeType.rawValue.capitalized, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if score.shouldForget {
                        Label("可遗忘", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(Int(score.overallScore * 100))%")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor)
                
                if score.shouldForget {
                    Button {
                        onForget()
                    } label: {
                        Text("遗忘")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Forgotten Nodes View
struct ForgottenNodesView: View {
    @ObservedObject var forgettingService: MemoryForgettingService
    @Binding var selectedForgottenNode: ForgottenNode?
    @Binding var showDetail: Bool
    
    var body: some View {
        if forgettingService.forgottenNodes.isEmpty {
            ContentUnavailableView(
                "遗忘之舟为空",
                systemImage: "ferry",
                description: Text("被遗忘的节点将在这里显示")
            )
        } else {
            List(forgettingService.forgottenNodes) { forgottenNode in
                ForgottenNodeRow(
                    forgottenNode: forgottenNode,
                    onTap: {
                        selectedForgottenNode = forgottenNode
                        showDetail = true
                    },
                    onRecall: {
                        Task {
                            await forgettingService.recallNode(forgottenNode)
                        }
                    }
                )
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Forgotten Node Row
struct ForgottenNodeRow: View {
    let forgottenNode: ForgottenNode
    let onTap: () -> Void
    let onRecall: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(forgottenNode.content)
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(.secondary)
            
            HStack {
                Label(forgottenNode.nodeType.rawValue.capitalized, systemImage: "tag")
                    .font(.caption)
                
                Spacer()
                
                Text("遗忘于 \(forgottenNode.forgottenAt, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text(forgottenNode.reason)
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Button {
                    onRecall()
                } label: {
                    Label("召回", systemImage: "arrow.uturn.backward")
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Parameter Settings View
struct ForgettingParametersView: View {
    @ObservedObject var forgettingService: MemoryForgettingService
    @Environment(\.dismiss) private var dismiss
    @State private var parameters: ForgettingParameters
    
    init(forgettingService: MemoryForgettingService) {
        self.forgettingService = forgettingService
        self._parameters = State(initialValue: forgettingService.parameters)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("遗忘策略") {
                    Picker("策略类型", selection: $parameters.strategy) {
                        ForEach(ForgettingStrategy.allCases, id: \.self) { strategy in
                            Text(strategy.displayName).tag(strategy)
                        }
                    }
                    
                    Toggle("启用自动遗忘", isOn: $parameters.enableAutoForgetting)
                }
                
                Section("参数设置") {
                    HStack {
                        Text("衰减率")
                        Slider(value: $parameters.decayRate, in: 0...1)
                        Text("\(Int(parameters.decayRate * 100))%")
                            .frame(width: 50)
                    }
                    
                    HStack {
                        Text("遗忘阈值")
                        Slider(value: $parameters.forgettingThreshold, in: 0...1)
                        Text("\(Int(parameters.forgettingThreshold * 100))%")
                            .frame(width: 50)
                    }
                    
                    HStack {
                        Text("最低保留分数")
                        Slider(value: $parameters.minimumRetentionScore, in: 0...1)
                        Text("\(Int(parameters.minimumRetentionScore * 100))%")
                            .frame(width: 50)
                    }
                }
                
                Section("保护设置") {
                    Stepper("保护期: \(parameters.protectionPeriodDays) 天",
                            value: $parameters.protectionPeriodDays,
                            in: 1...30)
                    
                    Stepper("最大遗忘数: \(parameters.maxForgottenNodes)",
                            value: $parameters.maxForgottenNodes,
                            in: 10...500,
                            step: 10)
                }
            }
            .navigationTitle("遗忘参数")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        forgettingService.updateParameters(parameters)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Node Memory Detail View
struct NodeMemoryDetailView: View {
    let node: ThoughtNode
    let memoryScore: MemoryScore?
    @ObservedObject var forgettingService: MemoryForgettingService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Node Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("节点内容")
                            .font(.headline)
                        Text(node.content)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Memory Scores
                    if let score = memoryScore {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("记忆评分")
                                .font(.headline)
                            
                            ScoreRow(title: "时间分数", score: score.timeScore)
                            ScoreRow(title: "频率分数", score: score.frequencyScore)
                            ScoreRow(title: "重要性分数", score: score.importanceScore)
                            ScoreRow(title: "情感分数", score: score.emotionalScore)
                            ScoreRow(title: "连接分数", score: score.connectionScore)
                            
                            Divider()
                            
                            HStack {
                                Text("总体分数")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(Int(score.overallScore * 100))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(scoreColor(for: score.overallScore))
                            }
                            
                            if score.shouldForget, let reason = score.forgettingReason {
                                Label(reason, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Actions
                    if let score = memoryScore, score.shouldForget {
                        Button {
                            Task {
                                await forgettingService.forgetNode(node)
                                dismiss()
                            }
                        } label: {
                            Label("遗忘此节点", systemImage: "minus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("节点记忆详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func scoreColor(for score: Double) -> Color {
        switch score {
        case 0.7...1.0: return .green
        case 0.4..<0.7: return .orange
        default: return .red
        }
    }
}

struct ScoreRow: View {
    let title: String
    let score: Double
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(Int(score * 100))%")
                .fontWeight(.medium)
        }
    }
}

// MARK: - Forgotten Node Detail View
struct ForgottenNodeDetailView: View {
    let forgottenNode: ForgottenNode
    @ObservedObject var forgettingService: MemoryForgettingService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("原始内容")
                            .font(.headline)
                        Text(forgottenNode.content)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Text("遗忘信息")
                            .font(.headline)
                        
                        InfoRow(label: "节点类型", value: forgottenNode.nodeType.rawValue.capitalized)
                        InfoRow(label: "创建时间", value: dateFormatter.string(from: forgottenNode.createdAt))
                        InfoRow(label: "遗忘时间", value: dateFormatter.string(from: forgottenNode.forgottenAt))
                        InfoRow(label: "遗忘原因", value: forgottenNode.reason)
                        InfoRow(label: "最终分数", value: "\(Int(forgottenNode.memoryScore * 100))%")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Recall Button
                    Button {
                        Task {
                            await forgettingService.recallNode(forgottenNode)
                            dismiss()
                        }
                    } label: {
                        Label("召回节点", systemImage: "arrow.uturn.backward.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
            .navigationTitle("遗忘节点详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Date Formatters
let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

let relativeDateFormatter: RelativeDateTimeFormatter = {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter
}()

#Preview {
    MemoryManagementView(
        forgettingService: MemoryForgettingService(),
        canvasViewModel: CanvasViewModel()
    )
}