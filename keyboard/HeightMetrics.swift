import CoreGraphics

enum HeightMetrics {
  /// 60 is v1.1's autocomplete strip footprint: .frame(height: 50) plus .padding(5) on all sides.
  static let predictionBarHeight: CGFloat = 60

  /// A compact height window is iPhone landscape, where the whole window is 402 points tall. The
  /// portrait rows leave the host 50 points and cover the field being typed into, so the rows shrink
  /// to land near the system keyboard's own landscape height. Measured in `docs/status/I1.md`, M3.
  static func inputViewHeight(for keySize: KeySize, predictionBarShown: Bool, compactHeight: Bool = false) -> CGFloat {
    let rowHeight = rowHeight(for: keySize, compactHeight: compactHeight)
    let rowCount: CGFloat = 4
    let rowGaps: CGFloat = 3 * 8
    let bottomPadding: CGFloat = 10
    let gridHeight = rowCount * rowHeight + rowGaps + bottomPadding
    return predictionBarShown ? gridHeight + predictionBarHeight : gridHeight
  }

  static func rowHeight(for keySize: KeySize, compactHeight: Bool) -> CGFloat {
    switch (keySize, compactHeight) {
    case (.small, false): 48
    case (.medium, false): 56
    case (.large, false): 64
    case (.small, true): 28
    case (.medium, true): 32
    case (.large, true): 36
    }
  }
}
