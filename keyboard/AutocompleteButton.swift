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
    Button(
      action: action,
      label: {
        Text(text ?? "")
          .frame(
            idealWidth: .infinity,
            maxWidth: .infinity,
            minHeight: 0,
            idealHeight: 40,
            alignment: .center
          )
          .foregroundColor(Color(uiColor: UIColor.label))
      }
    ).frame(
      minWidth: 0,
      idealWidth: .infinity,
      maxWidth: .infinity,
      minHeight: 0,
      idealHeight: 40,
      alignment: .center
    ).frame(
      minWidth: 0,
      idealWidth: .infinity,
      maxWidth: .infinity,
      idealHeight: 40,
      maxHeight: .infinity,
      alignment: .center
    )
  }
}
