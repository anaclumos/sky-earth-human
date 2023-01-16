//
//  KeyboardView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import SwiftUI

struct KeyboardView: View {
  @EnvironmentObject var options: KeyboardOptions
  var body: some View {
    if options.current == .hangul {
      HangulView()
    } else if options.current == .number {
      NumberView()
    } else if options.current == .symbol {
      SymbolView()
    }
  }
}
