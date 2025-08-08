//
//  DualTrackWelcomeView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI

// MARK: - Dual-Track Welcome View
struct DualTrackWelcomeView: View {
    @Binding var isPresented: Bool
    @ObservedObject var interactionService: InteractionPreferenceService
    @State private var detectedPreference: InteractionMode?
    @State private var userChoice: InteractionMode?
    @State private var showDetectionAnimation = false
    @State private var detectionComplete = false
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Text("欢迎来到 Prism")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("让我们找到最适合你的交互方式")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Detection Area
                if !detectionComplete {
                    InteractionDetectionView(
                        detectedPreference: $detectedPreference,
                        showAnimation: $showDetectionAnimation,
                        onComplete: {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                detectionComplete = true
                            }
                        }
                    )
                } else {
                    // Choice Selection
                    PreferenceSelectionView(
                        detectedPreference: detectedPreference,
                        userChoice: $userChoice,
                        onConfirm: {
                            if let choice = userChoice {
                                interactionService.completeOnboarding(selectedMode: choice)
                                isPresented = false
                            }
                        }
                    )
                }
                
                Spacer()
                
                // Skip button
                if !detectionComplete {
                    Button("跳过检测，让我选择") {
                        withAnimation {
                            detectionComplete = true
                        }
                    }
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            startDetection()
        }
    }
    
    private func startDetection() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showDetectionAnimation = true
        }
    }
}

// MARK: - Interaction Detection View
struct InteractionDetectionView: View {
    @Binding var detectedPreference: InteractionMode?
    @Binding var showAnimation: Bool
    let onComplete: () -> Void
    
    @State private var tapCount = 0
    @State private var gestureCount = 0
    @State private var detectionTimer: Timer?
    @State private var showInstructions = true
    
    var body: some View {
        VStack(spacing: 30) {
            // Instructions
            if showInstructions {
                Text("请随意与屏幕交互")
                    .font(.headline)
                    .transition(.opacity)
            }
            
            // Detection Canvas
            DetectionCanvasView(
                onTap: {
                    tapCount += 1
                    checkDetection()
                },
                onLongPress: {
                    gestureCount += 1
                    checkDetection()
                },
                onSwipe: {
                    gestureCount += 1
                    checkDetection()
                }
            )
            .frame(height: 300)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
            
            // Detection Progress
            if showAnimation {
                HStack(spacing: 20) {
                    DetectionIndicator(
                        label: "点击",
                        count: tapCount,
                        icon: "hand.tap"
                    )
                    
                    DetectionIndicator(
                        label: "手势",
                        count: gestureCount,
                        icon: "hand.draw"
                    )
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            startDetectionTimer()
        }
    }
    
    private func startDetectionTimer() {
        detectionTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            completeDetection()
        }
    }
    
    private func checkDetection() {
        withAnimation(.easeOut(duration: 0.3)) {
            showInstructions = false
        }
        
        // Reset timer on each interaction
        detectionTimer?.invalidate()
        startDetectionTimer()
        
        // Early detection if clear preference
        if tapCount >= 3 && gestureCount == 0 {
            detectedPreference = .traditional
            completeDetection()
        } else if gestureCount >= 3 && tapCount == 0 {
            detectedPreference = .gesture
            completeDetection()
        } else if tapCount >= 2 && gestureCount >= 2 {
            detectedPreference = .adaptive
            completeDetection()
        }
    }
    
    private func completeDetection() {
        detectionTimer?.invalidate()
        
        // Final preference determination
        if detectedPreference == nil {
            if tapCount > gestureCount * 2 {
                detectedPreference = .traditional
            } else if gestureCount > tapCount * 2 {
                detectedPreference = .gesture
            } else {
                detectedPreference = .adaptive
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
}

// MARK: - Detection Canvas
struct DetectionCanvasView: UIViewRepresentable {
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onSwipe: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // Tap gesture
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        view.addGestureRecognizer(tapGesture)
        
        // Long press gesture
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        longPressGesture.minimumPressDuration = 0.5
        view.addGestureRecognizer(longPressGesture)
        
        // Swipe gestures
        let swipeUp = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSwipe))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        let parent: DetectionCanvasView
        
        init(_ parent: DetectionCanvasView) {
            self.parent = parent
        }
        
        @objc func handleTap() {
            parent.onTap()
            showRipple()
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                parent.onLongPress()
                showHoldAnimation()
            }
        }
        
        @objc func handleSwipe() {
            parent.onSwipe()
            showSwipeAnimation()
        }
        
        private func showRipple() {
            // Visual feedback for tap
        }
        
        private func showHoldAnimation() {
            // Visual feedback for long press
        }
        
        private func showSwipeAnimation() {
            // Visual feedback for swipe
        }
    }
}

// MARK: - Detection Indicator
struct DetectionIndicator: View {
    let label: String
    let count: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .scaleEffect(count > 0 ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)
    }
}

// MARK: - Preference Selection View
struct PreferenceSelectionView: View {
    let detectedPreference: InteractionMode?
    @Binding var userChoice: InteractionMode?
    let onConfirm: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Detection Result
            if let detected = detectedPreference {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    Text("我们检测到你可能更喜欢")
                        .font(.headline)
                    
                    Text(modeTitle(for: detected))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            
            // Mode Options
            VStack(spacing: 16) {
                ForEach(InteractionMode.allCases, id: \.self) { mode in
                    ModeOptionCard(
                        mode: mode,
                        isRecommended: mode == detectedPreference,
                        isSelected: mode == userChoice,
                        onSelect: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                userChoice = mode
                            }
                        }
                    )
                }
            }
            
            // Confirm Button
            Button(action: onConfirm) {
                Text("开始使用")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(userChoice != nil ? Color.blue : Color.gray)
                    )
            }
            .disabled(userChoice == nil)
        }
    }
    
    private func modeTitle(for mode: InteractionMode) -> String {
        switch mode {
        case .traditional:
            return "传统按钮控制"
        case .gesture:
            return "手势控制"
        case .adaptive:
            return "智能自适应模式"
        }
    }
}

// MARK: - Mode Option Card
struct ModeOptionCard: View {
    let mode: InteractionMode
    let isRecommended: Bool
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: modeIcon)
                            .font(.title3)
                            .foregroundColor(isSelected ? .white : .blue)
                        
                        Text(modeTitle)
                            .font(.headline)
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        if isRecommended {
                            Label("推荐", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(isSelected ? .white : .orange)
                        }
                    }
                    
                    Text(modeDescription)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isRecommended && !isSelected ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var modeIcon: String {
        switch mode {
        case .traditional:
            return "square.grid.2x2"
        case .gesture:
            return "hand.draw"
        case .adaptive:
            return "wand.and.rays"
        }
    }
    
    private var modeTitle: String {
        switch mode {
        case .traditional:
            return "传统模式"
        case .gesture:
            return "手势模式"
        case .adaptive:
            return "自适应模式"
        }
    }
    
    private var modeDescription: String {
        switch mode {
        case .traditional:
            return "使用熟悉的按钮和菜单，适合精确控制"
        case .gesture:
            return "直接触摸交互，流畅捕捉思想"
        case .adaptive:
            return "根据使用场景智能切换，享受两种模式的优势"
        }
    }
}

#Preview {
    DualTrackWelcomeView(
        isPresented: .constant(true),
        interactionService: InteractionPreferenceService()
    )
}