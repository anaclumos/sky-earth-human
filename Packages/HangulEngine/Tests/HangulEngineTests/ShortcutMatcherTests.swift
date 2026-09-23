import HangulEngine
import Testing

@Suite("ShortcutMatcher")
struct ShortcutMatcherTests {
  private static let omw = ShortcutMatcher.Entry(userInput: "omw", documentText: "On my way!")
  private static let matcher = ShortcutMatcher(entries: [omw])

  /// `Expansion` is built by the matcher and nothing else, so the tests read its fields back rather
  /// than construct one to compare against.
  private static func expect(
    _ expansion: ShortcutMatcher.Expansion?,
    replacement: String,
    replacedLength: Int,
    sourceLocation: SourceLocation = #_sourceLocation
  ) {
    #expect(expansion?.replacement == replacement, sourceLocation: sourceLocation)
    #expect(expansion?.replacedLength == replacedLength, sourceLocation: sourceLocation)
  }

  @Test("an exact match on committed text expands")
  func exactMatch() {
    Self.expect(
      Self.matcher.expansion(textBeforeCursor: "omw", composing: ""),
      replacement: "On my way!",
      replacedLength: 3
    )
  }

  @Test("a prefix or an overrun of the shortcut does not match")
  func noMatchOnAPrefix() {
    #expect(Self.matcher.expansion(textBeforeCursor: "om", composing: "") == nil)
    #expect(Self.matcher.expansion(textBeforeCursor: "omwe", composing: "") == nil)
    #expect(Self.matcher.expansion(textBeforeCursor: "somw", composing: "") == nil)
  }

  @Test("a word split between committed text and composing matches")
  func wordSplitAcrossCommittedAndComposing() {
    Self.expect(
      Self.matcher.expansion(textBeforeCursor: "om", composing: "w"),
      replacement: "On my way!",
      replacedLength: 2
    )
  }

  @Test("a shortcut at the start of the field replaces no committed text")
  func matchAtTheStartOfTheField() {
    Self.expect(
      Self.matcher.expansion(textBeforeCursor: "", composing: "omw"),
      replacement: "On my way!",
      replacedLength: 0
    )
  }

  @Test("the current word starts after the last whitespace or newline")
  func wordAfterAnyWhitespace() {
    for field in ["see you omw", "see you\nomw", "see you\tomw"] {
      Self.expect(
        Self.matcher.expansion(textBeforeCursor: field, composing: ""),
        replacement: "On my way!",
        replacedLength: 3
      )
    }
  }

  @Test("replaced length counts only the committed part of the word")
  func replacedLengthCountsCommittedTextOnly() {
    Self.expect(
      Self.matcher.expansion(textBeforeCursor: "see you o", composing: "mw"),
      replacement: "On my way!",
      replacedLength: 1
    )
    #expect(
      Self.matcher.expansion(textBeforeCursor: "see you omw", composing: "")?.replacedLength == 3
    )
  }

  @Test("an entry whose two sides are equal is not a shortcut")
  func equalPairsIgnored() {
    let matcher = ShortcutMatcher(entries: [
      ShortcutMatcher.Entry(userInput: "Appleseed", documentText: "Appleseed"),
      ShortcutMatcher.Entry(userInput: "Tiburon", documentText: "Tiburon"),
    ])
    #expect(matcher.expansion(textBeforeCursor: "Appleseed", composing: "") == nil)
    #expect(matcher.expansion(textBeforeCursor: "Tiburon", composing: "") == nil)
  }

  @Test("an empty current word never matches")
  func emptyInputs() {
    #expect(Self.matcher.expansion(textBeforeCursor: "", composing: "") == nil)
    #expect(Self.matcher.expansion(textBeforeCursor: "see you ", composing: "") == nil)
    #expect(Self.matcher.expansion(textBeforeCursor: "\n", composing: "") == nil)

    let empty = ShortcutMatcher(entries: [])
    #expect(empty.expansion(textBeforeCursor: "omw", composing: "") == nil)

    let blankShortcut = ShortcutMatcher(entries: [
      ShortcutMatcher.Entry(userInput: "", documentText: "On my way!"),
    ])
    #expect(blankShortcut.expansion(textBeforeCursor: "", composing: "") == nil)
    #expect(blankShortcut.expansion(textBeforeCursor: "see you ", composing: "") == nil)
  }

  @Test("matching is case insensitive for Latin")
  func caseInsensitiveForLatin() {
    let matcher = ShortcutMatcher(entries: [
      ShortcutMatcher.Entry(userInput: "iphone", documentText: "iPhone"),
    ])
    #expect(matcher.expansion(textBeforeCursor: "iphone", composing: "")?.replacement == "iPhone")
    #expect(matcher.expansion(textBeforeCursor: "IPHONE", composing: "")?.replacement == "iPhone")
    #expect(matcher.expansion(textBeforeCursor: "iPhOnE", composing: "")?.replacement == "iPhone")
  }

  @Test("a shortcut stored as precomposed syllables matches what the engine renders")
  func hangulSyllableShortcut() {
    let matcher = ShortcutMatcher(entries: [
      ShortcutMatcher.Entry(userInput: "\u{AC00}\u{AC00}", documentText: "\u{AC10}\u{C0AC}\u{D569}\u{B2C8}\u{B2E4}"),
    ])
    Self.expect(
      matcher.expansion(textBeforeCursor: "\u{AC00}", composing: "\u{AC00}"),
      replacement: "\u{AC10}\u{C0AC}\u{D569}\u{B2C8}\u{B2E4}",
      replacedLength: 1
    )
  }

  @Test("a shortcut stored as compatibility jamo matches the precomposed syllable")
  func hangulCompatibilityJamoShortcut() {
    let matcher = ShortcutMatcher(entries: [
      ShortcutMatcher.Entry(userInput: "\u{3131}\u{314F}", documentText: "\u{AC10}\u{C0AC}\u{D569}\u{B2C8}\u{B2E4}"),
    ])
    Self.expect(
      matcher.expansion(textBeforeCursor: "", composing: "\u{AC00}"),
      replacement: "\u{AC10}\u{C0AC}\u{D569}\u{B2C8}\u{B2E4}",
      replacedLength: 0
    )
    Self.expect(
      matcher.expansion(textBeforeCursor: "\u{AC00}", composing: ""),
      replacement: "\u{AC10}\u{C0AC}\u{D569}\u{B2C8}\u{B2E4}",
      replacedLength: 1
    )
  }

  @Test("a lone compatibility jamo shortcut matches the lone jamo the engine renders")
  func hangulLoneJamoShortcut() {
    let matcher = ShortcutMatcher(entries: [
      ShortcutMatcher.Entry(userInput: "\u{3131}", documentText: "\u{AC10}\u{C0AC}"),
    ])
    Self.expect(
      matcher.expansion(textBeforeCursor: "", composing: "\u{3131}"),
      replacement: "\u{AC10}\u{C0AC}",
      replacedLength: 0
    )
  }

  @Test("a pending araea sequence stays distinct from a precomposed syllable")
  func pendingAraeaIsNotCollapsed() {
    let matcher = ShortcutMatcher(entries: [
      ShortcutMatcher.Entry(userInput: "\u{1100}\u{119E}", documentText: "\u{AC10}\u{C0AC}"),
    ])
    Self.expect(
      matcher.expansion(textBeforeCursor: "", composing: "\u{1100}\u{119E}"),
      replacement: "\u{AC10}\u{C0AC}",
      replacedLength: 0
    )
    #expect(matcher.expansion(textBeforeCursor: "", composing: "\u{AC00}") == nil)
    #expect(matcher.expansion(textBeforeCursor: "", composing: "\u{1100}\u{11A2}") == nil)
  }

  @Test("a shortcut whose userInput contains a space never matches")
  func shortcutWithASpaceNeverMatches() {
    let matcher = ShortcutMatcher(entries: [
      ShortcutMatcher.Entry(userInput: "on my way", documentText: "On my way!"),
    ])
    #expect(matcher.expansion(textBeforeCursor: "on my way", composing: "") == nil)
    #expect(matcher.expansion(textBeforeCursor: "on my ", composing: "way") == nil)
    #expect(matcher.expansion(textBeforeCursor: "", composing: "on my way") == nil)
  }
}
