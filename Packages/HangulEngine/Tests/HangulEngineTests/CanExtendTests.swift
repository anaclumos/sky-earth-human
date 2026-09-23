import HangulEngine
import Testing

/// `canExtend(to:)` holds when some run of presses, the empty run included, leaves a rendering that is a
/// non-empty prefix of the text. Every expectation here was answered by an exhaustive search over the
/// reference automaton, not by the engine.
@Suite("canExtend")
struct CanExtendTests {
  typealias Sample = (text: String, reachable: Bool)

  static let fromGa: [Sample] = [
    (text: "\u{AC00}", reachable: true),
    (text: "\u{AC01}", reachable: true),
    (text: "\u{AC02}", reachable: true),
    (text: "\u{AC03}", reachable: true),
    (text: "\u{AC18}", reachable: true),
    (text: "\u{AC1C}", reachable: true),
    (text: "\u{AC38}", reachable: true),
    (text: "\u{AE30}", reachable: false),
    (text: "\u{ACE0}", reachable: false),
    (text: "\u{B098}", reachable: false),
    (text: "\u{B2E4}", reachable: false),
  ]

  static let fromGal: [Sample] = [
    (text: "\u{AC08}", reachable: true),
    (text: "\u{AC09}", reachable: true),
    (text: "\u{AC0A}", reachable: true),
    (text: "\u{AC0B}", reachable: true),
    (text: "\u{AC0C}", reachable: true),
    (text: "\u{AC0D}", reachable: true),
    (text: "\u{AC0E}", reachable: true),
    (text: "\u{AC0F}", reachable: true),
    (text: "\u{AC04}", reachable: true),
    (text: "\u{AC10}", reachable: false),
    (text: "\u{AC00}", reachable: false),
  ]

  static let fromGag: [Sample] = [
    (text: "\u{AC01}", reachable: true),
    (text: "\u{AC02}", reachable: true),
    (text: "\u{AC03}", reachable: true),
    (text: "\u{AC18}", reachable: true),
    (text: "\u{AC00}\u{AE30}", reachable: true),
    (text: "\u{AC00}\u{D0A4}", reachable: true),
    (text: "\u{AC00}", reachable: false),
    (text: "\u{AC00}\u{B098}", reachable: false),
    (text: "\u{AC00}\u{B2C8}", reachable: false),
    (text: "\u{B098}", reachable: false),
  ]

  static let fromHas: [Sample] = [
    (text: "\u{D558}\u{C138}\u{C694}", reachable: true),
    (text: "\u{D558}\u{C2DC}", reachable: true),
    (text: "\u{D56B}", reachable: true),
    (text: "\u{D56B}\u{B3C4}\u{ADF8}", reachable: true),
    (text: "\u{D558}\u{B298}", reachable: false),
    (text: "\u{D558}", reachable: false),
  ]

  static let fromHaSeng: [Sample] = [
    (text: "\u{D558}\u{C138}\u{C694}", reachable: true),
    (text: "\u{D558}\u{C14D}", reachable: true),
    (text: "\u{D558}\u{C138}", reachable: false),
  ]

  static let fromAnThenLoneSiot: [Sample] = [
    (text: "\u{C548}\u{3145}", reachable: true),
    (text: "\u{C548}\u{C0AC}\u{C694}", reachable: true),
    (text: "\u{C54A}\u{C544}", reachable: true),
    (text: "\u{C548}\u{B155}", reachable: false),
    (text: "\u{C548}", reachable: false),
  ]

  static let fromGaThenLoneSsangtikeut: [Sample] = [
    (text: "\u{AC00}\u{3138}", reachable: true),
    (text: "\u{AC00}\u{B530}", reachable: true),
    (text: "\u{AC00}\u{B2E4}", reachable: true),
    (text: "\u{AC00}\u{D0C0}", reachable: true),
    (text: "\u{AC07}", reachable: true),
    (text: "\u{AC19}\u{C774}", reachable: true),
    (text: "\u{B530}", reachable: false),
    (text: "\u{AC00}", reachable: false),
    (text: "\u{AC00}\u{B098}", reachable: false),
  ]

  static let fromPendingAraea: [Sample] = [
    (text: "\u{AC70}", reachable: true),
    (text: "\u{AC8C}", reachable: true),
    (text: "\u{ACE0}", reachable: true),
    (text: "\u{AD50}", reachable: true),
    (text: "\u{1100}\u{119E}", reachable: true),
    (text: "\u{1100}\u{11A2}", reachable: true),
    (text: "\u{1100}\u{119E}\u{0021}", reachable: true),
    (text: "\u{AC00}", reachable: false),
    (text: "\u{AD6C}", reachable: false),
    (text: "\u{AE30}", reachable: false),
    (text: "\u{119E}", reachable: false),
    (text: "\u{1102}\u{119E}", reachable: false),
  ]

  static let fromGaKeuk: [Sample] = [
    (text: "\u{AC18}", reachable: true),
    (text: "\u{AC01}", reachable: true),
    (text: "\u{AC02}", reachable: true),
    (text: "\u{AC03}", reachable: true),
    (text: "\u{AC00}\u{AE30}", reachable: true),
    (text: "\u{AC00}\u{D0A4}", reachable: true),
    (text: "\u{AC00}", reachable: false),
    (text: "\u{AC00}\u{B098}", reachable: false),
    (text: "\u{AC0B}", reachable: false),
    (text: "\u{B098}", reachable: false),
  ]

  static let fromGan: [Sample] = [
    (text: "\u{AC04}", reachable: true),
    (text: "\u{AC05}", reachable: true),
    (text: "\u{AC08}", reachable: true),
    (text: "\u{AC09}", reachable: true),
    (text: "\u{AC0A}", reachable: true),
    (text: "\u{AC00}\u{B098}", reachable: true),
    (text: "\u{AC00}\u{C790}", reachable: false),
    (text: "\u{AC00}", reachable: false),
    (text: "\u{AC10}", reachable: false),
  ]

  static let fromGaPeup: [Sample] = [
    (text: "\u{AC1A}", reachable: true),
    (text: "\u{AC11}", reachable: true),
    (text: "\u{AC12}", reachable: true),
    (text: "\u{AC00}\u{BC14}", reachable: true),
    (text: "\u{AC00}\u{D30C}", reachable: true),
    (text: "\u{AC00}", reachable: false),
    (text: "\u{AC00}\u{B9C8}", reachable: false),
    (text: "\u{AC13}", reachable: false),
  ]

  static let fromGags: [Sample] = [
    (text: "\u{AC03}", reachable: true),
    (text: "\u{AC01}\u{C2DC}", reachable: true),
    (text: "\u{AC01}\u{D788}", reachable: true),
    (text: "\u{AC01}\u{C528}", reachable: true),
    (text: "\u{AC01}\u{C2DC}\u{C694}", reachable: true),
    (text: "\u{AC01}\u{AE30}", reachable: false),
    (text: "\u{AC01}", reachable: false),
    (text: "\u{AC00}\u{C2DC}", reachable: false),
    (text: "\u{AC02}", reachable: false),
  ]

  static let fromGaThenLoneSsangbieup: [Sample] = [
    (text: "\u{AC00}\u{3143}", reachable: true),
    (text: "\u{AC11}", reachable: true),
    (text: "\u{AC12}", reachable: true),
    (text: "\u{AC1A}", reachable: true),
    (text: "\u{AC00}\u{BC14}", reachable: true),
    (text: "\u{AC00}\u{D30C}", reachable: true),
    (text: "\u{AC00}\u{BE60}", reachable: true),
    (text: "\u{AC00}", reachable: false),
    (text: "\u{AC00}\u{B9C8}", reachable: false),
    (text: "\u{AC13}", reachable: false),
    (text: "\u{AC0B}", reachable: false),
  ]

  static let fromGang: [Sample] = [
    (text: "\u{AC15}", reachable: true),
    (text: "\u{AC15}\u{3145}", reachable: true),
    (text: "\u{AC00}\u{110B}\u{119E}", reachable: true),
    (text: "\u{AC00}\u{110B}\u{11A2}\u{3131}", reachable: true),
    (text: "\u{AC10}", reachable: true),
    (text: "\u{AC00}\u{C544}", reachable: true),
    (text: "\u{AC00}\u{B9C8}", reachable: true),
    (text: "\u{AC00}", reachable: false),
    (text: "\u{AC00}\u{B098}", reachable: false),
  ]

  static let fromHi: [Sample] = [
    (text: "\u{D788}", reachable: true),
    (text: "\u{D7A3}", reachable: true),
    (text: "\u{D790}", reachable: true),
    (text: "\u{D7A3}\u{AC00}", reachable: true),
    (text: "\u{D788}\u{BE60}", reachable: true),
    (text: "\u{D558}", reachable: true),
    (text: "\u{D7A4}", reachable: false),
    (text: "\u{AC00}", reachable: false),
  ]

  static let fromGi: [Sample] = [
    (text: "\u{AE30}", reachable: true),
    (text: "\u{AC00}", reachable: true),
    (text: "\u{AC01}", reachable: true),
    (text: "\u{AC1C}", reachable: true),
    (text: "\u{B098}", reachable: false),
  ]

  static let fromLoneGiyeok: [Sample] = [
    (text: "\u{AC00}", reachable: true),
    (text: "\u{AE30}", reachable: true),
    (text: "\u{314B}", reachable: true),
    (text: "\u{3131}\u{3131}", reachable: true),
    (text: "\u{3131}\u{3134}", reachable: true),
    (text: "\u{C774}", reachable: false),
    (text: "\u{3134}", reachable: false),
  ]

  static let fromLoneI: [Sample] = [
    (text: "\u{3163}", reachable: true),
    (text: "\u{3163}\u{AC00}", reachable: true),
    (text: "\u{AE30}", reachable: false),
    (text: "\u{C774}", reachable: false),
    (text: "\u{AC00}", reachable: false),
  ]

  @Test("an idle composer accepts every candidate")
  func idleAcceptsEverything() {
    let typist = Typist()
    #expect(typist.canExtend(to: "\u{AC00}"))
    #expect(typist.canExtend(to: "\u{AE30}\u{B098}"))
    #expect(typist.canExtend(to: "\u{D7A3}"))
    #expect(typist.canExtend(to: "!"))
    #expect(typist.canExtend(to: ""))
  }

  @Test("a complete syllable extends along the automaton", arguments: fromGa)
  func extendingGa(_ sample: Sample) {
    var typist = Typist()
    typist.press([.gk, .i, .arae])
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// U+AC0A is reachable through a transient second block: the M key detaches, then the repeat
  /// cycles it and merges it back as the compound final.
  @Test("a simple final extends to the compound finals it can grow", arguments: fromGal)
  func extendingGal(_ sample: Sample) {
    var typist = Typist()
    typist.press([.gk, .i, .arae, .nr, .nr])
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// A final is transient. The next vowel moves it on, so U+AC01 still leads to U+AC00 U+AE30. It cannot
  /// vanish, so U+AC00 alone is out, and it keeps its key, so U+AC00 U+B098 is out.
  @Test("a final either stays or moves on as the next initial", arguments: fromGag)
  func extendingGag(_ sample: Sample) {
    var typist = Typist()
    typist.press([.gk, .i, .arae, .gk])
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  @Test("a word is still accepted while its next initial sits as a final", arguments: fromHas)
  func extendingHas(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.sh, .sh, .i, .arae, .sh]).composing, is: "\u{D56B}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  @Test("earlier blocks must already match the text", arguments: fromHaSeng)
  func extendingHaSeng(_ sample: Sample) {
    var typist = Typist()
    let keys: [Key] = [.sh, .sh, .i, .arae, .sh, .arae, .i, .i, .om]
    Typist.expectRendering(typist.press(keys).composing, is: "\u{D558}\u{C14D}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  @Test("a lone consonant behind a closed syllable opens the next one or folds in", arguments: fromAnThenLoneSiot)
  func extendingAnThenLoneSiot(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.om, .i, .arae, .nr, .sh]).composing, is: "\u{C548}\u{3145}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// The lone U+3138 can fold into U+AC00 as U+AC07, and the next vowel moves that final back out, which
  /// is how U+AC00 U+B2E4 is reached.
  @Test("a lone consonant behind an open syllable opens the next one or folds in", arguments: fromGaThenLoneSsangtikeut)
  func extendingAFoldableConsonant(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .dt, .dt, .dt]).composing, is: "\u{AC00}\u{3138}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  @Test("a pending araea extends only along its own branch", arguments: fromPendingAraea)
  func extendingPendingAraea(_ sample: Sample) {
    var typist = Typist()
    typist.press([.gk, .arae])
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  @Test("a medial still open to more keys extends further", arguments: fromGi)
  func extendingGi(_ sample: Sample) {
    var typist = Typist()
    typist.press([.gk, .i])
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// U+314B needs a press inside the lock and U+3131 U+3131 one outside it. Both count.
  @Test("a lone consonant extends to what its key can open, inside or outside the lock", arguments: fromLoneGiyeok)
  func extendingALoneConsonant(_ sample: Sample) {
    var typist = Typist()
    typist.press([.gk])
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  @Test("a lone vowel never gains an initial", arguments: fromLoneI)
  func extendingALoneVowel(_ sample: Sample) {
    var typist = Typist()
    typist.press([.i])
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// A final reaches a compound by cycling back to the jamo the compound starts with, so U+AC18 still
  /// reaches U+AC03 even though U+314B is not U+3131. Sharing the key is what decides, not equality.
  @Test("a cycled final still reaches the compounds its key can start", arguments: fromGaKeuk)
  func extendingGaKeuk(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .gk, .gk]).composing, is: "\u{AC18}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// The same rule across the NR key: U+3134 cycles to U+3139, which starts seven compounds, so
  /// U+AC04 reaches U+AC09 and U+AC0A.
  @Test("a final reaches the compounds of the other jamo on its key", arguments: fromGan)
  func extendingGan(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .nr]).composing, is: "\u{AC04}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// U+314D cycles back to U+3142, which grows into U+3144, so U+AC1A reaches U+AC12.
  @Test("a cycled final reaches a compound through the jamo it cycles back to", arguments: fromGaPeup)
  func extendingGaPeup(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .bp, .bp]).composing, is: "\u{AC1A}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// A compound final splits on the next vowel: the first half stays and the second half leaves as the
  /// next initial. So U+AC03 reaches U+AC01 U+C2DC, and it reaches U+AC01 U+D788 because the half that
  /// leaves may still cycle on its own key. Nothing else lets the compound go, so U+AC01 alone is out.
  @Test("a compound final splits, the first half stays and the second leaves", arguments: fromGags)
  func extendingGags(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .gk, .sh]).composing, is: "\u{AC03}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// U+3143 is no final, so it stands as its own block. It folds in as U+3142 or U+314D, and it folds
  /// into U+3144 behind a syllable that has no final yet, which is how U+AC12 is reached.
  @Test("a lone U+3143 folds in as a simple final or grows the compound", arguments: fromGaThenLoneSsangbieup)
  func extendingGaThenLoneSsangbieup(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .bp, .bp, .bp]).composing, is: "\u{AC00}\u{3143}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// The text may carry a pending araea of its own, as U+110B plus U+119E here. It is one block, and it
  /// can sit behind a syllable that is already settled.
  @Test("a target block may be an initial with a pending araea", arguments: fromGang)
  func extendingGang(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .om]).composing, is: "\u{AC15}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// U+D7A3 is the last precomposed syllable and is read as one, so U+D788 reaches it by one SH press.
  /// U+D7A4 is past the block and is no rendering, so nothing extends to it.
  @Test("the last precomposed syllable is read as a syllable", arguments: fromHi)
  func extendingHi(_ sample: Sample) {
    var typist = Typist()
    Typist.expectRendering(typist.press([.sh, .sh, .i]).composing, is: "\u{D788}")
    #expect(typist.canExtend(to: sample.text) == sample.reachable)
  }

  /// The renderings a candidate is compared against are precomposed, so a candidate that is canonically
  /// equal to one of them is normalized before it is read. K5 measured the system completer returning
  /// NFC already, so this is a guard. A pending araea carries no canonical composition and still reads
  /// as an initial plus its araea.
  @Test("a canonically decomposed candidate answers the same as its precomposed form")
  func decomposedCandidate() {
    var open = Typist()
    open.press([.gk, .i, .arae])
    #expect(open.canExtend(to: "\u{1100}\u{1161}"))
    #expect(open.canExtend(to: "\u{1100}\u{1161}\u{11A8}"))
    #expect(open.canExtend(to: "\u{1100}\u{1161}\u{AE30}"))
    #expect(!open.canExtend(to: "\u{1102}\u{1161}"))

    var closed = Typist()
    closed.press([.gk, .i, .arae, .gk])
    #expect(closed.canExtend(to: "\u{AC00}\u{1100}\u{1175}"))
    #expect(!closed.canExtend(to: "\u{AC00}\u{1102}\u{1161}"))

    var pending = Typist()
    Typist.expectRendering(pending.press([.gk, .arae]).composing, is: "\u{1100}\u{119E}")
    #expect(pending.canExtend(to: "\u{1100}\u{119E}"))
    #expect(pending.canExtend(to: "\u{1100}\u{11A2}"))
    #expect(!pending.canExtend(to: "\u{1100}\u{1161}"))
  }

  /// The candidate is read only as far as the blocks the composition can still reach, so a candidate of
  /// a million scalars is answered from its head and costs what a short one costs.
  @Test("a candidate of a million scalars is answered from its head")
  func aVeryLongCandidate() {
    var typist = Typist()
    typist.press([.gk, .i, .arae])
    let tail = String(repeating: "\u{AE30}", count: 1_000_000)
    #expect(typist.canExtend(to: "\u{AC00}" + tail))
    #expect(!typist.canExtend(to: "\u{B098}" + tail))
  }

  @Test("text the engine cannot produce is accepted once a rendering is a prefix of it")
  func unproducibleText() {
    var open = Typist()
    open.press([.gk, .i, .arae])
    #expect(open.canExtend(to: "\u{AC00}!"))
    #expect(open.canExtend(to: "\u{AC00}AB"))
    #expect(!open.canExtend(to: ""))

    var closed = Typist()
    closed.press([.gk, .i, .arae, .gk])
    #expect(closed.canExtend(to: "\u{AC00}\u{AE30}!"))
    #expect(!closed.canExtend(to: "\u{AC00}!"))
    #expect(!closed.canExtend(to: "!"))
  }
}
