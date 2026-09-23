public struct HangulComposer: Sendable {
  /// A press reads and writes the last two blocks only, so the blocks it overwrote are enough to undo it.
  private struct Keystroke: Sendable {
    let key: Key
    let instant: ContinuousClock.Instant
    let kept: Int
    let first: Block?
    let second: Block?
  }

  private let cycleLock: Duration
  private var blocks: [Block] = []
  private var history: [Keystroke] = []

  public init(cycleLock: Duration) {
    self.cycleLock = cycleLock
  }

  public var isComposing: Bool {
    !history.isEmpty
  }

  public var composing: String {
    Automaton.render(blocks)
  }

  public mutating func press(_ key: Key, at instant: ContinuousClock.Instant) -> Composition {
    let cycling = history.last.map { $0.key == key && $0.instant.duration(to: instant) <= cycleLock } ?? false
    let kept = max(blocks.count - 2, 0)
    let overwritten = blocks[kept...]
    history.append(Keystroke(
      key: key,
      instant: instant,
      kept: kept,
      first: overwritten.first,
      second: overwritten.count == 2 ? overwritten.last : nil
    ))
    Automaton.press(&blocks, key, cycling: cycling)
    return Composition(committed: "", composing: Automaton.render(blocks))
  }

  public mutating func backspace() -> Composition? {
    guard let keystroke = history.popLast() else { return nil }
    blocks.removeSubrange(keystroke.kept...)
    if let first = keystroke.first {
      blocks.append(first)
    }
    if let second = keystroke.second {
      blocks.append(second)
    }
    return Composition(committed: "", composing: Automaton.render(blocks))
  }

  public mutating func commit() -> Composition {
    let committed = Automaton.render(blocks)
    blocks.removeAll()
    history.removeAll()
    return Composition(committed: committed, composing: "")
  }

  public func canExtend(to text: String) -> Bool {
    guard isComposing else { return true }
    return Automaton.extends(blocks, to: text)
  }
}
