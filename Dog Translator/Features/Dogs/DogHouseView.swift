import SwiftUI
import Combine

struct DogHouseView: View {

    @ObservedObject var viewModel: DogViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var navigateToAddDog = false

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
                            .shadow(color: Color.appPurple.opacity(0.4), radius: 10, y: 4)
                    }
                    Spacer()
                    Text("Dog House")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBlue)
                    Spacer()
                    Rectangle().frame(width: 44, height: 44).opacity(0)
                }
                .padding(.horizontal, 10)

                Image("dog_house_header")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)

                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.dogs) { dog in
                            NavigationLink(
                                destination: AddDogView(viewModel: viewModel, dogToEdit: dog)
                            ) {
                                DogRowView(dog: dog)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 90)
                }
            }
            .safeAreaInset(edge: .bottom) {

                ZStack {

                    NavigationLink(
                        destination: AddDogView(viewModel: viewModel),
                        isActive: $navigateToAddDog
                    ) { EmptyView() }
                        .opacity(0)

                    Button(action: handleAddDog) {
                        Text("Add Dog")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.appBlue)
                            .clipShape(Capsule())
                            .shadow(color: .appPurple.opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func handleAddDog() {

        if viewModel.canAddDog() {

            navigateToAddDog = true
        } else {

            viewModel.showPaywall = true
        }
    }
}

struct DogRowView: View {

    let dog: Dog

    var body: some View {
        HStack(spacing: 15) {
            Group {
                if let uiImage = dog.profileImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "pawprint.circle.fill")
                        .resizable()
                        .foregroundColor(.white.opacity(0.7))
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 3))

            VStack(alignment: .leading, spacing: 6) {
                Text(dog.name)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack {
                    Image(systemName: "gift.fill")
                    Text(dog.birthday.formattedDogDate)
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

                HStack {
                    Image(systemName: dog.gender.icon)
                    Text(dog.gender.rawValue)
                }
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            }

            Spacer()
        }
        .padding(20)
        .background(Color.appBlue)
        .cornerRadius(24)
    }
}

#Preview {

    NavigationView {
        DogHouseView(viewModel: {
            let vm = DogViewModel()
            vm.dogs = [
                Dog.dummyDog(),
                Dog(name: "Lucy",
                    birthday: Calendar.current.date(from: DateComponents(year: 2021, month: 12, day: 2))!,
                    breed: "Labrador",
                    gender: .female)
            ]
            return vm
        }())
    }
}

extension Date {

    var formattedDogDate: String {
        Date.cachedDogFormatter.string(from: self)
    }

    private static let cachedDogFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
}
