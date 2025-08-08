//
//  CognitiveFlowTestView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import SwiftData

// MARK: - Test View for Cognitive Flow State Engine
struct CognitiveFlowTestView: View {
    @StateObject private var engine = CognitiveFlowStateEngine()
    @State private var actionLog: [String] = []
    @State private var nodeCount = 0
    @State private var editDepth = 0
    @State private var searchCount = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Current State Display
                VStack(alignment: .leading, spacing: 8) {
                    Label("Current State: \(stateDescription)", systemImage: stateIcon)
                        .font(.headline)
                        .foregroundColor(stateColor)
                    
                    if let recommendation = engine.activeRecommendation {
                        Text("Recommendation: \(recommendation.reason)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Action Simulation Buttons
                VStack(spacing: 12) {
                    Text("Simulate Actions:")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        ActionButton(title: "Create Node", systemImage: "plus.circle.fill") {
                            simulateNodeCreation()
                        }
                        
                        ActionButton(title: "Edit Node", systemImage: "pencil.circle.fill") {
                            simulateNodeEdit()
                        }
                        
                        ActionButton(title: "Search", systemImage: "magnifyingglass.circle.fill") {
                            simulateSearch()
                        }
                    }
                    
                    HStack(spacing: 12) {
                        ActionButton(title: "Connect", systemImage: "link.circle.fill") {
                            simulateConnection()
                        }
                        
                        ActionButton(title: "Long Edit", systemImage: "hourglass.circle.fill") {
                            simulateLongEdit()
                        }
                    }
                }
                .padding()
                
                // Statistics
                HStack(spacing: 20) {
                    StatView(title: "Nodes", value: "\(nodeCount)")
                    StatView(title: "Edits", value: "\(editDepth)")
                    StatView(title: "Searches", value: "\(searchCount)")
                }
                
                // Action Log
                VStack(alignment: .leading, spacing: 8) {
                    Text("Action Log:")
                        .font(.headline)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(actionLog.reversed(), id: \.self) { log in
                                Text(log)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Cognitive Recommendation View
                CognitiveRecommendationView(engine: engine)
                    .padding()
            }
            .navigationTitle("🧠 Cognitive Flow Test")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        resetTest()
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var stateDescription: String {
        switch engine.currentState {
        case .divergentThinking: return "Divergent Thinking"
        case .deepFocus: return "Deep Focus"
        case .informationSeeking: return "Information Seeking"
        case .collaboration: return "Collaboration"
        case .incubation: return "Incubation"
        case .neutral: return "Neutral"
        }
    }
    
    private var stateIcon: String {
        switch engine.currentState {
        case .divergentThinking: return "sparkles"
        case .deepFocus: return "eye"
        case .informationSeeking: return "magnifyingglass"
        case .collaboration: return "person.2"
        case .incubation: return "moon.zzz"
        case .neutral: return "circle"
        }
    }
    
    private var stateColor: Color {
        switch engine.currentState {
        case .divergentThinking: return .purple
        case .deepFocus: return .blue
        case .informationSeeking: return .orange
        case .collaboration: return .green
        case .incubation: return .indigo
        case .neutral: return .gray
        }
    }
    
    // MARK: - Action Simulations
    
    private func simulateNodeCreation() {
        let action = UserAction(
            type: .nodeCreation,
            timestamp: Date(),
            duration: nil,
            detail: "Test node \(nodeCount + 1)"
        )
        engine.trackAction(action)
        nodeCount += 1
        logAction("Created node #\(nodeCount)")
    }
    
    private func simulateNodeEdit() {
        let editText = String(repeating: "Edit text ", count: Int.random(in: 1...10))
        let action = UserAction(
            type: .nodeEdit,
            timestamp: Date(),
            duration: TimeInterval.random(in: 5...30),
            detail: editText
        )
        engine.trackAction(action)
        editDepth += editText.count
        logAction("Edited node (\(editText.count) chars)")
    }
    
    private func simulateLongEdit() {
        let editText = String(repeating: "Long edit text ", count: 20)
        let action = UserAction(
            type: .nodeEdit,
            timestamp: Date(),
            duration: 180, // 3 minutes
            detail: editText
        )
        engine.trackAction(action)
        editDepth += editText.count
        logAction("Long edit (3 min, \(editText.count) chars)")
    }
    
    private func simulateSearch() {
        let action = UserAction(
            type: .search,
            timestamp: Date(),
            duration: nil,
            detail: "Search query \(searchCount + 1)"
        )
        engine.trackAction(action)
        searchCount += 1
        logAction("Searched for query #\(searchCount)")
    }
    
    private func simulateConnection() {
        let action = UserAction(
            type: .connection,
            timestamp: Date(),
            duration: nil,
            detail: "Connected nodes"
        )
        engine.trackAction(action)
        logAction("Created connection")
    }
    
    private func logAction(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        actionLog.append("\(timestamp): \(message)")
        
        // Keep only last 20 logs
        if actionLog.count > 20 {
            actionLog.removeFirst()
        }
    }
    
    private func resetTest() {
        nodeCount = 0
        editDepth = 0
        searchCount = 0
        actionLog.removeAll()
        logAction("Test reset")
    }
}

// MARK: - Helper Views

struct ActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    CognitiveFlowTestView()
}
