import HangulEngine
import Observation

@Observable
@MainActor
final class ComposerDriver: KeyActionHandler {
  private(set) var candidates: [PredictionCandidate] = []

  @ObservationIgnored private let adapter: any InsertionAdapter
  @ObservationIgnored private let provider: any PredictionProvider
  @ObservationIgnored private let settings: any SettingsReader
  @ObservationIgnored private let shortcuts: (any ShortcutExpander)?
  @ObservationIgnored private var session: InputSession
  @ObservationIgnored private var inputs: [Input] = []
  @ObservationIgnored private var inputsWaited = false

  private enum Input {
    case key(KeyAction, ContinuousClock.Instant)
    case candidate(PredictionCandidate)
  }

  init(
    adapter: any InsertionAdapter,
    provider: any PredictionProvider,
    settings: any SettingsReader,
    shortcuts: (any ShortcutExpander)? = nil
  ) {
    self.adapter = adapter
    self.provider = provider
    self.settings = settings
    self.shortcuts = shortcuts
    session = InputSession(cycleLock: settings.cycleLock)
    adapter.onSettle = { [weak self] in self?.drain() }
    // docs/status/K2.md finding 9. The host changed the text before the queued input, so the
    // composition is dropped and the queued input goes on in order.
    adapter.onHostChange = { [weak self] in
      guard let self else { return }
      _ = session.handle(.flush)
      candidates = []
    }
  }

  func handle(_ action: KeyAction) {
    inputs.append(.key(action, ContinuousClock.now))
    drain()
  }

  func apply(_ candidate: PredictionCandidate) {
    inputs.append(.candidate(candidate))
    drain()
  }

  private func drain() {
    // docs/status/K2.md findings 6 and 7. While the adapter waits for a run loop turn, every key
    // and candidate tap queues here in order, so none reads a context the waiting call has not
    // reached yet, and none lands ahead of it.
    while !inputs.isEmpty {
      guard adapter.isSettled else {
        inputsWaited = true
        return adapter.settle()
      }
      switch inputs.removeFirst() {
      case let .key(action, instant):
        perform(action, at: instant)
      case let .candidate(candidate):
        // The bar that offered a waiting candidate was built before the adapter settled.
        if inputsWaited {
          refreshCandidates()
          guard candidates.contains(candidate) else { continue }
        }
        replace(with: candidate)
      }
    }
    inputsWaited = false
    refreshCandidates()
  }

  private func perform(_ action: KeyAction, at instant: ContinuousClock.Instant) {
    switch action {
    case let .hangul(key):
      run(session.handle(.hangul(Self.engineKey(key), at: instant)))

    case let .insert(text):
      if text.contains(where: \.isPunctuation) {
        expandShortcut()
      }
      run(session.handle(.text(text)))

    case let .cycle(strings):
      expandShortcut()
      run(session.handle(.punctuation(cycle: strings, at: instant)))

    case .delete:
      run(session.handle(.delete))

    case .space:
      // An expansion ends the composition, so the space that follows one always lands,
      // the way iOS inserts a space after a text replacement.
      expandShortcut()
      run(session.handle(.space))

    case .returnKey:
      // The session's own return event ends the composition and commits a newline as text. The
      // adapter owns how a return reaches the host, so the session only flushes here.
      expandShortcut()
      run(session.handle(.flush))
      adapter.insertReturn()

    case .dismiss, .switchKeyboard, .nextSymbolPage:
      run(session.handle(.flush))
    }
  }

  func reloadSettings() {
    settings.reload()
    if settings.cycleLock != session.cycleLock {
      run(session.handle(.flush))
      session = InputSession(cycleLock: settings.cycleLock)
    }
    refreshCandidates()
  }

  func reset() {
    _ = session.handle(.flush)
    inputs = []
    inputsWaited = false
    candidates = []
  }

  func canExtend(to text: String) -> Bool {
    session.canExtend(to: text)
  }

  private func expandShortcut() {
    guard
      let shortcuts,
      let candidate = shortcuts.expansion(
        textBeforeCursor: adapter.textBeforeCursor,
        composing: session.composing
      )
    else { return }
    replace(with: candidate)
  }

  private func replace(with candidate: PredictionCandidate) {
    // The candidate replaces the composing text in full, so the composition must not land. The
    // adapter owns the proxy sequence for the replace, docs/status/K2.md finding 5.
    _ = session.handle(.flush)
    adapter.replace(deleting: candidate.replacedLength, with: candidate.insertion)
  }

  private func refreshCandidates() {
    guard settings.isPredictionEnabled else {
      candidates = []
      return
    }
    candidates = provider.candidates(
      textBeforeCursor: adapter.textBeforeCursor,
      composing: session.composing
    )
  }

  private func run(_ commands: [InputCommand]) {
    for command in commands {
      switch command {
      case let .setComposing(text):
        adapter.setComposing(text)
      case let .commit(text):
        adapter.commit(text)
      case .deleteBackward:
        adapter.deleteBackward()
      }
    }
  }

  private static func engineKey(_ key: HangulKey) -> HangulEngine.Key {
    switch key {
    case .i: .i
    case .arae: .arae
    case .eu: .eu
    case .gk: .gk
    case .nr: .nr
    case .dt: .dt
    case .bp: .bp
    case .sh: .sh
    case .jc: .jc
    case .om: .om
    }
  }
}
