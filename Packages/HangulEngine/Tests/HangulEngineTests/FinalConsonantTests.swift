import HangulEngine
import Testing

@Suite("Final consonants")
struct FinalConsonantTests {
  static let compounds: [(name: String, keys: [Key], syllable: String)] = [
    (name: "U+3133", keys: [.gk, .sh], syllable: "\u{AC03}"),
    (name: "U+3135", keys: [.nr, .jc], syllable: "\u{AC05}"),
    (name: "U+3136", keys: [.nr, .sh, .sh], syllable: "\u{AC06}"),
    (name: "U+313A", keys: [.nr, .nr, .gk], syllable: "\u{AC09}"),
    (name: "U+313B", keys: [.nr, .nr, .om, .om], syllable: "\u{AC0A}"),
    (name: "U+313C", keys: [.nr, .nr, .bp], syllable: "\u{AC0B}"),
    (name: "U+313D", keys: [.nr, .nr, .sh], syllable: "\u{AC0C}"),
    (name: "U+313E", keys: [.nr, .nr, .dt, .dt], syllable: "\u{AC0D}"),
    (name: "U+313F", keys: [.nr, .nr, .bp, .bp], syllable: "\u{AC0E}"),
    (name: "U+3140", keys: [.nr, .nr, .sh, .sh], syllable: "\u{AC0F}"),
    (name: "U+3144", keys: [.bp, .sh], syllable: "\u{AC12}"),
  ]

  @Test("a consonant after a complete syllable becomes its final")
  func firstFinal() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae]).composing, is: "\u{AC00}")
    Typist.expectRendering(typist.press(.gk).composing, is: "\u{AC01}")
  }

  @Test("every compound final forms from its two components", arguments: compounds)
  func compoundForms(_ sample: (name: String, keys: [Key], syllable: String)) {
    let result = Typist.compose([.gk, .i, .arae] + sample.keys)
    Typist.expectRendering(result.composing, is: sample.syllable, "compound \(sample.name)")
    #expect(result.committed.isEmpty)
  }

  @Test("a compound final cycles through its second component and detaches")
  func compoundCycleDetaches() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .nr, .nr]).composing, is: "\u{AC08}")
    Typist.expectRendering(typist.press(.bp).composing, is: "\u{AC0B}")
    Typist.expectRendering(typist.press(.bp).composing, is: "\u{AC0E}")
    Typist.expectRendering(typist.press(.bp).composing, is: "\u{AC08}\u{3143}")
  }

  @Test("a compound final splits when its second component leaves the cycle")
  func compoundFinalSplits() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.om, .arae, .i]).composing, is: "\u{C5B4}")
    Typist.expectRendering(typist.press(.bp).composing, is: "\u{C5C5}")
    Typist.expectRendering(typist.press(.sh).composing, is: "\u{C5C6}")
    Typist.expectRendering(typist.press(.sh).composing, is: "\u{C5C5}\u{314E}")
    Typist.expectRendering(typist.press(.arae).composing, is: "\u{C5C5}\u{1112}\u{119E}")
    Typist.expectRendering(typist.press(.eu).composing, is: "\u{C5C5}\u{D638}")
  }

  @Test("a consonant that pairs with no final starts a new block")
  func unpairableConsonantStartsABlock() {
    Typist.expectRendering(Typist.compose([.gk, .i, .arae, .nr, .nr, .om]).composing, is: "\u{AC08}\u{3147}")
    Typist.expectRendering(Typist.compose([.gk, .i, .arae, .nr, .jc, .gk]).composing, is: "\u{AC05}\u{3131}")
  }
}
