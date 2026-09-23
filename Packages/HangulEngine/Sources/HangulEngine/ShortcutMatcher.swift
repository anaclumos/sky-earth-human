import Foundation

public struct ShortcutMatcher: Sendable {
  public struct Entry: Equatable, Sendable {
    public let userInput: String
    public let documentText: String

    public init(userInput: String, documentText: String) {
      self.userInput = userInput
      self.documentText = documentText
    }
  }

  public struct Expansion: Equatable, Sendable {
    public let replacement: String
    public let replacedLength: Int
  }

  private let shortcuts: [String: String]

  public init(entries: [Entry]) {
    var shortcuts: [String: String] = [:]
    // Equal sides mean a contact name or a common word, not a Text Replacement shortcut. A userInput holding
    // whitespace is unreachable because the current word is always the tail after the last whitespace.
    for entry in entries
      where entry.userInput != entry.documentText
      && !entry.userInput.contains(where: { $0.isWhitespace })
    {
      shortcuts[Self.fold(entry.userInput)] = entry.documentText
    }
    self.shortcuts = shortcuts
  }

  public func expansion(textBeforeCursor: String, composing: String) -> Expansion? {
    let committed = Self.committedWord(in: textBeforeCursor)
    let word = String(committed) + composing
    guard !word.isEmpty, let replacement = shortcuts[Self.fold(word)] else { return nil }
    return Expansion(replacement: replacement, replacedLength: committed.count)
  }

  private static func committedWord(in textBeforeCursor: String) -> Substring {
    guard let boundary = textBeforeCursor.lastIndex(where: { $0.isWhitespace }) else {
      return textBeforeCursor[...]
    }
    return textBeforeCursor[textBeforeCursor.index(after: boundary)...]
  }

  private static func fold(_ text: String) -> String {
    text.precomposedStringWithCompatibilityMapping.lowercased()
  }
}
