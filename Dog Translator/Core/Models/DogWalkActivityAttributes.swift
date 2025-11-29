import ActivityKit
import Foundation
import CoreLocation

struct DogWalkActivityAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        var duration: TimeInterval
        var distance: CLLocationDistance
    }

    var dogName: String
}
