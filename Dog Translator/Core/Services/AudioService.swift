import AVFoundation
import Combine

final class AudioService: ObservableObject {
    static let shared = AudioService()

    private var audioPlayer: AVAudioPlayer?

    private init() {}

    func playSound(named name: String) {
        print("🔊 AudioService: Playing sound '\(name)'")

        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
        }

        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("❌ AudioService: Sound file not found: \(name).mp3")
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("❌ AudioService: Failed to play sound:", error.localizedDescription)
        }
    }

    func stop() {
        audioPlayer?.stop()
    }
}
