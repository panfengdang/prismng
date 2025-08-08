//
//  GrowthOptimizationService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Growth Optimization Service
@MainActor
class GrowthOptimizationService: ObservableObject {
    @Published var userEngagementScore: Double = 0.0
    @Published var conversionRecommendations: [ConversionRecommendation] = []
    @Published var growthInsights: [GrowthInsight] = []
    @Published var optimizationTriggers: [String] = []
    
    private let quotaService: QuotaManagementService
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    // Analytics tracking
    private var sessionStartTime: Date = Date()
    private var nodeCreationCount = 0
    private var connectionCreationCount = 0
    private var aiInteractionCount = 0
    private var featureUsageCounts: [String: Int] = [:]
    
    init(quotaService: QuotaManagementService) {
        self.quotaService = quotaService
        setupAnalytics()
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        startGrowthAnalysis()
    }
    
    // MARK: - Analytics Setup
    
    private func setupAnalytics() {
        // Track quota usage patterns
        quotaService.$currentQuotaUsage
            .sink { [weak self] usage in
                let remaining = (self?.quotaService.dailyQuota ?? 0) - usage
                self?.analyzeQuotaUsagePattern(remaining: remaining)
            }
            .store(in: &cancellables)
        
        // Track subscription tier changes based on quota limit
        quotaService.$dailyQuotaLimit
            .sink { [weak self] quota in
                self?.analyzeSubscriptionBehavior(dailyQuota: quota)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Growth Analysis
    
    private func startGrowthAnalysis() {
        // Perform periodic growth analysis
        Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { _ in
            Task { @MainActor in
                await self.performGrowthAnalysis()
            }
        }
    }
    
    func performGrowthAnalysis() async {
        guard let modelContext = modelContext else { return }
        
        do {
            // Calculate user engagement score
            userEngagementScore = await calculateEngagementScore()
            
            // Generate conversion recommendations
            conversionRecommendations = await generateConversionRecommendations()
            
            // Generate growth insights
            growthInsights = await generateGrowthInsights()
            
            // Update optimization triggers
            optimizationTriggers = await identifyOptimizationTriggers()
            
        } catch {
            print("Growth analysis failed: \(error)")
        }
    }
    
    // MARK: - Engagement Scoring
    
    private func calculateEngagementScore() async -> Double {
        guard let modelContext = modelContext else { return 0.0 }
        
        var score: Double = 0.0
        
        do {
            // Node creation activity (30% of score)
            let nodeDescriptor = FetchDescriptor<ThoughtNode>()
            let nodes = try modelContext.fetch(nodeDescriptor)
            let recentNodes = nodes.filter { $0.createdAt > Date().addingTimeInterval(-86400) } // Last 24 hours
            score += min(Double(recentNodes.count) / 10.0, 0.3) * 100
            
            // Connection creation activity (25% of score)
            let connectionDescriptor = FetchDescriptor<NodeConnection>()
            let connections = try modelContext.fetch(connectionDescriptor)
            let recentConnections = connections.filter { $0.createdAt > Date().addingTimeInterval(-86400) }
            score += min(Double(recentConnections.count) / 5.0, 0.25) * 100
            
            // AI interaction frequency (25% of score)
            let aiScore = min(Double(aiInteractionCount) / 20.0, 0.25) * 100
            score += aiScore
            
            // Session duration (20% of score)
            let sessionDuration = Date().timeIntervalSince(sessionStartTime)
            let sessionScore = min(sessionDuration / 3600.0, 0.2) * 100 // Max 1 hour for full score
            score += sessionScore
            
        } catch {
            print("Failed to calculate engagement score: \(error)")
        }
        
        return min(score, 100.0)
    }
    
    // MARK: - Conversion Recommendations
    
    private func generateConversionRecommendations() async -> [ConversionRecommendation] {
        var recommendations: [ConversionRecommendation] = []
        
        // Analyze quota usage patterns
        if quotaService.dailyQuota <= 2 { // Assume free tier has 2 or fewer daily quota
            let quotaUsageRate = 1.0 - (Double(quotaService.remainingQuota) / Double(quotaService.dailyQuota))
            
            if quotaUsageRate > 0.8 {
                recommendations.append(ConversionRecommendation(
                    type: .subscriptionUpgrade,
                    title: "解锁无限AI协作",
                    description: "您今日的AI配额即将用完。升级订阅享受无限AI协作功能。",
                    priority: .high,
                    estimatedConversionRate: 0.12,
                    trigger: .quotaNearExhaustion
                ))
            } else if quotaUsageRate > 0.5 {
                recommendations.append(ConversionRecommendation(
                    type: .featureHighlight,
                    title: "发现更多AI功能",
                    description: "尝试语音输入、情感洞察等高级功能，提升思维效率。",
                    priority: .medium,
                    estimatedConversionRate: 0.08,
                    trigger: .moderateUsage
                ))
            }
        }
        
        // Analyze engagement patterns
        if userEngagementScore > 70 && quotaService.dailyQuota <= 2 {
            recommendations.append(ConversionRecommendation(
                type: .subscriptionUpgrade,
                title: "成为思维专家",
                description: "您的活跃度很高！升级到专业版解锁更多认知增强功能。",
                priority: .high,
                estimatedConversionRate: 0.15,
                trigger: .highEngagement
            ))
        }
        
        // Feature-specific recommendations
        if nodeCreationCount > 10 && connectionCreationCount < 3 {
            recommendations.append(ConversionRecommendation(
                type: .featureEducation,
                title: "连接您的想法",
                description: "尝试创建节点间的连接，构建完整的思维网络。",
                priority: .medium,
                estimatedConversionRate: 0.25,
                trigger: .underutilizedFeature
            ))
        }
        
        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    // MARK: - Growth Insights
    
    private func generateGrowthInsights() async -> [GrowthInsight] {
        var insights: [GrowthInsight] = []
        
        // Usage pattern insights
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        if sessionDuration > 1800 { // 30 minutes
            insights.append(GrowthInsight(
                category: .usagePattern,
                title: "深度使用模式",
                description: "您在单次会话中花费了超过30分钟，显示出对深度思考的重视。",
                actionable: "考虑使用'审问模式'进行更深入的分析。",
                impact: .positive
            ))
        }
        
        // Feature adoption insights
        let uniqueFeatures = Set(featureUsageCounts.keys).count
        if uniqueFeatures >= 5 {
            insights.append(GrowthInsight(
                category: .featureAdoption,
                title: "多元化功能使用",
                description: "您已经使用了\(uniqueFeatures)种不同的功能，展现出探索精神。",
                actionable: "尝试组合使用不同功能，创造独特的思维工作流。",
                impact: .positive
            ))
        }
        
        // AI collaboration insights
        if aiInteractionCount > 15 {
            insights.append(GrowthInsight(
                category: .aiCollaboration,
                title: "AI协作专家",
                description: "您已经与AI进行了\(aiInteractionCount)次互动，建立了良好的协作模式。",
                actionable: "分享您的使用心得，帮助其他用户发现AI协作的价值。",
                impact: .positive
            ))
        }
        
        return insights
    }
    
    // MARK: - Optimization Triggers
    
    private func identifyOptimizationTriggers() async -> [String] {
        var triggers: [String] = []
        
        // Quota-based triggers
        if quotaService.subscriptionTier == .free && quotaService.remainingQuota < 5 {
            triggers.append("quota_low")
        }
        
        // Engagement-based triggers
        if userEngagementScore > 80 {
            triggers.append("high_engagement")
        }
        
        // Feature usage triggers
        if nodeCreationCount > 20 {
            triggers.append("power_user")
        }
        
        // Time-based triggers
        let sessionDuration = Date().timeIntervalSince(sessionStartTime)
        if sessionDuration > 3600 { // 1 hour
            triggers.append("extended_session")
        }
        
        return triggers
    }
    
    // MARK: - Event Tracking
    
    func trackNodeCreation() {
        nodeCreationCount += 1
        trackFeatureUsage("node_creation")
    }
    
    func trackConnectionCreation() {
        connectionCreationCount += 1
        trackFeatureUsage("connection_creation")
    }
    
    func trackAIInteraction() {
        aiInteractionCount += 1
        trackFeatureUsage("ai_interaction")
    }
    
    func trackFeatureUsage(_ feature: String) {
        featureUsageCounts[feature, default: 0] += 1
        
        // Trigger real-time optimization analysis
        Task {
            await performGrowthAnalysis()
        }
    }
    
    // MARK: - Conversion Analysis
    
    private func analyzeQuotaUsagePattern(remaining: Int) {
        // Implement quota usage pattern analysis
        let usageRate = 1.0 - (Double(remaining) / Double(quotaService.dailyQuota))
        
        if usageRate > 0.9 && quotaService.dailyQuota <= 2 {
            // High likelihood conversion opportunity for free tier
            print("🎯 High conversion opportunity detected: quota near exhaustion")
        }
    }
    
    private func analyzeSubscriptionBehavior(dailyQuota: Int) {
        // Analyze subscription tier based on quota for growth insights
        if dailyQuota <= 2 {
            print("📊 User in free tier - focus on value demonstration")
        } else if dailyQuota <= 10 {
            print("📊 User in basic tier - monitor feature adoption")
        } else if dailyQuota <= 50 {
            print("📊 User in advanced tier - focus on retention")
        } else {
            print("📊 Professional user - potential advocate")
        }
    }
    
    // MARK: - Recommendation Actions
    
    func executeRecommendation(_ recommendation: ConversionRecommendation) {
        switch recommendation.type {
        case .subscriptionUpgrade:
            // Trigger subscription upgrade flow
            print("🚀 Triggering subscription upgrade flow")
            
        case .featureHighlight:
            // Highlight specific features
            print("✨ Highlighting advanced features")
            
        case .featureEducation:
            // Show feature education content
            print("📚 Showing feature education content")
        }
    }
    
    // MARK: - Growth Metrics
    
    func getGrowthMetrics() -> GrowthMetrics {
        return GrowthMetrics(
            engagementScore: userEngagementScore,
            sessionDuration: Date().timeIntervalSince(sessionStartTime),
            nodeCreationCount: nodeCreationCount,
            connectionCreationCount: connectionCreationCount,
            aiInteractionCount: aiInteractionCount,
            uniqueFeatureUsageCount: Set(featureUsageCounts.keys).count,
            conversionLikelihood: calculateConversionLikelihood()
        )
    }
    
    private func calculateConversionLikelihood() -> Double {
        var likelihood: Double = 0.0
        
        // High engagement increases likelihood
        if userEngagementScore > 70 {
            likelihood += 0.3
        }
        
        // Quota pressure increases likelihood (only for free tier)
        if quotaService.dailyQuota <= 2 {
            let quotaUsage = 1.0 - (Double(quotaService.remainingQuota) / Double(quotaService.dailyQuota))
            if quotaUsage > 0.8 {
                likelihood += 0.4
            }
        }
        
        // Feature diversity indicates investment
        let featureDiversity = Double(Set(featureUsageCounts.keys).count) / 10.0
        likelihood += min(featureDiversity, 0.3)
        
        return min(likelihood, 1.0)
    }
}

// MARK: - Supporting Types

struct ConversionRecommendation: Identifiable {
    let id = UUID()
    let type: RecommendationType
    let title: String
    let description: String
    let priority: RecommendationPriority
    let estimatedConversionRate: Double
    let trigger: ConversionTrigger
    
    enum RecommendationType {
        case subscriptionUpgrade
        case featureHighlight
        case featureEducation
    }
    
    enum RecommendationPriority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    enum ConversionTrigger {
        case quotaNearExhaustion
        case highEngagement
        case moderateUsage
        case underutilizedFeature
    }
}

struct GrowthInsight: Identifiable {
    let id = UUID()
    let category: InsightCategory
    let title: String
    let description: String
    let actionable: String?
    let impact: InsightImpact
    
    enum InsightCategory {
        case usagePattern
        case featureAdoption
        case aiCollaboration
        case growthOpportunity
    }
    
    enum InsightImpact {
        case positive
        case neutral
        case negative
    }
}

struct GrowthMetrics {
    let engagementScore: Double
    let sessionDuration: TimeInterval
    let nodeCreationCount: Int
    let connectionCreationCount: Int
    let aiInteractionCount: Int
    let uniqueFeatureUsageCount: Int
    let conversionLikelihood: Double
}

// MARK: - Growth Optimization Dashboard View

struct GrowthOptimizationDashboardView: View {
    @ObservedObject var growthService: GrowthOptimizationService
    @State private var showingInsights = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Engagement Score
            engagementScoreCard
            
            // Conversion Recommendations
            if !growthService.conversionRecommendations.isEmpty {
                recommendationsSection
            }
            
            // Growth Insights
            if !growthService.growthInsights.isEmpty {
                insightsSection
            }
            
            // Optimization Triggers
            if !growthService.optimizationTriggers.isEmpty {
                triggersSection
            }
        }
        .padding()
        .sheet(isPresented: $showingInsights) {
            GrowthInsightsDetailView(insights: growthService.growthInsights)
        }
    }
    
    private var engagementScoreCard: some View {
        VStack(spacing: 8) {
            Text("用户参与度")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("\(Int(growthService.userEngagementScore))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(engagementColor)
            
            Text("基于您的活跃度和功能使用情况")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("转化建议")
                .font(.headline)
            
            ForEach(growthService.conversionRecommendations.prefix(3)) { recommendation in
                ConversionRecommendationCard(
                    recommendation: recommendation,
                    onExecute: {
                        growthService.executeRecommendation(recommendation)
                    }
                )
            }
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("成长洞察")
                    .font(.headline)
                
                Spacer()
                
                Button("查看全部") {
                    showingInsights = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ForEach(growthService.growthInsights.prefix(2)) { insight in
                GrowthInsightCard(insight: insight)
            }
        }
    }
    
    private var triggersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("优化触发器")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(growthService.optimizationTriggers, id: \.self) { trigger in
                        Text(trigger.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var engagementColor: Color {
        if growthService.userEngagementScore >= 80 {
            return .green
        } else if growthService.userEngagementScore >= 50 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Supporting Views

struct ConversionRecommendationCard: View {
    let recommendation: ConversionRecommendation
    let onExecute: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(recommendation.title)
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Spacer()
                
                priorityBadge
            }
            
            Text(recommendation.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("执行建议") {
                onExecute()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
    
    private var priorityBadge: some View {
        Text(priorityText)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var priorityText: String {
        switch recommendation.priority {
        case .high: return "高"
        case .medium: return "中"
        case .low: return "低"
        }
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }
}

struct GrowthInsightCard: View {
    let insight: GrowthInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(insight.title)
                .font(.callout)
                .fontWeight(.semibold)
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let actionable = insight.actionable {
                Text(actionable)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 2)
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(6)
    }
}

struct GrowthInsightsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let insights: [GrowthInsight]
    
    var body: some View {
        NavigationView {
            List(insights) { insight in
                GrowthInsightCard(insight: insight)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            .navigationTitle("成长洞察")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}