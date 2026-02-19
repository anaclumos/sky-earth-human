import Foundation

protocol KeyboardTextInputProxy: AnyObject {
  var documentContextBeforeInput: String? { get }
  func insertText(_ text: String)
  func deleteBackward()
}

struct KeyboardCompositionState: Equatable {
  var proxyBackup = ""
  var proxyHistory: [String] = []
  var isEditingLastCharacter = false
}

final class KeyboardInputEngine {
  private(set) var state = KeyboardCompositionState()
  private let hangulMap: [String: [String: String]]

  init(hangulMap: [String: [String: String]]) {
    self.hangulMap = hangulMap
  }

  func resetComposition() {
    state = KeyboardCompositionState()
  }

  func simpleInput(_ input: String, proxy: KeyboardTextInputProxy) {
    proxy.insertText(input)
    state.proxyBackup = input
    state.proxyHistory = [input]
    state.isEditingLastCharacter = true
  }

  func insertHangul(key: String, fallback: String, proxy: KeyboardTextInputProxy) {
    guard let map = hangulMap[key] else {
      simpleInput(fallback, proxy: proxy)
      return
    }

    if let context = proxy.documentContextBeforeInput {
      if !context.suffix(2).contains(state.proxyBackup) {
        resetComposition()
      }
    } else {
      resetComposition()
    }

    if !state.isEditingLastCharacter {
      proxy.insertText(fallback)
      state.proxyBackup = fallback
      state.proxyHistory = [fallback]
      state.isEditingLastCharacter = true
      return
    }

    if state.proxyBackup.count > 1 {
      let lastTwoCharacters = String(state.proxyBackup.suffix(2))
      if let next = map[lastTwoCharacters] {
        proxy.deleteBackward()
        proxy.deleteBackward()
        proxy.insertText(next)
        state.proxyBackup = next
        state.proxyHistory = [next]
        return
      }
    }

    if !state.proxyBackup.isEmpty {
      let lastCharacter = String(state.proxyBackup.suffix(1))
      if let next = map[lastCharacter] {
        proxy.deleteBackward()
        proxy.insertText(next)
        state.proxyBackup = next

        if lastCharacter.count != next.count {
          state.proxyHistory = [String(next.suffix(1))]
        } else {
          state.proxyHistory.append(next)
        }
        return
      }
    }

    proxy.insertText(fallback)
    state.isEditingLastCharacter = true
    state.proxyBackup += fallback
    state.proxyHistory = [fallback]
  }

  func composableInput(candidates: [String], proxy: KeyboardTextInputProxy) {
    guard let first = candidates.first else { return }

    if state.isEditingLastCharacter,
      let lastCharacter = proxy.documentContextBeforeInput?.last,
      let currentIndex = candidates.firstIndex(where: { $0.first == lastCharacter })
    {
      proxy.deleteBackward()
      let nextIndex = (currentIndex + 1) % candidates.count
      let next = candidates[nextIndex]
      proxy.insertText(next)
      state.proxyBackup = next
      state.proxyHistory = []
      return
    }

    proxy.insertText(first)
    state.isEditingLastCharacter = true
    state.proxyBackup = first
    state.proxyHistory = []
  }

  func deleteBackward(proxy: KeyboardTextInputProxy) {
    if state.proxyHistory.count > 1 {
      for _ in 0..<(state.proxyHistory.last?.count ?? 0) {
        proxy.deleteBackward()
      }
      if state.isEditingLastCharacter {
        state.proxyHistory.removeLast()
      }
      let last = state.proxyHistory.last ?? ""
      proxy.insertText(last)
      state.proxyBackup = last
      return
    }

    state.isEditingLastCharacter = false
    proxy.deleteBackward()
    state.proxyBackup = ""
    state.proxyHistory = []
  }

  @discardableResult
  func space(proxy: KeyboardTextInputProxy) -> String? {
    if !state.isEditingLastCharacter {
      let lastWord = Self.currentWord(from: proxy.documentContextBeforeInput ?? "")
      state.proxyHistory = []
      state.proxyBackup = ""
      proxy.insertText(" ")
      return lastWord.isEmpty ? nil : lastWord
    }

    resetComposition()
    return nil
  }

  @discardableResult
  func returnKey(proxy: KeyboardTextInputProxy) -> String? {
    let lastWord = Self.currentWord(from: proxy.documentContextBeforeInput ?? "")
    state.proxyHistory = []
    state.proxyBackup = ""
    state.isEditingLastCharacter = false
    proxy.insertText("\n")
    return lastWord.isEmpty ? nil : lastWord
  }

  @discardableResult
  func autocomplete(completion: String, proxy: KeyboardTextInputProxy) -> String {
    while let lastCharacter = proxy.documentContextBeforeInput?.last, !lastCharacter.isWhitespace {
      proxy.deleteBackward()
    }
    proxy.insertText(completion + " ")
    state.proxyBackup = completion
    state.proxyHistory = []
    state.isEditingLastCharacter = false
    return completion
  }

  static func currentWord(from text: String) -> String {
    String(text.split(whereSeparator: { $0.isWhitespace }).last ?? "")
  }
}
