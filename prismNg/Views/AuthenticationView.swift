//
//  AuthenticationView.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appleSignInService = AppleSignInService()
    @State private var showEmailSignIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var isSigningIn = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 64))
                            .foregroundColor(.blue)
                        
                        Text("Welcome to PrismNg")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sign in to sync your thoughts across all your devices and unlock premium features")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Authentication Options
                    VStack(spacing: 20) {
                        // Apple Sign-In
                        AppleSignInButton(appleSignInService: appleSignInService)
                            .frame(height: 50)
                            .frame(maxWidth: 280)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                        .frame(maxWidth: 280)
                        
                        // Email Sign-In Toggle
                        Button("Sign in with Email") {
                            showEmailSignIn.toggle()
                        }
                        .foregroundColor(.blue)
                        
                        // Email Sign-In Form
                        if showEmailSignIn {
                            VStack(spacing: 16) {
                                TextField("Email", text: $email)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                
                                SecureField("Password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.password)
                                
                                Button(action: signInWithEmail) {
                                    HStack {
                                        if isSigningIn {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        }
                                        Text("Sign In")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .disabled(isSigningIn || email.isEmpty || password.isEmpty)
                                }
                            }
                            .frame(maxWidth: 280)
                            .transition(.opacity)
                        }
                    }
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Terms and Privacy
                    VStack(spacing: 8) {
                        Text("By signing in, you agree to our")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Button("Terms of Service") {
                                // TODO: Show terms
                            }
                            .font(.caption)
                            
                            Button("Privacy Policy") {
                                // TODO: Show privacy policy
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.bottom)
                }
                .padding()
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            appleSignInService.checkSignInStatus()
        }
        .onChange(of: appleSignInService.isSignedIn) { isSignedIn in
            if isSignedIn {
                dismiss()
            }
        }
        .onChange(of: appleSignInService.errorMessage) { error in
            if let error = error {
                errorMessage = error
            }
        }
    }
    
    private func signInWithEmail() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isSigningIn = true
        errorMessage = ""
        
        Task {
            do {
                let firebaseManager = FirebaseManager.shared
                _ = try await firebaseManager.signIn(withEmail: email, password: password)
                
                await MainActor.run {
                    isSigningIn = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSigningIn = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Authentication Required View
struct AuthenticationRequiredView: View {
    @Binding var showAuthentication: Bool
    let feature: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.circle")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Sign In Required")
                .font(.headline)
            
            Text("Please sign in to use \(feature)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Sign In") {
                showAuthentication = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showAuthentication) {
            AuthenticationView()
        }
    }
}

#Preview {
    AuthenticationView()
}