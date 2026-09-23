import SwiftUI
import UIKit

struct NextKeyboardButton: View {
  @Environment(\.legibilityWeight) private var legibilityWeight

  let key: KeyDescriptor
  let keySize: KeySize
  let configure: (UIButton) -> Void

  var body: some View {
    KeyFace(label: key.label, style: key.style, keySize: keySize, legibilityWeight: legibilityWeight)
      .overlay {
        NextKeyboardButtonOverlay(configure: configure)
      }
      .accessibilityIdentifier(key.id)
      .accessibilityLabel(key.accessibilityLabel)
      .accessibilityAddTraits(.isKeyboardKey)
  }
}

struct NextKeyboardButtonOverlay: UIViewRepresentable {
  let configure: (UIButton) -> Void

  func makeUIView(context _: Context) -> UIButton {
    let button = UIButton()
    configure(button)
    return button
  }

  func updateUIView(_: UIButton, context _: Context) {}
}
