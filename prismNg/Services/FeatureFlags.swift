//
//  FeatureFlags.swift
//  prismNg
//
//  Centralized feature flags for runtime switches
//

import Foundation

final class FeatureFlags {
    static let shared = FeatureFlags()
    
    // AI routing
    var enableBYOK: Bool {
        UserDefaults.standard.bool(forKey: "ff.enableBYOK")
    }
    
    var useCloudProxyForLLM: Bool {
        // default true
        if UserDefaults.standard.object(forKey: "ff.useCloudProxyForLLM") == nil { return true }
        return UserDefaults.standard.bool(forKey: "ff.useCloudProxyForLLM")
    }
    
    // Realtime sync
    var enableRealtimeSync: Bool {
        if UserDefaults.standard.object(forKey: "ff.enableRealtimeSync") == nil { return true }
        return UserDefaults.standard.bool(forKey: "ff.enableRealtimeSync")
    }
}


