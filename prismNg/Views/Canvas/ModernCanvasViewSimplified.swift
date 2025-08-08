//
//  ModernCanvasViewSimplified.swift
//  prismNg
//
//  Simplified Modern Canvas View
//

import SwiftUI
import SwiftData

struct ModernCanvasViewSimplified: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var thoughtNodes: [ThoughtNode]
    @Query private var connections: [NodeConnection]
    
    @State private var canvasOffset = CGSize.zero
    @State private var canvasScale: CGFloat = 1.0
    @State private var selectedNodeId: UUID?
    @State private var cognitiveGear: CognitiveGear = .capture
    @State private var showSearch = false
    
    var body: some View {
        ZStack {
            // Canvas Background
            canvasBackground
            
            // Canvas Content
            canvasContent
                .scaleEffect(canvasScale)
                .offset(canvasOffset)
            
            // Overlays
            VStack {
                // Top Toolbar
                topToolbar
                
                Spacer()
                
                // Bottom Controls
                bottomControls
            }
        }
        .background(Color(.systemGroupedBackground))
        .gesture(magnificationGesture)
        .gesture(panGesture)
    }
    
    private var canvasBackground: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw grid pattern
                let gridSize: CGFloat = 20 * canvasScale
                let offsetX = canvasOffset.width.truncatingRemainder(dividingBy: gridSize)
                let offsetY = canvasOffset.height.truncatingRemainder(dividingBy: gridSize)
                
                for x in stride(from: offsetX, to: size.width, by: gridSize) {
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: size.height))
                        },
                        with: .color(.gray.opacity(0.1)),
                        lineWidth: 0.5
                    )
                }
                
                for y in stride(from: offsetY, to: size.height, by: gridSize) {
                    context.stroke(
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: size.width, y: y))
                        },
                        with: .color(.gray.opacity(0.1)),
                        lineWidth: 0.5
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var canvasContent: some View {
        ZStack {
            // Connections
            ForEach(connections) { connection in
                if let fromNode = thoughtNodes.first(where: { $0.id == connection.fromNodeId }),
                   let toNode = thoughtNodes.first(where: { $0.id == connection.toNodeId }) {
                    SimpleConnectionLine(
                        from: CGPoint(x: fromNode.position.x, y: fromNode.position.y),
                        to: CGPoint(x: toNode.position.x, y: toNode.position.y),
                        connectionType: connection.connectionType,
                        isAIGenerated: connection.isAIGenerated
                    )
                }
            }
            
            // Nodes
            ForEach(thoughtNodes) { node in
                SimpleNodeView(node: node, isSelected: selectedNodeId == node.id)
                    .position(x: node.position.x, y: node.position.y)
                    .onTapGesture {
                        selectedNodeId = node.id
                    }
            }
        }
    }
    
    private var topToolbar: some View {
        HStack {
            // Zoom controls
            HStack(spacing: 8) {
                Button(action: { zoomOut() }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                
                Text("\(Int(canvasScale * 100))%")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 50)
                
                Button(action: { zoomIn() }) {
                    Image(systemName: "plus.magnifyingglass")
                }
            }
            .padding(8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Spacer()
            
            // Cognitive Gear
            Menu {
                ForEach([CognitiveGear.capture, .muse, .inquiry], id: \.self) { gear in
                    Button(action: { cognitiveGear = gear }) {
                        Label(gear.displayName, systemImage: gear.icon)
                    }
                }
            } label: {
                Label(cognitiveGear.displayName, systemImage: cognitiveGear.icon)
                    .padding(8)
                    .background(cognitiveGear.color.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Search
            Button(action: { showSearch.toggle() }) {
                Image(systemName: "magnifyingglass")
                    .padding(8)
                    .background(showSearch ? Color.blue.opacity(0.2) : Color.clear)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    private var bottomControls: some View {
        HStack {
            // Add Node Button
            Button(action: addNewNode) {
                Label("Add Node", systemImage: "plus.circle.fill")
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Node Count
            Text("\(thoughtNodes.count) nodes")
                .font(.caption)
                .padding(8)
                .background(.thinMaterial)
                .clipShape(Capsule())
        }
        .padding()
    }
    
    // MARK: - Gestures
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                canvasScale = value
            }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                canvasOffset = CGSize(
                    width: value.translation.width,
                    height: value.translation.height
                )
            }
    }
    
    // MARK: - Actions
    
    private func zoomIn() {
        withAnimation(.spring(duration: 0.3)) {
            canvasScale = min(5.0, canvasScale + 0.2)
        }
    }
    
    private func zoomOut() {
        withAnimation(.spring(duration: 0.3)) {
            canvasScale = max(0.2, canvasScale - 0.2)
        }
    }
    
    private func addNewNode() {
        let node = ThoughtNode(
            content: "New Thought",
            nodeType: .thought,
            position: Position(x: 400, y: 300)
        )
        modelContext.insert(node)
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct SimpleNodeView: View {
    let node: ThoughtNode
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: node.nodeType.icon)
                    .font(.caption)
                    .foregroundColor(nodeColor)
                
                if node.isAIGenerated {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundColor(.purple)
                }
            }
            
            Text(node.content)
                .font(.system(size: 14))
                .lineLimit(3)
        }
        .padding(12)
        .frame(width: 200)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: isSelected ? 4 : 2)
    }
    
    private var nodeColor: Color {
        switch node.nodeType {
        case .thought: return .blue
        case .question: return .orange
        case .insight: return .purple
        case .conclusion: return .red
        case .contradiction: return .yellow
        case .structure: return .green
        }
    }
}

struct SimpleConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let connectionType: ConnectionType
    let isAIGenerated: Bool
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(
            isAIGenerated ? Color.purple.opacity(0.5) : Color.gray.opacity(0.3),
            style: StrokeStyle(
                lineWidth: connectionType == .strongSupport ? 2 : 1,
                dash: connectionType == .weakAssociation ? [5, 5] : []
            )
        )
    }
}

#Preview {
    ModernCanvasViewSimplified()
        .modelContainer(for: [ThoughtNode.self, NodeConnection.self])
}