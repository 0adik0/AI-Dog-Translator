import Foundation
import SwiftUI

struct MemoryItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let imageData: Data

    init(imageData: Data) {
        self.id = UUID()
        self.date = Date()
        self.imageData = imageData
    }

    var uiImage: UIImage? {
        UIImage(data: imageData)
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
