//
//  InteractionPreferenceService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Interaction Preference Detection Service
@MainActor
class InteractionPreferenceService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentPreference: InteractionMode = .traditional
    @Published var confidenceLevel: Float = 0.5
    @Published var showOnboarding: Bool = false
    @Published var adaptiveRecommendations: [InteractionRecommendation] = []
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private var userConfiguration: UserConfiguration?
    
    // Interaction tracking
    private var gestureInteractions: [InteractionEvent] = []
    private var traditionalUIInteractions: [InteractionEvent] = []
    private var sessionStartTime = Date()
    
    // Thresholds for preference detection
    private let confidenceThreshold: Float = 0.7
    private let adaptationPeriod: TimeInterval = 300 // 5 minutes
    private let minimumInteractionsForAnalysis = 5
    
    // MARK: - Setup
    func setup(modelContext: ModelContext, userConfiguration: UserConfiguration) {
        self.modelContext = modelContext
        self.userConfiguration = userConfiguration
        self.currentPreference = userConfiguration.interactionMode
        
        // Check if this is a new user
        if userConfiguration.createdAt.timeIntervalSinceNow > -60 { // Created less than 1 minute ago
            scheduleOnboarding()
        }
        
        // Start preference analysis
        startPreferenceAnalysis()
    }
    
    // MARK: - Onboarding
    private func scheduleOnboarding() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showOnboarding = true
        }
    }
    
    func completeOnboarding(selectedMode: InteractionMode) {
        currentPreference = selectedMode
        userConfiguration?.interactionMode = selectedMode
        
        if let modelContext = modelContext {
            try? modelContext.save()
        }
        
        showOnboarding = false
    }
    
    // MARK: - Interaction Tracking
    func trackInteraction(_ interaction: InteractionEvent) {
        switch interaction.type {
        case .gesture:
            gestureInteractions.append(interaction)
        case .traditionalUI:
            traditionalUIInteractions.append(interaction)
        }
        
        // Trigger analysis if we have enough data
        if getTotalInteractionCount() >= minimumInteractionsForAnalysis {
            analyzePreferences()
        }
    }
    
    func trackGestureInteraction(type: GestureType, success: Bool, duration: TimeInterval = 0) {
        let interaction = InteractionEvent(
            type: .gesture,
            gestureType: type,
            success: success,
            duration: duration,
            timestamp: Date()
        )
        trackInteraction(interaction)
    }
    
    func trackTraditionalUIInteraction(action: TraditionalUIAction, success: Bool, duration: TimeInterval = 0) {
        let interaction = InteractionEvent(
            type: .traditionalUI,
            uiAction: action,
            success: success,
            duration: duration,
            timestamp: Date()
        )
        trackInteraction(interaction)
    }
    
    // MARK: - Preference Analysis
    private func startPreferenceAnalysis() {
        // Periodically analyze preferences
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.analyzePreferences()
            }
        }
    }
    
    private func analyzePreferences() {
        let totalInteractions = getTotalInteractionCount()
        guard totalInteractions >= minimumInteractionsForAnalysis else { return }
        
        let gestureScore = calculateGesturePreferenceScore()
        let traditionalScore = calculateTraditionalUIPreferenceScore()
        
        // Determine preference based on scores
        let newPreference: InteractionMode
        let newConfidence: Float
        
        if abs(gestureScore - traditionalScore) < 0.2 {
            // Scores are close, recommend adaptive mode
            newPreference = .adaptive
            newConfidence = min(gestureScore, traditionalScore) + 0.2
        } else if gestureScore > traditionalScore {
            newPreference = .gesture
            newConfidence = gestureScore
        } else {
            newPreference = .traditional
            newConfidence = traditionalScore
        }
        
        // Update preference if confidence is high enough and different from current
        if newConfidence > confidenceThreshold && newPreference != currentPreference {
            updatePreference(to: newPreference, confidence: newConfidence)
        }
        
        // Generate recommendations
        generateAdaptiveRecommendations()
    }
    
    private func calculateGesturePreferenceScore() -> Float {
        guard !gestureInteractions.isEmpty else { return 0.0 }
        
        let recentInteractions = gestureInteractions.filter { 
            $0.timestamp.timeIntervalSinceNow > -adaptationPeriod 
        }
        
        guard !recentInteractions.isEmpty else { return 0.0 }
        
        // Success rate
        let successRate = Float(recentInteractions.filter { $0.success }.count) / Float(recentInteractions.count)
        
        // Average duration (shorter is better)
        let avgDuration = recentInteractions.reduce(0.0) { $0 + $1.duration } / Double(recentInteractions.count)
        let durationScore = max(0.0, 1.0 - Float(avgDuration / 5.0)) // Penalize if >5 seconds
        
        // Frequency score
        let frequency = Float(recentInteractions.count) / Float(getTotalRecentInteractionCount())
        
        // Gesture type diversity (more types used = higher comfort)
        let uniqueGestureTypes = Set(recentInteractions.compactMap { $0.gestureType }).count
        let diversityScore = min(1.0, Float(uniqueGestureTypes) / 4.0) // Max 4 gesture types
        
        // Weighted combination
        return (successRate * 0.4 + durationScore * 0.3 + frequency * 0.2 + diversityScore * 0.1)
    }
    
    private func calculateTraditionalUIPreferenceScore() -> Float {
        guard !traditionalUIInteractions.isEmpty else { return 0.0 }
        
        let recentInteractions = traditionalUIInteractions.filter { 
            $0.timestamp.timeIntervalSinceNow > -adaptationPeriod 
        }
        
        guard !recentInteractions.isEmpty else { return 0.0 }
        
        // Success rate
        let successRate = Float(recentInteractions.filter { $0.success }.count) / Float(recentInteractions.count)
        
        // Average duration
        let avgDuration = recentInteractions.reduce(0.0) { $0 + $1.duration } / Double(recentInteractions.count)
        let durationScore = max(0.0, 1.0 - Float(avgDuration / 3.0)) // Penalize if >3 seconds
        
        // Frequency score
        let frequency = Float(recentInteractions.count) / Float(getTotalRecentInteractionCount())
        
        // Action type diversity
        let uniqueActionTypes = Set(recentInteractions.compactMap { $0.uiAction }).count
        let diversityScore = min(1.0, Float(uniqueActionTypes) / 5.0) // Max 5 UI actions
        
        return (successRate * 0.4 + durationScore * 0.3 + frequency * 0.2 + diversityScore * 0.1)
    }
    
    private func updatePreference(to newPreference: InteractionMode, confidence: Float) {
        currentPreference = newPreference
        confidenceLevel = confidence
        
        // Update user configuration
        userConfiguration?.interactionMode = newPreference
        
        if let modelContext = modelContext {
            try? modelContext.save()
        }
        
        // Generate notification for user
        generatePreferenceUpdateNotification(newPreference, confidence)
    }
    
    // MARK: - Adaptive Recommendations
    private func generateAdaptiveRecommendations() {
        var recommendations: [InteractionRecommendation] = []
        
        let gestureScore = calculateGesturePreferenceScore()
        let traditionalScore = calculateTraditionalUIPreferenceScore()
        
        // Recommend trying gestures if they haven't been used much
        if gestureScore < 0.3 && getTotalInteractionCount() > 10 {
            recommendations.append(InteractionRecommendation(
                id: UUID(),
                type: .tryGestures,
                title: "Try Gesture Controls",
                description: "Long press to create nodes directly on the canvas",
                confidence: 0.8,
                priority: .medium
            ))
        }
        
        // Recommend traditional UI if gesture success rate is low
        if gestureScore > 0 && gestureScore < 0.5 {
            recommendations.append(InteractionRecommendation(
                id: UUID(),
                type: .useTraditionalUI,
                title: "Use Button Controls",
                description: "Access tools through the bottom toolbar for easier interaction",
                confidence: 0.7,
                priority: .high
            ))
        }
        
        // Recommend adaptive mode if both are being used
        if gestureScore > 0.3 && traditionalScore > 0.3 && currentPreference != .adaptive {
            recommendations.append(InteractionRecommendation(
                id: UUID(),
                type: .enableAdaptive,
                title: "Try Adaptive Mode",
                description: "Automatically switch between gesture and button controls",
                confidence: min(gestureScore, traditionalScore),
                priority: .medium
            ))
        }
        
        adaptiveRecommendations = recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func generatePreferenceUpdateNotification(_ mode: InteractionMode, _ confidence: Float) {
        let message: String
        switch mode {
        case .traditional:
            message = "We noticed you prefer button controls. Interface optimized!"
        case .gesture:
            message = "We see you love gesture controls. Canvas optimized for touch!"
        case .adaptive:
            message = "Adaptive mode enabled. Interface will adjust to your current context!"
        }
        
        // This would trigger a toast notification in the UI
        print("Preference Update: \(message) (Confidence: \(Int(confidence * 100))%)")
    }
    
    // MARK: - Utility Methods
    private func getTotalInteractionCount() -> Int {
        return gestureInteractions.count + traditionalUIInteractions.count
    }
    
    private func getTotalRecentInteractionCount() -> Int {
        let recentGestures = gestureInteractions.filter { $0.timestamp.timeIntervalSinceNow > -adaptationPeriod }
        let recentTraditional = traditionalUIInteractions.filter { $0.timestamp.timeIntervalSinceNow > -adaptationPeriod }
        return recentGestures.count + recentTraditional.count
    }
    
    func resetInteractionData() {
        gestureInteractions.removeAll()
        traditionalUIInteractions.removeAll()
        sessionStartTime = Date()
        confidenceLevel = 0.5
        adaptiveRecommendations.removeAll()
    }
    
    // MARK: - Manual Preference Setting
    func setPreference(_ mode: InteractionMode) {
        currentPreference = mode
        userConfiguration?.interactionMode = mode
        confidenceLevel = 1.0 // Manual setting = 100% confidence
        
        if let modelContext = modelContext {
            try? modelContext.save()
        }
    }
}

// MARK: - Supporting Types

struct InteractionEvent {
    let type: InteractionType
    let gestureType: GestureType?
    let uiAction: TraditionalUIAction?
    let success: Bool
    let duration: TimeInterval
    let timestamp: Date
    
    init(type: InteractionType, gestureType: GestureType? = nil, uiAction: TraditionalUIAction? = nil, success: Bool, duration: TimeInterval, timestamp: Date) {
        self.type = type
        self.gestureType = gestureType
        self.uiAction = uiAction
        self.success = success
        self.duration = duration
        self.timestamp = timestamp
    }
}

enum InteractionType {
    case gesture
    case traditionalUI
}

enum GestureType {
    case longPress
    case drag
    case pinch
    case doubleTap
    case swipe
}

enum TraditionalUIAction {
    case buttonTap
    case menuSelection
    case toolbarAction
    case textInput
    case navigationAction
}

struct InteractionRecommendation: Identifiable {
    let id: UUID
    let type: RecommendationType
    let title: String
    let description: String
    let confidence: Float
    let priority: RecommendationPriority
    
    enum RecommendationType {
        case tryGestures
        case useTraditionalUI
        case enableAdaptive
        case optimizeWorkflow
    }
    
    enum RecommendationPriority: Int, CaseIterable {
        case low = 1
        case medium = 2
        case high = 3
    }
}

// MARK: - Onboarding Data
struct InteractionModeOption {
    let mode: InteractionMode
    let title: String
    let description: String
    let icon: String
    let demoActions: [String]
    
    static let allOptions = [
        InteractionModeOption(
            mode: .traditional,
            title: "Button Controls",
            description: "Use familiar buttons and menus to interact with your thoughts",
            icon: "hand.tap",
            demoActions: ["Tap buttons to add nodes", "Use toolbar for tools", "Menu-driven workflow"]
        ),
        InteractionModeOption(
            mode: .gesture,
            title: "Gesture Controls", 
            description: "Direct touch interactions for fluid thought capture",
            icon: "hand.draw",
            demoActions: ["Long press to create", "Drag to connect", "Pinch to zoom"]
        ),
        InteractionModeOption(
            mode: .adaptive,
            title: "Smart Adaptive",
            description: "Automatically switches between modes based on context",
            icon: "wand.and.rays",
            demoActions: ["Best of both worlds", "Context-aware switching", "Learns your preferences"]
        )
    ]
}