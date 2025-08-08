//
//  AICreditsService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP2: AI Credits Service - 官方AI点数系统
//

import Foundation
import SwiftUI
import Combine

// MARK: - AI Credits Models

/// AI积分套餐类型
struct AICreditsPackage: Identifiable, Codable {
    let id: String
    let name: String
    let credits: Int
    let monthlyRecharge: Bool  // 是否每月自动充值
    let subscriptionTier: SubscriptionTier
    
    static let packages: [AICreditsPackage] = [
        AICreditsPackage(
            id: "free",
            name: "免费额度",
            credits: 60,  // 每日2次 * 30天
            monthlyRecharge: true,
            subscriptionTier: .free
        ),
        AICreditsPackage(
            id: "explorer",
            name: "探索层套餐",
            credits: 200,  // 每周50次
            monthlyRecharge: true,
            subscriptionTier: .explorer
        ),
        AICreditsPackage(
            id: "advanced",
            name: "进阶层套餐",
            credits: 1000,
            monthlyRecharge: true,
            subscriptionTier: .advanced
        ),
        AICreditsPackage(
            id: "professional",
            name: "专业层套餐",
            credits: 5000,  // 团队额度
            monthlyRecharge: true,
            subscriptionTier: .professional
        )
    ]
}

/// AI积分交易记录
struct AICreditsTransaction: Identifiable, Codable {
    let id: String
    let userId: String
    let amount: Int  // 正数为充值，负数为消费
    let balance: Int  // 交易后余额
    let transactionType: TransactionType
    let description: String
    let timestamp: Date
    let metadata: [String: String]?
    
    enum TransactionType: String, Codable, CaseIterable {
        case monthlyRecharge = "monthly_recharge"     // 月度充值
        case purchase = "purchase"                    // 购买充值
        case consumption = "consumption"              // AI调用消费
        case bonus = "bonus"                          // 奖励赠送
        case refund = "refund"                        // 退款
        case adjustment = "adjustment"                // 系统调整
        
        var displayName: String {
            switch self {
            case .monthlyRecharge: return "月度充值"
            case .purchase: return "购买充值"
            case .consumption: return "AI消费"
            case .bonus: return "奖励赠送"
            case .refund: return "退款"
            case .adjustment: return "系统调整"
            }
        }
        
        var icon: String {
            switch self {
            case .monthlyRecharge: return "calendar.circle"
            case .purchase: return "creditcard"
            case .consumption: return "minus.circle"
            case .bonus: return "gift"
            case .refund: return "arrow.uturn.backward"
            case .adjustment: return "wrench"
            }
        }
        
        var color: Color {
            switch self {
            case .monthlyRecharge, .purchase, .bonus:
                return .green
            case .consumption:
                return .orange
            case .refund:
                return .blue
            case .adjustment:
                return .purple
            }
        }
    }
}

/// AI功能消费配置
struct AIFeatureCredits {
    static let costs: [String: Int] = [
        "ai_lens": 3,              // AI透镜
        "structured_analysis": 5,   // 结构化分析
        "evolution_summary": 7,     // 进化摘要
        "identity_simulation": 10,  // 身份模拟
        "deep_search": 8,          // 深度搜索
        "team_ai_mediation": 15,   // 团队AI调解
        "custom_ai_model": 20      // 定制AI模型
    ]
    
    static func getCost(for feature: String) -> Int {
        return costs[feature] ?? 5  // 默认5积分
    }
}

/// 用户AI积分状态
struct UserCreditsStatus: Codable {
    let userId: String
    var balance: Int
    var monthlyCredits: Int
    var lastRechargeDate: Date
    var subscriptionTier: SubscriptionTier
    var consumptionThisMonth: Int
    var averageDailyUsage: Double
    var warningThreshold: Int  // 余额警告阈值
    var autoRechargeEnabled: Bool
    
    var isLowBalance: Bool {
        return balance <= warningThreshold
    }
    
    var daysUntilRecharge: Int {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: lastRechargeDate) ?? Date()
        let days = calendar.dateComponents([.day], from: Date(), to: nextMonth).day ?? 0
        return max(0, days)
    }
    
    var estimatedDaysRemaining: Int {
        guard averageDailyUsage > 0 else { return Int.max }
        return Int(Double(balance) / averageDailyUsage)
    }
}

// MARK: - AI Credits Service

/// AI积分管理服务
@MainActor
class AICreditsService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var creditsStatus: UserCreditsStatus?
    @Published var recentTransactions: [AICreditsTransaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var monthlyUsageChart: [DailyUsage] = []
    
    // MARK: - Private Properties
    private let firebaseManager = FirebaseManager.shared
    private var statusListener: Any? // Would be ListenerRegistration with real Firebase
    private var transactionsListener: Any?
    private var cancellables = Set<AnyCancellable>()
    private let userId: String
    
    // MARK: - Dependencies
    private let storeKitService: StoreKitService
    private let quotaService: QuotaManagementService
    
    init(userId: String, storeKitService: StoreKitService, quotaService: QuotaManagementService) {
        self.userId = userId
        self.storeKitService = storeKitService
        self.quotaService = quotaService
        
        setupListeners()
        checkAndPerformMonthlyRecharge()
    }
    
    deinit {
        // Would cleanup Firebase listeners in real implementation
        // statusListener?.remove()
        // transactionsListener?.remove()
    }
    
    // MARK: - Setup
    
    private func setupListeners() {
        // In a real implementation, this would use Firestore listeners
        // For now, simulate with initial data
        Task {
            initializeCreditsStatus()
            
            // Simulate some transaction history
            await MainActor.run {
                self.recentTransactions = [
                    AICreditsTransaction(
                        id: UUID().uuidString,
                        userId: userId,
                        amount: -3,
                        balance: 57,
                        transactionType: .consumption,
                        description: "使用 AI透镜",
                        timestamp: Date().addingTimeInterval(-3600),
                        metadata: ["feature": "ai_lens"]
                    ),
                    AICreditsTransaction(
                        id: UUID().uuidString,
                        userId: userId,
                        amount: 60,
                        balance: 60,
                        transactionType: .monthlyRecharge,
                        description: "月度充值",
                        timestamp: Date().addingTimeInterval(-86400),
                        metadata: ["tier": "free"]
                    )
                ]
                self.updateUsageChart(self.recentTransactions)
            }
        }
        
        // 监听订阅状态变化
        storeKitService.$currentSubscription
            .sink { [weak self] _ in
                self?.updateCreditsForSubscriptionChange()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Credits Management
    
    /// 消费AI积分
    func consumeCredits(for feature: String, amount: Int? = nil) async throws {
        guard let status = creditsStatus else {
            throw CreditsError.statusNotLoaded
        }
        
        let cost = amount ?? AIFeatureCredits.getCost(for: feature)
        
        // 检查余额
        if status.balance < cost {
            throw CreditsError.insufficientCredits(needed: cost, available: status.balance)
        }
        
        // 创建消费交易
        let transaction = AICreditsTransaction(
            id: UUID().uuidString,
            userId: userId,
            amount: -cost,
            balance: status.balance - cost,
            transactionType: .consumption,
            description: "使用 \(feature)",
            timestamp: Date(),
            metadata: ["feature": feature]
        )
        
        // 更新数据库
        try await performTransaction(transaction)
        
        // 更新配额服务
        _ = quotaService.incrementQuotaUsage()
    }
    
    /// 月度充值
    private func performMonthlyRecharge() async throws {
        guard let status = creditsStatus,
              status.autoRechargeEnabled else { return }
        
        // 获取当前订阅对应的积分套餐
        let currentTier = storeKitService.currentTier()
        guard let package = AICreditsPackage.packages.first(where: { $0.subscriptionTier == currentTier }) else {
            return
        }
        
        // 创建充值交易
        let transaction = AICreditsTransaction(
            id: UUID().uuidString,
            userId: userId,
            amount: package.credits,
            balance: status.balance + package.credits,
            transactionType: .monthlyRecharge,
            description: "\(package.name) 月度充值",
            timestamp: Date(),
            metadata: ["package": package.id, "tier": currentTier.rawValue]
        )
        
        try await performTransaction(transaction)
        
        // 更新最后充值日期
        if var status = creditsStatus {
            status.lastRechargeDate = Date()
            status.monthlyCredits = package.credits
            creditsStatus = status
            
            // Save to Firebase
            _ = try await firebaseManager.saveDocument(
                status,
                to: "users/\(userId)/credits",
                documentId: "status"
            )
        }
    }
    
    /// 执行交易
    private func performTransaction(_ transaction: AICreditsTransaction) async throws {
        // In real implementation, this would use Firestore batch operations
        // For now, simulate the transaction
        
        // Update local state
        await MainActor.run {
            self.recentTransactions.insert(transaction, at: 0)
            if self.recentTransactions.count > 20 {
                self.recentTransactions = Array(self.recentTransactions.prefix(20))
            }
            
            // Update status
            if var status = self.creditsStatus {
                status.balance = transaction.balance
                if transaction.transactionType == .consumption {
                    status.consumptionThisMonth += -transaction.amount
                }
                self.creditsStatus = status
            }
            
            self.updateUsageChart(self.recentTransactions)
        }
        
        // Simulate saving to Firebase
        try await firebaseManager.saveDocument(
            transaction,
            to: "users/\(userId)/credits/transactions/records",
            documentId: transaction.id
        )
    }
    
    // MARK: - Initialization
    
    private func initializeCreditsStatus() {
        Task {
            do {
                let currentTier = storeKitService.currentTier()
                let package = AICreditsPackage.packages.first(where: { $0.subscriptionTier == currentTier }) ?? AICreditsPackage.packages[0]
                
                let initialStatus = UserCreditsStatus(
                    userId: userId,
                    balance: package.credits,
                    monthlyCredits: package.credits,
                    lastRechargeDate: Date(),
                    subscriptionTier: currentTier,
                    consumptionThisMonth: 0,
                    averageDailyUsage: 0,
                    warningThreshold: 20,
                    autoRechargeEnabled: true
                )
                
                try await firebaseManager.saveDocument(
                    initialStatus,
                    to: "users/\(userId)/credits",
                    documentId: "status"
                )
                
                await MainActor.run {
                    self.creditsStatus = initialStatus
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = "初始化积分状态失败: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Subscription Management
    
    private func updateCreditsForSubscriptionChange() {
        guard let newTier = storeKitService.currentSubscription else { return }
        
        Task {
            // 如果订阅升级，立即补充差额积分
            if let currentStatus = creditsStatus,
               let newPackage = AICreditsPackage.packages.first(where: { 
                   $0.subscriptionTier == storeKitService.currentTier() 
               }),
               newPackage.credits > currentStatus.monthlyCredits {
                
                let bonusCredits = newPackage.credits - currentStatus.monthlyCredits
                
                let bonusTransaction = AICreditsTransaction(
                    id: UUID().uuidString,
                    userId: userId,
                    amount: bonusCredits,
                    balance: currentStatus.balance + bonusCredits,
                    transactionType: .bonus,
                    description: "订阅升级奖励",
                    timestamp: Date(),
                    metadata: ["reason": "subscription_upgrade"]
                )
                
                try? await performTransaction(bonusTransaction)
            }
        }
    }
    
    // MARK: - Monthly Recharge Check
    
    private func checkAndPerformMonthlyRecharge() {
        guard let status = creditsStatus else { return }
        
        let calendar = Calendar.current
        let lastRechargeMonth = calendar.component(.month, from: status.lastRechargeDate)
        let currentMonth = calendar.component(.month, from: Date())
        
        // 如果跨月了，执行充值
        if lastRechargeMonth != currentMonth {
            Task {
                try? await performMonthlyRecharge()
            }
        }
    }
    
    // MARK: - Warnings & Notifications
    
    private func checkLowBalanceWarning(_ status: UserCreditsStatus) {
        if status.isLowBalance {
            // 发送低余额通知
            NotificationCenter.default.post(
                name: .aiCreditsLowBalance,
                object: status
            )
        }
    }
    
    // MARK: - Usage Analytics
    
    private func updateUsageChart(_ transactions: [AICreditsTransaction]) {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // 过滤最近30天的消费记录
        let consumptions = transactions.filter { 
            $0.transactionType == .consumption && 
            $0.timestamp > thirtyDaysAgo 
        }
        
        // 按天分组
        let grouped = Dictionary(grouping: consumptions) { transaction in
            calendar.startOfDay(for: transaction.timestamp)
        }
        
        // 创建每日使用数据
        var dailyUsages: [DailyUsage] = []
        
        for day in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -day, to: Date()) ?? Date()
            let dayStart = calendar.startOfDay(for: date)
            
            let dayConsumption = grouped[dayStart]?.reduce(0) { $0 + (-$1.amount) } ?? 0
            
            dailyUsages.append(DailyUsage(
                date: dayStart,
                credits: dayConsumption
            ))
        }
        
        monthlyUsageChart = dailyUsages.reversed()
        
        // 计算平均每日使用量
        let totalUsage = dailyUsages.reduce(0) { $0 + $1.credits }
        let averageUsage = Double(totalUsage) / 30.0
        
        // 更新平均使用量
        Task {
            if var status = creditsStatus {
                status.averageDailyUsage = averageUsage
                creditsStatus = status
                
                try? await firebaseManager.saveDocument(
                    status,
                    to: "users/\(userId)/credits",
                    documentId: "status"
                )
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 购买额外积分包
    func purchaseAdditionalCredits(_ amount: Int, price: Decimal) async throws {
        // 这里应该先通过 StoreKit 完成支付
        // 支付成功后再添加积分
        
        let purchaseTransaction = AICreditsTransaction(
            id: UUID().uuidString,
            userId: userId,
            amount: amount,
            balance: (creditsStatus?.balance ?? 0) + amount,
            transactionType: .purchase,
            description: "购买 \(amount) 积分",
            timestamp: Date(),
            metadata: ["price": "\(price)"]
        )
        
        try await performTransaction(purchaseTransaction)
    }
    
    /// 获取功能消费预估
    func estimateCreditsNeeded(for features: [String]) -> Int {
        return features.reduce(0) { $0 + AIFeatureCredits.getCost(for: $1) }
    }
    
    /// 检查是否有足够积分
    func canAfford(feature: String) -> Bool {
        let cost = AIFeatureCredits.getCost(for: feature)
        return (creditsStatus?.balance ?? 0) >= cost
    }
    
    /// 设置低余额警告阈值
    func setWarningThreshold(_ threshold: Int) async {
        guard threshold > 0 else { return }
        
        do {
            if var status = creditsStatus {
                status.warningThreshold = threshold
                creditsStatus = status
                
                try await firebaseManager.saveDocument(
                    status,
                    to: "users/\(userId)/credits",
                    documentId: "status"
                )
            }
        } catch {
            errorMessage = "更新警告阈值失败: \(error.localizedDescription)"
        }
    }
    
    /// 切换自动充值
    func toggleAutoRecharge(_ enabled: Bool) async {
        do {
            if var status = creditsStatus {
                status.autoRechargeEnabled = enabled
                creditsStatus = status
                
                try await firebaseManager.saveDocument(
                    status,
                    to: "users/\(userId)/credits",
                    documentId: "status"
                )
            }
        } catch {
            errorMessage = "更新自动充值设置失败: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Models

struct DailyUsage: Identifiable {
    let id = UUID()
    let date: Date
    let credits: Int
}

// MARK: - Errors

enum CreditsError: LocalizedError {
    case statusNotLoaded
    case insufficientCredits(needed: Int, available: Int)
    case transactionFailed(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .statusNotLoaded:
            return "积分状态尚未加载"
        case .insufficientCredits(let needed, let available):
            return "积分不足：需要 \(needed) 积分，当前余额 \(available) 积分"
        case .transactionFailed(let message):
            return "交易失败：\(message)"
        case .networkError:
            return "网络连接错误"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let aiCreditsLowBalance = Notification.Name("aiCreditsLowBalance")
    static let aiCreditsRecharged = Notification.Name("aiCreditsRecharged")
    static let aiCreditsConsumed = Notification.Name("aiCreditsConsumed")
}