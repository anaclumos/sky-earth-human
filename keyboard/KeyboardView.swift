//
//  KeyboardView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import SwiftUI

struct KeyboardView: View {
  var body: some View {
    VStack {
      HStack {
        KeyboardButton(text: "ㅣ", action: {})
        KeyboardButton(text: "•", action: {})
        KeyboardButton(text: "ㅡ", action: {})
        KeyboardButton(image: "delete.left.fill", action: {})
      }
      HStack {
        KeyboardButton(text: "ㄱㅋ", action: {})
        KeyboardButton(text: "ㄴㄹ", action: {})
        KeyboardButton(text: "ㄷㅌ", action: {})
        KeyboardButton(image: "return", action: {})
      }
      HStack {
        KeyboardButton(text: "ㅂㅍ", action: {})
        KeyboardButton(text: "ㅅㅎ", action: {})
        KeyboardButton(text: "ㅈㅊ", action: {})
        KeyboardButton(text: ".,?!", action: {})
      }
      HStack {
        KeyboardButton(text: "!#1", action: {})
        KeyboardButton(text: "ㅇㅁ", action: {})
        KeyboardButton(image: "space", action: {})
        KeyboardButton(text: ",", action: {})
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity)
      .padding(10)
      .background(Color(uiColor: UIColor.tertiarySystemBackground))
  }
}
