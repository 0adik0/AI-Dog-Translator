import ActivityKit
import WidgetKit
import SwiftUI
import CoreLocation

struct DogWalkWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {

        ActivityConfiguration(for: DogWalkActivityAttributes.self) { context in

            LockScreenLiveActivityView(context: context)

        } dynamicIsland: { context in

            if context.isStale {

                DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        Text(formatDuration(context.state.duration))
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        Text("Walk Finished! \(formatDistance(context.state.distance))")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                } compactLeading: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } compactTrailing: {
                    Text(formatDistance(context.state.distance))
                        .font(.caption)
                        .foregroundColor(.white)
                } minimal: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }

            } else {

                DynamicIsland {
                    DynamicIslandExpandedRegion(.leading) {
                        Image(systemName: "pawprint.fill")
                            .font(.title2)
                            .foregroundColor(.appBlue)
                    }
                    DynamicIslandExpandedRegion(.trailing) {
                        Label {
                            Text(formatDuration(context.state.duration))
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        } icon: {
                            Image(systemName: "hourglass")
                                .foregroundColor(.appBlue)
                        }
                    }
                    DynamicIslandExpandedRegion(.bottom) {
                        VStack(alignment: .leading) {
                            Text("Walking with \(context.attributes.dogName)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)

                            Text("Distance: \(formatDistance(context.state.distance))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 4)
                    }
                } compactLeading: {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.appBlue)
                } compactTrailing: {
                    Text(formatDuration(context.state.duration))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                } minimal: {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.appBlue)
                }
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<DogWalkActivityAttributes>

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                .gradientStart,
                .gradientEnd
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {

        if context.isStale {

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundColor(.appBlue)
                    Text("Walk Finished!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.appBlue)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }

                Text("Nice walk with \(context.attributes.dogName)!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appPurple)

                HStack {
                    Spacer()
                    VStack {
                        Text("Total Distance")
                            .font(.caption)
                            .foregroundColor(.appPurple)
                        Text(formatDistance(context.state.distance))
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.appBlue)
                    }
                    Spacer()
                    VStack {
                        Text("Total Time")
                            .font(.caption)
                            .foregroundColor(.appPurple)
                        Text(formatDuration(context.state.duration))
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.appBlue)
                    }
                    Spacer()
                }
                .padding(.top, 5)
            }
            .padding(20)
            .background(backgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))

        } else {

            VStack(alignment: .leading, spacing: 12) {

                HStack {
                    Image(systemName: "pawprint.fill")
                    Text("Walking with \(context.attributes.dogName)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Spacer()
                }
                .foregroundColor(.appBlue)

                HStack(spacing: 24) {
                    Spacer()

                    VStack {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.appPurple)
                        Text(formatDuration(context.state.duration))
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.appBlue)
                    }
                    Spacer()

                    VStack {
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.appPurple)
                        Text(formatDistance(context.state.distance))
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.appBlue)
                    }
                    Spacer()
                }
            }
            .padding(20)
            .background(backgroundGradient)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

private func formatDistance(_ distance: CLLocationDistance) -> String {
    return String(format: "%.2f KM", distance / 1000)
}

private func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60
    if hours > 0 {
        return String(format: "%02d:%02d", hours, minutes)
    } else {
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
