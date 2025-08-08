//
//  NodeContextMenu.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI

struct NodeContextMenu: View {
    let node: ThoughtNode
    let canvasViewModel: CanvasViewModel
    let relatedNodes: [ThoughtNode]
    @Environment(\.dismiss) private var dismiss
    @State private var showingAILens = false
    @State private var showingEditView = false
    @State private var showingEmotionalMarker = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Node Info Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: nodeTypeIcon)
                        .foregroundColor(.blue)
                    Text(node.nodeType.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(node.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(node.content)
                    .font(.callout)
                    .lineLimit(3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Action Buttons
            VStack(spacing: 12) {
                // Edit
                Button {
                    showingEditView = true
                    dismiss()
                } label: {
                    Label("编辑节点", systemImage: "pencil")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                
                // AI Lens (Pro Feature)
                Button {
                    if canvasViewModel.quotaService.subscriptionTier != .free {
                        showingAILens = true
                        dismiss()
                    }
                } label: {
                    HStack {
                        Label("AI 透镜分析", systemImage: "wand.and.rays")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if canvasViewModel.quotaService.subscriptionTier == .free {
                            Text("Pro")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.blue)
                                )
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(canvasViewModel.quotaService.subscriptionTier == .free)
                
                // Emotional Marker
                Button {
                    showingEmotionalMarker = true
                    dismiss()
                } label: {
                    HStack {
                        Label("情感标记", systemImage: "heart.circle")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Show current emotions
                        if !canvasViewModel.emotionalService.getEmotions(for: node).isEmpty {
                            HStack(spacing: 4) {
                                ForEach(canvasViewModel.emotionalService.getEmotions(for: node).prefix(3), id: \.self) { emotion in
                                    Image(systemName: emotion.icon)
                                        .font(.caption)
                                        .foregroundColor(emotion.color)
                                }
                            }
                        }
                    }
                }
                
                // Create Connection
                Button {
                    // TODO: Enter connection mode
                    dismiss()
                } label: {
                    Label("创建连接", systemImage: "link")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                
                // Delete
                Button(role: .destructive) {
                    canvasViewModel.deleteNode(node.id)
                    dismiss()
                } label: {
                    Label("删除节点", systemImage: "trash")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
        .sheet(isPresented: $showingAILens) {
            if let aiLensService = canvasViewModel.aiLensService {
                AILensView(
                    aiLensService: aiLensService,
                    node: node,
                    relatedNodes: relatedNodes
                )
            }
        }
        .sheet(isPresented: $showingEditView) {
            NodeEditView(
                node: node,
                onSave: {},
                onDelete: {
                    canvasViewModel.deleteNode(node.id)
                }
            )
        }
        .sheet(isPresented: $showingEmotionalMarker) {
            EmotionalMarkerView(
                emotionalService: canvasViewModel.emotionalService,
                node: node
            )
        }
    }
    
    private var nodeTypeIcon: String {
        switch node.nodeType {
        case .thought: return "lightbulb"
        case .insight: return "star"
        case .question: return "questionmark.circle"
        case .conclusion: return "checkmark.seal"
        case .contradiction: return "exclamationmark.triangle"
        case .structure: return "grid"
        }
    }
}

// MARK: - Context Menu Modifier
struct NodeContextMenuModifier: ViewModifier {
    let node: ThoughtNode
    let canvasViewModel: CanvasViewModel
    let relatedNodes: [ThoughtNode]
    @State private var showingMenu = false
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture {
                showingMenu = true
            }
            .popover(isPresented: $showingMenu) {
                NodeContextMenu(
                    node: node,
                    canvasViewModel: canvasViewModel,
                    relatedNodes: relatedNodes
                )
            }
    }
}

extension View {
    func nodeContextMenu(
        node: ThoughtNode,
        canvasViewModel: CanvasViewModel,
        relatedNodes: [ThoughtNode]
    ) -> some View {
        modifier(NodeContextMenuModifier(
            node: node,
            canvasViewModel: canvasViewModel,
            relatedNodes: relatedNodes
        ))
    }
}
