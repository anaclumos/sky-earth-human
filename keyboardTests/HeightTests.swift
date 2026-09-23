import Testing
import UIKit

@MainActor
@Suite("Keyboard height")
struct HeightTests {
  @Test("the input view height for every key size, with and without the prediction bar")
  func heightPerKeySize() {
    #expect(HeightMetrics.predictionBarHeight == 60)
    #expect(HeightMetrics.inputViewHeight(for: .small, predictionBarShown: false) == 226)
    #expect(HeightMetrics.inputViewHeight(for: .medium, predictionBarShown: false) == 258)
    #expect(HeightMetrics.inputViewHeight(for: .large, predictionBarShown: false) == 290)
    #expect(HeightMetrics.inputViewHeight(for: .small, predictionBarShown: true) == 286)
    #expect(HeightMetrics.inputViewHeight(for: .medium, predictionBarShown: true) == 318)
    #expect(HeightMetrics.inputViewHeight(for: .large, predictionBarShown: true) == 350)
  }

  @Test("showing the bar adds exactly the bar's own height", arguments: KeySize.allCases)
  func barAddsItsOwnHeight(_ keySize: KeySize) {
    let shown = HeightMetrics.inputViewHeight(for: keySize, predictionBarShown: true)
    let hidden = HeightMetrics.inputViewHeight(for: keySize, predictionBarShown: false)
    #expect(shown - hidden == HeightMetrics.predictionBarHeight)
  }

  @Test("a compact height window gets the landscape rows, with and without the prediction bar")
  func compactHeightPerKeySize() {
    #expect(HeightMetrics.inputViewHeight(for: .small, predictionBarShown: true, compactHeight: true) == 206)
    #expect(HeightMetrics.inputViewHeight(for: .medium, predictionBarShown: true, compactHeight: true) == 222)
    #expect(HeightMetrics.inputViewHeight(for: .large, predictionBarShown: true, compactHeight: true) == 238)
    #expect(HeightMetrics.inputViewHeight(for: .small, predictionBarShown: false, compactHeight: true) == 146)
    #expect(HeightMetrics.inputViewHeight(for: .medium, predictionBarShown: false, compactHeight: true) == 162)
    #expect(HeightMetrics.inputViewHeight(for: .large, predictionBarShown: false, compactHeight: true) == 178)
  }

  @Test("the compact height is shorter than the regular one for every key size", arguments: KeySize.allCases)
  func compactIsShorter(_ keySize: KeySize) {
    let regular = HeightMetrics.inputViewHeight(for: keySize, predictionBarShown: true)
    let compact = HeightMetrics.inputViewHeight(for: keySize, predictionBarShown: true, compactHeight: true)
    #expect(compact < regular)
    #expect(HeightMetrics.rowHeight(for: keySize, compactHeight: true) < HeightMetrics.rowHeight(for: keySize, compactHeight: false))
  }

  @Test("the default is the regular height, so a caller that knows nothing of orientation is unchanged")
  func defaultIsRegular() {
    #expect(
      HeightMetrics.inputViewHeight(for: .medium, predictionBarShown: true)
        == HeightMetrics.inputViewHeight(for: .medium, predictionBarShown: true, compactHeight: false)
    )
  }

  @Test("the controller installs one constraint and only moves its constant afterwards")
  func oneConstraintPerView() {
    let view = UIView()
    let controller = HeightController(view: view)

    controller.apply(keySize: .medium, predictionBarShown: true)
    #expect(view.constraints.count == 1)
    #expect(view.constraints[0].constant == 318)
    #expect(view.constraints[0].priority == UILayoutPriority(999))

    controller.apply(keySize: .small, predictionBarShown: false)
    #expect(view.constraints.count == 1)
    #expect(view.constraints[0].constant == 226)

    controller.apply(keySize: .medium, predictionBarShown: true, compactHeight: true)
    #expect(view.constraints.count == 1)
    #expect(view.constraints[0].constant == 222)
  }
}
