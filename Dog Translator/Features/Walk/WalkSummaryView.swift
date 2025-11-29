import SwiftUI

struct WalkSummaryView: View {

    let distance: String
    let duration: String
    let dogName: String

    @Environment(\.dismiss) var dismissSheet

    @State private var showShareSheet = false

    private var shareText: String {
        "Just finished walking \(dogName)! We covered \(distance) in \(duration). 🐾"
    }

    var body: some View {
        VStack(spacing: 30) {

            Spacer()

            Text("Walk Summary")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.appBlue)

            VStack(spacing: 20) {
                SummaryRow(icon: "flag.fill", label: "Distance:", value: distance)
                SummaryRow(icon: "hourglass", label: "Duration:", value: duration)
            }
            .padding(25)
            .background(Color.elementBackground)
            .cornerRadius(25)
            .shadow(color: .appPurple.opacity(0.2), radius: 10, y: 5)
            .padding(.horizontal, 40)

            Spacer()

            HStack(spacing: 20) {

                Button {
                    dismissSheet()
                } label: {
                    Label("Close", systemImage: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.appBlue)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.elementBackground)
                        .clipShape(Capsule())
                        .shadow(color: .appPurple.opacity(0.15), radius: 5, y: 2)
                        .overlay(Capsule().stroke(Color.appBlue.opacity(0.5), lineWidth: 1))
                }

                Button {
                    showShareSheet = true
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(Color.appBlue)
                        .clipShape(Capsule())
                        .shadow(color: .appPurple.opacity(0.3), radius: 8, y: 4)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appPurple)
                .frame(width: 30)
            Text(label)
                .font(.system(size: 18))
                .foregroundColor(.appBlue)
            Spacer()
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appPurple)
        }
    }
}

#Preview {
    WalkSummaryView(distance: "1.23 KM", duration: "00:15:30", dogName: "Buddy")
}
