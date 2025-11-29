import SwiftUI
import SpriteKit

struct MainTabView: View {

    @ObservedObject var viewModel: DogViewModel

    @State private var selectedTab: Tab = .sounds

    enum Tab: String, CaseIterable {
        case sounds = "Sounds"
        case translator = "Translator"
        case generator = "Generator"
        case walk = "Walk"
        case memory = "Memory"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    .gradientStart,
                    .gradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            FloatingBonesBackground()
                .ignoresSafeArea()
                .opacity(0.5)

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .sounds:
                        SoundsView(viewModel: viewModel)
                    case .translator:
                        TranslatorView()
                    case .generator:
                        GeneratorView()
                    case .walk:
                        WalkView(viewModel: viewModel)
                    case .memory:
                        MemoryView(viewModel: viewModel)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)

                BottomNavBar(selectedTab: $selectedTab)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showCurrentWalk) {
            if viewModel.currentWalkingDog != nil {
                DogWalkView(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.loadDogs()
        }
    }
}

struct PlaceholderView: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.largeTitle)
            .foregroundColor(.appBlue)
    }
}

#Preview {
    MainTabView(viewModel: DogViewModel())
        .environmentObject(DogViewModel())
}
