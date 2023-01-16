//
//  KeyboardButton.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import CoreHaptics
import SwiftUI

struct KeyboardButton: View {
  @State var pressing = false

  @Environment(\.colorScheme) var colorScheme
  var text: String?
  var systemName: String?
  let primary: Bool
  var action: () -> Void
  var onLongPress: (() -> Void)?
  var onLongPressFinished: (() -> Void)?
  var body: some View {
    Button(action: {}) {
      if systemName != nil {
        Image(systemName: systemName!)
          .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
          .font(.system(size: 24))
          .foregroundColor(Color(uiColor: UIColor.label))
          .background(
            primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
          )
          .cornerRadius(5)
      } else if text != nil {
        Text(text!)
          .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
          .font(.system(size: 24))
          .foregroundColor(Color(uiColor: UIColor.label))
          .background(
            primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton")
          )
          .kerning(2)
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
          pressing = true
          onLongPress?()
        }
        .onEnded { _ in
          pressing = false
          onLongPressFinished?()
        }
    )
    .highPriorityGesture(TapGesture()
      .onEnded { _ in
        action()
      }
    )
  }
}
