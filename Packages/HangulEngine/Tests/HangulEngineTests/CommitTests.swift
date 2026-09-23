import HangulEngine
import Testing

@Suite("Commit")
struct CommitTests {
  @Test("commit hands back the rendering and clears the composition")
  func commitClears() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i]).composing, is: "\u{AE30}")
    let committed = typist.commit()
    Typist.expectRendering(committed.committed, is: "\u{AE30}")
    #expect(committed.composing.isEmpty)
  }

  @Test("commit hands back every block of a multi block composition")
  func commitCarriesEveryBlock() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .gk, .i]).composing, is: "\u{AC00}\u{AE30}")
    let committed = typist.commit()
    Typist.expectRendering(committed.committed, is: "\u{AC00}\u{AE30}")
    #expect(committed.composing.isEmpty)
  }

  @Test("the composer is idle after a commit")
  func idleAfterCommit() {
    var typist = Typist()
    typist.press([.gk, .i, .arae])
    _ = typist.commit()
    let afterCommit = typist.backspace()
    #expect(afterCommit == nil)
    let second = typist.commit()
    #expect(second.committed.isEmpty)
    #expect(second.composing.isEmpty)
  }

  @Test("a press after a commit starts a fresh composition")
  func pressAfterCommitStartsFresh() {
    var typist = Typist()
    typist.press([.gk, .i])
    _ = typist.commit()
    let next = typist.press(.gk)
    #expect(next.committed.isEmpty)
    Typist.expectRendering(next.composing, is: "\u{3131}")
  }

  @Test("two words separated by a commit render independently")
  func twoWords() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i]).composing, is: "\u{AE30}")
    let first = typist.commit()
    Typist.expectRendering(first.committed, is: "\u{AE30}")
    #expect(first.composing.isEmpty)
    Typist.expectRendering(typist.press([.nr, .arae, .i]).composing, is: "\u{B108}")
    let second = typist.commit()
    Typist.expectRendering(second.committed, is: "\u{B108}")
    #expect(second.composing.isEmpty)
  }

  @Test("commit with nothing composed is empty")
  func idleCommit() {
    var typist = Typist()
    let idle = typist.commit()
    #expect(idle.committed.isEmpty)
    #expect(idle.composing.isEmpty)
  }

  @Test("no press ever commits", arguments: Key.allCases)
  func pressNeverCommits(_ key: Key) {
    var typist = Typist()
    for seed in [Key.gk, .i, .arae, .nr, .nr, .bp, .sh, .eu, .arae, .om] {
      let step = typist.press(seed)
      #expect(step.committed.isEmpty)
    }
    let first = typist.press(key)
    #expect(first.committed.isEmpty)
    let repeated = typist.press(key)
    #expect(repeated.committed.isEmpty)
    let unlocked = typist.press(key, after: Typist.afterLock)
    #expect(unlocked.committed.isEmpty)
  }
}
