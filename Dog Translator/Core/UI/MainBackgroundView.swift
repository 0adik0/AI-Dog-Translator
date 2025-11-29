import SwiftUI

struct MainBackgroundView<Content: View>: View {

    @ViewBuilder let content: Content

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

            content
        }
    }
}
