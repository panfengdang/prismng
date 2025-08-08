//
//  VisualEffectsService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import SpriteKit
import CoreImage
import CoreHaptics

// MARK: - Visual Effects Service
@MainActor
class VisualEffectsService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isDriftModeActive = false
    @Published var isEmotionalLensActive = false
    @Published var isCognitiveFogActive = false
    @Published var activeEffects: Set<VisualEffectType> = []
    
    // MARK: - Private Properties
    private var hapticEngine: CHHapticEngine?
    private var effectNodes: [UUID: SKEffectNode] = [:]
    private var activeAnimations: [UUID: SKAction] = [:]
    
    // Core Image filters for effects
    private let gaussianBlur = CIFilter(name: "CIGaussianBlur")
    private let colorControls = CIFilter(name: "CIColorControls")
    private let hueAdjust = CIFilter(name: "CIHueAdjust")
    
    // MARK: - Animation Dictionary
    enum AnimationVerb {
        case emerge      // 浮现 - Node creation fade-in
        case settle      // 落定 - Node reaching target position
        case pulse       // 脉动 - Breathing sensation for emotional nodes
        case dissolve    // 溶解 - Forgetting effect
        case connect     // 连接 - Golden connection line animation
        case drift       // 漂移 - Brownian motion
        case shimmer     // 闪烁 - Confusion or uncertainty
        case glow        // 光晕 - Emotional aura
    }
    
    // MARK: - Setup
    func setup() {
        setupHapticEngine()
        setupCoreImageFilters()
    }
    
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Failed to setup haptic engine: \(error)")
        }
    }
    
    private func setupCoreImageFilters() {
        gaussianBlur?.setValue(5.0, forKey: kCIInputRadiusKey)
        colorControls?.setValue(1.2, forKey: kCIInputSaturationKey)
        hueAdjust?.setValue(0.0, forKey: kCIInputAngleKey)
    }
    
    // MARK: - Emotional Halo Effects
    func applyEmotionalHalo(to nodeSprite: SKNode, emotion: EmotionalTag, intensity: Double) {
        // Remove existing halo if any
        removeEffect(from: nodeSprite, type: .emotionalHalo)
        
        // Create halo effect node
        let haloNode = SKEffectNode()
        haloNode.name = "emotionalHalo"
        
        // Create glow shape
        let glowShape = SKShapeNode(circleOfRadius: 60)
        glowShape.fillColor = emotionColor(for: emotion).withAlphaComponent(0.3)
        glowShape.strokeColor = .clear
        glowShape.glowWidth = 20
        
        // Apply Core Image filter for soft glow
        if let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setValue(10.0, forKey: kCIInputRadiusKey)
            haloNode.filter = filter
            haloNode.shouldEnableEffects = true
        }
        
        haloNode.addChild(glowShape)
        nodeSprite.addChild(haloNode)
        
        // Store reference
        effectNodes[nodeSprite.userData?["nodeId"] as? UUID ?? UUID()] = haloNode
        
        // Apply pulsing animation based on intensity
        let pulseAction = createPulseAnimation(intensity: intensity)
        haloNode.run(SKAction.repeatForever(pulseAction))
    }
    
    private func emotionColor(for emotion: EmotionalTag) -> UIColor {
        switch emotion {
        case .excited:
            return .systemOrange // Warm orange-red
        case .calm:
            return .systemBlue // Cool blue
        case .inspired:
            return .systemGreen // Growth green
        case .confused:
            return .systemPurple // Uncertain purple
        case .confident:
            return .systemYellow // Golden achievement
        case .frustrated:
            return .systemRed.withAlphaComponent(0.8)
        case .curious:
            return .systemPink
        case .uncertain:
            return .systemIndigo
        }
    }
    
    // MARK: - Cognitive Fog Effect
    func applyCognitiveFog(to scene: SKScene) {
        guard !isCognitiveFogActive else { return }
        isCognitiveFogActive = true
        
        // Create fog overlay
        let fogNode = SKEffectNode()
        fogNode.name = "cognitiveFog"
        fogNode.zPosition = 100 // Above nodes but below UI
        
        // Create particle emitter for mist effect
        if let mistEmitter = createMistEmitter() {
            fogNode.addChild(mistEmitter)
        }
        
        // Apply blur filter
        if let filter = CIFilter(name: "CIGaussianBlur") {
            filter.setValue(3.0, forKey: kCIInputRadiusKey)
            fogNode.filter = filter
            fogNode.shouldEnableEffects = true
        }
        
        scene.addChild(fogNode)
        
        // Fade in animation
        fogNode.alpha = 0
        fogNode.run(SKAction.fadeIn(withDuration: 1.5))
    }
    
    func removeCognitiveFog(from scene: SKScene) {
        guard isCognitiveFogActive else { return }
        isCognitiveFogActive = false
        
        if let fogNode = scene.childNode(withName: "cognitiveFog") {
            fogNode.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    // MARK: - Dissolve Animation (Forgetting)
    func applyDissolveAnimation(to nodeSprite: SKNode, completion: @escaping () -> Void) {
        // Create dissolve effect sequence
        let dissolveSequence = SKAction.sequence([
            // Start pulsing faster
            SKAction.repeat(createPulseAnimation(intensity: 0.8, duration: 0.3), count: 3),
            
            // Fade and scale down simultaneously
            SKAction.group([
                SKAction.fadeOut(withDuration: 1.5),
                SKAction.scale(to: 0.3, duration: 1.5),
                SKAction.rotate(byAngle: .pi / 4, duration: 1.5)
            ]),
            
            // Clean up
            SKAction.run { completion() },
            SKAction.removeFromParent()
        ])
        
        // Add particles for dissolve effect
        if let particleEmitter = createDissolveParticles() {
            nodeSprite.addChild(particleEmitter)
        }
        
        // Play haptic feedback
        playHapticPattern(.dissolve)
        
        nodeSprite.run(dissolveSequence, withKey: "dissolve")
    }
    
    // MARK: - Drift Mode
    func enableDriftMode(for scene: SKScene) {
        guard !isDriftModeActive else { return }
        isDriftModeActive = true
        
        // Apply physics field for gentle drift
        let noiseField = SKFieldNode.noiseField(withSmoothness: 0.8, animationSpeed: 0.3)
        noiseField.name = "driftField"
        noiseField.strength = 0.5
        noiseField.region = SKRegion(size: scene.size)
        scene.addChild(noiseField)
        
        // Enable physics on all nodes
        scene.enumerateChildNodes(withName: "//thoughtNode") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.physicsBody = SKPhysicsBody(circleOfRadius: 30)
                sprite.physicsBody?.isDynamic = true
                sprite.physicsBody?.affectedByGravity = false
                sprite.physicsBody?.mass = 0.1
                sprite.physicsBody?.linearDamping = 0.8
            }
        }
    }
    
    func disableDriftMode(for scene: SKScene) {
        guard isDriftModeActive else { return }
        isDriftModeActive = false
        
        // Remove drift field
        scene.childNode(withName: "driftField")?.removeFromParent()
        
        // Disable physics on nodes
        scene.enumerateChildNodes(withName: "//thoughtNode") { node, _ in
            if let sprite = node as? SKSpriteNode {
                sprite.physicsBody = nil
            }
        }
    }
    
    // MARK: - Connection Animations
    func animateConnection(from startNode: SKNode, to endNode: SKNode, type: ConnectionType, in scene: SKScene) {
        // Create connection line
        let path = CGMutablePath()
        path.move(to: startNode.position)
        path.addLine(to: endNode.position)
        
        let connectionLine = SKShapeNode(path: path)
        connectionLine.name = "connectionAnimation"
        connectionLine.strokeColor = connectionColor(for: type)
        connectionLine.lineWidth = connectionWidth(for: type)
        connectionLine.zPosition = 50
        
        // Apply glow effect
        connectionLine.glowWidth = 5.0
        
        scene.addChild(connectionLine)
        
        // Animate the connection
        let animationSequence = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.3),
            SKAction.wait(forDuration: 1.5),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ])
        
        connectionLine.run(animationSequence)
        
        // Play haptic feedback
        playHapticPattern(.connection)
    }
    
    private func connectionColor(for type: ConnectionType) -> UIColor {
        switch type {
        case .strongSupport:
            return .systemGreen
        case .weakAssociation:
            return .systemBlue.withAlphaComponent(0.6)
        case .contradiction:
            return .systemRed
        case .similarity:
            return .systemPurple
        case .causality:
            return .systemOrange
        case .resonance:
            return .systemPink
        }
    }
    
    private func connectionWidth(for type: ConnectionType) -> CGFloat {
        switch type {
        case .strongSupport:
            return 3.0
        case .weakAssociation:
            return 1.5
        case .contradiction:
            return 2.0
        case .similarity:
            return 2.0
        case .causality:
            return 2.5
        case .resonance:
            return 1.8
        }
    }
    
    // MARK: - Animation Creators
    private func createPulseAnimation(intensity: Double, duration: TimeInterval = 1.0) -> SKAction {
        let scaleUp = SKAction.scale(to: 1.0 + CGFloat(intensity * 0.1), duration: duration / 2)
        let scaleDown = SKAction.scale(to: 1.0, duration: duration / 2)
        scaleUp.timingMode = .easeInEaseOut
        scaleDown.timingMode = .easeInEaseOut
        
        return SKAction.sequence([scaleUp, scaleDown])
    }
    
    private func createMistEmitter() -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleBirthRate = 10
        emitter.particleLifetime = 10
        emitter.particleLifetimeRange = 5
        emitter.particlePositionRange = CGVector(dx: 500, dy: 500)
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.particleAlpha = 0.2
        emitter.particleAlphaRange = 0.1
        emitter.particleScale = 0.5
        emitter.particleScaleRange = 0.3
        emitter.particleBlendMode = .alpha
        emitter.particleColor = .white
        return emitter
    }
    
    private func createDissolveParticles() -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        emitter.particleTexture = SKTexture(imageNamed: "spark")
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 50
        emitter.particleLifetime = 1.5
        emitter.particleLifetimeRange = 0.5
        emitter.particleSpeed = 50
        emitter.particleSpeedRange = 30
        emitter.emissionAngleRange = .pi * 2
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -0.5
        emitter.particleScale = 0.2
        emitter.particleScaleSpeed = -0.1
        emitter.particleColor = .systemBlue
        return emitter
    }
    
    // MARK: - Haptic Feedback
    enum HapticPattern {
        case nodeCreation
        case connection
        case dissolve
        case emotionalPulse
    }
    
    private func playHapticPattern(_ pattern: HapticPattern) {
        guard let engine = hapticEngine else { return }
        
        do {
            let hapticEvents: [CHHapticEvent]
            
            switch pattern {
            case .nodeCreation:
                hapticEvents = [
                    CHHapticEvent(eventType: .hapticTransient,
                                  parameters: [
                                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                                  ],
                                  relativeTime: 0)
                ]
                
            case .connection:
                hapticEvents = [
                    CHHapticEvent(eventType: .hapticContinuous,
                                  parameters: [
                                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                                  ],
                                  relativeTime: 0,
                                  duration: 0.3)
                ]
                
            case .dissolve:
                hapticEvents = (0..<3).map { i in
                    CHHapticEvent(eventType: .hapticTransient,
                                  parameters: [
                                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.8 - Double(i) * 0.2)),
                                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                                  ],
                                  relativeTime: TimeInterval(i) * 0.2)
                }
                
            case .emotionalPulse:
                hapticEvents = [
                    CHHapticEvent(eventType: .hapticContinuous,
                                  parameters: [
                                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                                  ],
                                  relativeTime: 0,
                                  duration: 1.0)
                ]
            }
            
            let pattern = try CHHapticPattern(events: hapticEvents, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    private func removeEffect(from node: SKNode, type: VisualEffectType) {
        switch type {
        case .emotionalHalo:
            node.childNode(withName: "emotionalHalo")?.removeFromParent()
        case .cognitiveFog:
            node.childNode(withName: "cognitiveFog")?.removeFromParent()
        case .driftMode:
            // Handled by disableDriftMode
            break
        }
    }
}

// MARK: - Supporting Types
enum VisualEffectType: String, CaseIterable {
    case emotionalHalo = "emotional_halo"
    case cognitiveFog = "cognitive_fog"
    case driftMode = "drift_mode"
}