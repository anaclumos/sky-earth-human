import HangulEngine
import Testing

@Suite("Cycle lock")
struct CycleLockTests {
  @Test("a repeat inside the lock cycles the jamo")
  func insideTheLock() {
    var typist = Typist()
    Typist.expectRendering(typist.press(.gk).composing, is: "\u{3131}")
    Typist.expectRendering(typist.press(.gk, after: .milliseconds(500)).composing, is: "\u{314B}")
    Typist.expectRendering(typist.press(.gk, after: .milliseconds(500)).composing, is: "\u{3132}")
  }

  @Test("a repeat after the lock starts a new jamo")
  func afterTheLock() {
    var typist = Typist()
    Typist.expectRendering(typist.press(.gk).composing, is: "\u{3131}")
    Typist.expectRendering(typist.press(.gk, after: Typist.afterLock).composing, is: "\u{3131}\u{3131}")
  }

  @Test("the lock is measured from the last press, not from the first")
  func lockRunsFromTheLastPress() {
    var typist = Typist()
    Typist.expectRendering(typist.press(.gk).composing, is: "\u{3131}")
    Typist.expectRendering(typist.press(.gk, after: .milliseconds(900)).composing, is: "\u{314B}")
    Typist.expectRendering(typist.press(.gk, after: .milliseconds(900)).composing, is: "\u{3132}")
  }

  @Test("a repeat at exactly the lock still cycles and the smallest step past it starts a new jamo")
  func lockBoundary() {
    var onTheLock = Typist()
    Typist.expectRendering(onTheLock.press(.gk).composing, is: "\u{3131}")
    Typist.expectRendering(onTheLock.press(.gk, after: Typist.lock).composing, is: "\u{314B}")
    Typist.expectRendering(onTheLock.press(.gk, after: Typist.lock).composing, is: "\u{3132}")

    let smallestStep = Duration(secondsComponent: 0, attosecondsComponent: 1)
    var pastTheLock = Typist()
    Typist.expectRendering(pastTheLock.press(.gk).composing, is: "\u{3131}")
    Typist.expectRendering(pastTheLock.press(.gk, after: Typist.lock + smallestStep).composing, is: "\u{3131}\u{3131}")
  }

  @Test("a final consonant stops cycling after the lock")
  func finalAfterTheLock() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .nr]).composing, is: "\u{AC04}")
    Typist.expectRendering(typist.press(.nr, after: Typist.afterLock).composing, is: "\u{AC04}\u{3134}")
  }

  @Test("the second half of a compound final stops cycling after the lock")
  func compoundFinalAfterTheLock() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .gk, .sh]).composing, is: "\u{AC03}")
    Typist.expectRendering(typist.press(.sh, after: Typist.afterLock).composing, is: "\u{AC03}\u{3145}")

    var other = Typist()
    Typist.expectRendering(other.press([.gk, .i, .arae, .nr, .nr, .bp]).composing, is: "\u{AC0B}")
    Typist.expectRendering(other.press(.bp, after: Typist.afterLock).composing, is: "\u{AC0B}\u{3142}")
  }

  @Test("another key in between ends the cycle")
  func anotherKeyEndsTheCycle() {
    Typist.expectRendering(Typist.compose([.gk, .nr, .gk]).composing, is: "\u{3131}\u{3134}\u{3131}")
  }

  @Test("a vowel key continues its automaton after the lock")
  func vowelsIgnoreTheLock() {
    var typist = Typist()
    Typist.expectRendering(typist.press(.arae).composing, is: "\u{119E}")
    Typist.expectRendering(typist.press(.arae, after: Typist.afterLock).composing, is: "\u{11A2}")

    var slowWriter = Typist()
    Typist.expectRendering(slowWriter.press(.i).composing, is: "\u{3163}")
    Typist.expectRendering(slowWriter.press(.arae, after: .seconds(5)).composing, is: "\u{314F}")
    Typist.expectRendering(slowWriter.press(.i, after: .seconds(5)).composing, is: "\u{3150}")
  }

  @Test("a vowel key does not reopen a locked consonant cycle")
  func vowelDoesNotReopenTheCycle() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae]).composing, is: "\u{AC00}")
    Typist.expectRendering(typist.press(.gk, after: Typist.afterLock).composing, is: "\u{AC01}")
    Typist.expectRendering(typist.press(.gk, after: Typist.afterLock).composing, is: "\u{AC01}\u{3131}")
  }

  @Test("the lock duration comes from the initializer")
  func lockDurationIsConfigurable() {
    var quick = Typist(cycleLock: .milliseconds(250))
    Typist.expectRendering(quick.press(.gk).composing, is: "\u{3131}")
    Typist.expectRendering(quick.press(.gk, after: .milliseconds(400)).composing, is: "\u{3131}\u{3131}")

    var patient = Typist(cycleLock: .seconds(5))
    Typist.expectRendering(patient.press(.gk).composing, is: "\u{3131}")
    Typist.expectRendering(patient.press(.gk, after: .seconds(3)).composing, is: "\u{314B}")
  }
}
