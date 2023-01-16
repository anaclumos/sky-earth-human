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
      .padding(.leading, 10)
      .padding(.trailing, 10)
      .background(
        Color("KeyboardBackground")
      )
  }
}
