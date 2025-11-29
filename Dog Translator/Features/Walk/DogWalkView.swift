import SwiftUI
import MapKit
import Combine
import CoreLocation

struct DogWalkView: View {

    @ObservedObject var viewModel: DogViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var showLocationAlert = false
    @State private var hapticTrigger = 0
    @State private var showExitAlert = false
    @State private var showTooShortAlert = false

    @State private var showImagePicker = false
    @State private var inputImage: UIImage?

    @State private var galleryInfo: PhotoGalleryInfo? = nil

    @State private var trackingMode: MapUserTrackingMode = .follow

    private var leaderDog: Dog? {
        viewModel.currentWalkingDog
    }

    private var walkTitle: String {
        guard let leaderName = leaderDog?.name else {
            return "Walk"
        }
        return "Walk with \(leaderName)"
    }

    var body: some View {

        Group {
            MainBackgroundView {

                if let leaderDog = leaderDog {
                    ZStack(alignment: .top) {

                        VStack(spacing: 10) {
                            CustomHeader(title: walkTitle, showBackButton: true) {
                                handleBackButtonPress()
                            }
                            .padding(.horizontal, 10)

                            Spacer().frame(height: 10)

                            DogImageView(imageData: leaderDog.profileImageData)
                                .frame(width: 80, height: 80)
                                .padding(.bottom, -30)
                                .zIndex(1)

                            ZStack(alignment: .bottomTrailing) {
                                RouteOverlayView(
                                    region: $viewModel.region,
                                    route: viewModel.route,
                                    annotations: viewModel.annotations.map {
                                        WalkAnnotation(
                                            id: $0.id,
                                            imageName: $0.imageName,
                                            coordinate: $0.coordinate
                                        )
                                    },
                                    isTrackingUser: trackingMode == .follow,

                                    onPhotoTapped: { (tappedID) in

                                        handlePhotoTap(tappedID: tappedID)
                                    },

                                    onClusterTapped: {

                                    },

                                    onClusterPhotoTapped: { (tappedID) in

                                        handlePhotoTap(tappedID: tappedID)
                                    }
                                )
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                                .padding(.horizontal, 20)
                                .frame(maxHeight: .infinity)

                                Button(action: {
                                    withAnimation {
                                        trackingMode = .follow
                                    }
                                }) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.appBlue.opacity(0.8))
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                }
                                .padding(30)
                                .opacity(trackingMode == .follow ? 0 : 1)
                                .animation(.default, value: trackingMode)
                            }

                            HStack(spacing: 15) {
                                WalkInfoCard(iconName: "flag.fill", label: "Distance", value: distanceFormatted)
                                WalkInfoCard(iconName: "hourglass", label: "Duration", value: durationFormatted)
                            }
                            .padding(.horizontal, 20)

                            if viewModel.walkState != .ready {
                                WalkEmojiButtons(
                                    onImageTapped: { imageName in
                                        viewModel.addEmojiAnnotation(imageName: imageName)
                                    },
                                    onPhotoTapped: {
                                        showImagePicker = true
                                    }
                                )
                                .transition(.scale.combined(with: .opacity))
                            }

                            controlButtons(for: leaderDog)
                                .padding(.bottom, 20)
                        }
                        .animation(.easeInOut, value: viewModel.walkState)

                    }
                } else {
                    ProgressView()
                        .onAppear {
                            viewModel.showCurrentWalk = false
                        }
                }
            }
        }
        .navigationBarHidden(true)
        .addWalkModalsAndAlerts(
            viewModel: viewModel,
            showImagePicker: $showImagePicker,
            inputImage: $inputImage,
            galleryInfo: $galleryInfo,
            showLocationAlert: $showLocationAlert,
            showExitAlert: $showExitAlert,
            showTooShortAlert: $showTooShortAlert
        )
        .onChange(of: viewModel.region.center.latitude) { _, _ in
            if trackingMode == .follow {

            } else {
                trackingMode = .none
            }
        }
    }

    private func handlePhotoTap(tappedID: UUID) {

        let photoAnnotations = viewModel.annotations.filter { $0.decodedImage != nil }

        guard let tappedIndex = photoAnnotations.firstIndex(where: { $0.id == tappedID }) else {

            if let annotation = viewModel.annotations.first(where: { $0.id == tappedID }),
               let tappedImage = annotation.decodedImage {
                self.galleryInfo = PhotoGalleryInfo(images: [tappedImage], startIndex: 0)
            }
            return
        }

        let allImages = photoAnnotations.compactMap { $0.decodedImage }

        self.galleryInfo = PhotoGalleryInfo(images: allImages, startIndex: tappedIndex)
    }

    @ViewBuilder
    private func controlButtons(for dog: Dog) -> some View {
        switch viewModel.walkState {
        case .ready:
            Button(action: {
                viewModel.requestLocationAndStart()
                hapticTrigger += 1
            }) {
                Text("START")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appBlue)
                    .clipShape(Capsule())
                    .shadow(color: .appPurple.opacity(0.4), radius: 10, y: 5)
            }
            .padding(.horizontal, 40)

        case .walking:
            HStack(spacing: 40) {
                controlButton(icon: "pause.circle.fill", color: .appBlue, action: viewModel.pauseWalk)
                controlButton(icon: "stop.circle.fill", color: .red, action: {
                    showExitAlert = true
                })
            }
            .transition(.scale.combined(with: .opacity))

        case .paused:
            HStack(spacing: 40) {
                controlButton(icon: "play.circle.fill", color: .appBlue, action: viewModel.resumeWalk)
                controlButton(icon: "stop.circle.fill", color: .red, action: {
                    showExitAlert = true
                })
            }
            .transition(.scale.combined(with: .opacity))
        }
    }

    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            action()
            hapticTrigger += 1
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }) {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(color)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(color: .appPurple.opacity(0.4), radius: 15, y: 8)
        }
    }

    private func handleBackButtonPress() {
        if viewModel.walkState == .walking || viewModel.walkState == .paused {
            viewModel.showCurrentWalk = false
        } else {
            viewModel.showCurrentWalk = false
        }
    }

    private var distanceFormatted: String {
        return String(format: "%.2f KM", viewModel.distance / 1000)
    }

    private var durationFormatted: String {
        let walkDuration = viewModel.walkDuration
        let hours = Int(walkDuration) / 3600
        let minutes = (Int(walkDuration) % 3600) / 60
        let seconds = Int(walkDuration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

private struct WalkViewModifiers: ViewModifier {
    @ObservedObject var viewModel: DogViewModel

    @Binding var showImagePicker: Bool
    @Binding var inputImage: UIImage?

    @Binding var galleryInfo: PhotoGalleryInfo?

    @Binding var showLocationAlert: Bool
    @Binding var showExitAlert: Bool
    @Binding var showTooShortAlert: Bool

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $showImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .fullScreenCover(item: $galleryInfo) { info in
                PhotoGalleryView(images: info.images, startIndex: info.startIndex)
            }
            .onChange(of: inputImage) { newImage in
                guard let uiImage = newImage else { return }
                viewModel.addPhotoAnnotation(uiImage)
                inputImage = nil
            }
            .alert("Location Access Denied", isPresented: $showLocationAlert) {
                Button("OK", role: .cancel) { }
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            } message: {
                Text("Please enable location access in Settings to track your walk.")
            }
            .alert("End Walk?", isPresented: $showExitAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Exit", role: .destructive) {
                    if viewModel.walkDuration > 5 {
                        viewModel.stopWalk()
                    } else {
                        viewModel.stopWalk()
                        showTooShortAlert = true
                    }
                }
            } message: {
                Text("Are you sure you want to end your walk? Your progress will be saved if it was long enough.")
            }
            .alert("Walk Too Short", isPresented: $showTooShortAlert) {
                Button("OK") { }
            } message: {
                Text("Walks shorter than 5 seconds are not saved.")
            }
            .onAppear {
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                     if viewModel.locationManager.authorizationStatus == .denied ||
                         viewModel.locationManager.authorizationStatus == .restricted {
                         self.showLocationAlert = true
                     }
                 }
             }
    }
}

fileprivate extension View {
    func addWalkModalsAndAlerts(
        viewModel: DogViewModel,
        showImagePicker: Binding<Bool>,
        inputImage: Binding<UIImage?>,
        galleryInfo: Binding<PhotoGalleryInfo?>,
        showLocationAlert: Binding<Bool>,
        showExitAlert: Binding<Bool>,
        showTooShortAlert: Binding<Bool>
    ) -> some View {
        self.modifier(WalkViewModifiers(
            viewModel: viewModel,
            showImagePicker: showImagePicker,
            inputImage: inputImage,
            galleryInfo: galleryInfo,
            showLocationAlert: showLocationAlert,
            showExitAlert: showExitAlert,
            showTooShortAlert: showTooShortAlert
        ))
    }
}

private struct CustomHeader: View {

    let title: String
    var showBackButton: Bool = false
    var backAction: (() -> Void)? = nil
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: { backAction?() }) {
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
            } else {
                Rectangle().frame(width: 44, height: 44).opacity(0)
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
    }
}

private struct WalkEmojiButtons: View {

    let imageNames = ["poop_icon", "paw_icon", "bone_icon", "dog_icon", "ball_icon"]
    var onImageTapped: (String) -> Void
    var onPhotoTapped: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            ForEach(imageNames, id: \.self) { imageName in
                Button(action: {
                    onImageTapped(imageName)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .frame(width: 55, height: 55)
                        .background(Color.elementBackground)
                        .clipShape(Circle())
                        .shadow(color: .appBlue.opacity(0.2), radius: 5, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Button(action: {
                onPhotoTapped()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                Image(systemName: "camera.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .foregroundColor(.appBlue)
                    .frame(width: 55, height: 55)
                    .background(Color.elementBackground)
                    .clipShape(Circle())
                    .shadow(color: .appBlue.opacity(0.2), radius: 5, y: 3)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.top, 5)
    }
}

struct DogImageView: View {

    let imageData: Data?
    var body: some View {
        Group {
            if let data = imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "pawprint.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(20)
                    .foregroundColor(.appBlue.opacity(0.6))
                    .background(Color.elementBackground)
            }
        }
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 4))
        .shadow(color: .appPurple.opacity(0.3), radius: 7)
    }
}

private struct ImagePicker: UIViewControllerRepresentable {

    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator

        #if targetEnvironment(simulator)
        picker.sourceType = .photoLibrary
        #else
        picker.sourceType = .camera
        #endif

        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
