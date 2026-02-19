import SwiftUI
import UIKit

final class KeyboardViewController: UIInputViewController {
  private var viewModel: KeyboardViewModel?
  private var proxyAdapter: KeyboardDocumentProxyAdapter?

  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }

  private func setup() {
    let hangulMap = loadHangulMap()
    let proxyAdapter = KeyboardDocumentProxyAdapter { [weak self] in
      self?.textDocumentProxy
    }

    let viewModel = KeyboardViewModel(
      needsInputModeSwitchKey: needsInputModeSwitchKey,
      nextKeyboardAction: #selector(handleInputModeList(from:with:)),
      proxy: proxyAdapter,
      inputEngine: KeyboardInputEngine(hangulMap: hangulMap),
      autocompleteService: UITextCheckerAutocompleteService(language: "ko_KR"),
      settingsStore: AppGroupSettingsStore(),
      feedback: Feedback.shared,
      dismissKeyboardAction: { [weak self] in
        self?.dismissKeyboard()
      }
    )

    let keyboardView = UIHostingController(rootView: KeyboardView().environmentObject(viewModel))

    self.proxyAdapter = proxyAdapter
    self.viewModel = viewModel

    view.addSubview(keyboardView.view)
    keyboardView.view.translatesAutoresizingMaskIntoConstraints = false
    keyboardView.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
    keyboardView.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true

    addChild(keyboardView)
    keyboardView.didMove(toParent: self)

    viewModel.refreshAutocomplete()
  }

  private func loadHangulMap() -> [String: [String: String]] {
    guard
      let path = Bundle.main.path(forResource: "한글.min", ofType: "json"),
      let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
      let map = try? JSONDecoder().decode([String: [String: String]].self, from: data)
    else {
      return [:]
    }

    return map
  }
}

final class KeyboardDocumentProxyAdapter: KeyboardTextInputProxy {
  private let proxyProvider: () -> UITextDocumentProxy?

  init(proxyProvider: @escaping () -> UITextDocumentProxy?) {
    self.proxyProvider = proxyProvider
  }

  var documentContextBeforeInput: String? {
    proxyProvider()?.documentContextBeforeInput
  }

  func insertText(_ text: String) {
    proxyProvider()?.insertText(text)
  }

  func deleteBackward() {
    proxyProvider()?.deleteBackward()
  }
}
