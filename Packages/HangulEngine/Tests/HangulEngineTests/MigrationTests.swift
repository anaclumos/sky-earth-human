import HangulEngine
import Testing

@Suite("Final consonant migration")
struct MigrationTests {
  static let compoundSplits: [(name: String, keys: [Key], formed: String, split: String)] = [
    (name: "U+3133", keys: [.gk, .sh], formed: "\u{AC03}", split: "\u{AC01}\u{C2DC}"),
    (name: "U+3135", keys: [.nr, .jc], formed: "\u{AC05}", split: "\u{AC04}\u{C9C0}"),
    (name: "U+3136", keys: [.nr, .sh, .sh], formed: "\u{AC06}", split: "\u{AC04}\u{D788}"),
    (name: "U+313A", keys: [.nr, .nr, .gk], formed: "\u{AC09}", split: "\u{AC08}\u{AE30}"),
    (name: "U+313B", keys: [.nr, .nr, .om, .om], formed: "\u{AC0A}", split: "\u{AC08}\u{BBF8}"),
    (name: "U+313C", keys: [.nr, .nr, .bp], formed: "\u{AC0B}", split: "\u{AC08}\u{BE44}"),
    (name: "U+313D", keys: [.nr, .nr, .sh], formed: "\u{AC0C}", split: "\u{AC08}\u{C2DC}"),
    (name: "U+313E", keys: [.nr, .nr, .dt, .dt], formed: "\u{AC0D}", split: "\u{AC08}\u{D2F0}"),
    (name: "U+313F", keys: [.nr, .nr, .bp, .bp], formed: "\u{AC0E}", split: "\u{AC08}\u{D53C}"),
    (name: "U+3140", keys: [.nr, .nr, .sh, .sh], formed: "\u{AC0F}", split: "\u{AC08}\u{D788}"),
    (name: "U+3144", keys: [.bp, .sh], formed: "\u{AC12}", split: "\u{AC11}\u{C2DC}"),
  ]

  @Test("a vowel after a simple final moves the whole final into a new syllable")
  func simpleFinalMigrates() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .gk]).composing, is: "\u{AC01}")
    Typist.expectRendering(typist.press(.i).composing, is: "\u{AC00}\u{AE30}")
  }

  @Test("a vowel after a compound final moves only its second half", arguments: compoundSplits)
  func compoundFinalMigrates(_ sample: (name: String, keys: [Key], formed: String, split: String)) {
    var typist = Typist()
    let built = typist.press([.gk, .i, .arae] + sample.keys)
    Typist.expectRendering(built.composing, is: sample.formed, "compound \(sample.name)")
    let moved = typist.press(.i)
    Typist.expectRendering(moved.composing, is: sample.split, "compound \(sample.name) after the I key")
    #expect(moved.committed.isEmpty)
  }

  @Test("a migrated consonant keeps the jamo the cycle left it on")
  func migrationKeepsTheCycledJamo() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .gk, .gk]).composing, is: "\u{AC18}")
    Typist.expectRendering(typist.press(.i).composing, is: "\u{AC00}\u{D0A4}")
  }

  @Test("a vowel after a lone consonant attaches to it instead of migrating")
  func vowelAttachesToALoneConsonant() {
    Typist.expectRendering(Typist.compose([.gk, .i]).composing, is: "\u{AE30}")
    Typist.expectRendering(Typist.compose([.nr, .arae, .i]).composing, is: "\u{B108}")
  }

  @Test("a migrated consonant takes the next vowel with it")
  func migratedConsonantCarriesOn() {
    var typist = Typist()
    Typist.expectRendering(typist.press([.gk, .i, .arae, .om]).composing, is: "\u{AC15}")
    Typist.expectRendering(typist.press(.arae).composing, is: "\u{AC00}\u{110B}\u{119E}")
    Typist.expectRendering(typist.press(.i).composing, is: "\u{AC00}\u{C5B4}")
  }
}
