import Foundation
import SwiftUI
import Speech
import AVFoundation
import Combine

@MainActor
final class TranslatorViewModel: ObservableObject {

    @Published var isRecording = false
    @Published var translationMode: TranslatorView.Mode = .humanToDog
    @Published var translatedText: String = "Press and hold to start recording"
    @Published var isThinking = false
    @Published var micPulse = false
    @Published var typingText: String = ""
    @Published var aiDots = ""

    private let speechRecognizer = SpeechRecognizer()
    private let audioService = AudioService.shared

    private let aiDogBarks = [
        "Woof woof!", "Grrrrr...", "Yip yip yip!", "Aroooooo!", "Bork!",
        "Arf!", "Ruff ruff!", "Awooo!"
    ]

    private let humanDogSounds = (1...12).map { "trans\($0)" }

    private var typingTimer: Timer?

    func toggleMode() {
        translationMode = translationMode == .humanToDog ? .dogToHuman : .humanToDog
        stopTypingAnimation()
        translatedText = "Press and hold to start recording"
        typingText = ""
        isThinking = false
    }

    func startRecording(canUseFeature: Bool, showPaywall: inout Bool) {
        guard canUseFeature else {
            showPaywall = true
            return
        }

        print("🎙 TranslatorViewModel: Start recording…")

        stopTypingAnimation()
        isThinking = false
        typingText = ""
        aiDots = ""
        translatedText = "Listening..."

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    do {
                        try self.speechRecognizer.startRecording()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            self.isRecording = true
                        }
                        withAnimation { self.micPulse = true }
                    } catch {
                        print("❌ SpeechRecognizer start error:", error.localizedDescription)
                        self.translatedText = "⚠️ Error starting recording."
                        self.isRecording = false
                    }
                } else {
                    self.translatedText = "⚠️ Microphone access denied. Please enable it in Settings."
                    self.isRecording = false
                }
            }
        }
    }

    func stopRecording(onUsage: @escaping () -> Void) {
        print("🛑 TranslatorViewModel: Stop recording")

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isRecording = false
        }
        withAnimation { micPulse = false }

        speechRecognizer.stopRecording { [weak self] (finalTranscript) in
            guard let self = self else { return }
            print("✅ TranslatorViewModel: Transcript: '\(finalTranscript)'")

            onUsage()

            if self.translationMode == .humanToDog {
                self.handleHumanToDog()
            } else {
                self.handleDogToHuman()
            }
        }
    }

    private func handleHumanToDog() {
        isThinking = false
        let randomSound = humanDogSounds.randomElement() ?? "trans1"

        stopTypingAnimation()
        startTypingAnimation("🐶")

        audioService.playSound(named: randomSound)
    }

    private func handleDogToHuman() {
        isThinking = true
        let fakeBarkInput = aiDogBarks.randomElement() ?? "Woof!"

        Task {
            await self.performTranslation(input: fakeBarkInput)
        }
    }

    private func performTranslation(input: String) async {
        do {
            let result = try await ClaudeTranslator.translate(text: input, mode: "dogToHuman")

            await MainActor.run {
                self.isThinking = false
                self.stopTypingAnimation()
                self.startTypingAnimation(result)
                ClaudeTranslator.speak(result, lang: "en-US")
            }
        } catch {
            await MainActor.run {
                self.isThinking = false
                self.stopTypingAnimation()
                let errorMsg = "Couldn't interpret the bark 🐶❌"
                self.startTypingAnimation(errorMsg)
                print("❌ Claude error:", error.localizedDescription)
            }
        }
    }

    func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            guard self.isThinking else {
                self.aiDots = ""
                return
            }
            self.aiDots = self.aiDots.count < 3 ? self.aiDots + "." : ""
        }
    }

    private func stopTypingAnimation() {
        typingTimer?.invalidate()
        typingTimer = nil
        if !typingText.isEmpty && typingText != translatedText {
            typingText = translatedText
        }
    }

    private func startTypingAnimation(_ text: String) {
        stopTypingAnimation()

        translatedText = text
        typingText = ""

        var index = text.startIndex

        typingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            guard index < text.endIndex else {
                timer.invalidate()
                self.typingTimer = nil
                return
            }

            self.typingText.append(text[index])
            index = text.index(after: index)
        }
    }

    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus != .authorized {
                    print("❌ Speech recognition access not granted.")
                    self.translatedText = "⚠️ Speech recognition access denied."
                }
            }
        }
    }
}
