import SwiftUI

struct MemoryDetailView: View {
    let memory: MemoryItem
    @ObservedObject var viewModel: DogViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        MainBackgroundView {
            VStack {

                CustomHeader(title: "Memory", showBackButton: true) {
                    dismiss()
                }
                .padding(.horizontal, 10)

                Spacer()

                VStack(spacing: 0) {
                    Text(memory.dateFormatted)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)

                    if let uiImage = memory.uiImage {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(Image(systemName: "pawprint.fill").foregroundColor(.gray))
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: .appPurple.opacity(0.2), radius: 5, y: 3)
                .padding(.horizontal, 20)

                HStack(spacing: 30) {
                    actionButton(icon: "trash.fill", action: deleteMemory)
                }
                .padding(.top, 40)

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }

    private func actionButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .frame(width: 64, height: 64)
                .foregroundColor(.white)
                .background(Color.appBlue)
                .clipShape(Circle())
                .shadow(color: .appPurple.opacity(0.5), radius: 10, y: 5)
        }
    }

    private func deleteMemory() {
        viewModel.deleteMemory(memory: memory)
        dismiss()
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
