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

  func 입력(map: [String: String]) {
    let proxy = textDocumentProxy
    if let lastThreeCharacters = proxy.documentContextBeforeInput?.suffix(3) {
      if map.keys.contains(String(lastThreeCharacters)) {
        proxy.deleteBackward()
        proxy.deleteBackward()
        proxy.deleteBackward()
        proxy.insertText(map[String(lastThreeCharacters)]!)
        return
      }
    }

    if let lastTwoCharacters = proxy.documentContextBeforeInput?.suffix(2) {
      if map.keys.contains(String(lastTwoCharacters)) {
        proxy.deleteBackward()
        proxy.deleteBackward()
        proxy.insertText(map[String(lastTwoCharacters)]!)
        return
      }
    }

    if let lastCharacter = proxy.documentContextBeforeInput?.last {
      if map.keys.contains(String(lastCharacter)) {
        proxy.deleteBackward()
        proxy.insertText(map[String(lastCharacter)]!)
        return
      }
    }
  }

  func ㅇㅁ() {
    입력(map: 한글.ㅇㅁ)
  }

  func ㄱㅋ() {
    입력(map: 한글.ㄱㅋ)
  }

  func ㄴㄹ() {
    입력(map: 한글.ㄴㄹ)
  }

  func ㄷㅌ() {
    입력(map: 한글.ㄷㅌ)
  }

  func ㅂㅍ() {
    입력(map: 한글.ㅂㅍ)
  }

  func ㅅㅎ() {
    입력(map: 한글.ㅅㅎ)
  }

  func ㅈㅊ() {
    입력(map: 한글.ㅈㅊ)
  }

  func quickSpecialCharacters() {
    composableInput(first: ".", second: "?", third: "!")
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

  func 천() {
    입력(map: 한글.천)
  }

  func 지() {
    입력(map: 한글.지)
  }

  func 인() {
    입력(map: 한글.인)
  }
}
