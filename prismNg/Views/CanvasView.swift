//
//  CanvasView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import SpriteKit
import SwiftData

// MARK: - Main Canvas View
struct CanvasView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var thoughtNodes: [ThoughtNode]
    @Query private var userConfig: [UserConfiguration]
    @EnvironmentObject var interactionService: InteractionPreferenceService
    @EnvironmentObject var growthOptimizationService: GrowthOptimizationService
    
    @StateObject private var canvasViewModel = CanvasViewModel()
    @StateObject private var adaptiveModeService = AdaptiveModeService()
    @State private var scene: InfiniteCanvasScene
    @State private var showGestureTutorial = false
    @State private var showMemoryManagement = false
    
    init() {
        let scene = InfiniteCanvasScene()
        self._scene = State(initialValue: scene)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Canvas Layer
                SpriteView(scene: scene)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .onAppear {
                        setupScene(geometry: geometry)
                        // Setup canvas view model with growth tracking
                        canvasViewModel.setup(
                            modelContext: modelContext,
                            nodes: Array(thoughtNodes),
                            growthService: growthOptimizationService
                        )
                    }
                
                // SwiftUI Overlay Layer for UI controls
                CanvasOverlayView(
                    canvasViewModel: canvasViewModel,
                    adaptiveModeService: adaptiveModeService,
                    showMemoryManagement: $showMemoryManagement
                )
                
                // Association Recommendations Panel
                FloatingAssociationPanel(
                    associationService: canvasViewModel.associationService,
                    thoughtNodes: thoughtNodes,
                    onNodeSelected: { nodeId in
                        canvasViewModel.selectNode(nodeId)
                    },
                    onCreateConnection: { fromId, toId, connectionType in
                        // Convert ConnectionType to AssociationType
                        let associationType: AssociationType
                        switch connectionType {
                        case .strongSupport:
                            associationType = .strongSupport
                        case .weakAssociation:
                            associationType = .weakAssociation
                        case .similarity:
                            associationType = .similarity
                        case .causality:
                            associationType = .contextual
                        case .contradiction:
                            associationType = .contextual
                        case .resonance:
                            associationType = .emotional
                        }
                        canvasViewModel.createConnection(from: fromId, to: toId, type: associationType)
                    }
                )
            }
            .radialMenu(
                isPresented: $canvasViewModel.showRadialMenu,
                location: $canvasViewModel.radialMenuLocation,
                onSelection: { item in
                    handleRadialMenuSelection(item)
                }
            )
        }
        .sheet(item: $canvasViewModel.editingNode) { node in
            NodeEditView(
                node: node,
                onSave: {
                    canvasViewModel.editingNode = nil
                },
                onDelete: {
                    canvasViewModel.editingNode = nil
                }
            )
        }
        .sheet(isPresented: $canvasViewModel.showVoiceInput) {
            VoiceInputView(
                text: .constant(""),
                isPresented: $canvasViewModel.showVoiceInput
            ) { recognizedText in
                canvasViewModel.createNodeFromVoiceInput(content: recognizedText)
            }
        }
        .sheet(isPresented: $canvasViewModel.interactionService.showOnboarding) {
            InteractionOnboardingView(
                preferenceService: canvasViewModel.interactionService,
                isPresented: $canvasViewModel.interactionService.showOnboarding
            )
        }
        .onAppear {
            canvasViewModel.setup(modelContext: modelContext, nodes: thoughtNodes)
            adaptiveModeService.setup(interactionService: interactionService)
            
            // Show gesture tutorial if user selected gesture mode
            if interactionService.currentPreference == .gesture && 
               UserDefaults.standard.bool(forKey: "hasShownGestureTutorial") == false {
                showGestureTutorial = true
            }
        }
        .sheet(isPresented: $showGestureTutorial) {
            GestureTutorialView(isPresented: $showGestureTutorial)
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasShownGestureTutorial")
                }
        }
        .onChange(of: thoughtNodes) { _, newNodes in
            canvasViewModel.updateNodes(newNodes)
        }
    }
    
    private func setupScene(geometry: GeometryProxy) {
        scene.size = geometry.size
        scene.scaleMode = .resizeFill
        scene.canvasViewModel = canvasViewModel
        scene.interactionService = interactionService
        canvasViewModel.scene = scene
    }
    
    private func handleRadialMenuSelection(_ item: RadialMenuItem) {
        switch item.id {
        case "text":
            canvasViewModel.createNode(
                content: "",
                type: .thought,
                position: Position(
                    x: canvasViewModel.radialMenuLocation.x,
                    y: canvasViewModel.radialMenuLocation.y
                )
            )
        case "voice":
            canvasViewModel.showVoiceInput = true
        case "question":
            canvasViewModel.createNode(
                content: "What if...",
                type: .question,
                position: Position(
                    x: canvasViewModel.radialMenuLocation.x,
                    y: canvasViewModel.radialMenuLocation.y
                )
            )
        case "insight":
            canvasViewModel.createNode(
                content: "💡 ",
                type: .insight,
                position: Position(
                    x: canvasViewModel.radialMenuLocation.x,
                    y: canvasViewModel.radialMenuLocation.y
                )
            )
        default:
            break
        }
    }
}

// MARK: - Canvas Overlay for SwiftUI Controls
struct CanvasOverlayView: View {
    @ObservedObject var canvasViewModel: CanvasViewModel
    @ObservedObject var adaptiveModeService: AdaptiveModeService
    @State private var showSettings = false
    @Binding var showMemoryManagement: Bool
    
    var body: some View {
        ZStack {
            VStack {
                // Top Navigation Bar
                HStack {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Cloud Sync Status
                    if canvasViewModel.cloudSyncManager.selectedProvider != .none {
                        SyncStatusView(syncService: canvasViewModel.cloudSyncManager.firebaseService)
                            .padding(.trailing, 8)
                    }
                    
                    // Quota Indicator
                    QuotaIndicatorView(quotaService: canvasViewModel.quotaService)
                        .padding(.trailing, 8)
                    
                    // Cognitive Gear Indicator
                    HStack {
                        Image(systemName: cognitiveGearIcon)
                            .foregroundColor(.blue)
                        Text(canvasViewModel.currentCognitiveGear.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                }
                .padding()
                
                // Search Button
                Button {
                    canvasViewModel.showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .padding(.trailing)
                
                // Emotional Insights Button
                Button {
                    canvasViewModel.showEmotionalInsights = true
                } label: {
                    Image(systemName: "heart.circle.fill")
                        .font(.title2)
                        .foregroundColor(.pink)
                }
                .padding(.trailing)
                
                // Memory Management Button
                Button {
                    showMemoryManagement = true
                } label: {
                    Image(systemName: "brain")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                .padding(.trailing)
            }
            
            Spacer()
            
            // Adaptive Mode Recommendation Toast
            if let recommendation = adaptiveModeService.adaptiveRecommendation {
                AdaptiveModeToast(
                    recommendation: AdaptiveModeRecommendation(
                        id: recommendation.id.uuidString,
                        title: "Switch to \(recommendation.suggestedMode.rawValue.capitalized) Mode",
                        description: recommendation.reason,
                        icon: recommendation.suggestedMode == .gesture ? "hand.tap" : "square.grid.2x2",
                        targetMode: adaptiveUIMode(from: recommendation.suggestedMode),
                        triggerReason: recommendation.reason
                    ),
                    onAccept: {
                        adaptiveModeService.applyRecommendation(recommendation)
                        updateUIVisibility()
                    },
                    onDismiss: {
                        adaptiveModeService.dismissRecommendation()
                    }
                )
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Bottom Toolbar (Traditional UI Track)
            if shouldShowToolbar {
                BottomToolbarView(canvasViewModel: canvasViewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        
        // Cognitive Flow Recommendation (top-right corner)
        VStack {
            HStack {
                Spacer()
                CognitiveRecommendationView(engine: canvasViewModel.cognitiveEngine)
                    .onTapGesture {
                        if let recommendation = canvasViewModel.cognitiveEngine.activeRecommendation {
                            canvasViewModel.switchToCognitiveMode(recommendation.mode)
                            canvasViewModel.cognitiveEngine.userAcceptedRecommendation()
                        }
                    }
            }
            Spacer()
        }
        }
        .animation(.easeInOut(duration: 0.3), value: canvasViewModel.showTraditionalUI)
        .animation(.easeInOut(duration: 0.3), value: adaptiveModeService.currentUIMode)
        .sheet(isPresented: $showSettings) {
            SettingsView(
                interactionService: canvasViewModel.interactionService,
                quotaService: canvasViewModel.quotaService,
                cloudSyncManager: canvasViewModel.cloudSyncManager
            )
        }
        .sheet(isPresented: $canvasViewModel.showSearch) {
            SemanticSearchView(canvasViewModel: canvasViewModel)
        }
        .sheet(isPresented: $canvasViewModel.showEmotionalInsights) {
            EmotionalInsightsView(emotionalService: canvasViewModel.emotionalService)
        }
        .sheet(isPresented: $showMemoryManagement) {
            MemoryManagementView(
                forgettingService: canvasViewModel.forgettingService,
                canvasViewModel: canvasViewModel
            )
        }
    }
    
    private var shouldShowToolbar: Bool {
        switch adaptiveModeService.currentUIMode {
        case .traditional:
            return true
        case .gesture:
            return false
        case .hidden:
            return false
        }
    }
    
    private func updateUIVisibility() {
        switch adaptiveModeService.currentUIMode {
        case .traditional:
            canvasViewModel.showTraditionalUI = true
        case .gesture:
            canvasViewModel.showTraditionalUI = false
        case .hidden:
            canvasViewModel.showTraditionalUI = false
        }
    }
    
    private var cognitiveGearIcon: String {
        switch canvasViewModel.currentCognitiveGear {
        case .capture:
            return "pencil.line"
        case .muse:
            return "sparkles"
        case .inquiry:
            return "magnifyingglass"
        case .synthesis:
            return "link"
        case .reflection:
            return "moon.stars"
        }
    }
    
    private func adaptiveUIMode(from uiMode: UIMode) -> AdaptiveUIMode {
        switch uiMode {
        case .traditional:
            return .traditional
        case .gesture:
            return .gesture
        case .hidden:
            return .hidden
        }
    }
}

// MARK: - Bottom Toolbar for Traditional UI Track
struct BottomToolbarView: View {
    @ObservedObject var canvasViewModel: CanvasViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            ToolbarButton(
                icon: "plus.circle.fill",
                title: "Add Thought",
                action: { canvasViewModel.createNodeAtCenter(type: .thought) }
            )
            
            ToolbarButton(
                icon: "questionmark.circle.fill", 
                title: "Add Question",
                action: { canvasViewModel.createNodeAtCenter(type: .question) }
            )
            
            AIFeatureButton(
                title: "AI Lens",
                icon: "link.circle.fill",
                action: { canvasViewModel.triggerAILens() },
                quotaService: canvasViewModel.quotaService
            )
            
            ToolbarButton(
                icon: "magnifyingglass.circle.fill",
                title: "Search",
                action: { canvasViewModel.toggleSearch() }
            )
            
            ToolbarButton(
                icon: "mic.circle.fill",
                title: "Voice",
                action: { canvasViewModel.createNodeWithVoiceInput() }
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
}

struct ToolbarButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.primary)
        }
        .frame(minWidth: 60)
    }
}


#Preview {
    CanvasView()
        .modelContainer(for: [ThoughtNode.self, NodeConnection.self, AITask.self, UserConfiguration.self])
}