//
//  AICreditsView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP2: AI Credits View - AI积分管理界面
//

import SwiftUI
import Charts

// MARK: - AI Credits Dashboard

/// AI积分管理主界面
struct AICreditsView: View {
    @ObservedObject var creditsService: AICreditsService
    @ObservedObject var storeKitService: StoreKitService
    @State private var showingPurchaseOptions = false
    @State private var showingTransactionHistory = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Credits overview card
                    CreditsOverviewCard(creditsService: creditsService)
                    
                    // Usage chart
                    if !creditsService.monthlyUsageChart.isEmpty {
                        UsageChartCard(usageData: creditsService.monthlyUsageChart)
                    }
                    
                    // Quick actions
                    QuickActionsSection(
                        creditsService: creditsService,
                        onPurchase: { showingPurchaseOptions = true },
                        onViewHistory: { showingTransactionHistory = true }
                    )
                    
                    // Recent transactions
                    if !creditsService.recentTransactions.isEmpty {
                        RecentTransactionsSection(
                            transactions: Array(creditsService.recentTransactions.prefix(5))
                        )
                    }
                    
                    // Subscription info
                    SubscriptionInfoCard(
                        creditsService: creditsService,
                        storeKitService: storeKitService
                    )
                }
                .padding()
            }
            .navigationTitle("AI积分")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingPurchaseOptions) {
                PurchaseCreditsView(creditsService: creditsService)
            }
            .sheet(isPresented: $showingTransactionHistory) {
                TransactionHistoryView(creditsService: creditsService)
            }
            .sheet(isPresented: $showingSettings) {
                CreditsSettingsView(creditsService: creditsService)
            }
        }
    }
}

// MARK: - Credits Overview Card

struct CreditsOverviewCard: View {
    @ObservedObject var creditsService: AICreditsService
    
    var body: some View {
        VStack(spacing: 16) {
            if let status = creditsService.creditsStatus {
                // Balance display
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("当前余额")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("\(status.balance)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundColor(status.isLowBalance ? .orange : .primary)
                            
                            Text("积分")
                                .font(.title3)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 8)
                        }
                        
                        if status.isLowBalance {
                            Label("余额偏低", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 12) {
                        // Days until recharge
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("下次充值")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(status.daysUntilRecharge)天后")
                                .font(.callout)
                                .fontWeight(.medium)
                        }
                        
                        // Estimated days remaining
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("预计可用")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if status.estimatedDaysRemaining == Int.max {
                                Text("充足")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(.green)
                            } else {
                                Text("\(status.estimatedDaysRemaining)天")
                                    .font(.callout)
                                    .fontWeight(.medium)
                                    .foregroundColor(status.estimatedDaysRemaining < 7 ? .orange : .primary)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Usage stats
                HStack(spacing: 20) {
                    UsageStatItem(
                        title: "本月消费",
                        value: "\(status.consumptionThisMonth)",
                        icon: "minus.circle",
                        color: .orange
                    )
                    
                    UsageStatItem(
                        title: "月度额度",
                        value: "\(status.monthlyCredits)",
                        icon: "calendar",
                        color: .blue
                    )
                    
                    UsageStatItem(
                        title: "日均使用",
                        value: String(format: "%.1f", status.averageDailyUsage),
                        icon: "chart.line.uptrend.xyaxis",
                        color: .purple
                    )
                }
            } else {
                // Loading state
                ProgressView("加载积分信息...")
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
        )
    }
}

struct UsageStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Usage Chart Card

struct UsageChartCard: View {
    let usageData: [DailyUsage]
    @State private var selectedDataPoint: DailyUsage?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用趋势")
                .font(.headline)
            
            Chart(usageData) { usage in
                BarMark(
                    x: .value("日期", usage.date, unit: .day),
                    y: .value("积分", usage.credits)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                    AxisValueLabel(format: .dateTime.day().month(), centered: true)
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                        .font(.caption2)
                }
            }
            .chartBackground { proxy in
                if let selectedDataPoint {
                    GeometryReader { geometry in
                        let xPosition = proxy.position(forX: selectedDataPoint.date) ?? 0
                        
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 20, height: geometry.size.height)
                            .position(x: xPosition, y: geometry.size.height / 2)
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            if let date = proxy.value(atX: location.x, as: Date.self) {
                                selectedDataPoint = findClosestDataPoint(to: date)
                            }
                        }
                }
            }
            
            if let selected = selectedDataPoint {
                HStack {
                    Text(selected.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("消费 \(selected.credits) 积分")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private func findClosestDataPoint(to date: Date) -> DailyUsage? {
        let calendar = Calendar.current
        return usageData.min(by: { usage1, usage2 in
            let diff1 = abs(calendar.dateComponents([.day], from: usage1.date, to: date).day ?? 0)
            let diff2 = abs(calendar.dateComponents([.day], from: usage2.date, to: date).day ?? 0)
            return diff1 < diff2
        })
    }
}

// MARK: - Quick Actions Section

struct QuickActionsSection: View {
    @ObservedObject var creditsService: AICreditsService
    let onPurchase: () -> Void
    let onViewHistory: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            QuickActionCard(
                icon: "plus.circle.fill",
                title: "充值积分",
                color: .green,
                action: onPurchase
            )
            
            QuickActionCard(
                icon: "clock.arrow.circlepath",
                title: "查看历史",
                color: .blue,
                action: onViewHistory
            )
            
            if creditsService.creditsStatus?.isLowBalance ?? false {
                QuickActionCard(
                    icon: "bell.badge",
                    title: "设置提醒",
                    color: .orange,
                    action: {
                        // 设置低余额提醒
                    }
                )
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Transactions Section

struct RecentTransactionsSection: View {
    let transactions: [AICreditsTransaction]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近交易")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("查看全部") {
                    // Navigate to full history
                }
                .font(.caption)
            }
            
            VStack(spacing: 8) {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct TransactionRow: View {
    let transaction: AICreditsTransaction
    
    var body: some View {
        HStack {
            // Transaction type icon
            Image(systemName: transaction.transactionType.icon)
                .font(.callout)
                .foregroundColor(transaction.transactionType.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description)
                    .font(.callout)
                    .fontWeight(.medium)
                
                Text(transaction.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(transaction.amount > 0 ? "+" : "")\(transaction.amount)")
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.amount > 0 ? .green : .orange)
                
                Text("余额: \(transaction.balance)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Subscription Info Card

struct SubscriptionInfoCard: View {
    @ObservedObject var creditsService: AICreditsService
    @ObservedObject var storeKitService: StoreKitService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                
                Text("订阅信息")
                    .font(.headline)
            }
            
            if let subscription = storeKitService.currentSubscription {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscription.displayName)
                            .font(.callout)
                            .fontWeight(.medium)
                        
                        Text("每月 \(creditsService.creditsStatus?.monthlyCredits ?? 0) 积分")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("管理订阅") {
                        Task {
                            await storeKitService.manageSubscriptions()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                if creditsService.creditsStatus?.autoRechargeEnabled ?? false {
                    Label("自动充值已启用", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } else {
                VStack(spacing: 12) {
                    Text("升级订阅以获得更多积分")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    NavigationLink("查看订阅方案") {
                        // Navigate to subscription options
                    }
                    .font(.callout)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

// MARK: - Purchase Credits View

struct PurchaseCreditsView: View {
    @ObservedObject var creditsService: AICreditsService
    @Environment(\.dismiss) private var dismiss
    
    let creditPackages = [
        (amount: 100, price: 9.99, bonus: 0),
        (amount: 500, price: 39.99, bonus: 50),
        (amount: 1000, price: 69.99, bonus: 150),
        (amount: 2000, price: 119.99, bonus: 400)
    ]
    
    @State private var selectedPackage = 0
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current balance
                if let balance = creditsService.creditsStatus?.balance {
                    Text("当前余额: \(balance) 积分")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // Package selection
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(creditPackages.indices, id: \.self) { index in
                            CreditPackageCard(
                                amount: creditPackages[index].amount,
                                bonus: creditPackages[index].bonus,
                                price: creditPackages[index].price,
                                isSelected: selectedPackage == index,
                                onTap: {
                                    selectedPackage = index
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // Purchase button
                Button {
                    purchaseSelectedPackage()
                } label: {
                    HStack {
                        if isPurchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "creditcard")
                            Text("购买 ¥\(creditPackages[selectedPackage].price, specifier: "%.2f")")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isPurchasing)
                .padding(.horizontal)
            }
            .navigationTitle("充值积分")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("购买失败", isPresented: $showError) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func purchaseSelectedPackage() {
        let package = creditPackages[selectedPackage]
        isPurchasing = true
        
        Task {
            do {
                let totalCredits = package.amount + package.bonus
                try await creditsService.purchaseAdditionalCredits(
                    totalCredits,
                    price: Decimal(package.price)
                )
                
                await MainActor.run {
                    isPurchasing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isPurchasing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct CreditPackageCard: View {
    let amount: Int
    let bonus: Int
    let price: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("\(amount)")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if bonus > 0 {
                                Text("+\(bonus)")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text("积分")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("¥\(price, specifier: "%.2f")")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if bonus > 0 {
                            let totalAmount = amount + bonus
                            let pricePerCredit = price / Double(totalAmount)
                            Text("¥\(pricePerCredit, specifier: "%.3f")/积分")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if bonus > 0 {
                    let bonusPercentage = Double(bonus) / Double(amount) * 100
                    Text("赠送 \(Int(bonusPercentage))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Transaction History View

struct TransactionHistoryView: View {
    @ObservedObject var creditsService: AICreditsService
    @Environment(\.dismiss) private var dismiss
    @State private var filterType: AICreditsTransaction.TransactionType?
    
    var body: some View {
        NavigationView {
            List {
                // Filter section
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "全部",
                                isSelected: filterType == nil,
                                onTap: { filterType = nil }
                            )
                            
                            ForEach(AICreditsTransaction.TransactionType.allCases, id: \.self) { type in
                                FilterChip(
                                    title: type.displayName,
                                    isSelected: filterType == type,
                                    color: type.color,
                                    onTap: { filterType = type }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Transactions list
                Section {
                    ForEach(filteredTransactions) { transaction in
                        TransactionDetailRow(transaction: transaction)
                    }
                }
            }
            .navigationTitle("交易历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var filteredTransactions: [AICreditsTransaction] {
        if let filterType = filterType {
            return creditsService.recentTransactions.filter { $0.transactionType == filterType }
        } else {
            return creditsService.recentTransactions
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TransactionDetailRow: View {
    let transaction: AICreditsTransaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: transaction.transactionType.icon)
                    .foregroundColor(transaction.transactionType.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.description)
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Text(transaction.transactionType.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(transaction.amount > 0 ? "+" : "")\(transaction.amount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(transaction.amount > 0 ? .green : .orange)
                    
                    Text("余额: \(transaction.balance)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(transaction.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("·")
                    .foregroundColor(.secondary)
                
                Text(transaction.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Credits Settings View

struct CreditsSettingsView: View {
    @ObservedObject var creditsService: AICreditsService
    @Environment(\.dismiss) private var dismiss
    
    @State private var warningThreshold: Double = 20
    @State private var autoRechargeEnabled = true
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("余额提醒") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("低余额警告阈值")
                        
                        HStack {
                            Slider(value: $warningThreshold, in: 10...100, step: 10)
                            
                            Text("\(Int(warningThreshold))")
                                .font(.callout)
                                .fontWeight(.medium)
                                .frame(width: 40)
                        }
                        
                        Text("当余额低于此值时发送提醒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("自动充值") {
                    Toggle("启用月度自动充值", isOn: $autoRechargeEnabled)
                    
                    if autoRechargeEnabled {
                        Text("每月自动充值订阅套餐对应的积分额度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("保存设置") {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("积分设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadSettings()
            }
            .alert("设置已保存", isPresented: $showingConfirmation) {
                Button("确定") {
                    dismiss()
                }
            }
        }
    }
    
    private func loadSettings() {
        if let status = creditsService.creditsStatus {
            warningThreshold = Double(status.warningThreshold)
            autoRechargeEnabled = status.autoRechargeEnabled
        }
    }
    
    private func saveSettings() {
        Task {
            await creditsService.setWarningThreshold(Int(warningThreshold))
            await creditsService.toggleAutoRecharge(autoRechargeEnabled)
            
            await MainActor.run {
                showingConfirmation = true
            }
        }
    }
}

#Preview {
    AICreditsView(
        creditsService: AICreditsService(
            userId: "preview",
            storeKitService: StoreKitService(),
            quotaService: QuotaManagementService()
        ),
        storeKitService: StoreKitService()
    )
}