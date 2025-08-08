//
//  SpeechRecognitionService.swift
//  prismNg
//
//  Created by AI Assistant on 2025/8/5.
//

import Foundation
import SwiftUI
import Speech
import AVFoundation

// MARK: - Speech Recognition Service
@MainActor
class SpeechRecognitionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var isAuthorized = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // MARK: - Initialization
    init() {
        requestAuthorization()
    }
    
    // MARK: - Authorization
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                self?.isAuthorized = status == .authorized
            }
        }
    }
    
    // MARK: - Recording Control
    func startRecording() async throws {
        // Cancel any existing recognition task
        stopRecording()
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // Create recognition request
        let recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        self.recognitionRequest = recognitionRequest
        recognitionRequest.shouldReportPartialResults = true
        
        // Set up audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        // Start recognition
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechRecognitionError.recognizerUnavailable
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.recognizedText = result.bestTranscription.formattedString
                }
                
                if error != nil || result?.isFinal == true {
                    self?.stopRecording()
                }
            }
        }
        
        isRecording = true
        recognizedText = ""
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        isRecording = false
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
    
    // MARK: - Convenience Methods
    func toggleRecording() async {
        if isRecording {
            stopRecording()
        } else {
            guard isAuthorized else {
                requestAuthorization()
                return
            }
            
            do {
                try await startRecording()
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }
    
    func clearText() {
        recognizedText = ""
    }
}

// MARK: - Speech Recognition Error
enum SpeechRecognitionError: Error, LocalizedError {
    case recognizerUnavailable
    case audioEngineError
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Speech recognizer is not available"
        case .audioEngineError:
            return "Audio engine error"
        case .authorizationDenied:
            return "Speech recognition authorization denied"
        }
    }
}

// MARK: - Speech Recognition Button View
struct SpeechRecognitionButton: View {
    @StateObject private var speechService = SpeechRecognitionService()
    @Binding var recognizedText: String
    let onTextRecognized: (String) -> Void
    
    var body: some View {
        Button(action: {
            Task {
                await speechService.toggleRecording()
            }
        }) {
            Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                .font(.title2)
                .foregroundColor(speechService.isRecording ? .red : .primary)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                )
        }
        .disabled(!speechService.isAuthorized)
        .onChange(of: speechService.recognizedText) { _, newText in
            if !newText.isEmpty && !speechService.isRecording {
                onTextRecognized(newText)
                speechService.clearText()
            }
        }
        .onAppear {
            if speechService.authorizationStatus == .notDetermined {
                speechService.requestAuthorization()
            }
        }
    }
}

// MARK: - Deprecated Legacy Voice Input View
@available(*, deprecated, message: "Use Views/VoiceInputView.swift instead (统一语音输入组件) - Unified Voice Input Component")
struct LegacyVoiceInputView: View {
    var body: some View { EmptyView() }
}