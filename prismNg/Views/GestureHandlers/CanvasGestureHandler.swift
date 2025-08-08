//
//  CanvasGestureHandler.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import UIKit

// MARK: - Canvas Gesture Coordinator
@MainActor
class CanvasGestureCoordinator: NSObject {
    weak var canvasViewModel: CanvasViewModel?
    weak var interactionService: InteractionPreferenceService?
    
    private var currentGestureStartTime: Date?
    private var radialMenuLocation: CGPoint?
    private var isShowingRadialMenu = false
    
    // MARK: - Gesture Handlers
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let view = gesture.view,
              let canvasVM = canvasViewModel,
              let interactionService = interactionService else { return }
        
        let location = gesture.location(in: view)
        
        switch gesture.state {
        case .began:
            currentGestureStartTime = Date()
            
            // Check interaction mode
            if canvasVM.interactionService.currentPreference == .traditional {
                // In traditional mode, long press might show context menu
                showContextMenu(at: location)
            } else {
                // In gesture/adaptive mode, show radial menu
                showRadialMenu(at: location)
            }
            
            // Haptic feedback
            provideHapticFeedback(.medium)
            
        case .changed:
            if isShowingRadialMenu {
                updateRadialMenuSelection(at: location)
            }
            
        case .ended:
            let duration = Date().timeIntervalSince(currentGestureStartTime ?? Date())
            
            if isShowingRadialMenu {
                executeRadialMenuSelection(at: location)
                hideRadialMenu()
            }
            
            // Track interaction
            interactionService.trackGestureInteraction(
                type: .longPress,
                success: true,
                duration: duration
            )
            
        case .cancelled, .failed:
            hideRadialMenu()
            
        default:
            break
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let canvasVM = canvasViewModel else { return }
        
        let location = gesture.location(in: view)
        let startTime = Date()
        
        // Convert to scene coordinates
        if let scene = canvasVM.scene {
            let sceneLocation = scene.convertPoint(fromView: location)
            
            // Check if tapping on a node
            let touchedNodes = scene.nodes(at: sceneLocation)
            if let nodeSprite = touchedNodes.first(where: { $0 is EnhancedNodeSprite }) as? EnhancedNodeSprite {
                canvasVM.selectNode(nodeSprite.nodeId)
                
                // Check for double tap
                let currentTime = CACurrentMediaTime()
                if let lastTap = nodeSprite.lastTapTime,
                   currentTime - lastTap < 0.5 {
                    canvasVM.editNode(nodeSprite.nodeId)
                }
                nodeSprite.lastTapTime = currentTime
            } else {
                canvasVM.deselectAllNodes()
            }
        }
        
        // Track interaction
        let duration = Date().timeIntervalSince(startTime)
        canvasVM.interactionService.trackGestureInteraction(
            type: .doubleTap,
            success: true,
            duration: duration
        )
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view,
              let canvasVM = canvasViewModel else { return }
        
        // Implementation handled in CanvasScene
        // Track as drag gesture
        if gesture.state == .ended {
            canvasVM.interactionService.trackGestureInteraction(
                type: .drag,
                success: true,
                duration: 0
            )
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let canvasVM = canvasViewModel,
              let scene = canvasVM.scene,
              let camera = scene.camera else { return }
        
        switch gesture.state {
        case .changed:
            // Zoom camera based on pinch scale
            let newScale = camera.xScale / gesture.scale
            let clampedScale = max(0.5, min(2.0, newScale))
            camera.setScale(clampedScale)
            gesture.scale = 1.0
            
        case .ended:
            // Track interaction
            canvasVM.interactionService.trackGestureInteraction(
                type: .pinch,
                success: true,
                duration: 0
            )
            
        default:
            break
        }
    }
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let canvasVM = canvasViewModel else { return }
        
        let location = gesture.location(in: view)
        
        // Quick create node at tap location
        if canvasVM.interactionService.currentPreference != .traditional {
            if let scene = canvasVM.scene {
                let sceneLocation = scene.convertPoint(fromView: location)
                canvasVM.createNode(
                    content: "",
                    type: .thought,
                    position: Position(x: sceneLocation.x, y: sceneLocation.y)
                )
                
                // Track interaction
                canvasVM.interactionService.trackGestureInteraction(
                    type: .doubleTap,
                    success: true,
                    duration: 0
                )
            }
        }
    }
    
    // MARK: - Radial Menu
    
    private func showRadialMenu(at location: CGPoint) {
        radialMenuLocation = location
        isShowingRadialMenu = true
        
        // Notify view model to show radial menu UI
        canvasViewModel?.showRadialMenu(at: location)
    }
    
    private func updateRadialMenuSelection(at location: CGPoint) {
        guard let menuLocation = radialMenuLocation else { return }
        
        // Calculate angle from menu center to current touch
        let angle = atan2(location.y - menuLocation.y, location.x - menuLocation.x)
        
        // Update selection in view model
        canvasViewModel?.updateRadialMenuSelection(angle: angle)
    }
    
    private func executeRadialMenuSelection(at location: CGPoint) {
        guard let menuLocation = radialMenuLocation else { return }
        
        // Calculate final selection
        let angle = atan2(location.y - menuLocation.y, location.x - menuLocation.x)
        let distance = hypot(location.x - menuLocation.x, location.y - menuLocation.y)
        
        // Only execute if dragged far enough
        if distance > 30 {
            canvasViewModel?.executeRadialMenuSelection(angle: angle)
        }
    }
    
    private func hideRadialMenu() {
        isShowingRadialMenu = false
        radialMenuLocation = nil
        canvasViewModel?.hideRadialMenu()
    }
    
    private func showContextMenu(at location: CGPoint) {
        // Show traditional context menu for traditional mode
        canvasViewModel?.showContextMenu(at: location)
    }
    
    // MARK: - Haptic Feedback
    
    private func provideHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

// MARK: - Gesture Delegate
extension CanvasGestureCoordinator: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow simultaneous recognition for pinch and pan
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIPanGestureRecognizer {
            return true
        }
        if gestureRecognizer is UIPanGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer {
            return true
        }
        return false
    }
}