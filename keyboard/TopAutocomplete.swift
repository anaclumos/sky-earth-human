import Foundation
import UIKit

protocol AutocompleteService {
  func suggestions(for contextBeforeInput: String) -> [String]
  func learn(word: String)
}

final class UITextCheckerAutocompleteService: AutocompleteService {
  private let checker = UITextChecker()
  private let language: String

  init(language: String = "ko_KR") {
    self.language = language
  }

  func suggestions(for contextBeforeInput: String) -> [String] {
    let lastWord = KeyboardInputEngine.currentWord(from: contextBeforeInput)
    guard !lastWord.isEmpty else { return [] }

    let range = NSRange(location: 0, length: lastWord.utf16.count)
    let guesses = checker.completions(forPartialWordRange: range, in: lastWord, language: language) ?? []

    if guesses.first == lastWord {
      return Array(guesses.dropFirst())
    }

    return guesses
  }

  func learn(word: String) {
    guard !word.isEmpty else { return }
    UITextChecker.learnWord(word)
  }
}
