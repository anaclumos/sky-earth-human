import SwiftUI

extension KeyStyle {
  var color: Color {
    switch self {
    case .primary: Color(.primaryKeyboardButton)
    case .secondary: Color(.secondaryKeyboardButton)
    }
  }
}
