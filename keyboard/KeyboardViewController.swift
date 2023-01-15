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

  var supportsHaptics: Bool = false
  var proxyBackup: String = ""
  var proxyHistory: [String] = []

  var 한글: [String: [String: String]] = [:]
  var isEditingLastCharacter = false
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
    let keyboardView = UIHostingController(rootView: KeyboardView(
      colorScheme: traitCollection.userInterfaceStyle == .dark ? .dark : .light,
      needsInputModeSwitchKey: needsInputModeSwitchKey,
      nextKeyboardAction: nextKeyboardAction,
      hangulAction: 입력,
      textAction: composableInput,
      proxy: textDocumentProxy,
      dismissKeyboard: dismissKeyboard,
      deleteAction: deleteAction,
      spaceAction: spaceAction
    ))
    view.addSubview(keyboardView.view)
    keyboardView.view.invalidateIntrinsicContentSize()
    keyboardView.view.translatesAutoresizingMaskIntoConstraints = false
    keyboardView.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    keyboardView.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    addChild(keyboardView)
    keyboardView.didMove(toParent: self)
  }

  func 입력(key: String, fallback: String) {
    guard let map = 한글[key] else {
      return
    }
    let proxy = textDocumentProxy
    if !isEditingLastCharacter {
      let proxy = textDocumentProxy
      proxy.insertText(fallback)
      proxyBackup = fallback
      proxyHistory.append(fallback)
      isEditingLastCharacter = true
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
        proxyHistory.append(next)
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
        proxyHistory.append(next)
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
        proxyHistory.append(next)
        return
      }
    }
    proxy.insertText(fallback)
    isEditingLastCharacter = true
    proxyBackup = fallback
    proxyHistory.append(fallback)
  }

  func composableInput(first: String, second: String, third: String? = nil) {
    let proxy = textDocumentProxy

    if isEditingLastCharacter {
      if let lastCharacter = proxy.documentContextBeforeInput?.last {
        if lastCharacter == first.first {
          proxy.deleteBackward()
          proxy.insertText(second)
          proxyBackup = second
          proxyHistory = []
          return
        } else if lastCharacter == second.first {
          proxy.deleteBackward()
          proxy.insertText(third ?? first)
          proxyBackup = third ?? first
          proxyHistory = []
          return
        } else if third != nil, lastCharacter == third?.first {
          proxy.deleteBackward()
          proxy.insertText(first)
          proxyBackup = first
          proxyHistory = []
          return
        }
      }
    }
    proxy.insertText(first)
    isEditingLastCharacter = true
    proxyBackup = first
    proxyHistory = []
  }

  func deleteAction() {
    print(proxyHistory)
    if proxyHistory.count > 1 {
      print("case 1")
      let proxy = textDocumentProxy
      proxy.deleteBackward()
      proxyHistory.removeLast()
      proxy.insertText(proxyHistory.removeLast())
      proxyBackup = proxyHistory.last ?? ""
      return
    }
    print("case 2")
    isEditingLastCharacter = false
    let proxy = textDocumentProxy
    proxy.deleteBackward()
    proxyBackup = ""
    proxyHistory = []
  }

  func spaceAction() {
    if !isEditingLastCharacter {
      textDocumentProxy.insertText(" ")
    } else {
      isEditingLastCharacter = false
      proxyBackup = ""
      proxyHistory = []
    }
  }
}
