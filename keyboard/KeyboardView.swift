//
//  KeyboardView.swift
//  keyboard
//
//  Created by Sunghyun Cho on 12/20/22.
//

import SwiftUI

struct KeyboardView: View {
  @EnvironmentObject var options: KeyboardOptions
  @EnvironmentObject var autocomplete: TopAutocomplete
  let sharedDefaults = UserDefaults(suiteName: "group.sh.cho.sky-earth-human.settings")

  var isAutocompleteEnabled: Bool {
    sharedDefaults?.object(forKey: "isAutocompleteEnabled") as? Bool ?? true
  }

  var body: some View {
    VStack(spacing: 0) {
      if isAutocompleteEnabled {
        HStack {
          AutocompleteButton(
            text: autocomplete.list.count >= 1 ? autocomplete.list[0] : "",
            action: {
              if autocomplete.list.count >= 1 {
                autocomplete.action(autocomplete.list[0])
              }
            })
          Divider()
          AutocompleteButton(
            text: autocomplete.list.count >= 2 ? autocomplete.list[1] : "",
            action: {
              if autocomplete.list.count >= 2 {
                autocomplete.action(autocomplete.list[1])
              }
            })
          Divider()
          AutocompleteButton(
            text: autocomplete.list.count >= 3 ? autocomplete.list[2] : "",
            action: {
              if autocomplete.list.count >= 3 {
                autocomplete.action(autocomplete.list[2])
              }
            })
        }
        .frame(height: 50, alignment: .center)
        .background(
          Color("KeyboardBackground")
        )
        .padding(5)
      } else {
        Spacer()
      }
      if options.current == .hangul {
        HangulView()
      } else if options.current == .number {
        NumberView()
      } else if options.current == .symbol {
        SymbolView()
      }
    }
    .background(
      Color("KeyboardBackground")
    )
  }
}
