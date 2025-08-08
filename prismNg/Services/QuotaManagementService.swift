//
//  QuotaManagementService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftData

// MARK: - Quota Management Service
@MainActor
class QuotaManagementService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentQuotaUsage: Int = 0
    @Published var dailyQuotaLimit: Int = 2  // Free tier: 2 AI calls per day
    @Published var quotaResetTime: Date?
    @Published var showQuotaExceededAlert: Bool = false
    @Published var showUpgradePrompt: Bool = false
    
    // MARK: - Private Properties
    private var modelContext: ModelContext?
    private var userConfiguration: UserConfiguration?
    private let calendar = Calendar.current
    
    // MARK: - Initialization
    init() {
        checkAndResetDailyQuota()
    }
    
    // MARK: - Setup
    func setup(modelContext: ModelContext, userConfiguration: UserConfiguration) {
        self.modelContext = modelContext
        self.userConfiguration = userConfiguration
        
        // Load current quota status
        loadQuotaStatus()
        
        // Check if quota needs reset
        checkAndResetDailyQuota()
    }
    
    // MARK: - Computed Properties
    var remainingQuota: Int {
        getRemainingQuota()
    }
    
    var dailyQuota: Int {
        dailyQuotaLimit
    }
    
    var subscriptionTier: SubscriptionTier {
        userConfiguration?.subscriptionTier ?? .free
    }
    
    var nextResetTime: Date {
        quotaResetTime ?? Date()
    }
    
    // MARK: - Quota Status Management
    private func loadQuotaStatus() {
        guard let config = userConfiguration else { return }
        
        currentQuotaUsage = config.aiQuotaUsed
        dailyQuotaLimit = config.aiQuotaLimit
        quotaResetTime = getNextResetTime()
    }
    
    private func checkAndResetDailyQuota() {
        guard let config = userConfiguration else { return }
        
        // Check if it's a new day
        if !calendar.isDate(config.lastQuotaReset, inSameDayAs: Date()) {
            // Reset quota
            config.aiQuotaUsed = 0
            config.lastQuotaReset = Date()
            currentQuotaUsage = 0
            
            // Save changes
            try? modelContext?.save()
            
            // Update reset time
            quotaResetTime = getNextResetTime()
        }
    }
    
    private func getNextResetTime() -> Date {
        // Calculate next reset time (midnight)
        let now = Date()
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let nextMidnight = calendar.dateInterval(of: .day, for: tomorrow)?.start else {
            return now
        }
        return nextMidnight
    }
    
    // MARK: - Quota Check and Usage
    func canUseAI() -> Bool {
        checkAndResetDailyQuota()
        return currentQuotaUsage < dailyQuotaLimit
    }
    
    func incrementQuotaUsage() -> Bool {
        guard canUseAI() else {
            showQuotaExceededAlert = true
            return false
        }
        
        guard let config = userConfiguration else { return false }
        
        config.aiQuotaUsed += 1
        currentQuotaUsage = config.aiQuotaUsed
        
        // Save changes
        try? modelContext?.save()
        
        // Check if approaching limit
        if currentQuotaUsage >= dailyQuotaLimit {
            showUpgradePrompt = true
        }
        
        return true
    }
    
    func getRemainingQuota() -> Int {
        return max(0, dailyQuotaLimit - currentQuotaUsage)
    }
    
    func getQuotaPercentage() -> Double {
        guard dailyQuotaLimit > 0 else { return 0 }
        return Double(currentQuotaUsage) / Double(dailyQuotaLimit)
    }
    
    // MARK: - Time Formatting
    func getTimeUntilReset() -> String {
        guard let resetTime = quotaResetTime else { return "Unknown" }
        
        let interval = resetTime.timeIntervalSince(Date())
        guard interval > 0 else { return "Resetting..." }
        
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Subscription Tier Management
    func updateSubscriptionTier(_ tier: SubscriptionTier) {
        guard let config = userConfiguration else { return }
        
        config.subscriptionTier = tier
        
        // Update quota limits based on tier
        switch tier {
        case .free:
            config.aiQuotaLimit = 2
        case .explorer:
            config.aiQuotaLimit = 50
        case .advanced:
            config.aiQuotaLimit = 500
        case .professional:
            config.aiQuotaLimit = -1  // Unlimited
        }
        
        dailyQuotaLimit = config.aiQuotaLimit
        
        // Save changes
        try? modelContext?.save()
    }
    
    func isUnlimitedQuota() -> Bool {
        return dailyQuotaLimit == -1
    }
}

// MARK: - Subscription Tier Extension
extension SubscriptionTier {
    var displayName: String {
        switch self {
        case .free:
            return "永久免费"
        case .explorer:
            return "探索者"
        case .advanced:
            return "进阶者"
        case .professional:
            return "专业版"
        }
    }
    
    var description: String {
        switch self {
        case .free:
            return "每日 2 次 AI 额度，完整本地功能"
        case .explorer:
            return "每日 50 次 AI 额度，云端同步"
        case .advanced:
            return "每日 500 次 AI 额度，高级分析"
        case .professional:
            return "无限 AI 额度，团队协作"
        }
    }
    
    var monthlyPrice: String {
        switch self {
        case .free:
            return "¥0"
        case .explorer:
            return "¥9.9"
        case .advanced:
            return "¥29.9"
        case .professional:
            return "¥99.9"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "每日 2 次 AI 智能分析",
                "无限本地节点创建",
                "手势与传统双轨交互",
                "本地向量搜索",
                "基础思维导图"
            ]
        case .explorer:
            return [
                "每日 50 次 AI 智能分析",
                "iCloud 自动同步",
                "情感计算系统",
                "智能联想推荐",
                "高级可视化效果"
            ]
        case .advanced:
            return [
                "每日 500 次 AI 智能分析",
                "跨设备实时同步",
                "深度结构分析",
                "知识图谱构建",
                "认知流状态引擎"
            ]
        case .professional:
            return [
                "无限 AI 智能分析",
                "团队实时协作",
                "中立 AI 引导者",
                "API 接口访问",
                "优先技术支持"
            ]
        }
    }
}

// MARK: - Quota Alert View
import SwiftUI

struct QuotaExceededAlert: View {
    @ObservedObject var quotaService: QuotaManagementService
    @State private var showUpgradeSheet = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("今日 AI 额度已用完")
                .font(.headline)
            
            Text("您今天的免费 AI 分析额度已经用完了")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("下次重置时间：\(quotaService.getTimeUntilReset())")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                Button("了解") {
                    quotaService.showQuotaExceededAlert = false
                }
                .buttonStyle(.bordered)
                
                Button("升级套餐") {
                    showUpgradeSheet = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .sheet(isPresented: $showUpgradeSheet) {
            SubscriptionUpgradeView(quotaService: quotaService)
        }
    }
}

// MARK: - Quota Status View
struct QuotaStatusView: View {
    @ObservedObject var quotaService: QuotaManagementService
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .foregroundColor(.purple)
            
            if quotaService.isUnlimitedQuota() {
                Text("AI 额度：无限")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("AI 额度：\(quotaService.getRemainingQuota())/\(quotaService.dailyQuotaLimit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Progress indicator
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(quotaService.getQuotaPercentage() > 0.8 ? Color.orange : Color.purple)
                            .frame(width: geometry.size.width * quotaService.getQuotaPercentage(), height: 4)
                    }
                }
                .frame(width: 50, height: 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

// MARK: - Subscription Upgrade View
struct SubscriptionUpgradeView: View {
    @ObservedObject var quotaService: QuotaManagementService
    @Environment(\.dismiss) var dismiss
    @State private var selectedTier: SubscriptionTier = .explorer
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("解锁更多 AI 能力")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("选择适合您的订阅计划")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Subscription tiers
                    ForEach(SubscriptionTier.allCases, id: \.self) { tier in
                        SubscriptionTierCard(
                            tier: tier,
                            isSelected: selectedTier == tier,
                            onTap: {
                                selectedTier = tier
                            }
                        )
                    }
                    
                    // Subscribe button
                    Button(action: {
                        // TODO: Implement subscription logic
                        quotaService.updateSubscriptionTier(selectedTier)
                        dismiss()
                    }) {
                        Text(selectedTier == .free ? "保持免费" : "立即订阅")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedTier == .free ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("升级订阅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Subscription Tier Card
struct SubscriptionTierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(tier.displayName)
                        .font(.headline)
                    
                    Text(tier.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(tier.monthlyPrice)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(tier == .free ? .green : .primary)
            }
            
            Divider()
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                ForEach(tier.features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
        .onTapGesture {
            onTap()
        }
        .padding(.horizontal)
    }
}