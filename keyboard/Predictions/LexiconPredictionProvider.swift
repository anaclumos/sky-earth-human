import HangulEngine
import UIKit

@MainActor
final class LexiconPredictionProvider: PredictionProvider, ShortcutExpander {
  private var matcher = ShortcutMatcher(entries: [])

  func update(with lexicon: UILexicon) {
    update(entries: lexicon.entries.map {
      ShortcutMatcher.Entry(userInput: $0.userInput, documentText: $0.documentText)
    })
  }

  func update(entries: [ShortcutMatcher.Entry]) {
    matcher = ShortcutMatcher(entries: entries)
  }

  func candidates(textBeforeCursor: String, composing: String) -> [PredictionCandidate] {
    guard let candidate = expansion(textBeforeCursor: textBeforeCursor, composing: composing) else { return [] }
    return [candidate]
  }

  func expansion(textBeforeCursor: String, composing: String) -> PredictionCandidate? {
    guard let match = matcher.expansion(textBeforeCursor: textBeforeCursor, composing: composing) else { return nil }
    return PredictionCandidate(
      display: match.replacement,
      replacedLength: match.replacedLength,
      insertion: match.replacement
    )
  }
}
