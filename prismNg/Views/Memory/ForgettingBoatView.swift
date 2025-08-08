//
//  ForgettingBoatView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP1c: Forgetting Boat View - 遗忘之舟系统界面
//

import SwiftUI
import Charts

// MARK: - Forgetting Boat Main View

/// 遗忘之舟主界面：优雅的记忆管理系统
struct ForgettingBoatView: View {
    @ObservedObject var memoryService: MemoryForgettingService
    @State private var selectedTab: ForgettingTab = .overview
    @State private var showingSettings = false
    @State private var showingForgottenVault = false
    
    enum ForgettingTab: String, CaseIterable {
        case overview = "概览"
        case analysis = "分析"
        case voyage = "航行"
        case vault = "记忆宝库"
        
        var icon: String {
            switch self {
            case .overview: return "chart.pie"
            case .analysis: return "brain.head.profile"
            case .voyage: return "sailboat"
            case .vault: return "archivebox"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with memory health status
                MemoryHealthHeader(memoryService: memoryService)
                
                // Tab bar
                ForgettingTabBar(selectedTab: $selectedTab)
                
                // Content area
                TabView(selection: $selectedTab) {
                    // Overview tab
                    MemoryOverviewView(memoryService: memoryService)
                        .tag(ForgettingTab.overview)
                    
                    // Analysis tab
                    MemoryAnalysisView(memoryService: memoryService)
                        .tag(ForgettingTab.analysis)
                    
                    // Voyage tab (forgetting process)
                    ForgettingVoyageView(memoryService: memoryService)
                        .tag(ForgettingTab.voyage)
                    
                    // Vault tab (forgotten memories)
                    ForgottenVaultView(memoryService: memoryService)
                        .tag(ForgettingTab.vault)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("遗忘之舟")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                ForgettingSettingsView(memoryService: memoryService)
            }
        }
    }
}

// MARK: - Memory Health Header

struct MemoryHealthHeader: View {
    @ObservedObject var memoryService: MemoryForgettingService
    
    var body: some View {
        let stats = memoryService.memoryHealthStats
        
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("记忆健康度")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(healthDescription(for: stats.averageMemoryScore))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Health score circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(stats.averageMemoryScore))
                        .stroke(healthColor(for: stats.averageMemoryScore), lineWidth: 8)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: stats.averageMemoryScore)
                    
                    Text("\(Int(stats.averageMemoryScore * 100))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(healthColor(for: stats.averageMemoryScore))
                }
            }
            
            // Quick stats
            HStack(spacing: 16) {
                HealthStatChip(
                    icon: "brain",
                    title: "活跃记忆",
                    value: "\(stats.totalNodes)",
                    color: .blue
                )
                
                HealthStatChip(
                    icon: "heart.fill",
                    title: "健康记忆",
                    value: "\(stats.healthyNodes)",
                    color: .green
                )
                
                HealthStatChip(
                    icon: "exclamationmark.triangle",
                    title: "风险记忆",
                    value: "\(stats.atRiskNodes)",
                    color: .orange
                )
                
                HealthStatChip(
                    icon: "moon.zzz",
                    title: "已遗忘",
                    value: "\(stats.forgottenNodes)",
                    color: .purple
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .padding(.horizontal)
    }
    
    private func healthDescription(for score: Double) -> String {
        switch score {
        case 0.8...:
            return "记忆系统运行良好，思维清晰有序"
        case 0.6..<0.8:
            return "记忆系统健康，建议适度清理"
        case 0.4..<0.6:
            return "记忆负载较重，需要主动遗忘"
        default:
            return "记忆系统需要深度清理和优化"
        }
    }
    
    private func healthColor(for score: Double) -> Color {
        switch score {
        case 0.8...: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .orange
        default: return .red
        }
    }
}

struct HealthStatChip: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.callout)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Forgetting Tab Bar

struct ForgettingTabBar: View {
    @Binding var selectedTab: ForgettingBoatView.ForgettingTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ForgettingBoatView.ForgettingTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .regular))
                        
                        Text(tab.rawValue)
                            .font(.caption2)
                    }
                    .foregroundColor(selectedTab == tab ? .blue : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// MARK: - Memory Overview View

struct MemoryOverviewView: View {
    @ObservedObject var memoryService: MemoryForgettingService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Memory distribution chart
                MemoryDistributionChart(memoryService: memoryService)
                
                // Recent forgetting activity
                RecentForgettingActivity(memoryService: memoryService)
                
                // Memory insights
                MemoryInsightsCard(memoryService: memoryService)
            }
            .padding()
        }
    }
}

struct MemoryDistributionChart: View {
    @ObservedObject var memoryService: MemoryForgettingService
    
    var body: some View {
        let stats = memoryService.memoryHealthStats
        
        VStack(alignment: .leading, spacing: 12) {
            Text("记忆分布")
                .font(.headline)
            
            Chart {
                SectorMark(
                    angle: .value("健康记忆", stats.healthyNodes),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(.green)
                .opacity(0.8)
                
                SectorMark(
                    angle: .value("风险记忆", stats.atRiskNodes),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(.orange)
                .opacity(0.8)
                
                SectorMark(
                    angle: .value("可遗忘", stats.forgettableNodes),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(.red)
                .opacity(0.8)
                
                SectorMark(
                    angle: .value("已遗忘", stats.forgottenNodes),
                    innerRadius: .ratio(0.6),
                    angularInset: 2
                )
                .foregroundStyle(.purple)
                .opacity(0.8)
            }
            .frame(height: 200)
            .chartBackground { _ in
                VStack {
                    Text("\(stats.totalNodes)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("总记忆")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .green, label: "健康", count: stats.healthyNodes)
                LegendItem(color: .orange, label: "风险", count: stats.atRiskNodes)
                LegendItem(color: .red, label: "可遗忘", count: stats.forgettableNodes)
                LegendItem(color: .purple, label: "已遗忘", count: stats.forgottenNodes)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption2)
            
            Text("(\(count))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct RecentForgettingActivity: View {
    @ObservedObject var memoryService: MemoryForgettingService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.blue)
                
                Text("最近的遗忘活动")
                    .font(.headline)
            }
            
            if memoryService.forgottenNodes.isEmpty {
                EmptyForgettingState()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(memoryService.forgottenNodes.suffix(5).reversed()) { forgottenNode in
                        ForgettingBoatNodeRow(forgottenNode: forgottenNode)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct EmptyForgettingState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "leaf")
                .font(.title)
                .foregroundColor(.green)
            
            Text("记忆保持良好")
                .font(.callout)
                .fontWeight(.medium)
            
            Text("暂时没有需要遗忘的记忆")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct ForgettingBoatNodeRow: View {
    let forgottenNode: ForgottenNode
    
    var body: some View {
        HStack(spacing: 12) {
            // Node type icon
            Image(systemName: forgottenNode.nodeType.icon)
                .foregroundColor(.purple)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(forgottenNode.content.prefix(50) + (forgottenNode.content.count > 50 ? "..." : ""))
                    .font(.callout)
                    .lineLimit(1)
                
                Text(forgottenNode.reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(forgottenNode.forgottenAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(Int(forgottenNode.memoryScore * 100))%")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

struct MemoryInsightsCard: View {
    @ObservedObject var memoryService: MemoryForgettingService
    
    var body: some View {
        let stats = memoryService.memoryHealthStats
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                
                Text("记忆洞察")
                    .font(.headline)
            }
            
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(generateInsights(from: stats), id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                            .padding(.top, 6)
                        
                        Text(insight)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
    }
    
    private func generateInsights(from stats: MemoryHealthStats) -> [String] {
        var insights: [String] = []
        
        if stats.averageMemoryScore > 0.8 {
            insights.append("你的记忆系统运行得很好，保持着健康的认知状态。")
        }
        
        if stats.atRiskNodes > stats.totalNodes / 3 {
            insights.append("有相当数量的记忆处于风险状态，建议考虑启动遗忘航行。")
        }
        
        if stats.forgottenNodes > 10 {
            insights.append("你已经成功遗忘了 \(stats.forgottenNodes) 个记忆，为新的思考腾出了空间。")
        }
        
        if stats.forgettableNodes > 5 {
            insights.append("检测到 \(stats.forgettableNodes) 个可以遗忘的记忆，它们的价值已经衰减。")
        }
        
        if insights.isEmpty {
            insights.append("你的记忆系统保持着良好的平衡状态。")
        }
        
        return insights
    }
}

// MARK: - Memory Analysis View

struct MemoryAnalysisView: View {
    @ObservedObject var memoryService: MemoryForgettingService
    @State private var isAnalyzing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Analysis controls
                AnalysisControlsCard(
                    isAnalyzing: $isAnalyzing,
                    onAnalyze: {
                        Task {
                            isAnalyzing = true
                            // In real implementation, would trigger analysis
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            isAnalyzing = false
                        }
                    }
                )
                
                // Memory scores visualization
                MemoryScoresView(memoryService: memoryService)
                
                // Analysis parameters
                AnalysisParametersCard(memoryService: memoryService)
            }
            .padding()
        }
    }
}

struct AnalysisControlsCard: View {
    @Binding var isAnalyzing: Bool
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                
                Text("记忆分析")
                    .font(.headline)
                
                Spacer()
                
                if isAnalyzing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            Button {
                onAnalyze()
            } label: {
                HStack {
                    Image(systemName: isAnalyzing ? "stop.circle" : "play.circle")
                    Text(isAnalyzing ? "分析中..." : "开始深度分析")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isAnalyzing)
            
            Text("分析所有记忆的健康状况，识别可以遗忘的低价值记忆")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct MemoryScoresView: View {
    @ObservedObject var memoryService: MemoryForgettingService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("记忆评分分布")
                .font(.headline)
            
            if memoryService.memoryScores.isEmpty {
                EmptyScoresState()
            } else {
                MemoryScoreHistogram(scores: Array(memoryService.memoryScores.values))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct EmptyScoresState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("运行分析以查看记忆评分")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct MemoryScoreHistogram: View {
    let scores: [MemoryScore]
    
    var body: some View {
        let buckets = createHistogramBuckets(from: scores)
        
        Chart {
            ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                BarMark(
                    x: .value("分数区间", bucket.label),
                    y: .value("数量", bucket.count)
                )
                .foregroundStyle(colorForBucket(index))
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel()
                    .font(.caption2)
            }
        }
    }
    
    private func createHistogramBuckets(from scores: [MemoryScore]) -> [(label: String, count: Int)] {
        let buckets = [
            ("0-0.2", scores.filter { $0.overallScore < 0.2 }.count),
            ("0.2-0.4", scores.filter { $0.overallScore >= 0.2 && $0.overallScore < 0.4 }.count),
            ("0.4-0.6", scores.filter { $0.overallScore >= 0.4 && $0.overallScore < 0.6 }.count),
            ("0.6-0.8", scores.filter { $0.overallScore >= 0.6 && $0.overallScore < 0.8 }.count),
            ("0.8-1.0", scores.filter { $0.overallScore >= 0.8 }.count)
        ]
        
        return buckets.map { (label: $0.0, count: $0.1) }
    }
    
    private func colorForBucket(_ index: Int) -> Color {
        let colors: [Color] = [.red, .orange, .yellow, .blue, .green]
        return colors[safe: index] ?? .gray
    }
}

struct AnalysisParametersCard: View {
    @ObservedObject var memoryService: MemoryForgettingService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分析参数")
                .font(.headline)
            
            VStack(spacing: 8) {
                ParameterRow(
                    title: "遗忘策略",
                    value: memoryService.parameters.strategy.displayName,
                    icon: "brain"
                )
                
                ParameterRow(
                    title: "遗忘阈值",
                    value: String(format: "%.1f", memoryService.parameters.forgettingThreshold),
                    icon: "slider.horizontal.3"
                )
                
                ParameterRow(
                    title: "保护期",
                    value: "\(memoryService.parameters.protectionPeriodDays) 天",
                    icon: "shield"
                )
                
                ParameterRow(
                    title: "衰减率",
                    value: String(format: "%.1f", memoryService.parameters.decayRate),
                    icon: "waveform.path.ecg"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct ParameterRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.callout)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Forgetting Voyage View

struct ForgettingVoyageView: View {
    @ObservedObject var memoryService: MemoryForgettingService
    @State private var isVoyaging = false
    @State private var voyageProgress: Double = 0.0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Voyage visualization
                VoyageVisualization(
                    isVoyaging: $isVoyaging,
                    progress: $voyageProgress
                )
                
                // Voyage controls
                VoyageControlsCard(
                    isVoyaging: $isVoyaging,
                    progress: $voyageProgress,
                    memoryService: memoryService
                )
                
                // Candidates for forgetting
                ForgettingCandidatesCard(memoryService: memoryService)
            }
            .padding()
        }
    }
}

struct VoyageVisualization: View {
    @Binding var isVoyaging: Bool
    @Binding var progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Ocean waves background
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 200)
                
                // Boat
                VStack {
                    Image(systemName: "sailboat")
                        .font(.system(size: 40))
                        .foregroundColor(.brown)
                        .rotationEffect(.degrees(isVoyaging ? 5 : 0))
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isVoyaging)
                    
                    Text(isVoyaging ? "航行中..." : "遗忘之舟")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .offset(x: isVoyaging ? CGFloat(progress * 100 - 50) : 0)
                .animation(.linear(duration: 1), value: progress)
            }
            
            if isVoyaging {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(y: 2)
            }
        }
    }
}

struct VoyageControlsCard: View {
    @Binding var isVoyaging: Bool
    @Binding var progress: Double
    @ObservedObject var memoryService: MemoryForgettingService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sailboat")
                    .foregroundColor(.blue)
                
                Text("启动遗忘航行")
                    .font(.headline)
            }
            
            if !isVoyaging {
                VStack(spacing: 12) {
                    Text("将低价值的记忆送上遗忘之舟，为新的思考腾出空间")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        startVoyage()
                    } label: {
                        HStack {
                            Image(systemName: "play.circle")
                            Text("开始航行")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Text("遗忘之舟正在前行...")
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Text("已处理 \(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func startVoyage() {
        isVoyaging = true
        progress = 0.0
        
        // Simulate voyage progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            progress += 0.02
            
            if progress >= 1.0 {
                timer.invalidate()
                isVoyaging = false
                progress = 0.0
            }
        }
    }
}

struct ForgettingCandidatesCard: View {
    @ObservedObject var memoryService: MemoryForgettingService
    
    var body: some View {
        let candidates = memoryService.memoryScores.values
            .filter { $0.shouldForget }
            .sorted { $0.overallScore < $1.overallScore }
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet")
                    .foregroundColor(.orange)
                
                Text("遗忘候选")
                    .font(.headline)
                
                Spacer()
                
                Text("\(candidates.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
            
            if candidates.isEmpty {
                EmptyCandidatesState()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(candidates.prefix(10).enumerated()), id: \.offset) { index, score in
                        CandidateRow(score: score, rank: index + 1)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct EmptyCandidatesState: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.title)
                .foregroundColor(.green)
            
            Text("没有需要遗忘的记忆")
                .font(.callout)
                .fontWeight(.medium)
            
            Text("你的记忆系统很健康")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

struct CandidateRow: View {
    let score: MemoryScore
    let rank: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.orange.opacity(0.2)))
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("记忆节点 \(score.nodeId.uuidString.prefix(8))")
                    .font(.callout)
                    .fontWeight(.medium)
                
                if let reason = score.forgettingReason {
                    Text(reason)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(score.overallScore * 100))%")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                
                Text("评分")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Forgotten Vault View

struct ForgottenVaultView: View {
    @ObservedObject var memoryService: MemoryForgettingService
    @State private var searchText = ""
    @State private var selectedNode: ForgottenNode?
    @State private var showingNodeDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            SearchBar(text: $searchText)
                .padding()
            
            // Forgotten memories list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredForgottenNodes) { forgottenNode in
                        ForgottenMemoryCard(
                            forgottenNode: forgottenNode,
                            onTap: {
                                selectedNode = forgottenNode
                                showingNodeDetail = true
                            },
                            onRecall: {
                                Task {
                                    await memoryService.recallNode(forgottenNode)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingNodeDetail) {
            if let node = selectedNode {
                ForgettingBoatNodeDetailView(forgottenNode: node, memoryService: memoryService)
            }
        }
    }
    
    private var filteredForgottenNodes: [ForgottenNode] {
        if searchText.isEmpty {
            return memoryService.forgottenNodes.sorted { $0.forgottenAt > $1.forgottenAt }
        } else {
            return memoryService.forgottenNodes.filter {
                $0.content.localizedCaseInsensitiveContains(searchText) ||
                $0.reason.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.forgottenAt > $1.forgottenAt }
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("搜索已遗忘的记忆...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

struct ForgottenMemoryCard: View {
    let forgottenNode: ForgottenNode
    let onTap: () -> Void
    let onRecall: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: forgottenNode.nodeType.icon)
                    .foregroundColor(.purple)
                
                Text(forgottenNode.nodeType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(forgottenNode.forgottenAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Content preview
            Text(forgottenNode.content)
                .font(.callout)
                .lineLimit(3)
                .onTapGesture(perform: onTap)
            
            // Footer
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("遗忘原因")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(forgottenNode.reason)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("记忆评分")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(forgottenNode.memoryScore * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.purple)
                }
                
                Button("召回") {
                    onRecall()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct ForgettingBoatNodeDetailView: View {
    let forgottenNode: ForgottenNode
    @ObservedObject var memoryService: MemoryForgettingService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Content
                    Text(forgottenNode.content)
                        .font(.body)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    
                    // Metadata
                    MetadataCard(forgottenNode: forgottenNode)
                    
                    // Actions
                    Button {
                        Task {
                            await memoryService.recallNode(forgottenNode)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.uturn.backward.circle")
                            Text("召回此记忆")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding()
            }
            .navigationTitle("遗忘的记忆")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MetadataCard: View {
    let forgottenNode: ForgottenNode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("记忆信息")
                .font(.headline)
            
            VStack(spacing: 8) {
                MetadataRow(title: "类型", value: forgottenNode.nodeType.displayName)
                MetadataRow(title: "创建时间", value: forgottenNode.createdAt.formatted(date: .abbreviated, time: .shortened))
                MetadataRow(title: "遗忘时间", value: forgottenNode.forgottenAt.formatted(date: .abbreviated, time: .shortened))
                MetadataRow(title: "遗忘原因", value: forgottenNode.reason)
                MetadataRow(title: "记忆评分", value: "\(Int(forgottenNode.memoryScore * 100))%")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct MetadataRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Forgetting Settings View

struct ForgettingSettingsView: View {
    @ObservedObject var memoryService: MemoryForgettingService
    @Environment(\.dismiss) private var dismiss
    @State private var parameters: ForgettingParameters
    
    init(memoryService: MemoryForgettingService) {
        self.memoryService = memoryService
        self._parameters = State(initialValue: memoryService.parameters)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("遗忘策略") {
                    Picker("策略", selection: $parameters.strategy) {
                        ForEach(ForgettingStrategy.allCases, id: \.self) { strategy in
                            Text(strategy.displayName).tag(strategy)
                        }
                    }
                    
                    Toggle("启用自动遗忘", isOn: $parameters.enableAutoForgetting)
                }
                
                Section("阈值设置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("遗忘阈值: \(parameters.forgettingThreshold, specifier: "%.2f")")
                        Slider(value: $parameters.forgettingThreshold, in: 0.1...0.9)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("衰减率: \(parameters.decayRate, specifier: "%.2f")")
                        Slider(value: $parameters.decayRate, in: 0.01...0.5)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最低保留分数: \(parameters.minimumRetentionScore, specifier: "%.2f")")
                        Slider(value: $parameters.minimumRetentionScore, in: 0.1...0.5)
                    }
                }
                
                Section("保护设置") {
                    Stepper("保护期: \(parameters.protectionPeriodDays) 天", 
                           value: $parameters.protectionPeriodDays, 
                           in: 1...30)
                    
                    Stepper("最大遗忘数量: \(parameters.maxForgottenNodes)", 
                           value: $parameters.maxForgottenNodes, 
                           in: 10...500)
                }
            }
            .navigationTitle("遗忘设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        memoryService.updateParameters(parameters)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// NodeType extension removed - already defined in ModernCanvasView

#Preview {
    ForgettingBoatView(memoryService: MemoryForgettingService())
}