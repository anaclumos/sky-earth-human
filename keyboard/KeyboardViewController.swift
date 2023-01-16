//
//  KeyboardViewController.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/19/22.
//

import SwiftUI
import UIKit

class KeyboardViewController: UIInputViewController {
  @IBOutlet var nextKeyboardButton: UIButton!
  @IBOutlet var helloButton: UIButton!
  var proxyBackup: String = ""
  var proxyHistory: [String] = []
  var 한글: [String: [String: String]] = [:]
  var isEditingLastCharacter = false
  var options: KeyboardOptions?
  var autocomplete: TopAutocomplete?
  override func updateViewConstraints() {
    super.updateViewConstraints()
  }

  func loadJsonAsync() {
    DispatchQueue.global(qos: .background).async {
      if let path = Bundle.main.path(forResource: "한글", ofType: "json") {
        do {
          let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
          let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
          if let jsonResult = jsonResult as? [String: Any], let 데이터 = jsonResult as? [String: [String: String]] {
            self.한글 = 데이터
          }
        } catch {
          exit(1)
        }
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }

  private func setup() {
    if 한글 == [:] {
      loadJsonAsync()
    }
    let nextKeyboardAction = #selector(handleInputModeList(from:with:))

    let options = KeyboardOptions(
      colorScheme: traitCollection.userInterfaceStyle == .dark ? .dark : .light,
      needsInputModeSwitchKey: needsInputModeSwitchKey,
      nextKeyboardAction: nextKeyboardAction,
      hangulAction: 입력,
      textAction: composableInput,
      proxy: textDocumentProxy,
      dismissKeyboard: dismissKeyboard,
      deleteAction: deleteAction,
      spaceAction: spaceAction,
      simpleInput: simpleInput
    )

    let autocomplete = TopAutocomplete(action: autocompleteAction)

    let keyboardView = UIHostingController(rootView: KeyboardView().environmentObject(options).environmentObject(autocomplete))
    autocomplete.list = ["", "", ""]

    self.options = options
    self.autocomplete = autocomplete

    view.addSubview(keyboardView.view)
    keyboardView.view.invalidateIntrinsicContentSize()
    keyboardView.view.translatesAutoresizingMaskIntoConstraints = false
    keyboardView.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    keyboardView.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    addChild(keyboardView)
    keyboardView.didMove(toParent: self)
    updateAutocomplete()
  }

  func 입력(key: String, fallback: String) {
    guard let map = 한글[key] else {
      simpleInput(fallback)
      return
    }

    let proxy = textDocumentProxy

    if proxy.documentContextBeforeInput != nil &&
      !proxy.documentContextBeforeInput!.contains(proxyBackup)
    {
      proxyBackup = ""
      proxyHistory = []
    }

    if !isEditingLastCharacter {
      proxy.insertText(fallback)
      proxyBackup = fallback
      proxyHistory = [fallback]
      isEditingLastCharacter = true
      updateAutocomplete()
      return
    }
    if proxyBackup.count > 2 {
      let lastThreeCharacters = proxyBackup.suffix(3)
      if map.keys.contains(String(lastThreeCharacters)) {
        proxy.deleteBackward()
        proxy.deleteBackward()
        proxy.deleteBackward()
        let next = map[String(lastThreeCharacters)]!
        proxy.insertText(next)
        proxyBackup = next
        proxyHistory = [next]
        updateAutocomplete()
        return
      }
    }
    if proxyBackup.count > 1 {
      let lastTwoCharacters = proxyBackup.suffix(2)
      if map.keys.contains(String(lastTwoCharacters)) {
        proxy.deleteBackward()
        proxy.deleteBackward()
        let next = map[String(lastTwoCharacters)]!
        proxy.insertText(next)
        proxyBackup = next
        proxyHistory = [next]
        updateAutocomplete()
        return
      }
    }
    if proxyBackup.count > 0 {
      let lastCharacter = proxyBackup.suffix(1)
      if map.keys.contains(String(lastCharacter)) {
        proxy.deleteBackward()
        let next = map[String(lastCharacter)]!
        proxy.insertText(next)
        proxyBackup = next
        if String(lastCharacter).count != next.count {
          let lastCharacter = next.suffix(1)
          proxyHistory = [String(lastCharacter)]
        } else {
          proxyHistory.append(next)
        }
        updateAutocomplete()
        return
      }
    }
    proxy.insertText(fallback)
    isEditingLastCharacter = true
    proxyBackup = fallback
    proxyHistory = [fallback]
    updateAutocomplete()
  }

  func simpleInput(_ input: String) {
    let proxy = textDocumentProxy
    proxy.insertText(input)
    proxyBackup = input
    proxyHistory = [input]
    updateAutocomplete()
  }

  func composableInput(first: String, second: String? = nil, third: String? = nil) {
    let proxy = textDocumentProxy
    if isEditingLastCharacter {
      if let lastCharacter = proxy.documentContextBeforeInput?.last {
        if lastCharacter == first.first {
          proxy.deleteBackward()
          proxy.insertText(second ?? first)
          proxyBackup = second ?? first
          proxyHistory = []
          updateAutocomplete()
          return
        } else if lastCharacter == second?.first {
          proxy.deleteBackward()
          proxy.insertText(third ?? first)
          proxyBackup = third ?? first
          proxyHistory = []
          updateAutocomplete()
          return
        } else if third != nil, lastCharacter == third?.first {
          proxy.deleteBackward()
          proxy.insertText(first)
          proxyBackup = first
          proxyHistory = []
          updateAutocomplete()
          return
        }
      }
    }
    proxy.insertText(first)
    isEditingLastCharacter = true
    proxyBackup = first
    proxyHistory = []
    updateAutocomplete()
  }

  func deleteAction() {
    if proxyHistory.count > 1 {
      let proxy = textDocumentProxy
      for _ in 0 ..< (proxyHistory.last?.count ?? 0) {
        proxy.deleteBackward()
      }

      if isEditingLastCharacter {
        proxyHistory.removeLast()
        isEditingLastCharacter = false
      }
      proxy.insertText(proxyHistory.removeLast())
      proxyBackup = proxyHistory.last ?? ""
      updateAutocomplete()
      return
    }
    isEditingLastCharacter = false
    let proxy = textDocumentProxy
    proxy.deleteBackward()
    proxyBackup = ""
    proxyHistory = []
    updateAutocomplete()
  }

  func spaceAction() {
    if !isEditingLastCharacter {
      textDocumentProxy.insertText(" ")
    } else {
      isEditingLastCharacter = false
      proxyBackup = ""
      proxyHistory = []
    }
    updateAutocomplete()
  }

  func autocompleteAction(completion: String) {
    let proxy = textDocumentProxy
    while let lastCharacter = proxy.documentContextBeforeInput?.last, lastCharacter != " " {
      proxy.deleteBackward()
    }
    proxy.insertText(completion)
    proxyBackup = completion
    proxyHistory = []
  }

  func updateAutocomplete() {
    let uiTextChecker = UITextChecker()
    let proxy = textDocumentProxy
    let allString = proxy.documentContextBeforeInput ?? ""
    let lastWord = allString.components(separatedBy: " ").last ?? ""
    let range = NSRange(location: 0, length: lastWord.count)
    let guesses = uiTextChecker.completions(forPartialWordRange: range, in: lastWord, language: "ko") ?? []
    if guesses.count > 0, guesses[0] == lastWord {
      autocomplete?.list = Array(guesses.dropFirst())
    } else {
      autocomplete?.list = guesses
    }
  }
}
