public enum InputEvent: Equatable, Sendable {
  case hangul(Key, at: ContinuousClock.Instant)
  case text(String)
  case punctuation(cycle: [String], at: ContinuousClock.Instant)
  case space
  case delete
  case returnKey
  case flush
}

public enum InputCommand: Equatable, Sendable {
  case setComposing(String)
  case commit(String)
  case deleteBackward
}

public struct InputSession: Sendable {
  public let cycleLock: Duration

  private struct Cycle: Equatable {
    var candidates: [String]
    var index: Int
    var instant: ContinuousClock.Instant
  }

  private var composer: HangulComposer
  private var cycle: Cycle?

  public init(cycleLock: Duration) {
    self.cycleLock = cycleLock
    composer = HangulComposer(cycleLock: cycleLock)
  }

  public var isComposing: Bool {
    composer.isComposing
  }

  public var composing: String {
    composer.composing
  }

  public func canExtend(to text: String) -> Bool {
    composer.canExtend(to: text)
  }

  public mutating func handle(_ event: InputEvent) -> [InputCommand] {
    switch event {
    case let .hangul(key, instant):
      cycle = nil
      return marking(composer.press(key, at: instant))

    case let .text(text):
      cycle = nil
      return endComposition() + [.commit(text)]

    case let .punctuation(candidates, instant):
      return punctuation(candidates, at: instant)

    case .space:
      cycle = nil
      // The first space while composing ends the composition and inserts no space.
      return composer.isComposing ? endComposition() : [.commit(" ")]

    case .delete:
      cycle = nil
      // One delete against marked text clears the whole mark, so a composition rewinds and re-marks instead.
      guard let rewound = composer.backspace() else { return [.deleteBackward] }
      return marking(rewound)

    case .returnKey:
      cycle = nil
      return endComposition() + [.commit("\n")]

    case .flush:
      cycle = nil
      return endComposition()
    }
  }

  private mutating func punctuation(
    _ candidates: [String],
    at instant: ContinuousClock.Instant
  ) -> [InputCommand] {
    guard let first = candidates.first else {
      cycle = nil
      return []
    }

    let wasComposing = composer.isComposing
    let previous = cycle
    let ended = endComposition()

    if !wasComposing, let previous, previous.candidates == candidates,
       previous.instant.duration(to: instant) <= cycleLock
    {
      let index = (previous.index + 1) % candidates.count
      cycle = Cycle(candidates: candidates, index: index, instant: instant)
      // The candidate being replaced is committed text, and one delete takes one Character off it.
      let deletes = Array(repeating: InputCommand.deleteBackward, count: candidates[previous.index].count)
      return deletes + [.commit(candidates[index])]
    }

    cycle = Cycle(candidates: candidates, index: 0, instant: instant)
    return ended + [.commit(first)]
  }

  private mutating func endComposition() -> [InputCommand] {
    guard composer.isComposing else { return [] }
    let ended = composer.commit()
    return ended.committed.isEmpty ? [] : [.commit(ended.committed)]
  }

  private func marking(_ composition: Composition) -> [InputCommand] {
    composition.committed.isEmpty
      ? [.setComposing(composition.composing)]
      : [.commit(composition.committed), .setComposing(composition.composing)]
  }
}
