import HangulEngine
import Testing

@Suite("Composer state")
struct StateTests {
  @Test("a new composer is idle with nothing composing")
  func startsIdle() {
    let typist = Typist()
    #expect(!typist.isComposing)
    #expect(typist.composing.isEmpty)
  }

  @Test("composing reads back what every press returned")
  func composingFollowsPresses() {
    var typist = Typist()
    let steps: [(key: Key, rendering: String)] = [
      (key: .gk, rendering: "\u{3131}"),
      (key: .i, rendering: "\u{AE30}"),
      (key: .arae, rendering: "\u{AC00}"),
      (key: .gk, rendering: "\u{AC01}"),
      (key: .i, rendering: "\u{AC00}\u{AE30}"),
      (key: .arae, rendering: "\u{AC00}\u{AC00}"),
    ]
    for step in steps {
      let pressed = typist.press(step.key)
      Typist.expectRendering(pressed.composing, is: step.rendering)
      Typist.expectRendering(typist.composing, is: step.rendering)
      #expect(typist.isComposing)
    }
  }

  @Test("composing and isComposing follow a backspace down to idle")
  func stateFollowsBackspace() throws {
    var typist = Typist()
    typist.press([.gk, .i, .arae, .gk, .i])
    for expected in ["\u{AC01}", "\u{AC00}", "\u{AE30}", "\u{3131}"] {
      let rewound = typist.backspace()
      let step = try #require(rewound)
      Typist.expectRendering(step.composing, is: expected)
      Typist.expectRendering(typist.composing, is: expected)
      #expect(typist.isComposing)
    }
    let last = typist.backspace()
    let emptied = try #require(last)
    #expect(emptied.composing.isEmpty)
    #expect(typist.composing.isEmpty)
    #expect(!typist.isComposing)
  }

  @Test("composing and isComposing clear on commit and start again on the next press")
  func stateFollowsCommit() {
    var typist = Typist()
    typist.press([.nr, .arae, .i])
    Typist.expectRendering(typist.composing, is: "\u{B108}")
    #expect(typist.isComposing)
    let committed = typist.commit()
    Typist.expectRendering(committed.committed, is: "\u{B108}")
    #expect(typist.composing.isEmpty)
    #expect(!typist.isComposing)
    typist.press(.om)
    Typist.expectRendering(typist.composing, is: "\u{3147}")
    #expect(typist.isComposing)
  }
}
