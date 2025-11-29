import Foundation
import SwiftUI
import Combine

final class SoundsViewModel: ObservableObject {

    @Published var selectedSound: String? = nil
    @Published var isPlaying = false

    private let audioService = AudioService.shared

    let sounds = [
        "happy", "angry", "cool", "cry", "dizzy",
        "in_love", "laugh", "lick", "neutral",
        "rage", "serious", "shock", "shy",
        "sick", "sleep", "smile", "tired",
        "tongue", "unamused", "wink", "wink_smile"
    ]

    func isPremium(index: Int) -> Bool {
        return index >= 5
    }

    func playSound(_ sound: String, isPremium: Bool, isProUser: Bool) -> Bool {
        if isPremium && !isProUser {
            return false
        }

        selectedSound = sound
        isPlaying = true
        audioService.playSound(named: sound)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.isPlaying = false
        }

        return true
    }
}
