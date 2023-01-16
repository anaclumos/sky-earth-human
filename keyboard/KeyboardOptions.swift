//
//  KeyboardOptions.swift
//  keyboard
//
//  Created by Sunghyun Cho on 1/15/23.
//

import Foundation
import SwiftUI

enum KeyboardType {
  case hangul
  case number
  case symbol
}

class KeyboardOptions: ObservableObject {
  @Published var current: KeyboardType = .hangul
  var colorScheme: ColorScheme
  var needsInputModeSwitchKey: Bool
  var nextKeyboardAction: Selector
  var hangulAction: (String, String) -> Void
  var textAction: (String, String, String?) -> Void
  var proxy: UITextDocumentProxy
  var dismissKeyboard: () -> Void
  var deleteAction: () -> Void
  var spaceAction: () -> Void
  var autocompleteAction: (String) -> Void
  var autocomplete: TopAutocomplete
  var simpleInput: (String) -> Void

  init(colorScheme: ColorScheme, needsInputModeSwitchKey: Bool, nextKeyboardAction: Selector, hangulAction: @escaping (String, String) -> Void, textAction: @escaping (String, String, String?) -> Void, proxy: UITextDocumentProxy, dismissKeyboard: @escaping () -> Void, deleteAction: @escaping () -> Void, spaceAction: @escaping () -> Void, autocomplete: TopAutocomplete, autocompleteAction: @escaping (String) -> Void, simpleInput: @escaping (String) -> Void) {
    self.colorScheme = colorScheme
    self.needsInputModeSwitchKey = needsInputModeSwitchKey
    self.nextKeyboardAction = nextKeyboardAction
    self.hangulAction = hangulAction
    self.textAction = textAction
    self.proxy = proxy
    self.dismissKeyboard = dismissKeyboard
    self.deleteAction = deleteAction
    self.spaceAction = spaceAction
    self.autocomplete = autocomplete
    self.autocompleteAction = autocompleteAction
    self.simpleInput = simpleInput
  }
}
