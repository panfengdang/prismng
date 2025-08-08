import Foundation
import SwiftUI
import Combine

// MARK: - Adaptive Mode Service
@MainActor
class AdaptiveModeService: ObservableObject {
    @Published var currentUIMode: UIMode = .traditional
    @Published var adaptiveRecommendation: AdaptiveRecommendation?
    @Published var userExpertiseLevel: ExpertiseLevel = .beginner
    
    // Usage tracking
    private var gestureUsageCount = 0
    private var traditionalUIUsageCount = 0
    private var lastModeSwitch: Date = Date()
    private var consecutiveSuccessfulGestures = 0
    
    // Dependencies
    private var interactionService: InteractionPreferenceService?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
    }
    
    // MARK: - Setup
    func setup(interactionService: InteractionPreferenceService) {
        self.interactionService = interactionService
        
        // Observe user interactions to provide adaptive recommendations
        startAdaptiveAnalysis()
    }
    
    // MARK: - Core Functionality
    func trackGestureUsage(successful: Bool) {
        gestureUsageCount += 1
        
        if successful {
            consecutiveSuccessfulGestures += 1
            
            // If user is getting good at gestures, suggest switching
            if consecutiveSuccessfulGestures >= 5 && currentUIMode == .traditional {
                suggestModeSwitch(to: .gesture, reason: "您已熟练掌握手势操作，可以尝试手势模式获得更纯净的体验")
            }
        } else {
            consecutiveSuccessfulGestures = 0
            
            // If user struggles with gestures, suggest traditional UI
            if consecutiveSuccessfulGestures == 0 && gestureUsageCount >= 3 && currentUIMode == .gesture {
                suggestModeSwitch(to: .traditional, reason: "手势操作有些困难？试试传统按钮界面")
            }
        }
    }
    
    func trackTraditionalUIUsage() {
        traditionalUIUsageCount += 1
        
        // If experienced user still using traditional, suggest gesture mode
        if traditionalUIUsageCount >= 10 && userExpertiseLevel != .beginner {
            suggestModeSwitch(to: .gesture, reason: "尝试纯手势交互，享受更流畅的创作体验")
        }
    }
    
    func switchToMode(_ mode: UIMode) {
        currentUIMode = mode
        lastModeSwitch = Date()
        saveSettings()
        
        // Update user expertise based on mode choice
        updateExpertiseLevel()
    }
    
    func applyRecommendation(_ recommendation: AdaptiveRecommendation) {
        switchToMode(recommendation.suggestedMode)
        adaptiveRecommendation = nil
    }
    
    func dismissRecommendation() {
        adaptiveRecommendation = nil
    }
    
    // MARK: - Private Methods
    private func suggestModeSwitch(to mode: UIMode, reason: String) {
        // Don't suggest too frequently
        guard Date().timeIntervalSince(lastModeSwitch) > 300 else { return } // 5 minutes
        
        let recommendation = AdaptiveRecommendation(
            id: UUID(),
            suggestedMode: mode,
            reason: reason,
            confidence: calculateConfidence(for: mode)
        )
        
        adaptiveRecommendation = recommendation
    }
    
    private func calculateConfidence(for mode: UIMode) -> Float {
        switch mode {
        case .gesture:
            // Higher confidence if user has successful gesture experience
            return min(0.9, 0.3 + Float(consecutiveSuccessfulGestures) * 0.1)
        case .traditional:
            // Higher confidence if gesture attempts are failing
            return min(0.9, 0.5 + Float(max(0, 5 - consecutiveSuccessfulGestures)) * 0.1)
        case .hidden:
            // Only suggest hidden mode for expert users
            return userExpertiseLevel == .expert ? 0.8 : 0.2
        }
    }
    
    private func updateExpertiseLevel() {
        let totalUsage = gestureUsageCount + traditionalUIUsageCount
        
        if totalUsage > 50 && consecutiveSuccessfulGestures > 10 {
            userExpertiseLevel = .expert
        } else if totalUsage > 20 {
            userExpertiseLevel = .intermediate
        } else {
            userExpertiseLevel = .beginner
        }
    }
    
    private func startAdaptiveAnalysis() {
        // Periodic analysis of user behavior
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.analyzeUserBehavior()
            }
            .store(in: &cancellables)
    }
    
    private func analyzeUserBehavior() {
        let totalUsage = gestureUsageCount + traditionalUIUsageCount
        let gestureSuccessRate = gestureUsageCount > 0 ? Float(consecutiveSuccessfulGestures) / Float(gestureUsageCount) : 0
        
        // Analyze patterns and suggest optimizations
        if totalUsage > 15 && gestureSuccessRate > 0.7 && currentUIMode == .traditional {
            suggestModeSwitch(to: .gesture, reason: "基于您的使用模式，手势模式可能更适合您")
        }
    }
    
    // MARK: - Persistence
    private func saveSettings() {
        UserDefaults.standard.set(currentUIMode.rawValue, forKey: "adaptiveUIMode")
        UserDefaults.standard.set(userExpertiseLevel.rawValue, forKey: "userExpertiseLevel")
        UserDefaults.standard.set(gestureUsageCount, forKey: "gestureUsageCount")
        UserDefaults.standard.set(traditionalUIUsageCount, forKey: "traditionalUIUsageCount")
    }
    
    private func loadSettings() {
        if let savedMode = UserDefaults.standard.object(forKey: "adaptiveUIMode") as? String,
           let mode = UIMode(rawValue: savedMode) {
            currentUIMode = mode
        }
        
        if let savedLevel = UserDefaults.standard.object(forKey: "userExpertiseLevel") as? String,
           let level = ExpertiseLevel(rawValue: savedLevel) {
            userExpertiseLevel = level
        }
        
        gestureUsageCount = UserDefaults.standard.integer(forKey: "gestureUsageCount")
        traditionalUIUsageCount = UserDefaults.standard.integer(forKey: "traditionalUIUsageCount")
    }
}

// MARK: - Supporting Types
enum UIMode: String, CaseIterable {
    case traditional = "traditional"
    case gesture = "gesture"
    case hidden = "hidden"
}

enum ExpertiseLevel: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case expert = "expert"
}

struct AdaptiveRecommendation: Identifiable {
    let id: UUID
    let suggestedMode: UIMode
    let reason: String
    let confidence: Float
}

// MARK: - Adaptive Mode Toast View
// AdaptiveModeToast is now defined in Views/AdaptiveModeToast.swift