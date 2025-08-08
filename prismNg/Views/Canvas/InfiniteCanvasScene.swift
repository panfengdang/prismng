//
//  InfiniteCanvasScene.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SpriteKit
import SwiftUI
import Combine

// MARK: - Infinite Canvas Scene
class InfiniteCanvasScene: SKScene {
    weak var canvasViewModel: CanvasViewModel?
    weak var interactionService: InteractionPreferenceService?
    
    // Node management
    private var nodeSprites: [UUID: EnhancedNodeSprite] = [:]
    private var connectionSprites: [UUID: ConnectionSprite] = [:]
    
    // Camera and viewport
    private var cameraNode: SKCameraNode!
    private var gridNode: GridNode!
    private var minimapNode: MinimapNode?
    
    // Gesture handling
    private var gestureCoordinator: CanvasGestureCoordinator?
    private var selectedNodes: Set<UUID> = []
    private var isDragging = false
    
    // Canvas bounds (soft limits)
    private let canvasBounds = CGRect(x: -5000, y: -5000, width: 10000, height: 10000)
    private let minZoom: CGFloat = 0.25
    private let maxZoom: CGFloat = 4.0
    
    // Performance optimization
    private var visibleNodes: Set<UUID> = []
    private var lastUpdateTime: TimeInterval = 0
    
    // Drift mode
    private var isDriftModeEnabled = false
    private var driftActions: [UUID: SKAction] = [:]
    
    // Advanced Animation System - MVP1c
    @MainActor
    private let animationSystem = AdvancedAnimationSystem()
    
    // Drift Mode Service - MVP1c
    @MainActor
    private let driftModeService = DriftModeService()
    
    override func didMove(to view: SKView) {
        setupScene()
        setupCamera()
        setupGrid()
        setupGestures()
        // use SpriteKit update loop instead of Timer-based loop
    }
    
    // MARK: - Scene Setup
    
    private func setupScene() {
        backgroundColor = .systemBackground
        
        // Enable multisampling for smoother edges
        view?.preferredFramesPerSecond = 60
        view?.ignoresSiblingOrder = true
        view?.showsFPS = false
        view?.showsNodeCount = false
        
        #if DEBUG
        view?.showsFPS = true
        view?.showsNodeCount = true
        view?.showsPhysics = false
        #endif
    }
    
    private func setupCamera() {
        cameraNode = SKCameraNode()
        camera = cameraNode
        addChild(cameraNode)
        
        // Set initial camera position
        cameraNode.position = CGPoint.zero
        cameraNode.setScale(1.0)
    }
    
    private func setupGrid() {
        gridNode = GridNode(size: canvasBounds.size)
        gridNode.position = CGPoint.zero
        gridNode.zPosition = -100
        addChild(gridNode)
    }
    
    private func setupGestures() {
        guard let view = view else { return }
        
        // Create gesture coordinator
        let coordinator = CanvasGestureCoordinator()
        coordinator.canvasViewModel = canvasViewModel
        coordinator.interactionService = interactionService
        self.gestureCoordinator = coordinator
        
        // Remove existing gesture recognizers
        view.gestureRecognizers?.forEach { view.removeGestureRecognizer($0) }
        
        // Add new gesture recognizers
        setupGestureRecognizers(view: view, coordinator: coordinator)
    }
    
    private func setupGestureRecognizers(view: SKView, coordinator: CanvasGestureCoordinator) {
        // Pan gesture for canvas and node dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = coordinator
        view.addGestureRecognizer(panGesture)
        
        // Long press for creating nodes
        let longPressGesture = UILongPressGestureRecognizer(
            target: coordinator,
            action: #selector(CanvasGestureCoordinator.handleLongPress(_:))
        )
        longPressGesture.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPressGesture)
        
        // Tap for selection
        let tapGesture = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(CanvasGestureCoordinator.handleTap(_:))
        )
        view.addGestureRecognizer(tapGesture)
        
        // Double tap for quick creation
        let doubleTapGesture = UITapGestureRecognizer(
            target: coordinator,
            action: #selector(CanvasGestureCoordinator.handleDoubleTap(_:))
        )
        doubleTapGesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTapGesture)
        
        // Require single tap to fail before recognizing double tap
        tapGesture.require(toFail: doubleTapGesture)
        
        // Pinch for zooming
        let pinchGesture = UIPinchGestureRecognizer(
            target: coordinator,
            action: #selector(CanvasGestureCoordinator.handlePinch(_:))
        )
        pinchGesture.delegate = coordinator
        view.addGestureRecognizer(pinchGesture)
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        // Throttle heavy updates to ~10 FPS to reduce cost
        let delta = currentTime - lastUpdateTime
        if delta >= (1.0 / 10.0) {
            lastUpdateTime = currentTime
            updateVisibleNodes()
        }
    }
    
    private func updateVisibleNodes() {
        guard let camera = camera else { return }
        
        // Calculate visible rect
        let cameraRect = CGRect(
            origin: CGPoint(
                x: camera.position.x - size.width / 2 / camera.xScale,
                y: camera.position.y - size.height / 2 / camera.yScale
            ),
            size: CGSize(
                width: size.width / camera.xScale,
                height: size.height / camera.yScale
            )
        )
        
        // Expand rect for buffer
        let bufferRect = cameraRect.insetBy(dx: -100, dy: -100)
        
        // Update visibility
        for (id, sprite) in nodeSprites {
            let isVisible = bufferRect.contains(sprite.position)
            
            if isVisible && !visibleNodes.contains(id) {
                // Node became visible
                visibleNodes.insert(id)
                sprite.isHidden = false
            } else if !isVisible && visibleNodes.contains(id) {
                // Node became invisible
                visibleNodes.remove(id)
                sprite.isHidden = true
            }
        }
    }
    
    // MARK: - Node Management
    
    func addNodeSprite(for node: ThoughtNode) {
        let sprite = EnhancedNodeSprite(node: node)
        nodeSprites[node.id] = sprite
        addChild(sprite)
        
        // Animate creation
        sprite.animateCreation()
        
        // Update visible nodes
        updateVisibleNodes()
    }
    
    func removeNodeSprite(nodeId: UUID) {
        guard let sprite = nodeSprites[nodeId] else { return }
        
        sprite.animateDeletion {
            self.nodeSprites.removeValue(forKey: nodeId)
            self.visibleNodes.remove(nodeId)
        }
    }
    
    func updateNodeSprite(for node: ThoughtNode) {
        nodeSprites[node.id]?.updateContent(node)
    }
    
    func focusOnNode(nodeId: UUID) {
        guard let nodeSprite = nodeSprites[nodeId] else { return }
        
        // Animate camera to center on node
        let moveAction = SKAction.move(to: nodeSprite.position, duration: 0.5)
        moveAction.timingMode = .easeInEaseOut
        
        camera?.run(moveAction) { [weak self] in
            // Select the node after camera movement
            self?.selectNode(nodeId)
        }
    }
    
    func selectNode(_ nodeId: UUID) {
        // Deselect previous nodes
        for id in selectedNodes {
            nodeSprites[id]?.animateDeselection()
        }
        
        selectedNodes.removeAll()
        
        // Select new node
        if let sprite = nodeSprites[nodeId] {
            selectedNodes.insert(nodeId)
            sprite.animateSelection()
            
            // Center camera on node with animation
            centerCamera(on: sprite.position, animated: true)
        }
    }
    
    func deselectAllNodes() {
        for id in selectedNodes {
            nodeSprites[id]?.animateDeselection()
        }
        selectedNodes.removeAll()
    }
    
    // MARK: - Camera Controls
    
    func centerCamera(on point: CGPoint, animated: Bool = true) {
        guard let camera = camera else { return }
        
        if animated {
            let moveAction = SKAction.move(to: point, duration: 0.3)
            moveAction.timingMode = .easeInEaseOut
            camera.run(moveAction)
        } else {
            camera.position = point
        }
    }
    
    func zoomCamera(to scale: CGFloat, animated: Bool = true) {
        guard let camera = camera else { return }
        
        let clampedScale = max(minZoom, min(maxZoom, scale))
        
        if animated {
            let scaleAction = SKAction.scale(to: clampedScale, duration: 0.3)
            scaleAction.timingMode = .easeInEaseOut
            camera.run(scaleAction)
        } else {
            camera.setScale(clampedScale)
        }
        
        // Update grid based on zoom level
        gridNode.updateGridScale(clampedScale)
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = view, let camera = camera else { return }
        
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            // Check if we're dragging a node
            let location = gesture.location(in: view)
            let sceneLocation = convertPoint(fromView: location)
            let touchedNodes = nodes(at: sceneLocation)
            
            if let nodeSprite = touchedNodes.first(where: { $0 is EnhancedNodeSprite }) as? EnhancedNodeSprite {
                isDragging = true
                nodeSprite.animateDrag(isDragging: true)
            } else {
                isDragging = false
            }
            
        case .changed:
            if isDragging {
                // Move selected nodes
                let sceneDelta = CGPoint(
                    x: translation.x / camera.xScale,
                    y: -translation.y / camera.yScale
                )
                
                for nodeId in selectedNodes {
                    if let sprite = nodeSprites[nodeId] {
                        let newPosition = CGPoint(
                            x: sprite.thoughtNode.position.x + sceneDelta.x,
                            y: sprite.thoughtNode.position.y + sceneDelta.y
                        )
                        
                        // Update sprite position immediately
                        sprite.position = newPosition
                        
                        // Update data model
                        canvasViewModel?.updateNodePosition(
                            nodeId,
                            position: Position(x: newPosition.x, y: newPosition.y)
                        )
                        
                        // 通知漂移模式服务节点位置变化
                        NotificationCenter.default.post(
                            name: .nodePositionChanged,
                            object: ["nodeId": nodeId, "position": newPosition]
                        )
                    }
                }
            } else {
                // Pan camera
                let delta = CGPoint(
                    x: -translation.x / camera.xScale,
                    y: translation.y / camera.yScale
                )
                
                var newPosition = CGPoint(
                    x: camera.position.x + delta.x,
                    y: camera.position.y + delta.y
                )
                
                // Soft bounds
                newPosition.x = max(canvasBounds.minX, min(canvasBounds.maxX, newPosition.x))
                newPosition.y = max(canvasBounds.minY, min(canvasBounds.maxY, newPosition.y))
                
                camera.position = newPosition
            }
            
            gesture.setTranslation(.zero, in: view)
            
        case .ended:
            if isDragging {
                // End drag
                for nodeId in selectedNodes {
                    nodeSprites[nodeId]?.animateDrag(isDragging: false)
                }
            } else {
                // Inertial scrolling
                let decelerationRate: CGFloat = 0.95
                let threshold: CGFloat = 5.0
                
                if abs(velocity.x) > threshold || abs(velocity.y) > threshold {
                    applyInertia(velocity: velocity, decelerationRate: decelerationRate)
                }
            }
            
            isDragging = false
            
        default:
            break
        }
    }
    
    private func applyInertia(velocity: CGPoint, decelerationRate: CGFloat) {
        guard let camera = camera else { return }
        
        let delta = CGPoint(
            x: -velocity.x * 0.1 / camera.xScale,
            y: velocity.y * 0.1 / camera.yScale
        )
        
        let distance = hypot(delta.x, delta.y)
        let duration = TimeInterval(log(0.01) / log(decelerationRate) * 0.016)
        
        let moveAction = SKAction.moveBy(x: delta.x, y: delta.y, duration: duration)
        moveAction.timingMode = .easeOut
        
        camera.run(moveAction, withKey: "inertia")
    }
    
    // MARK: - Drift Mode (Incubation)
    
    func enableDriftMode(_ enabled: Bool) {
        isDriftModeEnabled = enabled
        
        if enabled {
            // 使用新的DriftModeService
            driftModeService.activateDriftMode(in: self, animationSystem: animationSystem)
        } else {
            driftModeService.deactivateDriftMode()
        }
    }
    
    /// 激活缪斯模式 - MVP1c新增功能
    func enableMuseMode(_ enabled: Bool) {
        if enabled {
            driftModeService.activateMuseMode()
        } else {
            driftModeService.deactivateMuseMode()
        }
    }
    
    private func startNodeDrift() {
        nodeSprites.forEach { nodeId, sprite in
            // Create random drift action for each node
            let driftAction = createDriftAction()
            sprite.run(SKAction.repeatForever(driftAction), withKey: "drift")
            driftActions[nodeId] = driftAction
        }
    }
    
    private func stopNodeDrift() {
        nodeSprites.forEach { _, sprite in
            sprite.removeAction(forKey: "drift")
        }
        driftActions.removeAll()
    }
    
    private func createDriftAction() -> SKAction {
        // Create a sequence of random movements
        var actions: [SKAction] = []
        
        for _ in 0..<4 {
            let dx = CGFloat.random(in: -30...30)
            let dy = CGFloat.random(in: -30...30)
            let duration = TimeInterval.random(in: 3...6)
            
            let moveAction = SKAction.moveBy(x: dx, y: dy, duration: duration)
            moveAction.timingMode = .easeInEaseOut
            actions.append(moveAction)
            
            // Add a small pause between movements
            let waitAction = SKAction.wait(forDuration: TimeInterval.random(in: 0.5...1.5))
            actions.append(waitAction)
        }
        
        return SKAction.sequence(actions)
    }
}

// MARK: - Grid Node
class GridNode: SKNode {
    private var gridLines: [SKShapeNode] = []
    private let baseGridSize: CGFloat = 50
    private var currentGridSize: CGFloat = 50
    
    init(size: CGSize) {
        super.init()
        createGrid(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createGrid(size: CGSize) {
        let gridColor = UIColor.systemGray.withAlphaComponent(0.1)
        let majorGridColor = UIColor.systemGray.withAlphaComponent(0.2)
        
        // Create grid lines
        let gridSpacing = baseGridSize
        let majorGridInterval = 5
        
        // Vertical lines
        for i in stride(from: -size.width/2, through: size.width/2, by: gridSpacing) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: i, y: -size.height/2))
            path.addLine(to: CGPoint(x: i, y: size.height/2))
            line.path = path
            
            let isMajor = Int(i / gridSpacing) % majorGridInterval == 0
            line.strokeColor = isMajor ? majorGridColor : gridColor
            line.lineWidth = isMajor ? 1.5 : 1.0
            
            addChild(line)
            gridLines.append(line)
        }
        
        // Horizontal lines
        for i in stride(from: -size.height/2, through: size.height/2, by: gridSpacing) {
            let line = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -size.width/2, y: i))
            path.addLine(to: CGPoint(x: size.width/2, y: i))
            line.path = path
            
            let isMajor = Int(i / gridSpacing) % majorGridInterval == 0
            line.strokeColor = isMajor ? majorGridColor : gridColor
            line.lineWidth = isMajor ? 1.5 : 1.0
            
            addChild(line)
            gridLines.append(line)
        }
    }
    
    func updateGridScale(_ cameraScale: CGFloat) {
        // Adjust grid opacity based on zoom level
        let opacity = min(1.0, max(0.1, 1.0 - (cameraScale - 1.0) * 0.3))
        alpha = opacity
        
        // Hide grid when zoomed out too much
        isHidden = cameraScale < 0.5
    }
}

// MARK: - Minimap Node
class MinimapNode: SKNode {
    private let mapSize = CGSize(width: 150, height: 100)
    private let background: SKShapeNode
    private let viewport: SKShapeNode
    private var nodeDots: [UUID: SKShapeNode] = [:]
    
    override init() {
        // Background
        background = SKShapeNode(rectOf: mapSize, cornerRadius: 8)
        background.fillColor = UIColor.systemBackground.withAlphaComponent(0.9)
        background.strokeColor = UIColor.systemGray
        background.lineWidth = 1
        
        // Viewport indicator
        viewport = SKShapeNode(rectOf: CGSize(width: 30, height: 20))
        viewport.fillColor = .clear
        viewport.strokeColor = .systemBlue
        viewport.lineWidth = 2
        
        super.init()
        
        addChild(background)
        addChild(viewport)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateMinimap(nodes: [UUID: EnhancedNodeSprite], camera: SKCameraNode, canvasSize: CGSize) {
        // Update node dots
        // ... implementation
    }
}