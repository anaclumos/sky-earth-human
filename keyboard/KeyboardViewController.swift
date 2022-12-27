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

  var isEditingLastCharacter = false

  override func updateViewConstraints() {
    super.updateViewConstraints()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    nextKeyboardButton = UIButton(type: .system)
    nextKeyboardButton.setTitle(NSLocalizedString("Next Keyboard", comment: "Title for 'Next Keyboard' button"), for: [])
    nextKeyboardButton.sizeToFit()
    nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
    nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

    view.addSubview(nextKeyboardButton)

    nextKeyboardButton.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
    nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    let keyboardView = UIHostingController(rootView: KeyboardView(buttonAction: buttonAction, ㅇㅁ: ㅇㅁ))
    view.addSubview(keyboardView.view)
    keyboardView.view.invalidateIntrinsicContentSize()
    keyboardView.view.translatesAutoresizingMaskIntoConstraints = false
    keyboardView.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    keyboardView.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    addChild(keyboardView)
  }

  override func viewWillLayoutSubviews() {
    nextKeyboardButton.isHidden = !needsInputModeSwitchKey
    super.viewWillLayoutSubviews()
  }

  override func textWillChange(_: UITextInput?) {
    // The app is about to change the document's contents. Perform any preparation here.
  }

  override func textDidChange(_: UITextInput?) {
    // The app has just changed the document's contents, the document context has been updated.

    var textColor: UIColor
    let proxy = textDocumentProxy
    if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
      textColor = UIColor.white
    }
    else {
      textColor = UIColor.black
    }
    nextKeyboardButton.setTitleColor(textColor, for: [])
  }

  func buttonAction(buttonIdx: Int) {
    let proxy = textDocumentProxy
    switch buttonIdx {
    case 0:
      인()
    case 1:
      천()
    case 2:
      지()
    case 3:
      proxy.deleteBackward()
      isEditingLastCharacter = false
    case 4:
      ㄱㅋ()
    case 5:
      ㄴㄹ()
    case 6:
      ㄷㅌ()
    case 7:
      proxy.insertText("\n")
    case 8:
      ㅂㅍ()
    case 9:
      ㅅㅎ()
    case 10:
      ㅈㅊ()
    case 11:
      quickSpecialCharacters()
    case 12:
      print("12")
    case 13:
      ㅇㅁ()
    case 14:
      isEditingLastCharacter = false
    case 15:
      dismissKeyboard()
    default:
      proxy.insertText(" ")
      isEditingLastCharacter = false
    }
  }

  func composableInput(first: String, second: String, third: String? = nil) {
    let proxy = textDocumentProxy
    if isEditingLastCharacter {
      if let lastCharacter = proxy.documentContextBeforeInput?.last {
        if lastCharacter == first.first {
          proxy.deleteBackward()
          proxy.insertText(second)
        } else if lastCharacter == second.first {
          proxy.deleteBackward()
          proxy.insertText(third ?? first)
        } else if third != nil, lastCharacter == third?.first {
          proxy.deleteBackward()
          proxy.insertText(first)
        }
      }
      return
    }
    proxy.insertText(first)
    isEditingLastCharacter = true
  }

  func ㅇㅁ() {
    composableInput(first: "ㅇ", second: "ㅁ")
  }

  func ㄱㅋ() {
    composableInput(first: "ㄱ", second: "ㅋ", third: "ㄲ")
  }

  func ㄴㄹ() {
    composableInput(first: "ㄴ", second: "ㄹ")
  }

  func ㄷㅌ() {
    composableInput(first: "ㄷ", second: "ㅌ", third: "ㄸ")
  }

  func ㅂㅍ() {
    composableInput(first: "ㅂ", second: "ㅍ", third: "ㅃ")
  }

  func ㅅㅎ() {
    composableInput(first: "ㅅ", second: "ㅎ", third: "ㅆ")
  }

  func ㅈㅊ() {
    composableInput(first: "ㅈ", second: "ㅊ", third: "ㅉ")
  }

  func quickSpecialCharacters() {
    composableInput(first: ".", second: "?", third: "!")
  }

  func 천() {
    let map = [
      "ㄱ": "ᄀᆞ",
      "ㅋ": "ᄏᆞ",
      "ㄲ": "ᄁᆞ",
      "ㄴ": "ᄂᆞ",
      "ㄹ": "ᄅᆞ",
      "ㄷ": "ᄃᆞ",
      "ㅌ": "ᄐᆞ",
      "ㄸ": "ᄄᆞ",
      "ㅂ": "ᄇᆞ",
      "ㅍ": "ᄑᆞ",
      "ㅃ": "ᄈᆞ",
      "ㅅ": "ᄉᆞ",
      "ㅎ": "ᄒᆞ",
      "ㅆ": "ᄊᆞ",
      "ㅈ": "ᄌᆞ",
      "ㅊ": "ᄎᆞ",
      "ㅉ": "ᄍᆞ",
      "ㅇ": "ᄋᆞ",
      "ㅁ": "ᄆᆞ",
    ]

    let proxy = textDocumentProxy
    if isEditingLastCharacter {
      if let lastCharacter = proxy.documentContextBeforeInput?.last {
        if map.keys.contains(String(lastCharacter)) {
          proxy.deleteBackward()
          proxy.insertText(map[String(lastCharacter)]!)
        }
      }
      return
    }
  }

  func 지() {}

  func 인() {}
}
