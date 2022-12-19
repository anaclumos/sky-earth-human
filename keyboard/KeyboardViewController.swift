//
//  KeyboardViewController.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/19/22.
//

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

    helloButton = UIButton(type: .system)
    helloButton.setTitle("Hello", for: .normal)
    helloButton.addTarget(self, action: #selector(helloButtonTapped), for: .touchUpInside)
    helloButton.sizeToFit()
    helloButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(helloButton)
  }

  @objc func helloButtonTapped() {
    let proxy = textDocumentProxy as UITextDocumentProxy
    proxy.insertText("Hello")
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
}
