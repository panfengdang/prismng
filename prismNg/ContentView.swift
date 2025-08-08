//  ContentView.swift
//  prismNg
//
//  Created by suntiger on 2025/8/5.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var thoughtNodes: [ThoughtNode]
    @Query private var userConfig: [UserConfiguration]
    
    @State private var showOnboarding = false
    @State private var showDualTrackWelcome = false
    @State private var showFreeTierOnboarding = false
    @State private var isFirstLaunch = true
    @StateObject private var interactionService = InteractionPreferenceService()

    var body: some View {
        // 使用完整的主应用界面，包含侧边栏导航
        MainAppView()
            .onAppear {
                setupInitialConfiguration()
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .sheet(isPresented: $showDualTrackWelcome) {
                DualTrackWelcomeView(isPresented: $showDualTrackWelcome, interactionService: interactionService)
            }
            .sheet(isPresented: $showFreeTierOnboarding) {
                FreeTierOnboardingView(isPresented: $showFreeTierOnboarding)
            }
    }
    
    private var shouldShowOnboarding: Bool {
        userConfig.isEmpty
    }
    
    private func setupInitialConfiguration() {
        // Check if we need to migrate legacy data
        migrateLegacyDataIfNeeded()
        
        // Create default user configuration if none exists
        if userConfig.isEmpty {
            let defaultConfig = UserConfiguration()
            modelContext.insert(defaultConfig)
            try? modelContext.save()
            
            // Show onboarding for first time users
            showOnboarding = true
            
            // Show dual-track welcome after basic onboarding
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showDualTrackWelcome = true
            }
            
            // Show free tier onboarding after dual-track welcome
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showFreeTierOnboarding = true
            }
        } else if let config = userConfig.first {
            // Setup interaction service with existing config
            interactionService.setup(modelContext: modelContext, userConfiguration: config)
        }
        
        isFirstLaunch = false
    }
    
    private func migrateLegacyDataIfNeeded() {
        // Check for legacy Item data and migrate if found
        let itemRequest = FetchDescriptor<Item>()
        if let items = try? modelContext.fetch(itemRequest), !items.isEmpty {
            // Migrate legacy items to thought nodes
            for item in items {
                let thoughtNode = ThoughtNode(
                    content: "Migrated thought from \(item.timestamp.formatted())",
                    nodeType: .thought,
                    position: Position(x: Double.random(in: -200...200), y: Double.random(in: -200...200))
                )
                modelContext.insert(thoughtNode)
                modelContext.delete(item)
            }
            try? modelContext.save()
        }
    }
}


// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentStep = 0
    
    private let onboardingSteps = [
        OnboardingStep(
            title: "欢迎使用 PrismNg",
            description: "您的AI驱动思维伙伴",
            icon: "brain.head.profile"
        ),
        OnboardingStep(
            title: "捕捉您的想法",
            description: "长按任意位置创建新的思维节点",
            icon: "plus.circle"
        ),
        OnboardingStep(
            title: "选择您的风格",
            description: "使用传统UI或学习手势控制",
            icon: "hand.tap"
        )
    ]
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Image(systemName: onboardingSteps[currentStep].icon)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title and Description
            VStack(spacing: 16) {
                Text(onboardingSteps[currentStep].title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(onboardingSteps[currentStep].description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Navigation
            VStack(spacing: 20) {
                if currentStep < onboardingSteps.count - 1 {
                    Button("继续") {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    Button("开始思考") {
                        withAnimation {
                            isPresented = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                
                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<onboardingSteps.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            .padding(.bottom, 50)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }
}
	
struct OnboardingStep {
    let title: String
    let description: String
    let icon: String
}

#Preview("Main App") {
    ContentView()
        .modelContainer(for: [ThoughtNode.self, NodeConnection.self, AITask.self, UserConfiguration.self])
        .environmentObject(QuotaManagementService())
}

#Preview("Onboarding") {
    OnboardingView(isPresented: .constant(true))
}
