import Combine
import SwiftUI

struct HangulView: View {
  var body: some View {
    KeyboardGridView(mode: .hangul)
  }
}

struct KeyboardGridView: View {
  @EnvironmentObject var viewModel: KeyboardViewModel

  let mode: KeyboardType

  @State private var repeatDeleteTimer: AnyCancellable?
  @State private var lastLongPressKeyID: String?

  var body: some View {
    VStack {
      ForEach(Array(viewModel.rows(for: mode).enumerated()), id: \.offset) { _, row in
        HStack {
          ForEach(row) { key in
            keyView(for: key)
          }
        }
      }
    }
    .frame(maxWidth: 500, maxHeight: .infinity, alignment: .center)
    .padding(.leading, 10)
    .padding(.trailing, 10)
    .padding(.bottom, 10)
    .background(Color("KeyboardBackground"))
    .onDisappear {
      repeatDeleteTimer?.cancel()
      repeatDeleteTimer = nil
      lastLongPressKeyID = nil
    }
  }

  @ViewBuilder
  private func keyView(for key: KeyboardKeyDescriptor) -> some View {
    if key.isNextKeyboardKey {
      NextKeyboardButton(
        systemName: key.systemName ?? "globe",
        action: viewModel.nextKeyboardAction,
        primary: key.primary
      )
    } else {
      KeyboardButton(
        text: key.text,
        systemName: key.systemName,
        primary: key.primary,
        action: {
          viewModel.handleTap(on: key)
        },
        onLongPress: {
          handleLongPressStart(for: key)
        },
        onLongPressFinished: {
          handleLongPressEnd(for: key)
        }
      )
    }
  }

  private func handleLongPressStart(for key: KeyboardKeyDescriptor) {
    if key.action == .delete {
      guard repeatDeleteTimer == nil else { return }

      repeatDeleteTimer = Timer.publish(every: 0.1, on: .main, in: .common)
        .autoconnect()
        .sink { _ in
          viewModel.handleDeleteRepeat()
        }
      return
    }

    guard key.longPressAction != nil else { return }
    guard lastLongPressKeyID != key.id else { return }

    lastLongPressKeyID = key.id
    viewModel.handleLongPress(on: key)
  }

  private func handleLongPressEnd(for key: KeyboardKeyDescriptor) {
    if key.action == .delete {
      repeatDeleteTimer?.cancel()
      repeatDeleteTimer = nil
    }

    if lastLongPressKeyID == key.id {
      lastLongPressKeyID = nil
    }
  }
}
