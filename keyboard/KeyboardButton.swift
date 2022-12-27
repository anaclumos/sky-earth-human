//
//  KeyboardButton.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import SwiftUI

struct KeyboardButton: View {
  @Environment(\.colorScheme) var colorScheme
  var text: String?
  var image: String?
  var action: () -> Void
  var body: some View {
    Button(action: action) {
      if image != nil {
        Image(systemName: image!)
          .frame(maxWidth: .infinity, minHeight: 70, alignment: .center)
          .font(.system(size: 24))
          .foregroundColor(Color(uiColor: UIColor.label))
          .background(
            colorScheme == .dark ? Color(uiColor: UIColor.secondarySystemFill) : Color(uiColor: UIColor.systemGray6)
          )
          .cornerRadius(5)
      } else if text != nil {
        Text(text!)
          .frame(maxWidth: .infinity, minHeight: 70, alignment: .center)
          .font(.system(size: 24))
          .foregroundColor(Color(uiColor: UIColor.label))
          .background(
            colorScheme == .dark ? Color(uiColor: UIColor.secondarySystemFill) : Color(uiColor: UIColor.systemGray6)
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
