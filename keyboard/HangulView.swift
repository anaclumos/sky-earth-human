//
//  HangulView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 1/15/23.
//

import Combine
import SwiftUI

struct HangulView: View {
  @EnvironmentObject var options: KeyboardOptions
  @State var timer: AnyCancellable?
  @State var lastLongPressKey: String = ""

  var body: some View {
    VStack {
      HStack {
        KeyboardButton(text: "ㅣ", primary: true, action: {
          options.hangulAction("인", "ㅣ")
        },
        onLongPress: {
          if lastLongPressKey == "1" { return }
          options.simpleInput("1")
          lastLongPressKey = "1"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })
        KeyboardButton(text: "·", primary: true, action: {
          options.hangulAction("천", "ᆞ")
        },
        onLongPress: {
          if lastLongPressKey == "2" { return }
          options.simpleInput("2")
          lastLongPressKey = "2"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })

        KeyboardButton(text: "ㅡ", primary: true, action: {
          options.hangulAction("지", "ㅡ")
        },
        onLongPress: {
          if lastLongPressKey == "3" { return }
          options.simpleInput("3")
          lastLongPressKey = "3"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })
        KeyboardButton(systemName: "delete.left.fill", primary: false, action: {
          options.deleteAction()
        },
        onLongPress: {
          timer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
              options.deleteAction()
            }
        },
        onLongPressFinished: {
          timer?.cancel()
        })
      }
      HStack {
        KeyboardButton(text: "ㄱㅋ", primary: true, action: {
          options.hangulAction("ㄱㅋ", "ㄱ")
        },
        onLongPress: {
          if lastLongPressKey == "4" { return }
          options.simpleInput("4")
          lastLongPressKey = "4"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })
        KeyboardButton(text: "ㄴㄹ", primary: true, action: {
          options.hangulAction("ㄴㄹ", "ㄴ")
        },
        onLongPress: {
          if lastLongPressKey == "5" { return }
          options.simpleInput("5")
          lastLongPressKey = "5"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })
        KeyboardButton(text: "ㄷㅌ", primary: true, action: {
          options.hangulAction("ㄷㅌ", "ㄷ")
        },
        onLongPress: {
          if lastLongPressKey == "6" { return }
          options.simpleInput("6")
          lastLongPressKey = "6"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })
        KeyboardButton(systemName: "return", primary: false, action: {
          options.proxy.insertText("\n")
        })
      }
      HStack {
        KeyboardButton(text: "ㅂㅍ", primary: true, action: {
          options.hangulAction("ㅂㅍ", "ㅂ")
        },
        onLongPress: {
          if lastLongPressKey == "7" { return }
          options.simpleInput("7")
          lastLongPressKey = "7"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })
        KeyboardButton(text: "ㅅㅎ", primary: true, action: {
          options.hangulAction("ㅅㅎ", "ㅅ")
        },
        onLongPress: {
          if lastLongPressKey == "8" { return }
          options.simpleInput("8")
          lastLongPressKey = "8"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })
        KeyboardButton(text: "ㅈㅊ", primary: true, action: {
          options.hangulAction("ㅈㅊ", "ㅈ")
        },
        onLongPress: {
          if lastLongPressKey == "9" { return }
          options.simpleInput("9")
          lastLongPressKey = "9"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })
        KeyboardButton(text: ".?!", primary: false, action: {
          options.textAction(".", "?", "!")
        })
      }
      HStack {
        HStack {
          KeyboardButton(text: "!#1", primary: false, action: { options.current = .number })
          if options.needsInputModeSwitchKey {
            NextKeyboardButton(systemName: "globe",
                               action: options.nextKeyboardAction,
                               primary: false)
          }
        }
        KeyboardButton(text: "ㅇㅁ", primary: true, action: {
          options.hangulAction("ㅇㅁ", "ㅇ")
        },
        onLongPress: {
          if lastLongPressKey == "0" { return }
          options.simpleInput("0")
          lastLongPressKey = "0"
        },
        onLongPressFinished: {
          lastLongPressKey = ""
        })
        KeyboardButton(systemName: "space", primary: false, action: {
          options.spaceAction()
        })
        KeyboardButton(systemName: "keyboard.chevron.compact.down.fill", primary: false, action: {
          options.dismissKeyboard()
        })
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .padding(.leading, 10)
      .padding(.trailing, 10)
      .background(
        Color("KeyboardBackground")
      )
  }
}
