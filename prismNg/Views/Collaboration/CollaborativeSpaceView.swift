//
//  CollaborativeSpaceView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP1c: Collaborative Space View - 多人实时协作界面
//

import SwiftUI

// MARK: - Collaborative Space List View

/// 协作空间列表视图
struct CollaborativeSpacesListView: View {
    @StateObject private var collaborationService = CollaborativeSpaceService(
        userId: UUID().uuidString,
        aiService: AIService()
    )
    @State private var showingCreateSpace = false
    @State private var selectedSpace: CollaborativeSpace?
    @State private var showingSpaceDetail = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 当前空间状态
                if let currentSpace = collaborationService.currentSpace {
                    CurrentSpaceStatusBar(
                        space: currentSpace,
                        participantCount: collaborationService.participants.count,
                        onLeave: {
                            Task {
                                try? await collaborationService.leaveSpace()
                            }
                        }
                    )
                }
                
                // 可用空间列表
                List {
                    Section {
                        ForEach(collaborationService.availableSpaces) { space in
                            CollaborativeSpaceRow(
                                space: space,
                                onJoin: {
                                    Task {
                                        try? await collaborationService.joinSpace(space.id)
                                    }
                                },
                                onShowDetail: {
                                    selectedSpace = space
                                    showingSpaceDetail = true
                                }
                            )
                        }
                    } header: {
                        Text("可用的协作空间")
                    }
                }
            }
            .navigationTitle("协作空间")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateSpace = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSpace) {
                CreateCollaborativeSpaceView(collaborationService: collaborationService)
            }
            .sheet(isPresented: $showingSpaceDetail) {
                if let space = selectedSpace {
                    CollaborativeSpaceDetailView(space: space, collaborationService: collaborationService)
                }
            }
        }
    }
}

// MARK: - Current Space Status Bar

struct CurrentSpaceStatusBar: View {
    let space: CollaborativeSpace
    let participantCount: Int
    let onLeave: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("当前空间: \(space.name)")
                    .font(.callout)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    Label("\(participantCount)", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label(space.collaborationMode.displayName, systemImage: "bubble.left.and.bubble.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("离开", action: onLeave)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
    }
}

// MARK: - Collaborative Space Row

struct CollaborativeSpaceRow: View {
    let space: CollaborativeSpace
    let onJoin: () -> Void
    let onShowDetail: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(space.name)
                        .font(.headline)
                    
                    if !space.description.isEmpty {
                        Text(space.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(space.currentParticipants.count)/\(space.maxParticipants)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("加入") {
                        onJoin()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .disabled(space.currentParticipants.count >= space.maxParticipants)
                }
            }
            
            HStack(spacing: 16) {
                // 协作模式
                Label(space.collaborationMode.displayName, systemImage: "bubble.left.and.bubble.right")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                // AI调解员状态
                if space.aiMediatorSettings.enabled {
                    Label("AI调解", systemImage: "brain")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                
                // 公开状态
                if space.isPublic {
                    Label("公开", systemImage: "globe")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Button("详情") {
                    onShowDetail()
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Create Collaborative Space View

struct CreateCollaborativeSpaceView: View {
    @ObservedObject var collaborationService: CollaborativeSpaceService
    @Environment(\.dismiss) private var dismiss
    
    @State private var spaceName = ""
    @State private var spaceDescription = ""
    @State private var selectedMode: CollaborativeSpace.CollaborationMode = .freeform
    @State private var isPublic = true
    @State private var maxParticipants = 6
    @State private var aiMediatorEnabled = true
    @State private var interventionLevel: AIMediatorSettings.InterventionLevel = .moderate
    @State private var personalityType: AIMediatorSettings.AIPersonalityType = .neutral
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    TextField("空间名称", text: $spaceName)
                    TextField("描述（可选）", text: $spaceDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("协作设置") {
                    Picker("协作模式", selection: $selectedMode) {
                        ForEach(CollaborativeSpace.CollaborationMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    HStack {
                        Text("最大参与者")
                        Spacer()
                        Stepper("\(maxParticipants)", value: $maxParticipants, in: 2...20)
                    }
                    
                    Toggle("公开空间", isOn: $isPublic)
                }
                
                Section("AI调解员") {
                    Toggle("启用AI调解员", isOn: $aiMediatorEnabled)
                    
                    if aiMediatorEnabled {
                        Picker("介入级别", selection: $interventionLevel) {
                            ForEach(AIMediatorSettings.InterventionLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Picker("AI性格", selection: $personalityType) {
                            ForEach(AIMediatorSettings.AIPersonalityType.allCases, id: \.self) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("预览")
                            .font(.headline)
                        
                        Text("空间类型: \(selectedMode.displayName)")
                        Text("AI角色: \(selectedMode.aiRole)")
                        if aiMediatorEnabled {
                            Text("AI介入级别: \(interventionLevel.displayName)")
                            Text("AI性格: \(personalityType.displayName)")
                        }
                    }
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
            }
            .navigationTitle("创建协作空间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        createSpace()
                    }
                    .disabled(spaceName.isEmpty)
                }
            }
        }
    }
    
    private func createSpace() {
        Task {
            // TODO: Fix collaborationService method call
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Collaborative Space Detail View

struct CollaborativeSpaceDetailView: View {
    let space: CollaborativeSpace
    @ObservedObject var collaborationService: CollaborativeSpaceService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 空间信息卡片
                    SpaceInfoCard(space: space)
                    
                    // 参与者列表
                    if !collaborationService.participants.isEmpty {
                        ParticipantsSection(participants: collaborationService.participants)
                    }
                    
                    // AI调解员状态
                    if space.aiMediatorSettings.enabled {
                        AIMediatorStatusCard(
                            settings: space.aiMediatorSettings,
                            isActive: false,
                            onToggle: {
                                // TODO: Implement AI mediator toggle
                            }
                        )
                    }
                    
                    // 实时活动
                    // TODO: Fix realtimeEvents implementation
                    /*
                    if !collaborationService.realtimeEvents.isEmpty {
                        RealtimeActivitySection(events: collaborationService.realtimeEvents.suffix(10).reversed())
                    }
                    
                    // 共识点
                    if !collaborationService.consensusPoints.isEmpty {
                        ConsensusPointsSection(points: collaborationService.consensusPoints)
                    }
                    */
                    
                    // 冲突警告
                    if !collaborationService.conflictAlerts.isEmpty {
                        ConflictAlertsSection(alerts: collaborationService.conflictAlerts)
                    }
                }
                .padding()
            }
            .navigationTitle(space.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                if collaborationService.currentSpace?.id != space.id {
                    ToolbarItem(placement: .primaryAction) {
                        Button("加入空间") {
                            Task {
                                try? await collaborationService.joinSpace(space.id)
                                dismiss()
                            }
                        }
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button("离开空间") {
                            Task {
                                try? await collaborationService.leaveSpace()
                                dismiss()
                            }
                        }
                        .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SpaceInfoCard: View {
    let space: CollaborativeSpace
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(space.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if !space.description.isEmpty {
                        Text(space.description)
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(space.currentParticipants.count)/\(space.maxParticipants)")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text("参与者")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                InfoChip(
                    icon: "bubble.left.and.bubble.right",
                    title: "协作模式",
                    value: space.collaborationMode.displayName,
                    color: .blue
                )
                
                InfoChip(
                    icon: "brain",
                    title: "AI角色",
                    value: space.collaborationMode.aiRole,
                    color: .purple
                )
                
                InfoChip(
                    icon: space.isPublic ? "globe" : "lock",
                    title: "可见性",
                    value: space.isPublic ? "公开" : "私有",
                    color: space.isPublic ? .green : .orange
                )
                
                InfoChip(
                    icon: "clock",
                    title: "最后活动",
                    value: RelativeDateTimeFormatter().localizedString(for: space.lastActivityAt, relativeTo: Date()),
                    color: .gray
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

struct InfoChip: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct ParticipantsSection: View {
    let participants: [CollaborationParticipant]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("参与者 (\(participants.count))")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                ForEach(participants) { participant in
                    ParticipantCard(participant: participant)
                }
            }
        }
    }
}

struct ParticipantCard: View {
    let participant: CollaborationParticipant
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(participant.avatarColor))
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .fill(participant.isOnline ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                        .offset(x: 8, y: 8)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(participant.role.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct AIMediatorStatusCard: View {
    let settings: AIMediatorSettings
    let isActive: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                
                Text("AI调解员")
                    .font(.headline)
                
                Spacer()
                
                Button(isActive ? "停用" : "激活") {
                    onToggle()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(isActive ? Color.red : Color.purple)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("介入级别")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(settings.interventionLevel.displayName)
                        .font(.callout)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI性格")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(settings.personalityType.displayName)
                        .font(.callout)
                        .fontWeight(.medium)
                }
            }
            
            if isActive {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Text("AI调解员正在观察协作过程")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.1))
        )
    }
}

struct RealtimeActivitySection: View {
    let events: [CollaborationEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("实时活动")
                .font(.headline)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                    ActivityEventRow(event: event)
                }
            }
        }
    }
}

struct ActivityEventRow: View {
    let event: CollaborationEvent
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: getEventIcon(for: event.eventType))
                .font(.caption)
                .foregroundColor(getEventColor(for: event.eventType))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(getEventDisplayName(for: event.eventType))
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(event.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func getEventDisplayName(for eventType: CollaborationEvent.EventType) -> String {
        switch eventType {
        case .joined: return "加入空间"
        case .left: return "离开空间"
        case .nodeCreated: return "创建节点"
        case .nodeUpdated: return "更新节点"
        case .nodeDeleted: return "删除节点"
        case .connectionCreated: return "创建连接"
        case .connectionDeleted: return "删除连接"
        case .cursorMoved: return "光标移动"
        case .aiSuggestion: return "AI建议"
        case .consensusRequest: return "共识请求"
        case .voteCast: return "投票"
        }
    }
    
    private func getEventIcon(for eventType: CollaborationEvent.EventType) -> String {
        switch eventType {
        case .joined: return "person.badge.plus"
        case .left: return "person.badge.minus"
        case .nodeCreated: return "plus.circle"
        case .nodeUpdated: return "pencil.circle"
        case .nodeDeleted: return "minus.circle"
        case .connectionCreated: return "link"
        case .connectionDeleted: return "link.badge.minus"
        case .cursorMoved: return "cursorarrow"
        case .aiSuggestion: return "brain"
        case .consensusRequest: return "checkmark.circle"
        case .voteCast: return "exclamationmark.triangle"
        }
    }
    
    private func getEventColor(for eventType: CollaborationEvent.EventType) -> Color {
        switch eventType {
        case .joined: return .green
        case .left: return .orange
        case .nodeCreated: return .blue
        case .nodeUpdated: return .yellow
        case .nodeDeleted: return .red
        case .connectionCreated: return .purple
        case .connectionDeleted: return .pink
        case .cursorMoved: return .gray
        case .aiSuggestion: return .purple
        case .consensusRequest: return .green
        case .voteCast: return .red
        }
    }
}

struct ConsensusPointsSection: View {
    let points: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("达成的共识")
                    .font(.headline)
            }
            
            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(point)
                        .font(.callout)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
}

struct ConflictAlertsSection: View {
    let alerts: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("协作提醒")
                    .font(.headline)
            }
            
            ForEach(Array(alerts.enumerated()), id: \.offset) { index, alert in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text(alert)
                        .font(.callout)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

#Preview {
    CollaborativeSpacesListView()
}