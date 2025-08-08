//
//  DriftModeService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP1c: Drift Mode Service - 缪斯模式下的节点布朗运动和共鸣瞬现
//

import Foundation
import SwiftUI
import SpriteKit
import Combine

// MARK: - Drift Mode Configuration

/// 漂移模式配置：控制布朗运动和共鸣瞬现的参数
struct DriftModeConfig {
    // 布朗运动参数
    static let baseDriftForce: Float = 0.3
    static let maxDriftDistance: Float = 50.0
    static let driftCycleDuration: TimeInterval = 8.0
    static let thermalNoiseScale: Float = 0.1
    
    // 共鸣瞬现参数
    static let resonanceThreshold: Float = 0.75 // 语义相似度阈值
    static let resonanceDetectionInterval: TimeInterval = 5.0
    static let resonanceFlashDuration: TimeInterval = 1.5
    static let resonanceLineWidth: CGFloat = 2.0
    
    // 缪斯模式参数
    static let museModeDriftMultiplier: Float = 1.5
    static let incubationTimeRange: ClosedRange<TimeInterval> = 30.0...180.0
    static let serendipityFactor: Float = 0.2 // 偶然发现因子
}

// MARK: - Drift State Model

/// 节点漂移状态
struct NodeDriftState {
    let nodeId: UUID
    var velocity: CGVector
    var lastResonanceTime: Date
    var driftIntensity: Float
    var semanticField: [String] // 语义场词汇
    var isInResonance: Bool
    
    init(nodeId: UUID) {
        self.nodeId = nodeId
        self.velocity = CGVector(dx: 0, dy: 0)
        self.lastResonanceTime = Date.distantPast
        self.driftIntensity = DriftModeConfig.baseDriftForce
        self.semanticField = []
        self.isInResonance = false
    }
}

// MARK: - Resonance Event Model

/// 共鸣瞬现事件
struct ResonanceEvent: Identifiable {
    let id = UUID()
    let nodeA: UUID
    let nodeB: UUID
    let similarity: Float
    let timestamp: Date
    let connectionStrength: Float
    let semanticBridge: String // 语义桥梁描述
    
    /// 共鸣类型：基于相似度和上下文
    var resonanceType: ResonanceType {
        switch similarity {
        case 0.9...:
            return .harmonic // 和谐共鸣
        case 0.8..<0.9:
            return .complementary // 互补共鸣
        case 0.7..<0.8:
            return .creative // 创意共鸣
        default:
            return .unexpected // 意外共鸣
        }
    }
}

enum ResonanceType: String, CaseIterable {
    case harmonic = "harmonic"
    case complementary = "complementary"
    case creative = "creative"
    case unexpected = "unexpected"
    
    var displayName: String {
        switch self {
        case .harmonic: return "和谐共鸣"
        case .complementary: return "互补共鸣"
        case .creative: return "创意共鸣"
        case .unexpected: return "意外共鸣"
        }
    }
    
    var color: Color {
        switch self {
        case .harmonic: return .blue
        case .complementary: return .green
        case .creative: return .purple
        case .unexpected: return .orange
        }
    }
}

// MARK: - Drift Mode Service

/// 漂移模式服务：管理缪斯模式下的节点布朗运动和共鸣瞬现
@MainActor
class DriftModeService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isDriftModeActive = false
    @Published var isMuseModeActive = false
    @Published var currentResonances: [ResonanceEvent] = []
    @Published var driftIntensity: Float = DriftModeConfig.baseDriftForce
    @Published var serendipityEvents: [String] = []
    
    // MARK: - Private Properties
    private var driftStates: [UUID: NodeDriftState] = [:]
    private var driftTimer: Timer?
    private var resonanceTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var animationSystem: AdvancedAnimationSystem?
    private weak var canvasScene: InfiniteCanvasScene?
    
    // MARK: - Dependencies
    private let vectorDBService = VectorDBService()
    private let emotionalService = EmotionalComputingService()
    private let coreMLService = CoreMLEmbeddingService()
    
    init() {
        setupResonanceDetection()
    }
    
    // MARK: - Drift Mode Control
    
    /// 激活漂移模式
    func activateDriftMode(in scene: InfiniteCanvasScene, animationSystem: AdvancedAnimationSystem) {
        guard !isDriftModeActive else { return }
        
        self.canvasScene = scene
        self.animationSystem = animationSystem
        isDriftModeActive = true
        
        // 初始化所有节点的漂移状态
        initializeDriftStates(in: scene)
        
        // 启动漂移计算定时器
        startDriftTimer()
        
        // 启动共鸣检测
        startResonanceDetection()
        
        NotificationCenter.default.post(name: .driftModeActivated, object: nil)
    }
    
    /// 停用漂移模式
    func deactivateDriftMode() {
        guard isDriftModeActive else { return }
        
        isDriftModeActive = false
        isMuseModeActive = false
        
        // 停止所有定时器
        stopDriftTimer()
        stopResonanceDetection()
        
        // 清除漂移状态
        driftStates.removeAll()
        currentResonances.removeAll()
        
        // 停止所有节点的漂移动画
        canvasScene?.enableDriftMode(false)
        
        NotificationCenter.default.post(name: .driftModeDeactivated, object: nil)
    }
    
    /// 激活缪斯模式（孵化模式的高级形态）
    func activateMuseMode() {
        if !isDriftModeActive {
            // 如果漂移模式未激活，先激活它
            guard let scene = canvasScene, let animSystem = animationSystem else { return }
            activateDriftMode(in: scene, animationSystem: animSystem)
        }
        
        isMuseModeActive = true
        
        // 增强漂移强度
        driftIntensity *= DriftModeConfig.museModeDriftMultiplier
        
        // 更新所有节点的漂移强度
        for (nodeId, var state) in driftStates {
            state.driftIntensity *= DriftModeConfig.museModeDriftMultiplier
            driftStates[nodeId] = state
        }
        
        // 激活认知迷雾效果
        if let scene = canvasScene {
            let ghostWords = generateSerendipityWords()
            animationSystem?.activateCognitiveMist(in: scene, ghostWords: ghostWords)
        }
        
        NotificationCenter.default.post(name: .museModeActivated, object: nil)
    }
    
    /// 停用缪斯模式
    func deactivateMuseMode() {
        guard isMuseModeActive else { return }
        
        isMuseModeActive = false
        
        // 恢复正常漂移强度
        driftIntensity /= DriftModeConfig.museModeDriftMultiplier
        
        for (nodeId, var state) in driftStates {
            state.driftIntensity /= DriftModeConfig.museModeDriftMultiplier
            driftStates[nodeId] = state
        }
        
        // 停用认知迷雾
        if let scene = canvasScene {
            animationSystem?.deactivateCognitiveMist(in: scene)
        }
        
        NotificationCenter.default.post(name: .museModeDeactivated, object: nil)
    }
    
    // MARK: - Brownian Motion System
    
    private func initializeDriftStates(in scene: InfiniteCanvasScene) {
        // 获取场景中的所有节点
        for child in scene.children {
            if let nodeSprite = child as? EnhancedNodeSprite {
                let nodeId = nodeSprite.thoughtNode.id
                var driftState = NodeDriftState(nodeId: nodeId)
                
                // 基于节点的情感状态调整漂移参数
                let emotions = emotionalService.getEmotions(for: nodeSprite.thoughtNode)
                if let firstEmotion = emotions.first {
                    driftState.driftIntensity = adjustDriftIntensityForEmotion(firstEmotion)
                }
                
                // 提取节点的语义场
                driftState.semanticField = extractSemanticField(from: nodeSprite.thoughtNode)
                
                driftStates[nodeId] = driftState
            }
        }
    }
    
    private func startDriftTimer() {
        driftTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateBrownianMotion()
            }
        }
    }
    
    private func stopDriftTimer() {
        driftTimer?.invalidate()
        driftTimer = nil
    }
    
    private func updateBrownianMotion() {
        guard let scene = canvasScene else { return }
        
        for (nodeId, var state) in driftStates {
            // 计算布朗运动的随机力
            let thermalNoise = CGVector(
                dx: CGFloat.random(in: -1...1) * CGFloat(DriftModeConfig.thermalNoiseScale),
                dy: CGFloat.random(in: -1...1) * CGFloat(DriftModeConfig.thermalNoiseScale)
            )
            
            // 应用阻尼和随机力
            state.velocity = CGVector(
                dx: state.velocity.dx * 0.95 + thermalNoise.dx * CGFloat(state.driftIntensity),
                dy: state.velocity.dy * 0.95 + thermalNoise.dy * CGFloat(state.driftIntensity)
            )
            
            // 限制最大速度
            let maxVelocity = CGFloat(DriftModeConfig.maxDriftDistance) / CGFloat(DriftModeConfig.driftCycleDuration)
            let currentSpeed = hypot(state.velocity.dx, state.velocity.dy)
            if currentSpeed > maxVelocity {
                state.velocity = CGVector(
                    dx: state.velocity.dx * maxVelocity / currentSpeed,
                    dy: state.velocity.dy * maxVelocity / currentSpeed
                )
            }
            
            // 应用运动到节点
            if let nodeSprite = scene.childNode(withName: nodeId.uuidString) {
                let newPosition = CGPoint(
                    x: nodeSprite.position.x + state.velocity.dx,
                    y: nodeSprite.position.y + state.velocity.dy
                )
                nodeSprite.position = newPosition
            }
            
            driftStates[nodeId] = state
        }
    }
    
    private func adjustDriftIntensityForEmotion(_ emotion: EmotionalTag) -> Float {
        switch emotion {
        case .excited:
            return DriftModeConfig.baseDriftForce * 1.3 // 兴奋时漂移更活跃
        case .calm:
            return DriftModeConfig.baseDriftForce * 0.7 // 平静时漂移较缓慢
        case .frustrated:
            return DriftModeConfig.baseDriftForce * 1.1 // 焦虑时轻微增强
        case .confused, .uncertain:
            return DriftModeConfig.baseDriftForce * 1.2 // 困惑时增加探索性
        case .inspired, .confident:
            return DriftModeConfig.baseDriftForce * 1.15 // 灵感时稍微增强
        case .curious:
            return DriftModeConfig.baseDriftForce
        }
    }
    
    // MARK: - Resonance Detection System
    
    private func setupResonanceDetection() {
        // 监听节点位置变化，用于共鸣检测
        NotificationCenter.default.publisher(for: .nodePositionChanged)
            .sink { [weak self] notification in
                self?.checkForResonance()
            }
            .store(in: &cancellables)
    }
    
    private func startResonanceDetection() {
        resonanceTimer = Timer.scheduledTimer(
            withTimeInterval: DriftModeConfig.resonanceDetectionInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.performResonanceDetection()
            }
        }
    }
    
    private func stopResonanceDetection() {
        resonanceTimer?.invalidate()
        resonanceTimer = nil
    }
    
    private func performResonanceDetection() {
        guard let scene = canvasScene else { return }
        
        let nodeSprites = scene.children.compactMap { $0 as? EnhancedNodeSprite }
        
        // 遍历所有节点对，检测共鸣
        for i in 0..<nodeSprites.count {
            for j in (i+1)..<nodeSprites.count {
                let nodeA = nodeSprites[i]
                let nodeB = nodeSprites[j]
                
                checkResonanceBetween(nodeA: nodeA, nodeB: nodeB)
            }
        }
    }
    
    private func checkResonanceBetween(nodeA: EnhancedNodeSprite, nodeB: EnhancedNodeSprite) {
        let distance = hypot(
            nodeA.position.x - nodeB.position.x,
            nodeA.position.y - nodeB.position.y
        )
        
        // 只检测距离较近的节点
        guard distance < 200 else { return }
        
        // 计算语义相似度
        Task {
            let similarity = await calculateSemanticSimilarity(
                nodeA: nodeA.thoughtNode,
                nodeB: nodeB.thoughtNode
            )
            
            await MainActor.run {
                if similarity >= DriftModeConfig.resonanceThreshold {
                    self.triggerResonanceFlash(
                        between: nodeA.thoughtNode.id,
                        and: nodeB.thoughtNode.id,
                        similarity: similarity
                    )
                }
            }
        }
    }
    
    private func calculateSemanticSimilarity(nodeA: ThoughtNode, nodeB: ThoughtNode) async -> Float {
        // 使用向量数据库计算语义相似度
        let embeddingA = await coreMLService.generateEmbedding(for: nodeA.content)
        let embeddingB = await coreMLService.generateEmbedding(for: nodeB.content)
        
        if let embeddingA = embeddingA, let embeddingB = embeddingB {
            return cosineSimilarity(embeddingA, embeddingB)
        } else {
            // 回退到简单的文本相似度
            return calculateTextSimilarity(nodeA.content, nodeB.content)
        }
    }
    
    private func cosineSimilarity(_ vectorA: [Float], _ vectorB: [Float]) -> Float {
        guard vectorA.count == vectorB.count else { return 0.0 }
        
        let dotProduct = zip(vectorA, vectorB).map(*).reduce(0, +)
        let magnitudeA = sqrt(vectorA.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(vectorB.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    private func calculateTextSimilarity(_ textA: String, _ textB: String) -> Float {
        // 简单的词汇重叠相似度计算
        let wordsA = Set(textA.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let wordsB = Set(textB.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = wordsA.intersection(wordsB)
        let union = wordsA.union(wordsB)
        
        guard !union.isEmpty else { return 0.0 }
        
        return Float(intersection.count) / Float(union.count)
    }
    
    // MARK: - Resonance Flash System
    
    private func triggerResonanceFlash(between nodeAId: UUID, and nodeBId: UUID, similarity: Float) {
        guard let scene = canvasScene, let animSystem = animationSystem else { return }
        
        // 创建共鸣事件
        let resonanceEvent = ResonanceEvent(
            nodeA: nodeAId,
            nodeB: nodeBId,
            similarity: similarity,
            timestamp: Date(),
            connectionStrength: similarity,
            semanticBridge: generateSemanticBridge(nodeAId: nodeAId, nodeBId: nodeBId)
        )
        
        // 添加到当前共鸣列表
        currentResonances.append(resonanceEvent)
        
        // 限制共鸣事件数量
        if currentResonances.count > 10 {
            currentResonances.removeFirst()
        }
        
        // 更新节点的共鸣状态
        if var stateA = driftStates[nodeAId] {
            stateA.isInResonance = true
            stateA.lastResonanceTime = Date()
            driftStates[nodeAId] = stateA
        }
        
        if var stateB = driftStates[nodeBId] {
            stateB.isInResonance = true
            stateB.lastResonanceTime = Date()
            driftStates[nodeBId] = stateB
        }
        
        // 执行共鸣闪现动画
        animSystem.createResonanceFlash(from: nodeAId, to: nodeBId, in: scene) { [weak self] in
            // 共鸣动画完成后的回调
            self?.onResonanceFlashCompleted(event: resonanceEvent)
        }
        
        // 生成偶然发现事件
        if similarity > 0.85 && isMuseModeActive {
            generateSerendipityEvent(from: resonanceEvent)
        }
        
        NotificationCenter.default.post(
            name: .resonanceDetected,
            object: resonanceEvent
        )
    }
    
    private func onResonanceFlashCompleted(event: ResonanceEvent) {
        // 重置节点的共鸣状态
        if var stateA = driftStates[event.nodeA] {
            stateA.isInResonance = false
            driftStates[event.nodeA] = stateA
        }
        
        if var stateB = driftStates[event.nodeB] {
            stateB.isInResonance = false
            driftStates[event.nodeB] = stateB
        }
        
        // 记录共鸣历史用于学习
        recordResonanceHistory(event)
    }
    
    // MARK: - Serendipity System
    
    private func generateSerendipityEvent(from resonanceEvent: ResonanceEvent) {
        let serendipityMessages = [
            "意外的连接被发现：\(resonanceEvent.semanticBridge)",
            "新的洞察正在浮现：两个看似无关的想法产生了共鸣",
            "创意火花：\(resonanceEvent.resonanceType.displayName)创造了新的可能性",
            "思维的偶然相遇：或许这个连接值得深入探索"
        ]
        
        let serendipityEvent = serendipityMessages.randomElement() ?? "发现了意外的连接"
        serendipityEvents.append(serendipityEvent)
        
        // 限制事件数量
        if serendipityEvents.count > 5 {
            serendipityEvents.removeFirst()
        }
        
        NotificationCenter.default.post(
            name: .serendipityDetected,
            object: serendipityEvent
        )
    }
    
    private func generateSerendipityWords() -> [String] {
        return [
            "潜在的连接", "隐藏的模式", "意外的洞察", "创意的种子",
            "思想的回声", "概念的漂移", "灵感的碎片", "认知的涌现"
        ]
    }
    
    // MARK: - Semantic Field Analysis
    
    private func extractSemanticField(from node: ThoughtNode) -> [String] {
        // 从节点内容中提取关键词和概念
        let words = node.content.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 2 }
            .map { $0.lowercased() }
        
        // 简单的关键词提取（实际应用中可以使用更复杂的NLP技术）
        let uniqueWords = Array(Set(words))
        return Array(uniqueWords.prefix(10))
    }
    
    private func generateSemanticBridge(nodeAId: UUID, nodeBId: UUID) -> String {
        guard let stateA = driftStates[nodeAId],
              let stateB = driftStates[nodeBId] else {
            return "概念的交集"
        }
        
        let commonConcepts = Set(stateA.semanticField).intersection(Set(stateB.semanticField))
        
        if let commonConcept = commonConcepts.first {
            return "通过'\(commonConcept)'建立连接"
        } else {
            return "跨领域的概念桥梁"
        }
    }
    
    // MARK: - Resonance History & Learning
    
    private func recordResonanceHistory(_ event: ResonanceEvent) {
        // 记录共鸣历史用于改进算法
        // 这里可以实现机器学习逻辑来优化共鸣检测
        
        UserDefaults.standard.set(
            event.similarity,
            forKey: "last_resonance_similarity_\(event.nodeA)_\(event.nodeB)"
        )
    }
    
    private func checkForResonance() {
        // 响应节点位置变化的共鸣检测
        // 这个方法会在节点移动时被调用
        guard isDriftModeActive else { return }
        
        // 延迟执行以避免过于频繁的检测
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.performResonanceDetection()
        }
    }
    
    // MARK: - Public Interface
    
    /// 获取节点的当前漂移状态
    func getDriftState(for nodeId: UUID) -> NodeDriftState? {
        return driftStates[nodeId]
    }
    
    /// 手动触发共鸣检测
    func forceResonanceDetection() {
        performResonanceDetection()
    }
    
    /// 获取最近的共鸣事件
    func getRecentResonances(limit: Int = 5) -> [ResonanceEvent] {
        return Array(currentResonances.suffix(limit))
    }
    
    /// 清除所有共鸣历史
    func clearResonanceHistory() {
        currentResonances.removeAll()
        serendipityEvents.removeAll()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let driftModeActivated = Notification.Name("driftModeActivated")
    static let driftModeDeactivated = Notification.Name("driftModeDeactivated")
    static let museModeActivated = Notification.Name("museModeActivated")
    static let museModeDeactivated = Notification.Name("museModeDeactivated")
    static let resonanceDetected = Notification.Name("resonanceDetected")
    static let serendipityDetected = Notification.Name("serendipityDetected")
    static let nodePositionChanged = Notification.Name("nodePositionChanged")
}