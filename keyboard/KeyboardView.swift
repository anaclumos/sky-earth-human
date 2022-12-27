//
//  KeyboardView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import SwiftUI

struct KeyboardView: View {
  @Environment(\.colorScheme) var colorScheme
  var buttonAction: (Int) -> Void
  var ㅇㅁ: () -> Void

  var body: some View {
    VStack {
      HStack {
        KeyboardButton(text: "ㅣ", action: {
          buttonAction(0)
        })
        KeyboardButton(text: "·", action: {
          buttonAction(1)
        })
        KeyboardButton(text: "ㅡ", action: {
          buttonAction(2)

        })
        KeyboardButton(image: "delete.left.fill", action: {
          buttonAction(3)
        })
      }
      HStack {
        KeyboardButton(text: "ㄱㅋ", action: {
          buttonAction(4)
        })
        KeyboardButton(text: "ㄴㄹ", action: {
          buttonAction(5)
        })
        KeyboardButton(text: "ㄷㅌ", action: {
          buttonAction(6)
        })
        KeyboardButton(image: "return", action: {
          buttonAction(7)
        })
      }
      HStack {
        KeyboardButton(text: "ㅂㅍ", action: {
          buttonAction(8)
        })
        KeyboardButton(text: "ㅅㅎ", action: {
          buttonAction(9)
        })
        KeyboardButton(text: "ㅈㅊ", action: {
          buttonAction(10)
        })
        KeyboardButton(text: ".,?!", action: {
          buttonAction(11)
        })
      }
      HStack {
        HStack {
          KeyboardButton(text: "!#1", action: {
            buttonAction(12)
          })
          KeyboardButton(image: "globe", action: {
            // change keyboard
          })
        }

        KeyboardButton(text: "ㅇㅁ", action: {
          ㅇㅁ()
        })
        KeyboardButton(image: "space", action: {
          buttonAction(14)
        })
        KeyboardButton(image: "keyboard.chevron.compact.down.fill", action: {
          buttonAction(15)
        })
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .padding(10)
      .background(
        colorScheme == .dark ? Color(uiColor: UIColor.tertiarySystemBackground) : Color(red: 208 / 256, green: 212 / 256, blue: 216 / 256)
      )
  }
}
