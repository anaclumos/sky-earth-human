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

  var haptics: Bool?
  var sounds: Bool?

  let generator = UIImpactFeedbackGenerator(style: .light)

  private init() {
    if let haptics = UserDefaults.standard.object(forKey: "haptics") as? Bool {
      self.haptics = haptics
    } else {
      print("haptics not found")
    }
    if let sounds = UserDefaults.standard.object(forKey: "sounds") as? Bool {
      self.sounds = sounds
    } else {
      print("sounds not found")
    }
  }

  func playHaptics() {
    if !(haptics ?? false) {
      print("Haptic feedback is disabled")
      return
    }
    generator.impactOccurred()
  }

  func playTypeSound() {
    if !(sounds ?? false) { return }
    let systemSoundID: SystemSoundID = 1104
    AudioServicesPlaySystemSound(systemSoundID)
  }

  func playDeleteSound() {
    if !(sounds ?? false) { return }
    let systemSoundID: SystemSoundID = 1155
    AudioServicesPlaySystemSound(systemSoundID)
  }

  func playModifierSound() {
    if !(sounds ?? false) { return }
    let systemSoundID: SystemSoundID = 1156
    AudioServicesPlaySystemSound(systemSoundID)
  }
}
