//
//  BYOKKeyEntryView.swift
//  prismNg
//
//  UI to save/delete user's OpenAI API key in Keychain
//

import SwiftUI

struct BYOKKeyEntryView: View {
    @State private var apiKey: String = ""
    @State private var message: String = ""
    private let keychain = KeychainService()
    
    var body: some View {
        Form {
            Section("OpenAI API Key") {
                SecureField("sk-...", text: $apiKey)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            
            Section {
                Button {
                    do {
                        try keychain.saveOpenAIAPIKey(apiKey)
                        message = "已保存到 Keychain (Saved to Keychain)"
                    } catch {
                        message = "保存失败：\(error.localizedDescription)"
                    }
                } label: {
                    Label("保存", systemImage: "tray.and.arrow.down.fill")
                }
                .disabled(apiKey.isEmpty)
                
                Button(role: .destructive) {
                    do {
                        try keychain.saveOpenAIAPIKey("")
                        apiKey = ""
                        message = "已清除 (Cleared)"
                    } catch {
                        message = "清除失败：\(error.localizedDescription)"
                    }
                } label: {
                    Label("清除", systemImage: "trash")
                }
            }
            
            if !message.isEmpty {
                Section {
                    Text(message).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if let existing = try? keychain.getOpenAIAPIKey(), let k = existing { apiKey = k }
        }
    }
}


