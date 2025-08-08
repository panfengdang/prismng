import SwiftUI

struct AdaptiveModeToast: View {
    let recommendation: AdaptiveModeRecommendation
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: recommendation.icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                    
                    Text(recommendation.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 12) {
                Button("Not Now") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Switch") {
                    onAccept()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .frame(maxWidth: 400)
    }
}

struct AdaptiveModeRecommendation {
    let id: String
    let title: String
    let description: String
    let icon: String
    let targetMode: AdaptiveUIMode
    let triggerReason: String
}

enum AdaptiveUIMode: String, CaseIterable {
    case traditional = "traditional"
    case gesture = "gesture"
    case hidden = "hidden"
}

#Preview {
    VStack {
        AdaptiveModeToast(
            recommendation: AdaptiveModeRecommendation(
                id: "gesture-ready",
                title: "Ready for Gestures?",
                description: "You've mastered the basics. Try gesture mode for a cleaner canvas.",
                icon: "hand.tap",
                targetMode: .gesture,
                triggerReason: "User has successfully used traditional UI 10+ times"
            ),
            onAccept: { print("Accepted") },
            onDismiss: { print("Dismissed") }
        )
        .padding()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.1))
}