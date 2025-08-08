//
//  CognitiveGearService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP1c: Cognitive Gear Service - 认知档位系统
//

import Foundation
import SwiftUI
import Combine

// MARK: - Cognitive Gear Models

/// 认知档位类型：不同的思维模式
enum CognitiveGear: String, CaseIterable, Codable {
    case capture = "capture"       // 速记模式：快速捕获想法
    case muse = "muse"            // 缪斯模式：创意孵化和漂移
    case inquiry = "inquiry"       // 审问模式：深度分析和质疑
    case synthesis = "synthesis"   // 综合模式：整合和连接
    case reflection = "reflection" // 反思模式：回顾和沉思
    
    var displayName: String {
        switch self {
        case .capture: return "速记模式"
        case .muse: return "缪斯模式"
        case .inquiry: return "审问模式"
        case .synthesis: return "综合模式"
        case .reflection: return "反思模式"
        }
    }
    
    var subtitle: String {
        switch self {
        case .capture: return "快速捕获，即时记录"
        case .muse: return "自由漂移，创意孵化"
        case .inquiry: return "深度质疑，理性分析"
        case .synthesis: return "整合连接，构建结构"
        case .reflection: return "回望思考，洞察总结"
        }
    }
    
    var description: String {
        switch self {
        case .capture:
            return "专注于快速捕获灵感和想法。界面简化，输入流畅，最小化摩擦。适合头脑风暴和初步想法记录。"
        case .muse:
            return "开启创意孵化模式。节点自由漂移，启用认知迷雾，鼓励意外连接。适合创意探索和灵感发现。"
        case .inquiry:
            return "激活深度分析模式。AI主动提问，引导思考，挑战假设。适合问题解决和批判性思维。"
        case .synthesis:
            return "专注于整合和连接。强化关联推荐，显示模式识别，构建知识结构。适合知识整理和体系建构。"
        case .reflection:
            return "进入反思沉思模式。回顾历史思考，发现成长轨迹，生成深度洞察。适合总结回顾和自我认知。"
        }
    }
    
    var icon: String {
        switch self {
        case .capture: return "bolt.fill"
        case .muse: return "sparkles"
        case .inquiry: return "magnifyingglass.circle"
        case .synthesis: return "network"
        case .reflection: return "moon.stars"
        }
    }
    
    var color: Color {
        switch self {
        case .capture: return .orange
        case .muse: return .purple
        case .inquiry: return .blue
        case .synthesis: return .green
        case .reflection: return .indigo
        }
    }
    
    var lightColor: Color {
        return color.opacity(0.15)
    }
    
    /// 该档位的核心特征
    var characteristics: [CognitiveCharacteristic] {
        switch self {
        case .capture:
            return [.fastInput, .minimalFriction, .quickCapture, .streamlinedUI]
        case .muse:
            return [.creativeFlow, .serendipity, .visualEffects, .drift]
        case .inquiry:
            return [.deepAnalysis, .criticalThinking, .aiQuestioning, .methodical]
        case .synthesis:
            return [.patternRecognition, .structureBuilding, .connectionMapping, .integration]
        case .reflection:
            return [.retrospection, .insightGeneration, .narrativeView, .growth]
        }
    }
}

/// 认知特征
enum CognitiveCharacteristic: String, CaseIterable {
    case fastInput = "fast_input"
    case minimalFriction = "minimal_friction"
    case quickCapture = "quick_capture"
    case streamlinedUI = "streamlined_ui"
    case creativeFlow = "creative_flow"
    case serendipity = "serendipity"
    case visualEffects = "visual_effects"
    case drift = "drift"
    case deepAnalysis = "deep_analysis"
    case criticalThinking = "critical_thinking"
    case aiQuestioning = "ai_questioning"
    case methodical = "methodical"
    case patternRecognition = "pattern_recognition"
    case structureBuilding = "structure_building"
    case connectionMapping = "connection_mapping"
    case integration = "integration"
    case retrospection = "retrospection"
    case insightGeneration = "insight_generation"
    case narrativeView = "narrative_view"
    case growth = "growth"
    
    var displayName: String {
        switch self {
        case .fastInput: return "快速输入"
        case .minimalFriction: return "无摩擦体验"
        case .quickCapture: return "即时捕获"
        case .streamlinedUI: return "简化界面"
        case .creativeFlow: return "创意流动"
        case .serendipity: return "偶然发现"
        case .visualEffects: return "视觉效果"
        case .drift: return "自由漂移"
        case .deepAnalysis: return "深度分析"
        case .criticalThinking: return "批判思维"
        case .aiQuestioning: return "AI质疑"
        case .methodical: return "方法论指导"
        case .patternRecognition: return "模式识别"
        case .structureBuilding: return "结构构建"
        case .connectionMapping: return "连接映射"
        case .integration: return "信息整合"
        case .retrospection: return "回顾反思"
        case .insightGeneration: return "洞察生成"
        case .narrativeView: return "叙事视角"
        case .growth: return "成长轨迹"
        }
    }
}

/// 档位切换配置
struct GearTransitionConfig {
    let fromGear: CognitiveGear
    let toGear: CognitiveGear
    let transitionDuration: TimeInterval
    let animationStyle: GearTransitionAnimation
    let requiresConfirmation: Bool
    let contextualHints: [String]
    
    static let `default` = GearTransitionConfig(
        fromGear: .capture,
        toGear: .muse,
        transitionDuration: 0.8,
        animationStyle: .fade,
        requiresConfirmation: false,
        contextualHints: []
    )
}

enum GearTransitionAnimation: String, CaseIterable {
    case fade = "fade"
    case slide = "slide"
    case scale = "scale"
    case rotate = "rotate"
    case ripple = "ripple"
}

/// 档位使用统计
struct GearUsageStats: Codable {
    let gear: CognitiveGear
    let totalTimeSpent: TimeInterval
    let sessionCount: Int
    let averageSessionDuration: TimeInterval
    let nodeCreationCount: Int
    let lastUsed: Date
    let productivityScore: Double // 基于创建的节点质量和数量
    
    var efficiencyRating: EfficiencyRating {
        switch productivityScore {
        case 0.8...: return .excellent
        case 0.6..<0.8: return .good
        case 0.4..<0.6: return .fair
        default: return .needsImprovement
        }
    }
}

enum EfficiencyRating: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case needsImprovement = "needs_improvement"
    
    var displayName: String {
        switch self {
        case .excellent: return "优秀"
        case .good: return "良好"
        case .fair: return "一般"
        case .needsImprovement: return "需改进"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .needsImprovement: return .red
        }
    }
}

// MARK: - Cognitive Gear Service

/// 认知档位服务：管理不同思维模式的切换和配置
@MainActor
class CognitiveGearService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentGear: CognitiveGear = .capture
    @Published var previousGear: CognitiveGear?
    @Published var isTransitioning = false
    @Published var gearHistory: [GearTransition] = []
    @Published var usageStats: [CognitiveGear: GearUsageStats] = [:]
    @Published var autoSwitchEnabled = true
    @Published var contextualSuggestions: [GearSuggestion] = []
    
    // MARK: - Private Properties
    private var sessionStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    private let maxHistoryCount = 50
    
    // MARK: - Dependencies
    private let analyticsService = AnalyticsService()
    private let aiService: HybridAIService
    private let quotaService: QuotaManagementService
    
    init(quotaService: QuotaManagementService) {
        self.quotaService = quotaService
        self.aiService = HybridAIService(quotaService: quotaService)
        loadUserPreferences()
        startCurrentSession()
        setupContextualSuggestions()
    }
    
    // MARK: - Gear Switching
    
    /// 切换到指定的认知档位
    func switchToGear(_ gear: CognitiveGear, animated: Bool = true, reason: String? = nil) {
        guard gear != currentGear else { return }
        
        let previousGear = currentGear
        
        if animated {
            isTransitioning = true
        }
        
        // 记录当前会话结束
        endCurrentSession()
        
        // 执行切换
        performGearTransition(from: previousGear, to: gear, reason: reason)
        
        // 启动新会话
        startCurrentSession()
        
        if animated {
            // 模拟动画延迟
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.isTransitioning = false
            }
        }
    }
    
    /// 智能切换档位（基于上下文）
    func smartSwitch(context: SwitchContext) {
        guard autoSwitchEnabled else { return }
        
        let suggestedGear = determineBestGear(for: context)
        
        if suggestedGear != currentGear {
            let suggestion = GearSuggestion(
                recommendedGear: suggestedGear,
                reason: context.reason,
                confidence: context.confidence,
                context: context
            )
            
            contextualSuggestions.append(suggestion)
            
            // 如果置信度很高，自动切换
            if context.confidence > 0.8 {
                switchToGear(suggestedGear, reason: "智能推荐: \(context.reason)")
            }
        }
    }
    
    /// 回到上一个档位
    func switchBack() {
        guard let previousGear = previousGear else { return }
        switchToGear(previousGear, reason: "返回上一档位")
    }
    
    private func performGearTransition(from: CognitiveGear, to: CognitiveGear, reason: String?) {
        previousGear = from
        currentGear = to
        
        // 记录切换历史
        let transition = GearTransition(
            fromGear: from,
            toGear: to,
            timestamp: Date(),
            reason: reason ?? "手动切换",
            duration: 0 // 会在会话结束时更新
        )
        
        gearHistory.append(transition)
        
        // 限制历史记录数量
        if gearHistory.count > maxHistoryCount {
            gearHistory.removeFirst()
        }
        
        // 应用档位特性
        applyGearCharacteristics(to)
        
        // 发送通知
        NotificationCenter.default.post(
            name: .cognitiveGearChanged,
            object: GearChangeNotification(from: from, to: to, reason: reason)
        )
        
        saveUserPreferences()
    }
    
    private func applyGearCharacteristics(_ gear: CognitiveGear) {
        // 根据档位特性配置系统行为
        for characteristic in gear.characteristics {
            applyCharacteristic(characteristic)
        }
    }
    
    private func applyCharacteristic(_ characteristic: CognitiveCharacteristic) {
        switch characteristic {
        case .fastInput:
            // 启用快速输入模式
            NotificationCenter.default.post(name: .enableFastInputMode, object: true)
            
        case .minimalFriction:
            // 简化界面
            NotificationCenter.default.post(name: .enableMinimalUI, object: true)
            
        case .visualEffects:
            // 启用视觉效果
            NotificationCenter.default.post(name: .enableVisualEffects, object: true)
            
        case .drift:
            // 启用漂移模式
            NotificationCenter.default.post(name: .enableDriftMode, object: true)
            
        case .aiQuestioning:
            // 启用AI主动提问
            NotificationCenter.default.post(name: .enableAIQuestioning, object: true)
            
        case .patternRecognition:
            // 启用模式识别
            NotificationCenter.default.post(name: .enablePatternRecognition, object: true)
            
        default:
            break
        }
    }
    
    // MARK: - Context Analysis
    
    private func determineBestGear(for context: SwitchContext) -> CognitiveGear {
        switch context.trigger {
        case .rapidInput:
            return .capture
        case .creativeBlock:
            return .muse
        case .needAnalysis:
            return .inquiry
        case .manyNodes:
            return .synthesis
        case .endOfSession:
            return .reflection
        case .userRequest:
            return context.requestedGear ?? currentGear
        }
    }
    
    // MARK: - Session Management
    
    private func startCurrentSession() {
        sessionStartTime = Date()
    }
    
    private func endCurrentSession() {
        guard let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        updateUsageStats(gear: currentGear, sessionDuration: sessionDuration)
        
        // 更新最近的转换持续时间
        if var lastTransition = gearHistory.last, lastTransition.toGear == currentGear {
            lastTransition.duration = sessionDuration
            gearHistory[gearHistory.count - 1] = lastTransition
        }
        
        sessionStartTime = nil
    }
    
    private func updateUsageStats(gear: CognitiveGear, sessionDuration: TimeInterval) {
        var stats = usageStats[gear] ?? GearUsageStats(
            gear: gear,
            totalTimeSpent: 0,
            sessionCount: 0,
            averageSessionDuration: 0,
            nodeCreationCount: 0,
            lastUsed: Date(),
            productivityScore: 0.5
        )
        
        stats = GearUsageStats(
            gear: stats.gear,
            totalTimeSpent: stats.totalTimeSpent + sessionDuration,
            sessionCount: stats.sessionCount + 1,
            averageSessionDuration: (stats.totalTimeSpent + sessionDuration) / Double(stats.sessionCount + 1),
            nodeCreationCount: stats.nodeCreationCount, // 需要从外部更新
            lastUsed: Date(),
            productivityScore: calculateProductivityScore(for: stats, sessionDuration: sessionDuration)
        )
        
        usageStats[gear] = stats
    }
    
    private func calculateProductivityScore(for stats: GearUsageStats, sessionDuration: TimeInterval) -> Double {
        // 基于会话时长、创建节点数等计算生产力评分
        let timeEfficiency = min(1.0, sessionDuration / 300.0) // 5分钟为满分
        let baseScore = stats.productivityScore
        
        // 平滑更新评分
        return baseScore * 0.8 + timeEfficiency * 0.2
    }
    
    // MARK: - Contextual Suggestions
    
    private func setupContextualSuggestions() {
        // 监听各种上下文变化
        NotificationCenter.default.publisher(for: .nodeCreated)
            .sink { [weak self] notification in
                self?.analyzeNodeCreationContext(notification)
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .userIdleDetected)
            .sink { [weak self] _ in
                self?.suggestReflectionMode()
            }
            .store(in: &cancellables)
        
        // 定期分析使用模式
        Timer.publish(every: 300, on: .main, in: .common) // 每5分钟
            .autoconnect()
            .sink { [weak self] _ in
                self?.analyzeUsagePatterns()
            }
            .store(in: &cancellables)
    }
    
    private func analyzeNodeCreationContext(_ notification: Notification) {
        // 分析节点创建的上下文，建议合适的档位
        
        // 如果短时间内创建了多个节点，建议切换到综合模式
        let recentTransitions = gearHistory.suffix(5)
        let recentCaptureTime = recentTransitions
            .filter { $0.toGear == .capture }
            .reduce(0) { $0 + $1.duration }
        
        if recentCaptureTime > 600 { // 10分钟的速记模式
            let context = SwitchContext(
                trigger: .manyNodes,
                reason: "检测到大量快速输入，建议整合思路",
                confidence: 0.7
            )
            smartSwitch(context: context)
        }
    }
    
    private func suggestReflectionMode() {
        let context = SwitchContext(
            trigger: .endOfSession,
            reason: "检测到思考停顿，建议回顾反思",
            confidence: 0.6
        )
        smartSwitch(context: context)
    }
    
    private func analyzeUsagePatterns() {
        // 分析使用模式，提供个性化建议
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // 早晨建议速记模式
        if currentHour >= 7 && currentHour <= 9 && currentGear != .capture {
            let suggestion = GearSuggestion(
                recommendedGear: .capture,
                reason: "早晨时光，适合快速捕获新想法",
                confidence: 0.5,
                context: SwitchContext(trigger: .userRequest, reason: "时间建议", confidence: 0.5)
            )
            contextualSuggestions.append(suggestion)
        }
        
        // 深夜建议反思模式
        if currentHour >= 22 || currentHour <= 1 && currentGear != .reflection {
            let suggestion = GearSuggestion(
                recommendedGear: .reflection,
                reason: "夜深时分，适合回顾今日思考",
                confidence: 0.6,
                context: SwitchContext(trigger: .endOfSession, reason: "时间建议", confidence: 0.6)
            )
            contextualSuggestions.append(suggestion)
        }
    }
    
    // MARK: - Analytics & Insights
    
    func getGearInsights() -> [GearInsight] {
        var insights: [GearInsight] = []
        
        // 最常用档位
        if let mostUsedGear = usageStats.max(by: { $0.value.totalTimeSpent < $1.value.totalTimeSpent }) {
            insights.append(GearInsight(
                type: .mostUsed,
                gear: mostUsedGear.key,
                value: mostUsedGear.value.totalTimeSpent,
                description: "你最常使用\(mostUsedGear.key.displayName)，累计 \(Int(mostUsedGear.value.totalTimeSpent / 60)) 分钟"
            ))
        }
        
        // 效率最高档位
        if let mostEfficient = usageStats.max(by: { $0.value.productivityScore < $1.value.productivityScore }) {
            insights.append(GearInsight(
                type: .mostEfficient,
                gear: mostEfficient.key,
                value: mostEfficient.value.productivityScore,
                description: "在\(mostEfficient.key.displayName)中效率最高，评分 \(Int(mostEfficient.value.productivityScore * 100))%"
            ))
        }
        
        // 改进建议
        if let leastUsed = usageStats.min(by: { $0.value.totalTimeSpent < $1.value.totalTimeSpent }) {
            insights.append(GearInsight(
                type: .suggestion,
                gear: leastUsed.key,
                value: leastUsed.value.totalTimeSpent,
                description: "尝试多使用\(leastUsed.key.displayName)，或许会有意外收获"
            ))
        }
        
        return insights
    }
    
    func getOptimalGearSequence() -> [CognitiveGear] {
        // 基于历史数据分析最优的档位切换序列
        return [.capture, .muse, .inquiry, .synthesis, .reflection]
    }
    
    // MARK: - Persistence
    
    private func loadUserPreferences() {
        if let data = UserDefaults.standard.data(forKey: "CognitiveGearPreferences"),
           let preferences = try? JSONDecoder().decode(GearPreferences.self, from: data) {
            
            currentGear = preferences.defaultGear
            autoSwitchEnabled = preferences.autoSwitchEnabled
            
            // 加载使用统计
            if let statsData = UserDefaults.standard.data(forKey: "GearUsageStats"),
               let stats = try? JSONDecoder().decode([CognitiveGear: GearUsageStats].self, from: statsData) {
                usageStats = stats
            }
        }
    }
    
    private func saveUserPreferences() {
        let preferences = GearPreferences(
            defaultGear: currentGear,
            autoSwitchEnabled: autoSwitchEnabled
        )
        
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: "CognitiveGearPreferences")
        }
        
        // 保存使用统计
        if let statsData = try? JSONEncoder().encode(usageStats) {
            UserDefaults.standard.set(statsData, forKey: "GearUsageStats")
        }
    }
    
    // MARK: - Public Interface
    
    func dismissSuggestion(_ suggestion: GearSuggestion) {
        contextualSuggestions.removeAll { $0.id == suggestion.id }
    }
    
    func acceptSuggestion(_ suggestion: GearSuggestion) {
        switchToGear(suggestion.recommendedGear, reason: "接受建议: \(suggestion.reason)")
        dismissSuggestion(suggestion)
    }
    
    func getRecentHistory(limit: Int = 10) -> [GearTransition] {
        return Array(gearHistory.suffix(limit).reversed())
    }
    
    func resetUsageStats() {
        usageStats.removeAll()
        gearHistory.removeAll()
        contextualSuggestions.removeAll()
        saveUserPreferences()
    }
}

// MARK: - Supporting Models

struct GearTransition: Identifiable, Codable {
    let id = UUID()
    let fromGear: CognitiveGear
    let toGear: CognitiveGear
    let timestamp: Date
    let reason: String
    var duration: TimeInterval
}

struct SwitchContext {
    let trigger: SwitchTrigger
    let reason: String
    let confidence: Double
    let requestedGear: CognitiveGear?
    
    init(trigger: SwitchTrigger, reason: String, confidence: Double, requestedGear: CognitiveGear? = nil) {
        self.trigger = trigger
        self.reason = reason
        self.confidence = confidence
        self.requestedGear = requestedGear
    }
}

enum SwitchTrigger {
    case rapidInput        // 快速输入
    case creativeBlock     // 创意阻塞
    case needAnalysis      // 需要分析
    case manyNodes         // 节点过多
    case endOfSession      // 会话结束
    case userRequest       // 用户请求
}

struct GearSuggestion: Identifiable {
    let id = UUID()
    let recommendedGear: CognitiveGear
    let reason: String
    let confidence: Double
    let context: SwitchContext
    let timestamp = Date()
}

struct GearChangeNotification {
    let from: CognitiveGear
    let to: CognitiveGear
    let reason: String?
}

struct GearPreferences: Codable {
    let defaultGear: CognitiveGear
    let autoSwitchEnabled: Bool
}

struct GearInsight: Identifiable {
    let id = UUID()
    let type: InsightType
    let gear: CognitiveGear
    let value: Double
    let description: String
    
    enum InsightType {
        case mostUsed
        case mostEfficient
        case suggestion
        case pattern
    }
}

// MARK: - Analytics Service (Placeholder)

private class AnalyticsService {
    func trackGearSwitch(from: CognitiveGear, to: CognitiveGear, reason: String?) {
        // 实现分析跟踪
    }
    
    func trackGearUsage(gear: CognitiveGear, duration: TimeInterval) {
        // 实现使用时长跟踪
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let cognitiveGearChanged = Notification.Name("cognitiveGearChanged")
    static let enableFastInputMode = Notification.Name("enableFastInputMode")
    static let enableMinimalUI = Notification.Name("enableMinimalUI")
    static let enableVisualEffects = Notification.Name("enableVisualEffects")
    static let enableDriftMode = Notification.Name("enableDriftMode")
    static let enableAIQuestioning = Notification.Name("enableAIQuestioning")
    static let enablePatternRecognition = Notification.Name("enablePatternRecognition")
    static let nodeCreated = Notification.Name("nodeCreated")
    static let userIdleDetected = Notification.Name("userIdleDetected")
}