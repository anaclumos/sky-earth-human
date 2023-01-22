//
//  KeyboardButton.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import SwiftUI

struct KeyboardButton: View {
  @State private var pressed: Bool = false
  @Environment(\.colorScheme) var colorScheme

  var text: String?
  var systemName: String?
  let primary: Bool
  var action: () -> Void
  var onLongPress: (() -> Void)?
  var onLongPressFinished: (() -> Void)?

  let fontWeight: Font.Weight = UIAccessibility.isBoldTextEnabled ? .bold : .regular

  var body: some View {
    Button(action: {}) {
      if systemName != nil {
        Image(systemName: systemName!)
          .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
          .font(.system(size: 24, weight: fontWeight))
          .foregroundColor(Color(uiColor: UIColor.label))
          .background(
            primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
          )
          .cornerRadius(5)
      } else if text != nil {
        Text(text!)
          .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
          .font(.system(size: 24, weight: fontWeight))
          .foregroundColor(Color(uiColor: UIColor.label))
          .background(
            primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
          )
          .cornerRadius(5)
      }
    }
    .frame(
      minWidth: 0,
      maxWidth: .infinity,
      minHeight: 0,
      maxHeight: .infinity,
      alignment: .topLeading
    )
    .font(.system(size: 32))
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          onLongPress?()
        }
        .onEnded { _ in
          onLongPressFinished?()
        }
    )
    .highPriorityGesture(
      withAnimation(.easeInOut(duration: 0.5)) {
        TapGesture()
          .onEnded { _ in
            pressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
              pressed = false
            }
          }
      })
    .opacity(pressed ? 0.5 : 1.0)
  }
}
