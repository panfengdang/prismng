//
//  UnifiedAuthView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP2-5: Unified Auth View - 统一认证界面
//

import SwiftUI
import CoreLocation

// MARK: - Unified Auth View

/// 统一认证界面，根据地区自动切换登录方式
struct UnifiedAuthView: View {
    @StateObject private var authManager = UnifiedAuthManager()
    @StateObject private var chinaAuth = ChinaAuthService()
    @ObservedObject var firebaseManager: FirebaseManager
    @State private var showingRegionPicker = false
    @State private var isDetectingRegion = true
    
    var body: some View {
        Group {
            if isDetectingRegion {
                RegionDetectionView()
            } else {
                switch authManager.selectedRegion {
                case .china:
                    ChinaLoginView(authService: chinaAuth)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                case .global:
                    GlobalLoginView(firebaseManager: firebaseManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                case .auto:
                    EmptyView()
                }
            }
        }
        .animation(.easeInOut, value: authManager.selectedRegion)
        .overlay(alignment: .topTrailing) {
            if !isDetectingRegion {
                RegionSwitchButton(
                    currentRegion: authManager.selectedRegion,
                    onTap: { showingRegionPicker = true }
                )
                .padding()
            }
        }
        .sheet(isPresented: $showingRegionPicker) {
            RegionPickerView(
                selectedRegion: $authManager.selectedRegion,
                onConfirm: {
                    showingRegionPicker = false
                    authManager.saveRegionPreference()
                }
            )
        }
        .onAppear {
            detectRegion()
        }
    }
    
    private func detectRegion() {
        Task {
            await authManager.detectRegion()
            
            await MainActor.run {
                withAnimation {
                    isDetectingRegion = false
                }
            }
        }
    }
}

// MARK: - Region Detection View

struct RegionDetectionView: View {
    @State private var animationProgress = 0.0
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated globe
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "globe.asia.australia.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(animationProgress * 360))
                    .onAppear {
                        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                            animationProgress = 1
                        }
                    }
            }
            
            Text("正在检测您的地区...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("我们将为您提供最适合的登录方式")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Region Switch Button

struct RegionSwitchButton: View {
    let currentRegion: AuthRegion
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: currentRegion.icon)
                Text(currentRegion.shortName)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(.systemGray5))
            )
            .overlay(
                Capsule()
                    .stroke(Color(.systemGray3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Region Picker View

struct RegionPickerView: View {
    @Binding var selectedRegion: AuthRegion
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("选择您的地区")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                Text("不同地区提供不同的登录方式")
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 16) {
                    ForEach([AuthRegion.china, AuthRegion.global], id: \.self) { region in
                        RegionCard(
                            region: region,
                            isSelected: selectedRegion == region,
                            onTap: { selectedRegion = region }
                        )
                    }
                }
                .padding(.top, 30)
                
                Spacer()
                
                Button {
                    onConfirm()
                } label: {
                    Text("确认")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                Button("自动检测") {
                    selectedRegion = .auto
                    onConfirm()
                }
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.bottom)
            }
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
}

struct RegionCard: View {
    let region: AuthRegion
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                Image(systemName: region.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                VStack(spacing: 4) {
                    Text(region.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(region.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Available login methods
                HStack(spacing: 12) {
                    ForEach(region.availableMethods, id: \.self) { method in
                        LoginMethodChip(method: method)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct LoginMethodChip: View {
    let method: LoginMethod
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: method.icon)
                .font(.caption2)
            Text(method.name)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(method.color.opacity(0.2))
        )
        .foregroundColor(method.color)
    }
}

// MARK: - Global Login View

struct GlobalLoginView: View {
    @ObservedObject var firebaseManager: FirebaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showingAppleSignIn = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, 60)
                    
                    Text("Welcome to Prism")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Email/Password fields
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedTextFieldStyle())
                            .textContentType(isSignUp ? .newPassword : .password)
                    }
                    .padding(.horizontal)
                    
                    // Sign in/up button
                    Button {
                        Task {
                            if isSignUp {
                                // Sign up
                            } else {
                                try? await firebaseManager.signIn(withEmail: email, password: password)
                            }
                        }
                    } label: {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    
                    // Toggle sign in/up
                    Button {
                        isSignUp.toggle()
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.callout)
                            .foregroundColor(.blue)
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    
                    // Social login
                    VStack(spacing: 12) {
                        // Apple Sign In
                        Button {
                            showingAppleSignIn = true
                        } label: {
                            HStack {
                                Image(systemName: "applelogo")
                                Text("Sign in with Apple")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        // Google Sign In
                        Button {
                            // Google sign in
                        } label: {
                            HStack {
                                Image(systemName: "g.circle")
                                Text("Sign in with Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Rounded Text Field Style

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
    }
}

// MARK: - Unified Auth Manager

@MainActor
class UnifiedAuthManager: ObservableObject {
    @Published var selectedRegion: AuthRegion = .auto
    @Published var isInChina = false
    
    private let locationManager = CLLocationManager()
    
    func detectRegion() async {
        // Check saved preference first
        if let savedRegion = loadSavedRegion() {
            selectedRegion = savedRegion
            return
        }
        
        // Auto-detect based on various factors
        isInChina = await detectChinaRegion()
        selectedRegion = isInChina ? .china : .global
    }
    
    private func detectChinaRegion() async -> Bool {
        // Method 1: Check locale
        let locale = Locale.current
        if locale.regionCode == "CN" {
            return true
        }
        
        // Method 2: Check timezone
        let timezone = TimeZone.current
        if timezone.identifier.contains("Asia/Shanghai") || 
           timezone.identifier.contains("Asia/Chongqing") {
            return true
        }
        
        // Method 3: Check carrier (would need CoreTelephony)
        // Method 4: Check IP location (would need network request)
        
        return false
    }
    
    func saveRegionPreference() {
        UserDefaults.standard.set(selectedRegion.rawValue, forKey: "selectedAuthRegion")
    }
    
    private func loadSavedRegion() -> AuthRegion? {
        guard let rawValue = UserDefaults.standard.string(forKey: "selectedAuthRegion"),
              let region = AuthRegion(rawValue: rawValue) else {
            return nil
        }
        return region
    }
}

// MARK: - Auth Region

enum AuthRegion: String, CaseIterable {
    case china = "china"
    case global = "global"
    case auto = "auto"
    
    var displayName: String {
        switch self {
        case .china: return "中国大陆"
        case .global: return "Global"
        case .auto: return "自动检测"
        }
    }
    
    var shortName: String {
        switch self {
        case .china: return "CN"
        case .global: return "Global"
        case .auto: return "Auto"
        }
    }
    
    var icon: String {
        switch self {
        case .china: return "flag"
        case .global: return "globe"
        case .auto: return "location"
        }
    }
    
    var description: String {
        switch self {
        case .china: return "使用手机号和微信登录"
        case .global: return "Use email and social login"
        case .auto: return "根据您的位置自动选择"
        }
    }
    
    var availableMethods: [LoginMethod] {
        switch self {
        case .china:
            return [.phone, .wechat]
        case .global:
            return [.email, .apple, .google]
        case .auto:
            return []
        }
    }
}

// MARK: - Login Method

enum LoginMethod: String {
    case phone = "phone"
    case wechat = "wechat"
    case email = "email"
    case apple = "apple"
    case google = "google"
    
    var name: String {
        switch self {
        case .phone: return "手机号"
        case .wechat: return "微信"
        case .email: return "Email"
        case .apple: return "Apple"
        case .google: return "Google"
        }
    }
    
    var icon: String {
        switch self {
        case .phone: return "phone"
        case .wechat: return "message.fill"
        case .email: return "envelope"
        case .apple: return "applelogo"
        case .google: return "g.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .phone: return .blue
        case .wechat: return .green
        case .email: return .purple
        case .apple: return .black
        case .google: return .red
        }
    }
}

#Preview {
    UnifiedAuthView(firebaseManager: FirebaseManager.shared)
}