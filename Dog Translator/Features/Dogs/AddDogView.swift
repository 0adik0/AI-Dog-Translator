import SwiftUI
import PhotosUI

struct AddDogView: View {
    @ObservedObject var viewModel: DogViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var dog: Dog
    private var isEditing: Bool
    private var viewTitle: String

    @State private var selectedPhotoItem: PhotosPickerItem?

    init(viewModel: DogViewModel) {
        self.viewModel = viewModel
        self._dog = State(initialValue: Dog.emptyDog())
        self.isEditing = false
        self.viewTitle = "Add Dog"
    }

    init(viewModel: DogViewModel, dogToEdit: Dog) {
        self.viewModel = viewModel
        self._dog = State(initialValue: dogToEdit)
        self.isEditing = true
        self.viewTitle = "Edit Dog"
    }

    var body: some View {
        MainBackgroundView {
            VStack(spacing: 0) {

                HStack {
                    Button(action: { dismiss() }) {
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
                            .shadow(color: .appPurple.opacity(0.4), radius: 10, y: 4)
                    }
                    Spacer()
                    Text(viewTitle)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBlue)
                    Spacer()
                    Button(action: saveDog) {
                        Text("Save")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.appBlue)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 10)

                ScrollView {
                    VStack(spacing: 20) {

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            ZStack {
                                if let image = dog.profileImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else {
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                            }
                            .frame(width: 150, height: 150)
                            .background(.white.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 30))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.appBlue, lineWidth: 2)
                            )
                        }
                        .padding(.top, 20)

                        FormSection {
                            FormRow(icon: "house.fill", title: "Name")
                            TextField("Enter dog's name", text: $dog.name)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.leading, 38)
                            Divider()

                            FormRow(icon: "gift.fill", title: "Birthday")

                            CustomDatePicker(selectedDate: $dog.birthday)
                                .padding(.top, 8)
                                .padding(.leading, 38)
                                .padding(.trailing, 20)

                            Divider()
                            FormRow(icon: "book.fill", title: "Breed")
                            TextField("Enter dog's breed", text: $dog.breed)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.leading, 38)
                            Divider()
                            FormRow(icon: dog.gender.icon, title: "Gender")
                            Picker("Select dog's gender", selection: $dog.gender) {
                                ForEach(Dog.Gender.allCases, id: \.self) { gender in
                                    Text(gender.rawValue).tag(gender)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.leading, 38)
                        }

                        FormSection {
                            FormRow(icon: "stethoscope", title: "Vet's Name")
                            TextField("Enter vet's name", text: $dog.vetName)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.leading, 38)
                            Divider()
                            FormRow(icon: "phone.fill", title: "Vet's Phone")
                            TextField("Enter vet's phone number", text: $dog.vetPhone)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.leading, 38)
                                .keyboardType(.phonePad)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Notes")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.appBlue)

                            TextEditor(text: $dog.notes)
                                .font(.system(size: 16, weight: .medium))
                                .frame(height: 150)
                                .padding(10)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.appBlue.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    dog.profileImageData = data
                }
            }
        }
    }

    private func saveDog() {
        if isEditing {
            viewModel.updateDog(dog)
        } else {
            viewModel.addDog(dog)
        }
        dismiss()
    }
}

struct CustomDatePicker: View {
    @Binding var selectedDate: Date

    private let calendar = Calendar.current
    private let days = Array(1...31)
    private let months = Array(1...12)
    private let years = Array(1970...Calendar.current.component(.year, from: Date()))

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 10) {
                dateSegment(values: days, component: .day, width: geo.size.width * 0.22)
                dateSegment(values: months, component: .month, width: geo.size.width * 0.22)
                dateSegment(values: years, component: .year, width: geo.size.width * 0.35)
            }
            .frame(height: 50)
            .padding(10)
            .background(Color.white.opacity(0.9))
            .cornerRadius(16)
            .shadow(color: Color.appPurple.opacity(0.15), radius: 8, y: 4)
        }
        .frame(height: 70)
    }

    private func dateSegment(values: [Int], component: Calendar.Component, width: CGFloat) -> some View {
        Menu {
            ForEach(values, id: \.self) { value in
                Button(action: { updateDate(value, for: component) }) {
                    Text(label(for: value, component: component))
                }
            }
        } label: {
            Text(label(for: value(of: component), component: component))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appBlue)
                .frame(width: width, height: 40)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.appBlue.opacity(0.3), lineWidth: 1.2)
                )
                .cornerRadius(10)
                .shadow(color: .appPurple.opacity(0.15), radius: 4, y: 2)
        }
    }

    private func label(for value: Int, component: Calendar.Component) -> String {
        switch component {
        case .day, .month:
            return String(format: "%02d", value)
        case .year:
            return "\(value)"
        default:
            return ""
        }
    }

    private func value(of component: Calendar.Component) -> Int {
        calendar.component(component, from: selectedDate)
    }

    private func updateDate(_ newValue: Int, for component: Calendar.Component) {
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        switch component {
        case .day: components.day = newValue
        case .month: components.month = newValue
        case .year: components.year = newValue
        default: break
        }
        if let newDate = calendar.date(from: components) {
            selectedDate = newDate
        }
    }
}

struct FormSection<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 12) { content }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.elementBackground)
                    .shadow(color: .appPurple.opacity(0.15), radius: 5, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.appBlue.opacity(0.5), lineWidth: 1)
            )
            .padding(.horizontal, 20)
    }
}

struct FormRow: View {
    let icon: String
    let title: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.appBlue)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.appBlue)
            Spacer()
        }
    }
}
