import Observation
import UIKit

@MainActor
protocol InsertionAdapter: AnyObject {
  var textBeforeCursor: String { get }
  /// False while a host call waits for a run loop turn of its own. Nothing may read or mutate
  /// through the adapter until `onSettle` fires, docs/status/K2.md findings 6 and 7.
  var isSettled: Bool { get }
  var onSettle: (() -> Void)? { get set }
  /// Fired from `settle()` when a host change the adapter could not yet tell from its own
  /// return's answer turns out to be the host's, before the next mutation. The composition is
  /// gone from the host, docs/status/K2.md finding 9.
  var onHostChange: (() -> Void)? { get set }
  func settle()
  func setComposing(_ text: String)
  func commit(_ text: String)
  func deleteBackward()
  func replace(deleting count: Int, with text: String)
  func insertReturn()
}

struct PredictionCandidate: Hashable, Sendable {
  let display: String
  let replacedLength: Int
  let insertion: String
}

@MainActor
protocol PredictionProvider: AnyObject {
  func candidates(textBeforeCursor: String, composing: String) -> [PredictionCandidate]
}

protocol SettingsReader: Sendable {
  var keySize: KeySize { get }
  var isHapticFeedbackEnabled: Bool { get }
  var isPredictionEnabled: Bool { get }
  var cycleLock: Duration { get }
  func reload()
}

enum FeedbackKind: Equatable, Sendable {
  case input
  case delete
  case modifier
}

@MainActor
protocol FeedbackPlayer: AnyObject {
  func play(_ kind: FeedbackKind)
}

@MainActor
protocol KeyActionHandler: AnyObject {
  func handle(_ action: KeyAction)
}

@Observable
@MainActor
final class KeyboardModel {
  private(set) var keyboardType: KeyboardType = .hangul
  private(set) var symbolPage = 0
  private(set) var keySize = KeySize.default
  private(set) var isPredictionEnabled = true

  @ObservationIgnored let showsNextKeyboardKey: Bool
  @ObservationIgnored private let settings: any SettingsReader
  @ObservationIgnored private let feedback: any FeedbackPlayer
  @ObservationIgnored private let actions: any KeyActionHandler
  @ObservationIgnored private let dismissKeyboard: () -> Void
  @ObservationIgnored private let configureNextKeyboardButton: (UIButton) -> Void
  @ObservationIgnored private var deleteRepeat: Task<Void, Never>?

  init(
    showsNextKeyboardKey: Bool,
    settings: any SettingsReader,
    feedback: any FeedbackPlayer,
    actions: any KeyActionHandler,
    dismissKeyboard: @escaping () -> Void,
    configureNextKeyboardButton: @escaping (UIButton) -> Void
  ) {
    self.showsNextKeyboardKey = showsNextKeyboardKey
    self.settings = settings
    self.feedback = feedback
    self.actions = actions
    self.dismissKeyboard = dismissKeyboard
    self.configureNextKeyboardButton = configureNextKeyboardButton
    keySize = settings.keySize
    isPredictionEnabled = settings.isPredictionEnabled
  }

  var rows: [[KeyDescriptor]] {
    KeyboardLayout.rows(
      for: keyboardType,
      symbolPage: symbolPage,
      showsNextKeyboardKey: showsNextKeyboardKey
    )
  }

  func reloadSettings() {
    settings.reload()
    keySize = settings.keySize
    isPredictionEnabled = settings.isPredictionEnabled
  }

  func configure(nextKeyboardButton button: UIButton) {
    configureNextKeyboardButton(button)
  }

  func press(_ key: KeyDescriptor) {
    guard let action = key.action else { return }
    perform(action)
  }

  func longPress(_ key: KeyDescriptor) {
    guard let action = key.longPressAction else { return }
    perform(action)
  }

  /// The first delete lands when the repeat starts, not one tick later, so a hold that ends between the
  /// long press threshold and the first tick still deletes.
  func beginDeleteRepeat() {
    guard deleteRepeat == nil else { return }
    perform(.delete)
    deleteRepeat = Task { [weak self] in
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(100))
        guard let self, !Task.isCancelled else { return }
        perform(.delete)
      }
    }
  }

  func endDeleteRepeat() {
    deleteRepeat?.cancel()
    deleteRepeat = nil
  }

  private func perform(_ action: KeyAction) {
    feedback.play(feedbackKind(for: action))
    actions.handle(action)

    switch action {
    case let .switchKeyboard(type):
      keyboardType = type
    case .nextSymbolPage:
      symbolPage = (symbolPage + 1) % KeyboardLayout.symbolPages.count
    case .dismiss:
      dismissKeyboard()
    case .hangul, .insert, .cycle, .delete, .space, .returnKey:
      break
    }
  }

  private func feedbackKind(for action: KeyAction) -> FeedbackKind {
    switch action {
    case .delete:
      .delete
    case .space, .returnKey, .dismiss, .switchKeyboard, .nextSymbolPage:
      .modifier
    case .hangul, .insert, .cycle:
      .input
    }
  }
}
