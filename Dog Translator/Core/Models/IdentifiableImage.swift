import SwiftUI

struct PhotoGalleryInfo: Identifiable {
    let id = UUID()
    let images: [UIImage]
    let startIndex: Int
}

struct ImageCardView: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PhotoGalleryView: View {
    let images: [UIImage]

    @State private var currentIndex: Int

    @Environment(\.dismiss) var dismiss

    init(images: [UIImage], startIndex: Int) {
        self.images = images

        self._currentIndex = State(initialValue: startIndex)
    }

    var body: some View {
        MainBackgroundView {
            ZStack(alignment: .topLeading) {

                TabView(selection: $currentIndex) {
                    ForEach(images.indices, id: \.self) { index in
                        ImageCardView(image: images[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentIndex)

                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color.appPurple, Color.appBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: Color.appPurple.opacity(0.4), radius: 10, y: 4)
                }
                .padding()
            }
        }
    }
}
