//
//  NumberView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 1/15/23.
//

import Combine
import SwiftUI

struct SymbolView: View {
  @EnvironmentObject var options: KeyboardOptions

  let available = [
    ["!", "?", ".", ",", "(", ")", "@", ":", "/", "-", "★", "°", "*", "_", "%", "~", "^", "#"],
    ["$", "₩", "€", "↖", "↑", "↗", "£", "¥", "=", "←", "♥", "→", "+", "×", "÷", "↙", "↓", "↘"],
    ["《", "》", "『", "』", "\"", "\'", "`", "※", "|", "&", "\\", ";", "<", ">", "{", "}", "[", "]"],
  ]

  @State var page = 0
  @State var timer: AnyCancellable?

  var body: some View {
    VStack {
      HStack {
        HStack {
          KeyboardButton(text: available[page][0], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][0])
          })
          KeyboardButton(text: available[page][1], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][1])
          })
        }
        HStack {
          KeyboardButton(text: available[page][2], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][2])
          })
          KeyboardButton(text: available[page][3], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][3])
          })
        }
        HStack {
          KeyboardButton(text: available[page][4], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][4])
          })
          KeyboardButton(text: available[page][5], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][5])
          })
        }
        KeyboardButton(systemName: "delete.left.fill", primary: false, action: {
          Feedback.shared.playDeleteSound()
          Feedback.shared.playHaptics()
          options.deleteAction()
        },
        onLongPress: {
          timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
              Feedback.shared.playDeleteSound()
              Feedback.shared.playHaptics()
              options.deleteAction()
            }
        },
        onLongPressFinished: {
          timer?.cancel()
        })
      }
      HStack {
        HStack {
          KeyboardButton(text: available[page][6], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][6])
          })
          KeyboardButton(text: available[page][7], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][7])
          })
        }
        HStack {
          KeyboardButton(text: available[page][8], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][8])
          })
          KeyboardButton(text: available[page][9], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][9])
          })
        }
        HStack {
          KeyboardButton(text: available[page][10], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][10])
          })
          KeyboardButton(text: available[page][11], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][11])
          })
        }
        KeyboardButton(systemName: "return", primary: false, action: {
          Feedback.shared.playModifierSound()
          Feedback.shared.playHaptics()
          options.returnAction()
        })
      }
      HStack {
        HStack {
          KeyboardButton(text: available[page][12], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][12])
          })
          KeyboardButton(text: available[page][13], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][13])
          })
        }
        HStack {
          KeyboardButton(text: available[page][14], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][14])
          })
          KeyboardButton(text: available[page][15], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][15])
          })
        }
        HStack {
          KeyboardButton(text: available[page][16], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][16])
          })
          KeyboardButton(text: available[page][17], primary: true, action: {
            Feedback.shared.playTypeSound()
            Feedback.shared.playHaptics()
            options.simpleInput(available[page][17])
          })
        }
        KeyboardButton(text: ".?!", primary: false, action: {
          Feedback.shared.playTypeSound()
          Feedback.shared.playHaptics()
          options.textAction(".", "?", "!")
        })
      }
      HStack {
        HStack {
          KeyboardButton(text: "한", primary: false, action: {
            Feedback.shared.playModifierSound()
            Feedback.shared.playHaptics()
            options.current = .hangul
          })
          if options.needsInputModeSwitchKey {
            NextKeyboardButton(systemName: "globe",
                               action: options.nextKeyboardAction,
                               primary: false)
          }
        }
        KeyboardButton(text: "\(page + 1)/\(available.count)", primary: true, action: {
          Feedback.shared.playModifierSound()
          Feedback.shared.playHaptics()
          page = (page + 1) % available.count
        })
        HStack {
          KeyboardButton(systemName: "space", primary: false, action: {
            Feedback.shared.playModifierSound()
            Feedback.shared.playHaptics()
            options.spaceAction()
          })
        }
        HStack {
          KeyboardButton(systemName: "keyboard.chevron.compact.down.fill", primary: false, action: {
            Feedback.shared.playModifierSound()
            Feedback.shared.playHaptics()
            options.dismissKeyboard()
          })
        }
      }
    }.frame(maxWidth: 500, maxHeight: .infinity, alignment: .center)
      .padding(.leading, 10)
      .padding(.trailing, 10)
      .padding(.bottom, 10)
      .background(
        Color("KeyboardBackground")
      )
  }
}
