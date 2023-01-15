//
//  KeyboardButton.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import CoreHaptics
import SwiftUI

struct KeyboardButton: View {
  @Environment(\.colorScheme) var colorScheme
  var text: String?
  var systemName: String?
  let primary: Bool
  var action: () -> Void
  var body: some View {
    Button(action: {
      action()
    }) {
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
  }
}
