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
          print("error")
        }
      }
    }
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
    keyboardView.didMove(toParent: self)
    loadJsonAsync()
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
      if !isEditingLastCharacter {
        proxy.insertText(" ")
      } else {
        isEditingLastCharacter = false
      }
    case 15:
      dismissKeyboard()
    default:
      proxy.insertText(" ")
      isEditingLastCharacter = false
    }
  }

  func 입력(map: [String: String]?) -> Bool {
    guard let map = map else {
      return false
    }
    let proxy = textDocumentProxy
    if let lastThreeCharacters = proxy.documentContextBeforeInput?.suffix(3) {
      if map.keys.contains(String(lastThreeCharacters)) {
        proxy.deleteBackward()
        proxy.deleteBackward()
        proxy.deleteBackward()
        proxy.insertText(map[String(lastThreeCharacters)]!)
        return true
      }
    }

    if let lastTwoCharacters = proxy.documentContextBeforeInput?.suffix(2) {
      if map.keys.contains(String(lastTwoCharacters)) {
        proxy.deleteBackward()
        proxy.deleteBackward()
        proxy.insertText(map[String(lastTwoCharacters)]!)
        return true
      }
    }

    if let lastCharacter = proxy.documentContextBeforeInput?.last {
      if map.keys.contains(String(lastCharacter)) {
        proxy.deleteBackward()
        proxy.insertText(map[String(lastCharacter)]!)
        return true
      }
    }

    return false
  }

  func ㅇㅁ() {
    if !isEditingLastCharacter || !입력(map: 한글["ㅇㅁ"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ㅇ")
      isEditingLastCharacter = true
    }
  }

  func ㄱㅋ() {
    if !isEditingLastCharacter || !입력(map: 한글["ㄱㅋ"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ㄱ")
      isEditingLastCharacter = true
    }
  }

  func ㄴㄹ() {
    if !isEditingLastCharacter || !입력(map: 한글["ㄴㄹ"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ㄴ")
      isEditingLastCharacter = true
    }
  }

  func ㄷㅌ() {
    if !isEditingLastCharacter || !입력(map: 한글["ㄷㅌ"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ㄷ")
      isEditingLastCharacter = true
    }
  }

  func ㅂㅍ() {
    if !isEditingLastCharacter || !입력(map: 한글["ㅂㅍ"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ㅂ")
      isEditingLastCharacter = true
    }
  }

  func ㅅㅎ() {
    if !isEditingLastCharacter || !입력(map: 한글["ㅅㅎ"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ㅅ")
      isEditingLastCharacter = true
    }
  }

  func ㅈㅊ() {
    if !isEditingLastCharacter || !입력(map: 한글["ㅈㅊ"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ㅈ")
      isEditingLastCharacter = true
    }
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
    if !isEditingLastCharacter || !입력(map: 한글["천"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ᆞ")
      isEditingLastCharacter = true
    }
  }

  func 지() {
    if !isEditingLastCharacter || !입력(map: 한글["지"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ㅡ")
      isEditingLastCharacter = true
    }
  }

  func 인() {
    if !isEditingLastCharacter || !입력(map: 한글["인"]) {
      let proxy = textDocumentProxy
      proxy.insertText("ㅣ")
      isEditingLastCharacter = true
    }
  }
}
