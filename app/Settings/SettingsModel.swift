import Foundation
import Observation

@Observable
@MainActor
final class SettingsModel {
  static let appGroupSuiteName = "group.sh.cho.sky-earth-human.settings"

  static let cycleLockRange: ClosedRange<Double> = 0.5 ... 2.0
  static let cycleLockStep: Double = 0.25

  var keySize: KeySize {
    didSet { defaults.set(keySize.rawValue, forKey: Key.keySize) }
  }

  var isHapticFeedbackEnabled: Bool {
    didSet { defaults.set(isHapticFeedbackEnabled, forKey: Key.isHapticFeedbackEnabled) }
  }

  var isPredictionEnabled: Bool {
    didSet { defaults.set(isPredictionEnabled, forKey: Key.isPredictionEnabled) }
  }

  var cycleLockSeconds: Double {
    didSet { defaults.set(cycleLockSeconds, forKey: Key.cycleLockSeconds) }
  }

  private let defaults: UserDefaults

  private enum Key {
    static let keySize = "keySize"
    static let isHapticFeedbackEnabled = "isHapticFeedbackEnabled"
    static let isPredictionEnabled = "isPredictionEnabled"
    static let cycleLockSeconds = "cycleLockSeconds"
  }

  init() {
    guard let groupDefaults = UserDefaults(suiteName: Self.appGroupSuiteName) else {
      fatalError("App Group \(Self.appGroupSuiteName) is unavailable, check the application-groups entitlement")
    }
    defaults = groupDefaults
    keySize = KeySize(rawValue: groupDefaults.string(forKey: Key.keySize) ?? "") ?? .medium
    isHapticFeedbackEnabled = groupDefaults.object(forKey: Key.isHapticFeedbackEnabled) as? Bool ?? true
    isPredictionEnabled = groupDefaults.object(forKey: Key.isPredictionEnabled) as? Bool ?? true
    cycleLockSeconds = groupDefaults.object(forKey: Key.cycleLockSeconds) as? Double ?? 1.0
  }
}
