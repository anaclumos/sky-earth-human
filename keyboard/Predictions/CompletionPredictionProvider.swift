import HangulEngine
import UIKit

@MainActor
final class CompletionPredictionProvider: PredictionProvider {
  private let limit: Int
  private let source: @MainActor (String) -> [String]
  private let canExtend: @MainActor (String) -> Bool

  init(
    limit: Int = 3,
    source: @escaping @MainActor (String) -> [String],
    canExtend: @escaping @MainActor (String) -> Bool
  ) {
    self.limit = limit
    self.source = source
    self.canExtend = canExtend
  }

  convenience init(limit: Int = 3, canExtend: @escaping @MainActor (String) -> Bool) {
    let checker = UITextChecker()
    self.init(
      limit: limit,
      source: { partial in
        checker.completions(
          forPartialWordRange: NSRange(location: 0, length: partial.utf16.count),
          in: partial,
          language: "ko_KR"
        ) ?? []
      },
      canExtend: canExtend
    )
  }

  func candidates(textBeforeCursor: String, composing: String) -> [PredictionCandidate] {
    let filter = CompletionFilter(textBeforeCursor: textBeforeCursor, composing: composing)
    let found = filter.partialWords.flatMap { source($0) }
    return filter.completions(from: found, limit: limit) { canExtend($0) }.map {
      PredictionCandidate(display: $0.word, replacedLength: $0.replacedLength, insertion: $0.word)
    }
  }
}
