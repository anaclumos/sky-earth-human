import SwiftUI

struct KeyButton: View {
  @Environment(\.legibilityWeight) private var legibilityWeight

  let key: KeyDescriptor
  let keySize: KeySize
  let onPress: () -> Void
  let onLongPress: (() -> Void)?
  let onLongPressEnded: () -> Void

  var body: some View {
    Button(action: onPress) {
      KeyFace(label: key.label, style: key.style, keySize: keySize, legibilityWeight: legibilityWeight)
    }
    .buttonStyle(KeyButtonStyle(onLongPress: onLongPress, onLongPressEnded: onLongPressEnded))
    .accessibilityIdentifier(key.id)
    .accessibilityLabel(key.accessibilityLabel)
    .accessibilityAddTraits(.isKeyboardKey)
  }
}

/// A `Button` recognizes its own tap before any gesture a modifier adds, so a long press attached to the
/// button never wins. A `PrimitiveButtonStyle` replaces that built in interaction with this one, and
/// `configuration.trigger()` is what raises the button's action.
struct KeyButtonStyle: PrimitiveButtonStyle {
  let onLongPress: (() -> Void)?
  let onLongPressEnded: () -> Void

  func makeBody(configuration: Configuration) -> some View {
    KeyButtonSurface(configuration: configuration, onLongPress: onLongPress, onLongPressEnded: onLongPressEnded)
  }
}

/// A style is not a `View`, so the press state lives in this body instead.
/// `onLongPress` is nil for a key that has nothing to do on a long press. Those keys must still act on
/// lift however long they were held, so the threshold passes without claiming the press.
private struct KeyButtonSurface: View {
  @State private var isPressed = false
  @State private var didLongPress = false

  let configuration: PrimitiveButtonStyleConfiguration
  let onLongPress: (() -> Void)?
  let onLongPressEnded: () -> Void

  var body: some View {
    configuration.label
      .opacity(isPressed ? 0.5 : 1)
      .onLongPressGesture(minimumDuration: 0.35, maximumDistance: 20) {
        guard let onLongPress else { return }
        didLongPress = true
        onLongPress()
      } onPressingChanged: { isPressing in
        isPressed = isPressing
        guard !isPressing else { return }
        if didLongPress {
          didLongPress = false
          onLongPressEnded()
        } else {
          configuration.trigger()
        }
      }
  }
}

struct KeyFace: View {
  let label: KeyLabel
  let style: KeyStyle
  let keySize: KeySize
  let legibilityWeight: LegibilityWeight?

  var body: some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .font(.system(size: keySize.fontSize, weight: legibilityWeight == .bold ? .bold : .regular))
      .foregroundStyle(Color.primary)
      .background(style.color, in: .rect(cornerRadius: 5))
  }

  @ViewBuilder
  private var content: some View {
    switch label {
    case let .text(value):
      Text(value)
    case let .symbol(name):
      Image(systemName: name)
    case .nextKeyboard:
      Image(systemName: "globe")
    }
  }
}
