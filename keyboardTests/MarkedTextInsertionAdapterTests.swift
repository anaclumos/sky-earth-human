import Testing
import UIKit

@MainActor
final class FakeProxy: NSObject, UITextDocumentProxy {
  var calls: [String] = []
  var documentContextBeforeInput: String?
  var documentContextAfterInput: String?
  var selectedText: String?
  var documentInputMode: UITextInputMode?
  var documentIdentifier = UUID()
  var hasText = false
  /// The system proxy returns a nil documentIdentifier while the host has sent no document.
  var hasNoDocument = false
  /// A mark the host kept from before this adapter. The system proxy moves it into the before
  /// context as soon as unmarkText() is called, which is what the adapter reads.
  var hostMark: String?

  override func value(forKey key: String) -> Any? {
    // The adapter reads documentIdentifier on the main actor, and NSObject's KVC entry point is
    // nonisolated.
    if key == "documentIdentifier", MainActor.assumeIsolated({ hasNoDocument }) {
      return nil
    }
    return super.value(forKey: key)
  }

  func adjustTextPosition(byCharacterOffset offset: Int) {
    calls.append("adjust(\(offset))")
  }

  func setMarkedText(_ markedText: String, selectedRange: NSRange) {
    calls.append("setMarkedText(\(markedText), \(selectedRange.location), \(selectedRange.length))")
    hasText = hasText || !markedText.isEmpty
  }

  func unmarkText() {
    calls.append("unmarkText")
    if let hostMark {
      documentContextBeforeInput = (documentContextBeforeInput ?? "") + hostMark
      hasText = true
      self.hostMark = nil
    }
  }

  /// The system proxy adds inserted text to its local before context at once, a newline included,
  /// whatever the host later does with it.
  func insertText(_ text: String) {
    calls.append("insertText(\(text))")
    documentContextBeforeInput = (documentContextBeforeInput ?? "") + text
    hasText = true
  }

  /// A `textDidChange` from the host replaces the proxy's local view with the host's.
  func hostSends(before: String?, after: String? = nil, hasText: Bool) {
    documentContextBeforeInput = before
    documentContextAfterInput = after
    self.hasText = hasText
  }

  func deleteBackward() {
    calls.append("deleteBackward")
  }

  func take() -> [String] {
    let taken = calls
    calls = []
    return taken
  }
}

@MainActor
struct MarkedTextInsertionAdapterTests {
  let proxy = FakeProxy()

  private func make() -> MarkedTextInsertionAdapter {
    MarkedTextInsertionAdapter { [proxy] in proxy }
  }

  @Test("setComposing marks with a caret at the UTF-16 end")
  func setComposingMarks() {
    let adapter = make()
    adapter.setComposing("\u{AC00}")
    #expect(proxy.take() == ["setMarkedText(\u{AC00}, 1, 0)"])
    adapter.setComposing("\u{1100}\u{119E}")
    #expect(proxy.take() == ["setMarkedText(\u{1100}\u{119E}, 2, 0)"])
  }

  @Test("setComposing with the string already marked makes no call")
  func setComposingSameText() {
    let adapter = make()
    adapter.setComposing("\u{AC00}")
    _ = proxy.take()
    adapter.setComposing("\u{AC00}")
    #expect(proxy.take() == [])
  }

  @Test("setComposing empty with nothing marked makes no call")
  func setComposingEmptyIdle() {
    let adapter = make()
    adapter.setComposing("")
    #expect(proxy.take() == [])
  }

  @Test("setComposing empty clears a live mark with setMarkedText and never calls unmarkText")
  func setComposingEmptyMarked() {
    let adapter = make()
    adapter.setComposing("\u{AC00}")
    _ = proxy.take()
    adapter.setComposing("")
    #expect(proxy.take() == ["setMarkedText(, 0, 0)"])
    adapter.setComposing("")
    #expect(proxy.take() == [])
  }

  @Test("a candidate replace with nothing marked deletes the fragment then inserts")
  func replaceIdle() {
    let adapter = make()
    adapter.replace(deleting: 2, with: "\u{C0AC}\u{B78C}")
    #expect(proxy.take() == ["deleteBackward", "deleteBackward", "insertText(\u{C0AC}\u{B78C})"])
    adapter.replace(deleting: 0, with: "\u{C0AC}\u{B78C}")
    #expect(proxy.take() == ["insertText(\u{C0AC}\u{B78C})"])
  }

  @Test("a candidate replace of the whole mark with nothing committed of it is the commit shape")
  func replaceWholeMark() {
    let adapter = make()
    adapter.setComposing("\u{AC00}\u{B098}\u{B2E4}")
    _ = proxy.take()
    adapter.replace(deleting: 0, with: "\u{C0AC}\u{B78C}")
    #expect(proxy.take() == ["setMarkedText(, 0, 0)", "insertText(\u{C0AC}\u{B78C})"])
  }

  @Test("a candidate replace over a mark commits the mark, deletes the fragment plus the mark, then inserts")
  func replaceOverMark() {
    // docs/status/K2.md finding 5. One deleteBackward() per Character of the replaced fragment plus
    // the former mark, after the mark is committed through the commit shape.
    let adapter = make()
    proxy.documentContextBeforeInput = "\u{AC00}\u{B098}"
    adapter.setComposing("\u{B2E4}")
    _ = proxy.take()
    adapter.replace(deleting: 1, with: "\u{C0AC}\u{B78C}")
    #expect(proxy.take() == [
      "setMarkedText(, 0, 0)", "insertText(\u{B2E4})", "deleteBackward", "deleteBackward", "insertText(\u{C0AC}\u{B78C})",
    ])
    adapter.setComposing("\u{3134}")
    #expect(proxy.take() == ["setMarkedText(\u{3134}, 1, 0)"])
  }

  @Test("a candidate replace counts a vowel jamo that joins the last committed syllable as one delete")
  func replaceOverMergedCluster() {
    let adapter = make()
    proxy.documentContextBeforeInput = "\u{AC00}\u{B098}"
    adapter.setComposing("\u{119E}")
    _ = proxy.take()
    adapter.replace(deleting: 1, with: "\u{C0AC}\u{B78C}")
    #expect(proxy.take() == ["setMarkedText(, 0, 0)", "insertText(\u{119E})", "deleteBackward", "insertText(\u{C0AC}\u{B78C})"])
  }

  @Test("a candidate replace over a multi syllable mark deletes one Character per cluster")
  func replaceOverMultiSyllableMark() {
    let adapter = make()
    proxy.documentContextBeforeInput = "\u{AC00}\u{B098}"
    adapter.setComposing("\u{AC00}\u{110B}\u{119E}")
    _ = proxy.take()
    adapter.replace(deleting: 2, with: "\u{C0AC}\u{B78C}")
    #expect(proxy.take() == [
      "setMarkedText(, 0, 0)", "insertText(\u{AC00}\u{110B}\u{119E})",
      "deleteBackward", "deleteBackward", "deleteBackward", "deleteBackward", "insertText(\u{C0AC}\u{B78C})",
    ])
  }

  struct MarkShape: Sendable {
    let name: String
    let mark: String
    let deletesForOne: Int
    let deletesForTwo: Int
  }

  nonisolated static let markShapes = [
    MarkShape(name: "1syl", mark: "\u{B2E4}", deletesForOne: 2, deletesForTwo: 3),
    MarkShape(name: "jamo", mark: "\u{3137}", deletesForOne: 2, deletesForTwo: 3),
    MarkShape(name: "vowel", mark: "\u{119E}", deletesForOne: 1, deletesForTwo: 2),
    MarkShape(name: "ivowel", mark: "\u{3163}", deletesForOne: 2, deletesForTwo: 3),
    MarkShape(name: "araea", mark: "\u{1102}\u{119E}", deletesForOne: 2, deletesForTwo: 3),
    MarkShape(name: "2syl", mark: "\u{AC00}\u{AE30}", deletesForOne: 3, deletesForTwo: 4),
    MarkShape(name: "fold", mark: "\u{AC00}\u{3138}", deletesForOne: 3, deletesForTwo: 4),
    MarkShape(name: "sylaraea", mark: "\u{AC00}\u{110B}\u{119E}", deletesForOne: 3, deletesForTwo: 4),
    MarkShape(name: "3syl", mark: "\u{AC00}\u{AC00}\u{AE30}", deletesForOne: 4, deletesForTwo: 5),
  ]

  @Test("a candidate replace over every engine mark shape commits the mark then deletes one Character per cluster", arguments: markShapes)
  func replaceEveryShape(_ shape: MarkShape) {
    // docs/status/K2.md finding 5. markShapes is every mark shape the engine hands to setComposing, after
    // the committed fragment U+AC00 U+B098. The delete counts are the Character counts of the replaced
    // fragment plus the mark as one string, so the lone vowel jamo joins U+B098 and a conjoining pair
    // counts once.
    let adapter = make()
    for (count, deletes) in [(1, shape.deletesForOne), (2, shape.deletesForTwo)] {
      proxy.documentContextBeforeInput = "\u{AC00}\u{B098}"
      adapter.setComposing(shape.mark)
      _ = proxy.take()
      adapter.replace(deleting: count, with: "\u{C0AC}\u{B78C}")
      let expected = ["setMarkedText(, 0, 0)", "insertText(\(shape.mark))"]
        + Array(repeating: "deleteBackward", count: deletes) + ["insertText(\u{C0AC}\u{B78C})"]
      #expect(proxy.take() == expected, "\(shape.name) deleting \(count)")
    }
  }

  @Test("commit of the marked string removes the mark then inserts the text")
  func commitEqualText() {
    let adapter = make()
    adapter.setComposing("\u{AC04}")
    _ = proxy.take()
    adapter.commit("\u{AC04}")
    #expect(proxy.take() == ["setMarkedText(, 0, 0)", "insertText(\u{AC04})"])
  }

  @Test("commit of a different string removes the mark then inserts that string")
  func commitDifferentText() {
    let adapter = make()
    adapter.setComposing("\u{AC04}")
    _ = proxy.take()
    adapter.commit("\u{AC00}")
    #expect(proxy.take() == ["setMarkedText(, 0, 0)", "insertText(\u{AC00})"])
    adapter.setComposing("\u{B098}")
    #expect(proxy.take() == ["setMarkedText(\u{B098}, 1, 0)"])
  }

  @Test("commit empty with a mark only removes the mark")
  func commitEmptyMarked() {
    let adapter = make()
    adapter.setComposing("\u{B098}")
    _ = proxy.take()
    adapter.commit("")
    #expect(proxy.take() == ["setMarkedText(, 0, 0)"])
  }

  @Test("commit with nothing marked inserts plain text, and empty text makes no call")
  func commitIdle() {
    let adapter = make()
    adapter.commit(" ")
    #expect(proxy.take() == ["insertText( )"])
    adapter.commit("")
    #expect(proxy.take() == [])
  }

  @Test("two commits in one turn are two plain inserts after one mark removal")
  func commitThenCommit() {
    let adapter = make()
    adapter.setComposing("\u{AC04}")
    _ = proxy.take()
    adapter.commit("\u{AC04}")
    adapter.commit(".")
    #expect(proxy.take() == ["setMarkedText(, 0, 0)", "insertText(\u{AC04})", "insertText(.)"])
  }

  @Test("deleteBackward always reaches the proxy and drops the local mark")
  func deleteBackward() {
    let adapter = make()
    adapter.deleteBackward()
    #expect(proxy.take() == ["deleteBackward"])
    adapter.setComposing("\u{AC00}")
    _ = proxy.take()
    adapter.deleteBackward()
    #expect(proxy.take() == ["deleteBackward"])
    adapter.setComposing("\u{AC00}")
    #expect(proxy.take() == ["setMarkedText(\u{AC00}, 1, 0)"])
  }

  @Test("endLeftoverMark calls unmarkText and drops the local mark")
  func endLeftoverMark() {
    let adapter = make()
    adapter.endLeftoverMark()
    #expect(proxy.take() == ["unmarkText"])
    adapter.setComposing("\u{B2E4}")
    _ = proxy.take()
    adapter.endLeftoverMark()
    #expect(proxy.take() == ["unmarkText"])
    adapter.setComposing("\u{B2E4}")
    #expect(proxy.take() == ["setMarkedText(\u{B2E4}, 1, 0)"])
  }

  @Test("disappear then appear is one unmarkText at each lifecycle point, even after a host change")
  func disappearThenAppear() {
    let leaving = make()
    leaving.setComposing("\u{B2E4}")
    _ = proxy.take()
    #expect(leaving.hostTextDidChange() == true)
    leaving.endLeftoverMark()
    #expect(proxy.take() == ["unmarkText"])
    leaving.commit("")
    #expect(proxy.take() == [])
    let returning = make()
    returning.endLeftoverMark()
    #expect(proxy.take() == ["unmarkText"])
    returning.setComposing("\u{3134}")
    #expect(proxy.take() == ["setMarkedText(\u{3134}, 1, 0)"])
  }

  @Test("a host change drops the local mark without a proxy call")
  func hostChangeForgetsTheMark() {
    let adapter = make()
    adapter.setComposing("\u{B2E4}")
    _ = proxy.take()
    #expect(adapter.hostTextDidChange() == true)
    #expect(proxy.take() == [])
    adapter.commit("\u{B2E4}")
    #expect(proxy.take() == ["insertText(\u{B2E4})"])
    adapter.setComposing("\u{B2E4}")
    #expect(adapter.hostTextDidChange() == true)
    adapter.setComposing("\u{B2E4}")
    #expect(proxy.take() == ["setMarkedText(\u{B2E4}, 1, 0)", "setMarkedText(\u{B2E4}, 1, 0)"])
  }

  @Test("hasDocument is hasText or a non-nil context on either side, with no proxy mutation")
  func hasDocument() {
    let adapter = make()
    proxy.hasText = true
    proxy.documentContextBeforeInput = nil
    proxy.documentContextAfterInput = nil
    #expect(adapter.hasDocument == true)
    proxy.hasText = false
    proxy.documentContextBeforeInput = "\u{AC00}\u{B098}\u{0020}"
    #expect(adapter.hasDocument == true)
    proxy.documentContextBeforeInput = nil
    proxy.documentContextAfterInput = ""
    #expect(adapter.hasDocument == true)
    proxy.documentContextAfterInput = nil
    #expect(adapter.hasDocument == false)
    #expect(proxy.take() == [])
  }

  @Test("textBeforeCursor maps nil to the empty string and passes text through")
  func textBeforeCursor() {
    let adapter = make()
    proxy.documentContextBeforeInput = nil
    #expect(adapter.textBeforeCursor == "")
    proxy.documentContextBeforeInput = "\u{AC00}\u{B098}"
    #expect(adapter.textBeforeCursor == "\u{AC00}\u{B098}")
  }

  @Test("the proxy closure runs on every call")
  func proxyResolvedPerCall() {
    var count = 0
    let proxy = proxy
    let adapter = MarkedTextInsertionAdapter {
      count += 1
      return proxy
    }
    adapter.setComposing("\u{AC00}")
    adapter.commit("\u{AC00}")
    adapter.deleteBackward()
    _ = adapter.textBeforeCursor
    adapter.endLeftoverMark()
    _ = adapter.hostTextDidChange()
    _ = adapter.hasDocument
    // The first mutation also reads the host's view once, docs/status/K2.md finding 8.
    #expect(count == 9)
  }

  @Test("a new adapter is unsettled, and settle is one unmarkText followed by one turn of waiting")
  func settleEndsAHostMarkFirst() {
    let turns = ManualTurns()
    var settled = 0
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.onSettle = { settled += 1 }
    #expect(adapter.isSettled == false)
    adapter.settle()
    #expect(proxy.take() == ["unmarkText"])
    #expect(adapter.isSettled == false)
    adapter.settle()
    #expect(proxy.take() == [])
    #expect(settled == 0)
    turns.runNext()
    #expect(adapter.isSettled == true)
    #expect(settled == 1)
    adapter.settle()
    #expect(proxy.take() == [])
    #expect(turns.isEmpty)
    adapter.setComposing("\u{3131}")
    #expect(proxy.take() == ["setMarkedText(\u{3131}, 1, 0)"])
  }

  @Test("a host change unsettles the adapter, so the next settle ends whatever mark the host kept")
  func hostChangeUnsettles() {
    let turns = ManualTurns()
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.settle()
    turns.runNext()
    adapter.setComposing("\u{D558}\u{B298}")
    _ = proxy.take()
    #expect(adapter.hostTextDidChange() == true)
    #expect(adapter.isSettled == false)
    adapter.settle()
    #expect(proxy.take() == ["unmarkText"])
    turns.runNext()
    #expect(adapter.isSettled == true)
    adapter.setComposing("\u{3131}")
    #expect(proxy.take() == ["setMarkedText(\u{3131}, 1, 0)"])
  }

  @Test("insertReturn puts the newline one turn after the commit and settles one turn after the newline")
  func insertReturnAfterACommit() {
    let turns = ManualTurns()
    var settled = 0
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.onSettle = { settled += 1 }
    adapter.settle()
    turns.runNext()
    _ = proxy.take()
    settled = 0
    adapter.setComposing("\u{D558}")
    adapter.commit("\u{D558}")
    adapter.insertReturn()
    #expect(proxy.take() == ["setMarkedText(\u{D558}, 1, 0)", "setMarkedText(, 0, 0)", "insertText(\u{D558})"])
    #expect(adapter.isSettled == false)
    turns.runNext()
    #expect(proxy.take() == ["insertText(\n)"])
    #expect(adapter.isSettled == false)
    #expect(settled == 0)
    turns.runNext()
    #expect(proxy.take() == [])
    #expect(adapter.isSettled == true)
    #expect(settled == 1)
    #expect(turns.isEmpty)
  }

  @Test("an idle insertReturn and one after a replace take the same two turns")
  func insertReturnIdleAndAfterAReplace() {
    let turns = ManualTurns()
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.settle()
    turns.runNext()
    _ = proxy.take()
    adapter.insertReturn()
    #expect(proxy.take() == [])
    turns.runNext()
    #expect(proxy.take() == ["insertText(\n)"])
    turns.runNext()
    #expect(adapter.isSettled == true)
    adapter.replace(deleting: 0, with: "omw")
    adapter.insertReturn()
    #expect(proxy.take() == ["insertText(omw)"])
    turns.runNext()
    #expect(proxy.take() == ["insertText(\n)"])
    turns.runNext()
    #expect(adapter.isSettled == true)
  }

  @Test("a host change while the newline waits keeps the adapter unsettled after the newline, and settle then unmarks")
  func hostChangeWhileTheNewlineWaits() {
    let turns = ManualTurns()
    var settled = 0
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.onSettle = { settled += 1 }
    adapter.settle()
    turns.runNext()
    _ = proxy.take()
    settled = 0
    adapter.insertReturn()
    #expect(adapter.hostTextDidChange() == true)
    adapter.settle()
    #expect(proxy.take() == [])
    turns.runNext()
    #expect(proxy.take() == ["insertText(\n)"])
    turns.runNext()
    #expect(settled == 1)
    #expect(adapter.isSettled == false)
    adapter.settle()
    #expect(proxy.take() == ["unmarkText"])
    turns.runNext()
    #expect(adapter.isSettled == true)
    #expect(settled == 2)
  }

  @Test("the default scheduler leaves the turn: nothing settles synchronously")
  func defaultSchedulerHops() async {
    let adapter = make()
    await withCheckedContinuation { continuation in
      adapter.onSettle = { continuation.resume() }
      adapter.settle()
      #expect(adapter.isSettled == false)
      #expect(proxy.take() == ["unmarkText"])
    }
    #expect(adapter.isSettled == true)
    await withCheckedContinuation { continuation in
      adapter.onSettle = { continuation.resume() }
      adapter.insertReturn()
      #expect(proxy.take() == [])
    }
    #expect(proxy.take() == ["insertText(\n)"])
    #expect(adapter.isSettled == true)
  }

  /// A settled adapter over a field that shows `before` and holds no mark.
  private func settled(_ turns: ManualTurns, before: String?) -> MarkedTextInsertionAdapter {
    proxy.hostSends(before: before, hasText: before != nil)
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.settle()
    turns.runNext()
    _ = proxy.take()
    return adapter
  }

  /// Types U+D558, return, then U+AE30 and a space, and starts U+D558 again, the verifier's human
  /// pace script, with every turn run. The newline is the last call the host has answered for.
  private func typeWordReturnWord(_ adapter: MarkedTextInsertionAdapter, _ turns: ManualTurns) {
    adapter.setComposing("\u{D558}")
    adapter.commit("\u{D558}")
    adapter.insertReturn()
    turns.runNext()
    turns.runNext()
    adapter.setComposing("\u{3131}")
    adapter.setComposing("\u{AE30}")
    adapter.commit("\u{AE30}")
    adapter.commit(" ")
    adapter.setComposing("\u{314E}")
    _ = proxy.take()
  }

  @Test("an unmark that commits a host mark settles after one turn and waits for no answer")
  func committingUnmarkWaitsForNoAnswer() {
    let turns = ManualTurns()
    var settled = 0
    proxy.hostSends(before: "\u{AC00}\u{B098}\u{0020}", hasText: true)
    proxy.hostMark = "\u{D558}\u{B298}"
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.onSettle = { settled += 1 }
    adapter.settle()
    #expect(proxy.take() == ["unmarkText"])
    #expect(adapter.isSettled == false)
    adapter.settle()
    #expect(proxy.take() == [])
    turns.runNext()
    #expect(adapter.isSettled == true)
    #expect(settled == 1)
    #expect(turns.isEmpty)
    adapter.setComposing("\u{3131}")
    #expect(proxy.take() == ["setMarkedText(\u{3131}, 1, 0)"])
  }

  @Test("the host's answer to a committing unmark, arriving after the next key, is not a host change")
  func committingUnmarkAnsweredLate() {
    let turns = ManualTurns()
    proxy.hostSends(before: "\u{AC00}\u{B098}\u{0020}", hasText: true)
    proxy.hostMark = "\u{D558}\u{B298}"
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.settle()
    turns.runNext()
    adapter.setComposing("\u{3131}")
    proxy.hostSends(before: "\u{AC00}\u{B098}\u{0020}\u{D558}\u{B298}", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    #expect(adapter.isSettled == true)
    adapter.setComposing("\u{AE30}")
    #expect(proxy.take() == ["unmarkText", "setMarkedText(\u{3131}, 1, 0)", "setMarkedText(\u{AE30}, 1, 0)"])
  }

  @Test("a committing unmark the host never answers leaves nothing waiting, and a later host change still reads as one")
  func committingUnmarkNeverAnswered() {
    let turns = ManualTurns()
    proxy.hostSends(before: "\u{AC00}\u{B098}\u{0020}", hasText: true)
    proxy.hostMark = "\u{D558}\u{B298}"
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.settle()
    turns.runNext()
    for key in ["\u{3131}", "\u{AE30}"] {
      adapter.setComposing(key)
      #expect(adapter.isSettled == true)
    }
    adapter.commit("\u{AE30}")
    #expect(turns.isEmpty)
    _ = proxy.take()
    proxy.hostSends(before: nil, hasText: false)
    #expect(adapter.hostTextDidChange() == true)
    #expect(adapter.isSettled == false)
    adapter.settle()
    #expect(proxy.take() == ["unmarkText"])
    turns.runNext()
    #expect(adapter.isSettled == true)
  }

  @Test("after an unmark without a document, the first callback that brings one is the answer")
  func unmarkWithoutADocument() {
    let turns = ManualTurns()
    proxy.hasNoDocument = true
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.settle()
    #expect(proxy.take() == ["unmarkText"])
    turns.runNext()
    #expect(adapter.isSettled == true)
    adapter.setComposing("\u{3131}")
    proxy.hasNoDocument = false
    proxy.hostSends(before: "\u{AC00}\u{B098}\u{0020}\u{D558}\u{B298}", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    #expect(adapter.hostTextDidChange() == true)
  }

  @Test("a callback without a document is a host change even while an answer is expected")
  func callbackWithoutADocument() {
    let turns = ManualTurns()
    let adapter = settled(turns, before: "\u{D558}")
    adapter.insertReturn()
    turns.runNext()
    turns.runNext()
    proxy.hostSends(before: "\u{D558}", hasText: true)
    proxy.hasNoDocument = true
    #expect(adapter.hostTextDidChange() == true)
  }

  @Test("a late answer to a declined newline, after the next word began, is not a host change and the syllable goes on")
  func lateAnswerToADeclinedNewline() {
    // docs/status/K2.md finding 8, the verifier's slow return handler. The host answers 0.8 s after
    // the newline with its text as of the newline, after the keyboard committed U+AE30 and a space.
    let turns = ManualTurns()
    let adapter = settled(turns, before: nil)
    typeWordReturnWord(adapter, turns)
    proxy.hostSends(before: "\u{D558}", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    #expect(adapter.isSettled == true)
    adapter.setComposing("\u{D558}")
    #expect(proxy.take() == ["setMarkedText(\u{D558}, 1, 0)"])
  }

  @Test("after a late answer rewound the proxy's view, the next late answer is still expected from the host's text")
  func secondLateAnswer() {
    // docs/status/K2.md finding 8. The first answer drops U+AE30 and the space from the proxy's
    // view though the host has them, so the proxy's view at the second newline is not the host's.
    let turns = ManualTurns()
    let adapter = settled(turns, before: nil)
    typeWordReturnWord(adapter, turns)
    proxy.hostSends(before: "\u{D558}", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    adapter.setComposing("\u{D558}")
    adapter.commit("\u{D558}")
    adapter.insertReturn()
    turns.runNext()
    turns.runNext()
    adapter.setComposing("\u{3131}")
    #expect(proxy.documentContextBeforeInput == "\u{D558}\u{D558}\n")
    proxy.hostSends(before: "\u{D558}\u{AE30} \u{D558}", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    adapter.setComposing("\u{AE30}")
    #expect(proxy.take().last == "setMarkedText(\u{AE30}, 1, 0)")
  }

  @Test("two newlines sent before either is answered are each answered without the other's newline")
  func twoNewlinesBeforeTheirAnswers() {
    let turns = ManualTurns()
    let adapter = settled(turns, before: nil)
    for syllable in ["\u{D558}", "\u{AE30}"] {
      adapter.setComposing(syllable)
      adapter.commit(syllable)
      adapter.insertReturn()
      turns.runNext()
      turns.runNext()
    }
    adapter.setComposing("\u{3131}")
    proxy.hostSends(before: "\u{D558}", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    proxy.hostSends(before: "\u{D558}\u{AE30}", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    proxy.hostSends(before: "\u{D558}\u{AE30}", hasText: true)
    #expect(adapter.hostTextDidChange() == true)
  }

  @Test("a host that keeps the newline may answer with the text after it")
  func answerAfterAKeptNewline() {
    let turns = ManualTurns()
    let adapter = settled(turns, before: nil)
    typeWordReturnWord(adapter, turns)
    proxy.hostSends(before: "\u{D558}\n", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
  }

  @Test("an answer is taken once")
  func answersInOrder() {
    let turns = ManualTurns()
    let adapter = settled(turns, before: nil)
    typeWordReturnWord(adapter, turns)
    proxy.hostSends(before: "\u{D558}\n", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    proxy.hostSends(before: "\u{D558}", hasText: true)
    #expect(adapter.hostTextDidChange() == true)
  }

  @Test("a host change drops every expected answer")
  func hostChangeDropsAnswers() {
    let turns = ManualTurns()
    let adapter = settled(turns, before: nil)
    typeWordReturnWord(adapter, turns)
    proxy.hostSends(before: "\u{C608}", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    #expect(adapter.isSettled == false)
    proxy.hostSends(before: "\u{D558}", hasText: true)
    #expect(adapter.hostTextDidChange() == true)
    proxy.hostSends(before: "\u{D558}", hasText: true)
    #expect(adapter.hostTextDidChange() == true)
  }

  @Test("a return handler that clears the field sends the clear and then its answer, both empty, and the composition goes on")
  func returnHandlerThatClears() {
    // docs/status/K2.md finding 9, the verifier's slow clearing send. The handler's clear and the
    // answer to the return reach the keyboard before the host applies the keys typed since.
    let turns = ManualTurns()
    var hostChanges = 0
    let adapter = settled(turns, before: nil)
    adapter.onHostChange = { hostChanges += 1 }
    typeWordReturnWord(adapter, turns)
    proxy.hostSends(before: nil, hasText: false)
    #expect(adapter.hostTextDidChange() == false)
    #expect(adapter.isSettled == false)
    proxy.hostSends(before: nil, hasText: false)
    #expect(adapter.hostTextDidChange() == false)
    #expect(adapter.isSettled == true)
    adapter.setComposing("\u{D788}")
    #expect(proxy.take() == ["setMarkedText(\u{D788}, 1, 0)"])
    #expect(hostChanges == 0)
    proxy.hostSends(before: "\u{AE30} ", hasText: true)
    #expect(adapter.hostTextDidChange() == true)
  }

  @Test("a clearing return handler that sends no answer reads as a host change at the next key, which starts afresh")
  func returnHandlerThatClearsWithoutAnAnswer() {
    // docs/status/K2.md finding 9. A handler that returns true sends only its clear, the one
    // callback a host clear also sends, so the composition is dropped before the next key.
    let turns = ManualTurns()
    var hostChanges = 0
    var settledCount = 0
    let adapter = settled(turns, before: nil)
    adapter.onHostChange = { hostChanges += 1 }
    typeWordReturnWord(adapter, turns)
    adapter.onSettle = { settledCount += 1 }
    proxy.hostSends(before: nil, hasText: false)
    #expect(adapter.hostTextDidChange() == false)
    #expect(hostChanges == 0)
    adapter.settle()
    #expect(hostChanges == 1)
    #expect(proxy.take() == ["unmarkText"])
    turns.runNext()
    #expect(adapter.isSettled == true)
    #expect(settledCount == 1)
    adapter.setComposing("\u{314F}")
    #expect(proxy.take() == ["setMarkedText(\u{314F}, 1, 0)"])
    proxy.hostSends(before: nil, hasText: false)
    #expect(adapter.hostTextDidChange() == true)
  }

  @Test("a host clear while a return is unanswered, the Messages send, drops the composition at the next key")
  func hostClearWhileAReturnIsUnanswered() {
    // docs/status/K2.md finding 9. Messages keeps the newline and never answers it, and its send
    // sends one empty callback.
    let turns = ManualTurns()
    var hostChanges = 0
    let adapter = settled(turns, before: nil)
    adapter.onHostChange = { hostChanges += 1 }
    adapter.setComposing("\u{AC00}")
    adapter.commit("\u{AC00}")
    adapter.insertReturn()
    turns.runNext()
    turns.runNext()
    adapter.setComposing("\u{B2E4}")
    _ = proxy.take()
    proxy.hostSends(before: nil, hasText: false)
    #expect(adapter.hostTextDidChange() == false)
    adapter.settle()
    #expect(hostChanges == 1)
    turns.runNext()
    adapter.setComposing("\u{3134}")
    #expect(proxy.take() == ["unmarkText", "setMarkedText(\u{3134}, 1, 0)"])
  }

  @Test("the UITextField clear button's callbacks while a return is unanswered read as a host change at the second")
  func clearButtonWhileAReturnIsUnanswered() {
    // docs/status/K2.md finding 9. The clear button sends the field with the mark, a selection of
    // it, and two empty views.
    let turns = ManualTurns()
    let adapter = settled(turns, before: nil)
    adapter.setComposing("\u{AC00}")
    adapter.commit("\u{AC00}")
    adapter.insertReturn()
    turns.runNext()
    turns.runNext()
    adapter.setComposing("\u{B2E4}")
    proxy.hostSends(before: "\u{AC00}\u{B2E4}", hasText: true)
    #expect(adapter.hostTextDidChange() == false)
    proxy.hostSends(before: nil, hasText: true)
    #expect(adapter.hostTextDidChange() == true)
    proxy.hostSends(before: nil, hasText: false)
    #expect(adapter.hostTextDidChange() == true)
    #expect(adapter.hostTextDidChange() == true)
  }

  @Test("returns a host never answers leave a bounded record, and an answer older than the bound is not taken")
  func neverAnsweredReturns() {
    // docs/status/K2.md finding 9. Each round is four calls, a mark, its removal, the syllable and
    // the newline. After nine rounds the first return's answer is still taken. After eighty the
    // bound has dropped it, and the same view waits as a possible host change.
    for (rounds, answered) in [(9, true), (80, false)] {
      let proxy = FakeProxy()
      let turns = ManualTurns()
      let adapter = MarkedTextInsertionAdapter(proxy: { proxy }, nextTurn: turns.schedule)
      adapter.settle()
      turns.runNext()
      for _ in 0 ..< rounds {
        adapter.setComposing("\u{D558}")
        adapter.commit("\u{D558}")
        adapter.insertReturn()
        turns.runNext()
        turns.runNext()
      }
      proxy.hostSends(before: "\u{D558}", hasText: true)
      #expect(adapter.hostTextDidChange() == false, "\(rounds) rounds")
      #expect(adapter.isSettled == answered, "\(rounds) rounds")
    }
  }

  @Test("endLeftoverMark drops every expected answer, and the next settle unmarks again")
  func endLeftoverMarkDropsAnswers() {
    let turns = ManualTurns()
    let adapter = settled(turns, before: "\u{D558}")
    adapter.insertReturn()
    turns.runNext()
    turns.runNext()
    adapter.endLeftoverMark()
    #expect(proxy.take() == ["insertText(\n)", "unmarkText"])
    #expect(adapter.isSettled == false)
    proxy.hostSends(before: "\u{D558}", hasText: true)
    #expect(adapter.hostTextDidChange() == true)
  }

  @Test("endLeftoverMark during a one turn hold lets the turn end, and the adapter then settles afresh")
  func endLeftoverMarkDuringATurn() {
    let turns = ManualTurns()
    var settled = 0
    let adapter = MarkedTextInsertionAdapter(proxy: { [proxy] in proxy }, nextTurn: turns.schedule)
    adapter.onSettle = { settled += 1 }
    adapter.settle()
    adapter.endLeftoverMark()
    adapter.settle()
    #expect(proxy.take() == ["unmarkText", "unmarkText"])
    turns.runNext()
    #expect(settled == 1)
    #expect(adapter.isSettled == false)
    adapter.settle()
    #expect(proxy.take() == ["unmarkText"])
    turns.runNext()
    #expect(settled == 2)
    #expect(adapter.isSettled == true)
  }
}

@MainActor
final class ManualTurns {
  private var waiting: [@MainActor () -> Void] = []

  var isEmpty: Bool {
    waiting.isEmpty
  }

  func schedule(_ work: @escaping @MainActor () -> Void) {
    waiting.append(work)
  }

  func runNext() {
    let batch = waiting
    waiting = []
    for work in batch {
      work()
    }
  }
}
