import AVFoundation
import UIKit

final class Feedback: FeedbackService {
  static let shared = Feedback(settingsStore: AppGroupSettingsStore())

  private let settingsStore: SettingsStore
  private let generator = UIImpactFeedbackGenerator(style: .light)

  init(settingsStore: SettingsStore) {
    self.settingsStore = settingsStore
  }

  private var hapticsEnabled: Bool {
    settingsStore.bool(for: .isHapticFeedbackEnabled)
  }

  private var soundsEnabled: Bool {
    settingsStore.bool(for: .isSoundFeedbackEnabled)
  }

  func playHaptics() {
    guard hapticsEnabled else { return }
    generator.impactOccurred()
  }

  func playTypeSound() {
    guard soundsEnabled else { return }
    AudioServicesPlaySystemSound(1104)
  }

  func playDeleteSound() {
    guard soundsEnabled else { return }
    AudioServicesPlaySystemSound(1155)
  }

  func playModifierSound() {
    guard soundsEnabled else { return }
    AudioServicesPlaySystemSound(1156)
  }
}
