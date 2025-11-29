import Foundation
import CoreLocation
import MapKit
import SwiftUI

struct WalkAnnotation: Identifiable {
    let id: UUID
    let imageName: String
    let coordinate: CLLocationCoordinate2D

    init(id: UUID = UUID(), imageName: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.imageName = imageName
        self.coordinate = coordinate
    }

    var decodedImage: UIImage? {
        guard imageName.starts(with: "base64:") else {
            return nil
        }
        let base64String = String(imageName.dropFirst("base64:".count))
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: data)
    }
}

struct CodableCoordinate: Codable, Identifiable, Equatable {
    let id = UUID()
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    init() {
        self.latitude = 0
        self.longitude = 0
    }
}

struct WalkAnnotationCodable: Codable, Identifiable, Equatable {
    let id: UUID
    let imageName: String
    let coordinate: CodableCoordinate

    init(from annotation: WalkAnnotation) {
        self.id = annotation.id
        self.imageName = annotation.imageName
        self.coordinate = CodableCoordinate(coordinate: annotation.coordinate)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.imageName = try container.decodeIfPresent(String.self, forKey: .imageName) ?? "pawprint.fill"
        self.coordinate = try container.decodeIfPresent(CodableCoordinate.self, forKey: .coordinate) ?? CodableCoordinate()
    }

    private enum CodingKeys: String, CodingKey {
        case id, imageName, coordinate
    }

    var decodedImage: UIImage? {
        guard imageName.starts(with: "base64:") else {
            return nil
        }
        let base64String = String(imageName.dropFirst("base64:".count))
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: data)
    }
}

struct WalkRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let dogName: String
    let duration: TimeInterval
    let date: Date
    let dogProfileImageData: Data?
    let routeCoordinates: [CodableCoordinate]
    let annotations: [WalkAnnotationCodable]

    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var dateFormatted: String {
        Self.cachedDateFormatter.string(from: date)
    }

    private static let cachedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter
    }()

    init(dog: Dog, duration: TimeInterval, route: [CLLocationCoordinate2D], annotations: [WalkAnnotation]) {
        self.id = UUID()
        self.dogName = dog.name
        self.duration = duration
        self.date = Date()
        self.dogProfileImageData = dog.profileImageData
        self.routeCoordinates = route.map { CodableCoordinate(coordinate: $0) }
        self.annotations = annotations.map { WalkAnnotationCodable(from: $0) }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        dogName = try container.decodeIfPresent(String.self, forKey: .dogName) ?? "Unknown Dog"
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration) ?? 0
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        dogProfileImageData = try container.decodeIfPresent(Data.self, forKey: .dogProfileImageData)
        routeCoordinates = try container.decodeIfPresent([CodableCoordinate].self, forKey: .routeCoordinates) ?? []
        annotations = try container.decodeIfPresent([WalkAnnotationCodable].self, forKey: .annotations) ?? []
    }
}
