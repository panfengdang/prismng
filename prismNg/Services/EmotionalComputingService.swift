//
//  EmotionalComputingService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Emotion Type Extensions
extension EmotionalTag {
    
    var color: Color {
        switch self {
        case .excited: return .yellow
        case .inspired: return .purple
        case .calm: return .blue
        case .curious: return .green
        case .frustrated: return .red
        case .confused: return .orange
        case .confident: return .indigo
        case .uncertain: return .gray
        }
    }
    
    var icon: String {
        switch self {
        case .excited: return "sun.max.fill"
        case .inspired: return "sparkles"
        case .calm: return "leaf.fill"
        case .curious: return "magnifyingglass.circle.fill"
        case .frustrated: return "flame.fill"
        case .confused: return "questionmark.circle.fill"
        case .confident: return "checkmark.shield.fill"
        case .uncertain: return "cloud.fog.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .excited: return "激动"
        case .inspired: return "受启发"
        case .calm: return "平静"
        case .curious: return "好奇"
        case .frustrated: return "沮丧"
        case .confused: return "困惑"
        case .confident: return "自信"
        case .uncertain: return "不确定"
        }
    }
}

// MARK: - Emotional Marker
// EmotionalMarker is defined in Item.swift as a SwiftData model

// MARK: - Emotional Pattern
struct EmotionalPattern: Identifiable {
    let id = UUID()
    let pattern: String
    let emotions: [EmotionalTag]
    let frequency: Int
    let timeRange: DateInterval
    let relatedNodeIds: [UUID]
    let insight: String
}

// MARK: - Emotional Data Point
struct EmotionalDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let emotion: EmotionalTag
    let intensity: Double
}

// MARK: - Emotional Computing Service
@MainActor
class EmotionalComputingService: ObservableObject {
    @Published var emotionalPatterns: [EmotionalPattern] = []
    @Published var currentMood: EmotionalTag?
    @Published var moodTransitionHistory: [(from: EmotionalTag?, to: EmotionalTag, timestamp: Date)] = []
    @Published var isAnalyzing = false
    @Published var emotionalInsights: [String] = []
    @Published var dominantEmotions: [(emotion: EmotionalTag, percentage: Double)] = []
    @Published var emotionalTimeline: [EmotionalDataPoint] = []
    @Published var insights: [String] = []
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setup
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadEmotionalHistory()
    }
    
    // MARK: - Emotion Marking
    func markEmotion(for node: ThoughtNode, emotion: EmotionalTag, intensity: Double = 0.5, note: String? = nil) {
        guard let modelContext = modelContext else { return }
        
        // Create emotional marker
        let marker = EmotionalMarker(nodeId: node.id, emotionalTag: emotion, intensity: intensity, userNote: note)
        modelContext.insert(marker)
        
        // Add to node's emotional tags
        if !node.emotionalTags.contains(emotion) {
            node.emotionalTags.append(emotion)
        }
        
        // Update emotional intensity
        node.emotionalIntensity = intensity
        
        // Update current mood
        updateCurrentMood(to: emotion)
        
        // Track pattern
        Task {
            await analyzeEmotionalPatterns()
        }
        
        // Save changes
        try? modelContext.save()
    }
    
    func removeEmotion(from node: ThoughtNode, emotion: EmotionalTag) {
        guard let modelContext = modelContext else { return }
        
        // Remove from emotional tags
        node.emotionalTags.removeAll { $0 == emotion }
        
        // First fetch all markers for this node
        let nodeId = node.id
        let allMarkersRequest = FetchDescriptor<EmotionalMarker>(
            predicate: #Predicate { marker in
                marker.nodeId == nodeId
            }
        )
        
        // Then filter by emotion
        if let allMarkers = try? modelContext.fetch(allMarkersRequest) {
            let markersToDelete = allMarkers.filter { $0.emotionalTag == emotion }
            for marker in markersToDelete {
                modelContext.delete(marker)
            }
        }
        
        // Update emotional intensity
        if node.emotionalTags.isEmpty {
            node.emotionalIntensity = 0.0
        }
        
        try? modelContext.save()
    }
    
    func getEmotions(for node: ThoughtNode) -> [EmotionalTag] {
        return node.emotionalTags
    }
    
    func getEmotionalIntensity(for node: ThoughtNode, emotion: EmotionalTag) -> Double {
        guard let modelContext = modelContext else { return 0.0 }
        
        // First fetch all markers for this node
        let nodeId = node.id
        let request = FetchDescriptor<EmotionalMarker>(
            predicate: #Predicate { marker in
                marker.nodeId == nodeId
            }
        )
        
        guard let allMarkers = try? modelContext.fetch(request) else { return 0.0 }
        
        // Filter by emotion
        let emotionMarkers = allMarkers.filter { $0.emotionalTag == emotion }
        guard !emotionMarkers.isEmpty else { return 0.0 }
        
        // Return average intensity
        let totalIntensity = emotionMarkers.reduce(0.0) { $0 + $1.intensity }
        return totalIntensity / Double(emotionMarkers.count)
    }
    
    // MARK: - Pattern Analysis
    func analyzeEmotionalPatterns() async {
        isAnalyzing = true
        
        // Simulate analysis delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Analyze patterns (simplified for now)
        let patterns = detectEmotionalPatterns()
        await MainActor.run {
            self.emotionalPatterns = patterns
            self.isAnalyzing = false
            self.generateEmotionalInsights()
        }
    }
    
    private func detectEmotionalPatterns() -> [EmotionalPattern] {
        guard let modelContext = modelContext else { return [] }
        
        // Fetch all nodes with emotions
        let request = FetchDescriptor<ThoughtNode>(
            predicate: #Predicate { !$0.emotionalTags.isEmpty }
        )
        
        guard let emotionalNodes = try? modelContext.fetch(request) else { return [] }
        
        var patterns: [EmotionalPattern] = []
        
        // Pattern 1: Emotion sequences
        let emotionSequences = analyzeEmotionSequences(in: emotionalNodes)
        patterns.append(contentsOf: emotionSequences)
        
        // Pattern 2: Emotion clusters
        let emotionClusters = analyzeEmotionClusters(in: emotionalNodes)
        patterns.append(contentsOf: emotionClusters)
        
        // Pattern 3: Temporal patterns
        let temporalPatterns = analyzeTemporalPatterns(in: emotionalNodes)
        patterns.append(contentsOf: temporalPatterns)
        
        return patterns
    }
    
    private func analyzeEmotionSequences(in nodes: [ThoughtNode]) -> [EmotionalPattern] {
        // Analyze sequences of emotions over time
        var patterns: [EmotionalPattern] = []
        
        // Sort nodes by creation date
        let sortedNodes = nodes.sorted { $0.createdAt < $1.createdAt }
        
        // Look for common sequences
        if sortedNodes.count >= 3 {
            for i in 0..<(sortedNodes.count - 2) {
                let emotions1 = getEmotions(for: sortedNodes[i])
                let emotions2 = getEmotions(for: sortedNodes[i + 1])
                let emotions3 = getEmotions(for: sortedNodes[i + 2])
                
                if !emotions1.isEmpty && !emotions2.isEmpty && !emotions3.isEmpty {
                    // Check for transition patterns
                        if emotions1.contains(.frustrated) && emotions2.contains(.curious) && emotions3.contains(.inspired) {
                        patterns.append(EmotionalPattern(
                            pattern: "突破模式",
                            emotions: [.frustrated, .curious, .inspired],
                            frequency: 1,
                            timeRange: DateInterval(start: sortedNodes[i].createdAt, end: sortedNodes[i + 2].createdAt),
                            relatedNodeIds: [sortedNodes[i].id, sortedNodes[i + 1].id, sortedNodes[i + 2].id],
                            insight: "你经常通过好奇心将挫折转化为灵感"
                        ))
                    }
                }
            }
        }
        
        return patterns
    }
    
    private func analyzeEmotionClusters(in nodes: [ThoughtNode]) -> [EmotionalPattern] {
        // Find clusters of similar emotions
        var emotionGroups: [EmotionalTag: [ThoughtNode]] = [:]
        
        for node in nodes {
            for emotion in getEmotions(for: node) {
                emotionGroups[emotion, default: []].append(node)
            }
        }
        
        var patterns: [EmotionalPattern] = []
        
        for (emotion, groupNodes) in emotionGroups where groupNodes.count >= 3 {
            let earliestDate = groupNodes.map { $0.createdAt }.min() ?? Date()
            let latestDate = groupNodes.map { $0.createdAt }.max() ?? Date()
            
            patterns.append(EmotionalPattern(
                pattern: "\(emotion.displayName)聚集",
                emotions: [emotion],
                frequency: groupNodes.count,
                timeRange: DateInterval(start: earliestDate, end: latestDate),
                relatedNodeIds: groupNodes.map { $0.id },
                insight: "你在这个时期经常感受到\(emotion.displayName)"
            ))
        }
        
        return patterns
    }
    
    private func analyzeTemporalPatterns(in nodes: [ThoughtNode]) -> [EmotionalPattern] {
        // Analyze time-based patterns (e.g., morning vs evening emotions)
        var patterns: [EmotionalPattern] = []
        
        let calendar = Calendar.current
        var morningEmotions: [EmotionalTag] = []
        var eveningEmotions: [EmotionalTag] = []
        
        for node in nodes {
            let hour = calendar.component(.hour, from: node.createdAt)
            let emotions = getEmotions(for: node)
            
            if hour >= 6 && hour < 12 {
                morningEmotions.append(contentsOf: emotions)
            } else if hour >= 18 && hour < 24 {
                eveningEmotions.append(contentsOf: emotions)
            }
        }
        
        // Find dominant morning emotion
        if let dominantMorning = findDominantEmotion(in: morningEmotions) {
            patterns.append(EmotionalPattern(
                pattern: "晨间情绪",
                emotions: [dominantMorning],
                frequency: morningEmotions.filter { $0 == dominantMorning }.count,
                timeRange: DateInterval(start: Date().addingTimeInterval(-7 * 24 * 3600), end: Date()),
                relatedNodeIds: [],
                insight: "你的早晨通常充满\(dominantMorning.displayName)"
            ))
        }
        
        // Find dominant evening emotion
        if let dominantEvening = findDominantEmotion(in: eveningEmotions) {
            patterns.append(EmotionalPattern(
                pattern: "夜间情绪",
                emotions: [dominantEvening],
                frequency: eveningEmotions.filter { $0 == dominantEvening }.count,
                timeRange: DateInterval(start: Date().addingTimeInterval(-7 * 24 * 3600), end: Date()),
                relatedNodeIds: [],
                insight: "你的夜晚常常感到\(dominantEvening.displayName)"
            ))
        }
        
        return patterns
    }
    
    private func findDominantEmotion(in emotions: [EmotionalTag]) -> EmotionalTag? {
        let counts = Dictionary(grouping: emotions) { $0 }.mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Emotional Insights
    private func generateEmotionalInsights() {
        var insights: [String] = []
        
        // Insight 1: Emotional diversity
        let uniqueEmotions = Set(moodTransitionHistory.compactMap { $0.to })
        if uniqueEmotions.count >= 5 {
            insights.append("你的情感体验很丰富，这有助于全面的思考")
        }
        
        // Insight 2: Emotional balance
        let positiveEmotions: Set<EmotionalTag> = [.excited, .inspired, .calm, .curious, .confident]
        let negativeEmotions: Set<EmotionalTag> = [.frustrated, .confused, .uncertain]
        
        let positiveCount = moodTransitionHistory.filter { positiveEmotions.contains($0.to) }.count
        let negativeCount = moodTransitionHistory.filter { negativeEmotions.contains($0.to) }.count
        
        if positiveCount > 0 && negativeCount > 0 {
            let ratio = Double(positiveCount) / Double(positiveCount + negativeCount)
            if ratio > 0.6 && ratio < 0.8 {
                insights.append("你保持着健康的情感平衡")
            }
        }
        
        // Insight 3: Emotional patterns
        if emotionalPatterns.contains(where: { $0.pattern.contains("突破") }) {
            insights.append("你善于将负面情绪转化为成长机会")
        }
        
        emotionalInsights = insights
    }
    
    // MARK: - Mood Management
    private func updateCurrentMood(to emotion: EmotionalTag) {
        let previousMood = currentMood
        currentMood = emotion
        
        // Record transition
        moodTransitionHistory.append((from: previousMood, to: emotion, timestamp: Date()))
        
        // Keep only recent history (last 100 transitions)
        if moodTransitionHistory.count > 100 {
            moodTransitionHistory.removeFirst()
        }
    }
    
    // MARK: - Persistence Helpers
    private func getEmotionalMarkers(for node: ThoughtNode) -> [EmotionalMarker] {
        guard let modelContext = modelContext else { return [] }
        let nodeId = node.id
        let request = FetchDescriptor<EmotionalMarker>(
            predicate: #Predicate { marker in
                marker.nodeId == nodeId
            }
        )
        return (try? modelContext.fetch(request)) ?? []
    }
    
    func getPatterns(for emotion: EmotionalTag) -> [String] {
        // Return patterns associated with specific emotions
        switch emotion {
        case .excited:
            return [
                "Working on new features or breakthroughs",
                "Discovering unexpected connections",
                "Starting fresh projects"
            ]
        case .calm:
            return [
                "During reflection and review sessions",
                "When organizing existing thoughts",
                "In early morning or late evening sessions"
            ]
        case .confused:
            return [
                "Encountering complex problems",
                "Information overload situations",
                "When multiple perspectives conflict"
            ]
        case .inspired:
            return [
                "After making key connections",
                "Reading insightful content",
                "During creative exploration"
            ]
        case .frustrated:
            return [
                "Facing technical difficulties",
                "When progress feels blocked",
                "Dealing with contradictions"
            ]
        case .curious:
            return [
                "Exploring new topics",
                "Asking fundamental questions",
                "During research phases"
            ]
        case .confident:
            return [
                "After solving difficult problems",
                "When ideas crystallize clearly",
                "During productive work sessions"
            ]
        case .uncertain:
            return [
                "Facing important decisions",
                "Exploring unfamiliar territory",
                "When multiple paths seem viable"
            ]
        }
    }
    
    private func loadEmotionalHistory() {
        // Load mood transition history from UserDefaults or persistent storage
        // For now, we'll start fresh each session
    }
    
    // MARK: - Emotional Connections
    func findEmotionallyRelatedNodes(to node: ThoughtNode, in allNodes: [ThoughtNode]) -> [ThoughtNode] {
        let nodeEmotions = Set(getEmotions(for: node))
        guard !nodeEmotions.isEmpty else { return [] }
        
        return allNodes.filter { otherNode in
            guard otherNode.id != node.id else { return false }
            let otherEmotions = Set(getEmotions(for: otherNode))
            return !nodeEmotions.isDisjoint(with: otherEmotions)
        }
    }
    
    func calculateEmotionalSimilarity(between node1: ThoughtNode, and node2: ThoughtNode) -> Double {
        let emotions1 = Set(getEmotions(for: node1))
        let emotions2 = Set(getEmotions(for: node2))
        
        guard !emotions1.isEmpty && !emotions2.isEmpty else { return 0.0 }
        
        let intersection = emotions1.intersection(emotions2)
        let union = emotions1.union(emotions2)
        
        return Double(intersection.count) / Double(union.count)
    }
}

// MARK: - Emotional Marker View
struct EmotionalMarkerView: View {
    @ObservedObject var emotionalService: EmotionalComputingService
    let node: ThoughtNode
    @State private var selectedEmotion: EmotionalTag?
    @State private var emotionIntensity: Double = 0.5
    @State private var emotionNote: String = ""
    @State private var showEmotionPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Current emotions
            if !emotionalService.getEmotions(for: node).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("当前情感标记")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    FlowLayout(spacing: 8) {
                        ForEach(emotionalService.getEmotions(for: node), id: \.self) { emotion in
                            EmotionChip(
                                emotion: emotion,
                                intensity: emotionalService.getEmotionalIntensity(for: node, emotion: emotion),
                                onRemove: {
                                    emotionalService.removeEmotion(from: node, emotion: emotion)
                                }
                            )
                        }
                    }
                }
            }
            
            // Add emotion button
            Button {
                showEmotionPicker = true
            } label: {
                Label("添加情感标记", systemImage: "heart.circle.fill")
                    .font(.callout)
            }
            .sheet(isPresented: $showEmotionPicker) {
                EmotionPickerView(
                    selectedEmotion: $selectedEmotion,
                    intensity: $emotionIntensity,
                    note: $emotionNote,
                    onConfirm: {
                        if let emotion = selectedEmotion {
                            emotionalService.markEmotion(
                                for: node,
                                emotion: emotion,
                                intensity: emotionIntensity,
                                note: emotionNote.isEmpty ? nil : emotionNote
                            )
                        }
                        showEmotionPicker = false
                        selectedEmotion = nil
                        emotionIntensity = 0.5
                        emotionNote = ""
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Emotion Chip View
struct EmotionChip: View {
    let emotion: EmotionalTag
    let intensity: Double
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: emotion.icon)
                .font(.caption)
            
            Text(emotion.displayName)
                .font(.caption)
            
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(emotion.color.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(emotion.color, lineWidth: 1)
                )
        )
        .foregroundColor(emotion.color)
    }
}

// MARK: - Emotion Picker View
struct EmotionPickerView: View {
    @Binding var selectedEmotion: EmotionalTag?
    @Binding var intensity: Double
    @Binding var note: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Emotion grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                    ForEach(EmotionalTag.allCases, id: \.self) { emotion in
                        EmotionButton(
                            emotion: emotion,
                            isSelected: selectedEmotion == emotion,
                            onTap: {
                                selectedEmotion = emotion
                            }
                        )
                    }
                }
                .padding()
                
                if selectedEmotion != nil {
                    // Intensity slider
                    VStack(alignment: .leading, spacing: 8) {
                        Text("强度")
                            .font(.headline)
                        
                        HStack {
                            Text("轻微")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $intensity, in: 0...1)
                                .tint(selectedEmotion?.color)
                            
                            Text("强烈")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Note field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("备注（可选）")
                            .font(.headline)
                        
                        TextField("记录一些想法...", text: $note)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("选择情感")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("确认") {
                        onConfirm()
                    }
                    .disabled(selectedEmotion == nil)
                }
            }
        }
    }
}

// MARK: - Emotion Button
struct EmotionButton: View {
    let emotion: EmotionalTag
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: emotion.icon)
                    .font(.title2)
                
                Text(emotion.displayName)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? emotion.color.opacity(0.2) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? emotion.color : Color.clear, lineWidth: 2)
                    )
            )
            .foregroundColor(isSelected ? emotion.color : .primary)
        }
    }
}

// MARK: - Emotional Insights View
// EmotionalInsightsView is now defined in Views/EmotionalInsightsView.swift
struct LegacyEmotionalInsightsView: View {
    @ObservedObject var emotionalService: EmotionalComputingService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Current mood
                    if let currentMood = emotionalService.currentMood {
                        CurrentMoodCard(mood: currentMood)
                    }
                    
                    // Emotional patterns
                    if !emotionalService.emotionalPatterns.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("情感模式")
                                .font(.headline)
                            
                            ForEach(emotionalService.emotionalPatterns) { pattern in
                                EmotionalPatternCard(pattern: pattern)
                            }
                        }
                    }
                    
                    // Insights
                    if !emotionalService.emotionalInsights.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("情感洞察")
                                .font(.headline)
                            
                            ForEach(emotionalService.emotionalInsights, id: \.self) { insight in
                                EmotionalInsightCard(text: insight)
                            }
                        }
                    }
                    
                    // Mood history chart
                    if !emotionalService.moodTransitionHistory.isEmpty {
                        MoodHistoryChart(history: emotionalService.moodTransitionHistory)
                    }
                }
                .padding()
            }
            .navigationTitle("情感分析")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Supporting Views
struct CurrentMoodCard: View {
    let mood: EmotionalTag
    
    var body: some View {
        HStack {
            Image(systemName: mood.icon)
                .font(.largeTitle)
                .foregroundColor(mood.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("当前情感状态")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(mood.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(mood.color.opacity(0.1))
        )
    }
}

struct EmotionalPatternCard: View {
    let pattern: EmotionalPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.pattern)
                    .font(.callout)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("出现 \(pattern.frequency) 次")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 8) {
                ForEach(pattern.emotions, id: \.self) { emotion in
                    Image(systemName: emotion.icon)
                        .foregroundColor(emotion.color)
                        .font(.caption)
                }
            }
            
            Text(pattern.insight)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

struct EmotionalInsightCard: View {
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            
            Text(text)
                .font(.callout)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

struct MoodHistoryChart: View {
    let history: [(from: EmotionalTag?, to: EmotionalTag, timestamp: Date)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("情感变化历程")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(Array(history.suffix(10).enumerated()), id: \.offset) { index, transition in
                        VStack(spacing: 4) {
                            Image(systemName: transition.to.icon)
                                .font(.title2)
                                .foregroundColor(transition.to.color)
                            
                            Text(transition.timestamp, style: .time)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if index < history.suffix(10).count - 1 {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
    }
}