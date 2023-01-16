//
//  NumberView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 1/15/23.
//

import SwiftUI

struct NumberView: View {
  @EnvironmentObject var options: KeyboardOptions
  @EnvironmentObject var autocomplete: TopAutocomplete
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
          KeyboardButton(text: "@#$", primary: false, action: { options.current = .symbol })
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
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
      .padding(10)
      .background(
        Color("KeyboardBackground")
      )
  }
}
