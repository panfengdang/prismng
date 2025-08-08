//
//  CloudSyncView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP2-3: Cloud Sync View - 云同步管理界面
//

import SwiftUI
import Charts

// MARK: - Cloud Sync Dashboard

/// 云同步管理主界面
struct CloudSyncView: View {
    @ObservedObject var syncService: EnhancedCloudSyncService
    @ObservedObject var storeKitService: StoreKitService
    @State private var showingConflictResolution = false
    @State private var selectedConflict: ConflictedNode?
    @State private var showingDeviceManager = false
    @State private var showingSyncHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Sync status card
                    SyncStatusCard(syncService: syncService)
                    
                    // Pro feature notice
                    if !syncService.isProUser {
                        ProFeatureNotice(storeKitService: storeKitService)
                    } else {
                        // Active devices
                        if !syncService.activeSyncSessions.isEmpty {
                            ActiveDevicesCard(
                                sessions: syncService.activeSyncSessions,
                                onManage: { showingDeviceManager = true }
                            )
                        }
                        
                        // Sync metrics
                        SyncMetricsCard(metrics: syncService.syncMetrics)
                        
                        // Conflicts
                        if !syncService.conflictedNodes.isEmpty {
                            ConflictsCard(
                                conflicts: syncService.conflictedNodes,
                                onResolve: { conflict in
                                    selectedConflict = conflict
                                    showingConflictResolution = true
                                }
                            )
                        }
                        
                        // Sync controls
                        SyncControlsCard(syncService: syncService)
                    }
                }
                .padding()
            }
            .navigationTitle("云同步")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSyncHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingConflictResolution) {
                if let conflict = selectedConflict {
                    ConflictResolutionView(
                        conflict: conflict,
                        syncService: syncService
                    )
                }
            }
            .sheet(isPresented: $showingDeviceManager) {
                DeviceManagerView(syncService: syncService)
            }
            .sheet(isPresented: $showingSyncHistory) {
                SyncHistoryView(syncService: syncService)
            }
        }
    }
}

// MARK: - Sync Status Card

struct SyncStatusCard: View {
    @ObservedObject var syncService: EnhancedCloudSyncService
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Status icon
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                    .symbolEffect(.pulse, options: .repeating, isActive: syncService.syncStatus == .syncing)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.headline)
                    
                    Text(statusDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Sync button
                if syncService.isProUser {
                    Button {
                        Task {
                            await syncService.startRealtimeSync()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                    }
                    .disabled(syncService.syncStatus == .syncing)
                }
            }
            
            if let lastSync = syncService.syncMetrics.lastSyncTime {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("上次同步: \(lastSync, style: .relative)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
        )
    }
    
    private var statusIcon: String {
        switch syncService.syncStatus {
        case .idle: return "icloud"
        case .syncing: return "icloud.and.arrow.up.and.arrow.down"
        case .success: return "icloud.fill"
        case .error: return "exclamationmark.icloud"
        }
    }
    
    private var statusColor: Color {
        switch syncService.syncStatus {
        case .idle: return .gray
        case .syncing: return .blue
        case .success: return .green
        case .error: return .red
        }
    }
    
    private var statusTitle: String {
        switch syncService.syncStatus {
        case .idle: return "云同步已就绪"
        case .syncing: return "正在同步..."
        case .success: return "同步成功"
        case .error(let message): return "同步错误"
        }
    }
    
    private var statusDescription: String {
        switch syncService.syncStatus {
        case .idle: return "您的数据已准备好同步到云端"
        case .syncing: return "正在同步您的思想节点和连接"
        case .success: return "所有更改已成功同步"
        case .error(let message): return message
        }
    }
}

// MARK: - Pro Feature Notice

struct ProFeatureNotice: View {
    @ObservedObject var storeKitService: StoreKitService
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            
            Text("升级到高级版")
                .font(.headline)
            
            Text("实时多设备同步是高级版功能。升级后即可在所有设备上无缝访问您的思想空间。")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                // Navigate to subscription
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("了解高级版")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.1))
        )
    }
}

// MARK: - Active Devices Card

struct ActiveDevicesCard: View {
    let sessions: [SyncSession]
    let onManage: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "laptopcomputer.and.iphone")
                        .foregroundColor(.blue)
                    
                    Text("活跃设备")
                        .font(.headline)
                }
                
                Spacer()
                
                Button("管理") {
                    onManage()
                }
                .font(.caption)
            }
            
            VStack(spacing: 8) {
                ForEach(sessions.prefix(3)) { session in
                    DeviceRow(session: session)
                }
            }
            
            if sessions.count > 3 {
                Text("还有 \(sessions.count - 3) 台设备")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct DeviceRow: View {
    let session: SyncSession
    
    var body: some View {
        HStack {
            Image(systemName: deviceIcon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.deviceName)
                    .font(.callout)
                    .fontWeight(.medium)
                
                Text("最后活动: \(session.lastActivity, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Active indicator
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
    }
    
    private var deviceIcon: String {
        switch session.platform {
        case "iOS": return "iphone"
        case "iPadOS": return "ipad"
        case "macOS": return "laptopcomputer"
        default: return "desktopcomputer"
        }
    }
    
    private var isActive: Bool {
        Date().timeIntervalSince(session.lastActivity) < 300 // 5 minutes
    }
}

// MARK: - Sync Metrics Card

struct SyncMetricsCard: View {
    let metrics: SyncMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("同步统计")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricItem(
                    icon: "doc.on.doc",
                    title: "节点同步",
                    value: "\(metrics.nodesSynced)",
                    color: .blue
                )
                
                MetricItem(
                    icon: "link",
                    title: "连接同步",
                    value: "\(metrics.connectionsSynced)",
                    color: .purple
                )
                
                MetricItem(
                    icon: "checkmark.circle",
                    title: "成功率",
                    value: String(format: "%.1f%%", metrics.successRate * 100),
                    color: .green
                )
                
                MetricItem(
                    icon: "exclamationmark.triangle",
                    title: "冲突解决",
                    value: "\(metrics.conflictsResolved)",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct MetricItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Conflicts Card

struct ConflictsCard: View {
    let conflicts: [ConflictedNode]
    let onResolve: (ConflictedNode) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.2")
                    .foregroundColor(.orange)
                
                Text("同步冲突")
                    .font(.headline)
                
                Spacer()
                
                Text("\(conflicts.count) 个待解决")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(conflicts.prefix(3)) { conflict in
                    ConflictRow(
                        conflict: conflict,
                        onResolve: { onResolve(conflict) }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

struct ConflictRow: View {
    let conflict: ConflictedNode
    let onResolve: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: conflictIcon)
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(conflictTitle)
                    .font(.callout)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("检测时间: \(conflict.detectedAt, style: .relative)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("解决") {
                onResolve()
            }
            .font(.caption)
            .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
    
    private var conflictIcon: String {
        switch conflict.conflictType {
        case .contentMismatch: return "doc.badge.ellipsis"
        case .positionMismatch: return "move.3d"
        case .deletionConflict: return "trash.slash"
        case .connectionConflict: return "link.badge.plus"
        }
    }
    
    private var conflictTitle: String {
        let preview = String(conflict.localVersion.content.prefix(30))
        return preview.isEmpty ? "未命名节点" : preview
    }
}

// MARK: - Sync Controls Card

struct SyncControlsCard: View {
    @ObservedObject var syncService: EnhancedCloudSyncService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("同步设置")
                .font(.headline)
            
            Toggle("自动实时同步", isOn: $syncService.isAutoSyncEnabled)
                .tint(.blue)
            
            if syncService.isAutoSyncEnabled {
                Text("启用后，您的更改将实时同步到所有设备")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            VStack(spacing: 12) {
                ControlButton(
                    icon: "arrow.clockwise",
                    title: "立即同步",
                    description: "手动触发完整同步",
                    action: {
                        Task {
                            await syncService.startRealtimeSync()
                        }
                    }
                )
                
                ControlButton(
                    icon: "xmark.icloud",
                    title: "暂停同步",
                    description: "临时停止云同步服务",
                    destructive: true,
                    action: {
                        syncService.stopRealtimeSync()
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

struct ControlButton: View {
    let icon: String
    let title: String
    let description: String
    var destructive: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(destructive ? .red : .blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(destructive ? .red : .primary)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Conflict Resolution View

struct ConflictResolutionView: View {
    let conflict: ConflictedNode
    @ObservedObject var syncService: EnhancedCloudSyncService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStrategy: ConflictResolutionStrategy = .keepLocal
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Conflict info
                    ConflictInfoCard(conflict: conflict)
                    
                    // Version comparison
                    VersionComparisonCard(conflict: conflict)
                    
                    // Resolution options
                    ResolutionOptionsCard(
                        selectedStrategy: $selectedStrategy,
                        conflict: conflict
                    )
                    
                    // Action buttons
                    HStack(spacing: 12) {
                        Button("取消") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Button("应用") {
                            Task {
                                await syncService.resolveConflict(conflict, strategy: selectedStrategy)
                                dismiss()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("解决冲突")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ConflictInfoCard: View {
    let conflict: ConflictedNode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("检测到同步冲突")
                    .font(.headline)
            }
            
            Text("该节点在多个设备上被修改，需要您选择保留哪个版本。")
                .font(.callout)
                .foregroundColor(.secondary)
            
            Label("检测时间: \(conflict.detectedAt, style: .date) \(conflict.detectedAt, style: .time)", systemImage: "clock")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
    }
}

struct VersionComparisonCard: View {
    let conflict: ConflictedNode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("版本对比")
                .font(.headline)
            
            HStack(spacing: 12) {
                // Local version
                VersionCard(
                    title: "本地版本",
                    icon: "iphone",
                    content: conflict.localVersion.content,
                    timestamp: conflict.localVersion.updatedAt,
                    color: .blue
                )
                
                // Remote version
                VersionCard(
                    title: "云端版本",
                    icon: "icloud",
                    content: conflict.remoteVersion.content,
                    timestamp: conflict.remoteVersion.updatedAt,
                    color: .green
                )
            }
        }
    }
}

struct VersionCard: View {
    let title: String
    let icon: String
    let content: String
    let timestamp: Date
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Text(content)
                .font(.caption)
                .lineLimit(4)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            
            Text("修改时间: \(timestamp, style: .relative)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct ResolutionOptionsCard: View {
    @Binding var selectedStrategy: ConflictResolutionStrategy
    let conflict: ConflictedNode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("解决方案")
                .font(.headline)
            
            VStack(spacing: 8) {
                ResolutionOption(
                    strategy: .keepLocal,
                    title: "保留本地版本",
                    description: "使用此设备上的版本覆盖云端",
                    icon: "iphone",
                    isSelected: selectedStrategy == .keepLocal,
                    onSelect: { selectedStrategy = .keepLocal }
                )
                
                ResolutionOption(
                    strategy: .keepRemote,
                    title: "保留云端版本",
                    description: "使用云端版本覆盖本地",
                    icon: "icloud",
                    isSelected: selectedStrategy == .keepRemote,
                    onSelect: { selectedStrategy = .keepRemote }
                )
                
                ResolutionOption(
                    strategy: .merge,
                    title: "合并两个版本",
                    description: "将两个版本的内容合并到一起",
                    icon: "arrow.triangle.merge",
                    isSelected: selectedStrategy == .merge,
                    onSelect: { selectedStrategy = .merge }
                )
                
                ResolutionOption(
                    strategy: .duplicate,
                    title: "创建副本",
                    description: "保留本地版本并创建云端版本的副本",
                    icon: "doc.on.doc",
                    isSelected: selectedStrategy == .duplicate,
                    onSelect: { selectedStrategy = .duplicate }
                )
            }
        }
    }
}

struct ResolutionOption: View {
    let strategy: ConflictResolutionStrategy
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Device Manager View

struct DeviceManagerView: View {
    @ObservedObject var syncService: EnhancedCloudSyncService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(syncService.activeSyncSessions) { session in
                    DeviceDetailRow(session: session, isCurrentDevice: session.deviceId == getCurrentDeviceId())
                }
            }
            .navigationTitle("设备管理")
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
    
    private func getCurrentDeviceId() -> String {
        UserDefaults.standard.string(forKey: "prismng.deviceId") ?? ""
    }
}

struct DeviceDetailRow: View {
    let session: SyncSession
    let isCurrentDevice: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: deviceIcon)
                    .foregroundColor(.blue)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(session.deviceName)
                            .font(.headline)
                        
                        if isCurrentDevice {
                            Text("当前设备")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(session.platform)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                Label("开始时间: \(session.startedAt, style: .date)", systemImage: "calendar")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label("最后活动: \(session.lastActivity, style: .relative)", systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var deviceIcon: String {
        switch session.platform {
        case "iOS": return "iphone"
        case "iPadOS": return "ipad"
        case "macOS": return "laptopcomputer"
        default: return "desktopcomputer"
        }
    }
}

// MARK: - Sync History View

struct SyncHistoryView: View {
    @ObservedObject var syncService: EnhancedCloudSyncService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Sync chart
                    SyncActivityChart(syncService: syncService)
                    
                    // Recent syncs
                    RecentSyncsSection()
                }
                .padding()
            }
            .navigationTitle("同步历史")
            .navigationBarTitleDisplayMode(.inline)
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

struct SyncActivityChart: View {
    @ObservedObject var syncService: EnhancedCloudSyncService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("同步活动")
                .font(.headline)
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 200)
                .overlay(
                    Text("同步活动图表")
                        .foregroundColor(.secondary)
                )
        }
    }
}

struct RecentSyncsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近同步")
                .font(.headline)
            
            // Placeholder for sync history
            ForEach(0..<5) { index in
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("同步了 \(Int.random(in: 5...50)) 个节点")
                            .font(.callout)
                        
                        Text("\(index * 2 + 1) 小时前")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#Preview {
    CloudSyncView(
        syncService: EnhancedCloudSyncService(
            storeKitService: StoreKitService(),
            creditsService: AICreditsService(
                userId: "preview",
                storeKitService: StoreKitService(),
                quotaService: QuotaManagementService()
            )
        ),
        storeKitService: StoreKitService()
    )
}