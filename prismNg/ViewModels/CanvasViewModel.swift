//
//  CanvasViewModel.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import SwiftData
import SpriteKit
import Combine

@MainActor
class CanvasViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var thoughtNodes: [ThoughtNode] = []
    @Published var selectedNodeId: UUID?
    @Published var showTraditionalUI: Bool = true
    @Published var currentCognitiveGear: CognitiveGear = .capture
    @Published var isCreatingNode: Bool = false
    @Published var showSearch: Bool = false
    @Published var editingNode: ThoughtNode?
    @Published var showVoiceInput: Bool = false
    @Published var showEmotionalInsights: Bool = false
    
    // Radial Menu
    @Published var showRadialMenu: Bool = false
    @Published var radialMenuLocation: CGPoint = .zero
    @Published var radialMenuSelectedAngle: Double?
    
    // Context Menu
    @Published var showContextMenu: Bool = false
    @Published var contextMenuLocation: CGPoint = .zero
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private var userConfiguration: UserConfiguration?
    weak var scene: InfiniteCanvasScene?
    
    // MARK: - Services
    private let persistenceService: PersistenceService
    private let aiService: AIService
    let vectorService: VectorDBService
    let coreMLService: CoreMLEmbeddingService
    let embeddingManager: EmbeddingManager
    let associationService: AssociationRecommendationService
    @Published var interactionService: InteractionPreferenceService
    @Published var quotaService: QuotaManagementService
    @Published var cognitiveEngine: CognitiveFlowStateEngine
    @Published var cloudSyncManager: CloudSyncManager
    @Published var aiLensService: AILensService? = nil
    @Published var emotionalService: EmotionalComputingService
    @Published var forgettingService: MemoryForgettingService
    
    // Growth Optimization
    private var growthOptimizationService: GrowthOptimizationService?
    
    init(
        persistenceService: PersistenceService = PersistenceService(),
        aiService: AIService = AIService(),
        vectorService: VectorDBService = VectorDBService(),
        coreMLService: CoreMLEmbeddingService = CoreMLEmbeddingService(),
        associationService: AssociationRecommendationService = AssociationRecommendationService(),
        interactionService: InteractionPreferenceService = InteractionPreferenceService(),
        quotaService: QuotaManagementService = QuotaManagementService(),
        cognitiveEngine: CognitiveFlowStateEngine = CognitiveFlowStateEngine(),
        cloudSyncManager: CloudSyncManager = CloudSyncManager(),
        emotionalService: EmotionalComputingService = EmotionalComputingService(),
        forgettingService: MemoryForgettingService = MemoryForgettingService()
    ) {
        self.persistenceService = persistenceService
        self.aiService = aiService
        self.vectorService = vectorService
        self.coreMLService = coreMLEmbeddingService
        self.associationService = associationService
        self.interactionService = interactionService
        self.quotaService = quotaService
        self.cognitiveEngine = cognitiveEngine
        self.cloudSyncManager = cloudSyncManager
        self.emotionalService = emotionalService
        self.forgettingService = forgettingService

        // Initialize embedding manager with services
        self.embeddingManager = EmbeddingManager(
            embeddingService: coreMLService,
            vectorDB: vectorService
        )
    }
    
    // MARK: - Setup
    func setup(modelContext: ModelContext, nodes: [ThoughtNode], growthService: GrowthOptimizationService? = nil) {
        self.modelContext = modelContext
        self.growthOptimizationService = growthService
        self.cloudSyncManager.setup(modelContext: modelContext)
        self.aiLensService = AILensService(quotaService: quotaService, vectorService: vectorService)
        self.emotionalService.setup(modelContext: modelContext)
        self.forgettingService.setup(modelContext: modelContext)
        self.thoughtNodes = nodes
        
        // Setup association service
        associationService.setup(modelContext: modelContext)
        
        // Load or create user configuration
        loadUserConfiguration()
        
        // Setup interaction preference service
        if let userConfig = userConfiguration {
            interactionService.setup(modelContext: modelContext, userConfiguration: userConfig)
            quotaService.setup(modelContext: modelContext, userConfiguration: userConfig)
        }
        
        // Setup nodes in scene
        setupNodesInScene()
        
        // Start real-time embedding indexing
        embeddingManager.startRealtimeIndexing(for: nodes)
    }
    
    private func loadUserConfiguration() {
        guard let modelContext = modelContext else { return }
        
        let request = FetchDescriptor<UserConfiguration>()
        if let configs = try? modelContext.fetch(request), let config = configs.first {
            userConfiguration = config
            showTraditionalUI = config.interactionMode == .traditional || config.interactionMode == .adaptive
            currentCognitiveGear = config.cognitiveGear
        } else {
            // Create default configuration
            let config = UserConfiguration()
            modelContext.insert(config)
            userConfiguration = config
            try? modelContext.save()
        }
    }
    
    private func setupNodesInScene() {
        thoughtNodes.forEach { node in
            scene?.addNodeSprite(for: node)
        }
    }
    
    // MARK: - Node Management
    func updateNodes(_ newNodes: [ThoughtNode]) {
        let oldNodes = Set(thoughtNodes.map { $0.id })
        let newNodeSet = Set(newNodes.map { $0.id })
        
        // Remove deleted nodes from scene
        let deletedNodes = oldNodes.subtracting(newNodeSet)
        deletedNodes.forEach { nodeId in
            scene?.removeNodeSprite(nodeId: nodeId)
        }
        
        // Add new nodes to scene
        let addedNodes = newNodeSet.subtracting(oldNodes)
        newNodes.filter { addedNodes.contains($0.id) }.forEach { node in
            scene?.addNodeSprite(for: node)
        }
        
        // Update existing nodes
        let existingNodes = oldNodes.intersection(newNodeSet)
        newNodes.filter { existingNodes.contains($0.id) }.forEach { node in
            scene?.updateNodeSprite(for: node)
        }
        
        thoughtNodes = newNodes
    }
    
    func createNodeAtCenter(type: NodeType) {
        guard let scene = scene else { return }
        
        let startTime = Date()
        let centerPosition = scene.camera?.position ?? CGPoint.zero
        createNode(
            content: type == .question ? "What if..." : "New thought",
            type: type,
            position: Position(x: centerPosition.x, y: centerPosition.y)
        )
        
        // Track traditional UI interaction
        let duration = Date().timeIntervalSince(startTime)
        interactionService.trackTraditionalUIInteraction(action: .buttonTap, success: true, duration: duration)
    }
    
    func createNodeWithVoiceInput(type: NodeType = .thought) {
        showVoiceInput = true
    }
    
    func createNodeFromVoiceInput(content: String, type: NodeType = .thought) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard let scene = scene else { return }
        
        let centerPosition = scene.camera?.position ?? CGPoint.zero
        createNode(
            content: content,
            type: type,
            position: Position(x: centerPosition.x, y: centerPosition.y)
        )
        showVoiceInput = false
    }
    
    func createNode(content: String, type: NodeType, position: Position) {
        guard let modelContext = modelContext else { return }
        
        let node = ThoughtNode(
            content: content,
            nodeType: type,
            position: position
        )
        
        modelContext.insert(node)
        
        // Track node creation for growth optimization
        growthOptimizationService?.trackNodeCreation()
        
        do {
            try modelContext.save()
            
            // Track action for cognitive flow analysis
            cognitiveEngine.trackAction(UserAction(
                type: .nodeCreation,
                timestamp: Date(),
                duration: nil,
                detail: content
            ))
            
            // Generate embedding asynchronously
            Task {
                // Index node with embedding manager
                await embeddingManager.indexNode(node)
                
                // Sync to cloud
                await cloudSyncManager.syncNode(node)
            }
        } catch {
            print("Error saving node: \(error)")
        }
    }
    
    func updateNodePosition(_ nodeId: UUID, position: Position) {
        guard let modelContext = modelContext,
              let node = thoughtNodes.first(where: { $0.id == nodeId }) else { return }
        
        node.position = position
        node.updatedAt = Date()
        
        try? modelContext.save()
    }
    
    func deleteNode(_ nodeId: UUID) {
        guard let modelContext = modelContext,
              let node = thoughtNodes.first(where: { $0.id == nodeId }) else { return }
        
        modelContext.delete(node)
        try? modelContext.save()
    }
    
    // MARK: - Node Selection
    func selectNode(_ nodeId: UUID) {
        selectedNodeId = nodeId
        
        // Track action for cognitive flow analysis
        cognitiveEngine.trackAction(UserAction(
            type: .navigation,
            timestamp: Date(),
            duration: nil,
            detail: "node_selection"
        ))
        
        // Trigger association analysis for the selected node
        if let selectedNode = thoughtNodes.first(where: { $0.id == nodeId }) {
            Task {
                await associationService.analyzeNodeAssociations(for: selectedNode, in: thoughtNodes)
            }
        }
    }
    
    func deselectAllNodes() {
        selectedNodeId = nil
        associationService.clearRecommendations()
    }
    
    func editNode(_ nodeId: UUID) {
        if let node = thoughtNodes.first(where: { $0.id == nodeId }) {
            editingNode = node
        }
    }
    
    func trackNodeEdit(_ node: ThoughtNode, editDuration: TimeInterval, newContent: String) {
        // Track action for cognitive flow analysis
        cognitiveEngine.trackAction(UserAction(
            type: .nodeEdit,
            timestamp: Date(),
            duration: editDuration,
            detail: newContent
        ))
    }
    
    func trackSearch(_ query: String) {
        // Track search action
        cognitiveEngine.trackAction(UserAction(
            type: .search,
            timestamp: Date(),
            duration: nil,
            detail: query
        ))
    }
    
    // MARK: - Cognitive Mode Management
    func switchToCognitiveMode(_ mode: CognitiveMode) {
        // Track mode switch
        cognitiveEngine.trackAction(UserAction(
            type: .modeSwitch,
            timestamp: Date(),
            duration: nil,
            detail: mode.rawValue
        ))
        
        // Apply mode-specific settings
        switch mode {
        case .incubation:
            // Enable drift mode
            currentCognitiveGear = .muse
            scene?.enableDriftMode(true)
            
        case .exploration:
            // Enable focus mode
            currentCognitiveGear = .inquiry
            scene?.enableDriftMode(false)
            
        case .retrieval:
            // Show search
            showSearch = true
            
        case .association:
            // Enable association features
            currentCognitiveGear = .muse
            break
            
        case .capture:
            // Enable capture mode
            currentCognitiveGear = .capture
            break
        }
    }
    
    func createConnection(from fromNodeId: UUID, to toNodeId: UUID, type: AssociationType) {
        guard let modelContext = modelContext else { return }
        
        // Convert AssociationType to ConnectionType
        let connectionType: ConnectionType
        switch type {
        case .strongSupport:
            connectionType = .strongSupport
        case .weakAssociation:
            connectionType = .weakAssociation
        case .similarity:
            connectionType = .similarity
        case .contextual, .temporal, .emotional:
            connectionType = .weakAssociation // Map other types to weak association
        }
        
        let connection = NodeConnection(
            fromNodeId: fromNodeId,
            toNodeId: toNodeId,
            connectionType: connectionType,
            strength: 0.7,
            isAIGenerated: true,
            sourceNodeIds: [fromNodeId]
        )
        
        modelContext.insert(connection)
        
        do {
            try modelContext.save()
        } catch {
            print("Error creating connection: \(error)")
        }
    }
    
    // MARK: - Gesture Handling
    func handleLongPress(at location: CGPoint) {
        let startTime = Date()
        
        // Check interaction preference
        if interactionService.currentPreference == .traditional {
            // Show context menu in traditional mode
            showContextMenu(at: location)
        } else {
            // Show radial menu in gesture/adaptive mode
            showRadialMenu(at: location)
        }
        
        // Track gesture interaction
        let duration = Date().timeIntervalSince(startTime)
        interactionService.trackGestureInteraction(type: .longPress, success: true, duration: duration)
    }
    
    // MARK: - Radial Menu
    func showRadialMenu(at location: CGPoint) {
        radialMenuLocation = location
        showRadialMenu = true
    }
    
    func hideRadialMenu() {
        showRadialMenu = false
        radialMenuSelectedAngle = nil
    }
    
    func updateRadialMenuSelection(angle: Double) {
        radialMenuSelectedAngle = angle
    }
    
    func executeRadialMenuSelection(angle: Double) {
        // Determine which menu item was selected based on angle
        let normalizedAngle = angle.truncatingRemainder(dividingBy: 2 * .pi)
        
        // Map angle to menu items (4 quadrants)
        let nodeType: NodeType
        let content: String
        
        if normalizedAngle >= -0.785 && normalizedAngle < 0.785 {
            // Right: Text thought
            nodeType = .thought
            content = ""
        } else if normalizedAngle >= 0.785 && normalizedAngle < 2.356 {
            // Bottom: Voice input
            showVoiceInput = true
            hideRadialMenu()
            return
        } else if normalizedAngle >= -2.356 && normalizedAngle < -0.785 {
            // Top: Question
            nodeType = .question
            content = "What if..."
        } else {
            // Left: Insight
            nodeType = .insight
            content = "💡 "
        }
        
        // Create node at menu location
        createNode(
            content: content,
            type: nodeType,
            position: Position(x: radialMenuLocation.x, y: radialMenuLocation.y)
        )
        
        hideRadialMenu()
    }
    
    // MARK: - Context Menu
    func showContextMenu(at location: CGPoint) {
        contextMenuLocation = location
        showContextMenu = true
    }
    
    func hideContextMenu() {
        showContextMenu = false
    }
    
    // MARK: - AI Features
    func triggerAILens() {
        guard let selectedNodeId = selectedNodeId,
              let selectedNode = thoughtNodes.first(where: { $0.id == selectedNodeId }) else {
            // If no node selected, analyze all visible nodes
            analyzeAllVisibleNodes()
            return
        }
        
        // Analyze selected node and its context
        Task {
            await analyzeNodeContext(selectedNode)
        }
    }
    
    private func analyzeAllVisibleNodes() {
        // TODO: Implement global analysis
        print("Analyzing all visible nodes...")
    }
    
    private func analyzeNodeContext(_ node: ThoughtNode) async {
        guard let modelContext = modelContext else { return }
        
        // Check AI quota using quota service
        guard quotaService.canUseAI() else {
            // Quota exceeded - alert will be shown by quota service
            return
        }
        
        // Increment quota usage
        guard quotaService.incrementQuotaUsage() else {
            return
        }
        
        // Find related nodes using vector search
        let relatedNodes = await findRelatedNodes(to: node)
        
        // Create AI task
        let aiTask = AITask(
            taskType: .structureAnalysis,
            inputNodeIds: [node.id] + relatedNodes.map { $0.id }
        )
        modelContext.insert(aiTask)
        
        do {
            try modelContext.save()
            
            // Execute AI analysis
            await executeStructureAnalysis(task: aiTask, centerNode: node, relatedNodes: relatedNodes)
            
        } catch {
            print("Error creating AI task: \(error)")
        }
    }
    
    private func executeStructureAnalysis(task: AITask, centerNode: ThoughtNode, relatedNodes: [ThoughtNode]) async {
        guard let modelContext = modelContext else { return }
        
        // Update task status
        task.status = .running
        task.startedAt = Date()
        try? modelContext.save()
        
        do {
            // Call AI service for structure analysis
            let analysis = try await aiService.analyzeStructure(
                centerNode: centerNode,
                relatedNodes: relatedNodes
            )
            
            // Create result nodes and connections
            await createAnalysisResults(analysis: analysis, sourceNodes: [centerNode] + relatedNodes)
            
            // Mark task as completed
            task.status = .success
            task.completedAt = Date()
            
        } catch {
            // Mark task as failed
            task.status = .failed
            task.error = error.localizedDescription
        }
        
        try? modelContext.save()
    }
    
    private func createAnalysisResults(analysis: StructureAnalysis, sourceNodes: [ThoughtNode]) async {
        guard let modelContext = modelContext else { return }
        
        // Create conclusion node if analysis found insights
        if let conclusion = analysis.conclusion {
            let conclusionNode = ThoughtNode(
                content: conclusion,
                nodeType: .conclusion,
                position: Position(x: 0, y: -100), // Position relative to center
                isAIGenerated: true,
                sourceNodeIds: sourceNodes.map { $0.id }
            )
            modelContext.insert(conclusionNode)
        }
        
        // Create connection nodes for relationships
        for relationship in analysis.relationships {
            if let fromNode = sourceNodes.first(where: { $0.id == relationship.fromNodeId }),
               let toNode = sourceNodes.first(where: { $0.id == relationship.toNodeId }) {
                
                let connection = NodeConnection(
                    fromNodeId: fromNode.id,
                    toNodeId: toNode.id,
                    connectionType: relationship.type,
                    strength: relationship.strength,
                    isAIGenerated: true,
                    sourceNodeIds: sourceNodes.map { $0.id }
                )
                modelContext.insert(connection)
            }
        }
        
        try? modelContext.save()
    }
    
    // MARK: - AI Service Integration
    private func generateEmbedding(for node: ThoughtNode) async {
        guard let modelContext = modelContext else { return }
        
        do {
            let embedding = try await aiService.generateEmbedding(for: node.content)
            try await vectorService.addVector(embedding, for: node.id)
            
            // Update node to indicate it has embedding
            node.hasEmbedding = true
            node.embeddingVersion = "1.0"
            try modelContext.save()
            
        } catch {
            print("Error generating embedding: \(error)")
        }
    }
    
    private func findRelatedNodes(to node: ThoughtNode) async -> [ThoughtNode] {
        guard node.hasEmbedding else { return [] }
        
        do {
            let relatedIds = try await vectorService.findSimilar(to: node.id, limit: 5)
            return thoughtNodes.filter { relatedIds.contains($0.id) }
        } catch {
            print("Error finding related nodes: \(error)")
            return []
        }
    }
    
    
    // MARK: - UI State Management
    func toggleSearch() {
        showSearch.toggle()
    }
    
    func switchCognitiveGear(to gear: CognitiveGear) {
        currentCognitiveGear = gear
        userConfiguration?.cognitiveGear = gear
        try? modelContext?.save()
    }
    
    func toggleInteractionMode() {
        let newMode: InteractionMode = showTraditionalUI ? .gesture : .traditional
        showTraditionalUI = !showTraditionalUI
        userConfiguration?.interactionMode = newMode
        try? modelContext?.save()
    }
}

// MARK: - Supporting Types
struct StructureAnalysis {
    let conclusion: String?
    let relationships: [NodeRelationship]
}

struct NodeRelationship {
    let fromNodeId: UUID
    let toNodeId: UUID
    let type: ConnectionType
    let strength: Double
}