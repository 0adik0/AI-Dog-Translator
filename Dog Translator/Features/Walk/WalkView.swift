import SwiftUI
import CoreLocation
import MapKit

struct WalkView: View {

    @ObservedObject var viewModel: DogViewModel

    @State private var navigateToDogSelection = false

    @State private var recordToPush: WalkRecord? = nil
    @State private var showLastWalk: Bool = false

    var body: some View {
        NavigationStack {
            MainBackgroundView {

                ZStack {

                    NavigationLink(
                        destination: DogSelectionView(viewModel: viewModel),
                        isActive: $navigateToDogSelection
                    ) { EmptyView() }
                        .opacity(0)

                    if let record = recordToPush {
                        NavigationLink(
                            destination: WalkDetailView(viewModel: viewModel, record: record),
                            isActive: $showLastWalk
                        ) { EmptyView() }
                            .opacity(0)
                    }

                    VStack(spacing: 0) {

                        dogHouseBanner

                        Spacer().frame(height: 10)

                        ScrollView {
                            LazyVStack(spacing: 15) {

                                if viewModel.walkState != .ready, let dog = viewModel.currentWalkingDog {
                                    CurrentWalkRow()
                                        .environmentObject(viewModel)
                                        .onTapGesture {

                                            viewModel.showCurrentWalk = true
                                        }
                                }

                                if viewModel.walkHistory.isEmpty {

                                    if viewModel.walkState == .ready {
                                        Text("Your walk history is empty.\nPress 'Start New Walk' to begin!")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(40)
                                            .background(Color.elementBackground)
                                            .cornerRadius(20)
                                    }
                                } else {
                                    ForEach(viewModel.walkHistory) { record in
                                        NavigationLink(destination: WalkDetailView(viewModel: viewModel, record: record)) {
                                            WalkHistoryRow(record: record)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .padding(.bottom, 20)
                        }
                    }
                    .safeAreaInset(edge: .bottom) {

                        if viewModel.walkState == .ready {
                            startNewWalkButton
                                .padding(20)
                        } else {
                            Color.clear.frame(height: 20)
                        }
                    }
                }

                .task(id: viewModel.lastCompletedWalk) {

                    if let record = viewModel.lastCompletedWalk {
                        print("✅ [WalkView.task] Обнаружена 'lastCompletedWalk'. Показываю WalkDetailView.")
                        self.recordToPush = record
                        self.showLastWalk = true

                        viewModel.lastCompletedWalk = nil
                    }
                }
            }
        }
    }

    private var startNewWalkButton: some View {
        Button(action: handleStartWalkTapped) {
            Text("Start New Walk")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.appBlue)
                .clipShape(Capsule())
                .shadow(color: .appPurple.opacity(0.4), radius: 10, y: 5)
        }
    }

    private func handleStartWalkTapped() {
        if viewModel.canStartWalk() {
            navigateToDogSelection = true
        } else {
            viewModel.showPaywall = true
        }
    }

    private var dogHouseBanner: some View {
        NavigationLink(destination: DogHouseView(viewModel: viewModel)) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .center, spacing: 8) {
                    Text("Dog House")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 6)
                        .background( Capsule().fill(Color.appBlue) )

                    Text("Manage all your dogs")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.black.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.leading, 10)

                Spacer()

                Image("dog_banner")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .offset(x: 10, y: 20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.gradientStart, .gradientEnd]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay( RoundedRectangle(cornerRadius: 24).stroke(Color.appBlue, lineWidth: 2) )
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WalkHistoryRow: View {
    let record: WalkRecord

    var body: some View {
        HStack(spacing: 15) {
            Group {
                if let data = record.dogProfileImageData, let uiImage = UIImage(data: data) {
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
                Text(record.dogName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(record.dateFormatted)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(record.durationFormatted)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Duration")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(20)
        .background(Color.appBlue)
        .cornerRadius(24)
    }
}

struct CurrentWalkRow: View {

    @EnvironmentObject var viewModel: DogViewModel

    private var durationFormatted: String {
        let walkDuration = viewModel.walkDuration
        let hours = Int(walkDuration) / 3600
        let minutes = (Int(walkDuration) % 3600) / 60
        let seconds = Int(walkDuration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    var body: some View {
        HStack(spacing: 15) {

            Group {
                if let data = viewModel.currentWalkingDog?.profileImageData, let uiImage = UIImage(data: data) {
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
                Text(viewModel.currentWalkingDog?.name ?? "Walking...")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Walk in Progress...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(durationFormatted)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Duration")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(20)
        .background(Color.appPurple)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white, lineWidth: 2)
        )
    }
}

#Preview {
    WalkView(viewModel: DogViewModel())
}
