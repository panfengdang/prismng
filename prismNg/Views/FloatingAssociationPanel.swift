import SwiftUI

struct FloatingAssociationPanel: View {
    @ObservedObject var associationService: AssociationRecommendationService
    let thoughtNodes: [ThoughtNode]
    let onNodeSelected: (UUID) -> Void
    let onCreateConnection: (UUID, UUID, ConnectionType) -> Void
    
    @State private var isCollapsed = true
    @State private var dragOffset = CGSize.zero
    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 50, y: 200)
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if !isCollapsed && !associationService.recommendedAssociations.isEmpty {
                // Expanded panel
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(.blue)
                        Text("Suggested Connections")
                            .font(.headline)
                        Spacer()
                        Button {
                            withAnimation(.spring()) {
                                isCollapsed = true
                            }
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Recommendations
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(associationService.recommendedAssociations.prefix(5)) { recommendation in
                                AssociationCard(
                                    recommendation: recommendation,
                                    thoughtNodes: thoughtNodes,
                                    onAccept: {
                                        onCreateConnection(
                                            recommendation.targetNodeId,
                                            recommendation.associatedNodeId,
                                            ConnectionType.strongSupport  // Map from AssociationType to ConnectionType
                                        )
                                        associationService.acceptRecommendation(recommendation)
                                    },
                                    onReject: {
                                        associationService.rejectRecommendation(recommendation)
                                    },
                                    onNodeTap: onNodeSelected
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                .padding()
                .frame(width: 320)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 10)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }
            
            // Collapsed indicator
            if isCollapsed && !associationService.recommendedAssociations.isEmpty {
                Button {
                    withAnimation(.spring()) {
                        isCollapsed = false
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(.blue)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                        
                        // Badge for recommendation count
                        if associationService.recommendedAssociations.count > 0 {
                            Text("\(min(associationService.recommendedAssociations.count, 9))")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Circle().fill(.red))
                                .offset(x: 16, y: -16)
                        }
                    }
                }
                .shadow(radius: 8)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .position(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    position.x += value.translation.width
                    position.y += value.translation.height
                    dragOffset = .zero
                }
        )
    }
}

struct AssociationCard: View {
    let recommendation: AssociationRecommendation
    let thoughtNodes: [ThoughtNode]
    let onAccept: () -> Void
    let onReject: () -> Void
    let onNodeTap: (UUID) -> Void
    
    private var fromNode: ThoughtNode? {
        thoughtNodes.first { $0.id == recommendation.targetNodeId }
    }
    
    private var toNode: ThoughtNode? {
        thoughtNodes.first { $0.id == recommendation.associatedNodeId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Connection type and confidence
            HStack {
                HStack {
                    Image(systemName: iconForAssociationType(recommendation.associationType))
                        .foregroundColor(colorForAssociationType(recommendation.associationType))
                    Text(recommendation.associationType.displayName)
                }
                .font(.caption)
                
                Spacer()
                
                Text("\(Int(recommendation.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Node previews
            VStack(alignment: .leading, spacing: 4) {
                NodePreview(
                    node: fromNode,
                    label: "From:",
                    onTap: { if let id = fromNode?.id { onNodeTap(id) } }
                )
                
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 40)
                
                NodePreview(
                    node: toNode,
                    label: "To:",
                    onTap: { if let id = toNode?.id { onNodeTap(id) } }
                )
            }
            
            // Reason
            Text(recommendation.reasoning)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Actions
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        onReject()
                    }
                } label: {
                    Label("Dismiss", systemImage: "xmark")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
                
                Button {
                    withAnimation {
                        onAccept()
                    }
                } label: {
                    Label("Connect", systemImage: "link")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.mini)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func iconForAssociationType(_ type: AssociationType) -> String {
        switch type {
        case .strongSupport: return "checkmark.circle.fill"
        case .weakAssociation: return "link.circle"
        case .similarity: return "equal.circle"
        case .contextual: return "location.circle"
        case .temporal: return "clock.circle"
        case .emotional: return "heart.circle"
        }
    }
    
    private func colorForAssociationType(_ type: AssociationType) -> Color {
        switch type {
        case .strongSupport: return .green
        case .weakAssociation: return .blue
        case .similarity: return .purple
        case .contextual: return .orange
        case .temporal: return .cyan
        case .emotional: return .pink
        }
    }
}

struct NodePreview: View {
    let node: ThoughtNode?
    let label: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 35, alignment: .leading)
                
                Text(node?.content ?? "Unknown")
                    .font(.caption)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

extension ConnectionType {
    var displayName: String {
        switch self {
        case .strongSupport: return "Strong Support"
        case .weakAssociation: return "Related"
        case .contradiction: return "Contradiction"
        case .causality: return "Causal"
        case .similarity: return "Similar"
        case .resonance: return "Resonance"
        }
    }
    
    var icon: String {
        switch self {
        case .strongSupport: return "link.circle.fill"
        case .weakAssociation: return "link"
        case .contradiction: return "exclamationmark.triangle"
        case .causality: return "arrow.right.circle"
        case .similarity: return "equal.circle"
        case .resonance: return "sparkles"
        }
    }
    
    // color property already defined in ModernCanvasView extension
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
        
        FloatingAssociationPanel(
            associationService: {
                let service = AssociationRecommendationService()
                // Add mock recommendations
                return service
            }(),
            thoughtNodes: [],
            onNodeSelected: { _ in },
            onCreateConnection: { _, _, _ in }
        )
    }
    .ignoresSafeArea()
}