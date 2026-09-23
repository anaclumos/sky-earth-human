@MainActor
protocol ShortcutExpander: AnyObject {
  func expansion(textBeforeCursor: String, composing: String) -> PredictionCandidate?
}
