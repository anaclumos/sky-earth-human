import Foundation

enum AppGroup {
  static let suiteName = "group.sh.cho.sky-earth-human.settings"
}

enum AppSettingKey: String, CaseIterable {
  case isSoundFeedbackEnabled
  case isHapticFeedbackEnabled
  case isAutocompleteEnabled

  var defaultValue: Bool {
    true
  }
}

enum AppURL {
  static let website = URL(string: "https://cho.sh/ko")!
  static let installGuide = URL(string: "https://cho.sh/ko/r/BA36FC")!
  static let appStore = URL(string: "https://apps.apple.com/app/id/1666355842")!
  static let appStoreReview = URL(string: "https://apps.apple.com/app/id/1666355842?action=write-review")!
  static let repository = URL(string: "https://github.com/anaclumos/sky-earth-human")!
}

protocol SettingsStore {
  func bool(for key: AppSettingKey) -> Bool
  func set(_ value: Bool, for key: AppSettingKey)
}

final class AppGroupSettingsStore: SettingsStore {
  private let defaults: UserDefaults

  init(defaults: UserDefaults = UserDefaults(suiteName: AppGroup.suiteName) ?? .standard) {
    self.defaults = defaults
  }

  func bool(for key: AppSettingKey) -> Bool {
    if defaults.object(forKey: key.rawValue) == nil {
      return key.defaultValue
    }
    return defaults.bool(forKey: key.rawValue)
  }

  func set(_ value: Bool, for key: AppSettingKey) {
    defaults.set(value, forKey: key.rawValue)
  }
}
