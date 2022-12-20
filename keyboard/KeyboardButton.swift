//
//  KeyboardButton.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import SwiftUI

struct KeyboardButton: View {
  var text: String?
  var image: String?

  var action: () -> Void
  var body: some View {
    Button(action: action) {
      if image != nil {
        Image(systemName: image!)
          .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
          .font(.system(size: 24))
          .foregroundColor(Color(uiColor: UIColor.label))
          .background(Color(uiColor: UIColor.secondarySystemFill))
          .cornerRadius(5)
      } else if text != nil {
        Text(text!)
          .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
          .font(.system(size: 24))
          .foregroundColor(Color(uiColor: UIColor.label))
          .background(Color(uiColor: UIColor.secondarySystemFill))
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
