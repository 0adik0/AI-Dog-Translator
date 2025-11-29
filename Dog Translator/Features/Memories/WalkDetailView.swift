import SwiftUI
import MapKit
import CoreLocation

struct WalkDetailView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: DogViewModel
    let record: WalkRecord

    @State private var appear = false
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion()

    @State private var galleryInfo: PhotoGalleryInfo? = nil

    var body: some View {
        ZStack {

            LinearGradient(
                colors: [Color.gradientStart, Color.gradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {

                        HStack {
                            Button { dismiss() } label: {
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
                            Text("Walk Details")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundColor(.appBlue)
                            Spacer()
                            Color.clear.frame(width: 44)
                        }
                        .padding(.horizontal)

                        RouteOverlayView(
                            region: $mapRegion,

                            route: record.routeCoordinates.map { $0.coordinate },

                            annotations: record.annotations.map {
                                    WalkAnnotation(
                                        id: $0.id,
                                        imageName: $0.imageName,
                                        coordinate: $0.coordinate.coordinate
                                    )
                                },

                            isTrackingUser: false,

                            onPhotoTapped: { (tappedID) in

                                handlePhotoTap(tappedID: tappedID)
                            },

                            onClusterTapped: {

                            },

                            onClusterPhotoTapped: { (tappedID) in

                                handlePhotoTap(tappedID: tappedID)
                            }
                        )
                        .frame(height: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.appBlue.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.appPurple.opacity(0.25), radius: 15, y: 8)
                        .padding(.horizontal)
                        .scaleEffect(appear ? 1 : 0.95)
                        .opacity(appear ? 1 : 0)
                        .animation(.spring(duration: 0.5, bounce: 0.35), value: appear)
                        .onAppear {
                            setMapRegion()
                        }

                        if let data = record.dogProfileImageData,
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                                .overlay(Circle().strokeBorder(Color.white, lineWidth: 4))
                                .shadow(color: Color.appPurple.opacity(0.4), radius: 10, y: 5)
                                .offset(y: -55)
                                .padding(.bottom, -45)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Circle()
                                .fill(Color.elementBackground)
                                .frame(width: 110, height: 110)
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.gray.opacity(0.5))
                                )
                                .offset(y: -55)
                                .padding(.bottom, -45)
                        }

                        VStack(spacing: 18) {
                            HStack(spacing: 16) {
                                WalkInfoCard(
                                    iconName: "flag.fill",
                                    label: "Distance",
                                    value: distanceFormatted(from: record.routeCoordinates)
                                )
                                WalkInfoCard(
                                    iconName: "stopwatch.fill",
                                    label: "Duration",
                                    value: record.durationFormatted
                                )
                            }
                            WalkInfoCard(
                                iconName: "calendar",
                                label: "Date",
                                value: record.dateFormatted
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal)

                        HStack(spacing: 40) {
                            CircleButton(icon: "trash.fill", color: .red) {
                                deleteRecord()
                            }
                        }
                        .padding(.bottom, 60)
                        .padding(.top, 10)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                appear = true
            }
        }
        .fullScreenCover(item: $galleryInfo) { info in
            PhotoGalleryView(images: info.images, startIndex: info.startIndex)
        }
        .navigationBarHidden(true)
    }

    private func handlePhotoTap(tappedID: UUID) {

        let photoAnnotations = record.annotations.filter { $0.decodedImage != nil }

        guard let tappedIndex = photoAnnotations.firstIndex(where: { $0.id == tappedID }) else {
            if let annotation = record.annotations.first(where: { $0.id == tappedID }),
               let tappedImage = annotation.decodedImage {
                self.galleryInfo = PhotoGalleryInfo(images: [tappedImage], startIndex: 0)
            }
            return
        }

        let allImages = photoAnnotations.compactMap { $0.decodedImage }

        self.galleryInfo = PhotoGalleryInfo(images: allImages, startIndex: tappedIndex)
    }

    private func setMapRegion() {
        let coordinates = record.routeCoordinates.map { $0.coordinate }
        guard !coordinates.isEmpty else {
            mapRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 50.0647, longitude: 19.9450),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            return
        }

        var minLat = coordinates[0].latitude, maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude, maxLon = coordinates[0].longitude

        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let latDelta = (maxLat - minLat)
        let lonDelta = (maxLon - minLon)
        let span = MKCoordinateSpan(
            latitudeDelta: latDelta > 0 ? latDelta * 1.5 : 0.02,
            longitudeDelta: lonDelta > 0 ? lonDelta * 1.5 : 0.02
        )
        mapRegion = MKCoordinateRegion(center: center, span: span)
    }

    private func deleteRecord() {
        withAnimation {
            if let index = viewModel.walkHistory.firstIndex(where: { $0.id == record.id }) {
                viewModel.walkHistory.remove(at: index)
                viewModel.saveWalkHistory()
                dismiss()
            }
        }
    }

    private func distanceFormatted(from route: [CodableCoordinate]) -> String {
        guard route.count > 1 else { return "0.00 km" }
        var total: CLLocationDistance = 0
        for i in 1..<route.count {
            let prev = CLLocation(latitude: route[i-1].latitude, longitude: route[i-1].longitude)
            let next = CLLocation(latitude: route[i].latitude, longitude: route[i].longitude)
            total += prev.distance(from: next)
        }
        return String(format: "%.2f km", total / 1000)
    }
}
