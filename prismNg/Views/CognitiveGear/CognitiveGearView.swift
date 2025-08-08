//
//  CognitiveGearView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP1c: Cognitive Gear View - 认知档位系统界面
//

import SwiftUI
import Charts

// MARK: - Cognitive Gear Selector

/// 认知档位选择器：流畅的档位切换界面
struct CognitiveGearSelectorView: View {
    @ObservedObject var gearService: CognitiveGearService
    @State private var showingGearDetail = false
    @State private var selectedGear: CognitiveGear?
    @State private var showingHistory = false
    @State private var showingAnalytics = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Current gear indicator
            CurrentGearIndicator(
                currentGear: gearService.currentGear,
                isTransitioning: gearService.isTransitioning,
                onTap: {
                    selectedGear = gearService.currentGear
                    showingGearDetail = true
                }
            )
            
            // Gear selection wheel
            GearSelectionWheel(
                gears: CognitiveGear.allCases,
                currentGear: gearService.currentGear,
                onGearSelected: { gear in
                    gearService.switchToGear(gear, reason: "用户选择")
                }
            )
            
            // Contextual suggestions
            if !gearService.contextualSuggestions.isEmpty {
                ContextualSuggestions(
                    suggestions: gearService.contextualSuggestions,
                    onAccept: { suggestion in
                        gearService.acceptSuggestion(suggestion)
                    },
                    onDismiss: { suggestion in
                        gearService.dismissSuggestion(suggestion)
                    }
                )
            }
            
            // Quick actions
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "clock.arrow.circlepath",
                    title: "历史",
                    action: { showingHistory = true }
                )
                
                QuickActionButton(
                    icon: "chart.bar",
                    title: "分析",
                    action: { showingAnalytics = true }
                )
                
                if gearService.previousGear != nil {
                    QuickActionButton(
                        icon: "arrow.uturn.backward",
                        title: "返回",
                        action: { gearService.switchBack() }
                    )
                }
            }
        }
        .sheet(isPresented: $showingGearDetail) {
            if let gear = selectedGear {
                GearDetailView(gear: gear, gearService: gearService)
            }
        }
        .sheet(isPresented: $showingHistory) {
            GearHistoryView(gearService: gearService)
        }
        .sheet(isPresented: $showingAnalytics) {
            GearAnalyticsView(gearService: gearService)
        }
    }
}

// MARK: - Current Gear Indicator

struct CurrentGearIndicator: View {
    let currentGear: CognitiveGear
    let isTransitioning: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(currentGear.lightColor)
                        .frame(width: 80, height: 80)
                    
                    // Gear icon
                    Image(systemName: currentGear.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(currentGear.color)
                        .scaleEffect(isTransitioning ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: isTransitioning)
                    
                    // Transition indicator
                    if isTransitioning {
                        Circle()
                            .stroke(currentGear.color.opacity(0.3), lineWidth: 3)
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(isTransitioning ? 360 : 0))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isTransitioning)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(currentGear.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(currentGear.subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Gear Selection Wheel

struct GearSelectionWheel: View {
    let gears: [CognitiveGear]
    let currentGear: CognitiveGear
    let onGearSelected: (CognitiveGear) -> Void
    
    @State private var selectedIndex = 0
    
    var body: some View {
        VStack(spacing: 12) {
            // Wheel visualization
            GeometryReader { geometry in
                let radius = min(geometry.size.width, geometry.size.height) / 2 - 40
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 2)
                        .frame(width: radius * 2, height: radius * 2)
                        .position(center)
                    
                    // Gear positions
                    ForEach(Array(gears.enumerated()), id: \.offset) { index, gear in
                        let angle = Double(index) * (360.0 / Double(gears.count)) - 90
                        let position = positionForAngle(angle, radius: radius, center: center)
                        
                        GearWheelButton(
                            gear: gear,
                            isSelected: gear == currentGear,
                            isHighlighted: index == selectedIndex,
                            onTap: {
                                selectedIndex = index
                                onGearSelected(gear)
                            }
                        )
                        .position(position)
                    }
                    
                    // Selection indicator line
                    if selectedIndex < gears.count {
                        let angle = Double(selectedIndex) * (360.0 / Double(gears.count)) - 90
                        let endPosition = positionForAngle(angle, radius: radius - 20, center: center)
                        
                        Path { path in
                            path.move(to: center)
                            path.addLine(to: endPosition)
                        }
                        .stroke(gears[selectedIndex].color.opacity(0.5), lineWidth: 2)
                        .animation(.easeInOut(duration: 0.3), value: selectedIndex)
                    }
                }
            }
            .frame(height: 200)
            .onAppear {
                if let currentIndex = gears.firstIndex(of: currentGear) {
                    selectedIndex = currentIndex
                }
            }
            
            // Selected gear info
            if selectedIndex < gears.count {
                let selectedGear = gears[selectedIndex]
                VStack(spacing: 4) {
                    Text(selectedGear.displayName)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(selectedGear.color)
                    
                    Text(selectedGear.subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func positionForAngle(_ angle: Double, radius: CGFloat, center: CGPoint) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + radius * CGFloat(cos(radians)),
            y: center.y + radius * CGFloat(sin(radians))
        )
    }
}

struct GearWheelButton: View {
    let gear: CognitiveGear
    let isSelected: Bool
    let isHighlighted: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                Circle()
                    .fill(isSelected ? gear.color : (isHighlighted ? gear.lightColor : Color.clear))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(gear.color, lineWidth: isSelected ? 2 : 1)
                    )
                
                // Icon
                Image(systemName: gear.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : gear.color)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isHighlighted ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
    }
}

// MARK: - Contextual Suggestions

struct ContextualSuggestions: View {
    let suggestions: [GearSuggestion]
    let onAccept: (GearSuggestion) -> Void
    let onDismiss: (GearSuggestion) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                
                Text("智能建议")
                    .font(.callout)
                    .fontWeight(.medium)
            }
            
            ForEach(suggestions.prefix(2)) { suggestion in
                SuggestionCard(
                    suggestion: suggestion,
                    onAccept: { onAccept(suggestion) },
                    onDismiss: { onDismiss(suggestion) }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

struct SuggestionCard: View {
    let suggestion: GearSuggestion
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Recommended gear icon
            Image(systemName: suggestion.recommendedGear.icon)
                .foregroundColor(suggestion.recommendedGear.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("建议切换到\(suggestion.recommendedGear.displayName)")
                    .font(.callout)
                    .fontWeight(.medium)
                
                Text(suggestion.reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Confidence indicator
            ConfidenceIndicator(confidence: suggestion.confidence)
            
            // Actions
            HStack(spacing: 8) {
                Button("采纳") {
                    onAccept()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(suggestion.recommendedGear.color)
                .foregroundColor(.white)
                .clipShape(Capsule())
                
                Button("忽略") {
                    onDismiss()
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ConfidenceIndicator: View {
    let confidence: Double
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 1) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(confidence > Double(index) * 0.33 ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 3, height: 8)
                }
            }
            
            Text("\(Int(confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 60, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .foregroundColor(.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Gear Detail View

struct GearDetailView: View {
    let gear: CognitiveGear
    @ObservedObject var gearService: CognitiveGearService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    GearHeaderCard(gear: gear)
                    
                    // Description
                    GearDescriptionCard(gear: gear)
                    
                    // Characteristics
                    GearCharacteristicsCard(gear: gear)
                    
                    // Usage stats
                    if let stats = gearService.usageStats[gear] {
                        GearUsageStatsCard(stats: stats)
                    }
                    
                    // Switch button
                    if gear != gearService.currentGear {
                        Button {
                            gearService.switchToGear(gear, reason: "详情页切换")
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                Text("切换到\(gear.displayName)")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(gear.color)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(gear.displayName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GearHeaderCard: View {
    let gear: CognitiveGear
    
    var body: some View {
        HStack(spacing: 16) {
            // Large icon
            ZStack {
                Circle()
                    .fill(gear.lightColor)
                    .frame(width: 80, height: 80)
                
                Image(systemName: gear.icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(gear.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(gear.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(gear.subtitle)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(gear.lightColor)
        )
    }
}

struct GearDescriptionCard: View {
    let gear: CognitiveGear
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("模式说明")
                .font(.headline)
            
            Text(gear.description)
                .font(.callout)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct GearCharacteristicsCard: View {
    let gear: CognitiveGear
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("核心特征")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 8) {
                ForEach(gear.characteristics, id: \.self) { characteristic in
                    CharacteristicChip(characteristic: characteristic, color: gear.color)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct CharacteristicChip: View {
    let characteristic: CognitiveCharacteristic
    let color: Color
    
    var body: some View {
        Text(characteristic.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.2))
            )
            .foregroundColor(color)
    }
}

struct GearUsageStatsCard: View {
    let stats: GearUsageStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用统计")
                .font(.headline)
            
            VStack(spacing: 8) {
                UsageStatRow(
                    title: "总使用时长",
                    value: formatDuration(stats.totalTimeSpent),
                    icon: "clock"
                )
                
                UsageStatRow(
                    title: "使用次数",
                    value: "\(stats.sessionCount) 次",
                    icon: "number"
                )
                
                UsageStatRow(
                    title: "平均时长",
                    value: formatDuration(stats.averageSessionDuration),
                    icon: "chart.bar"
                )
                
                UsageStatRow(
                    title: "效率评级",
                    value: stats.efficiencyRating.displayName,
                    icon: "star",
                    valueColor: stats.efficiencyRating.color
                )
                
                UsageStatRow(
                    title: "最后使用",
                    value: RelativeDateTimeFormatter().localizedString(for: stats.lastUsed, relativeTo: Date()),
                    icon: "calendar"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
}

struct UsageStatRow: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = .primary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.callout)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Gear History View

struct GearHistoryView: View {
    @ObservedObject var gearService: CognitiveGearService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(gearService.getRecentHistory()) { transition in
                    GearTransitionRow(transition: transition)
                }
            }
            .navigationTitle("切换历史")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("清除") {
                        gearService.resetUsageStats()
                    }
                    .foregroundColor(.red)
                }
            }
        }
    }
}

struct GearTransitionRow: View {
    let transition: GearTransition
    
    var body: some View {
        HStack(spacing: 12) {
            // From gear
            Image(systemName: transition.fromGear.icon)
                .foregroundColor(transition.fromGear.color)
                .frame(width: 24)
            
            // Arrow
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.caption)
            
            // To gear
            Image(systemName: transition.toGear.icon)
                .foregroundColor(transition.toGear.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(transition.fromGear.displayName) → \(transition.toGear.displayName)")
                    .font(.callout)
                    .fontWeight(.medium)
                
                Text(transition.reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(transition.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if transition.duration > 0 {
                    Text("\(Int(transition.duration / 60))分钟")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Gear Analytics View

struct GearAnalyticsView: View {
    @ObservedObject var gearService: CognitiveGearService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Usage distribution chart
                    GearUsageChart(usageStats: gearService.usageStats)
                    
                    // Insights
                    GearInsightsCard(insights: gearService.getGearInsights())
                    
                    // Efficiency comparison
                    GearEfficiencyComparison(usageStats: gearService.usageStats)
                    
                    // Optimal sequence
                    OptimalSequenceCard(sequence: gearService.getOptimalGearSequence())
                }
                .padding()
            }
            .navigationTitle("使用分析")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GearUsageChart: View {
    let usageStats: [CognitiveGear: GearUsageStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("使用时长分布")
                .font(.headline)
            
            if !usageStats.isEmpty {
                Chart {
                    ForEach(Array(usageStats.keys), id: \.self) { gear in
                        if let stats = usageStats[gear] {
                            SectorMark(
                                angle: .value("时长", stats.totalTimeSpent),
                                innerRadius: .ratio(0.6),
                                angularInset: 2
                            )
                            .foregroundStyle(gear.color)
                            .opacity(0.8)
                        }
                    }
                }
                .frame(height: 200)
                
                // Legend
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(Array(usageStats.keys), id: \.self) { gear in
                        if let stats = usageStats[gear] {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(gear.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(gear.displayName)
                                    .font(.caption2)
                                
                                Text("(\(Int(stats.totalTimeSpent / 60))分)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            } else {
                Text("暂无使用数据")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct GearInsightsCard: View {
    let insights: [GearInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.yellow)
                
                Text("个性化洞察")
                    .font(.headline)
            }
            
            if insights.isEmpty {
                Text("继续使用以获得个性化洞察")
                    .font(.callout)
                    .foregroundColor(.secondary)
            } else {
                ForEach(insights) { insight in
                    InsightRow(insight: insight)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

struct InsightRow: View {
    let insight: GearInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: insight.gear.icon)
                .foregroundColor(insight.gear.color)
                .frame(width: 20)
            
            Text(insight.description)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
}

struct GearEfficiencyComparison: View {
    let usageStats: [CognitiveGear: GearUsageStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("效率对比")
                .font(.headline)
            
            ForEach(Array(usageStats.keys).sorted(by: { 
                (usageStats[$0]?.productivityScore ?? 0) > (usageStats[$1]?.productivityScore ?? 0) 
            }), id: \.self) { gear in
                if let stats = usageStats[gear] {
                    EfficiencyRow(gear: gear, stats: stats)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct EfficiencyRow: View {
    let gear: CognitiveGear
    let stats: GearUsageStats
    
    var body: some View {
        HStack {
            Image(systemName: gear.icon)
                .foregroundColor(gear.color)
                .frame(width: 20)
            
            Text(gear.displayName)
                .font(.callout)
            
            Spacer()
            
            // Efficiency bar
            GeometryReader { geometry in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: geometry.size.width * 0.7)
                        .overlay(
                            HStack {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(stats.efficiencyRating.color)
                                    .frame(width: geometry.size.width * 0.7 * CGFloat(stats.productivityScore))
                                
                                Spacer(minLength: 0)
                            }
                        )
                    
                    Text("\(Int(stats.productivityScore * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 80)
        }
        .padding(.vertical, 4)
    }
}

struct OptimalSequenceCard: View {
    let sequence: [CognitiveGear]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.blue)
                
                Text("推荐切换序列")
                    .font(.headline)
            }
            
            HStack(spacing: 8) {
                ForEach(Array(sequence.enumerated()), id: \.offset) { index, gear in
                    HStack(spacing: 4) {
                        Image(systemName: gear.icon)
                            .foregroundColor(gear.color)
                            .font(.caption)
                        
                        Text(gear.displayName)
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(gear.lightColor)
                    )
                    
                    if index < sequence.count - 1 {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("基于您的使用习惯，这个切换序列可能最适合您的思维流程")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

#Preview {
    CognitiveGearSelectorView(gearService: CognitiveGearService(quotaService: QuotaManagementService()))
}