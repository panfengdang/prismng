//
//  CognitiveFlowStateEngine.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Cognitive State Enum
enum CognitiveState {
    case divergentThinking  // 发散思维
    case deepFocus         // 深度专注
    case informationSeeking // 信息寻找
    case collaboration     // 协作模式
    case incubation        // 孵化模式
    case neutral           // 中性状态
}

// MARK: - Cognitive Factors
struct CognitiveFactors {
    let nodeCreationRate: Int
    let editDepth: Double
    let searchFrequency: Int
    let focusTime: TimeInterval
    let connectionActivity: Int
}

// MARK: - User Action
struct UserAction {
    let type: ActionType
    let timestamp: Date
    let duration: TimeInterval?
    let detail: String?
    
    enum ActionType {
        case nodeCreation
        case nodeEdit
        case search
        case connection
        case navigation
        case modeSwitch
    }
}

// MARK: - Recommendation
struct Recommendation {
    let mode: RecommendedMode
    let message: String
    let confidence: Double
    let features: [Feature]
    
    enum RecommendedMode {
        case incubation
        case exploration
        case retrieval
        case collaboration
        case focus
        
        var description: String {
            switch self {
            case .incubation: return "incubation_mode"
            case .exploration: return "exploration_mode"
            case .retrieval: return "retrieval_mode"
            case .collaboration: return "collaboration_mode"
            case .focus: return "focus_mode"
            }
        }
    }
    
    enum Feature {
        case driftMode
        case weakAssociations
        case spontaneousConnections
        case focusChamber
        case aiLens
        case contextualTools
        case semanticSearch
        case globalSearch
        case relatedNodes
    }
}

// MARK: - Cognitive Mode Enum
enum CognitiveMode: String, CaseIterable {
    case capture = "capture"
    case incubation = "incubation"
    case exploration = "exploration"
    case association = "association"
    case retrieval = "retrieval"
}

// MARK: - Cognitive Recommendation
struct CognitiveRecommendation: Identifiable {
    let id: String
    let mode: CognitiveMode
    let title: String
    let reason: String
    let icon: String
    let confidence: Double
}

// MARK: - Cognitive Flow State Engine
@MainActor
class CognitiveFlowStateEngine: ObservableObject {
    @Published var currentState: CognitiveState = .neutral
    @Published var activeRecommendation: CognitiveRecommendation?
    @Published var showRecommendation = false
    
    private var userActions: [UserAction] = []
    private var userProfile = UserProfile()
    private var cancellables = Set<AnyCancellable>()
    private let stateUpdateInterval: TimeInterval = 30 // Update state every 30 seconds
    
    init() {
        setupStateMonitoring()
    }
    
    // MARK: - Public Methods
    
    func trackAction(_ action: UserAction) {
        userActions.append(action)
        // Keep only recent actions (last 30 minutes)
        let cutoffTime = Date().addingTimeInterval(-30 * 60)
        userActions = userActions.filter { $0.timestamp > cutoffTime }
    }
    
    func userAcceptedRecommendation() {
        guard let recommendation = activeRecommendation else { return }
        // Convert CognitiveMode to RecommendedMode for profile tracking
        if let recommendedMode = convertToRecommendedMode(recommendation.mode) {
            userProfile.acceptedRecommendations.append(recommendedMode)
        }
        userProfile.updateConfidenceThreshold(increased: true)
        activeRecommendation = nil
        showRecommendation = false
    }
    
    func userDismissedRecommendation() {
        guard let recommendation = activeRecommendation else { return }
        // Convert CognitiveMode to RecommendedMode for profile tracking
        if let recommendedMode = convertToRecommendedMode(recommendation.mode) {
            userProfile.dismissedRecommendations.append(recommendedMode)
        }
        userProfile.updateConfidenceThreshold(increased: false)
        activeRecommendation = nil
        showRecommendation = false
    }
    
    func dismissRecommendation() {
        userDismissedRecommendation()
    }
    
    // MARK: - Private Methods
    
    private func setupStateMonitoring() {
        Timer.publish(every: stateUpdateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateCognitiveState()
            }
            .store(in: &cancellables)
    }
    
    private func updateCognitiveState() {
        let newState = detectCurrentState()
        
        if newState != currentState {
            currentState = newState
            generateRecommendationIfNeeded()
        }
    }
    
    private func detectCurrentState() -> CognitiveState {
        let recentActions = getRecentActions(minutes: 10)
        
        let factors = CognitiveFactors(
            nodeCreationRate: recentActions.filter { $0.type == .nodeCreation }.count,
            editDepth: calculateAverageEditDepth(recentActions),
            searchFrequency: recentActions.filter { $0.type == .search }.count,
            focusTime: calculateLongestFocusTime(recentActions),
            connectionActivity: recentActions.filter { $0.type == .connection }.count
        )
        
        // Rule-based state detection
        if factors.nodeCreationRate > 3 && factors.editDepth < 50 {
            return .divergentThinking
        } else if factors.focusTime > 120 && factors.editDepth > 100 {
            return .deepFocus
        } else if factors.searchFrequency > 2 {
            return .informationSeeking
        } else if factors.connectionActivity > 5 {
            return .collaboration
        } else if factors.nodeCreationRate == 0 && factors.editDepth == 0 {
            return .incubation
        }
        
        return .neutral
    }
    
    private func generateRecommendationIfNeeded() {
        guard !showRecommendation else { return }
        
        let recommendation = generateRecommendation(for: currentState)
        if let recommendation = recommendation,
           recommendation.confidence > userProfile.confidenceThreshold {
            activeRecommendation = recommendation
            showRecommendation = true
        }
    }
    
    private func generateRecommendation(for state: CognitiveState) -> CognitiveRecommendation? {
        switch state {
        case .divergentThinking:
            return CognitiveRecommendation(
                id: UUID().uuidString,
                mode: .incubation,
                title: "Incubation Mode",
                reason: "发现你正在探索新想法，要试试让它们自然连接吗？🌱",
                icon: "sparkles",
                confidence: calculateConfidence(state)
            )
            
        case .deepFocus:
            return CognitiveRecommendation(
                id: UUID().uuidString,
                mode: .exploration,
                title: "Exploration Mode",
                reason: "看起来你想深入思考这个想法，切换到专注模式？💡",
                icon: "magnifyingglass",
                confidence: calculateConfidence(state)
            )
            
        case .informationSeeking:
            return CognitiveRecommendation(
                id: UUID().uuidString,
                mode: .retrieval,
                title: "Retrieval Mode",
                reason: "需要找到相关信息？试试语义搜索功能 🔍",
                icon: "doc.text.magnifyingglass",
                confidence: calculateConfidence(state)
            )
            
        case .collaboration:
            return CognitiveRecommendation(
                id: UUID().uuidString,
                mode: .association,
                title: "Association Mode",
                reason: "检测到协作需求，要开启关联模式吗？👥",
                icon: "person.2.fill",
                confidence: calculateConfidence(state)
            )
            
        default:
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func getRecentActions(minutes: Int) -> [UserAction] {
        let cutoffTime = Date().addingTimeInterval(-Double(minutes * 60))
        return userActions.filter { $0.timestamp > cutoffTime }
    }
    
    private func calculateAverageEditDepth(_ actions: [UserAction]) -> Double {
        let editActions = actions.filter { $0.type == .nodeEdit }
        guard !editActions.isEmpty else { return 0 }
        
        let totalLength = editActions.compactMap { $0.detail?.count }.reduce(0, +)
        return Double(totalLength) / Double(editActions.count)
    }
    
    private func calculateLongestFocusTime(_ actions: [UserAction]) -> TimeInterval {
        let editActions = actions.filter { $0.type == .nodeEdit }
        return editActions.compactMap { $0.duration }.max() ?? 0
    }
    
    private func calculateConfidence(_ state: CognitiveState) -> Double {
        // Base confidence based on state clarity
        var confidence = 0.7
        
        // Adjust based on user history
        if userProfile.acceptedRecommendations.contains(where: { $0 == recommendationMode(for: state) }) {
            confidence += 0.1
        }
        if userProfile.dismissedRecommendations.contains(where: { $0 == recommendationMode(for: state) }) {
            confidence -= 0.2
        }
        
        // Adjust based on action consistency
        let recentActions = getRecentActions(minutes: 5)
        let actionConsistency = calculateActionConsistency(recentActions)
        confidence += actionConsistency * 0.2
        
        return min(max(confidence, 0), 1)
    }
    
    private func recommendationMode(for state: CognitiveState) -> Recommendation.RecommendedMode? {
        switch state {
        case .divergentThinking: return .incubation
        case .deepFocus: return .exploration
        case .informationSeeking: return .retrieval
        case .collaboration: return .collaboration
        default: return nil
        }
    }
    
    private func calculateActionConsistency(_ actions: [UserAction]) -> Double {
        guard actions.count > 2 else { return 0.5 }
        
        // Check if actions follow a consistent pattern
        let actionTypes = actions.map { $0.type }
        let uniqueTypes = Set(actionTypes)
        
        return 1.0 - (Double(uniqueTypes.count) / Double(actionTypes.count))
    }
    
    private func convertToRecommendedMode(_ cognitiveMode: CognitiveMode) -> Recommendation.RecommendedMode? {
        switch cognitiveMode {
        case .incubation: return .incubation
        case .exploration: return .exploration
        case .retrieval: return .retrieval
        case .capture: return .focus
        case .association: return .collaboration
        }
    }
}

// MARK: - User Profile
private struct UserProfile {
    var acceptedRecommendations: [Recommendation.RecommendedMode] = []
    var dismissedRecommendations: [Recommendation.RecommendedMode] = []
    var confidenceThreshold: Double = 0.6
    
    mutating func updateConfidenceThreshold(increased: Bool) {
        if increased {
            confidenceThreshold = max(0.4, confidenceThreshold - 0.05)
        } else {
            confidenceThreshold = min(0.9, confidenceThreshold + 0.05)
        }
    }
}
