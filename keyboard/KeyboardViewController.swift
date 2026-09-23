import SwiftUI
import UIKit

/// Not final: the root's tests subclass it only to hand `textDocumentProxy` a fake, so the shipped
/// graph and the shipped `textDidChange` run against a proxy the test controls.
class KeyboardViewController: UIInputViewController {
  private let settings = AppGroupSettingsReader()
  private let lexicon = LexiconPredictionProvider()

  private lazy var keyboardInputView = KeyboardInputView(frame: .zero, inputViewStyle: .keyboard)
  private lazy var heightController = HeightController(view: view)
  private lazy var feedback = SystemFeedbackPlayer(settings: settings, hapticView: keyboardInputView)
  private lazy var adapter = MarkedTextInsertionAdapter(proxy: { [unowned self] in textDocumentProxy })
  private lazy var leftoverMark = LeftoverMarkLifecycle(adapter: adapter, defaults: .standard)

  /// The provider's filter asks the driver and the driver owns the provider, so the type of each
  /// is spelled out to break the inference cycle between the two declarations.
  private lazy var completions: CompletionPredictionProvider = .init { [weak self] text in
    self?.driver.canExtend(to: text) ?? false
  }

  /// Internal so the root's tests press keys on the shipped driver.
  private(set) lazy var driver: ComposerDriver = .init(
    adapter: adapter,
    provider: PredictionBarProvider(shortcuts: lexicon, completions: completions, limit: 3),
    settings: settings,
    shortcuts: lexicon
  )

  private lazy var model = KeyboardModel(
    showsNextKeyboardKey: needsInputModeSwitchKey,
    settings: settings,
    feedback: feedback,
    actions: driver,
    dismissKeyboard: { [unowned self] in dismissKeyboard() },
    configureNextKeyboardButton: { [unowned self] button in
      button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
    }
  )

  override func viewDidLoad() {
    super.viewDidLoad()
    inputView = keyboardInputView

    let host = UIHostingController(rootView: KeyboardRootView(model: model, driver: driver))
    host.view.backgroundColor = .clear
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.topAnchor.constraint(equalTo: view.topAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
    // Rotation changes the vertical size class, and the height is what the host's visible area is
    // left over from, so it is reapplied there as well as on every appearance.
    registerForTraitChanges([UITraitVerticalSizeClass.self]) { (controller: KeyboardViewController, _) in
      controller.applyHeight()
    }
    applyHeight()

    // The first UITextChecker completions call in a process costs 50 ms to 2 s, so it is spent
    // here rather than on the first key press.
    _ = completions.candidates(textBeforeCursor: "\u{D558}", composing: "")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    leftoverMark.willAppear()
    reloadSettings()
    // UIKit delivers this completion on an XPC reply queue even though the SDK marks
    // UIInputViewController with NS_SWIFT_UI_ACTOR, so the closure must not be main actor
    // isolated. It traps in swift_task_checkIsolated otherwise.
    requestSupplementaryLexicon { @Sendable [weak self] supplementary in
      Task { @MainActor in self?.lexicon.update(with: supplementary) }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    leftoverMark.willDisappear { driver.reset() }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    leftoverMark.didDisappear()
  }

  /// UIKit keeps the input view alive after this controller is gone, through an associated
  /// `_UIInputViewContent`, so a hosted SwiftUI tree left inside it keeps the model, the driver and
  /// the whole graph alive with it, about 1 MB per host session. Detaching the child here is what
  /// frees the graph. Measured in `docs/status/I1.md`, M1.
  isolated deinit {
    for child in children {
      child.willMove(toParent: nil)
      child.view.removeFromSuperview()
      child.removeFromParent()
    }
  }

  override func textDidChange(_ textInput: (any UITextInput)?) {
    super.textDidChange(textInput)
    // The host answers the keyboard's own settle unmark and a declined newline here, possibly after
    // later keys, and only the adapter can tell those answers from a host change,
    // docs/status/K2.md finding 8. The root must not read the proxy to decide on its own.
    if adapter.hostTextDidChange() {
      driver.reset()
    }
  }

  private func reloadSettings() {
    model.reloadSettings()
    driver.reloadSettings()
    applyHeight()
  }

  private func applyHeight() {
    heightController.apply(
      keySize: model.keySize,
      predictionBarShown: model.isPredictionEnabled,
      compactHeight: traitCollection.verticalSizeClass == .compact
    )
  }
}

/// The two adapter members the lifecycle needs, so the sequence below runs against a fake in a test.
@MainActor
protocol LeftoverMarkAdapter {
  var hasDocument: Bool { get }
  func endLeftoverMark()
}

extension MarkedTextInsertionAdapter: LeftoverMarkAdapter {}

/// A host can keep a mark across a background or a resign, and `unmarkText()` commits it.
/// `docs/status/K2.md` measured that after a host resign the proxy has no document at disappearance,
/// and that an unconditional unmark on return then moves the caret to the start of the field, so the
/// return call is made only when the document was still attached when the keyboard left.
@MainActor
struct LeftoverMarkLifecycle {
  static let flagKey = "leftoverDocumentAttached"

  let adapter: any LeftoverMarkAdapter
  let defaults: UserDefaults

  /// `hasDocument` is read here, before the host tears the document down, because the flag is what
  /// the next appearance decides on. Nothing here touches the proxy: Safari calls this before it
  /// blurs its input, and an unmark issued now keeps the input focused with no keyboard session, so
  /// taps on it bring back an empty keyboard, `docs/status/I1.md` finding R07.
  func willDisappear(reset: () -> Void) {
    let attached = adapter.hasDocument
    reset()
    defaults.set(attached, forKey: Self.flagKey)
  }

  /// The one proxy call of a disappearance, after the host's own transition. Nothing else may follow
  /// it: a second proxy mutation in the same run loop turn as `unmarkText()` loses the text the
  /// unmark commits.
  func didDisappear() {
    adapter.endLeftoverMark()
  }

  /// The key is removed on every read so a stale true cannot leak into a later appearance.
  func willAppear() {
    let attached = defaults.bool(forKey: Self.flagKey)
    defaults.removeObject(forKey: Self.flagKey)
    if attached {
      adapter.endLeftoverMark()
    }
  }
}

struct KeyboardRootView: View {
  let model: KeyboardModel
  let driver: ComposerDriver

  var body: some View {
    VStack(spacing: 0) {
      PredictionBar(
        candidates: driver.candidates,
        isShown: model.isPredictionEnabled,
        keySize: model.keySize,
        onSelect: driver.apply
      )
      KeyboardView(model: model)
    }
  }
}
