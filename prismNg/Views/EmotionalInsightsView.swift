import SwiftUI
import Charts

struct EmotionalInsightsView: View {
    @ObservedObject var emotionalService: EmotionalComputingService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange = TimeRange.week
    @State private var selectedEmotion: EmotionalTag?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time range selector
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Emotional landscape chart
                    EmotionalLandscapeChart(
                        emotionalService: emotionalService,
                        timeRange: selectedTimeRange
                    )
                    .frame(height: 200)
                    .padding(.horizontal)
                    
                    // Dominant emotions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Dominant Emotions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(emotionalService.dominantEmotions, id: \.emotion) { item in
                                EmotionCard(
                                    emotion: item.emotion,
                                    percentage: item.percentage,
                                    isSelected: selectedEmotion == item.emotion,
                                    onTap: {
                                        withAnimation {
                                            selectedEmotion = selectedEmotion == item.emotion ? nil : item.emotion
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Emotional patterns
                    if let selectedEmotion = selectedEmotion {
                        EmotionalPatternView(
                            emotion: selectedEmotion,
                            emotionalService: emotionalService
                        )
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Insights
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Insights")
                            .font(.headline)
                        
                        ForEach(emotionalService.insights, id: \.self) { insight in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                                
                                Text(insight)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Emotional Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EmotionalLandscapeChart: View {
    @ObservedObject var emotionalService: EmotionalComputingService
    let timeRange: TimeRange
    
    var body: some View {
        Chart(emotionalService.emotionalTimeline) { dataPoint in
            LineMark(
                x: .value("Time", dataPoint.date),
                y: .value("Intensity", dataPoint.intensity)
            )
            .foregroundStyle(by: .value("Emotion", dataPoint.emotion.rawValue))
            .symbol(by: .value("Emotion", dataPoint.emotion.rawValue))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartLegend(.visible)
    }
}

struct EmotionCard: View {
    let emotion: EmotionalTag
    let percentage: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: emotion.icon)
                    .font(.largeTitle)
                    .foregroundColor(emotion.color)
                
                Text(emotion.displayName)
                    .font(.headline)
                
                Text("\(Int(percentage))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? emotion.color.opacity(0.2) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? emotion.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct EmotionalPatternView: View {
    let emotion: EmotionalTag
    @ObservedObject var emotionalService: EmotionalComputingService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: emotion.icon)
                    .foregroundColor(emotion.color)
                Text("\(emotion.displayName) Patterns")
                    .font(.headline)
            }
            
            Text("This emotion typically appears when:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ForEach(emotionalService.getPatterns(for: emotion), id: \.self) { pattern in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(emotion.color)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    
                    Text(pattern)
                        .font(.subheadline)
                }
            }
        }
    }
}

enum TimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case all = "All"
}


#Preview {
    EmotionalInsightsView(emotionalService: EmotionalComputingService())
}