import Foundation
import AVFoundation

struct ClaudeTranslator {

    static let apiKey = "YOUR_API_KEY_HERE"

    static let apiUrl = "https://api.anthropic.com/v1/messages"

    private static let synthesizer = AVSpeechSynthesizer()

    static func translate(text: String, mode: String) async throws -> String {
        guard let url = URL(string: apiUrl) else {
            throw URLError(.badURL)
        }

        let prompt: String
        if mode == "humanToDog" {
            prompt = """
            You are a dog translator. Act as a dog.
            Translate the following human phrase into a series of playful, varied dog sounds (like 'Woof!', 'Grrr', 'Yip!', 'Arf!').
            Be creative. Do not add any human explanation. Just return the dog sounds.
            Human phrase: \(text)
            """
        } else {
            prompt = """
            You are a dog translator. Act as a human interpreting a dog's bark.
            Translate the following dog bark into a short, creative, and playful human phrase.
            For example, 'Woof woof!' could become 'I'm so excited!'.
            Do not add any extra explanation. Just return the human phrase.
            Dog bark: \(text)
            """
        }

        let body: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 100,
            "messages": [
                [
                    "role": "user",
                    "content": prompt
                ]
            ]
        ]

        let data = try JSONSerialization.data(withJSONObject: body)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (responseData, _) = try await URLSession.shared.data(for: request)

        if let raw = String(data: responseData, encoding: .utf8) {
            print("🌐 Claude raw response:", raw)
        }

        let decoded = try JSONSerialization.jsonObject(with: responseData) as? [String: Any]

        if let error = decoded?["error"] as? [String: Any],
           let message = error["message"] as? String {
            print("❌ Claude API error:", message)
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }

        if let content = decoded?["content"] as? [[String: Any]],
           let textBlock = content.first?["text"] as? String {
            return textBlock.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No translation from Claude"])
    }

    static func speak(_ text: String, lang: String = "en-US") {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers, .defaultToSpeaker])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ AudioSession error:", error.localizedDescription)
        }

        let utterance = AVSpeechUtterance(string: text)

        if let siriVoice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language == lang && $0.name.contains("Siri") }) {
            utterance.voice = siriVoice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: lang)
        }

        utterance.rate = 0.45
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        Self.synthesizer.speak(utterance)
    }
}
