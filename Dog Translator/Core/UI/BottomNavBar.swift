import SwiftUI

struct BottomNavBar: View {
    @Binding var selectedTab: MainTabView.Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                Spacer()
                ZStack {
                    if selectedTab == tab {
                        Circle()
                            .fill(Color.appPurple.opacity(0.15))
                            .frame(width: 50, height: 50)
                            .shadow(color: Color.appPurple.opacity(0.3), radius: 6, y: 2)
                            .transition(.scale)
                    }

                    Image(systemName: tab.iconName)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .appPurple : .gray)
                        .scaleEffect(selectedTab == tab ? 1.15 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: selectedTab)
                }
                .padding(.vertical, 10)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 10, y: 2)
        )
        .padding(.horizontal, 16)
    }
}

extension MainTabView.Tab {
    var iconName: String {
        switch self {
        case .sounds: return "waveform"
        case .translator: return "text.bubble"
        case .generator: return "wand.and.stars"
        case .walk: return "figure.walk"
        case .memory: return "brain.head.profile"
        }
    }
}
