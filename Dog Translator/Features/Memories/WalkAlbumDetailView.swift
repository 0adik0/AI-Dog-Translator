import SwiftUI

private struct CustomHeader: View {
    let title: String
    var backAction: () -> Void

    var body: some View {
        HStack {
            Button(action: backAction) {
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
            Spacer()
            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(.appBlue)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Rectangle().frame(width: 44, height: 44).opacity(0)
        }
        .padding(.horizontal, 10)
    }
}

struct WalkAlbumDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let record: WalkRecord

    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    @State private var photoImages: [UIImage] = []
    @State private var galleryInfo: PhotoGalleryInfo?
    @State private var isLoading = true

    var body: some View {
        MainBackgroundView {
            VStack(spacing: 0) {

                CustomHeader(title: "Walk with \(record.dogName)") {
                    dismiss()
                }

                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if photoImages.isEmpty {
                    Text("No photos were taken on this walk.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                        .padding(40)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(photoImages.indices, id: \.self) { index in
                                Button(action: {
                                    self.galleryInfo = PhotoGalleryInfo(
                                        images: photoImages,
                                        startIndex: index
                                    )
                                }) {

                                    Rectangle()
                                        .fill(Color.clear)
                                        .aspectRatio(1, contentMode: .fit)
                                        .background(
                                            Image(uiImage: photoImages[index])
                                                .resizable()
                                                .scaledToFill()
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .shadow(color: .appPurple.opacity(0.2), radius: 5, y: 3)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $galleryInfo) { info in
            PhotoGalleryView(images: info.images, startIndex: info.startIndex)
        }
        .onAppear {
            loadPhotos()
        }
    }

    private func loadPhotos() {

        DispatchQueue.global(qos: .userInitiated).async {
            var images: [UIImage] = []

            let photoAnnotations = record.annotations.filter {
                $0.imageName.starts(with: "base64:")
            }

            for annotation in photoAnnotations {
                let base64String = String(annotation.imageName.dropFirst("base64:".count))
                if let data = Data(base64Encoded: base64String), let image = UIImage(data: data) {
                    images.append(image)
                }
            }

            DispatchQueue.main.async {
                self.photoImages = images
                self.isLoading = false
            }
        }
    }
}
