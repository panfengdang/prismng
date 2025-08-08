//
//  EmotionalComputingEngine.swift
//  prismNg
//
//  Emotional computing and analysis engine
//

import Foundation
import SwiftUI
import NaturalLanguage
import Combine

// MARK: - Emotional Analysis Types

struct EmotionalAnalysisResult {
    let node: ThoughtNode
    let primaryEmotion: EmotionalTag
    let emotionScores: [EmotionalTag: Double]
    let valence: Double // -1 (negative) to 1 (positive)
    let arousal: Double // 0 (calm) to 1 (excited)
    let confidence: Double
    let keywords: [String]
    let suggestion: String?
}

struct EmotionPattern {
    let id = UUID()
    let name: String
    let timeRange: DateInterval
    let dominantEmotions: [EmotionalTag]
    let emotionalJourney: [EmotionalSnapshot]
    let insights: [String]
}

struct EmotionalSnapshot {
    let timestamp: Date
    let emotion: EmotionalTag
    let intensity: Double
    let context: String?
}

struct EmotionalClimate {
    let overallValence: Double
    let overallArousal: Double
    let emotionalDiversity: Double
    let volatility: Double // How much emotions change
    let trends: [EmotionalTrend]
}

struct EmotionalTrend {
    let emotion: EmotionalTag
    let direction: TrendDirection
    let strength: Double
    let timespan: TimeInterval
    
    enum TrendDirection {
        case rising, falling, stable
    }
}

// MARK: - Emotional Computing Engine

@MainActor
class EmotionalComputingEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAnalyzing = false
    @Published var emotionalResults: [UUID: EmotionalAnalysisResult] = [:]
    @Published var emotionalPatterns: [EmotionPattern] = []
    @Published var currentClimate: EmotionalClimate?
    @Published var emotionalHeatmap: [[Double]] = []
    
    // MARK: - Private Properties
    
    private let tagger = NLTagger(tagSchemes: [.sentimentScore, .tokenType])
    private var cancellables = Set<AnyCancellable>()
    
    // Emotion keywords mapping
    private let emotionKeywords: [EmotionalTag: Set<String>] = [
        .excited: ["兴奋", "激动", "amazing", "wonderful", "fantastic", "太棒了", "excellent"],
        .calm: ["平静", "calm", "peaceful", "serene", "relaxed", "安静", "放松"],
        .confused: ["困惑", "confused", "puzzled", "unclear", "不明白", "疑惑", "why"],
        .inspired: ["灵感", "inspired", "idea", "创意", "brilliant", "enlightened", "顿悟"],
        .frustrated: ["沮丧", "frustrated", "annoying", "difficult", "stuck", "困难", "卡住"],
        .curious: ["好奇", "curious", "wonder", "interesting", "想知道", "interesting", "探索"],
        .confident: ["自信", "confident", "sure", "certain", "确定", "肯定", "相信"],
        .uncertain: ["不确定", "uncertain", "maybe", "perhaps", "可能", "也许", "不确定"]
    ]
    
    // Emotion color mapping for visualization
    private let emotionColors: [EmotionalTag: Color] = [
        .excited: .red,
        .calm: .blue,
        .confused: .purple,
        .inspired: .yellow,
        .frustrated: .orange,
        .curious: .green,
        .confident: .indigo,
        .uncertain: .gray
    ]
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
    }
    
    // MARK: - Main Analysis Functions
    
    func analyzeEmotion(for node: ThoughtNode) async -> EmotionalAnalysisResult {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Step 1: Basic sentiment analysis
        let sentiment = analyzeSentiment(text: node.content)
        
        // Step 2: Keyword-based emotion detection
        let keywordEmotions = detectEmotionsFromKeywords(text: node.content)
        
        // Step 3: Context-based emotion inference
        let contextEmotions = inferEmotionsFromContext(node: node)
        
        // Step 4: Combine all signals
        let emotionScores = combineEmotionSignals(
            sentiment: sentiment,
            keywords: keywordEmotions,
            context: contextEmotions
        )
        
        // Step 5: Determine primary emotion
        let primaryEmotion = emotionScores.max(by: { $0.value < $1.value })?.key ?? .calm
        
        // Step 6: Calculate valence and arousal
        let (valence, arousal) = calculateValenceArousal(emotionScores: emotionScores)
        
        // Step 7: Extract keywords
        let keywords = extractEmotionalKeywords(from: node.content)
        
        // Step 8: Generate suggestion
        let suggestion = generateEmotionalSuggestion(
            emotion: primaryEmotion,
            valence: valence,
            arousal: arousal
        )
        
        // Step 9: Calculate confidence
        let confidence = calculateConfidence(emotionScores: emotionScores)
        
        let result = EmotionalAnalysisResult(
            node: node,
            primaryEmotion: primaryEmotion,
            emotionScores: emotionScores,
            valence: valence,
            arousal: arousal,
            confidence: confidence,
            keywords: keywords,
            suggestion: suggestion
        )
        
        // Store result
        emotionalResults[node.id] = result
        
        // Update node's emotional tags
        if !node.emotionalTags.contains(primaryEmotion) {
            node.emotionalTags.append(primaryEmotion)
        }
        
        return result
    }
    
    func analyzeEmotionalPatterns(for nodes: [ThoughtNode]) async -> [EmotionPattern] {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Group nodes by time periods
        let groupedNodes = groupNodesByTimePeriod(nodes)
        var patterns: [EmotionPattern] = []
        
        for (name, interval, periodNodes) in groupedNodes {
            // Analyze emotions for each node in the period
            var snapshots: [EmotionalSnapshot] = []
            var emotionCounts: [EmotionalTag: Int] = [:]
            
            for node in periodNodes {
                let result = await analyzeEmotion(for: node)
                
                snapshots.append(EmotionalSnapshot(
                    timestamp: node.createdAt,
                    emotion: result.primaryEmotion,
                    intensity: result.emotionScores[result.primaryEmotion] ?? 0.5,
                    context: String(node.content.prefix(50))
                ))
                
                emotionCounts[result.primaryEmotion, default: 0] += 1
            }
            
            // Identify dominant emotions
            let dominantEmotions = emotionCounts
                .sorted { $0.value > $1.value }
                .prefix(3)
                .map { $0.key }
            
            // Generate insights
            let insights = generatePatternInsights(
                snapshots: snapshots,
                dominantEmotions: dominantEmotions
            )
            
            patterns.append(EmotionPattern(
                name: name,
                timeRange: interval,
                dominantEmotions: Array(dominantEmotions),
                emotionalJourney: snapshots.sorted { $0.timestamp < $1.timestamp },
                insights: insights
            ))
        }
        
        emotionalPatterns = patterns
        return patterns
    }
    
    func analyzeEmotionalClimate(for nodes: [ThoughtNode]) async -> EmotionalClimate {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        var totalValence: Double = 0
        var totalArousal: Double = 0
        var emotionVariety = Set<EmotionalTag>()
        var previousEmotions: [EmotionalTag] = []
        
        // Analyze each node
        for node in nodes.sorted(by: { $0.createdAt < $1.createdAt }) {
            let result = await analyzeEmotion(for: node)
            
            totalValence += result.valence
            totalArousal += result.arousal
            emotionVariety.insert(result.primaryEmotion)
            previousEmotions.append(result.primaryEmotion)
        }
        
        // Calculate averages
        let count = Double(nodes.count)
        let overallValence = count > 0 ? totalValence / count : 0
        let overallArousal = count > 0 ? totalArousal / count : 0
        
        // Calculate diversity
        let emotionalDiversity = Double(emotionVariety.count) / Double(EmotionalTag.allCases.count)
        
        // Calculate volatility
        let volatility = calculateEmotionalVolatility(emotions: previousEmotions)
        
        // Identify trends
        let trends = identifyEmotionalTrends(nodes: nodes)
        
        let climate = EmotionalClimate(
            overallValence: overallValence,
            overallArousal: overallArousal,
            emotionalDiversity: emotionalDiversity,
            volatility: volatility,
            trends: trends
        )
        
        currentClimate = climate
        return climate
    }
    
    // MARK: - Sentiment Analysis
    
    private func analyzeSentiment(text: String) -> Double {
        tagger.string = text
        
        var sentimentSum: Double = 0
        var wordCount = 0
        
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .sentimentScore) { tag, range in
            if let tag = tag {
                sentimentSum += Double(tag.rawValue) ?? 0
                wordCount += 1
            }
            return true
        }
        
        return wordCount > 0 ? sentimentSum / Double(wordCount) : 0
    }
    
    // MARK: - Keyword Detection
    
    private func detectEmotionsFromKeywords(text: String) -> [EmotionalTag: Double] {
        let lowercasedText = text.lowercased()
        var emotionScores: [EmotionalTag: Double] = [:]
        
        for (emotion, keywords) in emotionKeywords {
            var score: Double = 0
            for keyword in keywords {
                if lowercasedText.contains(keyword) {
                    score += 1.0
                }
            }
            
            if score > 0 {
                // Normalize by text length
                let normalizedScore = min(1.0, score / max(1.0, Double(text.count) / 100.0))
                emotionScores[emotion] = normalizedScore
            }
        }
        
        return emotionScores
    }
    
    // MARK: - Context Inference
    
    private func inferEmotionsFromContext(node: ThoughtNode) -> [EmotionalTag: Double] {
        var contextScores: [EmotionalTag: Double] = [:]
        
        // Question marks suggest curiosity or confusion
        if node.content.contains("?") || node.content.contains("？") {
            contextScores[.curious] = 0.6
            if node.content.contains("why") || node.content.contains("为什么") {
                contextScores[.confused] = 0.4
            }
        }
        
        // Exclamation marks suggest excitement
        if node.content.contains("!") || node.content.contains("！") {
            contextScores[.excited] = 0.5
        }
        
        // Question nodes suggest uncertainty or curiosity
        if node.nodeType == .question {
            contextScores[.curious] = 0.5
            contextScores[.uncertain] = 0.3
        }
        
        // Insight nodes are often inspiring
        if node.nodeType == .insight {
            contextScores[.inspired] = 0.6
        }
        
        return contextScores
    }
    
    // MARK: - Signal Combination
    
    private func combineEmotionSignals(
        sentiment: Double,
        keywords: [EmotionalTag: Double],
        context: [EmotionalTag: Double]
    ) -> [EmotionalTag: Double] {
        
        var combined: [EmotionalTag: Double] = [:]
        
        // Initialize all emotions with base scores
        for emotion in EmotionalTag.allCases {
            combined[emotion] = 0.1 // Base score
        }
        
        // Apply sentiment bias
        if sentiment > 0.3 {
            combined[.excited] = (combined[.excited] ?? 0) + sentiment * 0.3
            combined[.inspired] = (combined[.inspired] ?? 0) + sentiment * 0.2
            combined[.confident] = (combined[.confident] ?? 0) + sentiment * 0.2
        } else if sentiment < -0.3 {
            combined[.frustrated] = (combined[.frustrated] ?? 0) + abs(sentiment) * 0.3
            combined[.confused] = (combined[.confused] ?? 0) + abs(sentiment) * 0.2
            combined[.uncertain] = (combined[.uncertain] ?? 0) + abs(sentiment) * 0.2
        } else {
            combined[.calm] = (combined[.calm] ?? 0) + 0.3
        }
        
        // Add keyword scores with weight
        for (emotion, score) in keywords {
            combined[emotion] = (combined[emotion] ?? 0) + score * 0.5
        }
        
        // Add context scores with weight
        for (emotion, score) in context {
            combined[emotion] = (combined[emotion] ?? 0) + score * 0.3
        }
        
        // Normalize scores
        let total = combined.values.reduce(0, +)
        if total > 0 {
            for emotion in combined.keys {
                combined[emotion] = (combined[emotion] ?? 0) / total
            }
        }
        
        return combined
    }
    
    // MARK: - Valence and Arousal Calculation
    
    private func calculateValenceArousal(emotionScores: [EmotionalTag: Double]) -> (Double, Double) {
        var valence: Double = 0
        var arousal: Double = 0
        var totalWeight: Double = 0
        
        let emotionValenceArousal: [EmotionalTag: (valence: Double, arousal: Double)] = [
            .excited: (0.8, 0.9),
            .calm: (0.3, 0.1),
            .confused: (-0.3, 0.6),
            .inspired: (0.7, 0.7),
            .frustrated: (-0.6, 0.8),
            .curious: (0.4, 0.6),
            .confident: (0.6, 0.5),
            .uncertain: (-0.2, 0.4)
        ]
        
        for (emotion, score) in emotionScores {
            if let va = emotionValenceArousal[emotion] {
                valence += va.valence * score
                arousal += va.arousal * score
                totalWeight += score
            }
        }
        
        if totalWeight > 0 {
            valence /= totalWeight
            arousal /= totalWeight
        }
        
        return (valence, arousal)
    }
    
    // MARK: - Helper Functions
    
    private func extractEmotionalKeywords(from text: String) -> [String] {
        var keywords: [String] = []
        
        for (_, emotionKeywords) in emotionKeywords {
            for keyword in emotionKeywords {
                if text.lowercased().contains(keyword) {
                    keywords.append(keyword)
                }
            }
        }
        
        return Array(Set(keywords)).prefix(5).map { String($0) }
    }
    
    private func generateEmotionalSuggestion(
        emotion: EmotionalTag,
        valence: Double,
        arousal: Double
    ) -> String? {
        
        switch emotion {
        case .frustrated:
            return "考虑将问题分解成更小的部分，或者休息一下重新审视"
        case .confused:
            return "尝试用不同的角度重新表述问题，或寻找相关参考"
        case .uncertain:
            return "列出已知和未知的因素，逐步减少不确定性"
        case .excited:
            return "把握这股能量，深入探索让你兴奋的想法"
        case .inspired:
            return "记录下灵感的细节，并探索可能的应用场景"
        case .curious:
            return "跟随好奇心，深入研究感兴趣的方向"
        case .calm:
            return "良好的思维状态，适合深度思考和分析"
        case .confident:
            return "利用这份自信推进关键决策或行动"
        }
    }
    
    private func calculateConfidence(emotionScores: [EmotionalTag: Double]) -> Double {
        // Confidence based on how dominant the primary emotion is
        guard let maxScore = emotionScores.values.max() else { return 0.5 }
        
        // If one emotion is clearly dominant, confidence is high
        let secondHighest = emotionScores.values.sorted().dropLast().last ?? 0
        let dominance = maxScore - secondHighest
        
        return min(1.0, 0.5 + dominance)
    }
    
    private func groupNodesByTimePeriod(_ nodes: [ThoughtNode]) -> [(String, DateInterval, [ThoughtNode])] {
        // Group by day for simplicity
        let calendar = Calendar.current
        var grouped: [Date: [ThoughtNode]] = [:]
        
        for node in nodes {
            let dayStart = calendar.startOfDay(for: node.createdAt)
            grouped[dayStart, default: []].append(node)
        }
        
        return grouped.map { date, nodes in
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!
            let interval = DateInterval(start: date, end: dayEnd)
            let name = date.formatted(date: .abbreviated, time: .omitted)
            return (name, interval, nodes)
        }.sorted { $0.1.start < $1.1.start }
    }
    
    private func generatePatternInsights(
        snapshots: [EmotionalSnapshot],
        dominantEmotions: [EmotionalTag]
    ) -> [String] {
        
        var insights: [String] = []
        
        // Insight about dominant emotion
        if let dominant = dominantEmotions.first {
            insights.append("主导情绪: \(dominant.displayName)")
        }
        
        // Insight about emotional variety
        let uniqueEmotions = Set(snapshots.map { $0.emotion })
        if uniqueEmotions.count > 4 {
            insights.append("情感表达丰富多样")
        } else if uniqueEmotions.count == 1 {
            insights.append("情绪状态相对稳定")
        }
        
        // Insight about intensity
        let avgIntensity = snapshots.reduce(0.0) { $0 + $1.intensity } / Double(snapshots.count)
        if avgIntensity > 0.7 {
            insights.append("情感强度较高")
        }
        
        return insights
    }
    
    private func calculateEmotionalVolatility(emotions: [EmotionalTag]) -> Double {
        guard emotions.count > 1 else { return 0 }
        
        var changes = 0
        for i in 1..<emotions.count {
            if emotions[i] != emotions[i-1] {
                changes += 1
            }
        }
        
        return Double(changes) / Double(emotions.count - 1)
    }
    
    private func identifyEmotionalTrends(nodes: [ThoughtNode]) -> [EmotionalTrend] {
        // Simple trend identification
        var emotionCounts: [EmotionalTag: [Date]] = [:]
        
        for node in nodes {
            // Use the first emotional tag if available
            if let emotion = node.emotionalTags.first {
                emotionCounts[emotion, default: []].append(node.createdAt)
            }
        }
        
        var trends: [EmotionalTrend] = []
        
        for (emotion, dates) in emotionCounts {
            guard dates.count >= 2 else { continue }
            
            let sorted = dates.sorted()
            let recent = sorted.suffix(min(5, sorted.count))
            let older = sorted.prefix(min(5, sorted.count))
            
            let recentCount = recent.count
            let olderCount = older.count
            
            let direction: EmotionalTrend.TrendDirection
            if recentCount > olderCount {
                direction = .rising
            } else if recentCount < olderCount {
                direction = .falling
            } else {
                direction = .stable
            }
            
            trends.append(EmotionalTrend(
                emotion: emotion,
                direction: direction,
                strength: Double(abs(recentCount - olderCount)) / Double(max(recentCount, olderCount)),
                timespan: sorted.last!.timeIntervalSince(sorted.first!)
            ))
        }
        
        return trends
    }
    
    // MARK: - Visualization
    
    func generateEmotionalHeatmap(for nodes: [ThoughtNode], gridSize: Int = 10) async {
        var heatmap: [[Double]] = Array(repeating: Array(repeating: 0.0, count: gridSize), count: gridSize)
        
        // Map nodes to grid positions
        let minX = nodes.map { $0.position.x }.min() ?? 0
        let maxX = nodes.map { $0.position.x }.max() ?? 100
        let minY = nodes.map { $0.position.y }.min() ?? 0
        let maxY = nodes.map { $0.position.y }.max() ?? 100
        
        for node in nodes {
            let result = await analyzeEmotion(for: node)
            
            // Map position to grid
            let gridX = Int((node.position.x - minX) / (maxX - minX) * Double(gridSize - 1))
            let gridY = Int((node.position.y - minY) / (maxY - minY) * Double(gridSize - 1))
            
            // Add emotional intensity to heatmap
            if gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize {
                heatmap[gridY][gridX] += result.arousal
            }
        }
        
        // Normalize heatmap
        let maxValue = heatmap.flatMap { $0 }.max() ?? 1.0
        if maxValue > 0 {
            for i in 0..<gridSize {
                for j in 0..<gridSize {
                    heatmap[i][j] /= maxValue
                }
            }
        }
        
        emotionalHeatmap = heatmap
    }
    
    func getEmotionColor(for emotion: EmotionalTag) -> Color {
        emotionColors[emotion] ?? .gray
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Setup any necessary observers
    }
}

// Extensions moved to avoid duplication