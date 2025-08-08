//
//  ChinaLoginView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//  MVP2-5: China Login View - 中国市场登录界面
//

import SwiftUI

// MARK: - China Login View

/// 中国市场登录主界面
struct ChinaLoginView: View {
    @ObservedObject var authService: ChinaAuthService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var showingTerms = false
    @State private var agreedToTerms = false
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and welcome
                        WelcomeHeader()
                        
                        // Login tabs
                        LoginTabSelector(selectedTab: $selectedTab)
                        
                        // Login content
                        if selectedTab == 0 {
                            PhoneLoginView(
                                authService: authService,
                                phoneNumber: $phoneNumber,
                                verificationCode: $verificationCode,
                                agreedToTerms: $agreedToTerms
                            )
                        } else {
                            WeChatLoginView(
                                authService: authService,
                                agreedToTerms: $agreedToTerms
                            )
                        }
                        
                        // Terms and privacy
                        TermsAndPrivacyView(
                            agreedToTerms: $agreedToTerms,
                            onTermsTap: { showingTerms = true }
                        )
                        
                        // Alternative login options
                        AlternativeLoginOptions()
                    }
                    .padding()
                    .padding(.bottom, keyboardHeight)
                }
                .animation(.easeOut(duration: 0.3), value: keyboardHeight)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("跳过") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .alert("登录失败", isPresented: .constant(authService.authError != nil)) {
                Button("确定") {
                    authService.authError = nil
                }
            } message: {
                Text(authService.authError?.errorDescription ?? "")
            }
            .sheet(isPresented: $showingTerms) {
                TermsAndPrivacySheet()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
        }
    }
}

// MARK: - Welcome Header

struct WelcomeHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse)
            
            Text("欢迎使用 Prism")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("您的第二大脑，思想的伙伴")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
}

// MARK: - Login Tab Selector

struct LoginTabSelector: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "手机号登录",
                icon: "iphone",
                isSelected: selectedTab == 0,
                onTap: { selectedTab = 0 }
            )
            
            TabButton(
                title: "微信登录",
                icon: "message.fill",
                isSelected: selectedTab == 1,
                onTap: { selectedTab = 1 }
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.callout)
            .fontWeight(isSelected ? .semibold : .regular)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Phone Login View

struct PhoneLoginView: View {
    @ObservedObject var authService: ChinaAuthService
    @Binding var phoneNumber: String
    @Binding var verificationCode: String
    @Binding var agreedToTerms: Bool
    @FocusState private var focusedField: Field?
    @State private var showingVerificationField = false
    
    enum Field {
        case phone, code
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Phone number input
            VStack(alignment: .leading, spacing: 8) {
                Text("手机号码")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("+86")
                        .foregroundColor(.secondary)
                    
                    TextField("请输入手机号码", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .textFieldStyle(PlainTextFieldStyle())
                        .focused($focusedField, equals: .phone)
                        .onChange(of: phoneNumber) { newValue in
                            // Remove non-numeric characters
                            phoneNumber = newValue.filter { $0.isNumber }
                        }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .phone ? Color.blue : Color.clear, lineWidth: 2)
                        )
                )
            }
            
            // Verification code input
            if showingVerificationField {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("验证码")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if authService.verificationCountdown > 0 {
                            Text("\(authService.verificationCountdown)秒后重新发送")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Button("重新发送") {
                                Task {
                                    try? await authService.resendSMSCode(to: phoneNumber)
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    HStack {
                        ForEach(0..<6) { index in
                            VerificationCodeDigit(
                                digit: getDigit(at: index),
                                isActive: index == verificationCode.count,
                                isFilled: index < verificationCode.count
                            )
                        }
                    }
                    .onTapGesture {
                        focusedField = .code
                    }
                    
                    // Hidden text field for input
                    TextField("", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .code)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .onChange(of: verificationCode) { newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                verificationCode = String(newValue.prefix(6))
                            }
                            
                            // Auto-submit when complete
                            if verificationCode.count == 6 {
                                submitVerificationCode()
                            }
                        }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Action button
            Button {
                if showingVerificationField {
                    submitVerificationCode()
                } else {
                    sendVerificationCode()
                }
            } label: {
                HStack {
                    if authService.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(showingVerificationField ? "登录" : "获取验证码")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isButtonEnabled ? Color.blue : Color.gray)
                )
                .foregroundColor(.white)
            }
            .disabled(!isButtonEnabled || authService.isAuthenticating)
        }
        .animation(.easeInOut, value: showingVerificationField)
    }
    
    private var isButtonEnabled: Bool {
        if showingVerificationField {
            return phoneNumber.count == 11 && verificationCode.count == 6 && agreedToTerms
        } else {
            return phoneNumber.count == 11 && agreedToTerms
        }
    }
    
    private func getDigit(at index: Int) -> String {
        guard index < verificationCode.count else { return "" }
        let digit = verificationCode[verificationCode.index(verificationCode.startIndex, offsetBy: index)]
        return String(digit)
    }
    
    private func sendVerificationCode() {
        Task {
            do {
                try await authService.sendSMSCode(to: phoneNumber)
                withAnimation {
                    showingVerificationField = true
                }
                focusedField = .code
            } catch {
                // Error handled by authService
            }
        }
    }
    
    private func submitVerificationCode() {
        Task {
            do {
                try await authService.verifySMSCode(verificationCode, for: phoneNumber)
            } catch {
                // Error handled by authService
            }
        }
    }
}

struct VerificationCodeDigit: View {
    let digit: String
    let isActive: Bool
    let isFilled: Bool
    
    var body: some View {
        Text(digit)
            .font(.title2)
            .fontWeight(.semibold)
            .frame(width: 45, height: 55)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isActive ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
            .scaleEffect(isFilled ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFilled)
    }
}

// MARK: - WeChat Login View

struct WeChatLoginView: View {
    @ObservedObject var authService: ChinaAuthService
    @Binding var agreedToTerms: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            // WeChat icon
            Image(systemName: "message.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding()
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.1))
                )
            
            Text("使用微信快速登录")
                .font(.headline)
            
            Text("将跳转到微信进行授权登录")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // WeChat login button
            Button {
                Task {
                    try? await authService.signInWithWeChat()
                }
            } label: {
                HStack {
                    if authService.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "message.fill")
                        Text("微信登录")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(authService.isWeChatInstalled && agreedToTerms ? Color.green : Color.gray)
                )
                .foregroundColor(.white)
            }
            .disabled(!authService.isWeChatInstalled || !agreedToTerms || authService.isAuthenticating)
            
            if !authService.isWeChatInstalled {
                Label("请先安装微信客户端", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Terms and Privacy

struct TermsAndPrivacyView: View {
    @Binding var agreedToTerms: Bool
    let onTermsTap: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            Button {
                agreedToTerms.toggle()
            } label: {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreedToTerms ? .blue : .secondary)
            }
            
            Text("我已阅读并同意")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("《用户协议》") {
                onTermsTap()
            }
            .font(.caption)
            
            Text("和")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("《隐私政策》") {
                onTermsTap()
            }
            .font(.caption)
        }
    }
}

// MARK: - Alternative Login Options

struct AlternativeLoginOptions: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
                
                Text("其他登录方式")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            HStack(spacing: 30) {
                AlternativeLoginButton(
                    icon: "applelogo",
                    title: "Apple",
                    action: { }
                )
                
                AlternativeLoginButton(
                    icon: "envelope",
                    title: "邮箱",
                    action: { }
                )
            }
        }
        .padding(.top, 20)
    }
}

struct AlternativeLoginButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(Color(.systemGray6))
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Terms Sheet

struct TermsAndPrivacySheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("用户协议")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("""
                    欢迎使用 Prism！
                    
                    本协议是您与 Prism 之间关于使用 Prism 产品和服务的法律协议。请您仔细阅读本协议的全部内容。
                    
                    1. 服务内容
                    Prism 是一款基于人工智能的思维辅助工具，旨在帮助用户更好地记录、组织和发展自己的想法。
                    
                    2. 用户责任
                    - 您应当对自己的账号和密码安全负责
                    - 您创建的内容应当符合相关法律法规
                    - 不得利用本服务进行任何违法或不当行为
                    
                    3. 隐私保护
                    我们高度重视用户隐私保护，具体请参见《隐私政策》。
                    
                    4. 知识产权
                    您在 Prism 中创建的内容归您所有，但您授予我们使用这些内容来提供和改进服务的许可。
                    
                    5. 服务变更
                    我们可能会不时更新服务内容和本协议条款。
                    """)
                    .font(.body)
                    
                    Divider()
                    
                    Text("隐私政策")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("""
                    我们承诺保护您的隐私：
                    
                    1. 信息收集
                    - 账号信息：手机号、微信授权信息
                    - 使用数据：您创建的节点、连接等内容
                    - 设备信息：用于改善服务体验
                    
                    2. 信息使用
                    - 提供基础服务功能
                    - 个性化推荐和AI辅助
                    - 服务改进和问题诊断
                    
                    3. 信息保护
                    - 采用行业标准的加密技术
                    - 严格的访问控制
                    - 定期安全审计
                    
                    4. 信息共享
                    - 未经您同意，我们不会向第三方共享您的个人信息
                    - 法律要求除外
                    
                    5. 您的权利
                    - 访问和更正您的信息
                    - 删除账号和相关数据
                    - 导出您的数据
                    """)
                    .font(.body)
                }
                .padding()
            }
            .navigationTitle("条款与隐私")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Account Management View

/// 账号管理界面
struct AccountManagementView: View {
    @ObservedObject var authService: ChinaAuthService
    @State private var showingBindPhone = false
    @State private var showingBindWeChat = false
    @State private var showingDeleteAccount = false
    
    var body: some View {
        NavigationView {
            Form {
                // User info section
                Section("账号信息") {
                    if let user = authService.currentUser {
                        HStack {
                            if let avatarUrl = user.avatarUrl {
                                AsyncImage(url: URL(string: avatarUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                
                                if let phone = user.maskedPhoneNumber {
                                    Label(phone, systemImage: "phone")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if user.hasWeChat {
                                    Label("已绑定微信", systemImage: "message.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Account binding section
                Section("账号绑定") {
                    if let user = authService.currentUser {
                        if !user.hasPhoneNumber {
                            Button {
                                showingBindPhone = true
                            } label: {
                                HStack {
                                    Label("绑定手机号", systemImage: "phone.badge.plus")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if !user.hasWeChat {
                            Button {
                                showingBindWeChat = true
                            } label: {
                                HStack {
                                    Label("绑定微信", systemImage: "message.badge.plus")
                                        .foregroundColor(.green)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                
                // Security section
                Section("安全设置") {
                    NavigationLink(destination: EmptyView()) {
                        Label("修改密码", systemImage: "lock")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("登录设备管理", systemImage: "laptopcomputer.and.iphone")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("隐私设置", systemImage: "hand.raised")
                    }
                }
                
                // Sign out
                Section {
                    Button {
                        Task {
                            try? await authService.signOut()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("退出登录")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
                
                // Delete account
                Section {
                    Button {
                        showingDeleteAccount = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("注销账号")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("账号管理")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingBindPhone) {
                // Phone binding view
                Text("绑定手机号")
            }
            .sheet(isPresented: $showingBindWeChat) {
                // WeChat binding view
                Text("绑定微信")
            }
            .alert("注销账号", isPresented: $showingDeleteAccount) {
                Button("取消", role: .cancel) { }
                Button("确认注销", role: .destructive) {
                    // Delete account
                }
            } message: {
                Text("注销账号后，您的所有数据将被永久删除且无法恢复。")
            }
        }
    }
}

#Preview {
    ChinaLoginView(authService: ChinaAuthService())
}