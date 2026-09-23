import HangulEngine
import Testing

@Suite("Consonant cycles")
struct ConsonantCycleTests {
  static let lone: [(key: Key, renderings: [String])] = [
    (key: .gk, renderings: ["\u{3131}", "\u{314B}", "\u{3132}", "\u{3131}"]),
    (key: .nr, renderings: ["\u{3134}", "\u{3139}", "\u{3134}"]),
    (key: .dt, renderings: ["\u{3137}", "\u{314C}", "\u{3138}", "\u{3137}"]),
    (key: .bp, renderings: ["\u{3142}", "\u{314D}", "\u{3143}", "\u{3142}"]),
    (key: .sh, renderings: ["\u{3145}", "\u{314E}", "\u{3146}", "\u{3145}"]),
    (key: .jc, renderings: ["\u{3148}", "\u{314A}", "\u{3149}", "\u{3148}"]),
    (key: .om, renderings: ["\u{3147}", "\u{3141}", "\u{3147}"]),
  ]

  static let final: [(key: Key, renderings: [String])] = [
    (key: .gk, renderings: ["각", "갘", "갂", "각"]),
    (key: .nr, renderings: ["간", "갈", "간"]),
    (key: .dt, renderings: ["갇", "같", "가\u{3138}", "갇"]),
    (key: .bp, renderings: ["갑", "갚", "가\u{3143}", "갑"]),
    (key: .sh, renderings: ["갓", "갛", "갔", "갓"]),
    (key: .jc, renderings: ["갖", "갗", "가\u{3149}", "갖"]),
    (key: .om, renderings: ["강", "감", "강"]),
  ]

  static let initials: [(keys: [Key], rendering: String)] = [
    (keys: [.gk, .i, .arae], rendering: "\u{AC00}"),
    (keys: [.gk, .gk, .i, .arae], rendering: "\u{CE74}"),
    (keys: [.gk, .gk, .gk, .i, .arae], rendering: "\u{AE4C}"),
    (keys: [.nr, .i, .arae], rendering: "\u{B098}"),
    (keys: [.nr, .nr, .i, .arae], rendering: "\u{B77C}"),
    (keys: [.dt, .i, .arae], rendering: "\u{B2E4}"),
    (keys: [.dt, .dt, .i, .arae], rendering: "\u{D0C0}"),
    (keys: [.dt, .dt, .dt, .i, .arae], rendering: "\u{B530}"),
    (keys: [.bp, .i, .arae], rendering: "\u{BC14}"),
    (keys: [.bp, .bp, .i, .arae], rendering: "\u{D30C}"),
    (keys: [.bp, .bp, .bp, .i, .arae], rendering: "\u{BE60}"),
    (keys: [.sh, .i, .arae], rendering: "\u{C0AC}"),
    (keys: [.sh, .sh, .i, .arae], rendering: "\u{D558}"),
    (keys: [.sh, .sh, .sh, .i, .arae], rendering: "\u{C2F8}"),
    (keys: [.jc, .i, .arae], rendering: "\u{C790}"),
    (keys: [.jc, .jc, .i, .arae], rendering: "\u{CC28}"),
    (keys: [.jc, .jc, .jc, .i, .arae], rendering: "\u{C9DC}"),
    (keys: [.om, .i, .arae], rendering: "\u{C544}"),
    (keys: [.om, .om, .i, .arae], rendering: "\u{B9C8}"),
  ]

  /// A lone jamo renders from the compatibility table and a syllable from the initial index, so only a
  /// full syllable shows an initial sitting at the wrong index.
  @Test("every one of the nineteen initials opens its own syllable", arguments: initials)
  func everyInitial(_ sample: (keys: [Key], rendering: String)) {
    Typist.expectRendering(Typist.compose(sample.keys).composing, is: sample.rendering)
  }

  @Test("a consonant behind a block that is no full syllable starts its own block")
  func consonantAfterAnIncompleteBlock() {
    Typist.expectRendering(Typist.compose([.i, .gk]).composing, is: "\u{3163}\u{3131}")
    Typist.expectRendering(Typist.compose([.gk, .arae, .gk]).composing, is: "\u{1100}\u{119E}\u{3131}")
  }

  @Test("a cycling consonant never folds into a block that is no full syllable")
  func noFoldIntoAnIncompleteBlock() {
    Typist.expectRendering(Typist.compose([.i, .om, .om]).composing, is: "\u{3163}\u{3141}")
    Typist.expectRendering(Typist.compose([.eu, .nr, .nr]).composing, is: "\u{3161}\u{3139}")
    Typist.expectRendering(Typist.compose([.arae, .om, .om]).composing, is: "\u{119E}\u{3141}")
    Typist.expectRendering(Typist.compose([.gk, .arae, .arae, .om, .om]).composing, is: "\u{1100}\u{11A2}\u{3141}")
  }

  @Test("a repeated key cycles a lone jamo and wraps", arguments: lone)
  func loneCycle(_ sample: (key: Key, renderings: [String])) {
    var typist = Typist()
    for (index, expected) in sample.renderings.enumerated() {
      let step = typist.press(sample.key)
      Typist.expectRendering(step.composing, is: expected, "press \(index + 1)")
      #expect(step.committed.isEmpty)
    }
  }

  @Test("a repeated key cycles the final consonant and wraps", arguments: final)
  func finalCycle(_ sample: (key: Key, renderings: [String])) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae]).composing, is: "가")
    for (index, expected) in sample.renderings.enumerated() {
      let step = typist.press(sample.key)
      Typist.expectRendering(step.composing, is: expected, "press \(index + 1)")
      #expect(step.committed.isEmpty)
    }
  }

  @Test("a double consonant that cannot be a final detaches and rejoins on the wrap")
  func detachedDoubleRejoins() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .dt, .dt, .dt]).composing, is: "가\u{3138}")
    Typist.expectRendering(typist.press(.dt).composing, is: "갇")
  }

  @Test("every key starts a jamo from an empty composition", arguments: Key.allCases)
  func firstPressNeverIdles(_ key: Key) {
    let result = Typist.compose([key])
    #expect(!result.composing.isEmpty)
    #expect(result.committed.isEmpty)
  }
}
