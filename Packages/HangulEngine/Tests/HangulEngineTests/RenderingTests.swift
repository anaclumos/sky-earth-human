import HangulEngine
import Testing

@Suite("Rendering")
struct RenderingTests {
  @Test("a lone consonant renders as a compatibility jamo")
  func loneConsonant() {
    Typist.expectRendering(Typist.compose([.gk]).composing, is: "\u{3131}")
    Typist.expectRendering(Typist.compose([.om]).composing, is: "\u{3147}")
    Typist.expectRendering(Typist.compose([.sh, .sh]).composing, is: "\u{314E}")
  }

  @Test("a lone vowel renders as a compatibility jamo")
  func loneVowel() {
    Typist.expectRendering(Typist.compose([.i]).composing, is: "\u{3163}")
    Typist.expectRendering(Typist.compose([.eu]).composing, is: "\u{3161}")
    Typist.expectRendering(Typist.compose([.i, .arae]).composing, is: "\u{314F}")
  }

  @Test("a pending araea with no initial renders as the jungseong alone")
  func pendingAraeaAlone() {
    Typist.expectRendering(Typist.compose([.arae]).composing, is: "\u{119E}")
    Typist.expectRendering(Typist.compose([.arae, .arae]).composing, is: "\u{11A2}")
  }

  @Test("a pending araea after an initial renders in the U+1100 block")
  func pendingAraeaAfterAnInitial() {
    Typist.expectRendering(Typist.compose([.gk, .arae]).composing, is: "\u{1100}\u{119E}")
    Typist.expectRendering(Typist.compose([.gk, .arae, .arae]).composing, is: "\u{1100}\u{11A2}")
    Typist.expectRendering(Typist.compose([.sh, .sh, .arae]).composing, is: "\u{1112}\u{119E}")
  }

  @Test("a completed syllable renders precomposed")
  func precomposedSyllable() {
    Typist.expectRendering(Typist.compose([.gk, .i, .arae]).composing, is: "\u{AC00}")
    Typist.expectRendering(Typist.compose([.gk, .i, .arae, .gk]).composing, is: "\u{AC01}")
    Typist.expectRendering(Typist.compose([.gk, .i]).composing, is: "\u{AE30}")
  }

  /// Unicode 18.0 core specification 3.12.3 Hangul Syllable Composition, with SBase U+AC00,
  /// NCount 588 and TCount 28: s = SBase + (LIndex * NCount + VIndex * TCount) + TIndex.
  @Test("a precomposed syllable matches the Unicode composition formula")
  func compositionFormula() throws {
    let sBase: UInt32 = 0xAC00
    let nCount: UInt32 = 588
    let tCount: UInt32 = 28

    let ga = try #require(Unicode.Scalar(sBase + (0 * nCount + 0 * tCount) + 0))
    let gag = try #require(Unicode.Scalar(sBase + (0 * nCount + 0 * tCount) + 1))
    let gi = try #require(Unicode.Scalar(sBase + (0 * nCount + 20 * tCount) + 0))
    let neo = try #require(Unicode.Scalar(sBase + (2 * nCount + 4 * tCount) + 0))

    Typist.expectRendering(Typist.compose([.gk, .i, .arae]).composing, is: String(ga))
    Typist.expectRendering(Typist.compose([.gk, .i, .arae, .gk]).composing, is: String(gag))
    Typist.expectRendering(Typist.compose([.gk, .i]).composing, is: String(gi))
    Typist.expectRendering(Typist.compose([.nr, .arae, .i]).composing, is: String(neo))
  }

  @Test("two blocks render side by side")
  func twoBlocks() {
    Typist.expectRendering(Typist.compose([.gk, .nr]).composing, is: "\u{3131}\u{3134}")
    Typist.expectRendering(Typist.compose([.gk, .i, .arae, .gk, .i]).composing, is: "\u{AC00}\u{AE30}")
  }
}
