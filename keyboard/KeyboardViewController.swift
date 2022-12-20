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

    let keyboardView = UIHostingController(rootView: KeyboardView(buttonAction: buttonAction))
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
      proxy.insertText("ㅣ")
    case 1:
      proxy.insertText("•")
    case 2:
      proxy.insertText("ㅡ")
    case 3:
      proxy.deleteBackward()
    case 4:
      proxy.insertText("ㄱㅋ")
    case 5:
      proxy.insertText("ㄴㄹ")
    case 6:
      proxy.insertText("ㄷㅌ")
    case 7:
      proxy.insertText("\n")
    case 8:
      proxy.insertText("ㅂㅍ")
    case 9:
      proxy.insertText("ㅅㅎ")
    case 10:
      proxy.insertText("ㅈㅊ")
    case 11:
      proxy.insertText(".,?!")
    case 12:
      proxy.insertText("!#1")
    case 13:
      proxy.insertText("ㅇㅁ")
    case 14:
      proxy.insertText(" ")
    case 15:
      proxy.insertText(",")
    default:
      proxy.insertText(" ")
    }
  }
}
