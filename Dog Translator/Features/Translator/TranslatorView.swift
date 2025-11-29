import AVFoundation
import Speech
import SwiftUI
import NaturalLanguage

struct TranslatorView: View {

    @EnvironmentObject var viewModel: DogViewModel
    @StateObject private var translatorViewModel = TranslatorViewModel()

    @State private var isFullTextPresented = false

    enum Mode {
        case humanToDog, dogToHuman
    }

    var body: some View {
        MainBackgroundView {

            VStack(spacing: 0) {

                Text("AI Interpreter")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.appBlue)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                GeometryReader { geo in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 30) {

                            VStack(spacing: 12) {
                                Text(translatorViewModel.translationMode == .humanToDog ? "Human → Dog" : "Dog → Human")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.appPurple)

                                ZStack {
                                    if translatorViewModel.isThinking {
                                        Text("AI is thinking\(translatorViewModel.aiDots)")
                                            .font(.system(size: 18, weight: .medium, design: .rounded))
                                            .foregroundColor(.gray)
                                            .italic()
                                            .transition(.opacity)
                                    } else {
                                        Text(translatorViewModel.typingText.isEmpty ? translatorViewModel.translatedText : translatorViewModel.typingText)
                                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                                            .foregroundColor(.appBlue)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(3)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                if !translatorViewModel.translatedText.isEmpty && !translatorViewModel.isThinking {
                                                    isFullTextPresented = true
                                                }
                                            }
                                            .transition(.opacity)
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 60)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Color.elementBackground)
                                    .shadow(color: .appPurple.opacity(0.15), radius: 5, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.appBlue.opacity(0.5), lineWidth: 1)
                            )

                            Spacer()

                            ZStack {
                                Circle()
                                    .fill(Color.appPurple.opacity(0.15))
                                    .frame(width: 250, height: 250)
                                    .scaleEffect(translatorViewModel.micPulse ? 1.2 : 0.9)
                                    .opacity(translatorViewModel.micPulse ? 0 : 0.6)
                                    .animation(
                                        translatorViewModel.isRecording
                                        ? .easeInOut(duration: 1).repeatForever(autoreverses: false)
                                        : .default,
                                        value: translatorViewModel.micPulse
                                    )
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 180, height: 180)
                                    .shadow(color: .appPurple.opacity(0.2), radius: 15, y: 5)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.appPurple.opacity(0.3), lineWidth: 3)
                                    )
                                    .scaleEffect(translatorViewModel.isRecording ? 1.1 : 1)
                                    .shadow(color: .appPurple.opacity(translatorViewModel.isRecording ? 0.6 : 0), radius: 25)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: translatorViewModel.isRecording)
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.appPurple)
                                    .scaleEffect(translatorViewModel.isRecording ? 1.2 : 1)
                                    .animation(.easeInOut(duration: 0.25), value: translatorViewModel.isRecording)
                            }
                            .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
                                if pressing {
                                    translatorViewModel.startRecording(canUseFeature: viewModel.canUseAITranslator(), showPaywall: &viewModel.showPaywall)
                                } else {
                                    if translatorViewModel.isRecording {
                                        translatorViewModel.stopRecording {
                                            if !viewModel.isProUser {
                                                viewModel.freeTranslationsUsed += 1
                                            }
                                        }
                                    }
                                }
                            }, perform: {})

                            HStack(spacing: 20) {
                                ModeButton(icon: "person.fill", isActive: translatorViewModel.translationMode == .humanToDog)
                                Image(systemName: "arrow.left.arrow.right")
                                    .foregroundColor(.appPurple)
                                    .font(.system(size: 28, weight: .semibold))
                                ModeButton(icon: "pawprint.fill", isActive: translatorViewModel.translationMode == .dogToHuman)
                            }
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    translatorViewModel.toggleMode()
                                }
                            }
                            .padding(.top, 16)

                            Text("Hold the mic to talk")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 30)
                        .frame(minHeight: geo.size.height)
                    }
                }
            }
        }
        .onAppear {
            translatorViewModel.startDotAnimation()
            translatorViewModel.requestSpeechPermission()
        }
        .sheet(isPresented: $isFullTextPresented) {
            FullTextViewSheet(text: translatorViewModel.translatedText)
        }
    }
}

struct ModeButton: View {
    let icon: String
    let isActive: Bool

    var body: some View {
        Image(systemName: icon)
            .foregroundColor(isActive ? .white : .appPurple)
            .padding()
            .background(isActive ? Color.appPurple : Color.white)
            .clipShape(Circle())
            .shadow(color: .appPurple.opacity(0.2), radius: 5)
    }
}

struct FullTextViewSheet: View {
    let text: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Full Text")
                .font(.headline)
                .foregroundColor(.gray)

            ScrollView {
                Text(text)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.appBlue)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            Button("Close") {
                dismiss()
            }
            .padding(.top, 10)
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}
