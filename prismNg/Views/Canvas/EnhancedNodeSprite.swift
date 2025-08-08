//
//  EnhancedNodeSprite.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SpriteKit
import SwiftUI

// MARK: - Enhanced Node Sprite
class EnhancedNodeSprite: SKNode {
    let nodeId: UUID
    var thoughtNode: ThoughtNode
    var lastTapTime: CFTimeInterval?
    
    // Visual components
    private let backgroundNode: SKShapeNode
    private let glowNode: SKEffectNode
    private let contentLabel: SKLabelNode
    private let typeIndicator: SKShapeNode
    private let emotionalAura: SKEffectNode?
    private var emotionalIndicators: [SKNode] = []
    
    // Animation states
    private var isSelected = false
    private var isDragging = false
    private var breathingAction: SKAction?
    
    // Layout constants
    private let baseSize = CGSize(width: 120, height: 80)
    private let cornerRadius: CGFloat = 16
    private let glowRadius: CGFloat = 20
    
    init(node: ThoughtNode) {
        self.nodeId = node.id
        self.thoughtNode = node
        
        // Create background shape
        self.backgroundNode = SKShapeNode(rectOf: baseSize, cornerRadius: cornerRadius)
        
        // Create glow effect
        self.glowNode = SKEffectNode()
        let glowShape = SKShapeNode(rectOf: CGSize(
            width: baseSize.width + glowRadius * 2,
            height: baseSize.height + glowRadius * 2
        ), cornerRadius: cornerRadius + glowRadius/2)
        glowShape.fillColor = .clear
        glowShape.strokeColor = .clear
        glowNode.addChild(glowShape)
        
        // Create content label
        self.contentLabel = SKLabelNode(text: node.content)
        
        // Create type indicator
        self.typeIndicator = SKShapeNode(circleOfRadius: 6)
        
        // Create emotional aura if needed
        if node.emotionalIntensity > 0.3 {
            self.emotionalAura = SKEffectNode()
        } else {
            self.emotionalAura = nil
        }
        
        super.init()
        
        // Setup node hierarchy
        setupNodeHierarchy()
        
        // Apply initial appearance
        position = CGPoint(x: node.position.x, y: node.position.y)
        updateAppearance()
        
        // Start breathing animation
        startBreathingAnimation()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupNodeHierarchy() {
        // Add glow behind everything
        addChild(glowNode)
        
        // Add emotional aura if exists
        if let aura = emotionalAura {
            addChild(aura)
        }
        
        // Add background
        addChild(backgroundNode)
        
        // Add type indicator
        typeIndicator.position = CGPoint(x: baseSize.width/2 - 15, y: baseSize.height/2 - 15)
        backgroundNode.addChild(typeIndicator)
        
        // Add content label
        contentLabel.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(contentLabel)
    }
    
    // MARK: - Appearance Updates
    
    func updateAppearance() {
        // Update colors based on node type
        let (fillColor, strokeColor, typeColor) = getColorsForType(thoughtNode.nodeType)
        
        // Background appearance
        backgroundNode.fillColor = fillColor
        backgroundNode.strokeColor = strokeColor
        backgroundNode.lineWidth = isSelected ? 3 : 1.5
        backgroundNode.alpha = CGFloat(thoughtNode.opacity)
        
        // Glow effect
        if isSelected || thoughtNode.emotionalIntensity > 0.5 {
            glowNode.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 10])
            glowNode.shouldEnableEffects = true
            if let glowShape = glowNode.children.first as? SKShapeNode {
                glowShape.fillColor = typeColor.withAlphaComponent(0.3)
                glowShape.strokeColor = typeColor
            }
        } else {
            glowNode.shouldEnableEffects = false
        }
        
        // Type indicator
        typeIndicator.fillColor = typeColor
        typeIndicator.strokeColor = .clear
        
        // Content label
        setupContentLabel()
        
        // Emotional aura
        updateEmotionalAura()
        
        // Emotional indicators
        updateEmotionalIndicators()
        
        // Size based on content
        updateSize()
    }
    
    private func getColorsForType(_ type: NodeType) -> (fill: UIColor, stroke: UIColor, indicator: UIColor) {
        switch type {
        case .thought:
            return (.systemBlue.withAlphaComponent(0.1), .systemBlue, .systemBlue)
        case .insight:
            return (.systemYellow.withAlphaComponent(0.1), .systemYellow, .systemYellow)
        case .question:
            return (.systemPurple.withAlphaComponent(0.1), .systemPurple, .systemPurple)
        case .conclusion:
            return (.systemGreen.withAlphaComponent(0.1), .systemGreen, .systemGreen)
        case .contradiction:
            return (.systemRed.withAlphaComponent(0.1), .systemRed, .systemRed)
        case .structure:
            return (.systemGray.withAlphaComponent(0.1), .systemGray, .systemGray)
        }
    }
    
    private func setupContentLabel() {
        contentLabel.text = thoughtNode.content
        contentLabel.fontName = "System"
        contentLabel.fontSize = 14
        contentLabel.fontColor = .label
        contentLabel.preferredMaxLayoutWidth = baseSize.width - 20
        contentLabel.numberOfLines = 0
        contentLabel.verticalAlignmentMode = .center
        contentLabel.horizontalAlignmentMode = .center
        
        // Add shadow for better readability
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = CGSize(width: 0, height: 1)
        shadow.shadowBlurRadius = 2
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.label,
            .shadow: shadow
        ]
        
        contentLabel.attributedText = NSAttributedString(string: thoughtNode.content, attributes: attributes)
    }
    
    private func updateEmotionalAura() {
        guard let aura = emotionalAura else { return }
        
        // Remove existing children
        aura.removeAllChildren()
        
        // Create emotional particles
        if thoughtNode.emotionalIntensity > 0.3 {
            let particleEmitter = createEmotionalParticles()
            aura.addChild(particleEmitter)
            
            // Add blur effect
            aura.filter = CIFilter(name: "CIGaussianBlur", parameters: ["inputRadius": 5])
            aura.shouldEnableEffects = true
        }
    }
    
    private func updateEmotionalIndicators() {
        // Remove existing indicators
        emotionalIndicators.forEach { $0.removeFromParent() }
        emotionalIndicators.removeAll()
        
        // Add emotional tag indicators
        let emotions = thoughtNode.emotionalTags
        guard !emotions.isEmpty else { return }
        
        let indicatorSize: CGFloat = 16
        let spacing: CGFloat = 4
        let startX = -(CGFloat(emotions.count - 1) * (indicatorSize + spacing)) / 2
        
        for (index, emotionTag) in emotions.prefix(3).enumerated() {
            let indicator = SKShapeNode(circleOfRadius: indicatorSize / 2)
            indicator.fillColor = getEmotionColor(for: emotionTag.rawValue)
            indicator.strokeColor = .clear
            indicator.position = CGPoint(
                x: startX + CGFloat(index) * (indicatorSize + spacing),
                y: -baseSize.height/2 - 20
            )
            
            backgroundNode.addChild(indicator)
            emotionalIndicators.append(indicator)
            
            // Add subtle pulse animation
            let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 1.0)
            let fadeOut = SKAction.fadeAlpha(to: 0.5, duration: 1.0)
            let pulse = SKAction.repeatForever(SKAction.sequence([fadeIn, fadeOut]))
            indicator.run(pulse)
        }
    }
    
    private func getEmotionColor(for emotionTag: String) -> UIColor {
        // Map emotion tags to colors
        switch emotionTag {
        case "excited": return .systemYellow
        case "inspired": return .systemPurple
        case "calm": return .systemBlue
        case "curious": return .systemGreen
        case "frustrated": return .systemRed
        case "confused": return .systemOrange
        case "confident": return .systemIndigo
        case "uncertain": return .systemGray
        default: return .systemGray
        }
    }
    
    private func createEmotionalParticles() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        
        // Configure based on emotional tags
        if let primaryEmotion = thoughtNode.emotionalTags.first {
            switch primaryEmotion {
            case .excited:
                emitter.particleTexture = SKTexture(imageNamed: "spark")
                emitter.particleColor = .systemYellow
                emitter.particleColorBlendFactor = 1.0
                emitter.particleLifetime = 2.0
                emitter.particleBirthRate = 5
                
            case .calm:
                emitter.particleTexture = SKTexture(imageNamed: "circle")
                emitter.particleColor = .systemBlue
                emitter.particleColorBlendFactor = 0.8
                emitter.particleLifetime = 4.0
                emitter.particleBirthRate = 2
                
            case .confused:
                emitter.particleTexture = SKTexture(imageNamed: "question")
                emitter.particleColor = .systemPurple
                emitter.particleColorBlendFactor = 0.7
                emitter.particleLifetime = 3.0
                emitter.particleBirthRate = 3
                
            default:
                emitter.particleTexture = SKTexture(imageNamed: "circle")
                emitter.particleColor = .white
                emitter.particleColorBlendFactor = 0.5
                emitter.particleLifetime = 2.0
                emitter.particleBirthRate = 2
            }
        }
        
        // Common settings
        emitter.particleScale = 0.1
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = -0.05
        emitter.particleAlpha = CGFloat(thoughtNode.emotionalIntensity)
        emitter.particleAlphaSpeed = -0.3
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        
        return emitter
    }
    
    private func updateSize() {
        let contentSize = contentLabel.calculateAccumulatedFrame().size
        let newWidth = max(baseSize.width, contentSize.width + 40)
        let newHeight = max(baseSize.height, contentSize.height + 40)
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        // Update background size
        backgroundNode.path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: -newSize.width/2, y: -newSize.height/2), size: newSize), cornerRadius: cornerRadius).cgPath
        
        // Update glow size
        if let glowShape = glowNode.children.first as? SKShapeNode {
            let glowSize = CGSize(width: newSize.width + glowRadius * 2, height: newSize.height + glowRadius * 2)
            glowShape.path = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: -glowSize.width/2, y: -glowSize.height/2), size: glowSize), cornerRadius: cornerRadius + glowRadius/2).cgPath
        }
        
        // Update type indicator position
        typeIndicator.position = CGPoint(x: newSize.width/2 - 15, y: newSize.height/2 - 15)
    }
    
    // MARK: - Animations
    
    private func startBreathingAnimation() {
        // Subtle breathing effect
        let scaleUp = SKAction.scale(to: 1.02, duration: 2.0)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 0.98, duration: 2.0)
        scaleDown.timingMode = .easeInEaseOut
        
        breathingAction = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
        run(breathingAction!, withKey: "breathing")
    }
    
    func animateSelection() {
        isSelected = true
        updateAppearance()
        
        // Selection animation
        let scale = SKAction.scale(to: 1.1, duration: 0.1)
        let scaleBack = SKAction.scale(to: 1.0, duration: 0.1)
        run(SKAction.sequence([scale, scaleBack]))
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    func animateDeselection() {
        isSelected = false
        updateAppearance()
    }
    
    func animateCreation() {
        // Start from small scale
        setScale(0.1)
        alpha = 0
        
        // Grow and fade in
        let scale = SKAction.scale(to: 1.0, duration: 0.3)
        scale.timingMode = .easeOut
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        
        run(SKAction.group([scale, fadeIn]))
    }
    
    func animateDeletion(completion: @escaping () -> Void) {
        // Stop breathing
        removeAction(forKey: "breathing")
        
        // Shrink and fade out
        let scale = SKAction.scale(to: 0.1, duration: 0.3)
        scale.timingMode = .easeIn
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        run(SKAction.sequence([
            SKAction.group([scale, fadeOut]),
            remove
        ])) {
            completion()
        }
    }
    
    func animateDrag(isDragging: Bool) {
        self.isDragging = isDragging
        
        if isDragging {
            // Lift effect
            let scale = SKAction.scale(to: 1.15, duration: 0.1)
            run(scale)
            
            // Shadow effect
            // Note: In real implementation, add shadow node
        } else {
            // Drop effect
            let scale = SKAction.scale(to: 1.0, duration: 0.1)
            let bounce = SKAction.sequence([
                SKAction.scale(to: 0.95, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])
            run(SKAction.sequence([scale, bounce]))
        }
    }
    
    // MARK: - Update Methods
    
    func updateContent(_ node: ThoughtNode) {
        self.thoughtNode = node
        position = CGPoint(x: node.position.x, y: node.position.y)
        updateAppearance()
    }
}