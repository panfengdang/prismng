import SwiftUI
import Speech

struct VoiceInputView: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var isRecording = false
    var onCompletion: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Waveform animation placeholder
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.blue.opacity(isRecording ? 0.8 : 0.3))
                            .frame(width: 4, height: isRecording ? CGFloat.random(in: 10...50) : 20)
                            .animation(
                                isRecording ? Animation.easeInOut(duration: 0.5)
                                    .repeatForever()
                                    .delay(Double(index) * 0.1) : .default,
                                value: isRecording
                            )
                    }
                }
                .frame(height: 60)
                
                Text(speechService.recognizedText.isEmpty ? "Tap to start speaking" : speechService.recognizedText)
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(minHeight: 100)
                
                // Record button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.blue)
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isRecording ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: isRecording)
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 20) {
                    Button("Cancel") {
                        stopRecording()
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Create Note") {
                        stopRecording()
                        if !speechService.recognizedText.isEmpty {
                            onCompletion(speechService.recognizedText)
                        }
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(speechService.recognizedText.isEmpty)
                }
                .padding(.bottom)
            }
            .padding()
            .navigationTitle("Voice Input")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        stopRecording()
                        isPresented = false
                    }
                }
            }
        }
        .onAppear {
            speechService.requestAuthorization()
        }
        .onDisappear {
            stopRecording()
        }
        .alert("Microphone Permission Required", 
               isPresented: .constant(speechService.authorizationStatus == .denied)) {
            Button("OK") { }
        } message: {
            Text("Please enable microphone access in Settings to use voice input.")
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        Task {
            do {
                try await speechService.startRecording()
                isRecording = true
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }
    
    private func stopRecording() {
        speechService.stopRecording()
        isRecording = false
    }
}

#Preview {
    VoiceInputView(
        text: .constant(""),
        isPresented: .constant(true)
    ) { text in
        print("Recognized: \(text)")
    }
}