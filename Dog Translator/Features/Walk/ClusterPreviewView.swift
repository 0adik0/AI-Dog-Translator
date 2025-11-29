import SwiftUI

struct ClusterPreviewView: View {
    let photoCount: Int
    let emojiNames: [String]

    var onPhotoTapped: (() -> Void)? = nil

    private var emojiCounts: [(name: String, count: Int)] {
        let countedSet = NSCountedSet(array: emojiNames)
        return countedSet.allObjects.compactMap { obj -> (name: String, count: Int)? in
            guard let name = obj as? String else { return nil }
            return (name: name, count: countedSet.count(for: obj))
        }.sorted(by: { $0.count > $1.count })
    }

    var body: some View {

        HStack(spacing: 10) {

            if photoCount > 0 {
                Button(action: {
                    onPhotoTapped?()
                }) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Image(systemName: "photo.fill")
                        Text("\(photoCount)")
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }

            if photoCount > 0 && !emojiCounts.isEmpty {
                Divider()
                    .frame(height: 20)
            }

            if !emojiCounts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(emojiCounts, id: \.name) { item in
                            HStack(spacing: 4) {
                                Image(item.name)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)

                                if item.count > 1 {
                                    Text("x\(item.count)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.appBlue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.7))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 150)
            }
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundColor(.appBlue)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.elementBackground)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
