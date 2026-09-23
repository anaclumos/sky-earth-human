import SwiftUI

struct PredictionBar: View {
  private static let slotCount = 3

  let candidates: [PredictionCandidate]
  let isShown: Bool
  let keySize: KeySize
  let onSelect: (PredictionCandidate) -> Void

  var body: some View {
    if isShown {
      HStack(spacing: 0) {
        ForEach(0 ..< Self.slotCount, id: \.self) { index in
          if index > 0 {
            Rectangle()
              .fill(Color(.secondaryKeyboardButton))
              .frame(width: 1)
              .padding(.vertical, 12)
          }
          slot(at: index)
        }
      }
      .frame(maxWidth: 500)
      .frame(maxWidth: .infinity)
      .frame(height: HeightMetrics.predictionBarHeight)
      .background(Color(.keyboardBackground))
    }
  }

  @ViewBuilder
  private func slot(at index: Int) -> some View {
    if candidates.indices.contains(index) {
      let candidate = candidates[index]
      Button {
        onSelect(candidate)
      } label: {
        Text(candidate.display)
          .font(.system(size: keySize.fontSize))
          .lineLimit(1)
          .minimumScaleFactor(0.6)
          .foregroundStyle(Color.primary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    } else {
      Color.clear
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
