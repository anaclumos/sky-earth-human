import HangulEngine
import Testing

@Suite("Vowels")
struct VowelTests {
  static let patent: [(digits: String, keys: [Key], syllable: String, jamo: String)] = [
    (digits: "12", keys: [.i, .arae], syllable: "가", jamo: "\u{314F}"),
    (digits: "121", keys: [.i, .arae, .i], syllable: "개", jamo: "\u{3150}"),
    (digits: "122", keys: [.i, .arae, .arae], syllable: "갸", jamo: "\u{3151}"),
    (digits: "1221", keys: [.i, .arae, .arae, .i], syllable: "걔", jamo: "\u{3152}"),
    (digits: "21", keys: [.arae, .i], syllable: "거", jamo: "\u{3153}"),
    (digits: "211", keys: [.arae, .i, .i], syllable: "게", jamo: "\u{3154}"),
    (digits: "221", keys: [.arae, .arae, .i], syllable: "겨", jamo: "\u{3155}"),
    (digits: "2211", keys: [.arae, .arae, .i, .i], syllable: "계", jamo: "\u{3156}"),
    (digits: "23", keys: [.arae, .eu], syllable: "고", jamo: "\u{3157}"),
    (digits: "2312", keys: [.arae, .eu, .i, .arae], syllable: "과", jamo: "\u{3158}"),
    (digits: "23121", keys: [.arae, .eu, .i, .arae, .i], syllable: "괘", jamo: "\u{3159}"),
    (digits: "231", keys: [.arae, .eu, .i], syllable: "괴", jamo: "\u{315A}"),
    (digits: "223", keys: [.arae, .arae, .eu], syllable: "교", jamo: "\u{315B}"),
    (digits: "32", keys: [.eu, .arae], syllable: "구", jamo: "\u{315C}"),
    (digits: "3221", keys: [.eu, .arae, .arae, .i], syllable: "궈", jamo: "\u{315D}"),
    (digits: "32211", keys: [.eu, .arae, .arae, .i, .i], syllable: "궤", jamo: "\u{315E}"),
    (digits: "321", keys: [.eu, .arae, .i], syllable: "귀", jamo: "\u{315F}"),
    (digits: "322", keys: [.eu, .arae, .arae], syllable: "규", jamo: "\u{3160}"),
    (digits: "3", keys: [.eu], syllable: "그", jamo: "\u{3161}"),
    (digits: "31", keys: [.eu, .i], syllable: "긔", jamo: "\u{3162}"),
    (digits: "1", keys: [.i], syllable: "기", jamo: "\u{3163}"),
  ]

  /// Every medial of the automaton paired with every vowel key it has no edge for, 47 pairs over the
  /// 23 states. The two pending araea states have all three edges and do not appear.
  static let deadEnds: [(keys: [Key], rendering: String)] = [
    (keys: [.gk, .arae, .arae, .eu, .i], rendering: "\u{AD50}\u{3163}"),
    (keys: [.gk, .arae, .arae, .eu, .arae], rendering: "\u{AD50}\u{119E}"),
    (keys: [.gk, .arae, .arae, .eu, .eu], rendering: "\u{AD50}\u{3161}"),
    (keys: [.gk, .arae, .arae, .i, .arae], rendering: "\u{ACA8}\u{119E}"),
    (keys: [.gk, .arae, .arae, .i, .eu], rendering: "\u{ACA8}\u{3161}"),
    (keys: [.gk, .arae, .arae, .i, .i, .i], rendering: "\u{ACC4}\u{3163}"),
    (keys: [.gk, .arae, .arae, .i, .i, .arae], rendering: "\u{ACC4}\u{119E}"),
    (keys: [.gk, .arae, .arae, .i, .i, .eu], rendering: "\u{ACC4}\u{3161}"),
    (keys: [.gk, .arae, .eu, .arae], rendering: "\u{ACE0}\u{119E}"),
    (keys: [.gk, .arae, .eu, .eu], rendering: "\u{ACE0}\u{3161}"),
    (keys: [.gk, .arae, .eu, .i, .i], rendering: "\u{AD34}\u{3163}"),
    (keys: [.gk, .arae, .eu, .i, .eu], rendering: "\u{AD34}\u{3161}"),
    (keys: [.gk, .arae, .eu, .i, .arae, .arae], rendering: "\u{ACFC}\u{119E}"),
    (keys: [.gk, .arae, .eu, .i, .arae, .eu], rendering: "\u{ACFC}\u{3161}"),
    (keys: [.gk, .arae, .eu, .i, .arae, .i, .i], rendering: "\u{AD18}\u{3163}"),
    (keys: [.gk, .arae, .eu, .i, .arae, .i, .arae], rendering: "\u{AD18}\u{119E}"),
    (keys: [.gk, .arae, .eu, .i, .arae, .i, .eu], rendering: "\u{AD18}\u{3161}"),
    (keys: [.gk, .arae, .i, .arae], rendering: "\u{AC70}\u{119E}"),
    (keys: [.gk, .arae, .i, .eu], rendering: "\u{AC70}\u{3161}"),
    (keys: [.gk, .arae, .i, .i, .i], rendering: "\u{AC8C}\u{3163}"),
    (keys: [.gk, .arae, .i, .i, .arae], rendering: "\u{AC8C}\u{119E}"),
    (keys: [.gk, .arae, .i, .i, .eu], rendering: "\u{AC8C}\u{3161}"),
    (keys: [.gk, .eu, .eu], rendering: "\u{ADF8}\u{3161}"),
    (keys: [.gk, .eu, .arae, .eu], rendering: "\u{AD6C}\u{3161}"),
    (keys: [.gk, .eu, .arae, .arae, .eu], rendering: "\u{ADDC}\u{3161}"),
    (keys: [.gk, .eu, .arae, .arae, .i, .arae], rendering: "\u{AD88}\u{119E}"),
    (keys: [.gk, .eu, .arae, .arae, .i, .eu], rendering: "\u{AD88}\u{3161}"),
    (keys: [.gk, .eu, .arae, .i, .i], rendering: "\u{ADC0}\u{3163}"),
    (keys: [.gk, .eu, .arae, .i, .arae], rendering: "\u{ADC0}\u{119E}"),
    (keys: [.gk, .eu, .arae, .i, .eu], rendering: "\u{ADC0}\u{3161}"),
    (keys: [.gk, .i, .i], rendering: "\u{AE30}\u{3163}"),
    (keys: [.gk, .i, .eu], rendering: "\u{AE30}\u{3161}"),
    (keys: [.gk, .i, .arae, .eu], rendering: "\u{AC00}\u{3161}"),
    (keys: [.gk, .eu, .i, .i], rendering: "\u{AE14}\u{3163}"),
    (keys: [.gk, .eu, .i, .arae], rendering: "\u{AE14}\u{119E}"),
    (keys: [.gk, .eu, .i, .eu], rendering: "\u{AE14}\u{3161}"),
    (keys: [.gk, .eu, .arae, .arae, .i, .i, .i], rendering: "\u{ADA4}\u{3163}"),
    (keys: [.gk, .eu, .arae, .arae, .i, .i, .arae], rendering: "\u{ADA4}\u{119E}"),
    (keys: [.gk, .eu, .arae, .arae, .i, .i, .eu], rendering: "\u{ADA4}\u{3161}"),
    (keys: [.gk, .i, .arae, .arae, .arae], rendering: "\u{AC38}\u{119E}"),
    (keys: [.gk, .i, .arae, .arae, .eu], rendering: "\u{AC38}\u{3161}"),
    (keys: [.gk, .i, .arae, .i, .i], rendering: "\u{AC1C}\u{3163}"),
    (keys: [.gk, .i, .arae, .i, .arae], rendering: "\u{AC1C}\u{119E}"),
    (keys: [.gk, .i, .arae, .i, .eu], rendering: "\u{AC1C}\u{3161}"),
    (keys: [.gk, .i, .arae, .arae, .i, .i], rendering: "\u{AC54}\u{3163}"),
    (keys: [.gk, .i, .arae, .arae, .i, .arae], rendering: "\u{AC54}\u{119E}"),
    (keys: [.gk, .i, .arae, .arae, .i, .eu], rendering: "\u{AC54}\u{3161}"),
  ]

  @Test("a vowel key with no edge from the current medial starts a new block", arguments: deadEnds)
  func noEdgeStartsABlock(_ sample: (keys: [Key], rendering: String)) {
    Typist.expectRendering(Typist.compose(sample.keys).composing, is: sample.rendering)
  }

  @Test("every medial of the patent table follows a g initial", arguments: patent)
  func afterAnInitial(_ sample: (digits: String, keys: [Key], syllable: String, jamo: String)) {
    let result = Typist.compose([.gk] + sample.keys)
    Typist.expectRendering(result.composing, is: sample.syllable, "digits \(sample.digits)")
    #expect(result.committed.isEmpty)
  }

  @Test("every medial of the patent table stands alone", arguments: patent)
  func withoutAnInitial(_ sample: (digits: String, keys: [Key], syllable: String, jamo: String)) {
    let result = Typist.compose(sample.keys)
    Typist.expectRendering(result.composing, is: sample.jamo, "digits \(sample.digits)")
    #expect(result.committed.isEmpty)
  }

  @Test("the double araea has a back edge to the single araea")
  func araeaBackEdge() {
    Typist.expectRendering(Typist.compose([.arae, .arae]).composing, is: "\u{11A2}")
    Typist.expectRendering(Typist.compose([.arae, .arae, .arae]).composing, is: "\u{119E}")
    Typist.expectRendering(Typist.compose([.gk, .arae, .arae, .arae]).composing, is: "\u{1100}\u{119E}")
  }

  @Test("yu has a back edge to u")
  func yuBackEdge() {
    Typist.expectRendering(Typist.compose([.eu, .arae, .arae]).composing, is: "\u{3160}")
    Typist.expectRendering(Typist.compose([.eu, .arae, .arae, .arae]).composing, is: "\u{315C}")
  }

  @Test("a vowel key off the current branch starts a new block")
  func offBranchVowelStartsABlock() {
    Typist.expectRendering(Typist.compose([.gk, .eu, .i, .i]).composing, is: "긔\u{3163}")
    Typist.expectRendering(Typist.compose([.gk, .i, .arae, .arae, .arae]).composing, is: "갸\u{119E}")
  }
}
