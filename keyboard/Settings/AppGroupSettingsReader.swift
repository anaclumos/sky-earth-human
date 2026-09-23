import Foundation

struct AppGroupSettingsReader: SettingsReader {
  private static let suiteName = "group.sh.cho.sky-earth-human.settings"

  var keySize: KeySize {
    guard
      let stored = suite?.string(forKey: "keySize"),
      let size = KeySize(rawValue: stored)
    else { return .default }
    return size
  }

  var isHapticFeedbackEnabled: Bool {
    flag("isHapticFeedbackEnabled", default: true)
  }

  var isPredictionEnabled: Bool {
    flag("isPredictionEnabled", default: true)
  }

  var cycleLock: Duration {
    guard let suite, suite.object(forKey: "cycleLockSeconds") != nil else {
      return .seconds(1)
    }
    return .seconds(suite.double(forKey: "cycleLockSeconds"))
  }

  /// `UserDefaults` is not Sendable, so no instance is held. Every read opens the suite again,
  /// which is also what keeps a value written by the container app visible here.
  func reload() {}

  private var suite: UserDefaults? {
    UserDefaults(suiteName: Self.suiteName)
  }

  private func flag(_ key: String, default fallback: Bool) -> Bool {
    guard let suite, suite.object(forKey: key) != nil else { return fallback }
    return suite.bool(forKey: key)
  }
}
