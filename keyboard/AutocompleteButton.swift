//
//  AutocompleteButton.swift
//  keyboard
//
//  Created by Sunghyun Cho on 1/15/23.
//

import SwiftUI

struct AutocompleteButton: View {
  let text: String?
  let action: () -> Void

  var body: some View {
    Button(action: action,
           label: {
             Text(text ?? "")
               .frame(maxWidth: .infinity, minHeight: 60, alignment: .center)
               .foregroundColor(Color(uiColor: UIColor.label))
           }).frame(
      minWidth: 0,
      maxWidth: .infinity,
      minHeight: 0,
      maxHeight: .infinity,
      alignment: .topLeading
    )
    .font(.system(size: 16))
  }
}
