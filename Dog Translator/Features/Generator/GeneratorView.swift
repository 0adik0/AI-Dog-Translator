import SwiftUI
import AVFoundation
import AVFAudio

struct GeneratorView: View {
    @State private var frequency: Double = 10000
    @State private var isPlaying = false
    private let oscillator = AVTonePlayerUnit()

    var body: some View {
        MainBackgroundView {

            VStack(spacing: 0) {

                Text("Generator")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.appBlue)
                    .padding(.top, 20)

                Image("back_generate")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)

                GeometryReader { geo in
                    ScrollView(.vertical, showsIndicators: false) {

                        VStack(spacing: 20) {

                            Spacer()

                            VStack {

                                ZStack {
                                    if isPlaying {
                                        Circle()
                                            .stroke(Color.appPurple.opacity(0.3), lineWidth: 8)
                                            .frame(width: 250, height: 250)
                                            .scaleEffect(isPlaying ? 1.4 : 1)
                                            .opacity(isPlaying ? 0 : 1)
                                            .animation(
                                                .easeOut(duration: 1.5)
                                                .repeatForever(autoreverses: false),
                                                value: isPlaying
                                            )
                                    }
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 200, height: 200)
                                        .shadow(color: .appPurple.opacity(isPlaying ? 0.5 : 0.3),
                                                radius: isPlaying ? 30 : 20,
                                                y: 10)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.appPurple.opacity(0.3), lineWidth: 4)
                                        )
                                        .scaleEffect(isPlaying ? 1.15 : 1)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isPlaying)
                                        .onTapGesture {
                                            toggleSound()
                                        }
                                    Image(systemName: "waveform")
                                        .font(.system(size: 65, weight: .medium))
                                        .foregroundColor(.appPurple)
                                        .scaleEffect(isPlaying ? 1.15 : 1)
                                        .animation(.easeInOut(duration: 0.25), value: isPlaying)
                                        .shadow(color: .appPurple.opacity(isPlaying ? 0.7 : 0),
                                                radius: isPlaying ? 15 : 0)
                                }
                            }

                            .frame(height: 280)

                            Text("\(Int(frequency)) Hz")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.appBlue)
                                .opacity(isPlaying ? 1 : 0.7)
                                .animation(.easeInOut, value: isPlaying)
                                .contentTransition(.numericText(countsDown: frequency < Double(oscillator.frequencyValue)))

                            VStack(spacing: 15) {
                                Slider(value: $frequency, in: 1000...20000, step: 100)
                                    .tint(.appPurple)
                                    .padding(.horizontal, 40)
                                    .onChange(of: frequency) { _, newValue in
                                        oscillator.setFrequency(Float(newValue))
                                    }
                            }

                            .padding(.top, 20)

                            Text("High frequencies may not be audible to you, but dogs can hear them")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)

                            Spacer()
                        }

                        .frame(minHeight: geo.size.height)
                    }
                }
            }
        }
    }

    private func toggleSound() {
        if isPlaying {
            oscillator.stop()
        } else {
            oscillator.preparePlaying()
            oscillator.play()
        }
        isPlaying.toggle()
    }
}
