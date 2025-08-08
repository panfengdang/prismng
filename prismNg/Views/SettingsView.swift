//
//  SettingsView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import SwiftData

// MARK: - Settings View
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appleSignInService: AppleSignInService
    @EnvironmentObject var firebaseManager: FirebaseManager
    @ObservedObject var interactionService: InteractionPreferenceService
    @ObservedObject var quotaService: QuotaManagementService
    @ObservedObject var cloudSyncManager: CloudSyncManager
    @EnvironmentObject var realtimeSyncService: FirestoreRealtimeSyncService
    @EnvironmentObject var growthOptimizationService: GrowthOptimizationService
    @State private var showResetConfirmation = false
    @State private var showAbout = false
    @State private var showAuthentication = false
    
    var body: some View {
        List {
            accountSection
            interactionModeSection
            cognitiveGearSection
            aiQuotaSection
            aiRoutingSection
            growthOptimizationSection
            cloudSyncSection
            realtimeSyncSection
            dataManagementSection
            bgTasksSection
            aboutSection
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
        .alert("重置交互数据", isPresented: $showResetConfirmation) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                interactionService.resetInteractionData()
            }
        } message: {
            Text("这将清除所有交互历史记录，重新开始学习你的使用偏好。")
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showAuthentication) {
            AuthenticationView()
        }
    }
    
    // MARK: - Section Views
    
    private var accountSection: some View {
        Section {
            if firebaseManager.isAuthenticated || appleSignInService.isSignedIn {
                // Signed in state
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading) {
                            if let displayName = appleSignInService.userDisplayName ?? firebaseManager.currentUser?.displayName {
                                Text(displayName)
                                    .font(.headline)
                            } else {
                                Text("已登录")
                                    .font(.headline)
                            }
                            
                            if let email = appleSignInService.userEmail ?? firebaseManager.currentUser?.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button("退出") {
                            Task {
                                if appleSignInService.isSignedIn {
                                    await appleSignInService.signOut()
                                } else {
                                    try? await firebaseManager.signOut()
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            } else {
                // Not signed in state
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading) {
                            Text("未登录")
                                .font(.headline)
                            Text("登录以同步数据和使用高级功能")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("登录") {
                            showAuthentication = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
        } header: {
            Text("账户")
        }
    }
    
    private var interactionModeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("交互模式", systemImage: "hand.tap")
                    .font(.headline)
                
                Text("选择最适合你的操作方式")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(InteractionMode.allCases, id: \.self) { mode in
                    InteractionModeRow(
                        mode: mode,
                        isSelected: interactionService.currentPreference == mode,
                        confidence: mode == interactionService.currentPreference ? interactionService.confidenceLevel : nil,
                        onSelect: {
                            interactionService.setPreference(mode)
                            provideHapticFeedback()
                        }
                    )
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("交互偏好")
        }
    }
    
    private var cognitiveGearSection: some View {
        Section {
            CognitiveGearPicker()
        } header: {
            Text("认知档位")
        } footer: {
            Text("速记模式：快速捕捉，AI完全静默\n缪斯模式：灵感漂移，共鸣瞬现\n审问模式：深度分析，AI主动介入")
                .font(.caption)
        }
    }
    
    private var aiQuotaSection: some View {
        Section {
            HStack {
                Label("今日配额", systemImage: "sparkles")
                Spacer()
                Text("\(quotaService.remainingQuota) / \(quotaService.dailyQuota)")
                    .foregroundColor(quotaService.remainingQuota > 0 ? .primary : .red)
            }
            
            if quotaService.subscriptionTier == .free {
                HStack {
                    Label("下次重置", systemImage: "clock")
                    Spacer()
                    Text(quotaService.nextResetTime, style: .relative)
                        .foregroundColor(.secondary)
                }
            }
            
            NavigationLink {
                SubscriptionView(quotaService: quotaService)
                    .navigationBarBackButtonHidden()
            } label: {
                HStack {
                    Label("升级订阅", systemImage: "crown")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("AI 使用情况")
        }
    }
    
    private var cloudSyncSection: some View {
        CloudSyncSettingsView(syncManager: cloudSyncManager)
    }

    private var aiRoutingSection: some View {
        Section {
            Toggle("启用 BYOK（自带API密钥）", isOn: Binding(
                get: { FeatureFlags.shared.enableBYOK },
                set: { UserDefaults.standard.set($0, forKey: "ff.enableBYOK") }
            ))
            
            Toggle("优先云函数代理（官方额度）", isOn: Binding(
                get: { FeatureFlags.shared.useCloudProxyForLLM },
                set: { UserDefaults.standard.set($0, forKey: "ff.useCloudProxyForLLM") }
            ))
            
            NavigationLink {
                BYOKKeyEntryView()
                    .navigationTitle("API 密钥")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                Label("管理 OpenAI API Key", systemImage: "key.fill")
            }
        } header: {
            Text("AI 路由与密钥")
        } footer: {
            Text("默认通过云函数代理调用官方额度。开启 BYOK 后，改为使用你在设备 Keychain 中保存的 OpenAI API Key。")
                .font(.caption)
        }
    }
    
    private var growthOptimizationSection: some View {
        Section {
            NavigationLink {
                GrowthOptimizationDashboardView(growthService: growthOptimizationService)
                    .navigationTitle("成长分析")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                HStack {
                    Label("成长分析", systemImage: "chart.line.uptrend.xyaxis")
                    Spacer()
                    if growthOptimizationService.userEngagementScore > 0 {
                        Text("\(Int(growthOptimizationService.userEngagementScore))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !growthOptimizationService.conversionRecommendations.isEmpty {
                HStack {
                    Label("转化建议", systemImage: "lightbulb")
                    Spacer()
                    Text("\(growthOptimizationService.conversionRecommendations.count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        } header: {
            Text("成长优化")
        } footer: {
            Text("基于您的使用模式提供个性化建议，帮助您更好地利用应用功能。")
                .font(.caption)
        }
    }
    
    private var realtimeSyncSection: some View {
        RealtimeSyncSettingsView(syncService: realtimeSyncService)
    }
    
    private var dataManagementSection: some View {
        Section {
            Button {
                showResetConfirmation = true
            } label: {
                Label("重置交互数据", systemImage: "arrow.clockwise")
                    .foregroundColor(.red)
            }
            
            NavigationLink {
                DataExportView()
            } label: {
                Label("导出数据", systemImage: "square.and.arrow.up")
            }
        } header: {
            Text("数据管理")
        }
    }

    private var bgTasksSection: some View {
        Section {
            Button {
                BackgroundTaskManager.shared.scheduleAll()
            } label: {
                Label("立即调度后台任务", systemImage: "clock.arrow.2.circlepath")
            }
            .accessibilityLabel("Schedule Background Tasks")
            
            Button {
                BackgroundTaskManager.shared.setHandlers(
                    vectorIndex: { AppLogger.log("Manual vector index rebuild", category: .ai, type: .info) },
                    associationIncubation: { AppLogger.log("Manual association incubation", category: .ai, type: .info) },
                    forgettingScore: { AppLogger.log("Manual forgetting score", category: .ai, type: .info) }
                )
            } label: {
                Label("设置任务处理器（示例）", systemImage: "gearshape")
            }
        } header: {
            Text("后台任务")
        } footer: {
            Text("需要在 Info.plist 配置 BGTaskSchedulerPermittedIdentifiers，并在 Capabilities 中开启 Background Modes。").font(.caption)
        }
    }
    
    private var aboutSection: some View {
        Section {
            Button {
                showAbout = true
            } label: {
                HStack {
                    Label("关于 Prism", systemImage: "info.circle")
                    Spacer()
                    Text("v1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            
            Link(destination: URL(string: "https://prism.app/privacy")!) {
                Label("隐私政策", systemImage: "hand.raised")
            }
            
            Link(destination: URL(string: "https://prism.app/terms")!) {
                Label("服务条款", systemImage: "doc.text")
            }
        }
    }
    
    private func provideHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Interaction Mode Row
struct InteractionModeRow: View {
    let mode: InteractionMode
    let isSelected: Bool
    let confidence: Float?
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: modeIcon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(modeTitle)
                        .font(.callout)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    if isSelected, let confidence = confidence {
                        Text("适配度: \(Int(confidence * 100))%")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var modeIcon: String {
        switch mode {
        case .traditional:
            return "square.grid.2x2"
        case .gesture:
            return "hand.draw"
        case .adaptive:
            return "wand.and.rays"
        }
    }
    
    private var modeTitle: String {
        switch mode {
        case .traditional:
            return "传统按钮"
        case .gesture:
            return "手势控制"
        case .adaptive:
            return "智能自适应"
        }
    }
}

// MARK: - Cognitive Gear Picker
struct CognitiveGearPicker: View {
    @AppStorage("cognitiveGear") private var selectedGear: String = CognitiveGear.capture.rawValue
    
    var body: some View {
        Picker("认知档位", selection: $selectedGear) {
            ForEach(CognitiveGear.allCases, id: \.rawValue) { gear in
                Label {
                    Text(gearTitle(for: gear))
                } icon: {
                    Image(systemName: gearIcon(for: gear))
                }
                .tag(gear.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }
    
    private func gearTitle(for gear: CognitiveGear) -> String {
        switch gear {
        case .capture:
            return "速记"
        case .muse:
            return "缪斯"
        case .inquiry:
            return "审问"
        case .synthesis:
            return "综合"
        case .reflection:
            return "反思"
        }
    }
    
    private func gearIcon(for gear: CognitiveGear) -> String {
        switch gear {
        case .capture:
            return "pencil.line"
        case .muse:
            return "sparkles"
        case .inquiry:
            return "magnifyingglass"
        case .synthesis:
            return "link"
        case .reflection:
            return "moon.stars"
        }
    }
}

// MARK: - Data Export View
struct DataExportView: View {
    @State private var exportFormat = "json"
    @State private var includeEmbeddings = false
    @State private var isExporting = false
    
    var body: some View {
        Form {
            Section {
                Picker("导出格式", selection: $exportFormat) {
                    Text("JSON").tag("json")
                    Text("Markdown").tag("markdown")
                    Text("PDF").tag("pdf")
                }
                
                Toggle("包含向量数据", isOn: $includeEmbeddings)
            } header: {
                Text("导出选项")
            }
            
            Section {
                Button {
                    isExporting = true
                    // TODO: Implement export
                } label: {
                    if isExporting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("开始导出")
                    }
                }
                .disabled(isExporting)
            }
        }
        .navigationTitle("导出数据")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "brain")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Prism")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("共生认知系统")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Text("v1.0.0 (Build 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Divider()
                    .padding(.horizontal, 40)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Prism 是一个革命性的思维伙伴，通过 AI 增强您的认知能力，而非替代。")
                        .multilineTextAlignment(.center)
                    
                    Text("© 2025 Prism Team")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(
        interactionService: InteractionPreferenceService(),
        quotaService: QuotaManagementService(),
        cloudSyncManager: CloudSyncManager()
    )
}