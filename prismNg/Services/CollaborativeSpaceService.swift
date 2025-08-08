//
//  CollaborativeSpaceService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP1c: Collaborative Space Service - 多人实时协作空间和中立AI引导
//

import Foundation
import SwiftUI
import Combine

// MARK: - Collaborative Space Models

/// 协作空间模型
struct CollaborativeSpace: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let ownerId: String
    let createdAt: Date
    var lastActivityAt: Date
    var isPublic: Bool
    var maxParticipants: Int
    var currentParticipants: [String]
    var collaborationMode: CollaborationMode
    var aiMediatorSettings: AIMediatorSettings
    
    enum CollaborationMode: String, Codable, CaseIterable {
        case freeform = "freeform"           // 自由协作
        case structured = "structured"       // 结构化协作
        case facilitated = "facilitated"     // AI引导协作
        case consensus = "consensus"         // 共识决策模式
        
        var displayName: String {
            switch self {
            case .freeform: return "自由协作"
            case .structured: return "结构化协作"
            case .facilitated: return "AI引导协作"
            case .consensus: return "共识决策"
            }
        }
        
        var aiRole: String {
            switch self {
            case .freeform: return "观察者"
            case .structured: return "协调者"
            case .facilitated: return "引导者"
            case .consensus: return "调解者"
            }
        }
    }
}

/// 协作参与者
struct CollaborationParticipant: Codable, Identifiable {
    let id: String
    let userId: String
    let displayName: String
    let avatarColor: String
    let joinedAt: Date
    var lastActiveAt: Date
    var role: ParticipantRole
    var contributionCount: Int
    var isOnline: Bool
    var cursorPosition: CGPoint?
    var activeNodeId: String?
    
    enum ParticipantRole: String, Codable {
        case owner = "owner"
        case moderator = "moderator"
        case contributor = "contributor"
        case observer = "observer"
        
        var displayName: String {
            switch self {
            case .owner: return "拥有者"
            case .moderator: return "管理员"
            case .contributor: return "贡献者"
            case .observer: return "观察者"
            }
        }
    }
}

/// 协作事件
struct CollaborationEvent: Codable, Identifiable {
    let id: String
    let spaceId: String
    let participantId: String
    let eventType: EventType
    let timestamp: Date
    var data: [String: String]
    var nodeId: String?
    var connectionId: String?
    
    enum EventType: String, Codable {
        case joined = "joined"
        case left = "left"
        case nodeCreated = "node_created"
        case nodeUpdated = "node_updated"
        case nodeDeleted = "node_deleted"
        case connectionCreated = "connection_created"
        case connectionDeleted = "connection_deleted"
        case cursorMoved = "cursor_moved"
        case aiSuggestion = "ai_suggestion"
        case consensusRequest = "consensus_request"
        case voteCast = "vote_cast"
    }
}

/// AI调解者设置
struct AIMediatorSettings: Codable {
    var enabled: Bool
    var interventionLevel: InterventionLevel
    var conflictResolutionMode: ConflictResolutionMode
    var suggestionFrequency: SuggestionFrequency
    var personalityType: AIPersonalityType
    
    enum InterventionLevel: String, Codable, CaseIterable {
        case passive = "passive"     // 仅在请求时介入
        case moderate = "moderate"   // 适度介入
        case active = "active"       // 主动介入
        
        var displayName: String {
            switch self {
            case .passive: return "被动"
            case .moderate: return "适度"
            case .active: return "主动"
            }
        }
    }
    
    enum ConflictResolutionMode: String, Codable, CaseIterable {
        case mediate = "mediate"         // 调解模式
        case synthesize = "synthesize"   // 综合模式
        case vote = "vote"               // 投票模式
        
        var displayName: String {
            switch self {
            case .mediate: return "调解"
            case .synthesize: return "综合"
            case .vote: return "投票"
            }
        }
    }
    
    enum SuggestionFrequency: String, Codable, CaseIterable {
        case never = "never"
        case occasional = "occasional"
        case frequent = "frequent"
        
        var displayName: String {
            switch self {
            case .never: return "从不"
            case .occasional: return "偶尔"
            case .frequent: return "频繁"
            }
        }
    }
    
    enum AIPersonalityType: String, Codable, CaseIterable {
        case neutral = "neutral"
        case socratic = "socratic"
        case supportive = "supportive"
        case challenging = "challenging"
        
        var displayName: String {
            switch self {
            case .neutral: return "中立"
            case .socratic: return "苏格拉底式"
            case .supportive: return "支持型"
            case .challenging: return "挑战型"
            }
        }
    }
    
    static let `default` = AIMediatorSettings(
        enabled: true,
        interventionLevel: .moderate,
        conflictResolutionMode: .synthesize,
        suggestionFrequency: .occasional,
        personalityType: .neutral
    )
}

/// AI调解建议
struct AIMediatorSuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let content: String
    let targetNodeIds: [String]
    let confidence: Double
    let timestamp: Date
    
    enum SuggestionType {
        case connection     // 建议连接
        case synthesis      // 综合观点
        case question       // 引导性问题
        case clarification  // 澄清请求
        case consensus      // 共识点
        case conflict       // 冲突提示
    }
}

/// 共识决策项
struct ConsensusItem: Codable, Identifiable {
    let id: String
    let spaceId: String
    let proposerId: String
    let content: String
    let createdAt: Date
    var votes: [String: VoteType]  // userId -> vote
    var status: ConsensusStatus
    var aiAnalysis: String?
    
    enum VoteType: String, Codable {
        case agree = "agree"
        case disagree = "disagree"
        case abstain = "abstain"
    }
    
    enum ConsensusStatus: String, Codable {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
        case stalled = "stalled"
    }
}

/// 行动项
struct ActionItem: Codable, Identifiable {
    let id: String
    let spaceId: String
    let content: String
    let assignedTo: [String]
    let createdAt: Date
    var completedAt: Date?
    var status: ActionStatus
    
    enum ActionStatus: String, Codable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case cancelled = "cancelled"
    }
}

// MARK: - Collaborative Space Service

/// 协作空间服务
@MainActor
class CollaborativeSpaceService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentSpace: CollaborativeSpace?
    @Published var availableSpaces: [CollaborativeSpace] = []
    @Published var participants: [CollaborationParticipant] = []
    @Published var recentEvents: [CollaborationEvent] = []
    @Published var aiSuggestions: [AIMediatorSuggestion] = []
    @Published var consensusItems: [ConsensusItem] = []
    @Published var isConnected = false
    @Published var errorMessage: String?
    
    // AI Mediator states
    @Published var isAIMediatorActive = false
    @Published var currentDiscussionTopic: String?
    @Published var conflictDetected = false
    @Published var consensusPoints: [String] = []
    @Published var actionItems: [ActionItem] = []
    @Published var conflictAlerts: [String] = []
    
    // MARK: - Private Properties
    private let firebaseManager = FirebaseManager.shared
    private var spaceListeners: [Any] = [] // Would be ListenerRegistration with real Firebase
    private var cancellables = Set<AnyCancellable>()
    private let currentUserId: String
    
    // MARK: - Dependencies
    private let aiService: AIService
    
    // MARK: - Initialization
    
    init(userId: String, aiService: AIService) {
        self.currentUserId = userId
        self.aiService = aiService
        
        loadAvailableSpaces()
        
        // Simulate some demo spaces
        createDemoSpaces()
    }
    
    // MARK: - Space Management
    
    /// 创建新的协作空间
    func createSpace(
        name: String,
        description: String,
        isPublic: Bool = true,
        maxParticipants: Int = 10,
        mode: CollaborativeSpace.CollaborationMode = .facilitated
    ) async throws -> CollaborativeSpace {
        
        let spaceId = UUID().uuidString
        
        let space = CollaborativeSpace(
            id: spaceId,
            name: name,
            description: description,
            ownerId: currentUserId,
            createdAt: Date(),
            lastActivityAt: Date(),
            isPublic: isPublic,
            maxParticipants: maxParticipants,
            currentParticipants: [currentUserId],
            collaborationMode: mode,
            aiMediatorSettings: AIMediatorSettings.default
        )
        
        // Save to Firebase
        try await firebaseManager.saveDocument(space, to: "collaborative_spaces", documentId: spaceId)
        
        // Create initial participant
        let owner = CollaborationParticipant(
            id: UUID().uuidString,
            userId: currentUserId,
            displayName: "Space Owner",
            avatarColor: generateAvatarColor(),
            joinedAt: Date(),
            lastActiveAt: Date(),
            role: .owner,
            contributionCount: 0,
            isOnline: true
        )
        
        try await firebaseManager.saveDocument(
            owner,
            to: "collaborative_spaces/\(spaceId)/participants",
            documentId: currentUserId
        )
        
        await MainActor.run {
            self.availableSpaces.append(space)
        }
        
        return space
    }
    
    /// 加入协作空间
    func joinSpace(_ spaceId: String) async throws {
        guard let space = availableSpaces.first(where: { $0.id == spaceId }) else {
            throw CollaborationError.spaceNotFound
        }
        
        // Check space capacity
        if space.currentParticipants.count >= space.maxParticipants {
            throw CollaborationError.spaceFull
        }
        
        // Create participant record
        let participant = CollaborationParticipant(
            id: UUID().uuidString,
            userId: currentUserId,
            displayName: "User \(currentUserId.prefix(8))",
            avatarColor: generateAvatarColor(),
            joinedAt: Date(),
            lastActiveAt: Date(),
            role: .contributor,
            contributionCount: 0,
            isOnline: true
        )
        
        try await firebaseManager.saveDocument(
            participant,
            to: "collaborative_spaces/\(spaceId)/participants",
            documentId: currentUserId
        )
        
        // Record join event
        let joinEvent = CollaborationEvent(
            id: UUID().uuidString,
            spaceId: spaceId,
            participantId: currentUserId,
            eventType: .joined,
            timestamp: Date(),
            data: [:]
        )
        
        try await recordEvent(joinEvent)
        
        await MainActor.run {
            self.currentSpace = space
            self.participants.append(participant)
            self.isConnected = true
        }
        
        // Start AI mediator if enabled
        if space.aiMediatorSettings.enabled {
            startAIMediator()
        }
    }
    
    /// 离开协作空间
    func leaveSpace() async throws {
        guard let space = currentSpace else { return }
        
        // Update participant status
        let participant = CollaborationParticipant(
            id: currentUserId,
            userId: currentUserId,
            displayName: "User",
            avatarColor: "",
            joinedAt: Date(),
            lastActiveAt: Date(),
            role: .contributor,
            contributionCount: 0,
            isOnline: false
        )
        
        try await firebaseManager.saveDocument(
            participant,
            to: "collaborative_spaces/\(space.id)/participants",
            documentId: currentUserId
        )
        
        // Record leave event
        let leaveEvent = CollaborationEvent(
            id: UUID().uuidString,
            spaceId: space.id,
            participantId: currentUserId,
            eventType: .left,
            timestamp: Date(),
            data: [:]
        )
        
        try await recordEvent(leaveEvent)
        
        await MainActor.run {
            self.currentSpace = nil
            self.participants.removeAll()
            self.recentEvents.removeAll()
            self.isConnected = false
            self.isAIMediatorActive = false
        }
        
        removeListeners()
    }
    
    // MARK: - Real-time Collaboration
    
    /// 广播节点创建事件
    func broadcastNodeCreation(_ node: ThoughtNode) async throws {
        guard let space = currentSpace else { return }
        
        let event = CollaborationEvent(
            id: UUID().uuidString,
            spaceId: space.id,
            participantId: currentUserId,
            eventType: .nodeCreated,
            timestamp: Date(),
            data: [
                "content": node.content,
                "nodeType": node.nodeType.rawValue,
                "position": "\(node.position.x),\(node.position.y)"
            ],
            nodeId: node.id.uuidString
        )
        
        try await recordEvent(event)
    }
    
    /// 广播节点更新事件
    func broadcastNodeUpdate(_ node: ThoughtNode) async throws {
        guard let space = currentSpace else { return }
        
        let event = CollaborationEvent(
            id: UUID().uuidString,
            spaceId: space.id,
            participantId: currentUserId,
            eventType: .nodeUpdated,
            timestamp: Date(),
            data: [
                "content": node.content,
                "position": "\(node.position.x),\(node.position.y)"
            ],
            nodeId: node.id.uuidString
        )
        
        try await recordEvent(event)
    }
    
    /// 广播光标移动
    func broadcastCursorPosition(_ position: CGPoint) async throws {
        guard let space = currentSpace else { return }
        
        // Update participant cursor position
        if var participant = participants.first(where: { $0.userId == currentUserId }) {
            participant.cursorPosition = position
            participant.lastActiveAt = Date()
            
            try await firebaseManager.saveDocument(
                participant,
                to: "collaborative_spaces/\(space.id)/participants",
                documentId: currentUserId
            )
        }
    }
    
    // MARK: - AI Mediator
    
    /// 启动AI调解者
    private func startAIMediator() {
        guard let space = currentSpace,
              space.aiMediatorSettings.enabled else { return }
        
        isAIMediatorActive = true
        
        // Start monitoring collaboration patterns
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                await self.analyzeCollaborationPatterns()
            }
        }
    }
    
    /// 分析协作模式
    private func analyzeCollaborationPatterns() async {
        guard isAIMediatorActive else { return }
        
        // Analyze recent events for patterns
        let recentNodeEvents = recentEvents.filter { 
            [.nodeCreated, .nodeUpdated].contains($0.eventType) 
        }
        
        // Detect potential conflicts
        if detectConflictingEdits(in: recentNodeEvents) {
            conflictDetected = true
            await generateConflictResolution()
        }
        
        // Generate suggestions based on activity
        if shouldGenerateSuggestion() {
            await generateAISuggestion()
        }
        
        // Check for consensus opportunities
        await checkConsensusOpportunities()
    }
    
    /// 生成AI建议
    private func generateAISuggestion() async {
        // Analyze current state and generate appropriate suggestion
        let suggestionTypes: [AIMediatorSuggestion.SuggestionType] = [
            .connection, .synthesis, .question, .clarification
        ]
        
        let randomType = suggestionTypes.randomElement() ?? .question
        
        let suggestion = AIMediatorSuggestion(
            type: randomType,
            content: generateSuggestionContent(for: randomType),
            targetNodeIds: [],
            confidence: Double.random(in: 0.7...0.95),
            timestamp: Date()
        )
        
        await MainActor.run {
            self.aiSuggestions.append(suggestion)
            
            // Keep only recent suggestions
            if self.aiSuggestions.count > 10 {
                self.aiSuggestions = Array(self.aiSuggestions.suffix(10))
            }
        }
    }
    
    /// 处理共识请求
    func requestConsensus(on content: String) async throws {
        guard let space = currentSpace else { return }
        
        let consensusItem = ConsensusItem(
            id: UUID().uuidString,
            spaceId: space.id,
            proposerId: currentUserId,
            content: content,
            createdAt: Date(),
            votes: [currentUserId: .agree],
            status: .pending,
            aiAnalysis: nil
        )
        
        // Get AI analysis
        let thoughtNode = ThoughtNode(content: content)
        let analysis = try? await aiService.generateInsight(from: [thoughtNode])
        var updatedItem = consensusItem
        updatedItem.aiAnalysis = analysis
        
        try await firebaseManager.saveDocument(
            updatedItem,
            to: "collaborative_spaces/\(space.id)/consensus",
            documentId: consensusItem.id
        )
        
        await MainActor.run {
            self.consensusItems.append(updatedItem)
        }
    }
    
    /// 投票
    func vote(on itemId: String, vote: ConsensusItem.VoteType) async throws {
        guard let space = currentSpace,
              let index = consensusItems.firstIndex(where: { $0.id == itemId }) else { return }
        
        var item = consensusItems[index]
        item.votes[currentUserId] = vote
        
        // Check if consensus reached
        let totalParticipants = participants.count
        let agreeVotes = item.votes.values.filter { $0 == .agree }.count
        let disagreeVotes = item.votes.values.filter { $0 == .disagree }.count
        
        if agreeVotes > totalParticipants / 2 {
            item.status = .approved
            consensusPoints.append(item.content)
        } else if disagreeVotes > totalParticipants / 2 {
            item.status = .rejected
        }
        
        try await firebaseManager.saveDocument(
            item,
            to: "collaborative_spaces/\(space.id)/consensus",
            documentId: item.id
        )
        
        await MainActor.run {
            self.consensusItems[index] = item
        }
    }
    
    // MARK: - Private Methods
    
    private func setupRealtimeListeners(_ spaceId: String) {
        // In real implementation, setup Firestore listeners
        // For now, simulate with timer
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            Task { @MainActor in
                // Simulate participant updates
                self.simulateParticipantActivity()
            }
        }
    }
    
    private func removeListeners() {
        // Remove all listeners
        spaceListeners.removeAll()
    }
    
    private func loadAvailableSpaces() {
        // In real implementation, load from Firestore
        // For now, use demo data
    }
    
    private func recordEvent(_ event: CollaborationEvent) async throws {
        try await firebaseManager.saveDocument(
            event,
            to: "collaborative_spaces/\(event.spaceId)/events",
            documentId: event.id
        )
        
        await MainActor.run {
            self.recentEvents.append(event)
            
            // Keep only recent 100 events
            if self.recentEvents.count > 100 {
                self.recentEvents = Array(self.recentEvents.suffix(100))
            }
        }
    }
    
    private func generateAvatarColor() -> String {
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FECA57", "#FF9FF3"]
        return colors.randomElement() ?? "#4ECDC4"
    }
    
    private func detectConflictingEdits(in events: [CollaborationEvent]) -> Bool {
        // Simple conflict detection: multiple users editing same node within short time
        let nodeEdits = Dictionary(grouping: events) { $0.nodeId ?? "" }
        
        for (nodeId, edits) in nodeEdits {
            guard !nodeId.isEmpty else { continue }
            
            let uniqueEditors = Set(edits.map { $0.participantId })
            if uniqueEditors.count > 1 {
                // Multiple users edited same node
                return true
            }
        }
        
        return false
    }
    
    private func shouldGenerateSuggestion() -> Bool {
        guard let settings = currentSpace?.aiMediatorSettings else { return false }
        
        switch settings.suggestionFrequency {
        case .never:
            return false
        case .occasional:
            return Int.random(in: 0..<10) == 0
        case .frequent:
            return Int.random(in: 0..<3) == 0
        }
    }
    
    private func generateSuggestionContent(for type: AIMediatorSuggestion.SuggestionType) -> String {
        switch type {
        case .connection:
            return "这两个想法似乎有关联，考虑将它们连接起来探索更深层的关系。"
        case .synthesis:
            return "基于大家的讨论，我注意到一个共同的主题正在浮现..."
        case .question:
            return "有趣的观点！如果从另一个角度来看，会有什么不同的发现吗？"
        case .clarification:
            return "这个想法很有潜力，能否进一步阐述一下具体的含义？"
        case .consensus:
            return "看起来大家在这一点上达成了共识，要不要将其记录为关键结论？"
        case .conflict:
            return "我注意到这里有不同的观点，让我们探索如何将它们整合。"
        }
    }
    
    private func generateConflictResolution() async {
        let alert = "检测到潜在的编辑冲突。建议通过对话澄清各自的观点，寻找共同点。"
        
        await MainActor.run {
            self.conflictAlerts.append(alert)
            
            // Auto-clear after some time
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                self.conflictAlerts.removeAll { $0 == alert }
            }
        }
    }
    
    private func checkConsensusOpportunities() async {
        // Analyze discussion patterns for consensus opportunities
        // This is a simplified implementation
    }
    
    private func simulateParticipantActivity() {
        // Simulate other participants' cursor movements
        for i in 0..<participants.count {
            if participants[i].userId != currentUserId {
                participants[i].cursorPosition = CGPoint(
                    x: Double.random(in: 100...500),
                    y: Double.random(in: 100...500)
                )
                participants[i].lastActiveAt = Date()
            }
        }
    }
    
    private func createDemoSpaces() {
        let demoSpaces = [
            CollaborativeSpace(
                id: "demo1",
                name: "产品头脑风暴",
                description: "新产品功能的创意讨论空间",
                ownerId: "system",
                createdAt: Date().addingTimeInterval(-86400),
                lastActivityAt: Date().addingTimeInterval(-3600),
                isPublic: true,
                maxParticipants: 8,
                currentParticipants: ["user1", "user2", "user3"],
                collaborationMode: .facilitated,
                aiMediatorSettings: AIMediatorSettings.default
            ),
            CollaborativeSpace(
                id: "demo2",
                name: "团队回顾会议",
                description: "Sprint回顾和改进讨论",
                ownerId: "system",
                createdAt: Date().addingTimeInterval(-172800),
                lastActivityAt: Date().addingTimeInterval(-7200),
                isPublic: true,
                maxParticipants: 6,
                currentParticipants: ["user1", "user4"],
                collaborationMode: .consensus,
                aiMediatorSettings: AIMediatorSettings.default
            )
        ]
        
        availableSpaces = demoSpaces
    }
}

// MARK: - Collaboration Errors

enum CollaborationError: LocalizedError {
    case spaceNotFound
    case spaceFull
    case unauthorized
    case connectionFailed
    case syncError
    
    var errorDescription: String? {
        switch self {
        case .spaceNotFound:
            return "协作空间不存在"
        case .spaceFull:
            return "协作空间已满"
        case .unauthorized:
            return "没有权限访问此空间"
        case .connectionFailed:
            return "连接失败"
        case .syncError:
            return "同步错误"
        }
    }
}