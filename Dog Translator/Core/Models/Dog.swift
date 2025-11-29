import Foundation
import SwiftUI

struct Dog: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var birthday: Date
    var breed: String
    var gender: Gender
    var vetName: String = ""
    var vetPhone: String = ""
    var notes: String = ""
    var profileImageData: Data?

    enum Gender: String, CaseIterable, Codable {
        case male = "Male"
        case female = "Female"

        var icon: String {
            switch self {
            case .male: return "person.fill"
            case .female: return "person.crop.circle.fill"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, birthday, breed, gender, vetName, vetPhone, notes, profileImageData
    }

    init(id: UUID = UUID(),
         name: String,
         birthday: Date,
         breed: String,
         gender: Gender,
         vetName: String = "",
         vetPhone: String = "",
         notes: String = "",
         profileImageData: Data? = nil) {
        self.id = id
        self.name = name
        self.birthday = birthday
        self.breed = breed
        self.gender = gender
        self.vetName = vetName
        self.vetPhone = vetPhone
        self.notes = notes
        self.profileImageData = profileImageData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)

        if let dateString = try? container.decode(String.self, forKey: .birthday) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "d MMM yyyy"
            birthday = formatter.date(from: dateString) ?? Date()
        } else if let timestamp = try? container.decode(Double.self, forKey: .birthday) {
            birthday = Date(timeIntervalSince1970: timestamp)
        } else {
            birthday = Date()
        }

        breed = try container.decode(String.self, forKey: .breed)
        gender = try container.decode(Gender.self, forKey: .gender)
        vetName = try container.decodeIfPresent(String.self, forKey: .vetName) ?? ""
        vetPhone = try container.decodeIfPresent(String.self, forKey: .vetPhone) ?? ""
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        profileImageData = try container.decodeIfPresent(Data.self, forKey: .profileImageData)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        let dateString = formatter.string(from: birthday)
        try container.encode(dateString, forKey: .birthday)

        try container.encode(breed, forKey: .breed)
        try container.encode(gender, forKey: .gender)
        try container.encode(vetName, forKey: .vetName)
        try container.encode(vetPhone, forKey: .vetPhone)
        try container.encode(notes, forKey: .notes)
        try container.encode(profileImageData, forKey: .profileImageData)
    }

    static func emptyDog() -> Dog {
        Dog(name: "", birthday: Date(), breed: "", gender: .male)
    }

    static func dummyDog() -> Dog {
            let dummyImage = UIImage(named: "img10")

            let dummyData = dummyImage?.pngData()

            return Dog(name: "Buddy",
                       birthday: Calendar.current.date(from: DateComponents(year: 2022, month: 5, day: 20))!,
                       breed: "Corgi",
                       gender: .male,
                       vetName: "Dr. Smith",
                       profileImageData: dummyData)
        }

    var profileImage: UIImage? {
        guard let data = profileImageData else { return nil }
        return UIImage(data: data)
    }
}
