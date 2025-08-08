//
//  GestureTutorialView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI

// MARK: - Gesture Tutorial View
struct GestureTutorialView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    @State private var hasCompletedStep = false
    @State private var showSuccess = false
    
    private let tutorialSteps: [GestureTutorialStep] = [
        GestureTutorialStep(
            id: "longpress",
            title: "长按创建",
            description: "在画布上长按任意位置创建新想法",
            icon: "hand.point.up.left",
            gesture: .longPress,
            successMessage: "太棒了！你已经掌握了创建节点"
        ),
        GestureTutorialStep(
            id: "drag",
            title: "拖动移动",
            description: "按住节点并拖动来重新排列",
            icon: "hand.draw",
            gesture: .drag,
            successMessage: "完美！你可以自由移动想法了"
        ),
        GestureTutorialStep(
            id: "pinch",
            title: "缩放画布",
            description: "双指捏合来缩放视图",
            icon: "arrow.up.left.and.arrow.down.right",
            gesture: .pinch,
            successMessage: "很好！你已经掌握了画布导航"
        ),
        GestureTutorialStep(
            id: "doubletap",
            title: "双击编辑",
            description: "双击节点进入编辑模式",
            icon: "hand.tap",
            gesture: .doubleTap,
            successMessage: "excellent！你已经是手势大师了"
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                ProgressBar(
                    progress: Double(currentStep) / Double(tutorialSteps.count),
                    color: .blue
                )
                .frame(height: 6)
                
                // Tutorial Content
                if currentStep < tutorialSteps.count {
                    GestureTutorialStepView(
                        step: tutorialSteps[currentStep],
                        hasCompleted: $hasCompletedStep,
                        showSuccess: $showSuccess,
                        onComplete: {
                            moveToNextStep()
                        }
                    )
                } else {
                    CompletionView(onDismiss: {
                        isPresented = false
                    })
                }
            }
            .navigationTitle("手势教程")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("跳过") {
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private func moveToNextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
            hasCompletedStep = false
            showSuccess = false
        }
    }
}

// MARK: - Tutorial Step View
struct GestureTutorialStepView: View {
    let step: GestureTutorialStep
    @Binding var hasCompleted: Bool
    @Binding var showSuccess: Bool
    let onComplete: () -> Void
    
    @State private var showHint = false
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 30) {
            // Step Info
            VStack(spacing: 16) {
                Image(systemName: step.icon)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .symbolEffect(.bounce, value: showHint)
                
                Text(step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(step.description)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 40)
            
            // Practice Area
            GesturePracticeView(
                gestureType: step.gesture,
                onSuccess: {
                    handleSuccess()
                }
            )
            .frame(height: 300)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(hasCompleted ? Color.green : Color.blue.opacity(0.3), lineWidth: 2)
            )
            .padding(.horizontal)
            
            // Success Message
            if showSuccess {
                SuccessMessageView(message: step.successMessage)
                    .transition(.scale.combined(with: .opacity))
            }
            
            Spacer()
            
            // Continue Button
            if hasCompleted {
                Button(action: onComplete) {
                    Label("继续", systemImage: "arrow.right")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 20)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showHint = true
            }
        }
    }
    
    private func handleSuccess() {
        guard !hasCompleted else { return }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            hasCompleted = true
            showSuccess = true
        }
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Gesture Practice View
struct GesturePracticeView: UIViewRepresentable {
    let gestureType: GestureType
    let onSuccess: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // Add visual hints
        let hintLayer = CALayer()
        hintLayer.frame = view.bounds
        view.layer.addSublayer(hintLayer)
        
        context.coordinator.setupHintAnimation(for: hintLayer, gestureType: gestureType)
        
        // Add gesture recognizers
        switch gestureType {
        case .longPress:
            let longPress = UILongPressGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleLongPress(_:))
            )
            longPress.minimumPressDuration = 0.5
            view.addGestureRecognizer(longPress)
            
        case .drag:
            let pan = UIPanGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePan(_:))
            )
            view.addGestureRecognizer(pan)
            
        case .pinch:
            let pinch = UIPinchGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handlePinch(_:))
            )
            view.addGestureRecognizer(pinch)
            
        case .doubleTap:
            let doubleTap = UITapGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleDoubleTap(_:))
            )
            doubleTap.numberOfTapsRequired = 2
            view.addGestureRecognizer(doubleTap)
            
        case .swipe:
            let swipe = UISwipeGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleSwipe(_:))
            )
            view.addGestureRecognizer(swipe)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onSuccess: onSuccess)
    }
    
    class Coordinator: NSObject {
        let onSuccess: () -> Void
        private var hasTriggered = false
        
        init(onSuccess: @escaping () -> Void) {
            self.onSuccess = onSuccess
        }
        
        func setupHintAnimation(for layer: CALayer, gestureType: GestureType) {
            // Create hint animations based on gesture type
            switch gestureType {
            case .longPress:
                createLongPressHint(on: layer)
            case .drag:
                createDragHint(on: layer)
            case .pinch:
                createPinchHint(on: layer)
            case .doubleTap:
                createDoubleTapHint(on: layer)
            case .swipe:
                createSwipeHint(on: layer)
            }
        }
        
        private func createLongPressHint(on layer: CALayer) {
            let circle = CAShapeLayer()
            circle.path = UIBezierPath(ovalIn: CGRect(x: 100, y: 100, width: 60, height: 60)).cgPath
            circle.fillColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
            circle.strokeColor = UIColor.systemBlue.cgColor
            circle.lineWidth = 2
            
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = 1.0
            scaleAnimation.toValue = 1.2
            scaleAnimation.duration = 1.5
            scaleAnimation.repeatCount = .infinity
            scaleAnimation.autoreverses = true
            
            circle.add(scaleAnimation, forKey: "scale")
            layer.addSublayer(circle)
        }
        
        private func createDragHint(on layer: CALayer) {
            // Create drag path hint
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 50, y: 150))
            path.addCurve(
                to: CGPoint(x: 250, y: 150),
                controlPoint1: CGPoint(x: 100, y: 100),
                controlPoint2: CGPoint(x: 200, y: 200)
            )
            
            let pathLayer = CAShapeLayer()
            pathLayer.path = path.cgPath
            pathLayer.strokeColor = UIColor.systemBlue.cgColor
            pathLayer.fillColor = UIColor.clear.cgColor
            pathLayer.lineWidth = 3
            pathLayer.lineDashPattern = [10, 5]
            
            let dashAnimation = CABasicAnimation(keyPath: "lineDashPhase")
            dashAnimation.fromValue = 0
            dashAnimation.toValue = 15
            dashAnimation.duration = 1.0
            dashAnimation.repeatCount = .infinity
            
            pathLayer.add(dashAnimation, forKey: "dash")
            layer.addSublayer(pathLayer)
        }
        
        private func createPinchHint(on layer: CALayer) {
            // Two circles moving apart
            let circle1 = createCircle(at: CGPoint(x: 100, y: 150))
            let circle2 = createCircle(at: CGPoint(x: 200, y: 150))
            
            layer.addSublayer(circle1)
            layer.addSublayer(circle2)
        }
        
        private func createDoubleTapHint(on layer: CALayer) {
            let tapPoint = CGPoint(x: 150, y: 150)
            
            for i in 0..<2 {
                let circle = CAShapeLayer()
                circle.path = UIBezierPath(ovalIn: CGRect(x: tapPoint.x - 30, y: tapPoint.y - 30, width: 60, height: 60)).cgPath
                circle.fillColor = UIColor.clear.cgColor
                circle.strokeColor = UIColor.systemBlue.cgColor
                circle.lineWidth = 2
                circle.opacity = 0
                
                let fadeAnimation = CABasicAnimation(keyPath: "opacity")
                fadeAnimation.fromValue = 1.0
                fadeAnimation.toValue = 0.0
                fadeAnimation.duration = 0.6
                fadeAnimation.beginTime = CACurrentMediaTime() + Double(i) * 0.3
                fadeAnimation.repeatCount = .infinity
                // Use a delay between animations by adding to beginTime
                
                circle.add(fadeAnimation, forKey: "fade")
                layer.addSublayer(circle)
            }
        }
        
        private func createSwipeHint(on layer: CALayer) {
            // Create swipe arrow
            let arrow = CAShapeLayer()
            let path = UIBezierPath()
            path.move(to: CGPoint(x: 50, y: 150))
            path.addLine(to: CGPoint(x: 250, y: 150))
            path.move(to: CGPoint(x: 230, y: 130))
            path.addLine(to: CGPoint(x: 250, y: 150))
            path.addLine(to: CGPoint(x: 230, y: 170))
            
            arrow.path = path.cgPath
            arrow.strokeColor = UIColor.systemBlue.cgColor
            arrow.lineWidth = 3
            arrow.lineCap = .round
            arrow.lineJoin = .round
            
            layer.addSublayer(arrow)
        }
        
        private func createCircle(at point: CGPoint) -> CAShapeLayer {
            let circle = CAShapeLayer()
            circle.path = UIBezierPath(ovalIn: CGRect(x: point.x - 15, y: point.y - 15, width: 30, height: 30)).cgPath
            circle.fillColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
            circle.strokeColor = UIColor.systemBlue.cgColor
            circle.lineWidth = 2
            return circle
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began && !hasTriggered {
                hasTriggered = true
                onSuccess()
            }
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .changed {
                let translation = gesture.translation(in: gesture.view)
                if abs(translation.x) > 50 || abs(translation.y) > 50 {
                    if !hasTriggered {
                        hasTriggered = true
                        onSuccess()
                    }
                }
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            if gesture.state == .changed && abs(gesture.scale - 1.0) > 0.3 && !hasTriggered {
                hasTriggered = true
                onSuccess()
            }
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            if !hasTriggered {
                hasTriggered = true
                onSuccess()
            }
        }
        
        @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
            if !hasTriggered {
                hasTriggered = true
                onSuccess()
            }
        }
    }
}

// MARK: - Success Message View
struct SuccessMessageView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
}

// MARK: - Completion View
struct CompletionView: View {
    let onDismiss: () -> Void
    @State private var showConfetti = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Celebration Icon
            Image(systemName: "hands.clap")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .symbolEffect(.bounce, value: showConfetti)
            
            VStack(spacing: 16) {
                Text("恭喜完成！")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("你已经掌握了所有基本手势")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("现在可以流畅地使用 Prism 了")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Text("开始使用")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            showConfetti = true
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(color.opacity(0.2))
                
                Rectangle()
                    .fill(color)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
    }
}

// MARK: - Supporting Types
struct GestureTutorialStep {
    let id: String
    let title: String
    let description: String
    let icon: String
    let gesture: GestureType
    let successMessage: String
}

#Preview {
    GestureTutorialView(isPresented: .constant(true))
}