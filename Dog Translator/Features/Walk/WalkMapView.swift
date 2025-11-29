import SwiftUI
import MapKit
import CoreLocation

struct WalkMapView: View {
    let record: WalkRecord

    @State private var region: MKCoordinateRegion = .init(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )

    @State private var galleryInfo: PhotoGalleryInfo?

    var body: some View {
        ZStack {
            WalkHistoryMapView(
                route: record.routeCoordinates.map { $0.coordinate },
                annotations: record.annotations.map {

                    WalkAnnotation(id: $0.id, imageName: $0.imageName, coordinate: $0.coordinate.coordinate)
                },

                onAnnotationTapped: { imageName in
                    handlePhotoTap(imageName: imageName)
                }
            )

            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(record.dogName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.appBlue)
                        Text(record.dateFormatted)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        Text("Duration: \(record.durationFormatted)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.appPurple)
                    }
                    .padding(10)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            if let first = record.routeCoordinates.first?.coordinate {
                region.center = first
            }
        }
        .navigationTitle("Walk Route")
        .navigationBarTitleDisplayMode(.inline)

        .fullScreenCover(item: $galleryInfo) { info in
            PhotoGalleryView(images: info.images, startIndex: info.startIndex)
        }
    }

    private func handlePhotoTap(imageName: String) {

        let photoAnnotations = record.annotations.filter { $0.decodedImage != nil }

        guard let tappedIndex = photoAnnotations.firstIndex(where: { $0.imageName == imageName }) else {

            if let annotation = record.annotations.first(where: { $0.imageName == imageName }),
               let tappedImage = annotation.decodedImage {
                self.galleryInfo = PhotoGalleryInfo(images: [tappedImage], startIndex: 0)
            }
            return
        }

        let allImages = photoAnnotations.compactMap { $0.decodedImage }

        self.galleryInfo = PhotoGalleryInfo(images: allImages, startIndex: tappedIndex)
    }
}

struct WalkHistoryMapView: UIViewRepresentable {
    let route: [CLLocationCoordinate2D]
    let annotations: [WalkAnnotation]

    var onAnnotationTapped: (String) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = true
        mapView.mapType = .standard
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)

        if !route.isEmpty {
            let polyline = MKPolyline(coordinates: route, count: route.count)
            mapView.addOverlay(polyline)

            for annotation in annotations {
                let pin = MKPointAnnotation()
                pin.coordinate = annotation.coordinate
                pin.title = annotation.imageName
                mapView.addAnnotation(pin)
            }

            mapView.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 50, left: 40, bottom: 60, right: 40),
                animated: false
            )
        } else {
            mapView.setRegion(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ),
                animated: false
            )
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onAnnotationTapped: onAnnotationTapped)
    }

    class Coordinator: NSObject, MKMapViewDelegate {

        var onAnnotationTapped: (String) -> Void

        init(onAnnotationTapped: @escaping (String) -> Void) {
            self.onAnnotationTapped = onAnnotationTapped
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor(Color.appBlue)
            renderer.lineWidth = 5
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

            if annotation is MKUserLocation {
                return nil
            }

            let id = "customPin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)

            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                view?.canShowCallout = false

                view?.frame.size = CGSize(width: 35, height: 35)
                view?.backgroundColor = .clear

                let imageView = UIImageView(frame: view!.bounds)
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 8
                imageView.layer.borderColor = UIColor.white.cgColor
                imageView.layer.borderWidth = 1
                imageView.tag = 100
                view?.addSubview(imageView)
            }

            if let imageView = view?.viewWithTag(100) as? UIImageView {

                var imageName: String
                if let optionalImageName = annotation.title {
                    imageName = optionalImageName ?? "pawprint.fill"
                } else {
                    imageName = "pawprint.fill"
                }

                if imageName.starts(with: "base64:") {
                    let base64String = String(imageName.dropFirst("base64:".count))
                    if let data = Data(base64Encoded: base64String) {
                        imageView.image = UIImage(data: data)
                    } else {
                        imageView.image = UIImage(systemName: "photo.fill")
                    }
                    imageView.contentMode = .scaleAspectFill

                } else {
                    imageView.image = UIImage(named: imageName) ?? UIImage(systemName: "pawprint.fill")
                    imageView.contentMode = .scaleAspectFit
                }
            }

            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let title = view.annotation?.title, let imageName = title else { return }

            if imageName.starts(with: "base64:") {

                onAnnotationTapped(imageName)
            }

            mapView.deselectAnnotation(view.annotation, animated: false)
        }
    }
}
