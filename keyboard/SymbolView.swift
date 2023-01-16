//
//  NumberView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 1/15/23.
//

import SwiftUI

struct SymbolView: View {
  @EnvironmentObject var options: KeyboardOptions
  @EnvironmentObject var autocomplete: TopAutocomplete

  let available = [
    ["!", "?", ".", ",", "(", ")", "@", ":", "/", "-", "★", "°", "*", "_", "%", "~", "^", "#"],
    ["$", "₩", "€", "↖", "↑", "↗", "£", "¥", "=", "←", "♥", "→", "+", "×", "÷", "↙", "↓", "↘"],
    ["《", "》", "『", "』", "\"", "\'", "`", "※", "|", "&", "\\", ";", "<", ">", "{", "}", "[", "]"],
  ]

  @State var page = 0

  var body: some View {
    VStack {
      HStack {
        AutocompleteButton(text: autocomplete.list.count >= 1 ? autocomplete.list[0] : "", action: {
          if autocomplete.list.count >= 1 {
            autocomplete.action(autocomplete.list[0])
          }
        })
        Divider()
        AutocompleteButton(text: autocomplete.list.count >= 2 ? autocomplete.list[1] : "", action: {
          if autocomplete.list.count >= 2 {
            autocomplete.action(autocomplete.list[1])
          }
        })
        Divider()
        AutocompleteButton(text: autocomplete.list.count >= 3 ? autocomplete.list[2] : "", action: {
          if autocomplete.list.count >= 3 {
            autocomplete.action(autocomplete.list[2])
          }
        })
      }
      HStack {
        KeyboardButton(text: available[page][0], primary: true, action: {
          options.simpleInput(available[page][0])
        })
        KeyboardButton(text: available[page][1], primary: true, action: {
          options.simpleInput(available[page][1])
        })
        KeyboardButton(text: available[page][2], primary: true, action: {
          options.simpleInput(available[page][2])
        })
        KeyboardButton(text: available[page][3], primary: true, action: {
          options.simpleInput(available[page][3])
        })
        KeyboardButton(text: available[page][4], primary: true, action: {
          options.simpleInput(available[page][4])
        })
        KeyboardButton(text: available[page][5], primary: true, action: {
          options.simpleInput(available[page][5])
        })
        KeyboardButton(systemName: "delete.left.fill", primary: false, action: {
          options.deleteAction()
        })
      }
      HStack {
        KeyboardButton(text: available[page][6], primary: true, action: {
          options.simpleInput(available[page][6])
        })
        KeyboardButton(text: available[page][7], primary: true, action: {
          options.simpleInput(available[page][7])
        })
        KeyboardButton(text: available[page][8], primary: true, action: {
          options.simpleInput(available[page][8])
        })
        KeyboardButton(text: available[page][9], primary: true, action: {
          options.simpleInput(available[page][9])
        })
        KeyboardButton(text: available[page][10], primary: true, action: {
          options.simpleInput(available[page][10])
        })
        KeyboardButton(text: available[page][11], primary: true, action: {
          options.simpleInput(available[page][11])
        })
        KeyboardButton(systemName: "return", primary: false, action: {
          options.proxy.insertText("\n")
        })
      }
      HStack {
        KeyboardButton(text: available[page][12], primary: true, action: {
          options.simpleInput(available[page][12])
        })
        KeyboardButton(text: available[page][13], primary: true, action: {
          options.simpleInput(available[page][13])
        })
        KeyboardButton(text: available[page][14], primary: true, action: {
          options.simpleInput(available[page][14])
        })
        KeyboardButton(text: available[page][15], primary: true, action: {
          options.simpleInput(available[page][15])
        })
        KeyboardButton(text: available[page][16], primary: true, action: {
          options.simpleInput(available[page][16])
        })
        KeyboardButton(text: available[page][17], primary: true, action: {
          options.simpleInput(available[page][17])
        })
        KeyboardButton(text: ".?!", primary: false, action: {
          options.textAction(".", "?", "!")
        })
      }
      HStack {
        HStack {
          KeyboardButton(text: "한", primary: false, action: { options.current = .hangul })
          if options.needsInputModeSwitchKey {
            NextKeyboardButton(systemName: "globe",
                               action: options.nextKeyboardAction,
                               primary: false)
          }
        }
        KeyboardButton(text: "\(page + 1)/\(available.count)", primary: true, action: {
          page = (page + 1) % available.count
        })
        HStack {
          KeyboardButton(systemName: "space", primary: false, action: {
            options.spaceAction()
          })
        }
        HStack {
          KeyboardButton(systemName: "keyboard.chevron.compact.down.fill", primary: false, action: {
            options.dismissKeyboard()
          })
        }
      }
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .padding(10)
      .background(
        Color("KeyboardBackground")
      )
  }
}
