import Foundation
import SwiftUI

enum KeyboardType {
  case hangul
  case number
  case symbol
}

enum KeyboardAction: Equatable {
  case hangul(key: String, fallback: String)
  case cycle([String])
  case simpleInput(String)
  case delete
  case space
  case returnKey
  case dismissKeyboard
  case switchKeyboardType(KeyboardType)
  case nextSymbolPage
  case autocomplete(String)
}

struct KeyboardKeyDescriptor: Identifiable, Equatable {
  let id: String
  let text: String?
  let systemName: String?
  let primary: Bool
  let action: KeyboardAction?
  let longPressAction: KeyboardAction?
  let isNextKeyboardKey: Bool

  static func text(
    id: String,
    value: String,
    primary: Bool,
    action: KeyboardAction?,
    longPressAction: KeyboardAction? = nil
  ) -> KeyboardKeyDescriptor {
    KeyboardKeyDescriptor(
      id: id,
      text: value,
      systemName: nil,
      primary: primary,
      action: action,
      longPressAction: longPressAction,
      isNextKeyboardKey: false
    )
  }

  static func system(
    id: String,
    systemName: String,
    primary: Bool,
    action: KeyboardAction?
  ) -> KeyboardKeyDescriptor {
    KeyboardKeyDescriptor(
      id: id,
      text: nil,
      systemName: systemName,
      primary: primary,
      action: action,
      longPressAction: nil,
      isNextKeyboardKey: false
    )
  }

  static func nextKeyboard(id: String = "next-keyboard", primary: Bool) -> KeyboardKeyDescriptor {
    KeyboardKeyDescriptor(
      id: id,
      text: nil,
      systemName: "globe",
      primary: primary,
      action: nil,
      longPressAction: nil,
      isNextKeyboardKey: true
    )
  }
}

protocol FeedbackService {
  func playHaptics()
  func playTypeSound()
  func playDeleteSound()
  func playModifierSound()
}

final class KeyboardViewModel: ObservableObject {
  @Published var current: KeyboardType = .hangul
  @Published var autocompleteList: [String] = []
  @Published private(set) var symbolPage: Int = 0

  let needsInputModeSwitchKey: Bool
  let nextKeyboardAction: Selector

  private weak var proxy: KeyboardTextInputProxy?
  private let inputEngine: KeyboardInputEngine
  private let autocompleteService: AutocompleteService
  private let settingsStore: SettingsStore
  private let feedback: FeedbackService
  private let dismissKeyboardAction: () -> Void

  private let symbolPages = [
    ["!", "?", ".", ",", "(", ")", "@", ":", "/", "-", "★", "°", "*", "_", "%", "~", "^", "#"],
    ["$", "₩", "€", "↖", "↑", "↗", "£", "¥", "=", "←", "♥", "→", "+", "×", "÷", "↙", "↓", "↘"],
    ["《", "》", "『", "』", "\"", "'", "`", "※", "|", "&", "\\", ";", "<", ">", "{", "}", "[", "]"],
  ]

  init(
    needsInputModeSwitchKey: Bool,
    nextKeyboardAction: Selector,
    proxy: KeyboardTextInputProxy,
    inputEngine: KeyboardInputEngine,
    autocompleteService: AutocompleteService,
    settingsStore: SettingsStore,
    feedback: FeedbackService,
    dismissKeyboardAction: @escaping () -> Void
  ) {
    self.needsInputModeSwitchKey = needsInputModeSwitchKey
    self.nextKeyboardAction = nextKeyboardAction
    self.proxy = proxy
    self.inputEngine = inputEngine
    self.autocompleteService = autocompleteService
    self.settingsStore = settingsStore
    self.feedback = feedback
    self.dismissKeyboardAction = dismissKeyboardAction
  }

  var isAutocompleteEnabled: Bool {
    settingsStore.bool(for: .isAutocompleteEnabled)
  }

  func rows(for mode: KeyboardType) -> [[KeyboardKeyDescriptor]] {
    switch mode {
    case .hangul:
      return hangulRows()
    case .number:
      return numberRows()
    case .symbol:
      return symbolRows()
    }
  }

  func refreshAutocomplete() {
    guard isAutocompleteEnabled, let proxy else {
      autocompleteList = []
      return
    }

    autocompleteList = autocompleteService.suggestions(for: proxy.documentContextBeforeInput ?? "")
  }

  func handleTap(on key: KeyboardKeyDescriptor) {
    guard let action = key.action else { return }
    execute(action, asLongPress: false)
  }

  func handleLongPress(on key: KeyboardKeyDescriptor) {
    guard let action = key.longPressAction else { return }
    execute(action, asLongPress: true)
  }

  func handleDeleteRepeat() {
    execute(.delete, asLongPress: true)
  }

  func selectAutocomplete(_ completion: String) {
    execute(.autocomplete(completion), asLongPress: false)
  }

  private func execute(_ action: KeyboardAction, asLongPress _: Bool) {
    if shouldPlayFeedback(for: action) {
      playFeedback(for: action)
    }

    switch action {
    case let .hangul(key, fallback):
      guard let proxy else { return }
      inputEngine.insertHangul(key: key, fallback: fallback, proxy: proxy)

    case let .cycle(candidates):
      guard let proxy else { return }
      inputEngine.composableInput(candidates: candidates, proxy: proxy)

    case let .simpleInput(value):
      guard let proxy else { return }
      inputEngine.simpleInput(value, proxy: proxy)

    case .delete:
      guard let proxy else { return }
      inputEngine.deleteBackward(proxy: proxy)

    case .space:
      guard let proxy else { return }
      if let learnedWord = inputEngine.space(proxy: proxy) {
        autocompleteService.learn(word: learnedWord)
      }

    case .returnKey:
      guard let proxy else { return }
      if let learnedWord = inputEngine.returnKey(proxy: proxy) {
        autocompleteService.learn(word: learnedWord)
      }

    case .dismissKeyboard:
      inputEngine.resetComposition()
      dismissKeyboardAction()

    case let .switchKeyboardType(type):
      current = type

    case .nextSymbolPage:
      symbolPage = (symbolPage + 1) % symbolPages.count

    case let .autocomplete(completion):
      guard let proxy else { return }
      let learnedWord = inputEngine.autocomplete(completion: completion, proxy: proxy)
      autocompleteService.learn(word: learnedWord)
    }

    refreshAutocomplete()
  }

  private func shouldPlayFeedback(for _: KeyboardAction) -> Bool {
    true
  }

  private func playFeedback(for action: KeyboardAction) {
    switch action {
    case .delete:
      feedback.playDeleteSound()
    case .space, .returnKey, .dismissKeyboard, .switchKeyboardType(_), .nextSymbolPage:
      feedback.playModifierSound()
    case .hangul(_, _), .cycle(_), .simpleInput(_), .autocomplete(_):
      feedback.playTypeSound()
    }
    feedback.playHaptics()
  }

  private func hangulRows() -> [[KeyboardKeyDescriptor]] {
    var row4: [KeyboardKeyDescriptor] = [
      .text(id: "hangul-switch-number", value: "!#1", primary: false, action: .switchKeyboardType(.number))
    ]

    if needsInputModeSwitchKey {
      row4.append(.nextKeyboard(primary: false))
    }

    row4.append(
      .text(
        id: "hangul-0",
        value: "ㅇㅁ",
        primary: true,
        action: .hangul(key: "ㅇㅁ", fallback: "ㅇ"),
        longPressAction: .simpleInput("0")
      ))
    row4.append(.system(id: "hangul-space", systemName: "space", primary: false, action: .space))
    row4.append(
      .system(
        id: "hangul-dismiss",
        systemName: "keyboard.chevron.compact.down.fill",
        primary: false,
        action: .dismissKeyboard
      ))

    return [
      [
        .text(
          id: "hangul-1",
          value: "ㅣ",
          primary: true,
          action: .hangul(key: "인", fallback: "ㅣ"),
          longPressAction: .simpleInput("1")
        ),
        .text(
          id: "hangul-2",
          value: "·",
          primary: true,
          action: .hangul(key: "천", fallback: "ᆞ"),
          longPressAction: .simpleInput("2")
        ),
        .text(
          id: "hangul-3",
          value: "ㅡ",
          primary: true,
          action: .hangul(key: "지", fallback: "ㅡ"),
          longPressAction: .simpleInput("3")
        ),
        .system(id: "hangul-delete", systemName: "delete.left.fill", primary: false, action: .delete),
      ],
      [
        .text(
          id: "hangul-4",
          value: "ㄱㅋ",
          primary: true,
          action: .hangul(key: "ㄱㅋ", fallback: "ㄱ"),
          longPressAction: .simpleInput("4")
        ),
        .text(
          id: "hangul-5",
          value: "ㄴㄹ",
          primary: true,
          action: .hangul(key: "ㄴㄹ", fallback: "ㄴ"),
          longPressAction: .simpleInput("5")
        ),
        .text(
          id: "hangul-6",
          value: "ㄷㅌ",
          primary: true,
          action: .hangul(key: "ㄷㅌ", fallback: "ㄷ"),
          longPressAction: .simpleInput("6")
        ),
        .system(id: "hangul-return", systemName: "return", primary: false, action: .returnKey),
      ],
      [
        .text(
          id: "hangul-7",
          value: "ㅂㅍ",
          primary: true,
          action: .hangul(key: "ㅂㅍ", fallback: "ㅂ"),
          longPressAction: .simpleInput("7")
        ),
        .text(
          id: "hangul-8",
          value: "ㅅㅎ",
          primary: true,
          action: .hangul(key: "ㅅㅎ", fallback: "ㅅ"),
          longPressAction: .simpleInput("8")
        ),
        .text(
          id: "hangul-9",
          value: "ㅈㅊ",
          primary: true,
          action: .hangul(key: "ㅈㅊ", fallback: "ㅈ"),
          longPressAction: .simpleInput("9")
        ),
        .text(id: "hangul-punctuation", value: ".,?!", primary: false, action: .cycle([".", ",", "?", "!"])),
      ],
      row4,
    ]
  }

  private func numberRows() -> [[KeyboardKeyDescriptor]] {
    var row4: [KeyboardKeyDescriptor] = [
      .text(id: "number-switch-symbol", value: "@#", primary: false, action: .switchKeyboardType(.symbol))
    ]

    if needsInputModeSwitchKey {
      row4.append(.nextKeyboard(primary: false))
    }

    row4.append(.text(id: "number-0", value: "0", primary: true, action: .simpleInput("0")))
    row4.append(.system(id: "number-space", systemName: "space", primary: false, action: .space))
    row4.append(
      .system(
        id: "number-dismiss",
        systemName: "keyboard.chevron.compact.down.fill",
        primary: false,
        action: .dismissKeyboard
      ))

    return [
      [
        .text(id: "number-1", value: "1", primary: true, action: .simpleInput("1")),
        .text(id: "number-2", value: "2", primary: true, action: .simpleInput("2")),
        .text(id: "number-3", value: "3", primary: true, action: .simpleInput("3")),
        .system(id: "number-delete", systemName: "delete.left.fill", primary: false, action: .delete),
      ],
      [
        .text(id: "number-4", value: "4", primary: true, action: .simpleInput("4")),
        .text(id: "number-5", value: "5", primary: true, action: .simpleInput("5")),
        .text(id: "number-6", value: "6", primary: true, action: .simpleInput("6")),
        .system(id: "number-return", systemName: "return", primary: false, action: .returnKey),
      ],
      [
        .text(id: "number-7", value: "7", primary: true, action: .simpleInput("7")),
        .text(id: "number-8", value: "8", primary: true, action: .simpleInput("8")),
        .text(id: "number-9", value: "9", primary: true, action: .simpleInput("9")),
        .text(id: "number-punctuation", value: ".,?!", primary: false, action: .cycle([".", ",", "?", "!"])),
      ],
      row4,
    ]
  }

  private func symbolRows() -> [[KeyboardKeyDescriptor]] {
    let currentPage = symbolPages[symbolPage]

    var row4: [KeyboardKeyDescriptor] = [
      .text(id: "symbol-switch-hangul", value: "한", primary: false, action: .switchKeyboardType(.hangul))
    ]

    if needsInputModeSwitchKey {
      row4.append(.nextKeyboard(primary: false))
    }

    row4.append(
      .text(
        id: "symbol-page",
        value: "\(symbolPage + 1)/\(symbolPages.count)",
        primary: true,
        action: .nextSymbolPage
      ))
    row4.append(.system(id: "symbol-space", systemName: "space", primary: false, action: .space))
    row4.append(
      .system(
        id: "symbol-dismiss",
        systemName: "keyboard.chevron.compact.down.fill",
        primary: false,
        action: .dismissKeyboard
      ))

    return [
      symbolsRow(for: currentPage, row: 0, trailing: .system(id: "symbol-delete", systemName: "delete.left.fill", primary: false, action: .delete)),
      symbolsRow(for: currentPage, row: 1, trailing: .system(id: "symbol-return", systemName: "return", primary: false, action: .returnKey)),
      symbolsRow(for: currentPage, row: 2, trailing: .text(id: "symbol-punctuation", value: ".,?!", primary: false, action: .cycle([".", ",", "?", "!"]))),
      row4,
    ]
  }

  private func symbolsRow(
    for page: [String],
    row: Int,
    trailing: KeyboardKeyDescriptor
  ) -> [KeyboardKeyDescriptor] {
    let start = row * 6
    let values = Array(page[start..<(start + 6)])

    var keys: [KeyboardKeyDescriptor] = []
    keys.reserveCapacity(7)

    for (index, value) in values.enumerated() {
      keys.append(
        .text(
          id: "symbol-\(row)-\(index)",
          value: value,
          primary: true,
          action: .simpleInput(value)
        ))
    }

    keys.append(trailing)
    return keys
  }
}
