import SwiftUI

struct KeyboardButton: View {
  @State private var pressed = false
  @State private var didLongPress = false

  var text: String?
  var systemName: String?
  let primary: Bool
  var action: () -> Void
  var onLongPress: (() -> Void)?
  var onLongPressFinished: (() -> Void)?

  private let fontWeight: Font.Weight = UIAccessibility.isBoldTextEnabled ? .bold : .regular

  var body: some View {
    Button(action: handleTap) {
      content
    }
    .frame(
      minWidth: 0,
      maxWidth: .infinity,
      minHeight: 0,
      maxHeight: .infinity,
      alignment: .topLeading
    )
    .font(.system(size: 32))
    .onLongPressGesture(
      minimumDuration: 0.35,
      maximumDistance: 20,
      perform: {
        didLongPress = true
        onLongPress?()
      },
      onPressingChanged: { isPressing in
        if !isPressing {
          onLongPressFinished?()
        }
      }
    )
    .opacity(pressed ? 0.5 : 1.0)
  }

  @ViewBuilder
  private var content: some View {
    if let systemName {
      Image(systemName: systemName)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
        .font(.system(size: 24, weight: fontWeight))
        .foregroundColor(Color(uiColor: UIColor.label))
        .background(primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
        .cornerRadius(5)
    } else {
      Text(text ?? "")
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .center)
        .font(.system(size: 24, weight: fontWeight))
        .foregroundColor(Color(uiColor: UIColor.label))
        .background(primary ? Color("PrimaryKeyboardButton") : Color("SecondaryKeyboardButton"))
        .cornerRadius(5)
    }
  }

  private func handleTap() {
    if didLongPress {
      didLongPress = false
      return
    }

    pressed = true
    action()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
      pressed = false
    }
  }
}
