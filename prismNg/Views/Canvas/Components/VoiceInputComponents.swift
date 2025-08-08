//
//  VoiceInputComponents.swift
//  prismNg
//
//  Shared voice input components for canvas views
//

import SwiftUI
import AVFoundation

// MARK: - Speech Recognizer (Mock Implementation)
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    
    func startRecording() {
        isRecording = true
        // Mock implementation - in production, use Speech framework
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.transcript = "这是一个语音输入的示例文本"
        }
    }
    
    func stopRecording() {
        isRecording = false
    }
}

// MARK: - Voice Input Sheet
struct VoiceInputSheet: View {
    @ObservedObject var recognizer: SpeechRecognizer
    let onComplete: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Microphone animation
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(recognizer.isRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recognizer.isRecording)
                    
                    Image(systemName: recognizer.isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                }
                
                Text(recognizer.isRecording ? "正在录音..." : "点击开始录音")
                    .font(.headline)
                
                // Transcribed text
                if !recognizer.transcript.isEmpty {
                    ScrollView {
                        Text(recognizer.transcript)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
                
                // Control buttons
                HStack(spacing: 30) {
                    if recognizer.isRecording {
                        Button(action: {
                            recognizer.stopRecording()
                        }) {
                            Label("停止", systemImage: "stop.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(action: {
                            recognizer.startRecording()
                        }) {
                            Label("开始录音", systemImage: "mic.circle.fill")
                                .font(.title3)
                        }
                    }
                    
                    if !recognizer.transcript.isEmpty {
                        Button(action: {
                            onComplete(recognizer.transcript)
                        }) {
                            Label("完成", systemImage: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("语音输入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        recognizer.stopRecording()
                        dismiss()
                    }
                }
            }
        }
    }
}