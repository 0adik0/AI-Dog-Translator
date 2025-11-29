import SwiftUI
import Combine

@main
struct DogTranslatorApp: App {

    @StateObject private var dogViewModel = DogViewModel()
    @StateObject private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: dogViewModel)

                .environmentObject(dogViewModel)
                .environmentObject(storeManager)

                .fullScreenCover(isPresented: $dogViewModel.showPaywall) {
                    PaywallView()
                        .environmentObject(dogViewModel)
                        .environmentObject(storeManager)
                }
                .task {
                    for await isPro in storeManager.$isPro.values {
                        dogViewModel.isProUser = isPro
                    }
                }
        }
    }
}
