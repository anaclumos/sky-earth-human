import HangulEngine
import Testing

/// Every accept and reject below is a pair that `CanExtendTests` already pins against the reference automaton.
/// U+D56B has, U+D558 ha, U+D558 U+C138 U+C694 haseyo, U+D558 U+C2DC hasi, U+D558 U+B298 haneul,
/// U+D558 U+C14D haseng, U+C548 U+B155 annyeong, U+AC01 gag, U+AC00 U+AE30 gagi, U+B098 na.
@Suite("CompletionFilter")
struct CompletionFilterTests {
  typealias Completion = CompletionFilter.Completion

  static let has: [Key] = [.sh, .sh, .i, .arae, .sh]
  static let haseng: [Key] = [.sh, .sh, .i, .arae, .sh, .arae, .i, .i, .om]
  static let gag: [Key] = [.gk, .i, .arae, .gk]

  typealias Boundary = (text: String, fragment: String)
  typealias Partial = (text: String, composing: String, partials: [String])

  static let boundaries: [Boundary] = [
    (text: "", fragment: ""),
    (text: "\u{C548}\u{B155}", fragment: "\u{C548}\u{B155}"),
    (text: "\u{C624}\u{B298} \u{C548}", fragment: "\u{C548}"),
    (text: "\u{C624}\u{B298}\n\u{C548}", fragment: "\u{C548}"),
    (text: "\u{C624}\u{B298}\t\u{C548}", fragment: "\u{C548}"),
    (text: "\u{C624}\u{B298} ", fragment: ""),
    (text: "\u{C548}\u{B155} \u{C624}\u{B298} \u{C548}\u{B155}", fragment: "\u{C548}\u{B155}"),
    (text: "\u{C548}\u{B155}\n\u{C624}\u{B298} \u{C548}", fragment: "\u{C548}"),
    (text: "\u{C548}\u{B155} \u{C624}\u{B298}\n", fragment: ""),
    (text: "  \u{C548}", fragment: "\u{C548}"),
  ]

  static let partials: [Partial] = [
    (text: "", composing: "", partials: []),
    (text: "\u{C624}\u{B298} ", composing: "", partials: []),
    (text: "\u{C548}\u{B155}", composing: "", partials: ["\u{C548}\u{B155}"]),
    (text: "", composing: "\u{D56B}", partials: ["\u{D56B}"]),
    (text: "\u{C548}\u{B155}", composing: "\u{D56B}", partials: ["\u{C548}\u{B155}\u{D56B}", "\u{C548}\u{B155}"]),
    (text: "", composing: "\u{D558}\u{C14D}", partials: ["\u{D558}\u{C14D}", "\u{D558}"]),
    (
      text: "\u{C548}",
      composing: "\u{D558}\u{C14D}",
      partials: ["\u{C548}\u{D558}\u{C14D}", "\u{C548}\u{D558}", "\u{C548}"]
    ),
    (
      text: "",
      composing: "\u{C548}\u{B155}\u{D56B}",
      partials: ["\u{C548}\u{B155}\u{D56B}", "\u{C548}\u{B155}", "\u{C548}"]
    ),
    (
      text: "\u{C624}\u{B298} \u{C544}",
      composing: "\u{C548}\u{B155}\u{D56B}",
      partials: ["\u{C544}\u{C548}\u{B155}\u{D56B}", "\u{C544}\u{C548}\u{B155}", "\u{C544}\u{C548}"]
    ),
  ]

  static func typing(_ keys: [Key], rendering: String) -> Typist {
    var typist = Typist()
    Typist.expectRendering(typist.press(keys).composing, is: rendering)
    return typist
  }

  static func scalars(_ texts: [String]) -> [[Unicode.Scalar]] {
    texts.map { Array($0.unicodeScalars) }
  }

  @Test("the word being typed is kept while its next initial still sits as a final")
  func transientFinal() {
    let typist = Self.typing(Self.has, rendering: "\u{D56B}")
    let filter = CompletionFilter(textBeforeCursor: "", composing: typist.composing)
    let shown = filter.completions(
      from: ["\u{D558}\u{B298}", "\u{D558}\u{C138}\u{C694}", "\u{D558}", "\u{D558}\u{C2DC}"],
      limit: 3,
      canExtend: typist.canExtend
    )
    #expect(shown == [
      Completion(word: "\u{D558}\u{C138}\u{C694}", replacedLength: 0),
      Completion(word: "\u{D558}\u{C2DC}", replacedLength: 0),
    ])
  }

  @Test("the committed fragment is kept verbatim and only the remainder is checked against the composition")
  func fragmentPlusComposing() {
    let typist = Self.typing(Self.has, rendering: "\u{D56B}")
    let filter = CompletionFilter(textBeforeCursor: "\u{C624}\u{B298} \u{C548}\u{B155}", composing: typist.composing)
    #expect(filter.fragment == "\u{C548}\u{B155}")
    let shown = filter.completions(
      from: [
        "\u{C548}\u{B155}\u{D558}\u{B298}",
        "\u{D558}\u{C138}\u{C694}",
        "\u{C54A}\u{B155}\u{D558}\u{C138}\u{C694}",
        "\u{C548}\u{B155}\u{D558}\u{C138}\u{C694}",
        "\u{C548}\u{B155}",
      ],
      limit: 3,
      canExtend: typist.canExtend
    )
    #expect(shown == [Completion(word: "\u{C548}\u{B155}\u{D558}\u{C138}\u{C694}", replacedLength: 2)])
  }

  @Test("the fragment is the committed text after the last whitespace", arguments: boundaries)
  func fragmentBoundary(_ sample: Boundary) {
    #expect(CompletionFilter(textBeforeCursor: sample.text, composing: "").fragment == sample.fragment)
  }

  @Test("only the run after the last whitespace is replaced, however many words precede it")
  func fragmentAfterSeveralWords() {
    let typist = Self.typing(Self.has, rendering: "\u{D56B}")
    let filter = CompletionFilter(
      textBeforeCursor: "\u{C548}\u{B155} \u{C624}\u{B298} \u{C548}\u{B155}",
      composing: typist.composing
    )
    #expect(filter.fragment == "\u{C548}\u{B155}")
    #expect(
      filter.completions(
        from: ["\u{C548}\u{B155}\u{D558}\u{C138}\u{C694}"],
        limit: 3,
        canExtend: typist.canExtend
      ) == [Completion(word: "\u{C548}\u{B155}\u{D558}\u{C138}\u{C694}", replacedLength: 2)]
    )

    let trailing = CompletionFilter(
      textBeforeCursor: "\u{C548}\u{B155} \u{C624}\u{B298} ",
      composing: typist.composing
    )
    #expect(trailing.fragment.isEmpty)
    #expect(
      trailing.completions(from: ["\u{D558}\u{C138}\u{C694}"], limit: 3, canExtend: typist.canExtend)
        == [Completion(word: "\u{D558}\u{C138}\u{C694}", replacedLength: 0)]
    )
  }

  @Test("a decomposed fragment is one Character and matches a precomposed candidate")
  func decomposedFragment() {
    let decomposedHa = "\u{1112}\u{1161}"
    #expect(decomposedHa.count == 1)
    #expect(decomposedHa.unicodeScalars.count == 2)

    var typist = Typist()
    Typist.expectRendering(typist.press([.sh, .arae, .i, .i, .om]).composing, is: "\u{C14D}")
    let filter = CompletionFilter(textBeforeCursor: "\u{C624}\u{B298} " + decomposedHa, composing: typist.composing)
    #expect(filter.fragment.unicodeScalars.elementsEqual(decomposedHa.unicodeScalars))
    #expect(
      filter.completions(
        from: ["\u{D558}\u{C138}\u{C694}", "\u{D558}\u{B298}"],
        limit: 3,
        canExtend: typist.canExtend
      ) == [Completion(word: "\u{D558}\u{C138}\u{C694}", replacedLength: 1)]
    )

    let idle = Typist()
    let committed = CompletionFilter(textBeforeCursor: decomposedHa, composing: idle.composing)
    #expect(
      committed.completions(from: ["\u{D558}\u{C138}\u{C694}"], limit: 3, canExtend: idle.canExtend)
        == [Completion(word: "\u{D558}\u{C138}\u{C694}", replacedLength: 1)]
    )
  }

  @Test("a candidate equal to the current word as rendered is dropped")
  func currentWordIsDropped() {
    let typist = Self.typing(Self.gag, rendering: "\u{AC01}")
    #expect(typist.canExtend(to: "\u{AC01}"))
    let composing = CompletionFilter(textBeforeCursor: "", composing: typist.composing)
    #expect(
      composing.completions(from: ["\u{AC01}", "\u{AC00}\u{AE30}"], limit: 3, canExtend: typist.canExtend)
        == [Completion(word: "\u{AC00}\u{AE30}", replacedLength: 0)]
    )

    let idle = Typist()
    let committed = CompletionFilter(textBeforeCursor: "\u{C548}\u{B155}", composing: idle.composing)
    #expect(
      committed.completions(
        from: ["\u{C548}\u{B155}", "\u{C548}\u{B155}\u{D558}\u{C138}\u{C694}"],
        limit: 3,
        canExtend: idle.canExtend
      ) == [Completion(word: "\u{C548}\u{B155}\u{D558}\u{C138}\u{C694}", replacedLength: 2)]
    )

    let split = CompletionFilter(textBeforeCursor: "\u{C548}\u{B155}", composing: typist.composing)
    #expect(
      split.completions(
        from: ["\u{C548}\u{B155}\u{AC01}", "\u{C548}\u{B155}\u{AC00}\u{AE30}"],
        limit: 3,
        canExtend: typist.canExtend
      ) == [Completion(word: "\u{C548}\u{B155}\u{AC00}\u{AE30}", replacedLength: 2)]
    )
  }

  @Test("a duplicate is shown once, at its first position")
  func duplicatesAreDropped() {
    let typist = Self.typing(Self.has, rendering: "\u{D56B}")
    let filter = CompletionFilter(textBeforeCursor: "", composing: typist.composing)
    let shown = filter.completions(
      from: ["\u{D558}\u{C2DC}", "\u{D558}\u{C138}\u{C694}", "\u{D558}\u{C2DC}", "\u{D558}\u{C138}\u{C694}"],
      limit: 3,
      canExtend: typist.canExtend
    )
    #expect(shown.map(\.word) == ["\u{D558}\u{C2DC}", "\u{D558}\u{C138}\u{C694}"])
  }

  @Test("the cap counts shown candidates, keeps the source order, and stops asking once it is full")
  func cap() {
    let typist = Self.typing(Self.has, rendering: "\u{D56B}")
    let filter = CompletionFilter(textBeforeCursor: "", composing: typist.composing)
    let candidates = [
      "\u{D558}\u{B298}",
      "\u{D56B}\u{B3C4}\u{ADF8}",
      "\u{D558}",
      "\u{D558}\u{C2DC}",
      "\u{D558}\u{C138}\u{C694}",
    ]
    var asked: [String] = []
    let shown = filter.completions(from: candidates, limit: 2) { text in
      asked.append(text)
      return typist.canExtend(to: text)
    }
    #expect(shown.map(\.word) == ["\u{D56B}\u{B3C4}\u{ADF8}", "\u{D558}\u{C2DC}"])
    #expect(asked == ["\u{D558}\u{B298}", "\u{D56B}\u{B3C4}\u{ADF8}", "\u{D558}", "\u{D558}\u{C2DC}"])
    #expect(filter.completions(from: candidates, limit: 0, canExtend: typist.canExtend).isEmpty)
    #expect(filter.completions(from: candidates, limit: 9, canExtend: typist.canExtend).count == 3)
  }

  @Test("partial words drop zero, one and two trailing Characters of the composing text", arguments: partials)
  func partialWords(_ sample: Partial) {
    let filter = CompletionFilter(textBeforeCursor: sample.text, composing: sample.composing)
    #expect(Self.scalars(filter.partialWords) == Self.scalars(sample.partials))
  }

  @Test("a pending araea is one Character, so it leaves the partial word in one step")
  func partialWordsWithAPendingAraea() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .arae]).composing, is: "\u{1100}\u{119E}")
    #expect(typist.composing.count == 1)

    let alone = CompletionFilter(textBeforeCursor: "", composing: typist.composing)
    #expect(Self.scalars(alone.partialWords) == Self.scalars(["\u{1100}\u{119E}"]))

    let afterFragment = CompletionFilter(textBeforeCursor: "\u{C548}", composing: typist.composing)
    #expect(Self.scalars(afterFragment.partialWords) == Self.scalars(["\u{C548}\u{1100}\u{119E}", "\u{C548}"]))

    let afterSyllable = CompletionFilter(textBeforeCursor: "", composing: "\u{AC00}\u{1100}\u{119E}")
    #expect(Self.scalars(afterSyllable.partialWords) == Self.scalars(["\u{AC00}\u{1100}\u{119E}", "\u{AC00}"]))

    let loneAraea = CompletionFilter(textBeforeCursor: "", composing: "\u{AC38}\u{119E}")
    #expect("\u{AC38}\u{119E}".count == 1)
    #expect(Self.scalars(loneAraea.partialWords) == Self.scalars(["\u{AC38}\u{119E}"]))
  }

  @Test("a pending araea keeps only the words on its own vowel branch")
  func pendingAraeaFilters() {
    var typist = Typist()
    typist.press([.gk, .arae])
    let filter = CompletionFilter(textBeforeCursor: "", composing: typist.composing)
    let shown = filter.completions(
      from: ["\u{AC00}", "\u{AC70}", "\u{AE30}", "\u{ACE0}"],
      limit: 3,
      canExtend: typist.canExtend
    )
    #expect(shown.map(\.word) == ["\u{AC70}", "\u{ACE0}"])
  }

  @Test("querying every partial word finds a word the full rendering hides")
  func partialWordsFeedTheFilter() {
    let typist = Self.typing(Self.haseng, rendering: "\u{D558}\u{C14D}")
    let filter = CompletionFilter(textBeforeCursor: "", composing: typist.composing)
    let lexicon = [
      "\u{D558}\u{C14D}": [String](),
      "\u{D558}": ["\u{D558}\u{B298}", "\u{D558}\u{C138}\u{C694}", "\u{D558}\u{C138}"],
    ]
    var queried: [String] = []
    let raw = filter.partialWords.flatMap { partial in
      queried.append(partial)
      return lexicon[partial] ?? []
    }
    #expect(queried == ["\u{D558}\u{C14D}", "\u{D558}"])
    #expect(
      filter.completions(from: raw, limit: 3, canExtend: typist.canExtend)
        == [Completion(word: "\u{D558}\u{C138}\u{C694}", replacedLength: 0)]
    )
  }
}
