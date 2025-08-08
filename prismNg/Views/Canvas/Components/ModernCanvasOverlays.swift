//
//  ModernCanvasOverlays.swift
//  prismNg
//
//  Canvas UI overlays (toolbar, minimap, AI panel, etc.)
//

import SwiftUI

struct ModernCanvasOverlays: View {
    @ObservedObject var canvasState: ModernCanvasState
    let nodes: [ThoughtNode]
    let connections: [NodeConnection]
    
    var body: some View {
        VStack {
            // Top Toolbar
            if canvasState.showToolbar {
                ModernCanvasFullToolbar(canvasState: canvasState)
                    .transition(.move(edge: .top))
            }
            
            Spacer()
            
            // Bottom Controls
            HStack(alignment: .bottom) {
                // Minimap
                if canvasState.showMinimap {
                    MinimapView(
                        nodes: nodes,
                        connections: connections,
                        canvasState: canvasState
                    )
                    .frame(width: 200, height: 150)
                    .transition(.move(edge: .leading))
                }
                
                Spacer()
                
                // Zoom Controls
                ZoomControlsView(canvasState: canvasState)
            }
            .padding()
        }
        
        // Side Panels
        HStack {
            Spacer()
            
            // AI Assistant Panel
            if canvasState.showAIPanel {
                AIAssistantPanelView(
                    nodes: nodes,
                    canvasState: canvasState
                )
                .frame(width: 320)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        
        // Search Overlay
        if canvasState.showSearch {
            SearchOverlayView(
                nodes: nodes,
                canvasState: canvasState
            )
            .transition(.opacity)
        }
    }
}

// MARK: - Full Toolbar
struct ModernCanvasFullToolbar: View {
    @ObservedObject var canvasState: ModernCanvasState
    
    var body: some View {
        HStack(spacing: 16) {
            // Tool Selection
            HStack(spacing: 8) {
                ForEach(CanvasTool.allCases, id: \.self) { tool in
                    CanvasToolButton(
                        icon: tool.rawValue,
                        label: tool.displayName,
                        isSelected: canvasState.currentTool == tool
                    ) {
                        canvasState.currentTool = tool
                    }
                }
            }
            .padding(8)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Divider()
                .frame(height: 30)
            
            // Cognitive Gear Selector
            CognitiveGearSelector(
                currentGear: $canvasState.cognitiveGear,
                driftModeActive: $canvasState.driftModeActive
            )
            
            Spacer()
            
            // Right Side Controls
            HStack(spacing: 12) {
                // AI Toggle
                Button(action: { canvasState.showAIPanel.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("AI")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(canvasState.showAIPanel ? Color.purple : Color.purple.opacity(0.1))
                    .foregroundColor(canvasState.showAIPanel ? .white : .purple)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Search
                Button(action: { canvasState.showSearch.toggle() }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18))
                        .foregroundColor(canvasState.showSearch ? .blue : .primary)
                        .padding(10)
                        .background(canvasState.showSearch ? Color.blue.opacity(0.1) : Color.clear)
                        .clipShape(Circle())
                }
                
                // Settings
                Menu {
                    Toggle("Show Toolbar", isOn: $canvasState.showToolbar)
                    Toggle("Show Minimap", isOn: $canvasState.showMinimap)
                    Divider()
                    Button("Reset Canvas") {
                        canvasState.resetCanvas()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .padding(10)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

// MARK: - Minimap
struct MinimapView: View {
    let nodes: [ThoughtNode]
    let connections: [NodeConnection]
    @ObservedObject var canvasState: ModernCanvasState
    
    private let minimapScale: CGFloat = 0.1
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.8))
            
            // Minimap content
            Canvas { context, size in
                // Draw connections
                for connection in connections {
                    if let fromNode = nodes.first(where: { $0.id == connection.fromNodeId }),
                       let toNode = nodes.first(where: { $0.id == connection.toNodeId }) {
                        
                        let from = minimapPoint(fromNode.position, in: size)
                        let to = minimapPoint(toNode.position, in: size)
                        
                        context.stroke(
                            Path { path in
                                path.move(to: from)
                                path.addLine(to: to)
                            },
                            with: .color(.gray.opacity(0.3)),
                            lineWidth: 0.5
                        )
                    }
                }
                
                // Draw nodes
                for node in nodes {
                    let point = minimapPoint(node.position, in: size)
                    let nodeColor = nodeColor(for: node)
                    
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: point.x - 2,
                            y: point.y - 2,
                            width: 4,
                            height: 4
                        )),
                        with: .color(nodeColor)
                    )
                }
                
                // Draw viewport
                drawViewport(context: context, size: size)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func minimapPoint(_ position: Position, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (position.x * minimapScale) + size.width / 2,
            y: (position.y * minimapScale) + size.height / 2
        )
    }
    
    private func nodeColor(for node: ThoughtNode) -> Color {
        if canvasState.selectedNodes.contains(node) {
            return .blue
        } else if node.isAIGenerated {
            return .purple
        } else {
            return .white
        }
    }
    
    private func drawViewport(context: GraphicsContext, size: CGSize) {
        let viewportRect = CGRect(
            x: size.width / 2 - (canvasState.canvasOffset.width * minimapScale),
            y: size.height / 2 - (canvasState.canvasOffset.height * minimapScale),
            width: UIScreen.main.bounds.width * minimapScale / canvasState.canvasScale,
            height: UIScreen.main.bounds.height * minimapScale / canvasState.canvasScale
        )
        
        context.stroke(
            Path(roundedRect: viewportRect, cornerRadius: 2),
            with: .color(.yellow),
            lineWidth: 1
        )
        
        context.fill(
            Path(roundedRect: viewportRect, cornerRadius: 2),
            with: .color(.yellow.opacity(0.1))
        )
    }
}

// MARK: - Zoom Controls
struct ZoomControlsView: View {
    @ObservedObject var canvasState: ModernCanvasState
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: { zoomIn() }) {
                Image(systemName: "plus.magnifyingglass")
            }
            
            Text("\(Int(canvasState.canvasScale * 100))%")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .frame(width: 50)
            
            Button(action: { zoomOut() }) {
                Image(systemName: "minus.magnifyingglass")
            }
            
            Divider()
                .frame(width: 30)
            
            Button("Reset") {
                canvasState.resetCanvas()
            }
            .font(.system(size: 12))
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func zoomIn() {
        withAnimation(.spring(duration: 0.3)) {
            canvasState.canvasScale = min(5.0, canvasState.canvasScale + 0.2)
        }
    }
    
    private func zoomOut() {
        withAnimation(.spring(duration: 0.3)) {
            canvasState.canvasScale = max(0.2, canvasState.canvasScale - 0.2)
        }
    }
}

// MARK: - AI Assistant Panel
struct AIAssistantPanelView: View {
    let nodes: [ThoughtNode]
    @ObservedObject var canvasState: ModernCanvasState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.purple)
                Text("AI Assistant")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { canvasState.showAIPanel = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Quick Actions
                    Section {
                        ForEach(quickActions, id: \.title) { action in
                            AIActionButton(
                                icon: action.icon,
                                title: action.title,
                                description: action.description,
                                action: action.action
                            )
                        }
                    } header: {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                    }
                    
                    Divider()
                    
                    // AI Suggestions
                    if !canvasState.aiSuggestions.isEmpty {
                        Section {
                            ForEach(canvasState.aiSuggestions) { suggestion in
                                AISuggestionCard(suggestion: suggestion)
                            }
                        } header: {
                            Text("Suggestions")
                                .font(.headline)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .padding()
    }
    
    private var quickActions: [(icon: String, title: String, description: String, action: () -> Void)] {
        [
            ("wand.and.stars", "Find Connections", "Discover hidden relationships", {
                print("Finding connections...")
            }),
            ("brain", "Analyze Structure", "Understand your thought pattern", {
                print("Analyzing structure...")
            }),
            ("lightbulb", "Generate Insights", "Get AI-powered insights", {
                print("Generating insights...")
            }),
            ("arrow.triangle.branch", "Suggest Next Steps", "What to explore next", {
                print("Suggesting next steps...")
            })
        ]
    }
}

// MARK: - Search Overlay
struct SearchOverlayView: View {
    let nodes: [ThoughtNode]
    @ObservedObject var canvasState: ModernCanvasState
    
    @State private var searchResults: [ThoughtNode] = []
    
    var body: some View {
        VStack {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search nodes...", text: $canvasState.searchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: canvasState.searchQuery) { _ in
                        updateSearchResults()
                    }
                
                Button(action: { 
                    canvasState.searchQuery = ""
                    canvasState.showSearch = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()
            
            // Results
            if !searchResults.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(searchResults) { node in
                            CanvasSearchResultCard(node: node) {
                                canvasState.focusOnNode(node)
                                canvasState.showSearch = false
                            }
                        }
                    }
                    .padding()
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .background(Color.black.opacity(0.3))
        .onTapGesture {
            canvasState.showSearch = false
        }
    }
    
    private func updateSearchResults() {
        let query = canvasState.searchQuery.lowercased()
        searchResults = nodes.filter { node in
            node.content.lowercased().contains(query)
        }
    }
}

// MARK: - Supporting Components

struct CanvasToolButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(width: 44, height: 44)
            .background(isSelected ? Color.blue : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct AIActionButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.purple)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color.purple.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct AISuggestionCard: View {
    let suggestion: AISuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestionIcon)
                    .foregroundColor(.purple)
                Text(suggestionTitle)
                    .font(.system(size: 14, weight: .medium))
            }
            
            Text(suggestion.content)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text("Confidence: \(Int(suggestion.confidence * 100))%")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Button("Apply") {
                    print("Applying suggestion...")
                }
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.purple)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color.purple.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
    
    private var suggestionIcon: String {
        switch suggestion.type {
        case .connection: return "link"
        case .insight: return "lightbulb"
        case .question: return "questionmark.circle"
        case .structure: return "square.grid.3x3"
        }
    }
    
    private var suggestionTitle: String {
        switch suggestion.type {
        case .connection: return "New Connection"
        case .insight: return "Insight"
        case .question: return "Question"
        case .structure: return "Structure"
        }
    }
}

struct CanvasSearchResultCard: View {
    let node: ThoughtNode
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: node.nodeType.icon)
                    .foregroundColor(nodeTypeColor)
                
                VStack(alignment: .leading) {
                    Text(node.content)
                        .font(.system(size: 14))
                        .lineLimit(1)
                    Text(node.createdAt.formatted())
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
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
}