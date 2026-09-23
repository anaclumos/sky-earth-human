import HangulEngine
import Testing

@MainActor
private final class StubShortcutExpander: ShortcutExpander {
  let candidate: PredictionCandidate?
  init(_ candidate: PredictionCandidate?) {
    self.candidate = candidate
  }

  func expansion(textBeforeCursor _: String, composing _: String) -> PredictionCandidate? {
    candidate
  }
}

@MainActor
private final class StubCompletions: PredictionProvider {
  let list: [PredictionCandidate]
  init(_ list: [PredictionCandidate]) {
    self.list = list
  }

  func candidates(textBeforeCursor _: String, composing _: String) -> [PredictionCandidate] {
    list
  }
}

private func candidate(_ insertion: String, display: String? = nil, replacedLength: Int = 0) -> PredictionCandidate {
  PredictionCandidate(display: display ?? insertion, replacedLength: replacedLength, insertion: insertion)
}

@Suite("PredictionBarProvider merge rules")
@MainActor
struct PredictionBarProviderTests {
  @Test("empty when there is no shortcut and no completion")
  func emptyWhenNothingToShow() {
    let provider = PredictionBarProvider(shortcuts: StubShortcutExpander(nil), completions: StubCompletions([]))
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == [])
  }

  @Test("a shortcut with no completions fills only slot one")
  func shortcutAloneFillsSlotOne() {
    let shortcut = candidate("shortcut")
    let provider = PredictionBarProvider(shortcuts: StubShortcutExpander(shortcut), completions: StubCompletions([]))
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == [shortcut])
  }

  @Test("completions with no shortcut fill from slot one in source order")
  func completionsFillFromSlotOneWithNoShortcut() {
    let completions = [candidate("a"), candidate("b"), candidate("c")]
    let provider = PredictionBarProvider(shortcuts: StubShortcutExpander(nil), completions: StubCompletions(completions))
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == completions)
  }

  @Test("a nil shortcut expander behaves like no shortcut")
  func nilShortcutExpanderBehavesLikeNoShortcut() {
    let completions = [candidate("a"), candidate("b")]
    let provider = PredictionBarProvider(shortcuts: nil, completions: StubCompletions(completions))
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == completions)
  }

  @Test("shortcut takes slot one and completions fill the rest in order")
  func shortcutThenCompletionsInOrder() {
    let shortcut = candidate("shortcut")
    let completions = [candidate("a"), candidate("b"), candidate("c")]
    let provider = PredictionBarProvider(shortcuts: StubShortcutExpander(shortcut), completions: StubCompletions(completions))
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == [shortcut, candidate("a"), candidate("b")])
  }

  @Test("a completion whose insertion repeats the shortcut's insertion is skipped")
  func completionDuplicatingTheShortcutIsSkipped() {
    let shortcut = candidate("dup")
    let completions = [candidate("dup", display: "different display"), candidate("a"), candidate("b")]
    let provider = PredictionBarProvider(shortcuts: StubShortcutExpander(shortcut), completions: StubCompletions(completions))
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == [shortcut, candidate("a"), candidate("b")])
  }

  @Test("a completion whose insertion repeats an earlier completion's insertion is skipped")
  func completionDuplicatingAnEarlierCompletionIsSkipped() {
    let completions = [candidate("a"), candidate("a", display: "again"), candidate("b"), candidate("c")]
    let provider = PredictionBarProvider(shortcuts: StubShortcutExpander(nil), completions: StubCompletions(completions))
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == [candidate("a"), candidate("b"), candidate("c")])
  }

  @Test("the merged list is capped at three even with a shortcut and four completions")
  func cappedAtThreeWithShortcutAndFourCompletions() {
    let shortcut = candidate("shortcut")
    let completions = [candidate("a"), candidate("b"), candidate("c"), candidate("d")]
    let provider = PredictionBarProvider(shortcuts: StubShortcutExpander(shortcut), completions: StubCompletions(completions))
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == [shortcut, candidate("a"), candidate("b")])
  }

  @Test("a lower limit caps both the shortcut and the completions")
  func lowerLimitCapsEverything() {
    let shortcut = candidate("shortcut")
    let completions = [candidate("a"), candidate("b")]
    let provider = PredictionBarProvider(shortcuts: StubShortcutExpander(shortcut), completions: StubCompletions(completions), limit: 1)
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == [shortcut])
  }

  @Test("a limit of zero shows nothing even when a shortcut and completions exist")
  func zeroLimitShowsNothing() {
    let shortcut = candidate("shortcut")
    let completions = [candidate("a"), candidate("b")]
    let provider = PredictionBarProvider(shortcuts: StubShortcutExpander(shortcut), completions: StubCompletions(completions), limit: 0)
    #expect(provider.candidates(textBeforeCursor: "", composing: "") == [])
  }

  @Test("a shortcut from LexiconPredictionProvider lands in slot one, ahead of the completions")
  func lexiconShortcutLandsInSlotOne() {
    let provider = LexiconPredictionProvider()
    provider.update(entries: [ShortcutMatcher.Entry(userInput: "abc", documentText: "xyz")])

    let shortcut = PredictionCandidate(display: "xyz", replacedLength: 3, insertion: "xyz")
    let bar = PredictionBarProvider(
      shortcuts: provider,
      completions: StubCompletions([candidate("a"), candidate("b")]),
      limit: 3
    )
    #expect(bar.candidates(textBeforeCursor: "abc", composing: "") == [shortcut, candidate("a"), candidate("b")])
  }

  @Test("candidates() is asked with the exact text passed through")
  func passesTextThrough() {
    final class RecordingCompletions: PredictionProvider {
      private(set) var lastTextBeforeCursor: String?
      private(set) var lastComposing: String?
      func candidates(textBeforeCursor: String, composing: String) -> [PredictionCandidate] {
        lastTextBeforeCursor = textBeforeCursor
        lastComposing = composing
        return []
      }
    }
    let recorder = RecordingCompletions()
    let provider = PredictionBarProvider(shortcuts: nil, completions: recorder)
    _ = provider.candidates(textBeforeCursor: "hello ", composing: "wor")
    #expect(recorder.lastTextBeforeCursor == "hello ")
    #expect(recorder.lastComposing == "wor")
  }
}

@MainActor
private final class CountingShortcuts: ShortcutExpander {
  let candidate: PredictionCandidate?
  private(set) var calls: [(String, String)] = []
  init(_ candidate: PredictionCandidate?) {
    self.candidate = candidate
  }

  func expansion(textBeforeCursor: String, composing: String) -> PredictionCandidate? {
    calls.append((textBeforeCursor, composing))
    return candidate
  }
}

@MainActor
private final class CountingCompletions: PredictionProvider {
  let list: [PredictionCandidate]
  private(set) var calls: [(String, String)] = []
  init(_ list: [PredictionCandidate]) {
    self.list = list
  }

  func candidates(textBeforeCursor: String, composing: String) -> [PredictionCandidate] {
    calls.append((textBeforeCursor, composing))
    return list
  }
}

private func tt(_ insertion: String, display: String? = nil, replacedLength: Int = 1) -> PredictionCandidate {
  PredictionCandidate(display: display ?? insertion, replacedLength: replacedLength, insertion: insertion)
}

private let ttShortcut = tt("S", replacedLength: 2)
private let ttCompletions5 = [tt("c1"), tt("c2"), tt("c3"), tt("c4"), tt("c5")]

@MainActor
private func ttMerge(
  shortcut: PredictionCandidate?,
  shortcutsPresent: Bool = true,
  completions: [PredictionCandidate],
  limit: Int = 3,
  text: String = "",
  composing: String = ""
) -> [PredictionCandidate] {
  let provider = PredictionBarProvider(
    shortcuts: shortcutsPresent ? CountingShortcuts(shortcut) : nil,
    completions: CountingCompletions(completions),
    limit: limit
  )
  return provider.candidates(textBeforeCursor: text, composing: composing)
}

/// Truth-table coverage the merge rules table alone did not reach: dedupe against every earlier
/// slot rather than only slot one, the shortcut asked with the real composing text, the argument
/// order into both sources, and the cap staying at the caller's limit rather than a hardcoded 3.
@Suite("Truth table")
@MainActor
struct TruthTableTests {
  @Test("no shortcut, completions of length 0 to 5 fill up to three in order", arguments: 0 ... 5)
  func noShortcutLengths(count: Int) {
    let list = Array(ttCompletions5.prefix(count))
    #expect(ttMerge(shortcut: nil, completions: list) == Array(list.prefix(3)))
    #expect(ttMerge(shortcut: nil, shortcutsPresent: false, completions: list) == Array(list.prefix(3)))
  }

  @Test("shortcut present, completions of length 0 to 5 give shortcut then two completions", arguments: 0 ... 5)
  func shortcutLengths(count: Int) {
    let list = Array(ttCompletions5.prefix(count))
    let merged = ttMerge(shortcut: ttShortcut, completions: list)
    #expect(merged.first == ttShortcut)
    #expect(merged == [ttShortcut] + Array(list.prefix(2)))
    #expect(merged.count <= 3)
  }

  @Test("shortcut is slot one regardless of where its duplicate sits in the completions", arguments: 0 ... 4)
  func shortcutDuplicateAtIndex(index: Int) {
    var list = ttCompletions5
    list.insert(tt("S", display: "other", replacedLength: 1), at: index)
    let merged = ttMerge(shortcut: ttShortcut, completions: list)
    #expect(merged.first == ttShortcut)
    #expect(merged.count == 3)
    #expect(merged.filter { $0.insertion == "S" }.count == 1)
    #expect(merged == [ttShortcut] + Array(list.filter { $0.insertion != "S" }.prefix(2)))
  }

  @Test("duplicates inside completions collapse to the first occurrence")
  func duplicatesInsideCompletions() {
    let list = [tt("a"), tt("a", display: "again"), tt("a"), tt("b"), tt("b"), tt("c")]
    #expect(ttMerge(shortcut: nil, completions: list) == [tt("a"), tt("b"), tt("c")])
    #expect(ttMerge(shortcut: ttShortcut, completions: list) == [ttShortcut, tt("a"), tt("b")])
  }

  @Test("dedupe compares insertion, so a matching display with a different insertion is kept")
  func displayIsNotTheKey() {
    let sameDisplay = tt("X", display: "S")
    #expect(ttMerge(shortcut: ttShortcut, completions: [sameDisplay]) == [ttShortcut, sameDisplay])
    let sameInsertion = tt("S", display: "X")
    #expect(ttMerge(shortcut: ttShortcut, completions: [sameInsertion]) == [ttShortcut])
  }

  @Test("a completion sharing an insertion but not replacedLength is still dropped")
  func replacedLengthIsNotTheKey() {
    #expect(ttMerge(shortcut: ttShortcut, completions: [tt("S", replacedLength: 9)]) == [ttShortcut])
  }

  @Test("limits other than three", arguments: [1, 2, 4, 5, 6])
  func otherLimits(limit: Int) {
    let without = ttMerge(shortcut: nil, completions: ttCompletions5, limit: limit)
    #expect(without == Array(ttCompletions5.prefix(limit)))
    let with = ttMerge(shortcut: ttShortcut, completions: ttCompletions5, limit: limit)
    #expect(with == [ttShortcut] + Array(ttCompletions5.prefix(limit - 1)))
  }

  @Test("limit zero or negative yields nothing and asks neither source", arguments: [0, -1, Int.min])
  func nonPositiveLimit(limit: Int) {
    let shortcuts = CountingShortcuts(ttShortcut)
    let completions = CountingCompletions(ttCompletions5)
    let provider = PredictionBarProvider(shortcuts: shortcuts, completions: completions, limit: limit)
    #expect(provider.candidates(textBeforeCursor: "abc", composing: "d") == [])
    #expect(shortcuts.calls.isEmpty)
    #expect(completions.calls.isEmpty)
  }

  @Test("text is passed to both sources unchanged, exactly once each", arguments: [
    ("", ""),
    ("hello ", ""),
    ("hello", "wor"),
    ("hello ", "wor"),
    ("   ", "x"),
    ("\u{D558}\u{B294} ", "\u{D558}"),
  ])
  func passthroughOnce(text: String, composing: String) {
    let shortcuts = CountingShortcuts(ttShortcut)
    let completions = CountingCompletions(ttCompletions5)
    let provider = PredictionBarProvider(shortcuts: shortcuts, completions: completions)
    _ = provider.candidates(textBeforeCursor: text, composing: composing)
    #expect(shortcuts.calls.count == 1)
    #expect(completions.calls.count == 1)
    #expect(shortcuts.calls.first?.0 == text)
    #expect(shortcuts.calls.first?.1 == composing)
    #expect(completions.calls.first?.0 == text)
    #expect(completions.calls.first?.1 == composing)
  }

  @Test("a nil expansion from a present expander leaves slot one to the completions")
  func nilExpansionFromPresentExpander() {
    #expect(ttMerge(shortcut: nil, completions: ttCompletions5) == [tt("c1"), tt("c2"), tt("c3")])
  }

  @Test("the shortcut candidate itself is returned untouched, including replacedLength")
  func shortcutUntouched() {
    let merged = ttMerge(shortcut: ttShortcut, completions: [])
    #expect(merged == [ttShortcut])
    #expect(merged.first?.replacedLength == 2)
  }
}
