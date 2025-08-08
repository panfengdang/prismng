//
//  MemoryForgettingService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftData
import Combine

// MARK: - Forgetting Strategy
enum ForgettingStrategy: String, CaseIterable, Codable {
    case timeDecay = "time_decay"           // 时间衰减
    case accessFrequency = "access_frequency" // 访问频率
    case importance = "importance"           // 重要性评分
    case hybrid = "hybrid"                   // 混合策略
    
    var displayName: String {
        switch self {
        case .timeDecay: return "时间衰减"
        case .accessFrequency: return "访问频率"
        case .importance: return "重要性评分"
        case .hybrid: return "智能混合"
        }
    }
}

// MARK: - Forgetting Parameters
struct ForgettingParameters: Codable {
    var strategy: ForgettingStrategy = .hybrid
    var decayRate: Double = 0.1              // 衰减率 (0.0-1.0)
    var minimumRetentionScore: Double = 0.2  // 最低保留分数
    var forgettingThreshold: Double = 0.3    // 遗忘阈值
    var protectionPeriodDays: Int = 7        // 保护期（天）
    var maxForgottenNodes: Int = 100         // 最大遗忘节点数
    var enableAutoForgetting: Bool = true    // 启用自动遗忘
}

// MARK: - Memory Score
struct MemoryScore {
    let nodeId: UUID
    let timeScore: Double
    let frequencyScore: Double
    let importanceScore: Double
    let emotionalScore: Double
    let connectionScore: Double
    let overallScore: Double
    let shouldForget: Bool
    let forgettingReason: String?
}

// MARK: - Memory Forgetting Service
@MainActor
class MemoryForgettingService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var parameters = ForgettingParameters()
    @Published var memoryScores: [UUID: MemoryScore] = [:]
    @Published var forgottenNodes: [ForgottenNode] = []
    @Published var isAnalyzing = false
    @Published var lastAnalysisDate: Date?
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private let analysisQueue = DispatchQueue(label: "memory.forgetting", qos: .background)
    
    // MARK: - Setup
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadParameters()
        loadForgottenNodes()
        
        // Schedule periodic analysis
        if parameters.enableAutoForgetting {
            schedulePeriodicAnalysis()
        }
    }
    
    // MARK: - Parameter Management
    func updateParameters(_ newParameters: ForgettingParameters) {
        parameters = newParameters
        saveParameters()
        
        // Reschedule if auto-forgetting changed
        if parameters.enableAutoForgetting {
            schedulePeriodicAnalysis()
        }
    }
    
    private func loadParameters() {
        if let data = UserDefaults.standard.data(forKey: "ForgettingParameters"),
           let params = try? JSONDecoder().decode(ForgettingParameters.self, from: data) {
            parameters = params
        }
    }
    
    private func saveParameters() {
        if let data = try? JSONEncoder().encode(parameters) {
            UserDefaults.standard.set(data, forKey: "ForgettingParameters")
        }
    }
    
    // MARK: - Memory Analysis
    func analyzeMemoryScores(for nodes: [ThoughtNode]) async {
        isAnalyzing = true
        defer { 
            isAnalyzing = false
            lastAnalysisDate = Date()
        }
        
        var scores: [UUID: MemoryScore] = [:]
        
        for node in nodes {
            let score = await calculateMemoryScore(for: node, allNodes: nodes)
            scores[node.id] = score
        }
        
        // Update scores on main thread
        await MainActor.run {
            self.memoryScores = scores
        }
        
        // Apply forgetting if enabled
        if parameters.enableAutoForgetting {
            await applyForgetting(scores: scores, nodes: nodes)
        }
    }
    
    private func calculateMemoryScore(for node: ThoughtNode, allNodes: [ThoughtNode]) async -> MemoryScore {
        // Time-based score
        let timeScore = calculateTimeScore(for: node)
        
        // Access frequency score
        let frequencyScore = calculateFrequencyScore(for: node)
        
        // Importance score (based on connections and content)
        let importanceScore = calculateImportanceScore(for: node, allNodes: allNodes)
        
        // Emotional score (nodes with emotions are more memorable)
        let emotionalScore = calculateEmotionalScore(for: node)
        
        // Connection score (nodes with many connections are important)
        let connectionScore = calculateConnectionScore(for: node, allNodes: allNodes)
        
        // Calculate overall score based on strategy
        let overallScore = calculateOverallScore(
            timeScore: timeScore,
            frequencyScore: frequencyScore,
            importanceScore: importanceScore,
            emotionalScore: emotionalScore,
            connectionScore: connectionScore
        )
        
        // Determine if should forget
        let shouldForget = overallScore < parameters.forgettingThreshold &&
                          !isProtected(node: node)
        
        let forgettingReason = shouldForget ? determineForgettingReason(
            timeScore: timeScore,
            frequencyScore: frequencyScore,
            importanceScore: importanceScore
        ) : nil
        
        return MemoryScore(
            nodeId: node.id,
            timeScore: timeScore,
            frequencyScore: frequencyScore,
            importanceScore: importanceScore,
            emotionalScore: emotionalScore,
            connectionScore: connectionScore,
            overallScore: overallScore,
            shouldForget: shouldForget,
            forgettingReason: forgettingReason
        )
    }
    
    // MARK: - Score Calculation Methods
    private func calculateTimeScore(for node: ThoughtNode) -> Double {
        let daysSinceCreation = Date().timeIntervalSince(node.createdAt) / 86400.0
        let daysSinceUpdate = Date().timeIntervalSince(node.updatedAt) / 86400.0
        
        // Exponential decay
        let creationDecay = exp(-parameters.decayRate * daysSinceCreation / 30.0)
        let updateDecay = exp(-parameters.decayRate * daysSinceUpdate / 30.0)
        
        return max(creationDecay, updateDecay)
    }
    
    private func calculateFrequencyScore(for node: ThoughtNode) -> Double {
        // In a real implementation, we would track access frequency
        // For now, use a placeholder based on update frequency
        let updateCount = 1.0 // Placeholder
        return min(1.0, updateCount / 10.0)
    }
    
    private func calculateImportanceScore(for node: ThoughtNode, allNodes: [ThoughtNode]) -> Double {
        var score = 0.5 // Base score
        
        // Node type importance
        switch node.nodeType {
        case .insight, .conclusion:
            score += 0.2
        case .structure:
            score += 0.15
        case .question:
            score += 0.1
        case .contradiction:
            score += 0.1
        case .thought:
            score += 0.0
        }
        
        // Content length (longer content might be more important)
        let contentLength = Double(node.content.count)
        let lengthScore = min(1.0, contentLength / 500.0)
        score = score * 0.7 + lengthScore * 0.3
        
        return min(1.0, score)
    }
    
    private func calculateEmotionalScore(for node: ThoughtNode) -> Double {
        // Nodes with emotional tags are more memorable
        let emotionCount = Double(node.emotionalTags.count)
        let emotionScore = min(1.0, emotionCount / 3.0)
        
        // Emotional intensity also matters
        let intensityScore = node.emotionalIntensity
        
        return (emotionScore + intensityScore) / 2.0
    }
    
    private func calculateConnectionScore(for node: ThoughtNode, allNodes: [ThoughtNode]) -> Double {
        // Count connections (simplified - in real app, would query connections)
        let connectionCount = 0.0 // Placeholder
        return min(1.0, connectionCount / 5.0)
    }
    
    private func calculateOverallScore(
        timeScore: Double,
        frequencyScore: Double,
        importanceScore: Double,
        emotionalScore: Double,
        connectionScore: Double
    ) -> Double {
        switch parameters.strategy {
        case .timeDecay:
            return timeScore
            
        case .accessFrequency:
            return frequencyScore
            
        case .importance:
            return importanceScore
            
        case .hybrid:
            // Weighted combination
            return timeScore * 0.2 +
                   frequencyScore * 0.2 +
                   importanceScore * 0.3 +
                   emotionalScore * 0.15 +
                   connectionScore * 0.15
        }
    }
    
    private func isProtected(node: ThoughtNode) -> Bool {
        // Check protection period
        let daysSinceCreation = Date().timeIntervalSince(node.createdAt) / 86400.0
        if daysSinceCreation < Double(parameters.protectionPeriodDays) {
            return true
        }
        
        // AI-generated nodes are protected
        if node.isAIGenerated {
            return true
        }
        
        // Nodes with high emotional intensity are protected
        if node.emotionalIntensity > 0.7 {
            return true
        }
        
        return false
    }
    
    private func determineForgettingReason(
        timeScore: Double,
        frequencyScore: Double,
        importanceScore: Double
    ) -> String {
        var reasons: [String] = []
        
        if timeScore < 0.3 {
            reasons.append("长时间未访问")
        }
        
        if frequencyScore < 0.2 {
            reasons.append("访问频率低")
        }
        
        if importanceScore < 0.3 {
            reasons.append("重要性评分低")
        }
        
        return reasons.joined(separator: ", ")
    }
    
    // MARK: - Forgetting Application
    private func applyForgetting(scores: [UUID: MemoryScore], nodes: [ThoughtNode]) async {
        guard let modelContext = modelContext else { return }
        
        // Get nodes to forget
        let nodesToForget = scores.values
            .filter { $0.shouldForget }
            .sorted { $0.overallScore < $1.overallScore }
            .prefix(parameters.maxForgottenNodes)
        
        for score in nodesToForget {
            if let node = nodes.first(where: { $0.id == score.nodeId }) {
                await forgetNode(node, reason: score.forgettingReason ?? "综合评分低")
            }
        }
    }
    
    func forgetNode(_ node: ThoughtNode, reason: String = "手动遗忘") async {
        guard let modelContext = modelContext else { return }
        
        // Create forgotten node record
        let forgottenNode = ForgottenNode(
            originalId: node.id,
            content: node.content,
            nodeType: node.nodeType,
            createdAt: node.createdAt,
            forgottenAt: Date(),
            reason: reason,
            memoryScore: memoryScores[node.id]?.overallScore ?? 0.0
        )
        
        // Archive the node data
        archiveNode(node, forgottenNode: forgottenNode)
        
        // Remove from active nodes
        modelContext.delete(node)
        
        do {
            try modelContext.save()
            
            // Update forgotten nodes list
            forgottenNodes.append(forgottenNode)
            saveForgottenNodes()
            
            // Remove from memory scores
            memoryScores.removeValue(forKey: node.id)
            
        } catch {
            print("Failed to forget node: \(error)")
        }
    }
    
    func recallNode(_ forgottenNode: ForgottenNode) async {
        guard let modelContext = modelContext else { return }
        
        // Recreate the node
        let node = ThoughtNode(
            content: forgottenNode.content,
            nodeType: forgottenNode.nodeType,
            position: Position(x: 0, y: 0)
        )
        
        modelContext.insert(node)
        
        do {
            try modelContext.save()
            
            // Remove from forgotten nodes
            forgottenNodes.removeAll { $0.id == forgottenNode.id }
            saveForgottenNodes()
            
        } catch {
            print("Failed to recall node: \(error)")
        }
    }
    
    // MARK: - Archiving
    private func archiveNode(_ node: ThoughtNode, forgottenNode: ForgottenNode) {
        // In a real implementation, would save to a separate archive
        // For MVP, we just track the forgotten node metadata
    }
    
    // MARK: - Persistence
    private func loadForgottenNodes() {
        if let data = UserDefaults.standard.data(forKey: "ForgottenNodes"),
           let nodes = try? JSONDecoder().decode([ForgottenNode].self, from: data) {
            forgottenNodes = nodes
        }
    }
    
    private func saveForgottenNodes() {
        if let data = try? JSONEncoder().encode(forgottenNodes) {
            UserDefaults.standard.set(data, forKey: "ForgottenNodes")
        }
    }
    
    // MARK: - Periodic Analysis
    private func schedulePeriodicAnalysis() {
        // Run analysis daily
        Timer.publish(every: 86400, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    guard let self = self,
                          let modelContext = self.modelContext else { return }
                    
                    let request = FetchDescriptor<ThoughtNode>()
                    if let nodes = try? modelContext.fetch(request) {
                        await self.analyzeMemoryScores(for: nodes)
                    }
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Forgotten Node Model
struct ForgottenNode: Identifiable, Codable {
    let id = UUID()
    let originalId: UUID
    let content: String
    let nodeType: NodeType
    let createdAt: Date
    let forgottenAt: Date
    let reason: String
    let memoryScore: Double
}

// MARK: - Memory Health Statistics
extension MemoryForgettingService {
    
    var memoryHealthStats: MemoryHealthStats {
        let totalNodes = memoryScores.count
        let healthyNodes = memoryScores.values.filter { $0.overallScore > 0.7 }.count
        let atRiskNodes = memoryScores.values.filter { $0.overallScore > 0.3 && $0.overallScore <= 0.7 }.count
        let forgettableNodes = memoryScores.values.filter { $0.shouldForget }.count
        
        let averageScore = memoryScores.values.isEmpty ? 0.0 :
            memoryScores.values.reduce(0.0) { $0 + $1.overallScore } / Double(memoryScores.count)
        
        return MemoryHealthStats(
            totalNodes: totalNodes,
            healthyNodes: healthyNodes,
            atRiskNodes: atRiskNodes,
            forgettableNodes: forgettableNodes,
            forgottenNodes: forgottenNodes.count,
            averageMemoryScore: averageScore
        )
    }
}

struct MemoryHealthStats {
    let totalNodes: Int
    let healthyNodes: Int
    let atRiskNodes: Int
    let forgettableNodes: Int
    let forgottenNodes: Int
    let averageMemoryScore: Double
}