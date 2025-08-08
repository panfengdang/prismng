//
//  AdvancedAnimationSystem.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP1c: Advanced Animation System for Emotional Auras & Cognitive Mist
//

import Foundation
import SpriteKit
import SwiftUI
import CoreImage

// MARK: - Advanced Animation System

/// 高级动画系统：实现情感光晕、认知迷雾等视觉效果
/// 遵循设计哲学：光影叙事 (Light & Shadow Narrative)
@MainActor
class AdvancedAnimationSystem: ObservableObject {
    
    // MARK: - Animation Dictionary
    /// 实用主义动画金字塔：预定义的核心动画动词
    private var animationVocabulary: [String: SKAction] = [:]
    
    // MARK: - Effect Nodes Registry
    private var emotionalAuraNodes: [UUID: SKEffectNode] = [:]
    private var cognitiveFields: [UUID: SKFieldNode] = [:]
    
    // MARK: - Configuration
    struct AnimationConfig {
        static let emotionalAuraRadius: CGFloat = 80.0
        static let cognitiveFieldStrength: Float = 0.3
        static let breathingCycleDuration: TimeInterval = 4.0
        static let resonanceFlashDuration: TimeInterval = 1.2
        static let dissolveDuration: TimeInterval = 2.0
    }
    
    init() {
        setupAnimationVocabulary()
    }
    
    // MARK: - Animation Vocabulary Setup
    
    /// 定义核心动画动词，构建表达力强的动画词典
    private func setupAnimationVocabulary() {
        // emerge (浮现) - 节点创建时的渐入效果
        let emergeAction = SKAction.group([
            SKAction.fadeIn(withDuration: 0.8),
            SKAction.scale(to: 1.0, duration: 0.8),
            SKAction.sequence([
                SKAction.wait(forDuration: 0.3),
                createSettleAction()
            ])
        ])
        animationVocabulary["emerge"] = emergeAction
        
        // settle (落定) - 节点到达目标位置的缓动
        animationVocabulary["settle"] = createSettleAction()
        
        // pulse (脉动) - 情感节点的呼吸感
        let pulseAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.scale(to: 1.05, duration: AnimationConfig.breathingCycleDuration / 2),
                SKAction.scale(to: 0.95, duration: AnimationConfig.breathingCycleDuration / 2)
            ])
        )
        animationVocabulary["pulse"] = pulseAction
        
        // dissolve (溶解) - 遗忘效果的组合动画
        let dissolveAction = SKAction.group([
            SKAction.fadeOut(withDuration: AnimationConfig.dissolveDuration),
            SKAction.scale(to: 0.1, duration: AnimationConfig.dissolveDuration),
            SKAction.rotate(byAngle: .pi * 2, duration: AnimationConfig.dissolveDuration)
        ])
        animationVocabulary["dissolve"] = dissolveAction
        
        // connect (连接) - 共鸣瞬现的金色连线动画
        animationVocabulary["connect"] = createResonanceFlashAction()
    }
    
    private func createSettleAction() -> SKAction {
        return SKAction.customAction(withDuration: 0.5) { node, elapsedTime in
            let progress = elapsedTime / 0.5
            let easeOut = 1 - pow(1 - progress, 3) // Cubic ease-out
            node.setScale(0.95 + 0.05 * easeOut)
        }
    }
    
    private func createResonanceFlashAction() -> SKAction {
        return SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.group([
                SKAction.fadeOut(withDuration: AnimationConfig.resonanceFlashDuration),
                SKAction.customAction(withDuration: AnimationConfig.resonanceFlashDuration) { node, _ in
                    // 金色光线的动态效果
                    if let shapeNode = node as? SKShapeNode {
                        shapeNode.strokeColor = UIColor.systemYellow.withAlphaComponent(0.8)
                        shapeNode.glowWidth = 3.0
                    }
                }
            ])
        ])
    }
    
    // MARK: - Emotional Aura System
    
    /// 为节点添加情感光晕效果
    /// 基于用户标记的情绪呈现冷暖色调光晕
    func addEmotionalAura(to nodeId: UUID, emotion: EmotionalTag, in scene: SKScene) {
        guard let targetNode = scene.childNode(withName: nodeId.uuidString) else { return }
        
        // 移除现有光晕
        removeEmotionalAura(from: nodeId)
        
        // 创建 SKEffectNode 用于情感光晕
        let auraEffectNode = SKEffectNode()
        auraEffectNode.name = "emotional_aura_\(nodeId.uuidString)"
        
        // 创建光晕基础形状
        let auraShape = SKShapeNode(circleOfRadius: AnimationConfig.emotionalAuraRadius)
        auraShape.fillColor = .clear
        auraShape.strokeColor = getEmotionalColor(for: emotion)
        auraShape.glowWidth = 20.0
        auraShape.alpha = 0.6
        
        auraEffectNode.addChild(auraShape)
        
        // 应用 Core Image 滤镜实现柔和效果
        let gaussianBlur = CIFilter(name: "CIGaussianBlur")
        gaussianBlur?.setValue(15.0, forKey: kCIInputRadiusKey)
        auraEffectNode.filter = gaussianBlur
        auraEffectNode.shouldEnableEffects = true
        
        // 添加呼吸动画
        let breathingAnimation = createBreathingAnimation(for: emotion)
        auraEffectNode.run(breathingAnimation, withKey: "breathing")
        
        // 添加到场景并注册
        targetNode.addChild(auraEffectNode)
        emotionalAuraNodes[nodeId] = auraEffectNode
    }
    
    /// 移除节点的情感光晕
    func removeEmotionalAura(from nodeId: UUID) {
        if let auraNode = emotionalAuraNodes[nodeId] {
            auraNode.removeFromParent()
            emotionalAuraNodes.removeValue(forKey: nodeId)
        }
    }
    
    /// 更新情感光晕的强度
    func updateEmotionalIntensity(for nodeId: UUID, intensity: Float) {
        guard let auraNode = emotionalAuraNodes[nodeId] else { return }
        auraNode.alpha = CGFloat(intensity * 0.8) // 最大透明度为0.8
    }
    
    private func getEmotionalColor(for emotion: EmotionalTag) -> UIColor {
        switch emotion {
        case .excited:
            return UIColor.systemYellow
        case .calm:
            return UIColor.systemBlue
        case .frustrated:
            return UIColor.systemRed
        case .inspired:
            return UIColor.systemPink
        case .curious:
            return UIColor.systemOrange
        case .confused, .uncertain:
            return UIColor.systemGray
        case .confident:
            return UIColor.systemGreen
        }
    }
    
    private func createBreathingAnimation(for emotion: EmotionalTag) -> SKAction {
        let baseDuration = AnimationConfig.breathingCycleDuration
        
        // 不同情绪的呼吸节奏不同
        let duration: Double
        switch emotion {
        case .excited:
            duration = baseDuration * 0.7 // 快速呼吸
        case .calm:
            duration = baseDuration * 1.5 // 缓慢呼吸
        case .frustrated:
            duration = baseDuration * 0.8 // 稍快呼吸
        default:
            duration = baseDuration // 正常呼吸
        }
        
        return SKAction.repeatForever(
            SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 1.1, duration: duration / 2),
                    SKAction.fadeAlpha(to: 0.8, duration: duration / 2)
                ]),
                SKAction.group([
                    SKAction.scale(to: 0.9, duration: duration / 2),
                    SKAction.fadeAlpha(to: 0.4, duration: duration / 2)
                ])
            ])
        )
    }
    
    // MARK: - Cognitive Mist System
    
    /// 创建认知迷雾效果，用于"AI透镜"分析模式
    /// 在画布上生成幽灵词语和柔和的视觉迷雾
    func activateCognitiveMist(in scene: SKScene, ghostWords: [String]) {
        // 移除现有迷雾
        deactivateCognitiveMist(in: scene)
        
        // 创建主迷雾效果节点
        let mistEffectNode = SKEffectNode()
        mistEffectNode.name = "cognitive_mist"
        mistEffectNode.zPosition = -10 // 在背景层
        
        // 创建迷雾基础形状 - 覆盖整个画布
        let mistShape = SKShapeNode(rect: CGRect(x: -2000, y: -2000, width: 4000, height: 4000))
        mistShape.fillColor = UIColor.systemGray6.withAlphaComponent(0.3)
        mistShape.strokeColor = .clear
        
        mistEffectNode.addChild(mistShape)
        
        // 应用高斯模糊滤镜
        let gaussianBlur = CIFilter(name: "CIGaussianBlur")
        gaussianBlur?.setValue(25.0, forKey: kCIInputRadiusKey)
        mistEffectNode.filter = gaussianBlur
        mistEffectNode.shouldEnableEffects = true
        
        // 添加幽灵词语
        addGhostWords(ghostWords, to: mistEffectNode, in: scene)
        
        // 添加飘动效果
        let floatAnimation = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.moveBy(x: 20, y: 10, duration: 8.0),
                SKAction.moveBy(x: -20, y: -10, duration: 8.0)
            ])
        )
        mistEffectNode.run(floatAnimation, withKey: "floating")
        
        scene.addChild(mistEffectNode)
    }
    
    /// 停用认知迷雾效果
    func deactivateCognitiveMist(in scene: SKScene) {
        scene.childNode(withName: "cognitive_mist")?.removeFromParent()
    }
    
    private func addGhostWords(_ words: [String], to mistNode: SKEffectNode, in scene: SKScene) {
        for (index, word) in words.enumerated() {
            let ghostLabel = SKLabelNode(text: word)
            ghostLabel.fontName = "HelveticaNeue-Light"
            ghostLabel.fontSize = 18
            ghostLabel.fontColor = UIColor.systemGray2.withAlphaComponent(0.5)
            ghostLabel.alpha = 0.0
            
            // 随机位置
            let randomX = Float.random(in: -800...800)
            let randomY = Float.random(in: -600...600)
            ghostLabel.position = CGPoint(x: CGFloat(randomX), y: CGFloat(randomY))
            
            mistNode.addChild(ghostLabel)
            
            // 延迟出现动画
            let delay = TimeInterval(index) * 0.3
            let fadeInAction = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeIn(withDuration: 2.0)
            ])
            
            ghostLabel.run(fadeInAction)
            
            // 缓慢飘动
            let drift = SKAction.repeatForever(
                SKAction.sequence([
                    SKAction.moveBy(x: CGFloat.random(in: -50...50), 
                                   y: CGFloat.random(in: -30...30), 
                                   duration: TimeInterval.random(in: 15...25)),
                    SKAction.moveBy(x: CGFloat.random(in: -50...50), 
                                   y: CGFloat.random(in: -30...30), 
                                   duration: TimeInterval.random(in: 15...25))
                ])
            )
            ghostLabel.run(drift, withKey: "ghost_drift")
        }
    }
    
    // MARK: - Resonance Flash System
    
    /// 创建共鸣瞬现效果 - 两个节点间的金色连接线闪现
    /// 用于孵化阶段的顿悟体验
    func createResonanceFlash(from nodeA: UUID, to nodeB: UUID, in scene: SKScene, completion: @escaping () -> Void) {
        guard let nodeASprite = scene.childNode(withName: nodeA.uuidString),
              let nodeBSprite = scene.childNode(withName: nodeB.uuidString) else {
            completion()
            return
        }
        
        // 创建金色连接线
        let connectionPath = UIBezierPath()
        connectionPath.move(to: nodeASprite.position)
        connectionPath.addLine(to: nodeBSprite.position)
        
        let connectionLine = SKShapeNode(path: connectionPath.cgPath)
        connectionLine.strokeColor = UIColor.systemYellow
        connectionLine.lineWidth = 3.0
        connectionLine.glowWidth = 6.0
        connectionLine.alpha = 0.0
        connectionLine.name = "resonance_flash"
        connectionLine.zPosition = 100 // 在最上层
        
        scene.addChild(connectionLine)
        
        // 执行共鸣闪现动画
        let flashAction = animationVocabulary["connect"] ?? SKAction()
        connectionLine.run(flashAction) {
            connectionLine.removeFromParent()
            completion()
        }
        
        // 同时为两个节点添加短暂的光晕效果
        addTemporaryResonanceGlow(to: nodeASprite)
        addTemporaryResonanceGlow(to: nodeBSprite)
    }
    
    private func addTemporaryResonanceGlow(to node: SKNode) {
        let glowNode = SKShapeNode(circleOfRadius: 60)
        glowNode.fillColor = .clear
        glowNode.strokeColor = UIColor.systemYellow.withAlphaComponent(0.6)
        glowNode.glowWidth = 15.0
        glowNode.alpha = 0.0
        
        node.addChild(glowNode)
        
        let glowAction = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.wait(forDuration: 0.8),
            SKAction.fadeOut(withDuration: 0.4)
        ])
        
        glowNode.run(glowAction) {
            glowNode.removeFromParent()
        }
    }
    
    // MARK: - Node Animation Methods
    
    /// 执行预定义的动画动词
    func executeAnimation(_ animationName: String, on node: SKNode, completion: (() -> Void)? = nil) {
        guard let action = animationVocabulary[animationName] else {
            print("⚠️ Animation '\(animationName)' not found in vocabulary")
            completion?()
            return
        }
        
        if let completion = completion {
            node.run(action, completion: completion)
        } else {
            node.run(action)
        }
    }
    
    /// 节点浮现动画
    func emergeNode(_ node: SKNode, completion: (() -> Void)? = nil) {
        // 设置初始状态
        node.setScale(0.3)
        node.alpha = 0.0
        executeAnimation("emerge", on: node, completion: completion)
    }
    
    /// 节点落定动画
    func settleNode(_ node: SKNode, completion: (() -> Void)? = nil) {
        executeAnimation("settle", on: node, completion: completion)
    }
    
    /// 节点脉动动画
    func pulseNode(_ node: SKNode) {
        executeAnimation("pulse", on: node)
    }
    
    /// 节点溶解动画（用于建构性遗忘）
    func dissolveNode(_ node: SKNode, completion: @escaping () -> Void) {
        executeAnimation("dissolve", on: node, completion: completion)
    }
    
    // MARK: - Emotional Lens Mode
    
    /// 激活情感透镜模式 - 将画布变为情绪热力图
    func activateEmotionalLens(in scene: SKScene, emotionalNodes: [UUID: EmotionalTag]) {
        // 暗化所有非情感节点
        for child in scene.children {
            if let nodeName = child.name,
               !nodeName.contains("emotional_aura"),
               !emotionalNodes.keys.contains(UUID(uuidString: nodeName) ?? UUID()) {
                child.alpha = 0.3
            }
        }
        
        // 增强情感光晕的可见性
        for (nodeId, _) in emotionalNodes {
            if let auraNode = emotionalAuraNodes[nodeId] {
                auraNode.alpha = 1.0
                auraNode.setScale(1.5)
            }
        }
        
        // 添加情感热力图背景
        let heatMapOverlay = SKShapeNode(rect: CGRect(x: -2000, y: -2000, width: 4000, height: 4000))
        heatMapOverlay.fillColor = UIColor.black.withAlphaComponent(0.7)
        heatMapOverlay.strokeColor = .clear
        heatMapOverlay.name = "emotional_lens_overlay"
        heatMapOverlay.zPosition = -5
        
        scene.addChild(heatMapOverlay)
    }
    
    /// 停用情感透镜模式
    func deactivateEmotionalLens(in scene: SKScene) {
        // 恢复所有节点的透明度
        for child in scene.children {
            if child.name != "emotional_lens_overlay" {
                child.alpha = 1.0
                child.setScale(1.0)
            }
        }
        
        // 移除热力图背景
        scene.childNode(withName: "emotional_lens_overlay")?.removeFromParent()
    }
    
    // MARK: - Performance Optimization
    
    /// 清理未使用的效果节点
    func cleanupUnusedEffects() {
        // 清理已删除节点的情感光晕
        emotionalAuraNodes = emotionalAuraNodes.filter { _, auraNode in
            auraNode.parent != nil
        }
        
        // 清理认知场
        cognitiveFields = cognitiveFields.filter { _, fieldNode in
            fieldNode.parent != nil
        }
    }
    
    /// 启用性能模式 - 禁用复杂效果
    func enablePerformanceMode() {
        // 禁用所有滤镜效果
        for (_, auraNode) in emotionalAuraNodes {
            auraNode.shouldEnableEffects = false
        }
    }
    
    /// 禁用性能模式 - 重新启用效果
    func disablePerformanceMode() {
        // 重新启用滤镜效果
        for (_, auraNode) in emotionalAuraNodes {
            auraNode.shouldEnableEffects = true
        }
    }
}

// MARK: - Animation Extensions

extension SKNode {
    
    /// 为任意节点添加呼吸感动画
    func addBreathingAnimation(duration: TimeInterval = 4.0) {
        let breathingAction = SKAction.repeatForever(
            SKAction.sequence([
                SKAction.scale(to: 1.02, duration: duration / 2),
                SKAction.scale(to: 0.98, duration: duration / 2)
            ])
        )
        run(breathingAction, withKey: "breathing")
    }
    
    /// 移除呼吸感动画
    func removeBreathingAnimation() {
        removeAction(forKey: "breathing")
    }
}

// MARK: - Animation Configuration Model

struct AnimationSettings {
    var enableEmotionalAuras: Bool = true
    var enableCognitiveMist: Bool = true
    var enableResonanceFlash: Bool = true
    var performanceMode: Bool = false
    var animationIntensity: Float = 1.0
    
    static let `default` = AnimationSettings()
}