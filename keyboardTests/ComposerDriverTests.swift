import os
import Testing

@MainActor
final class FakeAdapter: InsertionAdapter {
  var log: [String] = []
  var textBeforeCursor = ""
  var isSettled = true
  var onSettle: (() -> Void)?
  var onHostChange: (() -> Void)?

  func settle() {
    log.append("settle")
  }

  func insertReturn() {
    log.append("return")
    isSettled = false
  }

  func finishTurn() {
    isSettled = true
    onSettle?()
  }

  func setComposing(_ text: String) {
    log.append("mark(\(text))")
  }

  func commit(_ text: String) {
    log.append("commit(\(text))")
  }

  func deleteBackward() {
    log.append("delete")
  }

  func replace(deleting count: Int, with text: String) {
    log.append("replace(\(count), \(text))")
  }

  func take() -> [String] {
    let taken = log
    log = []
    return taken
  }
}

@MainActor
final class FakeProvider: PredictionProvider {
  var answer: [PredictionCandidate] = []
  var seen: [(String, String)] = []

  func candidates(textBeforeCursor: String, composing: String) -> [PredictionCandidate] {
    seen.append((textBeforeCursor, composing))
    return answer
  }
}

@MainActor
final class FakeExpander: ShortcutExpander {
  var answer: PredictionCandidate?
  var asked = 0

  func expansion(textBeforeCursor _: String, composing _: String) -> PredictionCandidate? {
    asked += 1
    let once = answer
    answer = nil
    return once
  }
}

struct FakeSettings: SettingsReader {
  var keySize = KeySize.default
  var isHapticFeedbackEnabled = true
  var isPredictionEnabled = true
  var cycleLock = Duration.seconds(1)

  func reload() {}
}

final class MutableSettings: SettingsReader {
  private let box = OSAllocatedUnfairLock(initialState: Duration.seconds(1))
  private let predictionBox = OSAllocatedUnfairLock(initialState: true)

  let keySize = KeySize.default
  let isHapticFeedbackEnabled = true

  var cycleLock: Duration {
    box.withLock { $0 }
  }

  var isPredictionEnabled: Bool {
    predictionBox.withLock { $0 }
  }

  func set(cycleLock: Duration) {
    box.withLock { $0 = cycleLock }
  }

  func set(isPredictionEnabled: Bool) {
    predictionBox.withLock { $0 = isPredictionEnabled }
  }

  func reload() {}
}

@MainActor
@Suite("Composer driver")
struct ComposerDriverTests {
  let adapter = FakeAdapter()
  let provider = FakeProvider()
  let expander = FakeExpander()

  func makeDriver(_ settings: FakeSettings = FakeSettings()) -> ComposerDriver {
    ComposerDriver(adapter: adapter, provider: provider, settings: settings, shortcuts: expander)
  }

  @Test("hangul presses reach the adapter as marked text")
  func hangulMarks() {
    let driver = makeDriver()
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    #expect(adapter.take() == ["mark(\u{3131})", "mark(\u{AE30})"])
  }

  @Test("the first space commits the composition and inserts no space, the next inserts one")
  func spacePolicy() {
    let driver = makeDriver()
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    _ = adapter.take()
    driver.handle(.space)
    #expect(adapter.take() == ["commit(\u{AE30})"])
    driver.handle(.space)
    #expect(adapter.take() == ["commit( )"])
  }

  @Test("delete rewinds inside a composition and deletes a committed character outside one")
  func deletePolicy() {
    let driver = makeDriver()
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    _ = adapter.take()
    driver.handle(.delete)
    #expect(adapter.take() == ["mark(\u{3131})"])
    driver.handle(.delete)
    #expect(adapter.take() == ["mark()"])
    driver.handle(.delete)
    #expect(adapter.take() == ["delete"])
  }

  @Test("the punctuation cycle replaces the previous candidate")
  func punctuationCycle() {
    let driver = makeDriver()
    driver.handle(.cycle([".", ",", "?", "!"]))
    #expect(adapter.take() == ["commit(.)"])
    driver.handle(.cycle([".", ",", "?", "!"]))
    #expect(adapter.take() == ["delete", "commit(,)"])
  }

  @Test("a page change, a type switch and a dismiss flush the composition")
  func pageChangeFlushes() {
    for action in [KeyAction.switchKeyboard(.number), .nextSymbolPage, .dismiss] {
      let driver = makeDriver()
      driver.handle(.hangul(.gk))
      driver.handle(.hangul(.i))
      _ = adapter.take()
      driver.handle(action)
      #expect(adapter.take() == ["commit(\u{AE30})"])
    }
  }

  @Test("plain text and return end the composition first")
  func plainTextAndReturnEndTheComposition() {
    let driver = makeDriver()
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    _ = adapter.take()
    driver.handle(.insert("1"))
    #expect(adapter.take() == ["commit(\u{AE30})", "commit(1)"])
    driver.handle(.hangul(.nr))
    _ = adapter.take()
    driver.handle(.returnKey)
    #expect(adapter.take() == ["commit(\u{3134})", "return"])
  }

  @Test("an idle return is one insertReturn and no commit")
  func idleReturn() {
    let driver = makeDriver()
    driver.handle(.returnKey)
    #expect(adapter.take() == ["return"])
  }

  @Test("a shortcut expands before the return, and the return is still one insertReturn")
  func shortcutThenReturn() {
    let driver = makeDriver()
    driver.handle(.hangul(.gk))
    _ = adapter.take()
    expander.answer = PredictionCandidate(display: "x", replacedLength: 0, insertion: "omw")
    driver.handle(.returnKey)
    #expect(adapter.take() == ["replace(0, omw)", "return"])
  }

  @Test("keys that arrive while the adapter waits for its turn queue in order and run when it settles")
  func keysQueueWhileTheAdapterWaits() {
    let driver = makeDriver()
    driver.handle(.hangul(.gk))
    _ = adapter.take()
    driver.handle(.returnKey)
    #expect(adapter.take() == ["commit(\u{3131})", "return"])
    driver.handle(.hangul(.nr))
    driver.handle(.space)
    #expect(adapter.take() == ["settle", "settle"])
    adapter.finishTurn()
    #expect(adapter.take() == ["mark(\u{3134})", "commit(\u{3134})"])
  }

  @Test("the first key through an unsettled adapter asks it to settle and reads nothing until it has")
  func firstKeySettlesFirst() {
    adapter.isSettled = false
    let driver = makeDriver()
    provider.seen = []
    driver.handle(.hangul(.gk))
    #expect(adapter.take() == ["settle"])
    #expect(provider.seen.isEmpty)
    adapter.finishTurn()
    #expect(adapter.take() == ["mark(\u{3131})"])
    #expect(provider.seen.count == 1)
  }

  @Test("candidates refresh when the adapter settles after a return")
  func candidatesRefreshOnSettle() {
    let driver = makeDriver()
    driver.handle(.returnKey)
    provider.seen = []
    adapter.textBeforeCursor = "\n"
    adapter.finishTurn()
    #expect(provider.seen.count == 1)
    #expect(provider.seen[0].0 == "\n")
    _ = driver
  }

  @Test("a candidate tapped while the adapter waits applies only if the settled bar still offers it")
  func waitingCandidateIsRevalidated() {
    let kept = PredictionCandidate(display: "a", replacedLength: 1, insertion: "ab")
    let gone = PredictionCandidate(display: "b", replacedLength: 1, insertion: "bc")
    let driver = makeDriver()
    driver.handle(.returnKey)
    _ = adapter.take()
    driver.apply(gone)
    driver.apply(kept)
    provider.answer = [kept]
    adapter.finishTurn()
    #expect(adapter.take() == ["settle", "settle", "replace(1, ab)"])
  }

  @Test("reset drops the keys that were waiting")
  func resetDropsWaitingKeys() {
    let driver = makeDriver()
    driver.handle(.returnKey)
    driver.handle(.hangul(.gk))
    _ = adapter.take()
    driver.reset()
    adapter.finishTurn()
    #expect(adapter.take() == [])
  }

  @Test("after a refocus onto a host mark, keys wait one turn, compose one syllable after one unmark, and the host's late answer changes nothing")
  func refocusOntoAHostMarkComposesWhole() {
    let proxy = FakeProxy()
    proxy.hostSends(before: "\u{AC00}\u{B098}\u{0020}", hasText: true)
    proxy.hostMark = "\u{D558}\u{B298}"
    let turns = ManualTurns()
    let real = MarkedTextInsertionAdapter(proxy: { proxy }, nextTurn: turns.schedule)
    let driver = ComposerDriver(adapter: real, provider: provider, settings: FakeSettings(), shortcuts: expander)
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    #expect(proxy.take() == ["unmarkText"])
    turns.runNext()
    #expect(proxy.take() == ["setMarkedText(\u{3131}, 1, 0)", "setMarkedText(\u{AE30}, 1, 0)"])
    proxy.hostSends(before: "\u{AC00}\u{B098}\u{0020}\u{D558}\u{B298}", hasText: true)
    #expect(real.hostTextDidChange() == false)
    driver.handle(.space)
    #expect(proxy.take() == ["setMarkedText(, 0, 0)", "insertText(\u{AE30})"])
    #expect(proxy.documentContextBeforeInput == "\u{AC00}\u{B098}\u{0020}\u{D558}\u{B298}\u{AE30}")
    #expect(turns.isEmpty)
  }

  /// The composition root's `textDidChange` handler, docs/status/K2.md, What K3 and I1 must know.
  private func textDidChange(_ adapter: MarkedTextInsertionAdapter, _ driver: ComposerDriver) {
    if adapter.hostTextDidChange() {
      driver.reset()
    }
  }

  @Test("the host's answer to a return, landing inside the next syllable, keeps the syllable whole and nothing waits")
  func returnAnsweredMidSyllable() {
    // docs/status/K2.md finding 8, the verifier's in-extension burst in a UITextField whose return
    // handler declines the newline: the answer lands between U+3131 and U+3163.
    let proxy = FakeProxy()
    let turns = ManualTurns()
    let real = MarkedTextInsertionAdapter(proxy: { proxy }, nextTurn: turns.schedule)
    let driver = ComposerDriver(adapter: real, provider: provider, settings: FakeSettings(), shortcuts: expander)
    for key in [HangulKey.sh, .sh, .i, .arae] {
      driver.handle(.hangul(key))
    }
    turns.runNext()
    driver.handle(.returnKey)
    driver.handle(.hangul(.gk))
    turns.runNext()
    turns.runNext()
    proxy.hostSends(before: "\u{D558}", hasText: true)
    textDidChange(real, driver)
    driver.handle(.hangul(.i))
    driver.handle(.space)
    #expect(turns.isEmpty)
    #expect(real.isSettled)
    #expect(proxy.take() == [
      "unmarkText", "setMarkedText(\u{3145}, 1, 0)", "setMarkedText(\u{314E}, 1, 0)", "setMarkedText(\u{D788}, 1, 0)",
      "setMarkedText(\u{D558}, 1, 0)", "setMarkedText(, 0, 0)", "insertText(\u{D558})", "insertText(\n)",
      "setMarkedText(\u{3131}, 1, 0)", "setMarkedText(\u{AE30}, 1, 0)", "setMarkedText(, 0, 0)", "insertText(\u{AE30})",
    ])
  }

  @Test("after a host change, an unmark of the keyboard's own mark that the host never answers settles in one turn and no key is lost")
  func unansweredUnmarkAfterAHostChange() {
    // docs/status/K2.md finding 8. The verifier's freeze: the unmark changed the proxy view, no
    // answer came, and every later key queued behind it.
    let proxy = FakeProxy()
    let turns = ManualTurns()
    let real = MarkedTextInsertionAdapter(proxy: { proxy }, nextTurn: turns.schedule)
    let driver = ComposerDriver(adapter: real, provider: provider, settings: FakeSettings(), shortcuts: expander)
    driver.handle(.hangul(.gk))
    turns.runNext()
    proxy.hostSends(before: "\u{D558}", hasText: true)
    proxy.hostMark = "\u{3131}"
    textDidChange(real, driver)
    _ = proxy.take()
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    turns.runNext()
    #expect(real.isSettled)
    #expect(turns.isEmpty)
    #expect(proxy.take() == ["unmarkText", "setMarkedText(\u{3131}, 1, 0)", "setMarkedText(\u{AE30}, 1, 0)"])
  }

  @Test("a return handler that clears the field, answering while the next syllable composes, keeps the syllable whole")
  func clearingReturnAnsweredMidSyllable() {
    // docs/status/K2.md finding 9, the verifier's X9 rig. The handler's clear and its answer land
    // between U+3131 and U+3163, and the host applies U+3131 after both.
    let proxy = FakeProxy()
    let turns = ManualTurns()
    let real = MarkedTextInsertionAdapter(proxy: { proxy }, nextTurn: turns.schedule)
    let driver = ComposerDriver(adapter: real, provider: provider, settings: FakeSettings(), shortcuts: expander)
    for key in [HangulKey.sh, .sh, .i, .arae] {
      driver.handle(.hangul(key))
    }
    turns.runNext()
    driver.handle(.returnKey)
    turns.runNext()
    turns.runNext()
    driver.handle(.hangul(.gk))
    _ = proxy.take()
    proxy.hostSends(before: nil, hasText: false)
    textDidChange(real, driver)
    proxy.hostSends(before: nil, hasText: false)
    textDidChange(real, driver)
    driver.handle(.hangul(.i))
    driver.handle(.space)
    #expect(turns.isEmpty)
    #expect(proxy.take() == ["setMarkedText(\u{AE30}, 1, 0)", "setMarkedText(, 0, 0)", "insertText(\u{AE30})"])
  }

  @Test("a host clear while a return is unanswered drops the composition before the next key, which composes afresh")
  func hostClearWhileAReturnIsUnanswered() {
    // docs/status/K2.md finding 9, the Messages send. One empty callback and no answer.
    let proxy = FakeProxy()
    let turns = ManualTurns()
    let real = MarkedTextInsertionAdapter(proxy: { proxy }, nextTurn: turns.schedule)
    let driver = ComposerDriver(adapter: real, provider: provider, settings: FakeSettings(), shortcuts: expander)
    driver.handle(.hangul(.gk))
    turns.runNext()
    driver.handle(.returnKey)
    turns.runNext()
    turns.runNext()
    driver.handle(.hangul(.dt))
    _ = proxy.take()
    proxy.hostSends(before: nil, hasText: false)
    textDidChange(real, driver)
    #expect(proxy.take() == [])
    driver.handle(.hangul(.i))
    turns.runNext()
    driver.handle(.space)
    #expect(turns.isEmpty)
    #expect(proxy.take() == ["unmarkText", "setMarkedText(\u{3163}, 1, 0)", "setMarkedText(, 0, 0)", "insertText(\u{3163})"])
  }

  @Test("applying a candidate flushes the composition and hands the adapter one replace")
  func applyCandidate() {
    let driver = makeDriver()
    adapter.textBeforeCursor = "\u{C548}\u{B155} \u{D558}"
    driver.handle(.hangul(.sh))
    _ = adapter.take()
    driver.apply(PredictionCandidate(display: "x", replacedLength: 1, insertion: "\u{D558}\u{C138}\u{C694}"))
    #expect(adapter.take() == ["replace(1, \u{D558}\u{C138}\u{C694})"])
    driver.handle(.hangul(.nr))
    #expect(adapter.take() == ["mark(\u{3134})"])
  }

  @Test("applying a candidate with nothing composing is the same replace")
  func applyCandidateIdle() {
    let driver = makeDriver()
    driver.apply(PredictionCandidate(display: "x", replacedLength: 2, insertion: "ab"))
    #expect(adapter.take() == ["replace(2, ab)"])
  }

  @Test("a shortcut expands before the space, and the space then lands")
  func shortcutThenSpace() {
    let driver = makeDriver()
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    _ = adapter.take()
    expander.answer = PredictionCandidate(display: "x", replacedLength: 0, insertion: "omw")
    driver.handle(.space)
    #expect(adapter.take() == ["replace(0, omw)", "commit( )"])
  }

  @Test("a shortcut expands before punctuation and before the punctuation cycle")
  func shortcutBeforePunctuation() {
    let onCycle = makeDriver()
    expander.answer = PredictionCandidate(display: "x", replacedLength: 0, insertion: "omw")
    onCycle.handle(.cycle([".", ","]))
    #expect(adapter.take() == ["replace(0, omw)", "commit(.)"])

    let onInsert = makeDriver()
    expander.answer = PredictionCandidate(display: "x", replacedLength: 0, insertion: "omw")
    onInsert.handle(.insert("!"))
    #expect(adapter.take() == ["replace(0, omw)", "commit(!)"])
  }

  @Test("an expansion between two punctuation presses restarts the cycle")
  func expansionRestartsTheCycle() {
    let driver = makeDriver()
    driver.handle(.cycle([".", ","]))
    #expect(adapter.take() == ["commit(.)"])
    expander.answer = PredictionCandidate(display: "x", replacedLength: 0, insertion: "omw")
    driver.handle(.cycle([".", ","]))
    #expect(adapter.take() == ["replace(0, omw)", "commit(.)"])
  }

  @Test("plain text that is not punctuation never asks the expander")
  func digitsDoNotExpand() {
    let driver = makeDriver()
    expander.asked = 0
    driver.handle(.insert("1"))
    driver.handle(.insert("\u{2605}"))
    #expect(expander.asked == 0)
    driver.handle(.insert("."))
    #expect(expander.asked == 1)
  }

  @Test("hangul and delete never ask the expander")
  func hangulAndDeleteDoNotExpand() {
    let driver = makeDriver()
    expander.asked = 0
    driver.handle(.hangul(.gk))
    driver.handle(.delete)
    #expect(expander.asked == 0)
  }

  @Test("candidates refresh after every action from the text before the cursor and the composing text")
  func candidatesRefresh() {
    let driver = makeDriver()
    provider.answer = [PredictionCandidate(display: "a", replacedLength: 0, insertion: "a")]
    adapter.textBeforeCursor = "\u{C548}"
    provider.seen = []
    driver.handle(.hangul(.gk))
    #expect(driver.candidates.count == 1)
    #expect(provider.seen.count == 1)
    #expect(provider.seen[0].0 == "\u{C548}")
    #expect(provider.seen[0].1 == "\u{3131}")
  }

  @Test("candidates stay empty while the prediction setting is off")
  func predictionsOff() {
    var settings = FakeSettings()
    settings.isPredictionEnabled = false
    let driver = makeDriver(settings)
    provider.answer = [PredictionCandidate(display: "a", replacedLength: 0, insertion: "a")]
    provider.seen = []
    driver.handle(.hangul(.gk))
    #expect(driver.candidates.isEmpty)
    #expect(provider.seen.isEmpty)
  }

  @Test("reloadSettings keeps a composition in progress when the cycle lock did not change")
  func reloadKeepsComposition() {
    let driver = makeDriver()
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    _ = adapter.take()
    driver.reloadSettings()
    #expect(adapter.take() == [])
    driver.handle(.hangul(.arae))
    #expect(adapter.take() == ["mark(\u{AC00})"])
  }

  @Test("reloadSettings rebuilds the session when the cycle lock changed")
  func reloadRebuilds() {
    let settings = MutableSettings()
    let driver = ComposerDriver(adapter: adapter, provider: provider, settings: settings, shortcuts: nil)
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    _ = adapter.take()
    settings.set(cycleLock: .milliseconds(500))
    driver.reloadSettings()
    #expect(adapter.take() == ["commit(\u{AE30})"])
    driver.handle(.hangul(.nr))
    #expect(adapter.take() == ["mark(\u{3134})"])
  }

  @Test("reloadSettings refreshes candidates immediately when the prediction setting toggles, even when the cycle lock did not change")
  func reloadRefreshesOnPredictionToggle() {
    let settings = MutableSettings()
    provider.answer = [PredictionCandidate(display: "a", replacedLength: 0, insertion: "a")]
    let driver = ComposerDriver(adapter: adapter, provider: provider, settings: settings, shortcuts: nil)
    driver.handle(.hangul(.gk))
    #expect(driver.candidates == provider.answer)

    settings.set(isPredictionEnabled: false)
    driver.reloadSettings()
    #expect(driver.candidates.isEmpty)

    settings.set(isPredictionEnabled: true)
    driver.reloadSettings()
    #expect(driver.candidates == provider.answer)
  }

  @Test("reset drops the composition without touching the proxy")
  func resetIsSilent() {
    let driver = makeDriver()
    driver.handle(.hangul(.gk))
    driver.handle(.hangul(.i))
    _ = adapter.take()
    driver.reset()
    #expect(adapter.take() == [])
    #expect(driver.candidates.isEmpty)
    driver.handle(.hangul(.nr))
    #expect(adapter.take() == ["mark(\u{3134})"])
  }
}
