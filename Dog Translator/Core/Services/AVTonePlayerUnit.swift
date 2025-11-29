import AVFoundation

final class AVTonePlayerUnit {
    private var frequency: Double = 440
    private var sampleRate: Double = 44100
    private var theta: Double = 0
    private var playing = false

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode!

    init() {
        setupAudio()
    }

    private func setupAudio() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }

            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let thetaIncrement = 2.0 * Double.pi * self.frequency / self.sampleRate

            for frame in 0..<Int(frameCount) {
                let value: Float = self.playing ? Float(sin(self.theta)) : 0.0
                self.theta += thetaIncrement
                if self.theta > 2.0 * Double.pi {
                    self.theta -= 2.0 * Double.pi
                }

                for buffer in abl {
                    let pointer = buffer.mData?.assumingMemoryBound(to: Float.self)
                    pointer?[frame] = value
                }
            }
            return noErr
        }

        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
    }

    func preparePlaying() {
        guard !engine.isRunning else { return }
        print("🔈 Запуск аудиодвижка...")

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)

            engine.mainMixerNode.outputVolume = 1.0
            try engine.start()
            print("✅ Engine запущен")
        } catch {
            print("❌ Ошибка запуска Engine:", error.localizedDescription)
        }
    }

    func play() {
        playing = true
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("❌ Engine restart error:", error.localizedDescription)
            }
        }
    }

    func stop() {
        playing = false
    }

    func setFrequency(_ freq: Float) {
        frequency = Double(freq)
    }

    var frequencyValue: Float {
        get { Float(frequency) }
        set { frequency = Double(newValue) }
    }
}
