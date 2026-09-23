import HangulEngine
import Testing

/// Renderings are taken from `docs/oracle/automaton_oracle.py`, never from the engine under test.
/// U+3131 lone giyeok, U+314B lone kieuk, U+AE30 gi, U+AC00 ga, U+AC01 gak, U+B098 na, U+C0AC sa.
@Suite("Input session")
struct InputSessionTests {
  static let lock = Duration.seconds(1)
  static let step = Duration.milliseconds(100)
  static let pastLock = Duration.seconds(2)
  static let dotCycle = [".", ",", "?", "!"]

  struct Driver {
    private var session: InputSession
    private var instant = ContinuousClock.now

    init(cycleLock: Duration = InputSessionTests.lock) {
      session = InputSession(cycleLock: cycleLock)
    }

    var isComposing: Bool {
      session.isComposing
    }

    var composing: String {
      session.composing
    }

    mutating func press(
      _ key: Key,
      after gap: Duration = InputSessionTests.step
    ) -> [InputCommand] {
      instant = instant.advanced(by: gap)
      return session.handle(.hangul(key, at: instant))
    }

    @discardableResult
    mutating func press(_ keys: [Key]) -> [InputCommand] {
      var last: [InputCommand] = []
      for key in keys {
        last = press(key)
      }
      return last
    }

    mutating func punctuate(
      _ candidates: [String] = InputSessionTests.dotCycle,
      after gap: Duration = InputSessionTests.step
    ) -> [InputCommand] {
      instant = instant.advanced(by: gap)
      return session.handle(.punctuation(cycle: candidates, at: instant))
    }

    @discardableResult
    mutating func handle(_ event: InputEvent) -> [InputCommand] {
      session.handle(event)
    }
  }

  @Test("a hangul press marks the running composition")
  func hangulMarks() {
    var driver = Driver()
    #expect(driver.press(.gk) == [.setComposing("\u{3131}")])
    #expect(driver.press(.i) == [.setComposing("\u{AE30}")])
    #expect(driver.press(.arae) == [.setComposing("\u{AC00}")])
    #expect(driver.press(.gk) == [.setComposing("\u{AC01}")])
    #expect(driver.press(.i) == [.setComposing("\u{AC00}\u{AE30}")])
    #expect(driver.isComposing)
    #expect(driver.composing == "\u{AC00}\u{AE30}")
  }

  @Test("nothing is composing before the first press")
  func idleAtRest() {
    let driver = Driver()
    #expect(!driver.isComposing)
    #expect(driver.composing.isEmpty)
  }

  @Test("the press instant reaches the composer, so the cycle lock still applies")
  func instantReachesTheComposer() {
    var cycling = Driver()
    #expect(cycling.press(.gk) == [.setComposing("\u{3131}")])
    #expect(cycling.press(.gk) == [.setComposing("\u{314B}")])

    var locked = Driver()
    #expect(locked.press(.gk) == [.setComposing("\u{3131}")])
    #expect(locked.press(.gk, after: Self.pastLock) == [.setComposing("\u{3131}\u{3131}")])
  }

  @Test("the first space while composing commits and inserts no space")
  func firstSpaceCommits() {
    var driver = Driver()
    driver.press([.gk, .i])
    #expect(driver.handle(.space) == [.commit("\u{AE30}")])
    #expect(!driver.isComposing)
    #expect(driver.composing.isEmpty)
  }

  @Test("a space with nothing composing inserts a space")
  func idleSpaceInserts() {
    var driver = Driver()
    #expect(driver.handle(.space) == [.commit(" ")])
  }

  @Test("the space after the committing space inserts a space")
  func secondSpaceInserts() {
    var driver = Driver()
    driver.press([.gk, .i])
    #expect(driver.handle(.space) == [.commit("\u{AE30}")])
    #expect(driver.handle(.space) == [.commit(" ")])
  }

  @Test("a delete inside a composition rewinds one keystroke and re-marks")
  func deleteRewinds() {
    var driver = Driver()
    driver.press([.gk, .i, .arae])
    #expect(driver.composing == "\u{AC00}")
    #expect(driver.handle(.delete) == [.setComposing("\u{AE30}")])
    #expect(driver.handle(.delete) == [.setComposing("\u{3131}")])
    #expect(driver.isComposing)
  }

  @Test("a delete that empties the composition clears the mark")
  func deleteClearsTheMark() {
    var driver = Driver()
    driver.press([.gk])
    #expect(driver.handle(.delete) == [.setComposing("")])
    #expect(!driver.isComposing)
  }

  @Test("a delete outside a composition deletes one committed character")
  func deleteOutsideComposition() {
    var driver = Driver()
    #expect(driver.handle(.delete) == [.deleteBackward])

    driver.press([.gk, .i])
    #expect(driver.handle(.space) == [.commit("\u{AE30}")])
    #expect(driver.handle(.delete) == [.deleteBackward])
  }

  @Test("no delete is ever emitted while something is marked")
  func noDeleteWhileMarked() {
    var driver = Driver()
    driver.press([.gk, .i, .arae])
    #expect(driver.handle(.delete) == [.setComposing("\u{AE30}")])
    #expect(driver.handle(.delete) == [.setComposing("\u{3131}")])
    #expect(driver.handle(.delete) == [.setComposing("")])
    #expect(driver.handle(.delete) == [.deleteBackward])
  }

  @Test("plain text ends the composition before it lands")
  func plainTextEndsComposition() {
    var driver = Driver()
    driver.press([.gk, .i])
    #expect(driver.handle(.text("1")) == [.commit("\u{AE30}"), .commit("1")])
    #expect(!driver.isComposing)
  }

  @Test("plain text with nothing composing just lands")
  func plainTextIdle() {
    var driver = Driver()
    #expect(driver.handle(.text("1")) == [.commit("1")])
    #expect(driver.handle(.text("\u{2605}")) == [.commit("\u{2605}")])
  }

  @Test("return ends the composition then inserts a newline")
  func returnEndsComposition() {
    var driver = Driver()
    driver.press([.gk, .i])
    #expect(driver.handle(.returnKey) == [.commit("\u{AE30}"), .commit("\n")])
    #expect(!driver.isComposing)
    #expect(driver.handle(.returnKey) == [.commit("\n")])
  }

  @Test("flush ends the composition and inserts nothing")
  func flushEndsComposition() {
    var driver = Driver()
    driver.press([.gk, .i])
    #expect(driver.handle(.flush) == [.commit("\u{AE30}")])
    #expect(!driver.isComposing)
    #expect(driver.handle(.flush) == [])
  }

  @Test("the first punctuation press lands the first candidate")
  func punctuationFirstPress() {
    var driver = Driver()
    #expect(driver.punctuate() == [.commit(".")])
  }

  @Test("a punctuation press inside the window replaces the previous candidate and wraps")
  func punctuationCycles() {
    var driver = Driver()
    #expect(driver.punctuate() == [.commit(".")])
    #expect(driver.punctuate() == [.deleteBackward, .commit(",")])
    #expect(driver.punctuate() == [.deleteBackward, .commit("?")])
    #expect(driver.punctuate() == [.deleteBackward, .commit("!")])
    #expect(driver.punctuate() == [.deleteBackward, .commit(".")])
  }

  /// The candidate already landed as committed text, so replacing it takes one delete per Character.
  /// A single Character candidate still takes exactly one.
  @Test("a candidate longer than one Character is deleted in full")
  func punctuationReplacesEveryCharacter() {
    let ellipsis = ["\u{2026}", "..."]
    var driver = Driver()
    #expect(driver.punctuate(ellipsis) == [.commit("\u{2026}")])
    #expect(driver.punctuate(ellipsis) == [.deleteBackward, .commit("...")])
    #expect(
      driver.punctuate(ellipsis)
        == [.deleteBackward, .deleteBackward, .deleteBackward, .commit("\u{2026}")]
    )
    #expect(driver.punctuate(ellipsis, after: Self.pastLock) == [.commit("\u{2026}")])
  }

  @Test("a punctuation press exactly on the window still cycles")
  func punctuationOnTheBoundary() {
    var driver = Driver()
    #expect(driver.punctuate() == [.commit(".")])
    #expect(driver.punctuate(after: Self.lock) == [.deleteBackward, .commit(",")])
  }

  @Test("a punctuation press past the window starts the cycle again")
  func punctuationPastTheWindow() {
    var driver = Driver()
    #expect(driver.punctuate() == [.commit(".")])
    #expect(driver.punctuate(after: Self.pastLock) == [.commit(".")])
    #expect(driver.punctuate() == [.deleteBackward, .commit(",")])
  }

  @Test("punctuation ends the composition and never cycles into a marked string")
  func punctuationEndsComposition() {
    var driver = Driver()
    driver.press([.gk, .i])
    #expect(driver.punctuate() == [.commit("\u{AE30}"), .commit(".")])
    #expect(!driver.isComposing)
    #expect(driver.punctuate() == [.deleteBackward, .commit(",")])
  }

  @Test("a hangul press between two punctuation presses restarts the cycle")
  func hangulRestartsTheCycle() {
    var driver = Driver()
    #expect(driver.punctuate() == [.commit(".")])
    #expect(driver.press(.gk) == [.setComposing("\u{3131}")])
    #expect(driver.punctuate() == [.commit("\u{3131}"), .commit(".")])
  }

  @Test("a space, a delete, plain text, a return or a flush restarts the cycle")
  func otherKeysRestartTheCycle() {
    var afterSpace = Driver()
    #expect(afterSpace.punctuate() == [.commit(".")])
    #expect(afterSpace.handle(.space) == [.commit(" ")])
    #expect(afterSpace.punctuate() == [.commit(".")])

    var afterDelete = Driver()
    #expect(afterDelete.punctuate() == [.commit(".")])
    #expect(afterDelete.handle(.delete) == [.deleteBackward])
    #expect(afterDelete.punctuate() == [.commit(".")])

    var afterText = Driver()
    #expect(afterText.punctuate() == [.commit(".")])
    #expect(afterText.handle(.text("1")) == [.commit("1")])
    #expect(afterText.punctuate() == [.commit(".")])

    var afterReturn = Driver()
    #expect(afterReturn.punctuate() == [.commit(".")])
    #expect(afterReturn.handle(.returnKey) == [.commit("\n")])
    #expect(afterReturn.punctuate() == [.commit(".")])

    var afterFlush = Driver()
    #expect(afterFlush.punctuate() == [.commit(".")])
    #expect(afterFlush.handle(.flush) == [])
    #expect(afterFlush.punctuate() == [.commit(".")])
  }

  @Test("a different cycle starts at its own first candidate")
  func differentCycleRestarts() {
    var driver = Driver()
    #expect(driver.punctuate() == [.commit(".")])
    #expect(driver.punctuate(["-", "_"]) == [.commit("-")])
    #expect(driver.punctuate(["-", "_"]) == [.deleteBackward, .commit("_")])
  }

  @Test("an empty cycle emits nothing and leaves the composition alone")
  func emptyCycleDoesNothing() {
    var driver = Driver()
    driver.press([.gk, .i])
    #expect(driver.punctuate([]) == [])
    #expect(driver.isComposing)
    #expect(driver.composing == "\u{AE30}")
  }

  @Test("a run that mixes hangul, space, punctuation, delete, text and flush")
  func mixedRun() {
    var driver = Driver()
    #expect(driver.press(.gk) == [.setComposing("\u{3131}")])
    #expect(driver.press(.i) == [.setComposing("\u{AE30}")])
    #expect(driver.press(.arae) == [.setComposing("\u{AC00}")])
    #expect(driver.handle(.space) == [.commit("\u{AC00}")])
    #expect(driver.press(.nr) == [.setComposing("\u{3134}")])
    #expect(driver.press(.i) == [.setComposing("\u{B2C8}")])
    #expect(driver.press(.arae) == [.setComposing("\u{B098}")])
    #expect(driver.punctuate() == [.commit("\u{B098}"), .commit(".")])
    #expect(driver.punctuate() == [.deleteBackward, .commit(",")])
    #expect(driver.handle(.delete) == [.deleteBackward])
    #expect(driver.handle(.text("1")) == [.commit("1")])
    #expect(driver.press(.sh) == [.setComposing("\u{3145}")])
    #expect(driver.press(.i) == [.setComposing("\u{C2DC}")])
    #expect(driver.press(.arae) == [.setComposing("\u{C0AC}")])
    #expect(driver.handle(.flush) == [.commit("\u{C0AC}")])
    #expect(!driver.isComposing)
    #expect(driver.composing.isEmpty)
  }

  @Test("the cycle lock the session was built with is readable")
  func cycleLockIsReadable() {
    #expect(InputSession(cycleLock: .milliseconds(500)).cycleLock == .milliseconds(500))
  }

  @Test("canExtend answers for the running composition and accepts anything once it ends")
  func canExtendFollowsTheComposition() {
    var session = InputSession(cycleLock: Self.lock)
    var instant = ContinuousClock.now
    for key in [Key.gk, .i, .arae, .gk] {
      instant = instant.advanced(by: Self.step)
      _ = session.handle(.hangul(key, at: instant))
    }
    #expect(session.composing == "\u{AC01}")
    #expect(session.canExtend(to: "\u{AC00}\u{AE30}"))
    #expect(!session.canExtend(to: "\u{B098}"))

    _ = session.handle(.space)
    #expect(session.canExtend(to: "\u{B098}"))
  }
}
