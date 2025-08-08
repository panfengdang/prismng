//
//  ModernCanvasContent.swift
//  prismNg
//
//  Canvas content with nodes and connections
//

import SwiftUI
import SwiftData

struct ModernCanvasContent: View {
    let nodes: [ThoughtNode]
    let connections: [NodeConnection]
    @ObservedObject var canvasState: ModernCanvasState
    @ObservedObject var driftEngine: DriftModeEngine
    
    @Environment(\.modelContext) private var modelContext
    @State private var draggedNode: ThoughtNode?
    @State private var nodeOffsets: [UUID: CGSize] = [:]
    @State private var showingNodeEditor = false
    @State private var editingNode: ThoughtNode?
    @State private var showingVoiceInput = false
    @State private var newNodePosition = CGPoint.zero
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Connections Layer
                ForEach(connections) { connection in
                    if let fromNode = nodes.first(where: { $0.id == connection.fromNodeId }),
                       let toNode = nodes.first(where: { $0.id == connection.toNodeId }) {
                        ModernConnectionView(
                            from: nodePosition(fromNode, in: geometry),
                            to: nodePosition(toNode, in: geometry),
                            connection: connection,
                            isResonating: canvasState.resonanceConnections.contains(connection.id.uuidString)
                        )
                    }
                }
                
                // Nodes Layer
                ForEach(nodes) { node in
                    ModernNodeViewComplete(
                        node: node,
                        isSelected: canvasState.selectedNodes.contains(node),
                        isHovered: canvasState.hoveredNode == node,
                        cognitiveGear: canvasState.cognitiveGear,
                        scale: canvasState.canvasScale,
                        offset: nodeOffsets[node.id] ?? .zero,
                        isDrifting: canvasState.driftModeActive
                    )
                    .position(nodePosition(node, in: geometry))
                    .scaleEffect(canvasState.canvasScale)
                    .onTapGesture {
                        handleNodeTap(node)
                    }
                    .onTapGesture(count: 2) {
                        handleNodeDoubleTap(node)
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                handleNodeDragChanged(node, value: value)
                            }
                            .onEnded { value in
                                handleNodeDragEnded(node, value: value)
                            }
                    )
                    .onHover { isHovered in
                        canvasState.hoveredNode = isHovered ? node : nil
                    }
                }
                
                // Selection Rectangle
                if let rect = canvasState.selectionRect {
                    SelectionRectangle(rect: rect)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if canvasState.currentTool == .pan {
                            canvasState.canvasOffset = CGSize(
                                width: value.translation.width,
                                height: value.translation.height
                            )
                        } else if canvasState.currentTool == .select {
                            updateSelectionRect(with: value)
                        }
                    }
                    .onEnded { value in
                        if canvasState.currentTool == .select {
                            finalizeSelection()
                        } else if canvasState.currentTool == .text {
                            // Create text node at tap location
                            let location = value.location
                            createNode(with: "新想法", at: location)
                        }
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        canvasState.canvasScale = value
                    }
            )
            .onTapGesture(count: 2) {
                // Double tap to create node with voice
                if canvasState.currentTool == .text {
                    newNodePosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                    showingVoiceInput = true
                }
            }
        }
        .sheet(isPresented: $showingNodeEditor) {
            if let node = editingNode {
                NodeFullEditorView(node: node, modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputSheet(
                recognizer: speechRecognizer,
                onComplete: { text in
                    createNode(with: text, at: newNodePosition)
                    showingVoiceInput = false
                }
            )
        }
    }
    
    // MARK: - Position Calculations
    
    private func nodePosition(_ node: ThoughtNode, in geometry: GeometryProxy) -> CGPoint {
        let offset = nodeOffsets[node.id] ?? .zero
        return CGPoint(
            x: node.position.x + canvasState.canvasOffset.width + offset.width,
            y: node.position.y + canvasState.canvasOffset.height + offset.height
        )
    }
    
    // MARK: - Interaction Handlers
    
    private func handleNodeTap(_ node: ThoughtNode) {
        withAnimation(.spring(response: 0.3)) {
            if canvasState.selectedNodes.contains(node) {
                canvasState.selectedNodes.remove(node)
            } else {
                canvasState.selectedNodes.insert(node)
            }
        }
    }
    
    private func handleNodeDoubleTap(_ node: ThoughtNode) {
        editingNode = node
        showingNodeEditor = true
    }
    
    private func handleNodeDragChanged(_ node: ThoughtNode, value: DragGesture.Value) {
        nodeOffsets[node.id] = value.translation
        draggedNode = node
    }
    
    private func handleNodeDragEnded(_ node: ThoughtNode, value: DragGesture.Value) {
        let finalOffset = value.translation
        
        // Update node position in model
        node.position = Position(
            x: node.position.x + finalOffset.width / canvasState.canvasScale,
            y: node.position.y + finalOffset.height / canvasState.canvasScale
        )
        
        // Reset temporary offset
        withAnimation(.spring()) {
            nodeOffsets[node.id] = .zero
        }
        
        draggedNode = nil
    }
    
    private func updateSelectionRect(with value: DragGesture.Value) {
        let rect = CGRect(
            x: min(value.startLocation.x, value.location.x),
            y: min(value.startLocation.y, value.location.y),
            width: abs(value.location.x - value.startLocation.x),
            height: abs(value.location.y - value.startLocation.y)
        )
        canvasState.selectionRect = rect
    }
    
    private func finalizeSelection() {
        guard let rect = canvasState.selectionRect else { return }
        
        // Select nodes within rectangle
        canvasState.selectedNodes = Set(nodes.filter { node in
            let nodePos = CGPoint(
                x: node.position.x + canvasState.canvasOffset.width,
                y: node.position.y + canvasState.canvasOffset.height
            )
            return rect.contains(nodePos)
        })
        
        canvasState.selectionRect = nil
    }
    
    private func createNode(with content: String, at position: CGPoint) {
        let adjustedPosition = CGPoint(
            x: (position.x - canvasState.canvasOffset.width) / canvasState.canvasScale,
            y: (position.y - canvasState.canvasOffset.height) / canvasState.canvasScale
        )
        
        let node = ThoughtNode(
            content: content,
            nodeType: .thought,
            position: Position(x: adjustedPosition.x, y: adjustedPosition.y)
        )
        modelContext.insert(node)
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct ModernNodeViewComplete: View {
    let node: ThoughtNode
    let isSelected: Bool
    let isHovered: Bool
    let cognitiveGear: CognitiveGear
    let scale: CGFloat
    let offset: CGSize
    let isDrifting: Bool
    
    @State private var isPulsing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: node.nodeType.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(nodeTypeColor)
                
                if node.isAIGenerated {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.purple)
                }
                
                Spacer()
                
                Text(node.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            // Content
            Text(node.content)
                .font(.system(size: 14))
                .lineLimit(cognitiveGear == .capture ? 3 : nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Metadata - removed importanceScore check
        }
        .padding(12)
        .frame(width: nodeWidth)
        .background(nodeBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: shadowColor, radius: isHovered ? 8 : 4, x: 0, y: isHovered ? 4 : 2)
        .scaleEffect(isPulsing && isDrifting ? 1.05 : 1.0)
        .offset(offset)
        .onAppear {
            if isDrifting {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
        }
    }
    
    private var nodeWidth: CGFloat {
        switch cognitiveGear {
        case .capture: return 200
        case .muse: return 250
        case .inquiry: return 300
        case .synthesis: return 280
        case .reflection: return 260
        }
    }
    
    private var nodeTypeColor: Color {
        switch node.nodeType {
        case .thought: return .blue
        case .question: return .orange
        case .insight: return .purple
        case .conclusion: return .red
        case .contradiction: return .yellow
        case .structure: return .green
        }
    }
    
    private var nodeBackground: some View {
        Group {
            if node.isAIGenerated {
                LinearGradient(
                    colors: [Color.purple.opacity(0.05), Color.blue.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(.systemBackground)
            }
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if isHovered {
            return nodeTypeColor.opacity(0.6)
        } else {
            return Color.primary.opacity(0.1)
        }
    }
    
    private var borderWidth: CGFloat {
        isSelected ? 2 : 1
    }
    
    private var shadowColor: Color {
        if isSelected {
            return Color.blue.opacity(0.3)
        } else if node.isAIGenerated {
            return Color.purple.opacity(0.2)
        } else {
            return Color.black.opacity(0.1)
        }
    }
}

struct ModernConnectionView: View {
    let from: CGPoint
    let to: CGPoint
    let connection: NodeConnection
    let isResonating: Bool
    
    @State private var animationPhase: CGFloat = 0
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            // Create curved connection
            let controlPoint1 = CGPoint(
                x: from.x + (to.x - from.x) * 0.3,
                y: from.y
            )
            let controlPoint2 = CGPoint(
                x: from.x + (to.x - from.x) * 0.7,
                y: to.y
            )
            
            path.addCurve(to: to, control1: controlPoint1, control2: controlPoint2)
        }
        .stroke(
            connectionColor,
            style: StrokeStyle(
                lineWidth: connectionWidth,
                lineCap: .round,
                lineJoin: .round,
                dash: connection.connectionType == .weakAssociation ? [5, 5] : [],
                dashPhase: isResonating ? animationPhase : 0
            )
        )
        .onAppear {
            if isResonating {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    animationPhase = 10
                }
            }
        }
    }
    
    private var connectionColor: Color {
        if isResonating {
            return .yellow
        } else if connection.isAIGenerated {
            return .purple.opacity(0.5)
        } else {
            switch connection.connectionType {
            case .strongSupport: return .green.opacity(0.7)
            case .weakAssociation: return .gray.opacity(0.4)
            case .contradiction: return .red.opacity(0.6)
            case .similarity: return .blue.opacity(0.5)
            case .causality: return .orange.opacity(0.6)
            case .resonance: return .yellow.opacity(0.7)
            }
        }
    }
    
    private var connectionWidth: CGFloat {
        switch connection.connectionType {
        case .strongSupport: return 2
        case .weakAssociation: return 1
        case .contradiction: return 1.5
        case .similarity: return 1
        case .causality: return 1.5
        case .resonance: return 2
        }
    }
}

struct SelectionRectangle: View {
    let rect: CGRect
    
    var body: some View {
        Rectangle()
            .fill(Color.blue.opacity(0.1))
            .overlay(
                Rectangle()
                    .stroke(Color.blue, lineWidth: 1)
                    .background(
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundColor(.white)
                    )
            )
            .frame(width: rect.width, height: rect.height)
            .position(x: rect.midX, y: rect.midY)
    }
}

