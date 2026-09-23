import HangulEngine
import Testing

struct Typist {
  static let lock = Duration.seconds(1)
  static let step = Duration.milliseconds(100)
  static let afterLock = Duration.seconds(2)

  private var composer: HangulComposer
  private var instant = ContinuousClock.now

  init(cycleLock: Duration = Typist.lock) {
    composer = HangulComposer(cycleLock: cycleLock)
  }

  var isComposing: Bool {
    composer.isComposing
  }

  var composing: String {
    composer.composing
  }

  @discardableResult
  mutating func press(_ key: Key, after gap: Duration = Typist.step) -> Composition {
    instant = instant.advanced(by: gap)
    return composer.press(key, at: instant)
  }

  @discardableResult
  mutating func press(_ keys: [Key]) -> Composition {
    var last = Composition(committed: "", composing: "")
    for key in keys {
      last = press(key)
    }
    return last
  }

  mutating func backspace() -> Composition? {
    composer.backspace()
  }

  mutating func commit() -> Composition {
    composer.commit()
  }

  func canExtend(to text: String) -> Bool {
    composer.canExtend(to: text)
  }

  static func compose(_ keys: [Key]) -> Composition {
    var typist = Typist()
    return typist.press(keys)
  }

  /// String equality is canonical, so a decomposed rendering compares equal to a precomposed one.
  /// The contract pins the scalars, so renderings are compared scalar by scalar.
  static func expectRendering(
    _ actual: String,
    is expected: String,
    _ comment: Comment? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    #expect(
      Array(actual.unicodeScalars) == Array(expected.unicodeScalars),
      comment ?? "rendered \(points(actual)), expected \(points(expected))",
      sourceLocation: sourceLocation
    )
  }

  static func points(_ text: String) -> String {
    let listed = text.unicodeScalars.map { "U+" + String($0.value, radix: 16, uppercase: true) }
    return listed.isEmpty ? "nothing" : listed.joined(separator: " ")
  }
}
