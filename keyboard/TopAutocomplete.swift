//
//  TopAutocomplete.swift
//  keyboard
//
//  Created by Sunghyun Cho on 1/15/23.
//

import Foundation

class TopAutocomplete: ObservableObject {
  @Published var list: [String] = []
  var action: (String) -> Void

  init(action: @escaping (String) -> Void) {
    self.action = action
  }
}
