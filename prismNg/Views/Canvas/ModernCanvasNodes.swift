//
//  ModernCanvasNodes.swift
//  prismNg
//
//  Canvas Node Components
//

import SwiftUI
import SwiftData

struct CanvasNodeView: View {
    let node: ThoughtNode
    let isSelected: Bool
    let isHovered: Bool
    let cognitiveGear: CognitiveGear
    let scale: CGFloat
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onDrag: (CGSize) -> Void
    
    @State private var dragOffset = CGSize.zero
    @State private var isPulsing = false
    
    var body: some View {
        nodeContent
            .scaleEffect(scale * (isPulsing ? 1.05 : 1.0))
            .offset(dragOffset)
            .onTapGesture(perform: onTap)
            .onTapGesture(count: 2, perform: onDoubleTap)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        onDrag(value.translation)
                        dragOffset = .zero
                    }
            )
            .onAppear {
                if node.isAIGenerated {
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
    }
    
    private var nodeContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Node Header
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
            
            // Node Content
            Text(node.content)
                .font(.system(size: 14))
                .lineLimit(cognitiveGear == .capture ? 3 : nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Node Footer - removed tags and emotional valence for now
        }
        .padding(12)
        .frame(width: nodeWidth)
        .background(nodeBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: shadowColor,
            radius: isHovered ? 8 : 4,
            x: 0,
            y: isHovered ? 4 : 2
        )
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
                    colors: [
                        Color.purple.opacity(0.05),
                        Color.blue.opacity(0.05)
                    ],
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

struct EmotionalIndicator: View {
    let valence: Double
    
    private var emoji: String {
        switch valence {
        case ..<(-0.5): return "😔"
        case -0.5..<(-0.2): return "😐"
        case -0.2..<0.2: return "😊"
        case 0.2..<0.5: return "😃"
        default: return "🤩"
        }
    }
    
    private var color: Color {
        if valence < 0 {
            return .red
        } else if valence > 0 {
            return .green
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Text(emoji)
                .font(.system(size: 14))
            
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(color)
                        .frame(width: 4, height: 4)
                )
        }
    }
}