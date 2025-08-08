import SwiftUI

struct CognitiveRecommendationView: View {
    @ObservedObject var engine: CognitiveFlowStateEngine
    @State private var isExpanded = false
    
    var body: some View {
        Group {
            if let recommendation = engine.activeRecommendation {
                VStack(alignment: .trailing, spacing: 8) {
                    // Collapsed view
                    if !isExpanded {
                        Button {
                            withAnimation(.spring()) {
                                isExpanded.toggle()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: recommendation.icon)
                                    .font(.title3)
                                    .foregroundColor(.white)
                                
                                Text("Try \(recommendation.mode.displayName)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(recommendation.mode.color)
                                    .shadow(radius: 4)
                            )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Expanded view
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: recommendation.icon)
                                    .font(.title2)
                                    .foregroundColor(recommendation.mode.color)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(recommendation.title)
                                        .font(.headline)
                                    
                                    Text(recommendation.reason)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    withAnimation {
                                        engine.dismissRecommendation()
                                        isExpanded = false
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Button("Not Now") {
                                    withAnimation {
                                        engine.dismissRecommendation()
                                        isExpanded = false
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Switch Mode") {
                                    engine.userAcceptedRecommendation()
                                    withAnimation {
                                        isExpanded = false
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.regularMaterial)
                                .shadow(radius: 8)
                        )
                        .frame(width: 280)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
        }
    }
}

extension CognitiveMode {
    var displayName: String {
        switch self {
        case .capture: return "Capture Mode"
        case .incubation: return "Muse Mode"
        case .exploration: return "Focus Mode"
        case .association: return "Connect Mode"
        case .retrieval: return "Search Mode"
        }
    }
    
    var color: Color {
        switch self {
        case .capture: return .blue
        case .incubation: return .purple
        case .exploration: return .orange
        case .association: return .green
        case .retrieval: return .indigo
        }
    }
}

#Preview {
    VStack {
        Spacer()
        HStack {
            Spacer()
            CognitiveRecommendationView(engine: {
                let engine = CognitiveFlowStateEngine()
                engine.activeRecommendation = CognitiveRecommendation(
                    id: UUID().uuidString,
                    mode: .incubation,
                    title: "Time to Incubate",
                    reason: "You've captured many thoughts. Let them simmer.",
                    icon: "sparkles",
                    confidence: 0.85
                )
                return engine
            }())
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.1))
}