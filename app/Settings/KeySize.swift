import Foundation

enum KeySize: String, CaseIterable, Identifiable, Sendable {
  case small
  case medium
  case large

  var id: String {
    rawValue
  }

  var label: String {
    switch self {
    case .small: "작게"
    case .medium: "보통"
    case .large: "크게"
    }
  }
}
