//
//  prismNgApp.swift
//  prismNg
//
//  Created by suntiger on 2025/8/5.
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct prismNgApp: App {
    @StateObject private var quotaService = QuotaManagementService()
    
    init() {
        print("PrismNg App initializing...")
        // Firebase初始化暂时跳过，避免崩溃
        // FirebaseManager.shared.initialize()
        // Register background tasks
        BackgroundTaskManager.shared.registerTasks()
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ThoughtNode.self,
            NodeConnection.self,
            AITask.self,
            UserConfiguration.self,
            EmotionalMarker.self,
            Item.self  // Keep for migration compatibility
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(quotaService)
                .environmentObject(FirebaseManager.shared)
                .onAppear {
                    print("ContentView appeared in WindowGroup")
                    BackgroundTaskManager.shared.scheduleAll()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
