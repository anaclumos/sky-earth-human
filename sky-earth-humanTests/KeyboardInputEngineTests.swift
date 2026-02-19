import XCTest
@testable import sky_earth_human

final class KeyboardInputEngineTests: XCTestCase {
  func testHangulTransitionFromSingleToDoubleToCollapsedCharacter() {
    let engine = KeyboardInputEngine(
      hangulMap: [
        "key": [
          "a": "ab",
          "ab": "c",
        ]
      ])

    let proxy = FakeKeyboardProxy()

    engine.insertHangul(key: "key", fallback: "a", proxy: proxy)
    XCTAssertEqual(proxy.text, "a")

    engine.insertHangul(key: "key", fallback: "a", proxy: proxy)
    XCTAssertEqual(proxy.text, "ab")

    engine.insertHangul(key: "key", fallback: "a", proxy: proxy)
    XCTAssertEqual(proxy.text, "c")
  }

  func testComposableInputCyclesAndWraps() {
    let engine = KeyboardInputEngine(hangulMap: [:])
    let proxy = FakeKeyboardProxy()

    engine.composableInput(candidates: ["a", "b", "c"], proxy: proxy)
    XCTAssertEqual(proxy.text, "a")

    engine.composableInput(candidates: ["a", "b", "c"], proxy: proxy)
    XCTAssertEqual(proxy.text, "b")

    engine.composableInput(candidates: ["a", "b", "c"], proxy: proxy)
    XCTAssertEqual(proxy.text, "c")

    engine.composableInput(candidates: ["a", "b", "c"], proxy: proxy)
    XCTAssertEqual(proxy.text, "a")
  }

  func testDeleteUsesCompositionHistoryBeforeHostDelete() {
    let engine = KeyboardInputEngine(
      hangulMap: [
        "key": [
          "a": "b",
          "b": "c",
        ]
      ])

    let proxy = FakeKeyboardProxy()

    engine.insertHangul(key: "key", fallback: "a", proxy: proxy)
    engine.insertHangul(key: "key", fallback: "a", proxy: proxy)

    XCTAssertEqual(proxy.text, "b")

    engine.deleteBackward(proxy: proxy)
    XCTAssertEqual(proxy.text, "a")

    engine.deleteBackward(proxy: proxy)
    XCTAssertEqual(proxy.text, "")
  }

  func testSpaceOnlyInsertsWhenCompositionIsNotEditing() {
    let engine = KeyboardInputEngine(hangulMap: [:])
    let proxy = FakeKeyboardProxy(text: "hello")

    let learned = engine.space(proxy: proxy)

    XCTAssertEqual(learned, "hello")
    XCTAssertEqual(proxy.text, "hello ")

    engine.simpleInput("a", proxy: proxy)

    let learnedWhileEditing = engine.space(proxy: proxy)

    XCTAssertNil(learnedWhileEditing)
    XCTAssertEqual(proxy.text, "hello a")
  }
}

private final class FakeKeyboardProxy: KeyboardTextInputProxy {
  var text: String

  init(text: String = "") {
    self.text = text
  }

  var documentContextBeforeInput: String? {
    text
  }

  func insertText(_ text: String) {
    self.text += text
  }

  func deleteBackward() {
    guard !text.isEmpty else { return }
    text.removeLast()
  }
}
