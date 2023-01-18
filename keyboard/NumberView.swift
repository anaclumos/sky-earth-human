//
//  NumberView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 1/15/23.
//

import Combine
import SwiftUI

struct NumberView: View {
  @EnvironmentObject var options: KeyboardOptions
  @State var timer: AnyCancellable?
  var body: some View {
    VStack {
      HStack {
        KeyboardButton(text: "1", primary: true, action: {
          options.simpleInput("1")
        })
        KeyboardButton(text: "2", primary: true, action: {
          options.simpleInput("2")
        })
        KeyboardButton(text: "3", primary: true, action: {
          options.simpleInput("3")
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
        KeyboardButton(text: "4", primary: true, action: {
          options.simpleInput("4")
        })
        KeyboardButton(text: "5", primary: true, action: {
          options.simpleInput("5")
        })
        KeyboardButton(text: "6", primary: true, action: {
          options.simpleInput("6")
        })
        KeyboardButton(systemName: "return", primary: false, action: {
          options.proxy.insertText("\n")
        })
      }
      HStack {
        KeyboardButton(text: "7", primary: true, action: {
          options.simpleInput("7")
        })
        KeyboardButton(text: "8", primary: true, action: {
          options.simpleInput("8")
        })
        KeyboardButton(text: "9", primary: true, action: {
          options.simpleInput("9")
        })
        KeyboardButton(text: ".?!", primary: false, action: {
          options.textAction(".", "?", "!")
        })
      }
      HStack {
        HStack {
          KeyboardButton(text: "@#", primary: false, action: { options.current = .symbol })
          if options.needsInputModeSwitchKey {
            NextKeyboardButton(systemName: "globe",
                               action: options.nextKeyboardAction,
                               primary: false)
          }
        }
        KeyboardButton(text: "0", primary: true, action: {
          options.simpleInput("0")
        })
        KeyboardButton(systemName: "space", primary: false, action: {
          options.spaceAction()
        })
        KeyboardButton(systemName: "keyboard.chevron.compact.down.fill", primary: false, action: {
          options.dismissKeyboard()
        })
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
