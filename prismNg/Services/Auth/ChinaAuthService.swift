//
//  ChinaAuthService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP2-5: China Auth Service - 中国市场登录优化
//

import Foundation
import SwiftUI
import Combine

// MARK: - China Authentication Service

/// 中国市场认证服务，提供手机号验证码和微信登录
@MainActor
class ChinaAuthService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthenticating = false
    @Published var isAuthenticated = false
    @Published var currentUser: ChinaUser?
    @Published var authError: AuthError?
    @Published var verificationCountdown = 0
    @Published var isWeChatInstalled = false
    
    // MARK: - Private Properties
    private let firebaseManager = FirebaseManager.shared
    private var verificationTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    
    // SMS verification
    private var pendingVerificationId: String?
    private let smsCodeLength = 6
    private let verificationTimeout = 60 // seconds
    
    // WeChat OAuth
    private let wechatAppId = "wx_prismng_2025" // Replace with actual WeChat App ID
    private var wechatAuthState: String?
    
    // MARK: - Initialization
    
    init() {
        checkWeChatAvailability()
        loadCachedUser()
    }
    
    // MARK: - Phone Number Authentication
    
    /// 发送短信验证码
    func sendSMSCode(to phoneNumber: String) async throws {
        // Validate phone number
        guard isValidChinesePhoneNumber(phoneNumber) else {
            throw AuthError.invalidPhoneNumber
        }
        
        isAuthenticating = true
        authError = nil
        
        do {
            // Format phone number with country code
            let formattedNumber = "+86" + phoneNumber.replacingOccurrences(of: "+86", with: "")
            
            // Call Firebase Functions to send SMS
            let response = try await sendSMSViaFirebase(phoneNumber: formattedNumber)
            
            pendingVerificationId = response.verificationId
            
            // Start countdown timer
            startVerificationCountdown()
            
            isAuthenticating = false
            
        } catch {
            isAuthenticating = false
            authError = AuthError.smsSendFailed(error.localizedDescription)
            throw authError!
        }
    }
    
    /// 验证短信验证码
    func verifySMSCode(_ code: String, for phoneNumber: String) async throws {
        guard code.count == smsCodeLength else {
            throw AuthError.invalidVerificationCode
        }
        
        guard let verificationId = pendingVerificationId else {
            throw AuthError.noActiveVerification
        }
        
        isAuthenticating = true
        authError = nil
        
        do {
            // Verify code via Firebase
            let credential = PhoneAuthCredential(
                verificationId: verificationId,
                verificationCode: code
            )
            
            let firebaseUser = try await signInWithPhoneCredential(credential)
            
            // Create or update user profile
            let user = ChinaUser(
                id: firebaseUser.uid,
                phoneNumber: phoneNumber,
                displayName: generateDefaultName(from: phoneNumber),
                authType: .phone,
                createdAt: Date()
            )
            
            await updateUserProfile(user)
            
            currentUser = user
            isAuthenticated = true
            isAuthenticating = false
            
            // Clear verification state
            pendingVerificationId = nil
            stopVerificationCountdown()
            
            // Cache user
            cacheUser(user)
            
        } catch {
            isAuthenticating = false
            authError = AuthError.verificationFailed(error.localizedDescription)
            throw authError!
        }
    }
    
    /// 重新发送验证码
    func resendSMSCode(to phoneNumber: String) async throws {
        guard verificationCountdown == 0 else {
            throw AuthError.tooManyRequests
        }
        
        try await sendSMSCode(to: phoneNumber)
    }
    
    // MARK: - WeChat Authentication
    
    /// 微信登录
    func signInWithWeChat() async throws {
        guard isWeChatInstalled else {
            throw AuthError.wechatNotInstalled
        }
        
        isAuthenticating = true
        authError = nil
        
        do {
            // Generate state for security
            wechatAuthState = UUID().uuidString
            
            // Launch WeChat OAuth
            let wechatAuth = try await launchWeChatOAuth(state: wechatAuthState!)
            
            // Exchange WeChat code for Firebase credential
            let firebaseUser = try await exchangeWeChatToken(wechatAuth)
            
            // Create user profile
            let user = ChinaUser(
                id: firebaseUser.uid,
                phoneNumber: nil,
                displayName: wechatAuth.nickname ?? "微信用户",
                authType: .wechat,
                wechatOpenId: wechatAuth.openId,
                wechatUnionId: wechatAuth.unionId,
                avatarUrl: wechatAuth.avatarUrl,
                createdAt: Date()
            )
            
            await updateUserProfile(user)
            
            currentUser = user
            isAuthenticated = true
            isAuthenticating = false
            
            // Cache user
            cacheUser(user)
            
        } catch {
            isAuthenticating = false
            authError = AuthError.wechatAuthFailed(error.localizedDescription)
            throw authError!
        }
    }
    
    /// 处理微信OAuth回调
    func handleWeChatCallback(_ url: URL) async {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value,
              let state = components.queryItems?.first(where: { $0.name == "state" })?.value,
              state == wechatAuthState else {
            authError = AuthError.invalidCallback
            return
        }
        
        // Process WeChat auth code
        do {
            let wechatAuth = WeChatAuthResult(
                code: code,
                openId: "", // Will be fetched from WeChat API
                unionId: nil,
                nickname: nil,
                avatarUrl: nil
            )
            
            let firebaseUser = try await exchangeWeChatToken(wechatAuth)
            
            // Continue with user creation...
        } catch {
            authError = AuthError.wechatAuthFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Account Binding
    
    /// 绑定手机号到现有账户
    func bindPhoneNumber(_ phoneNumber: String, to user: ChinaUser) async throws {
        guard user.phoneNumber == nil else {
            throw AuthError.phoneAlreadyBound
        }
        
        // Send verification code
        try await sendSMSCode(to: phoneNumber)
        
        // After verification, update user profile
        // This would be called after verifySMSCode succeeds
    }
    
    /// 绑定微信到现有账户
    func bindWeChat(to user: ChinaUser) async throws {
        guard user.wechatOpenId == nil else {
            throw AuthError.wechatAlreadyBound
        }
        
        try await signInWithWeChat()
        
        // Update existing user with WeChat info
        // This would merge the accounts
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        do {
            try await firebaseManager.signOut()
            
            currentUser = nil
            isAuthenticated = false
            pendingVerificationId = nil
            
            // Clear cache
            clearCachedUser()
            
        } catch {
            authError = AuthError.signOutFailed(error.localizedDescription)
            throw authError!
        }
    }
    
    // MARK: - Private Methods
    
    private func isValidChinesePhoneNumber(_ phoneNumber: String) -> Bool {
        let cleaned = phoneNumber.replacingOccurrences(of: "+86", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        // Chinese mobile number regex
        let regex = "^1[3-9]\\d{9}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: cleaned)
    }
    
    private func generateDefaultName(from phoneNumber: String) -> String {
        let lastFour = String(phoneNumber.suffix(4))
        return "用户\(lastFour)"
    }
    
    private func startVerificationCountdown() {
        verificationCountdown = verificationTimeout
        
        verificationTimer?.invalidate()
        verificationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if self.verificationCountdown > 0 {
                    self.verificationCountdown -= 1
                } else {
                    self.stopVerificationCountdown()
                }
            }
        }
    }
    
    private func stopVerificationCountdown() {
        verificationTimer?.invalidate()
        verificationTimer = nil
        verificationCountdown = 0
    }
    
    private func checkWeChatAvailability() {
        #if os(iOS)
        if let wechatURL = URL(string: "weixin://") {
            isWeChatInstalled = UIApplication.shared.canOpenURL(wechatURL)
        }
        #else
        isWeChatInstalled = false
        #endif
    }
    
    // MARK: - Firebase Integration
    
    private func sendSMSViaFirebase(phoneNumber: String) async throws -> SMSVerificationResponse {
        // In real implementation, call Firebase Functions
        // For demo, simulate the response
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return SMSVerificationResponse(
            verificationId: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(300)
        )
    }
    
    private func signInWithPhoneCredential(_ credential: PhoneAuthCredential) async throws -> FirebaseUser {
        // In real implementation, use Firebase Auth
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return FirebaseUser(
            uid: UUID().uuidString,
            email: nil,
            displayName: nil
        )
    }
    
    private func launchWeChatOAuth(state: String) async throws -> WeChatAuthResult {
        // In real implementation, launch WeChat SDK
        throw AuthError.wechatNotInstalled
    }
    
    private func exchangeWeChatToken(_ wechatAuth: WeChatAuthResult) async throws -> FirebaseUser {
        // Exchange WeChat token for Firebase credential
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return FirebaseUser(
            uid: UUID().uuidString,
            email: nil,
            displayName: wechatAuth.nickname
        )
    }
    
    private func updateUserProfile(_ user: ChinaUser) async {
        // Update user profile in Firestore
        do {
            try await firebaseManager.saveDocument(
                user,
                to: "users",
                documentId: user.id
            )
        } catch {
            print("Failed to update user profile: \(error)")
        }
    }
    
    // MARK: - Cache Management
    
    private func cacheUser(_ user: ChinaUser) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: "cachedChinaUser")
        }
    }
    
    private func loadCachedUser() {
        guard let data = userDefaults.data(forKey: "cachedChinaUser"),
              let user = try? JSONDecoder().decode(ChinaUser.self, from: data) else {
            return
        }
        
        currentUser = user
        isAuthenticated = true
    }
    
    private func clearCachedUser() {
        userDefaults.removeObject(forKey: "cachedChinaUser")
    }
}

// MARK: - Supporting Types

/// 中国用户模型
struct ChinaUser: Identifiable, Codable {
    let id: String
    var phoneNumber: String?
    var displayName: String
    let authType: AuthType
    var wechatOpenId: String?
    var wechatUnionId: String?
    var avatarUrl: String?
    let createdAt: Date
    var lastLoginAt: Date = Date()
    
    enum AuthType: String, Codable {
        case phone = "phone"
        case wechat = "wechat"
        case both = "both"
    }
    
    var hasPhoneNumber: Bool {
        phoneNumber != nil
    }
    
    var hasWeChat: Bool {
        wechatOpenId != nil
    }
    
    var maskedPhoneNumber: String? {
        guard let phone = phoneNumber else { return nil }
        let cleaned = phone.replacingOccurrences(of: "+86", with: "")
        guard cleaned.count >= 11 else { return phone }
        
        let prefix = String(cleaned.prefix(3))
        let suffix = String(cleaned.suffix(4))
        return "\(prefix)****\(suffix)"
    }
}

/// 手机验证凭证
struct PhoneAuthCredential {
    let verificationId: String
    let verificationCode: String
}

/// 短信验证响应
struct SMSVerificationResponse {
    let verificationId: String
    let expiresAt: Date
}

/// 微信认证结果
struct WeChatAuthResult {
    let code: String
    let openId: String
    let unionId: String?
    let nickname: String?
    let avatarUrl: String?
}

/// 认证错误
enum AuthError: LocalizedError {
    case invalidPhoneNumber
    case smsSendFailed(String)
    case invalidVerificationCode
    case noActiveVerification
    case verificationFailed(String)
    case tooManyRequests
    case wechatNotInstalled
    case wechatAuthFailed(String)
    case invalidCallback
    case phoneAlreadyBound
    case wechatAlreadyBound
    case signOutFailed(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "请输入有效的手机号码"
        case .smsSendFailed(let message):
            return "发送验证码失败: \(message)"
        case .invalidVerificationCode:
            return "验证码格式错误"
        case .noActiveVerification:
            return "请先获取验证码"
        case .verificationFailed(let message):
            return "验证失败: \(message)"
        case .tooManyRequests:
            return "请求过于频繁，请稍后再试"
        case .wechatNotInstalled:
            return "请先安装微信"
        case .wechatAuthFailed(let message):
            return "微信登录失败: \(message)"
        case .invalidCallback:
            return "无效的回调参数"
        case .phoneAlreadyBound:
            return "该账号已绑定手机号"
        case .wechatAlreadyBound:
            return "该账号已绑定微信"
        case .signOutFailed(let message):
            return "退出登录失败: \(message)"
        case .networkError:
            return "网络连接错误"
        }
    }
}

// MARK: - WeChat SDK Integration

/// 微信SDK管理器（简化版）
class WeChatSDKManager {
    static let shared = WeChatSDKManager()
    
    private init() {}
    
    func registerApp(_ appId: String) {
        // Register with WeChat SDK
        print("Registering WeChat App: \(appId)")
    }
    
    func handleOpenURL(_ url: URL) -> Bool {
        // Handle WeChat callback
        return url.scheme?.hasPrefix("wx") ?? false
    }
    
    func sendAuthRequest(scope: String, state: String) {
        // Send auth request to WeChat
        print("Sending WeChat auth request with state: \(state)")
    }
}