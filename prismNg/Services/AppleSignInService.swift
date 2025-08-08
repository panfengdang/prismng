//
//  AppleSignInService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import AuthenticationServices
import Combine

// MARK: - Apple Sign-In Service
@MainActor
class AppleSignInService: NSObject, ObservableObject {
    @Published var isSignedIn = false
    @Published var userDisplayName: String?
    @Published var userEmail: String?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private let firebaseManager = FirebaseManager.shared
    
    // MARK: - Sign In Methods
    
    func signInWithApple() {
        isLoading = true
        errorMessage = nil
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func signOut() async {
        do {
            try await firebaseManager.signOut()
            isSignedIn = false
            userDisplayName = nil
            userEmail = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Credential Status Check
    
    func checkSignInStatus() {
        guard let userID = getCurrentUserID() else {
            isSignedIn = false
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { [weak self] credentialState, error in
            DispatchQueue.main.async {
                switch credentialState {
                case .authorized:
                    self?.isSignedIn = true
                case .revoked, .notFound:
                    self?.isSignedIn = false
                    self?.clearUserData()
                default:
                    self?.isSignedIn = false
                }
            }
        }
    }
    
    private func getCurrentUserID() -> String? {
        return UserDefaults.standard.string(forKey: "AppleSignInUserID")
    }
    
    private func saveUserID(_ userID: String) {
        UserDefaults.standard.set(userID, forKey: "AppleSignInUserID")
    }
    
    private func clearUserData() {
        UserDefaults.standard.removeObject(forKey: "AppleSignInUserID")
        userDisplayName = nil
        userEmail = nil
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            handleAppleIDCredential(appleIDCredential, authorization: authorization)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
        print("Apple Sign-In failed: \(error)")
    }
    
    private func handleAppleIDCredential(_ credential: ASAuthorizationAppleIDCredential, authorization: ASAuthorization) {
        let userID = credential.user
        let email = credential.email
        let fullName = credential.fullName
        
        // Save user information
        saveUserID(userID)
        
        if let email = email {
            userEmail = email
        }
        
        if let fullName = fullName {
            let displayName = PersonNameComponentsFormatter().string(from: fullName)
            userDisplayName = displayName
        }
        
        // Create Firebase-compatible credential
        let firebaseCredential = AppleSignInCredential(
            userIdentifier: userID,
            email: email,
            fullName: userDisplayName,
            identityToken: credential.identityToken,
            authorizationCode: credential.authorizationCode
        )
        
        // Sign in with Firebase
        Task {
            do {
                let firebaseUser = try await firebaseManager.signInWithApple(authorization: authorization)
                
                await MainActor.run {
                    self.isSignedIn = true
                    self.isLoading = false
                    
                    // Update user info if not already set
                    if self.userEmail == nil {
                        self.userEmail = firebaseUser.email
                    }
                    if self.userDisplayName == nil {
                        self.userDisplayName = firebaseUser.displayName
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Apple Sign-In Button View
struct AppleSignInButton: View {
    @ObservedObject var appleSignInService: AppleSignInService
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    
    init(
        appleSignInService: AppleSignInService,
        type: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        style: ASAuthorizationAppleIDButton.Style = .black
    ) {
        self.appleSignInService = appleSignInService
        self.type = type
        self.style = style
    }
    
    var body: some View {
        AppleSignInButtonRepresentable(
            type: type,
            style: style
        ) {
            appleSignInService.signInWithApple()
        }
        .frame(height: 50)
        .disabled(appleSignInService.isLoading)
        .opacity(appleSignInService.isLoading ? 0.6 : 1.0)
    }
}

// MARK: - UIViewRepresentable for Apple Sign-In Button
struct AppleSignInButtonRepresentable: UIViewRepresentable {
    let type: ASAuthorizationAppleIDButton.ButtonType
    let style: ASAuthorizationAppleIDButton.Style
    let action: () -> Void
    
    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: type, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonTapped), for: .touchUpInside)
        return button
    }
    
    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: () -> Void
        
        init(action: @escaping () -> Void) {
            self.action = action
        }
        
        @objc func buttonTapped() {
            action()
        }
    }
}

// MARK: - Sign-In Status View
struct SignInStatusView: View {
    @ObservedObject var appleSignInService: AppleSignInService
    
    var body: some View {
        VStack(spacing: 16) {
            if appleSignInService.isSignedIn {
                // Signed in state
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    if let displayName = appleSignInService.userDisplayName {
                        Text("Hello, \(displayName)")
                            .font(.headline)
                    } else {
                        Text("Signed In")
                            .font(.headline)
                    }
                    
                    if let email = appleSignInService.userEmail {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Sign Out") {
                        Task {
                            await appleSignInService.signOut()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                // Sign in required state
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Sign in to sync your thoughts across devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    AppleSignInButton(appleSignInService: appleSignInService)
                        .frame(maxWidth: 280)
                }
            }
            
            if let errorMessage = appleSignInService.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            if appleSignInService.isLoading {
                ProgressView("Signing in...")
                    .font(.caption)
            }
        }
        .padding()
    }
}

#Preview {
    SignInStatusView(appleSignInService: AppleSignInService())
}