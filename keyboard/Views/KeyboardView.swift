import SwiftUI

struct KeyboardView: View {
  let model: KeyboardModel

  var body: some View {
    VStack(spacing: 8) {
      ForEach(Array(model.rows.enumerated()), id: \.offset) { _, row in
        HStack(spacing: 8) {
          ForEach(row) { key in
            keyView(for: key)
          }
        }
      }
    }
    .frame(maxWidth: 500, maxHeight: .infinity)
    .padding(.horizontal, 10)
    .padding(.bottom, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.keyboardBackground))
    .onAppear {
      model.reloadSettings()
    }
    .onDisappear {
      model.endDeleteRepeat()
    }
  }

  @ViewBuilder
  private func keyView(for key: KeyDescriptor) -> some View {
    switch key.label {
    case .nextKeyboard:
      NextKeyboardButton(key: key, keySize: model.keySize, configure: model.configure(nextKeyboardButton:))
    case .text, .symbol:
      KeyButton(
        key: key,
        keySize: model.keySize,
        onPress: { model.press(key) },
        onLongPress: longPress(for: key),
        onLongPressEnded: {
          if key.action == .delete {
            model.endDeleteRepeat()
          }
        }
      )
    }
  }

  /// Nil for a key with nothing to do on a long press, so `KeyButton` leaves it to act on lift.
  private func longPress(for key: KeyDescriptor) -> (() -> Void)? {
    if key.action == .delete {
      return { model.beginDeleteRepeat() }
    }
    guard key.longPressAction != nil else { return nil }
    return { model.longPress(key) }
  }
}
