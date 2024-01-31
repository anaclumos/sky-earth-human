//
//  Feedback.swift
//  keyboard
//
//  Created by Sunghyun Cho on 2023-01-21.
//

import AVFoundation
import UIKit

class Feedback {
  static let shared = Feedback()

  var sharedDefaults: UserDefaults?

  let generator = UIImpactFeedbackGenerator(style: .light)

  private init() {
    sharedDefaults = UserDefaults(suiteName: "group.sh.cho.sky-earth-human.settings")
  }

  var haptics: Bool {
    return sharedDefaults?.bool(forKey: "isHapticFeedbackEnabled") ?? true
  }

  var sounds: Bool {
    return sharedDefaults?.bool(forKey: "isSoundFeedbackEnabled") ?? true
  }

  func playHaptics() {
    if !haptics { return }
    generator.impactOccurred()
  }

  func playTypeSound() {
    if !sounds { return }
    let systemSoundID: SystemSoundID = 1104
    AudioServicesPlaySystemSound(systemSoundID)
  }

  func playDeleteSound() {
    if !sounds { return }
    let systemSoundID: SystemSoundID = 1155
    AudioServicesPlaySystemSound(systemSoundID)
  }

  func playModifierSound() {
    if !sounds { return }
    let systemSoundID: SystemSoundID = 1156
    AudioServicesPlaySystemSound(systemSoundID)
  }
}
