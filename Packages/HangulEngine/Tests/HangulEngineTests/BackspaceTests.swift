import HangulEngine
import Testing

@Suite("Backspace")
struct BackspaceTests {
  @Test("backspace rewinds one keystroke at a time and empties the composition")
  func rewindToEmpty() throws {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .gk, .gk, .gk]).composing, is: "\u{AC02}")
    for expected in ["\u{AC18}", "\u{AC01}", "\u{AC00}", "\u{AE30}", "\u{3131}"] {
      let rewound = typist.backspace()
      let step = try #require(rewound)
      Typist.expectRendering(step.composing, is: expected)
      #expect(step.committed.isEmpty)
    }
    let last = typist.backspace()
    let emptied = try #require(last)
    #expect(emptied.composing.isEmpty)
    #expect(emptied.committed.isEmpty)
    let exhausted = typist.backspace()
    #expect(exhausted == nil)
  }

  @Test("backspace rewinds through a migration")
  func rewindThroughAMigration() throws {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .gk]).composing, is: "\u{AC01}")
    Typist.expectRendering(typist.press(.i).composing, is: "\u{AC00}\u{AE30}")
    let rewound = typist.backspace()
    let back = try #require(rewound)
    Typist.expectRendering(back.composing, is: "\u{AC01}")
    let rewoundAgain = typist.backspace()
    let further = try #require(rewoundAgain)
    Typist.expectRendering(further.composing, is: "\u{AC00}")
  }

  @Test("backspace rewinds through a compound final that split")
  func rewindThroughACompoundSplit() throws {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .bp, .sh]).composing, is: "\u{AC12}")
    Typist.expectRendering(typist.press(.i).composing, is: "\u{AC11}\u{C2DC}")
    let rewound = typist.backspace()
    let back = try #require(rewound)
    Typist.expectRendering(back.composing, is: "\u{AC12}")
    let rewoundAgain = typist.backspace()
    let further = try #require(rewoundAgain)
    Typist.expectRendering(further.composing, is: "\u{AC11}")
  }

  /// A fold is the one press that rewrites two blocks and removes one, so its rewind has to bring a
  /// block back and restore the syllable it folded into.
  @Test("backspace rewinds a fold and brings the lone consonant back")
  func rewindThroughAFold() throws {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .dt, .dt, .dt]).composing, is: "\u{AC00}\u{3138}")
    Typist.expectRendering(typist.press(.dt).composing, is: "\u{AC07}")
    let rewound = typist.backspace()
    let back = try #require(rewound)
    Typist.expectRendering(back.composing, is: "\u{AC00}\u{3138}")
    let rewoundAgain = typist.backspace()
    let further = try #require(rewoundAgain)
    Typist.expectRendering(further.composing, is: "\u{AC19}")

    var compound = Typist()
    Typist.expectRendering(compound.press([.gk, .i, .arae, .nr, .sh]).composing, is: "\u{AC04}\u{3145}")
    Typist.expectRendering(compound.press(.sh).composing, is: "\u{AC06}")
    let unfolded = compound.backspace()
    let restored = try #require(unfolded)
    Typist.expectRendering(restored.composing, is: "\u{AC04}\u{3145}")
  }

  @Test("backspace rewinds a cycle press to the jamo before it")
  func rewindACyclePress() throws {
    var typist = Typist()
    Typist.expectRendering(typist.press([.sh, .sh, .sh]).composing, is: "\u{3146}")
    let rewound = typist.backspace()
    let back = try #require(rewound)
    Typist.expectRendering(back.composing, is: "\u{314E}")
  }

  @Test("backspace with nothing composed returns nil")
  func idleBackspace() {
    var typist = Typist()
    let idle = typist.backspace()
    #expect(idle == nil)
  }

  @Test("backspace after a commit returns nil")
  func backspaceAfterCommit() {
    var typist = Typist()
    typist.press([.gk, .i])
    _ = typist.commit()
    let afterCommit = typist.backspace()
    #expect(afterCommit == nil)
  }
}
