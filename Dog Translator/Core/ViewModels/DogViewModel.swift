import Foundation
import Combine
import SwiftUI
import CoreLocation
import MapKit
import ActivityKit

final class DogViewModel: ObservableObject {

    @AppStorage("isProUser") var isProUser: Bool = false
    @Published var showPaywall: Bool = false

    @AppStorage("freeTranslationsUsed") var freeTranslationsUsed: Int = 0
    @AppStorage("freeWalksUsed") var freeWalksUsed: Int = 0
    @AppStorage("freeMemoriesUsed") var freeMemoriesUsed: Int = 0
    @AppStorage("freeSoundsUsed") var freeSoundsUsed: Int = 0

    let maxFreeTranslations = 2
    let maxFreeWalks = 2
    let maxFreeMemories = 3
    let maxFreeSounds = 5
    let maxFreeDogs = 3

    @Published var dogs: [Dog] = []
    @Published var walkHistory: [WalkRecord] = []
    @Published var memories: [MemoryItem] = []

    private var dogsFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("savedDogs.json")
    }

    private var historyFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("walkHistory.json")
    }

    private var memoriesFileURL: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("dogMemories.json")
    }

    let locationManager = LocationManager()

    @Published var walkState: WalkState = .ready
    @Published var walkDuration: TimeInterval = 0
    @Published var annotations: [WalkAnnotation] = []

    @Published var walkJustFinished: Bool = false

    @Published var showCurrentWalk: Bool = false

    @Published var lastCompletedWalk: WalkRecord? = nil

    @Published var currentWalkingDog: Dog? = nil

    @Published var route: [CLLocationCoordinate2D] = []
    @Published var distance: CLLocationDistance = 0
    @Published var region: MKCoordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var currentActivity: Activity<DogWalkActivityAttributes>? = nil

    init() {
        loadDogs()
        loadWalkHistory()
        loadMemories()

        locationManager.$route
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRoute in self?.route = newRoute }
            .store(in: &cancellables)

        locationManager.$distance
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newDistance in self?.distance = newDistance }
            .store(in: &cancellables)

        locationManager.$region
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRegion in self?.region = newRegion }
            .store(in: &cancellables)
    }

    func toggleProAccessForReviewer() {
        isProUser.toggle()
        print("Reviewer Pro Access Toggled: \(isProUser)")
    }

    func canUseAITranslator() -> Bool {
        if isProUser { return true }
        if freeTranslationsUsed < maxFreeTranslations { return true }
        else { return false }
    }

    func canStartWalk() -> Bool {
        if isProUser { return true }
        if walkHistory.count < maxFreeWalks { return true }
        else { return false }
    }

    func canAddDog() -> Bool {
        if isProUser { return true }
        if dogs.count < maxFreeDogs { return true }
        else { return false }
    }

    func canAddMemory() -> Bool {
        return true
    }

    func canPlaySound() -> Bool {
        if isProUser { return true }
        if freeSoundsUsed < maxFreeSounds { return true }
        return false
    }

    func startWalk(dog: Dog) {
        guard canStartWalk() else {
            showPaywall = true
            return
        }

        resetWalk()

        self.currentWalkingDog = dog
        self.walkState = .ready

        print("--- 1. [VM] Walk Prepared for \(dog.name). Ready to show DogWalkView. ---")

        locationManager.onPermissionGranted = { [weak self] in
            DispatchQueue.main.async {
                print(">>> Permission GRANTED! Starting tracking...")
                self?.resumeWalk()
            }
        }
    }

    func requestLocationAndStart() {
        print("--- 2. [VM] Requesting location... ---")
        locationManager.startWalkProcess()
    }

    func resumeWalk() {
        guard let dog = currentWalkingDog else { return }

        if walkState == .paused {
            print("--- 3a. [VM] Walk Resumed ---")
            walkState = .walking
            startTimer()
            locationManager.resumeWalk()
        } else if walkState == .ready {
            print("--- 3b. [VM] Walk Started (First time) ---")
            walkState = .walking
            locationManager.startTracking()
            startTimer()
            startLiveActivity(dog: dog)
        }
    }

    func pauseWalk() {
        if walkState != .walking { return }
        print("--- 4. [VM] Walk Paused ---")
        walkState = .paused
        timer?.cancel()
        locationManager.pauseWalk()
    }

    func stopWalk() {
        guard let dog = currentWalkingDog else {
            walkState = .ready
            return
        }

        print("--- 5. [VM] Stopping walk... ---")
        locationManager.stopWalk()
        timer?.cancel()

        let walkWasLongEnough = walkDuration > 5
        if walkWasLongEnough {
                    let newRecord = WalkRecord(
                        dog: dog,
                        duration: walkDuration,
                        route: locationManager.route,
                        annotations: annotations
                    )
                    addWalkRecord(newRecord)

                    self.lastCompletedWalk = newRecord

                    if !isProUser {
                freeWalksUsed += 1
            }

        } else {
            print("Walk too short, not saving.")
            self.lastCompletedWalk = nil
        }

        Task {
            let finalState = DogWalkActivityAttributes.ContentState(
                duration: self.walkDuration,
                distance: self.distance
            )
            await self.currentActivity?.end(using: finalState, dismissalPolicy: .default)
            self.currentActivity = nil
            print("⏹️ Live Activity остановлена")
        }

        walkState = .ready
        walkJustFinished = true
        showCurrentWalk = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currentWalkingDog = nil
            self.annotations = []
            self.walkDuration = 0
            self.route = []
            self.distance = 0
        }
    }

    private func resetWalk() {
        locationManager.stopWalk()
        timer?.cancel()
        walkState = .ready
        currentWalkingDog = nil
        annotations = []
        walkDuration = 0
        route = []
        distance = 0
        walkJustFinished = false
        lastCompletedWalk = nil
        showCurrentWalk = false
    }

    private func startLiveActivity(dog: Dog) {
        let attributes = DogWalkActivityAttributes(dogName: dog.name)
        let initialState = DogWalkActivityAttributes.ContentState(duration: 0, distance: 0)

        do {
            let activity = try Activity<DogWalkActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            self.currentActivity = activity
            print("✅ Live Activity запущена: \(activity.id)")
        } catch (let error) {
            print("❌ Ошибка запуска Live Activity: \(error.localizedDescription)")
        }
    }

    func addEmojiAnnotation(imageName: String) {
        guard walkState == .walking, let coordinate = locationManager.userLocation?.coordinate else { return }
        let newAnnotation = WalkAnnotation(imageName: imageName, coordinate: coordinate)
        annotations.append(newAnnotation)
    }

    func addPhotoAnnotation(_ image: UIImage) {
        guard walkState == .walking, let coordinate = locationManager.userLocation?.coordinate else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
            let base64String = imageData.base64EncodedString()
            let prefixedString = "base64:\(base64String)"
            let newAnnotation = WalkAnnotation(imageName: prefixedString, coordinate: coordinate)

            DispatchQueue.main.async {
                self.annotations.append(newAnnotation)
            }
        }
    }

    private func startTimer() {
        timer?.cancel()

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                if self.walkState == .walking {
                    self.walkDuration += 1

                    let newState = DogWalkActivityAttributes.ContentState(
                        duration: self.walkDuration,
                        distance: self.distance
                    )

                    Task {
                        await self.currentActivity?.update(using: newState)
                    }

                } else {
                    self.timer?.cancel()
                }
            }

        if let timer = timer {
            cancellables.insert(timer)
        }
    }

    func loadDogs() {
        guard let data = try? Data(contentsOf: dogsFileURL) else {
            print("No saved dogs file found. Loading dummy dog.")
            self.dogs = [Dog.dummyDog()]
            return
        }
        do {
            self.dogs = try JSONDecoder().decode([Dog].self, from: data)
            print("✅ Dogs loaded from file system.")
        } catch {
            print("❌ Failed to decode dogs: \(error)")
            self.dogs = [Dog.dummyDog()]
        }
    }

    func saveDogs() {
        do {
            let data = try JSONEncoder().encode(dogs)
            try data.write(to: dogsFileURL, options: [.atomicWrite, .completeFileProtection])
            print("✅ Dogs saved to file system.")
        } catch {
            print("❌ Failed to save dogs to file system: \(error)")
        }
    }

    func addDog(_ dog: Dog) {
        dogs.append(dog)
        saveDogs()
    }

    func updateDog(_ dog: Dog) {
        guard let index = dogs.firstIndex(where: { $0.id == dog.id }) else { return }
        dogs[index] = dog
        saveDogs()
    }

    func deleteDog(at offsets: IndexSet) {
        dogs.remove(atOffsets: offsets)
        saveDogs()
    }

    func addMemory(imageData: Data) {
        let newMemory = MemoryItem(imageData: imageData)
        memories.insert(newMemory, at: 0)
        saveMemories()
        print("✅ New memory added and saved! (No limits)")
    }

    func saveMemories() {
        do {
            let data = try JSONEncoder().encode(memories)
            try data.write(to: memoriesFileURL, options: [.atomicWrite, .completeFileProtection])
            print("✅ Memories saved to file system.")
        } catch {
            print("❌ Failed to save memories to file system: \(error)")
        }
    }

    func loadMemories() {
        guard let data = try? Data(contentsOf: memoriesFileURL) else {
            print("No saved memories file found. Adding default 'img10'.")
            if let defaultImage = UIImage(named: "img10")?.jpegData(compressionQuality: 0.8) {
                let defaultMemory = MemoryItem(imageData: defaultImage)
                self.memories = [defaultMemory]
                saveMemories()
            }
            return
        }

        do {
            self.memories = try JSONDecoder().decode([MemoryItem].self, from: data)
            print("✅ Memories loaded from file system!")
        } catch {
            print("❌ Failed to load memories from file system: \(error)")
            self.memories = []
        }
    }

    func deleteMemory(memory: MemoryItem) {
        memories.removeAll { $0.id == memory.id }
        saveMemories()
        print("🗑️ Memory deleted.")
    }

    func addWalkRecord(_ newRecord: WalkRecord) {
        walkHistory.insert(newRecord, at: 0)
        saveWalkHistory()
        print("✅ Walk record saved!")
    }

    func loadWalkHistory() {
        guard let data = try? Data(contentsOf: historyFileURL) else {
            print("No walk history file found.")
            return
        }
        do {
            walkHistory = try JSONDecoder().decode([WalkRecord].self, from: data)
            print("✅ Walk history loaded from file system!")
        } catch {
            print("❌ Failed to load walk history from file system: \(error)")
        }
    }

    func saveWalkHistory() {
        do {
            let data = try JSONEncoder().encode(walkHistory)
            try data.write(to: historyFileURL, options: [.atomicWrite, .completeFileProtection])
            print("✅ Walk history saved to file system!")
        } catch {
            print("❌ Failed to save walk history to file system: \(error)")
        }
    }
}
