//
//  AIRequestRouter.swift
//  prismNg
//
//  Strategy router for AI calls: Cloud Functions proxy (default) vs BYOK (Keychain)
//

import Foundation
import SwiftUI

enum LLMBackendMode {
    case cloudProxy   // Firebase Functions proxy (official quota/cost controlled)
    case byok         // User brings own API key (Keychain)
    case mock         // Fallback/local-only
}

@MainActor
final class AIRequestRouter: ObservableObject {
    private let keychain: KeychainService
    private let featureFlags: FeatureFlags
    private let quotaService: QuotaManagementService
    
    init(quotaService: QuotaManagementService, keychain: KeychainService = KeychainService(), featureFlags: FeatureFlags = .shared) {
        self.quotaService = quotaService
        self.keychain = keychain
        self.featureFlags = featureFlags
    }
    
    func decideBackend(for task: HybridAITaskType, nodeCount: Int = 0) -> LLMBackendMode {
        // If proxy disabled globally, fallback to BYOK or mock
        if !featureFlags.useCloudProxyForLLM {
            return hasValidBYOK ? .byok : .mock
        }
        
        // If BYOK enabled and key present, honor user choice
        if featureFlags.enableBYOK && hasValidBYOK {
            return .byok
        }
        
        // Default to cloud proxy when quota allows
        if quotaService.canUseAI() {
            return .cloudProxy
        }
        
        // Fallback
        return .mock
    }
    
    var hasValidBYOK: Bool {
        guard let key = try? keychain.getOpenAIAPIKey() else { return false }
        return (key?.isEmpty == false)
    }
}


