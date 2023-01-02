// Source: https://github.com/littleossa/CustomKeyboardProject/blob/main/HelloWorldKeyboard/NextKeyboardButton.swift

import SwiftUI
import UIKit

struct NextKeyboardButton: View {
  let systemName: String
  let action: Selector
  let primary: Bool
  var body: some View {
    Image(systemName: systemName)
      .overlay {
        NextKeyboardButtonOverlay(action: action)
      }.background(
        primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
      )
  }
}

struct NextKeyboardButtonOverlay: UIViewRepresentable {
  let action: Selector
  func makeUIView(context _: Context) -> UIButton {
    let button = UIButton()
    button.addTarget(nil,
                     action: action,
                     for: .allTouchEvents)
    return button
  }

  func updateUIView(_: UIButton, context _: Context) {}
}
