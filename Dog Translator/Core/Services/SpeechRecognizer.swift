import Foundation
import Combine
import Speech
import AVFoundation

final class SpeechRecognizer: ObservableObject {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var lastTranscript: String = ""

    private var isStopping = false

    func startRecording() throws {

        lastTranscript = ""
        isStopping = false
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
             print("❌ SpeechRecognizer: recognitionRequest is nil")
             throw NSError(domain: "SpeechRecognizer", code: 1, userInfo: [NSLocalizedDescriptionKey: "SFSpeechAudioBufferRecognitionRequest failed to create."])
        }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)

        recognitionTask = recognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            var isFinal = false
            if let result = result {
                self.lastTranscript = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }

            if error != nil || isFinal {

                print("🏁 SpeechRecognizer: recognitionTask завершен (isFinal: \(isFinal), error: \(error != nil))")

                if self.isStopping {
                    self.audioEngine.stop()
                    self.recognitionRequest = nil
                }
            }
        }

        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        print("🎙 SpeechRecognizer: Запись начата. audioEngine.isRunning: \(audioEngine.isRunning)")
    }

    func stopRecording(completion: @escaping (String) -> Void) {

        guard !isStopping else {
             print("⚠️ SpeechRecognizer: stopRecording() уже был вызван.")
            return
        }

        isStopping = true

        print("🛑 SpeechRecognizer: stopRecording() вызван. audioEngine.isRunning: \(audioEngine.isRunning)")

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        recognitionRequest?.endAudio()

        recognitionTask?.cancel()

        print("✅ SpeechRecognizer: Возвращаем: '\(lastTranscript)'")
        completion(lastTranscript)

        recognitionRequest = nil
        recognitionTask = nil
    }
}
