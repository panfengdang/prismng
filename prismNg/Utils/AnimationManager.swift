//
//  AnimationManager.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SpriteKit
import SwiftUI

// MARK: - Animation Manager
class AnimationManager {
    
    // MARK: - Node Animations
    
    static func nodeAppearAnimation() -> SKAction {
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        let bounce = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        
        let appearGroup = SKAction.group([fadeIn, scaleUp])
        return SKAction.sequence([appearGroup, bounce])
    }
    
    static func nodeDisappearAnimation() -> SKAction {
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let scaleDown = SKAction.scale(to: 0.1, duration: 0.2)
        return SKAction.group([fadeOut, scaleDown])
    }
    
    static func nodeSelectAnimation() -> SKAction {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.15),
            SKAction.scale(to: 1.0, duration: 0.15)
        ])
        return SKAction.repeat(pulse, count: 1)
    }
    
    static func nodeHighlightAnimation() -> SKAction {
        let glow = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        return SKAction.repeatForever(glow)
    }
    
    // MARK: - Connection Animations
    
    static func connectionAppearAnimation() -> SKAction {
        let drawAction = SKAction.customAction(withDuration: 0.5) { node, elapsedTime in
            guard let shapeNode = node as? SKShapeNode else { return }
            let progress = elapsedTime / 0.5
            // Update stroke end based on progress
            shapeNode.alpha = progress
        }
        return drawAction
    }
    
    static func connectionPulseAnimation() -> SKAction {
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        return SKAction.repeatForever(pulse)
    }
    
    // MARK: - UI Animations
    
    static func toolbarSlideIn() -> Animation {
        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    }
    
    static func toolbarSlideOut() -> Animation {
        .easeInOut(duration: 0.3)
    }
    
    static func cognitiveGearTransition() -> Animation {
        .interpolatingSpring(stiffness: 300, damping: 30)
    }
    
    // MARK: - Special Effects
    
    static func createResonanceFlash(at position: CGPoint, in scene: SKScene) {
        let flash = SKShapeNode(circleOfRadius: 30)
        flash.fillColor = .systemYellow
        flash.strokeColor = .systemOrange
        flash.lineWidth = 2
        flash.position = position
        flash.alpha = 0
        
        scene.addChild(flash)
        
        let flashSequence = SKAction.sequence([
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.1),
                SKAction.scale(to: 2.0, duration: 0.1)
            ]),
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 0.1, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ])
        
        flash.run(flashSequence)
    }
    
    static func createIncubationDrift() -> SKAction {
        let driftX = SKAction.moveBy(x: CGFloat.random(in: -20...20), y: 0, duration: 2.0)
        let driftY = SKAction.moveBy(x: 0, y: CGFloat.random(in: -20...20), duration: 2.0)
        let drift = SKAction.group([driftX, driftY])
        
        let returnX = SKAction.moveBy(x: -driftX.duration, y: 0, duration: 2.0)
        let returnY = SKAction.moveBy(x: 0, y: -driftY.duration, duration: 2.0)
        let returnDrift = SKAction.group([returnX, returnY])
        
        let fullCycle = SKAction.sequence([drift, returnDrift])
        return SKAction.repeatForever(fullCycle)
    }
    
    // MARK: - Emotional Animations
    
    static func emotionalGlow(for intensity: Double, emotion: EmotionalTag) -> SKAction {
        // Create a custom glow effect
        let glow = SKAction.customAction(withDuration: 1.0) { node, elapsedTime in
            let progress = sin(elapsedTime * 2 * .pi)
            let currentAlpha = 0.3 + (progress * 0.3 * intensity)
            node.alpha = currentAlpha
        }
        
        return SKAction.repeatForever(glow)
    }
    
    private static func emotionalColor(for emotion: EmotionalTag) -> UIColor {
        switch emotion {
        case .excited:
            return .systemYellow
        case .calm:
            return .systemBlue
        case .confused:
            return .systemPurple
        case .inspired:
            return .systemOrange
        case .frustrated:
            return .systemRed
        case .curious:
            return .systemTeal
        case .confident:
            return .systemGreen
        case .uncertain:
            return .systemGray
        }
    }
    
    // MARK: - Physics-based Animations
    
    static func configureNodePhysics(for node: SKNode, mass: CGFloat = 1.0) {
        let physicsBody = SKPhysicsBody(circleOfRadius: 30)
        physicsBody.mass = mass
        physicsBody.friction = 0.2
        physicsBody.restitution = 0.3
        physicsBody.linearDamping = 0.5
        physicsBody.angularDamping = 0.5
        physicsBody.categoryBitMask = PhysicsCategory.node
        physicsBody.contactTestBitMask = PhysicsCategory.node
        physicsBody.collisionBitMask = PhysicsCategory.node
        
        node.physicsBody = physicsBody
    }
    
    static func createAttractiveForce(between nodeA: SKNode, and nodeB: SKNode, strength: Float = 0.1) -> SKFieldNode {
        let fieldNode = SKFieldNode.springField()
        fieldNode.strength = strength
        fieldNode.falloff = 2.0
        fieldNode.minimumRadius = 50.0
        fieldNode.position = CGPoint(
            x: (nodeA.position.x + nodeB.position.x) / 2,
            y: (nodeA.position.y + nodeB.position.y) / 2
        )
        return fieldNode
    }
}

// MARK: - Physics Categories
struct PhysicsCategory {
    static let node: UInt32 = 0x1 << 0
    static let connection: UInt32 = 0x1 << 1
    static let boundary: UInt32 = 0x1 << 2
}

// MARK: - Animation Extensions

extension SKNode {
    func animate(with animation: SKAction, completion: (() -> Void)? = nil) {
        if let completion = completion {
            let completionAction = SKAction.run(completion)
            let sequence = SKAction.sequence([animation, completionAction])
            self.run(sequence)
        } else {
            self.run(animation)
        }
    }
    
    func stopAllAnimations() {
        self.removeAllActions()
    }
    
    func pulseOnce() {
        animate(with: AnimationManager.nodeSelectAnimation())
    }
    
    func startGlowAnimation(for emotion: EmotionalTag, intensity: Double) {
        let glowAction = AnimationManager.emotionalGlow(for: intensity, emotion: emotion)
        self.run(glowAction, withKey: "emotionalGlow")
    }
    
    func stopGlowAnimation() {
        self.removeAction(forKey: "emotionalGlow")
    }
}

extension View {
    func animatedAppear() -> some View {
        self
            .transition(.asymmetric(
                insertion: .scale.combined(with: .opacity),
                removal: .scale.combined(with: .opacity)
            ))
    }
    
    func cognitiveGearTransition() -> some View {
        self
            .animation(AnimationManager.cognitiveGearTransition(), value: UUID())
    }
}