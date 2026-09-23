@MainActor
final class PredictionBarProvider: PredictionProvider {
  private let shortcuts: (any ShortcutExpander)?
  private let completions: any PredictionProvider
  private let limit: Int

  init(shortcuts: (any ShortcutExpander)?, completions: any PredictionProvider, limit: Int = 3) {
    self.shortcuts = shortcuts
    self.completions = completions
    self.limit = limit
  }

  func candidates(textBeforeCursor: String, composing: String) -> [PredictionCandidate] {
    guard limit > 0 else { return [] }

    var merged: [PredictionCandidate] = []
    if let shortcut = shortcuts?.expansion(textBeforeCursor: textBeforeCursor, composing: composing) {
      merged.append(shortcut)
    }

    // Slot one is reserved for the shortcut. The completion provider fills the rest in its
    // own order, and a completion that repeats an earlier slot's insertion is dropped rather
    // than shown twice.
    for candidate in completions.candidates(textBeforeCursor: textBeforeCursor, composing: composing) {
      guard merged.count < limit else { break }
      guard !merged.contains(where: { $0.insertion == candidate.insertion }) else { continue }
      merged.append(candidate)
    }

    return merged
  }
}
