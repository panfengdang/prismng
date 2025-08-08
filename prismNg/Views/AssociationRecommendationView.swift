import SwiftUI

struct AssociationRecommendationView: View {
    @ObservedObject var associationService: AssociationRecommendationService
    let thoughtNodes: [ThoughtNode]
    let onNodeSelected: (UUID) -> Void
    let onCreateConnection: (UUID, UUID, ConnectionType) -> Void
    
    @State private var selectedAssociation: RecommendedAssociation?
    @State private var hoveredNodeId: UUID?
    
    private var topRecommendations: [RecommendedAssociation] {
        Array(associationService.recommendedAssociations.prefix(5))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "link.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Suggested Connections")
                    .font(.headline)
                
                Spacer()
                
                Text("\(topRecommendations.count) suggestions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if topRecommendations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "link.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No associations found")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Create more thoughts to discover potential connections")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(topRecommendations) { association in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(association.associationType.displayName)
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(association.confidence * 100))%")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(association.reasoning)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Button("Accept") {
                                        acceptAssociation(association)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    
                                    Button("Reject") {
                                        rejectAssociation(association)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private func acceptAssociation(_ association: RecommendedAssociation) {
        // Create the connection - map AssociationType to ConnectionType
        let connectionType: ConnectionType = mapAssociationToConnection(association.associationType)
        onCreateConnection(
            association.targetNodeId, 
            association.associatedNodeId, 
            connectionType
        )
        
        // Clear recommendations after accepting one
        withAnimation(.easeOut(duration: 0.3)) {
            associationService.clearRecommendations()
        }
    }
    
    private func rejectAssociation(_ association: RecommendedAssociation) {
        // Clear recommendations after rejecting (could be more sophisticated)
        withAnimation(.easeOut(duration: 0.3)) {
            associationService.clearRecommendations()
        }
    }
    
    private func mapAssociationToConnection(_ associationType: AssociationType) -> ConnectionType {
        switch associationType {
        case .strongSupport:
            return .strongSupport
        case .weakAssociation:
            return .weakAssociation
        case .similarity:
            return .similarity
        case .contextual:
            return .similarity // Map contextual to similarity for now
        case .temporal:
            return .causality // Map temporal to causality for now
        case .emotional:
            return .resonance // Map emotional to resonance for now
        }
    }
}

#Preview {
    let service = AssociationRecommendationService()
    let sampleNodes = [
        ThoughtNode(content: "Sample thought 1", nodeType: .thought, position: Position(x: 0, y: 0)),
        ThoughtNode(content: "Sample thought 2", nodeType: .thought, position: Position(x: 100, y: 100))
    ]
    
    return AssociationRecommendationView(
        associationService: service,
        thoughtNodes: sampleNodes,
        onNodeSelected: { _ in },
        onCreateConnection: { _, _, _ in }
    )
}