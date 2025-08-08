//
//  InteractionOnboardingView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI

// MARK: - Interaction Mode Onboarding
struct InteractionOnboardingView: View {
    @ObservedObject var preferenceService: InteractionPreferenceService
    @Binding var isPresented: Bool
    
    @State private var selectedMode: InteractionMode?
    @State private var currentStep = 0
    @State private var showDemoAnimation = false
    
    private let options = InteractionModeOption.allOptions
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressIndicator(currentStep: currentStep, totalSteps: 3)
                    .padding(.top)
                
                // Content area
                TabView(selection: $currentStep) {
                    // Welcome step
                    WelcomeStepView()
                        .tag(0)
                    
                    // Mode selection step
                    ModeSelectionStepView(
                        options: options,
                        selectedMode: $selectedMode,
                        showDemoAnimation: $showDemoAnimation
                    )
                    .tag(1)
                    
                    // Confirmation step
                    ConfirmationStepView(
                        selectedMode: selectedMode,
                        onComplete: {
                            if let mode = selectedMode {
                                preferenceService.completeOnboarding(selectedMode: mode)
                                isPresented = false
                            }
                        }
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Navigation controls
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation(.easeInOut) {
                                currentStep -= 1
                            }
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    if currentStep < 2 {
                        Button("Next") {
                            withAnimation(.easeInOut) {
                                currentStep += 1
                            }
                        }
                        .disabled(currentStep == 1 && selectedMode == nil)
                        .foregroundColor(canProceed ? .blue : .gray)
                    }
                }
                .padding()
            }
            .navigationTitle("Setup Your Interaction Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        preferenceService.completeOnboarding(selectedMode: .traditional)
                        isPresented = false
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .interactiveDismissDisabled()
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1: return selectedMode != nil
        case 2: return true
        default: return false
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            // Title
            Text("Welcome to PrismNg")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Description
            VStack(spacing: 16) {
                Text("PrismNg adapts to how you think and work.")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                
                Text("Let's set up your preferred interaction style for the best experience.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Feature highlights
            VStack(alignment: .leading, spacing: 12) {
                FeatureHighlight(icon: "brain.head.profile", text: "AI-powered thought connections")
                FeatureHighlight(icon: "hand.draw", text: "Intuitive gesture controls")
                FeatureHighlight(icon: "sparkles", text: "Adaptive interface")
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct FeatureHighlight: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Mode Selection Step
struct ModeSelectionStepView: View {
    let options: [InteractionModeOption]
    @Binding var selectedMode: InteractionMode?
    @Binding var showDemoAnimation: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            VStack(spacing: 8) {
                Text("Choose Your Interaction Style")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("You can change this later in settings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            // Mode options
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(options, id: \.mode) { option in
                        InteractionModeCard(
                            option: option,
                            isSelected: selectedMode == option.mode,
                            onSelect: {
                                selectedMode = option.mode
                                triggerDemoAnimation()
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Demo area
            if let selectedMode = selectedMode {
                DemoAnimationView(mode: selectedMode, isAnimating: showDemoAnimation)
                    .frame(height: 100)
                    .padding()
            }
        }
    }
    
    private func triggerDemoAnimation() {
        showDemoAnimation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showDemoAnimation = false
        }
    }
}

// MARK: - Interaction Mode Card
struct InteractionModeCard: View {
    let option: InteractionModeOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: option.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : .blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.title)
                            .font(.headline)
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        Text(option.description)
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
                
                // Demo actions
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(option.demoActions.enumerated()), id: \.offset) { index, action in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(isSelected ? .white.opacity(0.6) : .blue.opacity(0.6))
                                .frame(width: 4, height: 4)
                            
                            Text(action)
                                .font(.caption)
                                .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .blue : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Demo Animation View
struct DemoAnimationView: View {
    let mode: InteractionMode
    let isAnimating: Bool
    
    @State private var animationOffset: CGFloat = 0
    @State private var animationOpacity: Double = 0
    
    var body: some View {
        HStack {
            Spacer()
            
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: 200, height: 80)
                
                // Demo content based on mode
                Group {
                    switch mode {
                    case .traditional:
                        traditionalModeDemo
                    case .gesture:
                        gestureModeDemo
                    case .adaptive:
                        adaptiveModeDemo
                    }
                }
                .opacity(animationOpacity)
                .offset(x: animationOffset)
            }
            
            Spacer()
        }
        .onChange(of: isAnimating) { _, newValue in
            if newValue {
                performAnimation()
            }
        }
    }
    
    private var traditionalModeDemo: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue)
                        .frame(width: 40, height: 20)
                }
            }
            Text("Button Interface")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var gestureModeDemo: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.blue, lineWidth: 2)
                    .frame(width: 30, height: 30)
                
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
            }
            Text("Touch & Hold")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private var adaptiveModeDemo: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "hand.tap")
                    .font(.caption)
                Image(systemName: "arrow.right")
                    .font(.caption2)
                Image(systemName: "hand.draw")
                    .font(.caption)
            }
            .foregroundColor(.blue)
            
            Text("Smart Switching")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func performAnimation() {
        withAnimation(.easeInOut(duration: 0.6)) {
            animationOpacity = 1.0
            animationOffset = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                animationOpacity = 0.7
            }
        }
    }
}

// MARK: - Confirmation Step
struct ConfirmationStepView: View {
    let selectedMode: InteractionMode?
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            // Title
            Text("Perfect!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Selected mode summary
            if let mode = selectedMode,
               let option = InteractionModeOption.allOptions.first(where: { $0.mode == mode }) {
                VStack(spacing: 12) {
                    Text("You've selected \(option.title)")
                        .font(.title3)
                        .multilineTextAlignment(.center)
                    
                    Text(option.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            // Complete button
            Button(action: onComplete) {
                Text("Start Thinking")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            // Additional info
            Text("You can change your interaction preference anytime in Settings.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - Progress Indicator
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? .blue : Color(.systemGray4))
                    .frame(width: 8, height: 8)
                    .scaleEffect(step == currentStep ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
        }
        .padding()
    }
}

#Preview {
    InteractionOnboardingView(
        preferenceService: InteractionPreferenceService(),
        isPresented: .constant(true)
    )
}