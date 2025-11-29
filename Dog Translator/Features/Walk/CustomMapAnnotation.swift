import SwiftUI
import MapKit
import CoreLocation

class CustomMapAnnotation: NSObject, MKAnnotation {
    let id: UUID
    let imageName: String
    @objc dynamic var coordinate: CLLocationCoordinate2D

    let isPhoto: Bool
    let decodedImage: UIImage?

    init(from walkAnnotation: WalkAnnotation) {
        self.id = walkAnnotation.id
        self.imageName = walkAnnotation.imageName
        self.coordinate = walkAnnotation.coordinate

        if imageName.starts(with: "base64:") {
            self.isPhoto = true
            let base64String = String(imageName.dropFirst("base64:".count))
            if let data = Data(base64Encoded: base64String) {
                self.decodedImage = UIImage(data: data)
            } else {
                self.decodedImage = nil
            }
        } else {
            self.isPhoto = false
            self.decodedImage = nil
        }

        super.init()
    }
}

final class CustomAnnotationView: MKAnnotationView {

    override var annotation: MKAnnotation? {
        willSet {
            clusteringIdentifier = "walk-item"
        }
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        collisionMode = .circle
        update(for: annotation)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(for annotation: MKAnnotation?) {
        guard let customAnnotation = annotation as? CustomMapAnnotation else { return }
        subviews.forEach { $0.removeFromSuperview() }

        if customAnnotation.isPhoto {
            self.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
            let imageView = UIImageView(frame: self.bounds)
            imageView.image = customAnnotation.decodedImage ?? UIImage(systemName: "photo.fill")
            imageView.contentMode = .scaleAspectFill
            imageView.layer.cornerRadius = 22
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.borderWidth = 2
            imageView.clipsToBounds = true
            self.addSubview(imageView)
            self.displayPriority = .required
        } else {
            self.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
            let imageView = UIImageView(frame: self.bounds)
            imageView.image = UIImage(named: customAnnotation.imageName)
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            self.addSubview(imageView)
            self.displayPriority = .required
        }
        self.centerOffset = CGPoint(x: 0, y: -self.frame.height / 2)
    }
}

final class ClusterAnnotationView: MKAnnotationView {
    let label = UILabel()
    var hostingController: UIHostingController<ClusterPreviewView>?
    var clusterPhotos: [UIImage] = []

    override var annotation: MKAnnotation? {
        didSet {
            update(for: annotation)
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews {
            let convertedPoint = subview.convert(point, from: self)
            if subview.point(inside: convertedPoint, with: event) {
                return true
            }
        }
        return super.point(inside: point, with: event)
    }

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)

        collisionMode = .circle
        canShowCallout = false
        frame = CGRect(x: 0, y: 0, width: 44, height: 44)

        backgroundColor = UIColor(Color.appBlue).withAlphaComponent(0.9)
        layer.cornerRadius = 22
        layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        layer.borderWidth = 2

        label.frame = bounds
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        addSubview(label)

        update(for: annotation)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(for annotation: MKAnnotation?) {
        guard let cluster = annotation as? MKClusterAnnotation else { return }
        label.text = "\(cluster.memberAnnotations.count)"

        hostingController?.view.removeFromSuperview()
        hostingController = nil
    }
}

struct RouteOverlayView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let route: [CLLocationCoordinate2D]
    let annotations: [WalkAnnotation]
    let isTrackingUser: Bool

    var onPhotoTapped: (UUID) -> Void
    var onClusterTapped: () -> Void
    var onClusterPhotoTapped: (UUID) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.isUserInteractionEnabled = true
        mapView.showsUserLocation = true

        mapView.register(
            CustomAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier
        )
        mapView.register(
            ClusterAnnotationView.self,
            forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier
        )

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        let currentTrackingMode = uiView.userTrackingMode
        if isTrackingUser && currentTrackingMode != .follow {
            uiView.setUserTrackingMode(.follow, animated: true)
        } else if !isTrackingUser && currentTrackingMode != .none {
            uiView.setUserTrackingMode(.none, animated: true)
        }

        if !isTrackingUser && region.span.latitudeDelta > 0.0001 {
             uiView.setRegion(region, animated: true)
        }

        uiView.overlays.forEach { uiView.removeOverlay($0) }
        if route.count > 1 {
            let polyline = MKPolyline(coordinates: route, count: route.count)
            uiView.addOverlay(polyline)
        }

        let oldAnnotations = uiView.annotations.compactMap { $0 as? CustomMapAnnotation }
        let oldIDs = Set(oldAnnotations.map { $0.id })
        let newIDs = Set(annotations.map { $0.id })

        let toRemove = oldAnnotations.filter { !newIDs.contains($0.id) }
        let toAdd = annotations
            .filter { !oldIDs.contains($0.id) }
            .map { CustomMapAnnotation(from: $0) }

        uiView.removeAnnotations(toRemove)
        uiView.addAnnotations(toAdd)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteOverlayView

        init(_ parent: RouteOverlayView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(Color.appBlue.opacity(0.8))
                renderer.lineWidth = 6
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }

            if let clusterAnnotation = annotation as? MKClusterAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: clusterAnnotation) as? ClusterAnnotationView
                return view
            }

            if let customAnnotation = annotation as? CustomMapAnnotation {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: customAnnotation) as? CustomAnnotationView
                view?.update(for: customAnnotation)
                return view
            }
            return nil
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let clusterView = view as? ClusterAnnotationView,
                  let cluster = clusterView.annotation as? MKClusterAnnotation else {
                if let custom = view.annotation as? CustomMapAnnotation, custom.isPhoto {
                    parent.onPhotoTapped(custom.id)
                    mapView.deselectAnnotation(view.annotation, animated: false)
                }
                return
            }

            parent.onClusterTapped()

            var photoCount = 0
            var emojiNames: [String] = []

            var photoAnnotations: [CustomMapAnnotation] = []

            for member in cluster.memberAnnotations {
                if let m = member as? CustomMapAnnotation {
                    if m.isPhoto {
                        photoCount += 1
                        photoAnnotations.append(m)
                    } else {
                        emojiNames.append(m.imageName)
                    }
                }
            }

            let photosForPreview = photoAnnotations.compactMap { $0.decodedImage }
            clusterView.clusterPhotos = photosForPreview

            let preview = ClusterPreviewView(
                photoCount: photoCount,
                emojiNames: emojiNames,
                onPhotoTapped: { [weak self] in
                    if let firstID = photoAnnotations.first?.id {
                        self?.parent.onClusterPhotoTapped(firstID)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        mapView.deselectAnnotation(view.annotation, animated: false)
                    }
                }
            )

            let hosting = UIHostingController(rootView: preview)
            hosting.view.backgroundColor = .clear
            hosting.view.isUserInteractionEnabled = true

            clusterView.hostingController?.view.removeFromSuperview()
            clusterView.hostingController = hosting

            let tap = UITapGestureRecognizer(target: self, action: #selector(handleClusterPreviewTap(_:)))
            hosting.view.addGestureRecognizer(tap)

            clusterView.addSubview(hosting.view)
            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hosting.view.centerXAnchor.constraint(equalTo: clusterView.centerXAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: clusterView.topAnchor, constant: -10)
            ])
        }

        @objc private func handleClusterPreviewTap(_ sender: UITapGestureRecognizer) {
            guard let hostingView = sender.view,
                  let clusterView = hostingView.superview as? ClusterAnnotationView,
                  let cluster = clusterView.annotation as? MKClusterAnnotation
            else { return }

            let firstPhotoID = cluster.memberAnnotations
                .compactMap { $0 as? CustomMapAnnotation }
                .first(where: { $0.isPhoto })?
                .id

            if let firstPhotoID = firstPhotoID {
                parent.onClusterPhotoTapped(firstPhotoID)
            }

            if let mapView = hostingView.findSuperview(of: MKMapView.self),
               let annotation = clusterView.annotation {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    mapView.deselectAnnotation(annotation, animated: false)
                }
            }
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if let clusterView = view as? ClusterAnnotationView {
                clusterView.hostingController?.view.removeFromSuperview()
                clusterView.hostingController = nil
            }
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            if let selectedAnnotation = mapView.selectedAnnotations.first {
                mapView.deselectAnnotation(selectedAnnotation, animated: true)
            }

            let panGesture = mapView.gestureRecognizers?.first(where: { $0 is UIPanGestureRecognizer })
            if let panGesture = panGesture, panGesture.state == .began {
                mapView.setUserTrackingMode(.none, animated: true)
            }
        }
    }
}

private extension UIView {
    func findSuperview<T: UIView>(of type: T.Type) -> T? {
        var v: UIView? = self
        while let cur = v {
            if let t = cur as? T { return t }
            v = cur.superview
        }
        return nil
    }
}
