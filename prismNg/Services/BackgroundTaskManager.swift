//
//  BackgroundTaskManager.swift
//  prismNg
//
//  BGProcessing for vector index rebuild, weak association incubation, forgetting score updates
//

import Foundation
import BackgroundTasks

enum BGTaskIdentifier: String {
    case vectorIndex = "com.prismng.bg.vectorIndex"
    case associationIncubation = "com.prismng.bg.associationIncubation"
    case forgettingScore = "com.prismng.bg.forgettingScore"
}

final class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()
    private init() {}
    
    // Handlers can be set at runtime (Dependency Injection via closures)
    private var onVectorIndex: (() -> Void)?
    private var onAssociationIncubation: (() -> Void)?
    private var onForgettingScore: (() -> Void)?
    
    func setHandlers(
        vectorIndex: (() -> Void)? = nil,
        associationIncubation: (() -> Void)? = nil,
        forgettingScore: (() -> Void)? = nil
    ) {
        self.onVectorIndex = vectorIndex
        self.onAssociationIncubation = associationIncubation
        self.onForgettingScore = forgettingScore
    }
    
    func registerTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BGTaskIdentifier.vectorIndex.rawValue, using: nil) { task in
            self.handleVectorIndexTask(task: task as! BGProcessingTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BGTaskIdentifier.associationIncubation.rawValue, using: nil) { task in
            self.handleAssociationIncubation(task: task as! BGProcessingTask)
        }
        BGTaskScheduler.shared.register(forTaskWithIdentifier: BGTaskIdentifier.forgettingScore.rawValue, using: nil) { task in
            self.handleForgettingScore(task: task as! BGProcessingTask)
        }
    }
    
    func scheduleAll() {
        scheduleVectorIndex()
        scheduleAssociationIncubation()
        scheduleForgettingScore()
    }
    
    private func scheduleVectorIndex() {
        let request = BGProcessingTaskRequest(identifier: BGTaskIdentifier.vectorIndex.rawValue)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func scheduleAssociationIncubation() {
        let request = BGProcessingTaskRequest(identifier: BGTaskIdentifier.associationIncubation.rawValue)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func scheduleForgettingScore() {
        let request = BGProcessingTaskRequest(identifier: BGTaskIdentifier.forgettingScore.rawValue)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        try? BGTaskScheduler.shared.submit(request)
    }
    
    private func handleVectorIndexTask(task: BGProcessingTask) {
        let queue = DispatchQueue.global(qos: .utility)
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        queue.async {
            self.onVectorIndex?()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func handleAssociationIncubation(task: BGProcessingTask) {
        let queue = DispatchQueue.global(qos: .utility)
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        queue.async {
            self.onAssociationIncubation?()
            task.setTaskCompleted(success: true)
        }
    }
    
    private func handleForgettingScore(task: BGProcessingTask) {
        let queue = DispatchQueue.global(qos: .utility)
        task.expirationHandler = { task.setTaskCompleted(success: false) }
        queue.async {
            self.onForgettingScore?()
            task.setTaskCompleted(success: true)
        }
    }
}


