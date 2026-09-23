import Testing
import UIKit

@MainActor
private final class RecordingActions: KeyActionHandler {
  var actions: [KeyAction] = []

  func handle(_ action: KeyAction) {
    actions.append(action)
  }
}

@MainActor
private final class SilentFeedback: FeedbackPlayer {
  func play(_: FeedbackKind) {}
}

private struct FixedSettings: SettingsReader {
  var keySize: KeySize {
    .medium
  }

  var isHapticFeedbackEnabled: Bool {
    false
  }

  var isPredictionEnabled: Bool {
    true
  }

  var cycleLock: Duration {
    .seconds(1)
  }

  func reload() {}
}

@Suite("KeyboardModel delete repeat")
@MainActor
struct KeyboardModelDeleteRepeatTests {
  private func makeModel(_ actions: RecordingActions) -> KeyboardModel {
    KeyboardModel(
      showsNextKeyboardKey: false,
      settings: FixedSettings(),
      feedback: SilentFeedback(),
      actions: actions,
      dismissKeyboard: {},
      configureNextKeyboardButton: { _ in }
    )
  }

  @Test("the repeat deletes once the moment it starts, so a hold shorter than the first tick still deletes")
  func deletesOnStart() {
    let actions = RecordingActions()
    let model = makeModel(actions)
    model.beginDeleteRepeat()
    model.endDeleteRepeat()
    #expect(actions.actions == [.delete])
  }

  @Test("beginning again while the repeat runs does not delete a second time")
  func beginningTwiceDeletesOnce() {
    let actions = RecordingActions()
    let model = makeModel(actions)
    model.beginDeleteRepeat()
    model.beginDeleteRepeat()
    model.endDeleteRepeat()
    #expect(actions.actions == [.delete])
  }

  @Test("the repeat keeps deleting while it is held")
  func keepsDeletingWhileHeld() async throws {
    let actions = RecordingActions()
    let model = makeModel(actions)
    model.beginDeleteRepeat()
    // Polls instead of sleeping a fixed span: a fixed wait raced the repeat's 100 ms tick under load.
    let deadline = ContinuousClock.now + .seconds(5)
    while actions.actions.count <= 1, ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(5))
    }
    model.endDeleteRepeat()
    #expect(actions.actions.allSatisfy { $0 == .delete })
    #expect(actions.actions.count > 1)
  }

  @Test("no delete lands after the press ends")
  func stopsOnEnd() async throws {
    let actions = RecordingActions()
    let model = makeModel(actions)
    model.beginDeleteRepeat()
    try await Task.sleep(for: .milliseconds(250))
    model.endDeleteRepeat()
    let atEnd = actions.actions.count
    try await Task.sleep(for: .milliseconds(400))
    #expect(actions.actions.count == atEnd)
  }
}
