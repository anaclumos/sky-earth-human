import CoreGraphics

enum KeySize: String, CaseIterable, Sendable {
  case small
  case medium
  case large

  static let `default` = KeySize.medium

  var fontSize: CGFloat {
    switch self {
    case .small: 20
    case .medium: 24
    case .large: 28
    }
  }
}
