import SwiftUI
import Combine

struct SyncStatusView: View {
    @ObservedObject var syncService: FirebaseSyncService
    @State private var showDetails = false
    
    private var statusIcon: String {
        switch syncService.syncStatus {
        case .idle:
            return "icloud"
        case .syncing:
            return "arrow.triangle.2.circlepath"
        case .error(_):
            return "exclamationmark.icloud"
        case .success:
            return "checkmark.icloud"
        }
    }
    
    private var statusColor: Color {
        switch syncService.syncStatus {
        case .idle:
            return .green
        case .syncing:
            return .blue
        case .error(_):
            return .red
        case .success:
            return .green
        }
    }
    
    var body: some View {
        Button {
            showDetails.toggle()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.caption)
                    .rotationEffect(.degrees(syncService.syncStatus == .syncing ? 360 : 0))
                    .animation(
                        syncService.syncStatus == .syncing ? 
                        Animation.linear(duration: 2).repeatForever(autoreverses: false) : 
                        .default,
                        value: syncService.syncStatus
                    )
                
                if syncService.syncStatus == .syncing {
                    Text("Syncing...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .popover(isPresented: $showDetails) {
            SyncDetailsView(syncService: syncService)
                .frame(width: 250)
        }
    }
}

struct SyncDetailsView: View {
    @ObservedObject var syncService: FirebaseSyncService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "icloud.and.arrow.up.fill")
                    .foregroundColor(.blue)
                Text("Cloud Sync")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Status", systemImage: "circle.fill")
                    .foregroundColor(syncStatusColor)
                    .font(.caption)
                
                Text(syncStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let lastSync = syncService.lastSyncDate {
                    Label("Last sync: \(lastSync.formatted(.relative(presentation: .numeric)))", 
                          systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if case .error(let errorMessage) = syncService.syncStatus {
                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Divider()
            
            Button("Sync Now") {
                Task {
                    await syncService.performSync()
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(syncService.syncStatus == .syncing)
        }
        .padding()
    }
    
    private var syncStatusColor: Color {
        switch syncService.syncStatus {
        case .idle: return .green
        case .syncing: return .blue
        case .error(_): return .red
        case .success: return .green
        }
    }
    
    private var syncStatusText: String {
        switch syncService.syncStatus {
        case .idle: return "All data synced"
        case .syncing: return "Syncing in progress..."
        case .error(let message): return "Sync error: \(message)"
        case .success: return "Sync completed successfully"
        }
    }
}

#Preview {
    HStack {
        SyncStatusView(syncService: FirebaseSyncService())
            .padding()
        
        SyncStatusView(syncService: {
            let service = FirebaseSyncService()
            service.syncStatus = .syncing
            return service
        }())
        .padding()
        
        SyncStatusView(syncService: {
            let service = FirebaseSyncService()
            service.syncStatus = .error("Network connection failed")
            // Note: lastSyncError is not directly settable in preview
            return service
        }())
        .padding()
    }
}