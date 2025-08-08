//
//  CloudSyncManager.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import Combine
import SwiftData

// MARK: - Cloud Provider
enum CloudProvider {
    case iCloud
    case firebase
    case both
    case none
}

// MARK: - Cloud Sync Manager
@MainActor
class CloudSyncManager: ObservableObject {
    @Published var selectedProvider: CloudProvider = .none
    @Published var isSyncing = false
    @Published var lastSyncError: Error?
    @Published var syncProgress: Double = 0.0
    
    // Services - lazy and optional to avoid initialization issues
    private var _iCloudService: iCloudSyncService?
    private var _firebaseService: FirebaseSyncService?
    
    var iCloudService: iCloudSyncService {
        if _iCloudService == nil {
            _iCloudService = iCloudSyncService()
        }
        return _iCloudService!
    }
    
    var firebaseService: FirebaseSyncService {
        if _firebaseService == nil {
            _firebaseService = FirebaseSyncService()
        }
        return _firebaseService!
    }
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Delay service initialization
        Task { @MainActor in
            setupObservers()
            loadSelectedProvider()
        }
    }
    
    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Provider Selection
    
    func updateProvider(_ provider: CloudProvider) {
        selectedProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: "selectedCloudProvider")
        
        // Start initial sync if needed
        if provider != .none {
            Task {
                await performFullSync()
            }
        }
    }

    private func loadSelectedProvider() {
        if let raw = UserDefaults.standard.string(forKey: "selectedCloudProvider"),
           let provider = CloudProvider(rawValue: raw) {
            selectedProvider = provider
        }
    }
    
    // MARK: - Sync Operations
    
    func syncNode(_ node: ThoughtNode) async {
        guard selectedProvider != .none else { return }
        
        var hasError = false
        
        if shouldSyncToiCloud {
            do {
                try await iCloudService.syncNode(node)
            } catch {
                lastSyncError = error
                hasError = true
            }
        }
        
        if shouldSyncToFirebase {
            do {
                try await firebaseService.syncNode(node)
            } catch {
                lastSyncError = error
                hasError = true
            }
        }
        
        if !hasError {
            lastSyncError = nil
        }
    }
    
    func performFullSync() async {
        guard selectedProvider != .none else { return }
        guard let modelContext = modelContext else { return }
        
        isSyncing = true
        syncProgress = 0.0
        
        do {
            // Fetch all local nodes
            let descriptor = FetchDescriptor<ThoughtNode>()
            let localNodes = try modelContext.fetch(descriptor)
            
            // Sync based on provider
            if shouldSyncToiCloud {
                await synciCloudNodes(localNodes)
            }
            
            if shouldSyncToFirebase {
                await syncFirebaseNodes(localNodes)
            }
            
            lastSyncError = nil
        } catch {
            lastSyncError = error
        }
        
        isSyncing = false
        syncProgress = 1.0
    }
    
    // MARK: - Private Sync Methods
    
    private func synciCloudNodes(_ nodes: [ThoughtNode]) async {
        let totalNodes = nodes.count
        var completed = 0
        
        // First, fetch remote nodes for comparison
        do {
            let remoteNodes = try await iCloudService.fetchThoughtNodes()
            let remoteNodeIds = Set(remoteNodes.map { $0.id })
            
            // Upload new or updated nodes
            for node in nodes {
                if !remoteNodeIds.contains(node.id) {
                    try await iCloudService.syncNode(node)
                }
                completed += 1
                syncProgress = Double(completed) / Double(totalNodes * 2)
            }
            
            // Download new nodes from remote
            for remoteNode in remoteNodes {
                if !nodes.contains(where: { $0.id == remoteNode.id }) {
                    modelContext?.insert(remoteNode)
                }
                completed += 1
                syncProgress = Double(completed) / Double(totalNodes * 2)
            }
            
            try? modelContext?.save()
        } catch {
            print("iCloud sync error: \(error)")
        }
    }
    
    private func syncFirebaseNodes(_ nodes: [ThoughtNode]) async {
        // Similar implementation for Firebase
        // For now, just sync individual nodes
        let totalNodes = nodes.count
        var completed = 0
        
        for node in nodes {
            do {
                try await firebaseService.syncNode(node)
                completed += 1
                syncProgress = Double(completed) / Double(totalNodes)
            } catch {
                print("Firebase sync error for node \(node.id): \(error)")
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var shouldSyncToiCloud: Bool {
        selectedProvider == .iCloud || selectedProvider == .both
    }
    
    private var shouldSyncToFirebase: Bool {
        selectedProvider == .firebase || selectedProvider == .both
    }
    
    // MARK: - Observers
    
    private func setupObservers() {
        // Safely setup observers with error handling
        if let iCloud = _iCloudService {
            // Observe iCloud availability
            _ = iCloud // placeholder: concrete availability publisher belongs to impl
        }
        
        if let firebase = _firebaseService {
            // Observe Firebase authentication
            _ = firebase // placeholder: concrete auth publisher belongs to impl
        }
    }
}

// MARK: - CloudProvider Extension
extension CloudProvider: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "iCloud": self = .iCloud
        case "firebase": self = .firebase
        case "both": self = .both
        case "none": self = .none
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .iCloud: return "iCloud"
        case .firebase: return "firebase"
        case .both: return "both"
        case .none: return "none"
        }
    }
}

// MARK: - Cloud Sync Settings View
struct CloudSyncSettingsView: View {
    @ObservedObject var syncManager: CloudSyncManager
    @State private var showingSignIn = false
    
    var body: some View {
        Section("云同步设置") {
            Picker("同步服务", selection: $syncManager.selectedProvider) {
                Text("关闭").tag(CloudProvider.none)
                if syncManager.iCloudService.iCloudAvailable {
                    Text("iCloud").tag(CloudProvider.iCloud)
                }
                if syncManager.firebaseService.isAuthenticated {
                    Text("Firebase").tag(CloudProvider.firebase)
                }
                if syncManager.iCloudService.iCloudAvailable && syncManager.firebaseService.isAuthenticated {
                    Text("全部").tag(CloudProvider.both)
                }
            }
            .onChange(of: syncManager.selectedProvider) { _, newValue in
                syncManager.updateProvider(newValue)
            }
            
            // Firebase Sign In
            if !syncManager.firebaseService.isAuthenticated {
                Button {
                    showingSignIn = true
                } label: {
                    Label("登录 Firebase", systemImage: "person.crop.circle.badge.plus")
                }
            } else {
                HStack {
                    Label("已登录", systemImage: "person.crop.circle.badge.checkmark")
                        .foregroundColor(.green)
                    Spacer()
                    Button("退出") {
                        Task {
                            try? await syncManager.firebaseService.signOut()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            
            // Sync Status
            if syncManager.isSyncing {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("正在同步...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(syncManager.syncProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let error = syncManager.lastSyncError {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Manual Sync Button
            if syncManager.selectedProvider != .none && !syncManager.isSyncing {
                Button {
                    Task {
                        await syncManager.performFullSync()
                    }
                } label: {
                    Label("立即同步", systemImage: "arrow.triangle.2.circlepath")
                }
            }
        }
        .sheet(isPresented: $showingSignIn) {
            FirebaseSignInView(syncService: syncManager.firebaseService)
        }
    }
}

// MARK: - Firebase Sign In View
struct FirebaseSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var syncService: FirebaseSyncService
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("登录信息") {
                    TextField("邮箱", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("密码", text: $password)
                        .textContentType(.password)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button {
                        Task {
                            await signIn()
                        }
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("登录")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                    
                    Button {
                        Task {
                            await signInWithApple()
                        }
                    } label: {
                        Label("使用 Apple 登录", systemImage: "applelogo")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .navigationTitle("登录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signIn() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await syncService.signIn(with: email, password: password)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func signInWithApple() async {
        // Note: Apple Sign-In needs to be implemented with SignInWithAppleButton
        // This is a placeholder - real implementation would use ASAuthorizationController
        errorMessage = "Apple Sign-In requires UI implementation"
        
        // In a real implementation:
        // 1. Use SignInWithAppleButton from AuthenticationServices
        // 2. Handle the authorization in onRequest and onCompletion
        // 3. Pass the ASAuthorization to syncService.signInWithApple(authorization:)
    }
}
