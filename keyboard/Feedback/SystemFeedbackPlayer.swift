import UIKit

@MainActor
final class SystemFeedbackPlayer: FeedbackPlayer {
  private let settings: any SettingsReader
  private let generator: UIImpactFeedbackGenerator

  init(settings: any SettingsReader, hapticView: UIView) {
    self.settings = settings
    // The view-attached initializer needs iOS 17.5; the deployment target is 17.0, so
    // 17.0 through 17.4 fall back to the deprecated style-only initializer. One generator is
    // created here and reused for every press; Apple's own UIImpactFeedbackGenerator sample
    // stores the generator as a property and calls impactOccurred() on it repeatedly.
    generator = if #available(iOS 17.5, *) {
      UIImpactFeedbackGenerator(style: .light, view: hapticView)
    } else {
      UIImpactFeedbackGenerator(style: .light)
    }
  }

  func play(_: FeedbackKind) {
    UIDevice.current.playInputClick()
    guard settings.isHapticFeedbackEnabled else { return }
    generator.prepare()
    generator.impactOccurred()
  }
}
