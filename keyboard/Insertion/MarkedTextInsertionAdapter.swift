import UIKit

@MainActor
final class MarkedTextInsertionAdapter: InsertionAdapter {
  private let proxy: @MainActor () -> any UITextDocumentProxy
  private let nextTurn: @MainActor (@escaping @MainActor () -> Void) -> Void
  private var marked = ""
  private var hostMayHoldMark = true
  private var holding = false

  // docs/status/K2.md finding 8. The host answers some of the adapter's own calls with a
  // textDidChange that carries its view as of that call, often after later calls, and the proxy
  // then shows that old view with the later calls lost. So the adapter keeps the last view the host
  // sent, its own calls since, and which of those calls may be answered, and computes each expected
  // answer from the host's view rather than from the proxy's. No answer is ever waited for.
  private var base: HostView?
  private var calls: [Call] = []
  private var answers: [Answer] = []

  /// Finding 9. A return handler runs before the host applies any call the keyboard made after the
  /// return, and a handler that changes the text sends that change first and then its answer to the
  /// return with the same view. A view that matches no expected answer while a return is unanswered
  /// is kept here, taken as the handler's own change when the answer repeats it, and as the host's
  /// change at the next mutation otherwise.
  private var unconfirmed: HostView?

  /// Finding 9. A host that never answers a return leaves its expected answer, and every call after
  /// it, until the next host callback. Past this many calls the adapter gives the answers up. The
  /// largest backlog measured behind a blocking return handler is 103 calls with 9 answers.
  private static let callLimit = 256

  private enum Call {
    case marked(Bool)
    case inserted(String)
    case deleted
    case unmarked(HostView)
  }

  /// A textDidChange the host may send for the first `through` calls since `base`.
  private struct Answer {
    var through: Int
    var kind: Kind

    enum Kind {
      /// The host's view after those calls.
      case view
      /// The last of those calls is a newline, and the host's view after it or, where the host
      /// declined it, before it.
      case newline
      /// The last of those calls is an unmark made without a document, and any view that brings one.
      case anyDocument
    }
  }

  private struct HostView: Equatable {
    var document: UUID?
    var hasText: Bool
    var before: String
    var after: String

    @MainActor
    init(_ proxy: any UITextDocumentProxy) {
      // The SDK declares documentIdentifier non-null, but the system proxy returns nil while the
      // host has sent no document, and the bridged Swift read then traps in
      // UUID._unconditionallyBridgeFromObjectiveC. docs/status/K2.md finding 6 has the crash reports.
      document = (proxy as? NSObject)?.value(forKey: "documentIdentifier") as? UUID
      hasText = proxy.hasText
      before = proxy.documentContextBeforeInput ?? ""
      after = proxy.documentContextAfterInput ?? ""
    }

    /// Applies `call` the way the proxy and a host that keeps a newline do.
    mutating func apply(_ call: Call) {
      switch call {
      case let .marked(live):
        hasText = live || !before.isEmpty || !after.isEmpty
      case let .inserted(text):
        before += text
        hasText = true
      case .deleted:
        if !before.isEmpty {
          before.removeLast()
        }
        hasText = !before.isEmpty || !after.isEmpty
      case let .unmarked(unmarked):
        self = unmarked
      }
    }
  }

  var onSettle: (() -> Void)?
  var onHostChange: (() -> Void)?

  init(
    proxy: @escaping @MainActor () -> any UITextDocumentProxy,
    nextTurn: @escaping @MainActor (@escaping @MainActor () -> Void) -> Void = { work in Task { @MainActor in work() } }
  ) {
    self.proxy = proxy
    self.nextTurn = nextTurn
  }

  var textBeforeCursor: String {
    proxy().documentContextBeforeInput ?? ""
  }

  var isSettled: Bool {
    !holding && !hostMayHoldMark && unconfirmed == nil
  }

  func settle() {
    // docs/status/K2.md finding 6. A stock UIKit control keeps a mark alive across a resign or a
    // focus move, and the next setMarkedText then replaces the whole marked word. A new adapter, or
    // one the host changed text under, cannot tell whether such a mark exists, so it ends one with
    // unmarkText() before its first mutation. A mutation in the same run loop turn as the unmark
    // measured as reaching the host first, so the mutation waits for the next turn. When the unmark
    // committed a mark the proxy knew of the host may answer with its text as of the unmark, and
    // when the proxy had no document an answer brings the document.
    guard !holding else { return }
    if let view = unconfirmed {
      unconfirmed = nil
      hostChanged(to: view)
      onHostChange?()
    }
    guard hostMayHoldMark else { return }
    hostMayHoldMark = false
    let before = HostView(proxy())
    if base == nil {
      base = before
    }
    proxy().unmarkText()
    let after = HostView(proxy())
    record(.unmarked(after))
    if before.document == nil {
      answers.append(Answer(through: calls.count, kind: .anyDocument))
    } else if after != before {
      answers.append(Answer(through: calls.count, kind: .view))
    }
    hold()
  }

  /// The composition root calls this from `textDidChange`. False means the callback is the host's
  /// answer to one of the adapter's own calls, or a change the adapter cannot tell yet from a return
  /// handler's own, and the composition goes on. True means the host changed the text itself: the
  /// adapter has forgotten its mark, ends any host mark before its next mutation, and the root
  /// resets the driver. docs/status/K2.md findings 8 and 9.
  func hostTextDidChange() -> Bool {
    let view = HostView(proxy())
    if let pending = unconfirmed {
      unconfirmed = nil
      guard view == pending, let newline = answers.firstIndex(where: { $0.kind == .newline }) else {
        hostChanged(to: view)
        return true
      }
      answered(newline, with: view)
      return false
    }
    if let index = answer(matching: view) {
      answered(index, with: view)
      return false
    }
    if view.document != nil, answers.contains(where: { $0.kind == .newline }) {
      unconfirmed = view
      return false
    }
    hostChanged(to: view)
    return true
  }

  private func answered(_ index: Int, with view: HostView) {
    base = view
    let through = answers[index].through
    calls.removeFirst(through)
    answers = answers.dropFirst(index + 1).map { Answer(through: $0.through - through, kind: $0.kind) }
    if answers.isEmpty {
      fold()
    }
  }

  private func hostChanged(to view: HostView) {
    base = view
    calls = []
    answers = []
    forgetMark()
  }

  private func fold() {
    for call in calls {
      base?.apply(call)
    }
    calls = []
  }

  /// The index of the first expected answer `view` is, replaying the calls since `base` once.
  private func answer(matching view: HostView) -> Int? {
    guard view.document != nil, var expected = base else { return nil }
    var applied = 0
    func replay(through count: Int) {
      while applied < count {
        expected.apply(calls[applied])
        applied += 1
      }
    }
    for (index, answer) in answers.enumerated() {
      switch answer.kind {
      case .anyDocument:
        return index
      case .view:
        replay(through: answer.through)
        if expected == view {
          return index
        }
      case .newline:
        replay(through: answer.through - 1)
        if expected == view {
          return index
        }
        replay(through: answer.through)
        if expected == view {
          return index
        }
      }
    }
    return nil
  }

  private func mutate(_ call: Call, _ body: () -> Void) {
    if base == nil {
      base = HostView(proxy())
    }
    body()
    record(call)
  }

  private func record(_ call: Call) {
    if answers.isEmpty {
      base?.apply(call)
      return
    }
    calls.append(call)
    if calls.count > Self.callLimit {
      answers = []
      fold()
    }
  }

  func insertReturn() {
    // docs/status/K2.md finding 7. A newline that shares a run loop turn with any other insertText
    // lands in a single line field as a space and fires no return action, in either order. So the
    // newline gets a turn of its own, after whatever this turn inserted and before whatever comes
    // next. Finding 8: a field whose return handler declines the newline answers with its text as of
    // the newline, the text before it, and a host that keeps the newline may answer with the text
    // after it.
    holding = true
    nextTurn { [weak self] in
      guard let self else { return }
      answers.append(Answer(through: calls.count + 1, kind: .newline))
      mutate(.inserted("\n")) { proxy().insertText("\n") }
      hold()
    }
  }

  private func hold() {
    holding = true
    nextTurn { [weak self] in
      guard let self else { return }
      holding = false
      onSettle?()
    }
  }

  // docs/status/K2.md: after a host resign the proxy has no document at viewWillDisappear, and
  // ending a leftover mark on the next appearance then moves the caret to the start of the field.
  // The composition root reads this before endLeftoverMark() in viewWillDisappear and calls
  // endLeftoverMark() on appearance only when it was true.
  var hasDocument: Bool {
    let current = proxy()
    return current.hasText || current.documentContextBeforeInput != nil || current.documentContextAfterInput != nil
  }

  func setComposing(_ text: String) {
    guard text != marked else { return }
    guard !text.isEmpty else { return commit("") }
    mutate(.marked(true)) { proxy().setMarkedText(text, selectedRange: NSRange(location: text.utf16.count, length: 0)) }
    marked = text
  }

  func commit(_ text: String) {
    // Never unmarkText() here. docs/status/K2.md measured that a proxy mutation issued in the
    // same run loop turn as unmarkText() loses the text the unmark should have committed.
    if !marked.isEmpty {
      mutate(.marked(false)) { proxy().setMarkedText("", selectedRange: NSRange(location: 0, length: 0)) }
      marked = ""
    }
    if !text.isEmpty {
      mutate(.inserted(text)) { proxy().insertText(text) }
    }
  }

  func replace(deleting count: Int, with text: String) {
    // docs/status/K2.md finding 5. The host absorbs the first deleteBackward() issued after
    // setMarkedText(""), and a deleteBackward() on a live mark removes one grapheme cluster in
    // WebKit rather than the mark. So with a mark and committed text to replace, the mark is
    // committed first through the commit shape above, and the deletes then walk committed text
    // only, one Character per call, over the replaced fragment plus the former mark, read before
    // any mutation so a jamo that joins the last committed syllable counts once.
    if marked.isEmpty || count == 0 {
      for _ in 0 ..< count {
        mutate(.deleted) { proxy().deleteBackward() }
      }
      return commit(text)
    }
    let word = String(textBeforeCursor.suffix(count)) + marked
    commit(marked)
    for _ in 0 ..< word.count {
      mutate(.deleted) { proxy().deleteBackward() }
    }
    commit(text)
  }

  func deleteBackward() {
    mutate(.deleted) { proxy().deleteBackward() }
    marked = ""
  }

  func endLeftoverMark() {
    proxy().unmarkText()
    // Nothing the keyboard did before it left is answered after, and the next appearance may meet a
    // host mark again, so the adapter settles afresh before its next mutation.
    base = nil
    calls = []
    answers = []
    unconfirmed = nil
    forgetMark()
  }

  private func forgetMark() {
    marked = ""
    hostMayHoldMark = true
  }
}
