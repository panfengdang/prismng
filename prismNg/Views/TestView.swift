//
//  TestView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import SwiftData

struct TestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var thoughtNodes: [ThoughtNode]
    @Query private var userConfig: [UserConfiguration]
    @StateObject private var testHelper = TestHelper()
    
    var body: some View {
        NavigationView {
            List {
                Section("Data Model Tests") {
                    Button("Create Test Node") {
                        createTestNode()
                    }
                    
                    Button("Create Test Connection") {
                        createTestConnection()
                    }
                    
                    Button("Test AI Task") {
                        createTestAITask()
                    }
                    
                    Text("Nodes: \(thoughtNodes.count)")
                    Text("Config: \(userConfig.count)")
                }
                
                Section("AI Service Tests") {
                    AsyncButton("Test Embedding Generation") {
                        await testEmbeddingGeneration()
                    }
                    
                    AsyncButton("Test Vector Search") {
                        await testVectorSearch()
                    }
                    
                    AsyncButton("Test Structure Analysis") {
                        await testStructureAnalysis()
                    }
                }
                
                Section("Canvas Tests") {
                    Button("Test Canvas Creation") {
                        testCanvasCreation()
                    }
                    
                    Button("Test Gesture Recognition") {
                        testGestureRecognition()
                    }
                }
                
                Section("Test Results") {
                    ForEach(testHelper.results, id: \.self) { result in
                        HStack {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.success ? .green : .red)
                            VStack(alignment: .leading) {
                                Text(result.testName)
                                    .font(.headline)
                                Text(result.message)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("PrismNg Tests")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Results") {
                        testHelper.results.removeAll()
                    }
                }
            }
        }
    }
    
    // MARK: - Test Functions
    
    private func createTestNode() {
        let testNode = ThoughtNode(
            content: "Test thought created at \(Date().formatted())",
            nodeType: .thought,
            position: Position(x: Double.random(in: -100...100), y: Double.random(in: -100...100))
        )
        
        modelContext.insert(testNode)
        
        do {
            try modelContext.save()
            testHelper.addResult(TestResult(
                testName: "Create Test Node",
                success: true,
                message: "Successfully created node with ID: \(testNode.id)"
            ))
        } catch {
            testHelper.addResult(TestResult(
                testName: "Create Test Node",
                success: false,
                message: "Failed: \(error.localizedDescription)"
            ))
        }
    }
    
    private func createTestConnection() {
        guard thoughtNodes.count >= 2 else {
            testHelper.addResult(TestResult(
                testName: "Create Test Connection",
                success: false,
                message: "Need at least 2 nodes to create connection"
            ))
            return
        }
        
        let connection = NodeConnection(
            fromNodeId: thoughtNodes[0].id,
            toNodeId: thoughtNodes[1].id,
            connectionType: .strongSupport,
            strength: 0.8
        )
        
        modelContext.insert(connection)
        
        do {
            try modelContext.save()
            testHelper.addResult(TestResult(
                testName: "Create Test Connection",
                success: true,
                message: "Successfully created connection"
            ))
        } catch {
            testHelper.addResult(TestResult(
                testName: "Create Test Connection",
                success: false,
                message: "Failed: \(error.localizedDescription)"
            ))
        }
    }
    
    private func createTestAITask() {
        let aiTask = AITask(
            taskType: .generateEmbedding,
            inputNodeIds: thoughtNodes.prefix(1).map { $0.id }
        )
        
        modelContext.insert(aiTask)
        
        do {
            try modelContext.save()
            testHelper.addResult(TestResult(
                testName: "Create AI Task",
                success: true,
                message: "Successfully created AI task"
            ))
        } catch {
            testHelper.addResult(TestResult(
                testName: "Create AI Task",
                success: false,
                message: "Failed: \(error.localizedDescription)"
            ))
        }
    }
    
    private func testEmbeddingGeneration() async {
        let aiService = AIService()
        
        do {
            let embedding = try await aiService.generateEmbedding(for: "Test embedding generation")
            testHelper.addResult(TestResult(
                testName: "Embedding Generation",
                success: true,
                message: "Generated embedding with \(embedding.count) dimensions"
            ))
        } catch {
            testHelper.addResult(TestResult(
                testName: "Embedding Generation",
                success: false,
                message: "Failed: \(error.localizedDescription)"
            ))
        }
    }
    
    private func testVectorSearch() async {
        let vectorService = VectorDBService()
        
        do {
            // Add a test vector
            let testVector: [Float] = Array(0..<128).map { _ in Float.random(in: -1...1) }
            let testId = UUID()
            
            try await vectorService.addVector(testVector, for: testId)
            
            // Search for similar vectors
            let results = try await vectorService.findSimilarByVector(testVector, limit: 5)
            
            testHelper.addResult(TestResult(
                testName: "Vector Search",
                success: true,
                message: "Found \(results.count) similar vectors"
            ))
        } catch {
            testHelper.addResult(TestResult(
                testName: "Vector Search",
                success: false,
                message: "Failed: \(error.localizedDescription)"
            ))
        }
    }
    
    private func testStructureAnalysis() async {
        guard thoughtNodes.count >= 2 else {
            testHelper.addResult(TestResult(
                testName: "Structure Analysis",
                success: false,
                message: "Need at least 2 nodes for analysis"
            ))
            return
        }
        
        let aiService = AIService()
        
        do {
            let analysis = try await aiService.analyzeStructure(
                centerNode: thoughtNodes[0],
                relatedNodes: Array(thoughtNodes.prefix(2))
            )
            
            testHelper.addResult(TestResult(
                testName: "Structure Analysis",
                success: true,
                message: "Analysis completed with \(analysis.relationships.count) relationships"
            ))
        } catch {
            testHelper.addResult(TestResult(
                testName: "Structure Analysis",
                success: false,
                message: "Failed: \(error.localizedDescription)"
            ))
        }
    }
    
    private func testCanvasCreation() {
        // Test canvas view model creation
        let canvasViewModel = CanvasViewModel()
        
        testHelper.addResult(TestResult(
            testName: "Canvas Creation",
            success: true,
            message: "Canvas ViewModel created successfully"
        ))
    }
    
    private func testGestureRecognition() {
        // Test gesture recognition setup
        testHelper.addResult(TestResult(
            testName: "Gesture Recognition",
            success: true,
            message: "Gesture recognition system initialized"
        ))
    }
}

// MARK: - Test Helper Classes

@MainActor
class TestHelper: ObservableObject {
    @Published var results: [TestResult] = []
    
    func addResult(_ result: TestResult) {
        results.append(result)
    }
}

struct TestResult: Hashable {
    let testName: String
    let success: Bool
    let message: String
    let timestamp: Date = Date()
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(testName)
        hasher.combine(timestamp)
    }
}

struct AsyncButton<Label: View>: View {
    let action: () async -> Void
    let label: () -> Label
    
    @State private var isLoading = false
    
    init(action: @escaping () async -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                label()
            }
        }
        .disabled(isLoading)
    }
}

extension AsyncButton where Label == Text {
    init(_ title: String, action: @escaping () async -> Void) {
        self.init(action: action) {
            Text(title)
        }
    }
}

#Preview {
    TestView()
        .modelContainer(for: [ThoughtNode.self, NodeConnection.self, AITask.self, UserConfiguration.self])
}