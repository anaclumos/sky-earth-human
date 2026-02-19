import SwiftUI

struct QuickSettingsView: View {
  @StateObject private var viewModel = QuickSettingsViewModel()

  var body: some View {
    VStack {
      Toggle("소리 피드백", isOn: $viewModel.isSoundFeedbackEnabled)
      Divider()
      Toggle("햅틱 피드백", isOn: $viewModel.isHapticFeedbackEnabled)
      Divider()
      Toggle("자동완성 및 추천", isOn: $viewModel.isAutocompleteEnabled)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

final class QuickSettingsViewModel: ObservableObject {
  @Published var isSoundFeedbackEnabled: Bool {
    didSet { settingsStore.set(isSoundFeedbackEnabled, for: .isSoundFeedbackEnabled) }
  }

  @Published var isHapticFeedbackEnabled: Bool {
    didSet { settingsStore.set(isHapticFeedbackEnabled, for: .isHapticFeedbackEnabled) }
  }

  @Published var isAutocompleteEnabled: Bool {
    didSet { settingsStore.set(isAutocompleteEnabled, for: .isAutocompleteEnabled) }
  }

  private let settingsStore: SettingsStore

  init(settingsStore: SettingsStore = AppGroupSettingsStore()) {
    self.settingsStore = settingsStore
    isSoundFeedbackEnabled = settingsStore.bool(for: .isSoundFeedbackEnabled)
    isHapticFeedbackEnabled = settingsStore.bool(for: .isHapticFeedbackEnabled)
    isAutocompleteEnabled = settingsStore.bool(for: .isAutocompleteEnabled)
  }
}

#Preview {
  QuickSettingsView()
}
