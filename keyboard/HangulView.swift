//
//  HangulView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 1/15/23.
//

import SwiftUI

struct HangulView: View {
  @EnvironmentObject var options: KeyboardOptions
  var body: some View {
    VStack {
      HStack {
        AutocompleteButton(text: options.autocomplete.list.count >= 1 ? options.autocomplete.list[0] : "", action: {
          if options.autocomplete.list.count >= 1 {
            options.autocompleteAction(options.autocomplete.list[0])
          }
        })
        Divider()
        AutocompleteButton(text: options.autocomplete.list.count >= 2 ? options.autocomplete.list[1] : "", action: {
          if options.autocomplete.list.count >= 2 {
            options.autocompleteAction(options.autocomplete.list[1])
          }
        })
        Divider()
        AutocompleteButton(text: options.autocomplete.list.count >= 3 ? options.autocomplete.list[2] : "", action: {
          if options.autocomplete.list.count >= 3 {
            options.autocompleteAction(options.autocomplete.list[2])
          }
        })
      }
      HStack {
        KeyboardButton(text: "ㅣ", primary: true, action: {
          options.hangulAction("인", "ㅣ")
        })
        KeyboardButton(text: "·", primary: true, action: {
          options.hangulAction("천", "ᆞ")
        })
        KeyboardButton(text: "ㅡ", primary: true, action: {
          options.hangulAction("지", "ㅡ")
        })
        KeyboardButton(systemName: "delete.left.fill", primary: false, action: {
          options.deleteAction()
        })
      }
      HStack {
        KeyboardButton(text: "ㄱㅋ", primary: true, action: {
          options.hangulAction("ㄱㅋ", "ㄱ")
        })
        KeyboardButton(text: "ㄴㄹ", primary: true, action: {
          options.hangulAction("ㄴㄹ", "ㄴ")
        })
        KeyboardButton(text: "ㄷㅌ", primary: true, action: {
          options.hangulAction("ㄷㅌ", "ㄷ")
        })
        KeyboardButton(systemName: "return", primary: false, action: {
          options.proxy.insertText("\n")
        })
      }
      HStack {
        KeyboardButton(text: "ㅂㅍ", primary: true, action: {
          options.hangulAction("ㅂㅍ", "ㅂ")
        })
        KeyboardButton(text: "ㅅㅎ", primary: true, action: {
          options.hangulAction("ㅅㅎ", "ㅅ")
        })
        KeyboardButton(text: "ㅈㅊ", primary: true, action: {
          options.hangulAction("ㅈㅊ", "ㅈ")
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
        })
        KeyboardButton(systemName: "space", primary: false, action: {
          options.spaceAction()
        })
        KeyboardButton(systemName: "keyboard.chevron.compact.down.fill", primary: false, action: {
          options.dismissKeyboard()
        })
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .padding(10)
      .background(
        Color("KeyboardBackground")
      )
  }
}
