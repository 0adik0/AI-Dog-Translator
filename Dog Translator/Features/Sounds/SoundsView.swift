import SwiftUI
import AVFoundation

struct SoundsView: View {
    @StateObject private var soundsViewModel = SoundsViewModel()
    @ObservedObject var viewModel: DogViewModel

    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            MainBackgroundView {
                VStack(spacing: 20) {

                    Text("Sounds")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBlue)
                        .padding(.top, 20)

                    Image("dog_house_header")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)

                    selectedSoundDisplay

                    soundsGrid
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var selectedSoundDisplay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.elementBackground)
                .frame(width: 240, height: 240)
                .shadow(color: .appPurple.opacity(0.25), radius: 15, y: 10)

            if let sound = soundsViewModel.selectedSound {
                Image(sound)
                    .resizable().scaledToFit().frame(width: 150, height: 150)
                    .scaleEffect(soundsViewModel.isPlaying ? 1.15 : 1)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: soundsViewModel.isPlaying)
            } else {
                Image("happy").resizable().scaledToFit().frame(width: 150, height: 150).opacity(0.4)
            }
        }
    }

    private var soundsGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {

                ForEach(soundsViewModel.sounds.indices, id: \.self) { index in
                    let sound = soundsViewModel.sounds[index]
                    let isPremium = soundsViewModel.isPremium(index: index)

                    soundButton(sound: sound, isPremium: isPremium)
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private func soundButton(sound: String, isPremium: Bool) -> some View {
        Button(action: {
            if !soundsViewModel.playSound(sound, isPremium: isPremium, isProUser: viewModel.isProUser) {
                viewModel.showPaywall = true
            }
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.elementBackground)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(soundsViewModel.selectedSound == sound ? Color.appPurple : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: .appPurple.opacity(0.15), radius: 5, y: 3)

                Image(sound)
                    .resizable().scaledToFit().frame(width: 60, height: 60)
                    .scaleEffect(soundsViewModel.selectedSound == sound && soundsViewModel.isPlaying ? 1.15 : 1.0)
                    .opacity(isPremium && !viewModel.isProUser ? 0.5 : 1.0)

                if isPremium && !viewModel.isProUser {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.appPurple)
                        .padding(5)
                        .background(Color.white.opacity(0.7))
                        .clipShape(Circle())
                        .shadow(radius: 1)
                        .padding(5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(soundsViewModel.selectedSound == sound ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.25), value: soundsViewModel.selectedSound)
    }
}

#Preview {
    SoundsView(viewModel: DogViewModel())
}
