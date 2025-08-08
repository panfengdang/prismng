//
//  SimpleCanvasView.swift
//  prismNg
//
//  Created for testing canvas functionality
//

import SwiftUI
import SwiftData

struct SimpleCanvasView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var thoughtNodes: [ThoughtNode]
    @Query private var connections: [NodeConnection]
    
    @State private var offset = CGSize.zero
    @State private var scale: CGFloat = 1.0
    @State private var selectedNode: ThoughtNode?
    @State private var showingNodeEditor = false
    @State private var longPressLocation = CGPoint.zero
    @State private var connectingFromNode: ThoughtNode?
    @State private var showConnectionMode = false
    @State private var showAIPanel = false
    @State private var isAnalyzing = false
    @State private var analysisResult = ""
    @State private var suggestedAssociations: [(from: ThoughtNode, to: ThoughtNode, reason: String)] = []
    @State private var showAssociations = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                // Main content
                canvasContent
                
                // Overlay
                overlayContent
            }
            .navigationBarHidden(true)
        }
    }
    
    private var canvasContent: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid background
                GridPattern()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
                    .scaleEffect(scale)
                    .offset(offset)
                
                // Nodes
                // Connection lines
                ForEach(connections) { connection in
                    if let fromNode = thoughtNodes.first(where: { $0.id == connection.fromNodeId }),
                       let toNode = thoughtNodes.first(where: { $0.id == connection.toNodeId }) {
                        ConnectionLine(
                            from: CGPoint(
                                x: fromNode.position.x * scale + offset.width + geometry.size.width / 2,
                                y: fromNode.position.y * scale + offset.height + geometry.size.height / 2
                            ),
                            to: CGPoint(
                                x: toNode.position.x * scale + offset.width + geometry.size.width / 2,
                                y: toNode.position.y * scale + offset.height + geometry.size.height / 2
                            )
                        )
                    }
                }
                
                // Nodes
                ForEach(thoughtNodes) { node in
                    NodeView(
                        node: node,
                        isSelected: selectedNode?.id == node.id,
                        onTap: { 
                            if showConnectionMode {
                                handleConnectionTap(node)
                            } else {
                                selectedNode = node
                            }
                        },
                        onDelete: { deleteNode(node) }
                    )
                    .position(
                        x: node.position.x * scale + offset.width + geometry.size.width / 2,
                        y: node.position.y * scale + offset.height + geometry.size.height / 2
                    )
                    .scaleEffect(scale)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !showConnectionMode && selectedNode?.id == node.id {
                                    // Update node position while dragging
                                    node.position.x += value.translation.width / scale
                                    node.position.y += value.translation.height / scale
                                }
                            }
                            .onEnded { _ in
                                // Save the new position
                                try? modelContext.save()
                            }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onLongPressGesture(minimumDuration: 0.5) {
                // Long press detected - create node at center for now
                createNode(at: CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2), in: geometry)
            }
            .gesture(panGesture)
            .gesture(scaleGesture)
        }
    }
    
    private var overlayContent: some View {
        VStack {
            HStack {
                Text("节点数: \(thoughtNodes.count)")
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Text("连接数: \(connections.count)")
                    .padding(8)
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Spacer()
                
                // Connection mode toggle
                Button(showConnectionMode ? "完成连接" : "连接模式") {
                    showConnectionMode.toggle()
                    if !showConnectionMode {
                        connectingFromNode = nil
                    }
                }
                .padding(8)
                .background(showConnectionMode ? Color.orange : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                // AI Analysis button
                Button("AI 分析") {
                    if !thoughtNodes.isEmpty {
                        analyzeWithAI()
                    }
                }
                .padding(8)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(8)
                .opacity(thoughtNodes.isEmpty ? 0.5 : 1.0)
                .disabled(thoughtNodes.isEmpty || isAnalyzing)
                
                // Smart Associations button
                Button("智能联想") {
                    if thoughtNodes.count >= 2 {
                        findSmartAssociations()
                    }
                }
                .padding(8)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(8)
                .opacity(thoughtNodes.count < 2 ? 0.5 : 1.0)
                .disabled(thoughtNodes.count < 2 || isAnalyzing)
                
                Button("关闭") {
                    dismiss()
                }
                .padding(8)
                .background(Color.red.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            
            Spacer()
            
            // Instructions and AI Results
            VStack(spacing: 8) {
                // Instructions
                VStack(spacing: 4) {
                    Text("长按创建节点")
                    Text("拖动移动画布")
                    Text("双指缩放")
                    if showConnectionMode {
                        Text("点击两个节点创建连接")
                            .foregroundColor(.orange)
                    }
                }
                .font(.caption)
                .padding(8)
                .background(Color.black.opacity(0.6))
                .foregroundColor(.white)
                .cornerRadius(8)
                
                // AI Analysis Results
                if isAnalyzing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("AI 分析中...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(8)
                } else if !analysisResult.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI 分析结果")
                            .font(.caption.bold())
                            .foregroundColor(.purple)
                        Text(analysisResult)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .frame(maxWidth: 300)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                }
                
                // Smart Associations
                if showAssociations && !suggestedAssociations.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("🧠 智能联想建议")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                            Spacer()
                            Button("关闭") {
                                showAssociations = false
                            }
                            .font(.caption2)
                            .foregroundColor(.gray)
                        }
                        
                        ForEach(Array(suggestedAssociations.prefix(3).enumerated()), id: \.offset) { index, association in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text("\(index + 1).")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                    Text("\(String(association.from.content.prefix(20)))... → \(String(association.to.content.prefix(20)))...")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                }
                                Text(association.reason)
                                    .font(.caption2)
                                    .foregroundColor(.green.opacity(0.8))
                                    .italic()
                                
                                Button("创建连接") {
                                    createSuggestedConnection(from: association.from, to: association.to)
                                }
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(4)
                            }
                            .padding(4)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(4)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: 350)
                    .background(Color.black.opacity(0.9))
                    .cornerRadius(8)
                }
            }
            .padding()
        }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: value.translation.width,
                    height: value.translation.height
                )
            }
    }
    
    private var scaleGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = value
            }
    }
    
    private func createNode(at location: CGPoint, in geometry: GeometryProxy) {
        let x = (location.x - geometry.size.width / 2 - offset.width) / scale
        let y = (location.y - geometry.size.height / 2 - offset.height) / scale
        
        let node = ThoughtNode(
            content: "新节点 \(Date().formatted(date: .omitted, time: .shortened))",
            nodeType: .thought,
            position: Position(x: x, y: y)
        )
        
        modelContext.insert(node)
        do {
            try modelContext.save()
            print("✅ Created node at (\(x), \(y))")
        } catch {
            print("❌ Failed to create node: \(error)")
        }
    }
    
    private func deleteNode(_ node: ThoughtNode) {
        // Delete connections related to this node
        for connection in connections {
            if connection.fromNodeId == node.id || connection.toNodeId == node.id {
                modelContext.delete(connection)
            }
        }
        
        modelContext.delete(node)
        try? modelContext.save()
        if selectedNode?.id == node.id {
            selectedNode = nil
        }
    }
    
    private func handleConnectionTap(_ node: ThoughtNode) {
        if let fromNode = connectingFromNode {
            // Create connection
            if fromNode.id != node.id {
                let connection = NodeConnection(
                    fromNodeId: fromNode.id,
                    toNodeId: node.id,
                    connectionType: .weakAssociation
                )
                modelContext.insert(connection)
                try? modelContext.save()
                print("✅ Created connection from \(fromNode.content) to \(node.content)")
            }
            connectingFromNode = nil
        } else {
            // Set as starting node
            connectingFromNode = node
            print("📍 Selected \(node.content) as connection start")
        }
    }
    
    private func analyzeWithAI() {
        isAnalyzing = true
        analysisResult = ""
        
        // Simulate AI analysis
        Task {
            // In real implementation, this would call the AIService
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                // Generate basic analysis based on nodes
                if thoughtNodes.count == 1 {
                    analysisResult = "发现1个独立思维节点。建议：添加更多相关想法以形成思维网络。"
                } else if thoughtNodes.count < 5 {
                    analysisResult = "当前有\(thoughtNodes.count)个节点。结构分析：初步思维框架形成中。建议创建连接来明确关系。"
                } else {
                    let connectionRatio = Double(connections.count) / Double(thoughtNodes.count)
                    if connectionRatio < 0.5 {
                        analysisResult = "节点连接稀疏（连接率：\(Int(connectionRatio * 100))%）。建议：探索节点间的潜在关联。"
                    } else if connectionRatio < 1.5 {
                        analysisResult = "思维网络结构良好。发现\(connections.count)个连接。可以开始深入分析主题关系。"
                    } else {
                        analysisResult = "思维网络密集连接。识别到复杂的关系网络，建议进行结构化梳理。"
                    }
                }
                
                // Add smart suggestions
                if let selectedNode = selectedNode {
                    analysisResult += "\n\n针对选中节点「\(selectedNode.content)」的建议：可以从不同角度展开思考。"
                }
                
                isAnalyzing = false
            }
        }
    }
    
    private func findSmartAssociations() {
        isAnalyzing = true
        suggestedAssociations = []
        showAssociations = false
        
        Task {
            // Simulate AI finding associations
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                // Generate smart associations based on content similarity
                var associations: [(from: ThoughtNode, to: ThoughtNode, reason: String)] = []
                
                for i in 0..<thoughtNodes.count {
                    for j in (i+1)..<thoughtNodes.count {
                        let node1 = thoughtNodes[i]
                        let node2 = thoughtNodes[j]
                        
                        // Check if connection already exists
                        let connectionExists = connections.contains { conn in
                            (conn.fromNodeId == node1.id && conn.toNodeId == node2.id) ||
                            (conn.fromNodeId == node2.id && conn.toNodeId == node1.id)
                        }
                        
                        if !connectionExists {
                            // Simple keyword-based association
                            let words1 = Set(node1.content.lowercased().components(separatedBy: " "))
                            let words2 = Set(node2.content.lowercased().components(separatedBy: " "))
                            let commonWords = words1.intersection(words2)
                            
                            if !commonWords.isEmpty {
                                associations.append((
                                    from: node1,
                                    to: node2,
                                    reason: "共同关键词：\(commonWords.joined(separator: ", "))"
                                ))
                            } else if node1.content.count > 10 && node2.content.count > 10 {
                                // Simulate semantic similarity for longer texts
                                let randomReasons = [
                                    "主题相关性高",
                                    "逻辑上存在因果关系",
                                    "属于同一概念范畴",
                                    "可能存在对比关系",
                                    "互为补充说明"
                                ]
                                if Int.random(in: 0...2) == 0 {
                                    associations.append((
                                        from: node1,
                                        to: node2,
                                        reason: randomReasons.randomElement() ?? "潜在关联"
                                    ))
                                }
                            }
                        }
                    }
                }
                
                // Sort by relevance (in real implementation, would use AI scoring)
                suggestedAssociations = Array(associations.prefix(5))
                showAssociations = !suggestedAssociations.isEmpty
                
                if suggestedAssociations.isEmpty {
                    analysisResult = "未发现明显的关联建议。节点内容可能较为独立。"
                } else {
                    analysisResult = "发现 \(suggestedAssociations.count) 个潜在关联"
                }
                
                isAnalyzing = false
            }
        }
    }
    
    private func createSuggestedConnection(from: ThoughtNode, to: ThoughtNode) {
        let connection = NodeConnection(
            fromNodeId: from.id,
            toNodeId: to.id,
            connectionType: .similarity
        )
        modelContext.insert(connection)
        try? modelContext.save()
        
        // Remove this suggestion
        suggestedAssociations.removeAll { $0.from.id == from.id && $0.to.id == to.id }
        
        if suggestedAssociations.isEmpty {
            showAssociations = false
        }
    }
}

// Connection line view
struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(Color.blue.opacity(0.5), lineWidth: 2)
    }
}

// Enhanced node view with full interaction
struct NodeView: View {
    @Environment(\.modelContext) private var modelContext
    let node: ThoughtNode
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editText = ""
    
    var body: some View {
        VStack(spacing: 4) {
            if isEditing {
                // Edit mode
                TextField("节点内容", text: $editText, onCommit: {
                    saveEdit()
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.caption)
                .frame(maxWidth: 150)
                .padding(4)
            } else {
                // Display mode
                Text(node.content)
                    .font(.caption)
                    .lineLimit(3)
                    .padding(8)
                    .frame(maxWidth: 150)
                    .onTapGesture(count: 2) {
                        startEditing()
                    }
            }
            
            HStack {
                Text(node.nodeType.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isSelected {
                    HStack(spacing: 4) {
                        Button(action: { startEditing() }) {
                            Image(systemName: "pencil")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.2) : Color.white)
                .shadow(radius: isSelected ? 4 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .onTapGesture {
            if !isEditing {
                onTap()
            }
        }
        .onAppear {
            editText = node.content
        }
    }
    
    private func startEditing() {
        editText = node.content
        isEditing = true
    }
    
    private func saveEdit() {
        if !editText.isEmpty && editText != node.content {
            node.content = editText
            try? modelContext.save()
        }
        isEditing = false
    }
}

// Grid pattern for background
struct GridPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let gridSize: CGFloat = 50
        
        // Vertical lines
        for x in stride(from: 0, through: rect.width, by: gridSize) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: rect.height))
        }
        
        // Horizontal lines
        for y in stride(from: 0, through: rect.height, by: gridSize) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }
        
        return path
    }
}

#Preview {
    SimpleCanvasView()
        .modelContainer(for: [ThoughtNode.self, NodeConnection.self])
}