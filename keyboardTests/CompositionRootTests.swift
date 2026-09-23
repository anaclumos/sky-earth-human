import Foundation
import HangulEngine
import Testing
import UIKit

/// The same construction order the composition root uses: the completion provider is built first
/// with a weak reference back to the object that will own the driver, then the driver.
@MainActor
private final class RootWiring {
  let adapter = FakeAdapter()
  let lexicon = LexiconPredictionProvider()

  private let source: @MainActor (String) -> [String]

  private lazy var completions: CompletionPredictionProvider = .init(
    limit: 3,
    source: source,
    canExtend: { [weak self] text in self?.driver.canExtend(to: text) ?? false }
  )

  lazy var driver: ComposerDriver = .init(
    adapter: adapter,
    provider: PredictionBarProvider(shortcuts: lexicon, completions: completions, limit: 3),
    settings: FakeSettings(),
    shortcuts: lexicon
  )

  init(source: @escaping @MainActor (String) -> [String]) {
    self.source = source
  }
}

/// The two adapter members the lifecycle drives, with a scripted `hasDocument` and one call log that
/// the driver reset writes into as well, so the order of the three calls is what the test reads.
@MainActor
private final class FakeLeftoverAdapter: LeftoverMarkAdapter {
  var attached = true
  var log: [String] = []

  var hasDocument: Bool {
    log.append("hasDocument")
    return attached
  }

  func endLeftoverMark() {
    log.append("end")
  }
}

/// The shipped controller with only its document proxy replaced, so `textDidChange` and the graph
/// the controller builds are the real ones.
@MainActor
private final class FakeProxyKeyboardViewController: KeyboardViewController {
  let fake = FakeProxy()

  override var textDocumentProxy: any UITextDocumentProxy {
    fake
  }
}

@MainActor
@Suite("Composition root")
struct CompositionRootTests {
  /// Runs main actor turns until the proxy has recorded `count` calls. The adapter's settle and
  /// return hops are real `Task`s in the shipped controller.
  private func calls(_ proxy: FakeProxy, count: Int) async throws -> [String] {
    for _ in 0 ..< 200 where proxy.calls.count < count {
      try await Task.sleep(for: .milliseconds(5))
    }
    try #require(proxy.calls.count == count, "proxy calls \(proxy.calls)")
    return proxy.take()
  }

  @Test("the controller's textDidChange resets the driver when the adapter reads a host change")
  func textDidChangeResetsOnAHostChange() async throws {
    let controller = FakeProxyKeyboardViewController()
    let proxy = controller.fake
    controller.loadViewIfNeeded()
    controller.driver.handle(.hangul(.gk))
    #expect(try await calls(proxy, count: 2) == ["unmarkText", "setMarkedText(\u{3131}, 1, 0)"])

    proxy.hostSends(before: "\u{AC00}", hasText: true)
    controller.textDidChange(nil)
    controller.driver.handle(.hangul(.i))

    // A reset dropped the composing U+3131, so the adapter settles again and U+3163 starts anew.
    #expect(try await calls(proxy, count: 2) == ["unmarkText", "setMarkedText(\u{3163}, 1, 0)"])
  }

  @Test("the controller's textDidChange keeps the composition when the callback is the host's answer to the keyboard's own unmark")
  func textDidChangeKeepsTheCompositionOnAnAnswer() async throws {
    let controller = FakeProxyKeyboardViewController()
    let proxy = controller.fake
    proxy.hostSends(before: "\u{AC00}\u{B098}\u{0020}", hasText: true)
    proxy.hostMark = "\u{D558}\u{B298}"
    controller.loadViewIfNeeded()
    controller.driver.handle(.hangul(.gk))
    #expect(try await calls(proxy, count: 2) == ["unmarkText", "setMarkedText(\u{3131}, 1, 0)"])

    // The host's answer to the unmark carries the field as of the unmark, which is what the
    // adapter expects, docs/status/K2.md finding 8.
    proxy.hostSends(before: "\u{AC00}\u{B098}\u{0020}\u{D558}\u{B298}", hasText: true)
    controller.textDidChange(nil)
    controller.driver.handle(.hangul(.i))

    #expect(proxy.take() == ["setMarkedText(\u{AE30}, 1, 0)"])
  }

  @Test("a lexicon shortcut takes slot one and completions fill the two slots after it")
  func shortcutLeadsTheBar() {
    let lexicon = LexiconPredictionProvider()
    lexicon.update(entries: [ShortcutMatcher.Entry(userInput: "omw", documentText: "on my way")])
    let completions = CompletionPredictionProvider(
      limit: 3,
      source: { _ in ["omwa", "omwb", "omwc"] },
      canExtend: { _ in true }
    )
    let provider = PredictionBarProvider(shortcuts: lexicon, completions: completions, limit: 3)

    let shown = provider.candidates(textBeforeCursor: "omw", composing: "")
    #expect(shown.map(\.insertion) == ["on my way", "omwa", "omwb"])
    #expect(shown.map(\.replacedLength) == [3, 3, 3])
  }

  @Test("a completion the composition cannot reach is filtered out through the driver")
  func canExtendRoutesToTheDriver() {
    let wiring = RootWiring(source: { _ in ["\u{AC00}", "\u{C774}"] })
    wiring.driver.handle(.hangul(.gk))
    #expect(wiring.driver.candidates.map(\.insertion) == ["\u{AC00}"])
  }

  private func makeDefaults(_ name: String) throws -> UserDefaults {
    let defaults = try #require(UserDefaults(suiteName: name))
    defaults.removePersistentDomain(forName: name)
    return defaults
  }

  @Test("the disappearance reads the document, resets the driver and records the flag, and ends the leftover mark only once it is over")
  func disappearanceOrder() throws {
    let name = "sh.cho.sky-earth-human.tests.\(UUID().uuidString)"
    let defaults = try makeDefaults(name)
    defer { defaults.removePersistentDomain(forName: name) }
    let adapter = FakeLeftoverAdapter()
    let lifecycle = LeftoverMarkLifecycle(adapter: adapter, defaults: defaults)

    lifecycle.willDisappear { adapter.log.append("reset") }
    #expect(adapter.log == ["hasDocument", "reset"])
    #expect(defaults.bool(forKey: LeftoverMarkLifecycle.flagKey))

    lifecycle.didDisappear()
    #expect(adapter.log == ["hasDocument", "reset", "end"])
  }

  @Test("the controller's viewWillDisappear leaves the proxy alone and its viewDidDisappear issues the one unmark")
  func controllerUnmarksOnlyAfterTheDisappearance() async throws {
    defer { UserDefaults.standard.removeObject(forKey: LeftoverMarkLifecycle.flagKey) }
    let controller = FakeProxyKeyboardViewController()
    let proxy = controller.fake
    controller.loadViewIfNeeded()
    controller.driver.handle(.hangul(.gk))
    #expect(try await calls(proxy, count: 2) == ["unmarkText", "setMarkedText(\u{3131}, 1, 0)"])

    // Safari calls viewWillDisappear before it blurs the input, and an unmark issued there keeps
    // the input focused with no keyboard session, docs/status/I1.md finding R07.
    controller.viewWillDisappear(false)
    #expect(proxy.take().isEmpty)

    controller.viewDidDisappear(false)
    #expect(proxy.take() == ["unmarkText"])
  }

  @Test("the appearance ends the leftover mark once when the document was still attached when the keyboard left")
  func appearanceEndsTheMarkWhenAttached() throws {
    let name = "sh.cho.sky-earth-human.tests.\(UUID().uuidString)"
    let defaults = try makeDefaults(name)
    defer { defaults.removePersistentDomain(forName: name) }
    let adapter = FakeLeftoverAdapter()
    adapter.attached = true
    let lifecycle = LeftoverMarkLifecycle(adapter: adapter, defaults: defaults)

    lifecycle.willDisappear {}
    adapter.log = []
    lifecycle.willAppear()
    lifecycle.willAppear()

    #expect(adapter.log == ["end"])
    #expect(defaults.object(forKey: LeftoverMarkLifecycle.flagKey) == nil)
  }

  @Test("the appearance makes no call when the proxy had no document when the keyboard left")
  func appearanceSkipsTheCallWhenDetached() throws {
    let name = "sh.cho.sky-earth-human.tests.\(UUID().uuidString)"
    let defaults = try makeDefaults(name)
    defer { defaults.removePersistentDomain(forName: name) }
    let adapter = FakeLeftoverAdapter()
    adapter.attached = false
    let lifecycle = LeftoverMarkLifecycle(adapter: adapter, defaults: defaults)

    lifecycle.willDisappear {}
    #expect(defaults.object(forKey: LeftoverMarkLifecycle.flagKey) != nil)
    #expect(defaults.bool(forKey: LeftoverMarkLifecycle.flagKey) == false)
    adapter.log = []
    lifecycle.willAppear()

    #expect(adapter.log.isEmpty)
    #expect(defaults.object(forKey: LeftoverMarkLifecycle.flagKey) == nil)
  }
}
