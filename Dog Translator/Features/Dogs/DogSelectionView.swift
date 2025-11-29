import SwiftUI

struct DogSelectionView: View {

    @ObservedObject var viewModel: DogViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDogIDs: [UUID] = []

    private var selectedDogs: [Dog] {
        viewModel.dogs.filter { selectedDogIDs.contains($0.id) }
    }

    var body: some View {
        MainBackgroundView {
            VStack(spacing: 20) {

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
                    Text("Select Dog")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.appBlue)
                    Spacer()
                    Rectangle().frame(width: 44, height: 44).opacity(0)
                }
                .padding(.horizontal, 10)

                ScrollView {
                    LazyVStack(spacing: 15) {
                        if viewModel.dogs.isEmpty {
                            Text("No dogs found.\nGo to the 'Sounds' tab and add a dog in the 'Dog House'.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(40)
                                .background(Color.elementBackground)
                                .cornerRadius(20)
                        } else {
                            ForEach(viewModel.dogs) { dog in
                                SelectableDogRow(
                                    dog: dog,
                                    isSelected: selectedDogIDs.contains(dog.id),
                                    action: {
                                        withAnimation(.spring()) {
                                            toggleSelection(for: dog.id)
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }

                Spacer()
            }
            .safeAreaInset(edge: .bottom) {
                startButton
                    .padding(20)
            }
        }
        .navigationBarHidden(true)

        .onAppear {
            viewModel.walkJustFinished = false
        }

        .onChange(of: viewModel.walkJustFinished) { _, newValue in
            if newValue == true {
                print("✅ [DogSelectionView] Обнаружен 'walkJustFinished'. Закрываюсь.")
                dismiss()
            }
        }
        .onChange(of: viewModel.showCurrentWalk) { _, newValue in
            if newValue == true {
                print("✅ [DogSelectionView] Обнаружен 'showCurrentWalk'. Закрываюсь.")
                dismiss()
            }
        }
    }

    @ViewBuilder
    private var startButton: some View {

        let currentSelectedDog = selectedDogs.first

        if let dog = currentSelectedDog {

            Button(action: {
                print("[DogSelectionView] Нажата кнопка Start Walk.")

                viewModel.startWalk(dog: dog)

                viewModel.showCurrentWalk = true

            }) {
                Text("Start Walk")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appBlue)
                    .clipShape(Capsule())
                    .shadow(color: .appPurple.opacity(0.4), radius: 10, y: 5)
            }
        } else {

            Text(selectedDogs.isEmpty ? "Select a Dog" : "Select Only One Dog")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.gray.opacity(0.5))
                .clipShape(Capsule())
        }
    }

    private func toggleSelection(for id: UUID) {
        if selectedDogIDs.contains(id) {
            selectedDogIDs.removeAll()
        } else {
            selectedDogIDs = [id]
        }
    }
}

struct SelectableDogRow: View {
    let dog: Dog
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))

                VStack(alignment: .leading, spacing: 4) {
                    Text(dog.name)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if !dog.breed.isEmpty {
                        Text(dog.breed)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    HStack(spacing: 4) {
                        Image(systemName: dog.gender.icon)
                        Text(dog.gender.rawValue)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(Color.appBlue)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(isSelected ? Color.appPurple : Color.clear, lineWidth: 4)
            )
            .shadow(color: .appPurple.opacity(isSelected ? 0.3 : 0.1), radius: 5, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DogSelectionView(viewModel: DogViewModel())
}
