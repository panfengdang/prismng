//
//  StoreKitService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import StoreKit
import SwiftUI
import Combine
import UIKit

// MARK: - Store Product Identifiers
enum ProductIdentifier: String, CaseIterable {
    case explorer = "com.prismng.subscription.explorer"        // $2.99/月
    case advanced = "com.prismng.subscription.advanced"        // $14.99/月  
    case professional = "com.prismng.subscription.professional" // $49.99/月
    
    var subscriptionTier: SubscriptionTier {
        switch self {
        case .explorer: return .explorer
        case .advanced: return .advanced
        case .professional: return .professional
        }
    }
    
    var displayName: String {
        switch self {
        case .explorer: return "探索层"
        case .advanced: return "进阶层"
        case .professional: return "专业层"
        }
    }
    
    var description: String {
        switch self {
        case .explorer:
            return "一杯咖啡的价格，让思考更深入"
        case .advanced:
            return "完整的第二大脑体验"
        case .professional:
            return "企业级认知协作解决方案"
        }
    }
    
    var features: [String] {
        switch self {
        case .explorer:
            return [
                "每周50次AI互动",
                "进阶AI功能",
                "基础云备份",
                "无广告体验"
            ]
        case .advanced:
            return [
                "智能无限AI互动",
                "高级AI功能",
                "多设备云同步",
                "优先客服支持",
                "高级导出功能"
            ]
        case .professional:
            return [
                "团队协作空间",
                "专属AI模型",
                "API接口访问",
                "白标定制选项",
                "企业级安全",
                "专属客户成功经理"
            ]
        }
    }
}

// MARK: - Store Service
@MainActor
class StoreKitService: NSObject, ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<Product> = []
    @Published var currentSubscription: Product?
    @Published var subscriptionStatus: Product.SubscriptionInfo.RenewalState?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    override init() {
        super.init()
        
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products and restore purchases
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let productIds = ProductIdentifier.allCases.map { $0.rawValue }
            let storeProducts = try await Product.products(for: productIds)
            
            await MainActor.run {
                self.products = storeProducts.sorted { $0.price < $1.price }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load products: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Purchase Management
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            await MainActor.run {
                self.isLoading = false
            }
            
            switch result {
            case .success(let verification):
                let transaction = try await checkVerified(verification)
                
                // Update subscription status
                await checkSubscriptionStatus()
                
                // Finish the transaction
                await transaction.finish()
                
                return transaction
                
            case .userCancelled:
                return nil
                
            case .pending:
                await MainActor.run {
                    self.errorMessage = "Purchase is pending approval"
                }
                return nil
                
            @unknown default:
                await MainActor.run {
                    self.errorMessage = "Unknown purchase result"
                }
                return nil
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await checkSubscriptionStatus()
            
            await MainActor.run {
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Subscription Status
    
    func checkSubscriptionStatus() async {
        var validSubscriptions: Set<Product> = []
        var activeSubscription: Product?
        var renewalState: Product.SubscriptionInfo.RenewalState?
        
        // Check current entitlements
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try await checkVerified(result)
                
                // Find the product for this transaction
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    validSubscriptions.insert(product)
                    
                    // Keep track of the most expensive active subscription
                    if activeSubscription == nil || product.price > activeSubscription!.price {
                        activeSubscription = product
                    }
                }
                
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
        
        // Check renewal info for subscription status  
        if let activeProduct = activeSubscription,
           let subscription = activeProduct.subscription {
            
            // Get the subscription status
            Task {
                do {
                    let statuses = try await subscription.status
                    if let firstStatus = statuses.first {
                        await MainActor.run {
                            renewalState = firstStatus.state
                        }
                    }
                } catch {
                    print("Failed to get subscription status: \(error)")
                }
            }
        }
        
        await MainActor.run {
            self.purchasedProducts = validSubscriptions
            self.currentSubscription = activeSubscription
            self.subscriptionStatus = renewalState
        }
    }
    
    // MARK: - Transaction Listening
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in StoreKit.Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Update subscription status on main thread
                    await self.checkSubscriptionStatus()
                    
                    // Finish the transaction
                    await transaction.finish()
                    
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Verification
    
    private func checkVerified<T>(_ result: VerificationResult<T>) async throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Helper Methods
    
    func product(for identifier: ProductIdentifier) -> Product? {
        return products.first { $0.id == identifier.rawValue }
    }
    
    func isPurchased(_ product: Product) -> Bool {
        return purchasedProducts.contains(product)
    }
    
    func currentTier() -> SubscriptionTier {
        guard let currentProduct = currentSubscription,
              let identifier = ProductIdentifier(rawValue: currentProduct.id) else {
            return .free
        }
        return identifier.subscriptionTier
    }
    
    func isSubscriptionActive() -> Bool {
        guard let status = subscriptionStatus else { return false }
        
        switch status {
        case .subscribed:
            return true
        case .inGracePeriod:
            return true
        case .inBillingRetryPeriod:
            return false
        case .expired:
            return false
        case .revoked:
            return false
        default:
            return false
        }
    }
}

// MARK: - Store Errors

enum StoreError: Error, LocalizedError {
    case failedVerification
    case purchaseFailed(String)
    case networkError
    case userCancelled
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .networkError:
            return "Network connection error"
        case .userCancelled:
            return "Purchase was cancelled"
        }
    }
}

// MARK: - Product Extension

extension Product {
    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = priceFormatStyle.locale
        return formatter.string(from: price as NSDecimalNumber) ?? ""
    }
    
    var subscriptionPeriod: String {
        guard let subscription = subscription else { return "" }
        
        let unit = subscription.subscriptionPeriod.unit
        let value = subscription.subscriptionPeriod.value
        
        switch unit {
        case .day:
            return value == 1 ? "日" : "\(value)天"
        case .week:
            return value == 1 ? "周" : "\(value)周"
        case .month:
            return value == 1 ? "月" : "\(value)个月"
        case .year:
            return value == 1 ? "年" : "\(value)年"
        @unknown default:
            return ""
        }
    }
    
    var displayPrice: String {
        if subscription != nil {
            return "\(localizedPrice)/\(subscriptionPeriod)"
        } else {
            return localizedPrice
        }
    }
}

// MARK: - Subscription Management

extension StoreKitService {
    func cancelSubscription() async {
        // In iOS, subscriptions are managed through Settings app
        // We can only direct users there
        await MainActor.run {
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
    
    func manageSubscriptions() async {
        do {
            try await AppStore.showManageSubscriptions(in: UIApplication.shared.connectedScenes.first as! UIWindowScene)
        } catch {
            await MainActor.run {
                self.errorMessage = "Could not show subscription management: \(error.localizedDescription)"
            }
        }
    }
}