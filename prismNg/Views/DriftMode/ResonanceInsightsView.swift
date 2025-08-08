//
//  ResonanceInsightsView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP1c: Resonance Insights View - 共鸣瞬现洞察界面
//

import SwiftUI

// MARK: - Resonance Insights View

/// 共鸣洞察视图：显示漂移模式中的共鸣事件和偶然发现
struct ResonanceInsightsView: View {
    @ObservedObject var driftModeService: DriftModeService
    @State private var selectedResonance: ResonanceEvent?
    @State private var showingResonanceDetail = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 缪斯模式状态卡片
                    MuseModeStatusCard(driftModeService: driftModeService)
                    
                    // 偶然发现事件
                    if !driftModeService.serendipityEvents.isEmpty {
                        SerendipityEventsSection(events: driftModeService.serendipityEvents)
                    }
                    
                    // 当前共鸣事件
                    if !driftModeService.currentResonances.isEmpty {
                        ResonanceEventsSection(
                            resonances: driftModeService.currentResonances,
                            onResonanceSelected: { resonance in
                                selectedResonance = resonance
                                showingResonanceDetail = true
                            }
                        )
                    }
                    
                    // 空状态
                    if driftModeService.currentResonances.isEmpty && 
                       driftModeService.serendipityEvents.isEmpty &&
                       !driftModeService.isDriftModeActive {
                        EmptyStateView()
                    }
                }
                .padding()
            }
            .navigationTitle("共鸣洞察")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            if driftModeService.isDriftModeActive {
                                driftModeService.deactivateDriftMode()
                            } else {
                                // 需要传递场景和动画系统引用，这里暂时注释
                                // driftModeService.activateDriftMode(in: scene, animationSystem: animSystem)
                            }
                        } label: {
                            Label(
                                driftModeService.isDriftModeActive ? "停用漂移模式" : "激活漂移模式",
                                systemImage: driftModeService.isDriftModeActive ? "pause.circle" : "play.circle"
                            )
                        }
                        
                        if driftModeService.isDriftModeActive {
                            Button {
                                if driftModeService.isMuseModeActive {
                                    driftModeService.deactivateMuseMode()
                                } else {
                                    driftModeService.activateMuseMode()
                                }
                            } label: {
                                Label(
                                    driftModeService.isMuseModeActive ? "退出缪斯模式" : "进入缪斯模式",
                                    systemImage: driftModeService.isMuseModeActive ? "moon.stars" : "sparkles"
                                )
                            }
                        }
                        
                        Divider()
                        
                        Button {
                            driftModeService.forceResonanceDetection()
                        } label: {
                            Label("手动检测共鸣", systemImage: "magnifyingglass")
                        }
                        
                        Button {
                            driftModeService.clearResonanceHistory()
                        } label: {
                            Label("清除历史", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingResonanceDetail) {
                if let resonance = selectedResonance {
                    ResonanceDetailView(resonance: resonance)
                }
            }
        }
    }
}

// MARK: - Muse Mode Status Card

struct MuseModeStatusCard: View {
    @ObservedObject var driftModeService: DriftModeService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: driftModeService.isMuseModeActive ? "moon.stars.fill" : "circle.dashed")
                    .font(.title2)
                    .foregroundColor(driftModeService.isMuseModeActive ? .purple : .secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(driftModeService.isMuseModeActive ? "缪斯模式" : "漂移模式")
                        .font(.headline)
                    
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 漂移强度指示器
                VStack(alignment: .trailing, spacing: 4) {
                    Text("强度")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Circle()
                                .fill(index < Int(driftModeService.driftIntensity * 5) ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            
            if driftModeService.isDriftModeActive {
                // 活动状态指示器
                HStack {
                    Label("节点正在自由漂移", systemImage: "waveform.path")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    if driftModeService.isMuseModeActive {
                        Label("认知迷雾激活", systemImage: "cloud.fog")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(driftModeService.isMuseModeActive ? Color.purple.opacity(0.1) : Color.blue.opacity(0.1))
        )
    }
    
    private var statusDescription: String {
        if driftModeService.isMuseModeActive {
            return "深度孵化模式，增强偶然发现"
        } else if driftModeService.isDriftModeActive {
            return "思想节点正在进行布朗运动"
        } else {
            return "静态模式，节点位置固定"
        }
    }
}

// MARK: - Serendipity Events Section

struct SerendipityEventsSection: View {
    let events: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.orange)
                
                Text("偶然发现")
                    .font(.headline)
            }
            
            ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                SerendipityEventCard(event: event, isRecent: index >= events.count - 2)
            }
        }
    }
}

struct SerendipityEventCard: View {
    let event: String
    let isRecent: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)
                .font(.callout)
            
            Text(event)
                .font(.callout)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if isRecent {
                Text("新")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(isRecent ? 0.1 : 0.05))
        )
    }
}

// MARK: - Resonance Events Section

struct ResonanceEventsSection: View {
    let resonances: [ResonanceEvent]
    let onResonanceSelected: (ResonanceEvent) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.blue)
                
                Text("共鸣事件")
                    .font(.headline)
                
                Spacer()
                
                Text("\(resonances.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            
            LazyVStack(spacing: 8) {
                ForEach(resonances.suffix(5).reversed()) { resonance in
                    ResonanceEventCard(
                        resonance: resonance,
                        onTap: { onResonanceSelected(resonance) }
                    )
                }
            }
        }
    }
}

struct ResonanceEventCard: View {
    let resonance: ResonanceEvent
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // 共鸣类型指示器
                    Circle()
                        .fill(resonance.resonanceType.color)
                        .frame(width: 12, height: 12)
                    
                    Text(resonance.resonanceType.displayName)
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // 相似度指示器
                    Text("\(Int(resonance.similarity * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 时间戳
                    Text(resonance.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(resonance.semanticBridge)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                // 连接强度可视化
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(resonance.resonanceType.color.opacity(0.3))
                        .frame(height: 4)
                        .overlay(
                            HStack {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(resonance.resonanceType.color)
                                    .frame(width: geometry.size.width * CGFloat(resonance.connectionStrength))
                                
                                Spacer(minLength: 0)
                            }
                        )
                }
                .frame(height: 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(resonance.resonanceType.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "moon.stars")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("启动漂移模式")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("让思想节点自由漂移，发现意外的连接和共鸣")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Resonance Detail View

struct ResonanceDetailView: View {
    let resonance: ResonanceEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 共鸣类型卡片
                    ResonanceTypeCard(resonance: resonance)
                    
                    // 连接信息
                    ConnectionInfoCard(resonance: resonance)
                    
                    // 语义桥梁
                    SemanticBridgeCard(bridge: resonance.semanticBridge)
                    
                    // 时间线信息
                    TimelineInfoCard(resonance: resonance)
                }
                .padding()
            }
            .navigationTitle("共鸣详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ResonanceTypeCard: View {
    let resonance: ResonanceEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(resonance.resonanceType.color)
                    .frame(width: 20, height: 20)
                
                Text(resonance.resonanceType.displayName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(resonance.similarity * 100))%")
                    .font(.headline)
                    .foregroundColor(resonance.resonanceType.color)
            }
            
            Text(getResonanceDescription(for: resonance.resonanceType))
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(resonance.resonanceType.color.opacity(0.1))
        )
    }
    
    private func getResonanceDescription(for type: ResonanceType) -> String {
        switch type {
        case .harmonic:
            return "两个思想在概念层面高度一致，形成和谐共鸣。这种连接可能揭示了深层的模式或原理。"
        case .complementary:
            return "两个思想相互补充，各自填补对方的空白。这种连接可能带来更完整的理解。"
        case .creative:
            return "两个看似不同的思想产生了创意性的连接。这种碰撞可能催生新的想法。"
        case .unexpected:
            return "意外的连接被发现，可能隐藏着尚未被意识到的深层关联。"
        }
    }
}

struct ConnectionInfoCard: View {
    let resonance: ResonanceEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("连接信息")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("节点 A")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(resonance.nodeA.uuidString.prefix(8))
                        .font(.callout)
                        .fontWeight(.medium)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("节点 B")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(resonance.nodeB.uuidString.prefix(8))
                        .font(.callout)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            // 连接强度可视化
            VStack(alignment: .leading, spacing: 4) {
                Text("连接强度")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ProgressView(value: Double(resonance.connectionStrength))
                    .tint(resonance.resonanceType.color)
                    .scaleEffect(y: 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct SemanticBridgeCard: View {
    let bridge: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "link")
                    .foregroundColor(.blue)
                
                Text("语义桥梁")
                    .font(.headline)
            }
            
            Text(bridge)
                .font(.callout)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct TimelineInfoCard: View {
    let resonance: ResonanceEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                
                Text("时间线")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("发现时间:")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Text(resonance.timestamp, style: .date)
                        .font(.callout)
                        .fontWeight(.medium)
                    
                    Text(resonance.timestamp, style: .time)
                        .font(.callout)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("已过时间:")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    Text(resonance.timestamp, style: .relative)
                        .font(.callout)
                        .fontWeight(.medium)
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

#Preview {
    ResonanceInsightsView(driftModeService: DriftModeService())
}