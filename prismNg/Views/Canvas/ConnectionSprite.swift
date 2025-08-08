//
//  ConnectionSprite.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SpriteKit

// MARK: - Connection Sprite
class ConnectionSprite: SKNode {
    let connectionId: UUID
    let connection: NodeConnection
    
    private let lineNode: SKShapeNode
    private let flowNode: SKShapeNode?
    private let labelNode: SKLabelNode?
    
    private var fromPosition: CGPoint = .zero
    private var toPosition: CGPoint = .zero
    
    init(connection: NodeConnection, from fromNode: EnhancedNodeSprite, to toNode: EnhancedNodeSprite) {
        self.connectionId = connection.id
        self.connection = connection
        
        // Create line
        self.lineNode = SKShapeNode()
        
        // Create flow animation if needed
        if connection.strength > 0.7 {
            self.flowNode = SKShapeNode()
        } else {
            self.flowNode = nil
        }
        
        // Create label for AI-generated connections
        if connection.isAIGenerated {
            self.labelNode = SKLabelNode()
        } else {
            self.labelNode = nil
        }
        
        super.init()
        
        // Setup appearance
        setupAppearance()
        
        // Update positions
        updateConnection(from: fromNode, to: toNode)
        
        // Add children
        addChild(lineNode)
        if let flow = flowNode {
            addChild(flow)
        }
        if let label = labelNode {
            addChild(label)
        }
        
        // Start animations
        if connection.strength > 0.7 {
            startFlowAnimation()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupAppearance() {
        // Line appearance based on connection type
        let (color, pattern) = getStyleForType(connection.connectionType)
        
        lineNode.strokeColor = color.withAlphaComponent(CGFloat(connection.strength))
        lineNode.lineWidth = 1.5 + CGFloat(connection.strength) * 1.5
        
        // Note: SKShapeNode doesn't support dash patterns directly
        // For dashed lines, we would need to create custom path with gaps
        
        // Flow node appearance
        if let flow = flowNode {
            flow.strokeColor = color
            flow.lineWidth = 3.0
            flow.alpha = 0.6
        }
        
        // Label for AI connections
        if let label = labelNode {
            label.text = "AI"
            label.fontSize = 10
            label.fontName = "System"
            label.fontColor = color
            label.alpha = 0.8
        }
    }
    
    private func getStyleForType(_ type: ConnectionType) -> (color: UIColor, pattern: [CGFloat]?) {
        switch type {
        case .strongSupport:
            return (.systemGreen, nil)
        case .weakAssociation:
            return (.systemGray, [5, 5])
        case .contradiction:
            return (.systemRed, [3, 3])
        case .causality:
            return (.systemBlue, nil)
        case .similarity:
            return (.systemPurple, [8, 4])
        case .resonance:
            return (.systemYellow, [2, 2])
        }
    }
    
    // MARK: - Update
    
    func updateConnection(from fromNode: EnhancedNodeSprite, to toNode: EnhancedNodeSprite) {
        fromPosition = fromNode.position
        toPosition = toNode.position
        
        // Create curved path
        let path = createCurvedPath(from: fromPosition, to: toPosition)
        lineNode.path = path
        
        // Update flow path
        if let flow = flowNode {
            flow.path = path
        }
        
        // Update label position
        if let label = labelNode {
            let midPoint = CGPoint(
                x: (fromPosition.x + toPosition.x) / 2,
                y: (fromPosition.y + toPosition.y) / 2
            )
            label.position = midPoint
        }
    }
    
    private func createCurvedPath(from: CGPoint, to: CGPoint) -> CGPath {
        let path = UIBezierPath()
        path.move(to: from)
        
        // Calculate control points for a subtle curve
        let dx = to.x - from.x
        let dy = to.y - from.y
        let distance = hypot(dx, dy)
        
        if distance > 100 {
            // Add curve for longer connections
            let midX = (from.x + to.x) / 2
            let midY = (from.y + to.y) / 2
            
            // Perpendicular offset for curve
            let perpX = -dy / distance * 20
            let perpY = dx / distance * 20
            
            let controlPoint = CGPoint(x: midX + perpX, y: midY + perpY)
            
            path.addQuadCurve(to: to, controlPoint: controlPoint)
        } else {
            // Straight line for short connections
            path.addLine(to: to)
        }
        
        // Add arrowhead
        if connection.connectionType == .causality {
            addArrowhead(to: path, at: to, from: from)
        }
        
        return path.cgPath
    }
    
    private func addArrowhead(to path: UIBezierPath, at point: CGPoint, from: CGPoint) {
        let angle = atan2(point.y - from.y, point.x - from.x)
        let arrowLength: CGFloat = 10
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: point.x - arrowLength * cos(angle - arrowAngle),
            y: point.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: point.x - arrowLength * cos(angle + arrowAngle),
            y: point.y - arrowLength * sin(angle + arrowAngle)
        )
        
        path.move(to: arrowPoint1)
        path.addLine(to: point)
        path.addLine(to: arrowPoint2)
    }
    
    // MARK: - Animations
    
    private func startFlowAnimation() {
        guard let flow = flowNode else { return }
        
        // Create dash phase animation for flow effect
        let dashAnimation = CABasicAnimation(keyPath: "lineDashPhase")
        dashAnimation.fromValue = 0
        dashAnimation.toValue = 20
        dashAnimation.duration = 2.0
        dashAnimation.repeatCount = .infinity
        
        if let shapeLayer = flow.path.flatMap({ path in
            let layer = CAShapeLayer()
            layer.path = path
            return layer
        }) {
            shapeLayer.add(dashAnimation, forKey: "flow")
        }
        
        // Pulse animation
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.8, duration: 1.0),
            SKAction.fadeAlpha(to: 0.4, duration: 1.0)
        ])
        flow.run(SKAction.repeatForever(pulse))
    }
    
    func animateCreation() {
        alpha = 0
        setScale(0.8)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let scale = SKAction.scale(to: 1.0, duration: 0.3)
        scale.timingMode = .easeOut
        
        run(SKAction.group([fadeIn, scale]))
    }
    
    func animateDeletion(completion: @escaping () -> Void) {
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let scale = SKAction.scale(to: 0.8, duration: 0.3)
        scale.timingMode = .easeIn
        let remove = SKAction.removeFromParent()
        
        run(SKAction.sequence([
            SKAction.group([fadeOut, scale]),
            remove
        ])) {
            completion()
        }
    }
    
    func highlight() {
        let scale = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleBack = SKAction.scale(to: 1.0, duration: 0.1)
        let glow = SKAction.run { [weak self] in
            self?.lineNode.glowWidth = 5.0
        }
        let removeGlow = SKAction.run { [weak self] in
            self?.lineNode.glowWidth = 0.0
        }
        
        run(SKAction.sequence([glow, scale, scaleBack, removeGlow]))
    }
}