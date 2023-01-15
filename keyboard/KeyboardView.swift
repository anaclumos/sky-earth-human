//
//  KeyboardView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import CoreHaptics
import SwiftUI

class TopAutocomplete: ObservableObject {
  @Published var list: [String] = []
}

struct KeyboardView: View {
  let colorScheme: ColorScheme
  let needsInputModeSwitchKey: Bool
  let nextKeyboardAction: Selector
  let hangulAction: (String, String) -> Void
  let textAction: (String, String, String?) -> Void
  let nextKeyboardButton = UIButton(type: .system)
  let proxy: UITextDocumentProxy
  let dismissKeyboard: () -> Void
  let deleteAction: () -> Void
  let spaceAction: () -> Void
  @ObservedObject var autocomplete: TopAutocomplete
  let autocompleteAction: (String) -> Void

  var body: some View {
    VStack {
      HStack {
        AutocompleteButton(text: autocomplete.list.count >= 1 ? autocomplete.list[0] : "", action: {
          if autocomplete.list.count >= 1 {
            autocompleteAction(autocomplete.list[0])
          }
        })
        Divider()
        AutocompleteButton(text: autocomplete.list.count >= 2 ? autocomplete.list[1] : "", action: {
          if autocomplete.list.count >= 2 {
            autocompleteAction(autocomplete.list[1])
          }
        })
        Divider()
        AutocompleteButton(text: autocomplete.list.count >= 3 ? autocomplete.list[2] : "", action: {
          if autocomplete.list.count >= 3 {
            autocompleteAction(autocomplete.list[2])
          }
        })
      }
      HStack {
        KeyboardButton(text: "ㅣ", primary: true, action: {
          hangulAction("인", "ㅣ")
        })
        KeyboardButton(text: "·", primary: true, action: {
          hangulAction("천", "ᆞ")
        })
        KeyboardButton(text: "ㅡ", primary: true, action: {
          hangulAction("지", "ㅡ")
        })
        KeyboardButton(systemName: "delete.left.fill", primary: false, action: {
          deleteAction()
        })
      }
      HStack {
        KeyboardButton(text: "ㄱㅋ", primary: true, action: {
          hangulAction("ㄱㅋ", "ㄱ")
        })
        KeyboardButton(text: "ㄴㄹ", primary: true, action: {
          hangulAction("ㄴㄹ", "ㄴ")
        })
        KeyboardButton(text: "ㄷㅌ", primary: true, action: {
          hangulAction("ㄷㅌ", "ㄷ")
        })
        KeyboardButton(systemName: "return", primary: false, action: {
          proxy.insertText("\n")
        })
      }
      HStack {
        KeyboardButton(text: "ㅂㅍ", primary: true, action: {
          hangulAction("ㅂㅍ", "ㅂ")
        })
        KeyboardButton(text: "ㅅㅎ", primary: true, action: {
          hangulAction("ㅅㅎ", "ㅅ")
        })
        KeyboardButton(text: "ㅈㅊ", primary: true, action: {
          hangulAction("ㅈㅊ", "ㅈ")
        })
        KeyboardButton(text: ".?!", primary: false, action: {
          textAction(".", "?", "!")
        })
      }
      HStack {
        HStack {
          KeyboardButton(text: "!#1", primary: false, action: {
            // do nothing
          })
          if needsInputModeSwitchKey {
            NextKeyboardButton(systemName: "globe",
                               action: nextKeyboardAction,
                               primary: false)
          }
        }
        KeyboardButton(text: "ㅇㅁ", primary: true, action: {
          hangulAction("ㅇㅁ", "ㅇ")
        })
        KeyboardButton(systemName: "space", primary: false, action: {
          spaceAction()
        })
        KeyboardButton(systemName: "keyboard.chevron.compact.down.fill", primary: false, action: {
          dismissKeyboard()
        })
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .padding(10)
      .background(
        Color("KeyboardBackground")
      )
  }
}
