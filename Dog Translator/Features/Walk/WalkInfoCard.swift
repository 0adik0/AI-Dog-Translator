import SwiftUI

struct WalkInfoCard: View {
    let iconName: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .background(Color.appBlue)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.appBlue.opacity(0.3), radius: 5, y: 3)

            VStack(spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.appPurple)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.elementBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }
}

struct CircleButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.3), radius: 10, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
