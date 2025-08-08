//
//  ModernCanvasMainView.swift
//  prismNg
//
//  Main canvas view with all original functionality
//

import SwiftUI
import SwiftData

// MARK: - Main Canvas View
struct ModernCanvasMainView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var thoughtNodes: [ThoughtNode]
    @Query private var connections: [NodeConnection]
    
    @StateObject private var canvasState = ModernCanvasState()
    @StateObject private var driftEngine = DriftModeEngine()
    
    var body: some View {
        ZStack {
            // Background Canvas
            ModernCanvasBackground(
                canvasOffset: canvasState.canvasOffset,
                canvasScale: canvasState.canvasScale
            )
            
            // Main Canvas Content
            ModernCanvasContent(
                nodes: thoughtNodes,
                connections: connections,
                canvasState: canvasState,
                driftEngine: driftEngine
            )
            
            // UI Overlays
            ModernCanvasOverlays(
                canvasState: canvasState,
                nodes: thoughtNodes,
                connections: connections
            )
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            setupCanvas()
        }
    }
    
    private func setupCanvas() {
        canvasState.initialize(with: thoughtNodes, connections: connections)
        if canvasState.driftModeActive {
            driftEngine.startDriftMode(for: thoughtNodes)
        }
    }
}

// MARK: - Canvas State
class ModernCanvasState: ObservableObject {
    // Canvas Transform
    @Published var canvasOffset = CGSize.zero
    @Published var canvasScale: CGFloat = 1.0
    
    // Selection
    @Published var selectedNodes: Set<ThoughtNode> = []
    @Published var hoveredNode: ThoughtNode?
    @Published var selectionRect: CGRect?
    
    // Tools & Modes
    @Published var currentTool: CanvasTool = .select
    @Published var cognitiveGear: CognitiveGear = .capture
    @Published var driftModeActive = false
    
    // UI States
    @Published var showToolbar = true
    @Published var showMinimap = true
    @Published var showSearch = false
    @Published var showAIPanel = false
    @Published var searchQuery = ""
    
    // AI & Suggestions
    @Published var aiSuggestions: [AISuggestion] = []
    @Published var resonanceConnections: Set<String> = []
    
    // Drag States
    @Published var isDragging = false
    @Published var dragStartLocation = CGPoint.zero
    
    // Animation
    @Published var pulseAnimation = false
    
    func initialize(with nodes: [ThoughtNode], connections: [NodeConnection]) {
        // Initial setup if needed
    }
    
    func resetCanvas() {
        withAnimation(.spring()) {
            canvasOffset = .zero
            canvasScale = 1.0
        }
    }
    
    func focusOnNode(_ node: ThoughtNode) {
        withAnimation(.spring()) {
            canvasOffset = CGSize(
                width: -node.position.x + UIScreen.main.bounds.width / 2,
                height: -node.position.y + UIScreen.main.bounds.height / 2
            )
            canvasScale = 1.5
        }
        selectedNodes = [node]
    }
}

// MARK: - Canvas Tool
enum CanvasTool: String, CaseIterable {
    case select = "arrow.up.left"
    case pan = "hand.draw"
    case connect = "link"
    case text = "text.cursor"
    case sticky = "note"
    
    var displayName: String {
        switch self {
        case .select: return "Select"
        case .pan: return "Pan"
        case .connect: return "Connect"
        case .text: return "Text"
        case .sticky: return "Sticky"
        }
    }
}

// MARK: - AI Suggestion
struct AISuggestion: Identifiable {
    let id = UUID()
    let type: SuggestionType
    let content: String
    let confidence: Double
    let sourceNodes: [UUID]
    
    enum SuggestionType {
        case connection
        case insight
        case question
        case structure
    }
}