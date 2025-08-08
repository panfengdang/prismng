//
//  AILensService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import Combine

// MARK: - AI Analysis Type
enum AIAnalysisType {
    case logicalStructure       // 逻辑结构分析
    case contradictionDetection // 矛盾点检测
    case patternRecognition     // 模式识别
    case deepInsights          // 深度洞察
    case connectionSuggestions  // 连接建议
}

// MARK: - AI Analysis Result
struct AIAnalysisResult {
    let type: AIAnalysisType
    let insights: [Insight]
    let suggestedConnections: [ConnectionSuggestion]
    let newNodes: [GeneratedNode]
    let confidence: Double
    
    struct Insight {
        let title: String
        let description: String
        let relatedNodeIds: [UUID]
        let importance: Double
    }
    
    struct ConnectionSuggestion {
        let fromNodeId: UUID
        let toNodeId: UUID
        let connectionType: AssociationType
        let reason: String
        let confidence: Double
    }
    
    struct GeneratedNode {
        let content: String
        let nodeType: NodeType
        let sourceNodeIds: [UUID]
        let suggestedPosition: Position?
    }
}

// MARK: - AI Lens Service
@MainActor
class AILensService: ObservableObject {
    @Published var isAnalyzing = false
    @Published var currentAnalysis: AIAnalysisResult?
    @Published var analysisProgress: Double = 0.0
    @Published var error: Error?
    
    private let quotaService: QuotaManagementService
    private let vectorService: VectorDBService
    
    init(quotaService: QuotaManagementService, vectorService: VectorDBService) {
        self.quotaService = quotaService
        self.vectorService = vectorService
    }
    
    // MARK: - Public Methods
    
    func analyzeNode(_ node: ThoughtNode, relatedNodes: [ThoughtNode], analysisType: AIAnalysisType) async throws -> AIAnalysisResult {
        // Check quota
        guard quotaService.canUseAI() else {
            throw AILensError.quotaExceeded
        }
        
        // Check if Pro feature
        guard quotaService.subscriptionTier != .free else {
            throw AILensError.proFeatureRequired
        }
        
        isAnalyzing = true
        analysisProgress = 0.0
        error = nil
        
        do {
            // Consume quota
            _ = quotaService.incrementQuotaUsage()
            
            // Perform analysis based on type
            let result = try await performAnalysis(node, relatedNodes: relatedNodes, type: analysisType)
            
            currentAnalysis = result
            analysisProgress = 1.0
            isAnalyzing = false
            
            return result
        } catch {
            self.error = error
            isAnalyzing = false
            throw error
        }
    }
    
    func analyzeMulitpleNodes(_ nodes: [ThoughtNode], analysisType: AIAnalysisType) async throws -> AIAnalysisResult {
        // Check quota for bulk analysis
        guard quotaService.canUseAI() else {
            throw AILensError.quotaExceeded
        }
        
        guard quotaService.subscriptionTier == .advanced || quotaService.subscriptionTier == .professional else {
            throw AILensError.advancedProFeatureRequired
        }
        
        isAnalyzing = true
        analysisProgress = 0.0
        
        // For now, simulate the analysis
        // In real implementation, this would call the cloud AI service
        let result = try await performBulkAnalysis(nodes, type: analysisType)
        
        currentAnalysis = result
        analysisProgress = 1.0
        isAnalyzing = false
        
        return result
    }
    
    // MARK: - Private Methods
    
    private func performAnalysis(_ node: ThoughtNode, relatedNodes: [ThoughtNode], type: AIAnalysisType) async throws -> AIAnalysisResult {
        // Update progress
        analysisProgress = 0.2
        
        // Prepare context
        let context = prepareAnalysisContext(node, relatedNodes: relatedNodes)
        
        analysisProgress = 0.4
        
        // Call AI service (mocked for now)
        // In real implementation, this would call Firebase Functions or direct API
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        
        analysisProgress = 0.8
        
        // Generate mock result based on analysis type
        let result = generateMockResult(for: node, relatedNodes: relatedNodes, type: type)
        
        return result
    }
    
    private func performBulkAnalysis(_ nodes: [ThoughtNode], type: AIAnalysisType) async throws -> AIAnalysisResult {
        // Similar to single node analysis but for multiple nodes
        analysisProgress = 0.2
        
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 second delay
        
        analysisProgress = 0.8
        
        // Generate comprehensive analysis
        return generateMockBulkResult(for: nodes, type: type)
    }
    
    private func prepareAnalysisContext(_ node: ThoughtNode, relatedNodes: [ThoughtNode]) -> String {
        var context = "Central Node: \(node.content)\n\n"
        context += "Related Nodes:\n"
        for related in relatedNodes.prefix(5) {
            context += "- \(related.content)\n"
        }
        return context
    }
    
    // MARK: - Mock Data Generation
    
    private func generateMockResult(for node: ThoughtNode, relatedNodes: [ThoughtNode], type: AIAnalysisType) -> AIAnalysisResult {
        switch type {
        case .logicalStructure:
            return AIAnalysisResult(
                type: type,
                insights: [
                    .init(
                        title: "核心观点结构",
                        description: "这个想法包含了3个关键要素：目标、方法和结果。其中目标是最核心的驱动力。",
                        relatedNodeIds: relatedNodes.prefix(2).map { $0.id },
                        importance: 0.9
                    ),
                    .init(
                        title: "逻辑链缺失",
                        description: "从'问题'到'解决方案'之间缺少一个关键的中间步骤。",
                        relatedNodeIds: [node.id],
                        importance: 0.7
                    )
                ],
                suggestedConnections: relatedNodes.isEmpty ? [] : [
                    .init(
                        fromNodeId: node.id,
                        toNodeId: relatedNodes[0].id,
                        connectionType: .strongSupport,
                        reason: "这两个观点在逻辑上形成支撑关系",
                        confidence: 0.85
                    )
                ],
                newNodes: [
                    .init(
                        content: "关键问题：如何将这个想法转化为实际行动？",
                        nodeType: .question,
                        sourceNodeIds: [node.id],
                        suggestedPosition: Position(
                            x: node.position.x + 150,
                            y: node.position.y
                        )
                    )
                ],
                confidence: 0.82
            )
            
        case .contradictionDetection:
            return AIAnalysisResult(
                type: type,
                insights: [
                    .init(
                        title: "潜在矛盾",
                        description: "发现一个潜在的矛盾：你既希望'快速实现'，又强调'质量优先'。",
                        relatedNodeIds: relatedNodes.prefix(2).map { $0.id },
                        importance: 0.8
                    )
                ],
                suggestedConnections: [],
                newNodes: [
                    .init(
                        content: "矛盾点：速度 vs 质量 - 需要找到平衡点",
                        nodeType: .contradiction,
                        sourceNodeIds: [node.id],
                        suggestedPosition: nil
                    )
                ],
                confidence: 0.75
            )
            
        case .patternRecognition:
            return AIAnalysisResult(
                type: type,
                insights: [
                    .init(
                        title: "思考模式",
                        description: "你的思考倾向于'发散-收敛'模式：先探索多种可能性，然后逐步聚焦。",
                        relatedNodeIds: relatedNodes.map { $0.id },
                        importance: 0.85
                    )
                ],
                suggestedConnections: [],
                newNodes: [],
                confidence: 0.78
            )
            
        case .deepInsights:
            return AIAnalysisResult(
                type: type,
                insights: [
                    .init(
                        title: "深层洞察",
                        description: "这个想法的背后可能反映了你对'控制感'的追求。考虑探索为什么这对你很重要。",
                        relatedNodeIds: [node.id],
                        importance: 0.9
                    ),
                    .init(
                        title: "关联模式",
                        description: "这与你之前关于'自主性'的思考有很强的关联。",
                        relatedNodeIds: relatedNodes.prefix(1).map { $0.id },
                        importance: 0.75
                    )
                ],
                suggestedConnections: [],
                newNodes: [],
                confidence: 0.88
            )
            
        case .connectionSuggestions:
            let suggestions = relatedNodes.prefix(3).enumerated().map { index, relatedNode in
                AIAnalysisResult.ConnectionSuggestion(
                    fromNodeId: node.id,
                    toNodeId: relatedNode.id,
                    connectionType: index == 0 ? .strongSupport : .weakAssociation,
                    reason: index == 0 ? "这两个观点在本质上是相互支撑的" : "发现了微妙的关联",
                    confidence: Double(90 - index * 10) / 100.0
                )
            }
            
            return AIAnalysisResult(
                type: type,
                insights: [],
                suggestedConnections: suggestions,
                newNodes: [],
                confidence: 0.8
            )
        }
    }
    
    private func generateMockBulkResult(for nodes: [ThoughtNode], type: AIAnalysisType) -> AIAnalysisResult {
        // Generate a more comprehensive result for multiple nodes
        return AIAnalysisResult(
            type: type,
            insights: [
                .init(
                    title: "整体思维图景",
                    description: "这\(nodes.count)个节点形成了一个完整的思考体系，主要围绕'创新'和'效率'两个核心主题。",
                    relatedNodeIds: nodes.map { $0.id },
                    importance: 0.95
                )
            ],
            suggestedConnections: [],
            newNodes: [
                .init(
                    content: "核心主题：如何平衡创新与效率",
                    nodeType: .structure,
                    sourceNodeIds: nodes.prefix(3).map { $0.id },
                    suggestedPosition: nil
                )
            ],
            confidence: 0.85
        )
    }
}

// MARK: - AI Lens Error
enum AILensError: LocalizedError {
    case quotaExceeded
    case proFeatureRequired
    case advancedProFeatureRequired
    case analysisFailed
    case analysisInProgress
    
    var errorDescription: String? {
        switch self {
        case .quotaExceeded:
            return "AI 使用次数已用完"
        case .proFeatureRequired:
            return "AI 透镜是 Pro 功能，请升级订阅"
        case .advancedProFeatureRequired:
            return "批量分析是高级 Pro 功能"
        case .analysisFailed:
            return "AI 分析失败，请稍后重试"
        case .analysisInProgress:
            return "正在进行分析，请稍候"
        }
    }
}

// MARK: - AI Lens View
struct AILensView: View {
    @ObservedObject var aiLensService: AILensService
    let node: ThoughtNode
    let relatedNodes: [ThoughtNode]
    @State private var selectedAnalysisType: AIAnalysisType = .logicalStructure
    @State private var showingResult = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Node Preview
                VStack(alignment: .leading, spacing: 8) {
                    Label("分析节点", systemImage: "brain.head.profile")
                        .font(.headline)
                    
                    Text(node.content)
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                .padding(.horizontal)
                
                // Analysis Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("选择分析类型")
                        .font(.headline)
                    
                    ForEach(analysisTypes, id: \.self) { type in
                        AnalysisTypeRow(
                            type: type,
                            isSelected: selectedAnalysisType == type,
                            onSelect: {
                                selectedAnalysisType = type
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    if aiLensService.isAnalyzing {
                        ProgressView("正在分析...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                    } else {
                        Button {
                            Task {
                                await startAnalysis()
                            }
                        } label: {
                            Label("开始 AI 分析", systemImage: "wand.and.rays")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    
                    if let error = aiLensService.error {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
            }
            .navigationTitle("AI 透镜")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingResult) {
            if let result = aiLensService.currentAnalysis {
                AILensResultView(result: result, sourceNode: node)
            }
        }
    }
    
    private var analysisTypes: [AIAnalysisType] {
        [.logicalStructure, .contradictionDetection, .patternRecognition, .deepInsights, .connectionSuggestions]
    }
    
    private func startAnalysis() async {
        do {
            _ = try await aiLensService.analyzeNode(
                node,
                relatedNodes: relatedNodes,
                analysisType: selectedAnalysisType
            )
            showingResult = true
        } catch {
            // Error is handled by the service
        }
    }
}

// MARK: - Analysis Type Row
struct AnalysisTypeRow: View {
    let type: AIAnalysisType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: typeIcon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(typeTitle)
                        .font(.callout)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(typeDescription)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
    }
    
    private var typeIcon: String {
        switch type {
        case .logicalStructure: return "diagram.hierarchy"
        case .contradictionDetection: return "exclamationmark.triangle"
        case .patternRecognition: return "waveform.path.ecg"
        case .deepInsights: return "eye"
        case .connectionSuggestions: return "link"
        }
    }
    
    private var typeTitle: String {
        switch type {
        case .logicalStructure: return "逻辑结构分析"
        case .contradictionDetection: return "矛盾点检测"
        case .patternRecognition: return "模式识别"
        case .deepInsights: return "深度洞察"
        case .connectionSuggestions: return "连接建议"
        }
    }
    
    private var typeDescription: String {
        switch type {
        case .logicalStructure: return "分析想法的内在逻辑和结构"
        case .contradictionDetection: return "发现潜在的矛盾和冲突"
        case .patternRecognition: return "识别重复出现的思考模式"
        case .deepInsights: return "提供深层次的理解和洞察"
        case .connectionSuggestions: return "发现节点间的潜在关联"
        }
    }
}

// MARK: - AI Lens Result View
struct AILensResultView: View {
    let result: AIAnalysisResult
    let sourceNode: ThoughtNode
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Confidence Score
                    HStack {
                        Label("分析置信度", systemImage: "chart.bar.fill")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(result.confidence * 100))%")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(confidenceColor)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Insights
                    if !result.insights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("核心洞察", systemImage: "lightbulb.fill")
                                .font(.headline)
                            
                            ForEach(result.insights.indices, id: \.self) { index in
                                InsightCard(insight: result.insights[index])
                            }
                        }
                    }
                    
                    // Suggested Connections
                    if !result.suggestedConnections.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("建议连接", systemImage: "link")
                                .font(.headline)
                            
                            ForEach(result.suggestedConnections.indices, id: \.self) { index in
                                ConnectionSuggestionCard(suggestion: result.suggestedConnections[index])
                            }
                        }
                    }
                    
                    // Generated Nodes
                    if !result.newNodes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("生成的新节点", systemImage: "plus.circle")
                                .font(.headline)
                            
                            ForEach(result.newNodes.indices, id: \.self) { index in
                                GeneratedNodeCard(node: result.newNodes[index])
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("分析结果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var confidenceColor: Color {
        if result.confidence > 0.8 {
            return .green
        } else if result.confidence > 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Result Card Views
struct InsightCard: View {
    let insight: AIAnalysisResult.Insight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Importance indicator
                ForEach(0..<importanceStars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                }
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !insight.relatedNodeIds.isEmpty {
                HStack {
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("关联 \(insight.relatedNodeIds.count) 个节点")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
    
    private var importanceStars: Int {
        Int(insight.importance * 5)
    }
}

struct ConnectionSuggestionCard: View {
    let suggestion: AIAnalysisResult.ConnectionSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(connectionColor)
                Text(connectionTypeText)
                    .font(.callout)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(suggestion.reason)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(connectionColor, lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(connectionColor.opacity(0.1))
                )
        )
    }
    
    private var connectionColor: Color {
        switch suggestion.connectionType {
        case .strongSupport: return .green
        case .weakAssociation: return .blue
        case .similarity: return .purple
        case .contextual: return .orange
        case .temporal: return .indigo
        case .emotional: return .pink
        }
    }
    
    private var connectionTypeText: String {
        switch suggestion.connectionType {
        case .strongSupport: return "强支撑"
        case .weakAssociation: return "弱关联"
        case .similarity: return "相似性"
        case .contextual: return "上下文"
        case .temporal: return "时间关联"
        case .emotional: return "情感关联"
        }
    }
}

struct GeneratedNodeCard: View {
    let node: AIAnalysisResult.GeneratedNode
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: nodeTypeIcon)
                    .foregroundColor(nodeTypeColor)
                Text(nodeTypeText)
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
            }
            
            if isExpanded {
                Text(node.content)
                    .font(.callout)
                    .padding(.top, 4)
            } else {
                Text(node.content)
                    .font(.callout)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            
            if !node.sourceNodeIds.isEmpty {
                HStack {
                    Image(systemName: "arrow.triangle.branch")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("基于 \(node.sourceNodeIds.count) 个源节点")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(nodeTypeColor.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(nodeTypeColor, lineWidth: 1)
                )
        )
    }
    
    private var nodeTypeIcon: String {
        switch node.nodeType {
        case .thought: return "lightbulb"
        case .insight: return "star"
        case .question: return "questionmark.circle"
        case .conclusion: return "checkmark.seal"
        case .contradiction: return "exclamationmark.triangle"
        case .structure: return "grid"
        }
    }
    
    private var nodeTypeColor: Color {
        switch node.nodeType {
        case .thought: return .blue
        case .insight: return .purple
        case .question: return .orange
        case .conclusion: return .green
        case .contradiction: return .red
        case .structure: return .gray
        }
    }
    
    private var nodeTypeText: String {
        switch node.nodeType {
        case .thought: return "想法"
        case .insight: return "洞察"
        case .question: return "问题"
        case .conclusion: return "结论"
        case .contradiction: return "矛盾"
        case .structure: return "结构"
        }
    }
}
