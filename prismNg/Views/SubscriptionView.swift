//
//  SubscriptionView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import StoreKit

// MARK: - Subscription View
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeService = StoreKitService()
    @ObservedObject var quotaService: QuotaManagementService
    @State private var selectedProduct: Product?
    @State private var selectedTier: SubscriptionTier = .explorer
    @State private var showManageSubscriptions = false
    @State private var isProcessingPurchase = false
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Current Status
                    currentStatusCard
                    
                    // Subscription Tiers
                    if storeService.isLoading {
                        ProgressView("Loading products...")
                            .frame(height: 100)
                    } else {
                        tierSelectionSection
                    }
                    
                    // Features Comparison
                    featuresComparisonSection
                    
                    // Purchase Button
                    purchaseButton
                    
                    // Terms and Restore
                    termsSection
                }
                .padding()
            }
            .navigationTitle("升级订阅")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .alert("购买失败", isPresented: $showPurchaseError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(purchaseErrorMessage)
        }
        .onAppear {
            selectedTier = quotaService.subscriptionTier == .free ? .explorer : quotaService.subscriptionTier
        }
        .onChange(of: storeService.errorMessage) { errorMessage in
            if let error = errorMessage {
                purchaseErrorMessage = error
                showPurchaseError = true
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("解锁 Prism 的全部潜能")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("升级获得更多 AI 配额和高级功能")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    // MARK: - Current Status Card
    private var currentStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("当前套餐", systemImage: "person.circle")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quotaService.subscriptionTier.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("今日剩余: \(quotaService.remainingQuota) / \(quotaService.dailyQuota)")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if quotaService.subscriptionTier == .free {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("下次重置")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(quotaService.nextResetTime, style: .relative)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Tier Selection
    private var tierSelectionSection: some View {
        VStack(spacing: 16) {
            Text("选择适合你的套餐")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(storeService.products, id: \.id) { product in
                if let identifier = ProductIdentifier(rawValue: product.id) {
                    StoreKitTierCard(
                        product: product,
                        identifier: identifier,
                        isSelected: selectedProduct?.id == product.id,
                        isCurrentTier: storeService.currentTier() == identifier.subscriptionTier,
                        isPurchased: storeService.isPurchased(product),
                        onSelect: {
                            selectedProduct = product
                            selectedTier = identifier.subscriptionTier
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Features Comparison
    private var featuresComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("功能对比")
                .font(.headline)
            
            // Feature rows
            ForEach(comparisonFeatures, id: \.name) { feature in
                FeatureComparisonRow(feature: feature)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Purchase Button
    private var purchaseButton: some View {
        Button {
            processPurchase()
        } label: {
            Group {
                if isProcessingPurchase || storeService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(purchaseButtonText)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(purchaseButtonColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isProcessingPurchase || storeService.isLoading || selectedProduct == nil || storeService.currentTier() == selectedTier)
    }
    
    private var purchaseButtonText: String {
        guard let product = selectedProduct else { return "选择套餐" }
        
        if storeService.currentTier() == selectedTier {
            return "当前套餐"
        } else if storeService.currentTier() == .free {
            return "升级到 \(selectedTier.displayName) - \(product.displayPrice)"
        } else {
            return "更改为 \(selectedTier.displayName) - \(product.displayPrice)"
        }
    }
    
    private var purchaseButtonColor: Color {
        if storeService.currentTier() == selectedTier {
            return Color.gray
        } else {
            return Color.blue
        }
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        VStack(spacing: 12) {
            Button {
                restorePurchases()
            } label: {
                HStack {
                    if storeService.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("恢复购买")
                }
                .font(.callout)
                .foregroundColor(.blue)
            }
            .disabled(storeService.isLoading)
            
            HStack(spacing: 16) {
                Link("服务条款", destination: URL(string: "https://prism.app/terms")!)
                    .font(.caption)
                
                Link("隐私政策", destination: URL(string: "https://prism.app/privacy")!)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            Text("订阅将自动续费，可随时在设置中取消")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Helper Methods
    private func processPurchase() {
        guard let product = selectedProduct else { return }
        
        isProcessingPurchase = true
        
        Task {
            do {
                let transaction = try await storeService.purchase(product)
                
                await MainActor.run {
                    if transaction != nil {
                        // Update quota service with new tier
                        quotaService.updateSubscriptionTier(selectedTier)
                        dismiss()
                    }
                    isProcessingPurchase = false
                }
            } catch {
                await MainActor.run {
                    purchaseErrorMessage = error.localizedDescription
                    showPurchaseError = true
                    isProcessingPurchase = false
                }
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            await storeService.restorePurchases()
            
            // Update quota service based on restored purchases
            await MainActor.run {
                let currentTier = storeService.currentTier()
                quotaService.updateSubscriptionTier(currentTier)
            }
        }
    }
    
    // MARK: - Comparison Features
    private var comparisonFeatures: [ComparisonFeature] {
        [
            ComparisonFeature(
                name: "每日 AI 配额",
                free: "2 次",
                explorer: "50 次",
                advanced: "500 次",
                professional: "无限"
            ),
            ComparisonFeature(
                name: "本地功能",
                free: "✓",
                explorer: "✓",
                advanced: "✓",
                professional: "✓"
            ),
            ComparisonFeature(
                name: "云端同步",
                free: "✗",
                explorer: "✓",
                advanced: "✓",
                professional: "✓"
            ),
            ComparisonFeature(
                name: "情感计算",
                free: "✗",
                explorer: "✓",
                advanced: "✓",
                professional: "✓"
            ),
            ComparisonFeature(
                name: "深度分析",
                free: "✗",
                explorer: "✗",
                advanced: "✓",
                professional: "✓"
            ),
            ComparisonFeature(
                name: "团队协作",
                free: "✗",
                explorer: "✗",
                advanced: "✗",
                professional: "✓"
            )
        ]
    }
}

// MARK: - StoreKit Tier Card
struct StoreKitTierCard: View {
    let product: Product
    let identifier: ProductIdentifier
    let isSelected: Bool
    let isCurrentTier: Bool
    let isPurchased: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(identifier.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            if isCurrentTier {
                                Text("当前")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                            
                            if identifier == .professional {
                                Text("最受欢迎")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(identifier.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(product.localizedPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/\(product.subscriptionPeriod)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Key features
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(identifier.features.prefix(3), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                // Purchase status indicator
                if isPurchased && !isCurrentTier {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已购买")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legacy Tier Card (for fallback)
struct TierCard: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let isCurrentTier: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(tier.displayName)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            if isCurrentTier {
                                Text("当前")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                            
                            if tier == .professional {
                                Text("最受欢迎")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                        
                        Text(tier.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(tier.monthlyPrice)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("/月")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Key features
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(tier.features.prefix(3), id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(feature)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Feature Comparison Row
struct FeatureComparisonRow: View {
    let feature: ComparisonFeature
    
    var body: some View {
        HStack {
            Text(feature.name)
                .font(.callout)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            HStack(spacing: 20) {
                FeatureValue(value: feature.free, tier: .free)
                FeatureValue(value: feature.explorer, tier: .explorer)
                FeatureValue(value: feature.advanced, tier: .advanced)
                FeatureValue(value: feature.professional, tier: .professional)
            }
        }
    }
}

struct FeatureValue: View {
    let value: String
    let tier: SubscriptionTier
    
    var body: some View {
        VStack(spacing: 4) {
            Text(tier.displayName.prefix(2))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if value == "✓" {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else if value == "✗" {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.gray)
                    .font(.caption)
            } else {
                Text(value)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
        }
        .frame(width: 50)
    }
}

// MARK: - Supporting Types
struct ComparisonFeature {
    let name: String
    let free: String
    let explorer: String
    let advanced: String
    let professional: String
}

#Preview {
    SubscriptionView(quotaService: QuotaManagementService())
}