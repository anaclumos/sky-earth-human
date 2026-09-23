import HangulEngine
import Testing

/// The 399 in-entry disagreements between the v1.1 map and the reference automaton are all the BP
/// key on a compound final. Version 2 takes the automaton value, so these cases are pinned here.
@Suite("BP on a compound final")
struct CompoundFinalBPTests {
  @Test("BP on the RB compound cycles its second half to P")
  func cyclesTheSecondHalf() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .nr, .nr, .bp]).composing, is: "\u{AC0B}")
    Typist.expectRendering(typist.press(.bp).composing, is: "\u{AC0E}")
  }

  @Test("BP on the RP compound detaches the double because it is no final")
  func detachesTheDouble() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .nr, .nr, .bp, .bp]).composing, is: "\u{AC0E}")
    Typist.expectRendering(typist.press(.bp).composing, is: "\u{AC08}\u{3143}")
  }

  @Test("BP on a compound whose second half is outside the cycle starts a new block")
  func startsANewBlock() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .bp, .sh]).composing, is: "\u{AC12}")
    Typist.expectRendering(typist.press(.bp).composing, is: "\u{AC12}\u{3142}")

    var other = Typist()
    Typist.expectRendering(other.press([.gk, .i, .arae, .gk, .sh]).composing, is: "\u{AC03}")
    Typist.expectRendering(other.press(.bp).composing, is: "\u{AC03}\u{3142}")
  }
}
