//
//  QuickSettingsView.swift
//  sky-earth-human
//
//  Created by Sunghyun Cho on 2024-01-30.
//

import SwiftUI

struct QuickSettingsView: View {
  @State private var isSoundFeedbackEnabled: Bool
  @State private var isHapticFeedbackEnabled: Bool
  @State private var isAutocompleteEnabled: Bool
  private var sharedDefaults: UserDefaults?

  init() {
    sharedDefaults = UserDefaults(suiteName: "group.sh.cho.sky-earth-human.settings")

    // Check if the UserDefaults value exists and if not, default to true
    if sharedDefaults?.object(forKey: "isSoundFeedbackEnabled") == nil {
      _isSoundFeedbackEnabled = State(initialValue: true)
    } else {
      _isSoundFeedbackEnabled = State(
        initialValue: sharedDefaults!.bool(forKey: "isSoundFeedbackEnabled"))
    }

    if sharedDefaults?.object(forKey: "isHapticFeedbackEnabled") == nil {
      _isHapticFeedbackEnabled = State(initialValue: true)
    } else {
      _isHapticFeedbackEnabled = State(
        initialValue: sharedDefaults!.bool(forKey: "isHapticFeedbackEnabled"))
    }

    if sharedDefaults?.object(forKey: "isAutocompleteEnabled") == nil {
      _isAutocompleteEnabled = State(initialValue: true)
    } else {
      _isAutocompleteEnabled = State(
        initialValue: sharedDefaults!.bool(forKey: "isAutocompleteEnabled"))
    }
  }

  var body: some View {
    VStack {
      Toggle("소리 피드백", isOn: $isSoundFeedbackEnabled)
        .onChange(of: isSoundFeedbackEnabled) { newValue in
          sharedDefaults?.set(newValue, forKey: "isSoundFeedbackEnabled")
          sharedDefaults?.synchronize()

        }
      Divider()
      Toggle("햅틱 피드백", isOn: $isHapticFeedbackEnabled)
        .onChange(of: isHapticFeedbackEnabled) { newValue in
          sharedDefaults?.set(newValue, forKey: "isHapticFeedbackEnabled")
          sharedDefaults?.synchronize()

        }
      Divider()
      Toggle("자동완성 및 추천", isOn: $isAutocompleteEnabled)
        .onChange(of: isAutocompleteEnabled) { newValue in
          sharedDefaults?.set(newValue, forKey: "isAutocompleteEnabled")
          sharedDefaults?.synchronize()

        }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

#Preview {
  QuickSettingsView()
}
