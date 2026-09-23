enum KeyboardType: Equatable, Sendable {
  case hangul
  case number
  case symbol
}

enum KeyAction: Equatable, Sendable {
  case hangul(HangulKey)
  case insert(String)
  case cycle([String])
  case delete
  case space
  case returnKey
  case dismiss
  case switchKeyboard(KeyboardType)
  case nextSymbolPage
}

enum KeyStyle: Equatable, Sendable {
  case primary
  case secondary
}

enum KeyLabel: Equatable, Sendable {
  case text(String)
  case symbol(String)
  case nextKeyboard
}

struct KeyDescriptor: Identifiable, Equatable, Sendable {
  let id: String
  let label: KeyLabel
  let style: KeyStyle
  let action: KeyAction?
  let longPressAction: KeyAction?
  let accessibilityLabel: String

  init(
    id: String,
    label: KeyLabel,
    style: KeyStyle,
    action: KeyAction?,
    longPressAction: KeyAction? = nil,
    accessibilityLabel: String
  ) {
    self.id = id
    self.label = label
    self.style = style
    self.action = action
    self.longPressAction = longPressAction
    self.accessibilityLabel = accessibilityLabel
  }
}
