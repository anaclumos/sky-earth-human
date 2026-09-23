import UIKit

@MainActor
final class HeightController {
  private let view: UIView
  private var heightConstraint: NSLayoutConstraint?

  init(view: UIView) {
    self.view = view
  }

  func apply(keySize: KeySize, predictionBarShown: Bool, compactHeight: Bool = false) {
    let height = HeightMetrics.inputViewHeight(
      for: keySize,
      predictionBarShown: predictionBarShown,
      compactHeight: compactHeight
    )
    if let heightConstraint {
      heightConstraint.constant = height
    } else {
      let constraint = view.heightAnchor.constraint(equalToConstant: height)
      constraint.priority = UILayoutPriority(999)
      constraint.isActive = true
      heightConstraint = constraint
    }
    view.setNeedsLayout()
    view.layoutIfNeeded()
  }
}
