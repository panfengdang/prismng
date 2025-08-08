//
//  SyncServiceProtocol.swift
//  prismNg
//
//  Protocol abstraction for sync services (iCloud / Firebase)
//

import Foundation
import SwiftData

@MainActor
protocol SyncServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get }
    func setup(modelContext: ModelContext)
    func syncNode(_ node: ThoughtNode) async throws
    func fetchThoughtNodes() async throws -> [ThoughtNode]
    func startRealtimeSync() async throws
    func stopRealtimeSync()
}


