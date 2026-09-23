public struct Composition: Equatable, Sendable {
  public var committed: String
  public var composing: String

  public init(committed: String, composing: String) {
    self.committed = committed
    self.composing = composing
  }
}
