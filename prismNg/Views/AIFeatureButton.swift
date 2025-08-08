import SwiftUI

struct AIFeatureButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @ObservedObject var quotaService: QuotaManagementService
    
    private var isDisabled: Bool {
        !quotaService.canUseAI()
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                action()
            }
        }) {
            VStack(spacing: 4) {
                ZStack {
                    Image(systemName: icon)
                        .font(.title2)
                    
                    if !quotaService.canUseAI() {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(2)
                            .background(Circle().fill(Color.red))
                            .offset(x: 12, y: -12)
                    }
                }
                
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isDisabled ? .secondary : .primary)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .frame(minWidth: 60)
        .disabled(isDisabled)
        .popover(isPresented: .constant(isDisabled && quotaService.showUpgradePrompt)) {
            QuotaExhaustedPopover(quotaService: quotaService)
                .frame(width: 300)
        }
    }
}

struct QuotaExhaustedPopover: View {
    @ObservedObject var quotaService: QuotaManagementService
    @State private var showSubscriptionView = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles.slash")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("AI Quota Exhausted")
                .font(.headline)
            
            Text("You've used all \(quotaService.dailyQuotaLimit) free AI interactions today. Upgrade to continue using AI features.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 8) {
                Text("Next reset in:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(quotaService.getTimeUntilReset())
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            Button("Upgrade Now") {
                showSubscriptionView = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView(quotaService: quotaService)
        }
    }
}

#Preview {
    HStack {
        AIFeatureButton(
            title: "AI Lens",
            icon: "link.circle.fill",
            action: { print("AI Lens tapped") },
            quotaService: QuotaManagementService()
        )
        
        AIFeatureButton(
            title: "Structure",
            icon: "square.grid.3x3.fill",
            action: { print("Structure tapped") },
            quotaService: {
                let service = QuotaManagementService()
                // Simulate used quota for preview
                service.currentQuotaUsage = 2
                return service
            }()
        )
    }
    .padding()
}