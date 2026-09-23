public struct CompletionFilter: Sendable {
  public struct Completion: Equatable, Sendable {
    public let word: String
    public let replacedLength: Int

    public init(word: String, replacedLength: Int) {
      self.word = word
      self.replacedLength = replacedLength
    }
  }

  public let fragment: String
  public let composing: String

  public init(textBeforeCursor: String, composing: String) {
    if let boundary = textBeforeCursor.lastIndex(where: { $0.isWhitespace }) {
      fragment = String(textBeforeCursor[textBeforeCursor.index(after: boundary)...])
    } else {
      fragment = textBeforeCursor
    }
    self.composing = composing
  }

  /// A consonant first lands as a final and moves on when a vowel follows, so up to the last two composing
  /// Characters can still change and the word being typed need not start with the composing text as rendered.
  public var partialWords: [String] {
    var partials: [String] = []
    for removed in 0 ... 2 {
      let partial = fragment + composing.dropLast(removed)
      if !partial.isEmpty, !partials.contains(partial) {
        partials.append(partial)
      }
    }
    return partials
  }

  public func completions(
    from candidates: [String],
    limit: Int,
    canExtend: (String) -> Bool
  ) -> [Completion] {
    let word = fragment + composing
    var seen: Set<String> = []
    var completions: [Completion] = []
    for candidate in candidates {
      guard completions.count < limit else { break }
      guard
        candidate != word,
        candidate.hasPrefix(fragment),
        seen.insert(candidate).inserted,
        canExtend(String(candidate.dropFirst(fragment.count)))
      else { continue }
      completions.append(Completion(word: candidate, replacedLength: fragment.count))
    }
    return completions
  }
}
