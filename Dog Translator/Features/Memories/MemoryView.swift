import SwiftUI
import PhotosUI

struct MemoryView: View {

    @ObservedObject var viewModel: DogViewModel

    @State private var selectedPhotoItem: PhotosPickerItem?

    @State private var galleryInfo: PhotoGalleryInfo? = nil
    @State private var selectedWalkAlbum: WalkRecord? = nil

    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    private var walksWithPhotos: [WalkRecord] {
        viewModel.walkHistory
            .filter { record in
                record.annotations.contains { $0.imageName.starts(with: "base64:") }
            }
            .sorted(by: { $0.date > $1.date })
    }

    var body: some View {

        ZStack {

            ScrollView {
                VStack(spacing: 20) {

                    Text("Memory")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBlue)

                    if !walksWithPhotos.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Walk Albums")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.appBlue)
                                .padding(.horizontal, 20)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(walksWithPhotos) { record in
                                        Button(action: {
                                            selectedWalkAlbum = record
                                        }) {
                                            WalkAlbumPreviewCard(record: record)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)
                            }
                        }
                    }

                    if !viewModel.memories.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Memories")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(.appBlue)
                                .padding(.horizontal, 20)

                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(viewModel.memories) { memory in
                                    Button(action: {
                                        let memoriesWithImages = viewModel.memories.filter { $0.uiImage != nil }
                                        let allImages = memoriesWithImages.compactMap { $0.uiImage }

                                        if let tappedIndex = memoriesWithImages.firstIndex(where: { $0.id == memory.id }) {
                                            self.galleryInfo = PhotoGalleryInfo(
                                                images: allImages,
                                                startIndex: tappedIndex
                                            )
                                        } else if let tappedImage = memory.uiImage {
                                            self.galleryInfo = PhotoGalleryInfo(images: [tappedImage], startIndex: 0)
                                        }
                                    }) {
                                        MemoryCardView(memory: memory)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    if walksWithPhotos.isEmpty && viewModel.memories.isEmpty {
                        Text("Your memories are empty.\nTap the camera button to add a photo!")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(40)
                            .background(Color.elementBackground)
                            .cornerRadius(20)
                            .padding(.top, 40)
                    }

                    Spacer(minLength: 100)
                }
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images
                    ) {
                        Image(systemName: "plus")
                            .font(.system(size: 28, weight: .semibold))
                            .frame(width: 64, height: 64)
                            .foregroundColor(.white)
                            .background(Color.appBlue)
                            .clipShape(Circle())
                            .shadow(color: .appPurple.opacity(0.5), radius: 10, y: 5)
                    }
                    .padding(20)
                }
            }
        }

        .fullScreenCover(item: $selectedWalkAlbum) { record in
            WalkAlbumDetailView(record: record)
        }
        .fullScreenCover(item: $galleryInfo) { info in
            PhotoGalleryView(images: info.images, startIndex: info.startIndex)
        }

        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    viewModel.addMemory(imageData: data)
                    selectedPhotoItem = nil
                }
            }
        }
    }
}

struct MemoryCardView: View {
    let memory: MemoryItem

    var body: some View {
        VStack(spacing: 0) {
            Text(memory.dateFormatted)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.black)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.white)

            Rectangle()
                .fill(Color.clear)
                .aspectRatio(1, contentMode: .fit)
                .background(

                    (memory.uiImage.map { Image(uiImage: $0) } ?? Image(systemName: "pawprint.fill"))
                        .resizable()
                        .scaledToFill()
                        .background(Color.gray.opacity(0.2))
                )
                .clipped()
        }
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: .appPurple.opacity(0.2), radius: 5, y: 3)
    }
}

struct WalkAlbumPreviewCard: View {

    let record: WalkRecord

    private var firstPhoto: UIImage? {
        guard let photoAnnotation = record.annotations.first(where: {
            $0.imageName.starts(with: "base64:")
        }) else {
            return nil
        }

        let base64String = String(photoAnnotation.imageName.dropFirst("base64:".count))
        guard let data = Data(base64Encoded: base64String),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    var body: some View {
        ZStack {
            Group {
                if let firstPhoto = firstPhoto {
                    Image(uiImage: firstPhoto)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.3)
                        .overlay(Image(systemName: "photo.on.rectangle.angled").font(.largeTitle).foregroundColor(.gray))
                }
            }
            .frame(width: 160, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack {
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 80)
            }

            VStack(alignment: .leading) {
                Spacer()
                Text(record.dogName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(record.dateFormatted)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 160, height: 200)
        .cornerRadius(12)
        .shadow(color: .appPurple.opacity(0.3), radius: 5, y: 4)
    }
}

#Preview {
    MemoryView(viewModel: DogViewModel())
}
