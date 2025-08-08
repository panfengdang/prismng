//
//  FirebaseManager.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import AuthenticationServices
import CryptoKit

// MARK: - Firebase Manager
// Note: This is a mock implementation that simulates Firebase functionality
// Real Firebase SDK can be integrated via Xcode's Package Dependencies when needed

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isConfigured = false
    @Published var isAuthenticated = false
    @Published var currentUser: FirebaseUser?
    
    private var authStateListener: Any?
    private var currentNonce: String?
    
    private init() {
        setupAuthListener()
    }
    
    // MARK: - Configuration
    
    func initialize() {
        // Mock implementation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isConfigured = true
            print("✅ Firebase: Mock configuration completed")
        }
    }
    
    private func setupAuthListener() {
        // Mock implementation
        Task { @MainActor in
            // Check for saved mock auth state
            if UserDefaults.standard.bool(forKey: "mockIsAuthenticated") {
                self.isAuthenticated = true
                self.currentUser = FirebaseUser(
                    uid: "mock-user-id",
                    email: "user@example.com",
                    displayName: "Mock User"
                )
            }
        }
    }
    
    // MARK: - Authentication
    
    func signIn(withEmail email: String, password: String) async throws -> FirebaseUser {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Simple mock validation
        guard email.contains("@") && !password.isEmpty else {
            throw FirebaseError.invalidCredentials
        }
        
        let firebaseUser = FirebaseUser(
            uid: UUID().uuidString,
            email: email,
            displayName: email.components(separatedBy: "@").first
        )
        
        await MainActor.run {
            self.currentUser = firebaseUser
            self.isAuthenticated = true
            UserDefaults.standard.set(true, forKey: "mockIsAuthenticated")
        }
        
        return firebaseUser
    }
    
    func createUser(withEmail email: String, password: String, displayName: String?) async throws -> FirebaseUser {
        // Mock implementation - similar to signIn for now
        return try await signIn(withEmail: email, password: password)
    }
    
    func signInWithApple(authorization: ASAuthorization) async throws -> FirebaseUser {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw FirebaseError.authenticationFailed("Invalid Apple credential")
        }
        
        // Mock implementation
        let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        let firebaseUser = FirebaseUser(
            uid: appleIDCredential.user,
            email: appleIDCredential.email,
            displayName: fullName.isEmpty ? nil : fullName
        )
        
        await MainActor.run {
            self.currentUser = firebaseUser
            self.isAuthenticated = true
            UserDefaults.standard.set(true, forKey: "mockIsAuthenticated")
        }
        
        return firebaseUser
    }
    
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
    
    func signOut() async throws {
        // Mock implementation
        await MainActor.run {
            self.currentUser = nil
            self.isAuthenticated = false
            UserDefaults.standard.set(false, forKey: "mockIsAuthenticated")
        }
    }
    
    func deleteAccount() async throws {
        // Mock implementation
        try await signOut()
    }
    
    func resetPassword(email: String) async throws {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Password reset email sent to \(email) (mock)")
    }
    
    // MARK: - Firestore Operations
    
    func saveDocument<T: Codable>(_ document: T, to collection: String, documentId: String? = nil) async throws -> String {
        // Mock implementation
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let docId = documentId ?? UUID().uuidString
        print("💾 Mock: Saved document to \(collection)/\(docId)")
        
        // Store in UserDefaults for mock persistence
        if let encoded = try? JSONEncoder().encode(document) {
            UserDefaults.standard.set(encoded, forKey: "mock_\(collection)_\(docId)")
        }
        
        return docId
    }
    
    func fetchDocument<T: Codable>(from collection: String, documentId: String, as type: T.Type) async throws -> T? {
        // Mock implementation
        try await Task.sleep(nanoseconds: 300_000_000)
        
        // Try to fetch from UserDefaults mock storage
        if let data = UserDefaults.standard.data(forKey: "mock_\(collection)_\(documentId)"),
           let decoded = try? JSONDecoder().decode(type, from: data) {
            return decoded
        }
        
        return nil
    }
    
    func fetchDocuments<T: Codable>(from collection: String, where field: String? = nil, isEqualTo value: Any? = nil, as type: T.Type) async throws -> [T] {
        // Mock implementation - return empty array for now
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
    
    func deleteDocument(from collection: String, documentId: String) async throws {
        // Mock implementation
        try await Task.sleep(nanoseconds: 200_000_000)
        UserDefaults.standard.removeObject(forKey: "mock_\(collection)_\(documentId)")
        print("🗑️ Mock: Deleted document \(collection)/\(documentId)")
    }
    
    func batchWrite(operations: [(collection: String, documentId: String?, data: Any)]) async throws {
        // Mock implementation
        for operation in operations {
            if let data = operation.data as? Codable {
                _ = try await saveDocument(data, to: operation.collection, documentId: operation.documentId)
            }
        }
    }
    
    // Mock listener registration
    func listenToDocument<T: Codable>(
        collection: String,
        documentId: String,
        as type: T.Type,
        completion: @escaping (Result<T?, Error>) -> Void
    ) -> MockListenerRegistration {
        // Mock implementation
        Task {
            let doc = try? await fetchDocument(from: collection, documentId: documentId, as: type)
            completion(.success(doc))
        }
        
        return MockListenerRegistration()
    }
    
    // MARK: - Cloud Functions
    
    func callFunction(name: String, data: [String: Any]) async throws -> [String: Any] {
        // Mock implementation
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        print("⚡ Mock: Called function \(name)")
        
        // Mock AI proxy response
        if name == "aiProxy" {
            return [
                "result": "Mock AI response",
                "usage": ["input_tokens": 100, "output_tokens": 200],
                "cost": 0.003
            ]
        }
        
        return ["success": true]
    }
    
    // MARK: - Storage Operations
    
    func uploadData(_ data: Data, to path: String, metadata: [String: String]? = nil) async throws -> URL {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Store in UserDefaults for mock
        UserDefaults.standard.set(data, forKey: "mock_storage_\(path)")
        
        // Return mock URL
        return URL(string: "https://mock.storage.example.com/\(path)")!
    }
    
    func downloadData(from path: String) async throws -> Data {
        // Mock implementation
        try await Task.sleep(nanoseconds: 500_000_000)
        
        if let data = UserDefaults.standard.data(forKey: "mock_storage_\(path)") {
            return data
        }
        
        throw FirebaseError.firestoreError("File not found")
    }
    
    func deleteFile(at path: String) async throws {
        // Mock implementation
        try await Task.sleep(nanoseconds: 200_000_000)
        UserDefaults.standard.removeObject(forKey: "mock_storage_\(path)")
    }
}

// MARK: - Supporting Types

struct FirebaseUser: Identifiable, Codable {
    let id = UUID()
    let uid: String
    let email: String?
    let displayName: String?
    let createdAt: Date
    
    init(uid: String, email: String?, displayName: String?) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.createdAt = Date()
    }
}

struct AppleSignInCredential {
    let userIdentifier: String
    let email: String?
    let fullName: String?
    let identityToken: Data?
    let authorizationCode: Data?
}

// MARK: - Firebase Errors

enum FirebaseError: LocalizedError {
    case configurationFailed
    case authenticationFailed(String)
    case networkError
    case invalidCredentials
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case firestoreError(String)
    case functionsError(String)
    
    var errorDescription: String? {
        switch self {
        case .configurationFailed:
            return "Firebase configuration failed"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .networkError:
            return "Network connection error"
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User account not found"
        case .emailAlreadyInUse:
            return "Email address is already in use"
        case .weakPassword:
            return "Password is too weak"
        case .firestoreError(let message):
            return "Database error: \(message)"
        case .functionsError(let message):
            return "Function error: \(message)"
        }
    }
}

// MARK: - Firebase Collections

struct FirebaseCollections {
    static let users = "users"
    static let thoughtNodes = "thoughtNodes"
    static let connections = "connections"
    static let userConfigurations = "userConfigurations"
    static let aiTasks = "aiTasks"
    static let emotionalMarkers = "emotionalMarkers"
}

// MARK: - Firestore Document Protocol

protocol FirestoreDocument: Identifiable, Codable {
    var id: String { get }
    var createdAt: Date { get }
    var updatedAt: Date { get set }
}

extension FirestoreDocument {
    mutating func updateTimestamp() {
        updatedAt = Date()
    }
}

// MARK: - Mock Listener Registration
struct MockListenerRegistration {
    func remove() {
        // Mock implementation - does nothing
    }
}