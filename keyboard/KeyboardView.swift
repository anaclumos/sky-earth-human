import SwiftUI

struct KeyboardView: View {
  @EnvironmentObject var viewModel: KeyboardViewModel

  var body: some View {
    VStack(spacing: 0) {
      if viewModel.isAutocompleteEnabled {
        HStack {
          autocompleteButton(at: 0)
          Divider()
          autocompleteButton(at: 1)
          Divider()
          autocompleteButton(at: 2)
        }
        .frame(height: 50, alignment: .center)
        .background(Color("KeyboardBackground"))
        .padding(5)
      } else {
        Spacer(minLength: 0)
      }

      switch viewModel.current {
      case .hangul:
        HangulView()
      case .number:
        NumberView()
      case .symbol:
        SymbolView()
      }
    }
    .background(Color("KeyboardBackground"))
    .onAppear {
      viewModel.refreshAutocomplete()
    }
  }

  @ViewBuilder
  private func autocompleteButton(at index: Int) -> some View {
    let suggestions = viewModel.autocompleteList
    let text = suggestions.indices.contains(index) ? suggestions[index] : ""

    AutocompleteButton(text: text) {
      guard suggestions.indices.contains(index) else { return }
      viewModel.selectAutocomplete(suggestions[index])
    }
  }
}
