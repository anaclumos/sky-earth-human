# Rebuild plan

Version 2 of the Cheonjiin keyboard, built from an empty tree. Version 1.1 sources are archived on branch `archive/v1` at commit `1fe3471`. This is a clean-room build. The 1.1 code is not a source for any node, only its observable behavior, its user-facing content and the patent inform the design. This file is the DAG that subagents execute. The orchestrator spawns and verifies and never edits.

## Fixed points

| Item | Value |
| --- | --- |
| App bundle id | `sh.cho.sky-earth-human` |
| Keyboard bundle id | `sh.cho.sky-earth-human.keyboard` |
| App Group | `group.sh.cho.sky-earth-human.settings` |
| Team | `QKPXP9788L` |
| Minimum iOS | 17.0 on every target |
| Swift | 6 language mode, strict concurrency |
| UI | SwiftUI, `@Observable`, `UIHostingController` inside the extension |
| Tests | Swift Testing |
| Layout | 4 by 4 Cheonjiin grid, three symbol pages, long-press digits, key order row 1 I, ARAE, EU, delete, row 2 GK, NR, DT, return, row 3 BP, SH, JC, punctuation cycle, row 4 symbol page, globe when the system asks for it, OM, space, dismiss |
| Marketing version | 2.0 |
| `RequestsOpenAccess` | false |
| `IsASCIICapable` | false |
| `PrimaryLanguage` | `ko-KR` |
| Formatting | `.swiftformat` at the repository root |
| Xcode project | Synchronized root folders so adding a source file never edits `project.pbxproj` |

## Reference facts

Every node builds on these. Each line links its source.

- A keyboard without Full Access gets read-only access to the App Group container, the Settings text shortcuts list, and a common words lexicon. [Configuring open access](https://developer.apple.com/documentation/uikit/configuring-open-access-for-a-custom-keyboard)
- `setMarkedText(_:selectedRange:)` and `unmarkText()` exist on the document proxy from iOS 13. [setMarkedText](https://developer.apple.com/documentation/uikit/uitextdocumentproxy/setmarkedtext(_:selectedrange:))
- `requestSupplementaryLexicon` returns Text Replacement shortcuts, unpaired contact names, and common words as `userInput` and `documentText` pairs. [UILexicon](https://developer.apple.com/documentation/uikit/uilexicon), [UILexiconEntry](https://developer.apple.com/documentation/uikit/uilexiconentry)
- Keyboard height is a height constraint on the input view controller's view. [Custom Keyboard guide](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/CustomKeyboard.html)
- Input clicks come from `UIInputViewAudioFeedback` plus `playInputClick()` and follow the system keyboard-click setting. [playInputClick](https://developer.apple.com/documentation/uikit/uidevice/playinputclick())
- No API lets a keyboard extension show the system QuickType bar. [Apple forums answer](https://developer.apple.com/forums/thread/7420)
- Apple documents nothing about haptics inside keyboard extensions. Device test only.
- Vowel automaton source is patent KR100291839B1. [Google Patents](https://patents.google.com/patent/KR100291839B1/ko)
- Reference automaton: `docs/oracle/automaton_oracle.py`, derived from the patent vowel table and the consonant cycle rules. It is the oracle every engine test derives its expectations from.

## Engine contract

Every node programs against this surface. E1 owns the implementation. Changes to the surface go through the orchestrator.

```swift
public enum Key: CaseIterable, Sendable {
  case i, arae, eu          // vowel keys U+3163, U+318D, U+3161
  case gk, nr, dt, bp, sh, jc, om   // consonant keys in grid order
}

public struct Composition: Equatable, Sendable {
  public var committed: String   // text to insert as plain text since the last call
  public var composing: String   // text to present as marked text, empty when idle
  public init(committed: String, composing: String)
}

public struct HangulComposer: Sendable {
  public init(cycleLock: Duration)
  public var isComposing: Bool { get }
  public var composing: String { get }
  public mutating func press(_ key: Key, at instant: ContinuousClock.Instant) -> Composition
  public mutating func backspace() -> Composition?   // nil when nothing is composing
  public mutating func commit() -> Composition       // ends the composition
  public func canExtend(to text: String) -> Bool   // completion filter hook
}
```

- Rendering. Precomposed syllables, U+1100 block initial plus U+119E or U+11A2 for a pending araea, U+119E or U+11A2 alone when no initial exists, compatibility jamo for a lone jamo.
- Cycle lock applies to consonant cycling only. A press on the same consonant key after `cycleLock` starts a new jamo instead of cycling. Vowel continuation is unaffected.
- Space handling lives outside the engine. The extension calls `commit()` on the first space while composing and inserts a space on the second.
- Backspace rewinds one keystroke inside the composition. Outside a composition the extension deletes one character through the proxy.
- Every consonant key cycles with wrap: GK gives U+3131, U+314B, U+3132 and back to U+3131, and the other six keys cycle their own sets the same way.
- EU plus I gives U+3162. A double araea plus ARAE returns to a single araea.
- BP on a compound final follows the automaton, for example U+AC0B plus BP gives U+AC0E.
- The cycle lock interval is measured from the previous press of the same consonant key, so every press restarts it. A press at exactly `cycleLock` still cycles.
- `canExtend(to:)` is true when idle. Otherwise it is true when some continuation of key presses from the current state reaches a rendering that is a non-empty prefix of the text and still accounts for every current block. The single syllable form was replaced on 2026-09-20 because it rejected the word being typed whenever a consonant sat as a transient final.
- `isComposing`, `composing` and the `Composition` initializer were added to the surface through the orchestrator on 2026-09-19.

## Decisions

Defaults apply until the owner overrides them.

| Decision | Default | Blocks |
| --- | --- | --- |
| Xcode pin | 27.0 beta | P1 |
| Sound | `playInputClick()`, no in-app sound toggle | K7, H1 |
| Cycle-lock default | One second, user adjustable | K3, H1 |
| In-app shortcut list beyond Text Replacement | Not in 2.0 | K4 |
| Galaxy device for edge-case comparison | Patent plus the Samsung space-commit answer are the reference | E2 |
| App Store review export from App Store Connect | Feedback items stay as the owner described them | Q1 |

## Nodes

| ID | Depends on | Model | Owns | Deliverable | Gate |
| --- | --- | --- | --- | --- | --- |
| A1 | none | small | git | `archive/v1` at `1fe3471`, empty `main` | Done |
| A2 | A1 | small | `PLAN.md`, `docs/oracle/` | This file and the oracle on `main`, branch `rebuild` from `main` | Mechanical doc check passes |
| S1 | A2 | mid | `docs/spikes/S1.md` | Lexicon spike on the simulator. Entries with Full Access off, effect of `PrimaryLanguage ko-KR`, refresh after adding a shortcut mid-session | File has a table per question with log excerpts |
| S2 | A2 | strong | `docs/spikes/S2.md` | Marked text per host on the simulator. Messages, Notes, Safari address bar, Safari form, Mail, password field, search field. What `documentContextBeforeInput` returns while marked | Table per host with pass or fail and evidence |
| S3 | A2 | mid | `docs/spikes/S3.md` | Height constraint on iPhone and iPad, both orientations, changed at runtime | Table with screenshots |
| S4 | A2 | mid | `docs/spikes/S4.md` | `playInputClick()` path on the simulator. Haptics section left for the owner | Simulator part filled, owner part listed |
| S5 | none | owner | `docs/spikes/S5.md` | Korean `UITextChecker` completions and haptics on a physical device | Owner fills the file |
| E1 | A2 | strongest | `Packages/HangulEngine/Sources/**`, `Packages/HangulEngine/Package.swift` | Engine per contract | `swift build -c release` clean with zero warnings |
| E2 | A2 | strong | `Packages/HangulEngine/Tests/**` | Swift Testing suite written from the patent table, the cycle strings, the eleven compound pairs, final-consonant migration, backspace rewind, cycle lock | Compiles once E1 lands |
| E3 | E1, E2 | strongest | both | Every test passes. Each change to a test is justified in `docs/status/E3.md` | `swift test` green |
| E5 | E3 | strongest | `docs/status/E5.md` | Unhinted adversarial review of the engine | Findings fixed by a follow-up node or marked no change with a reason |
| P1 | A2 | mid | `*.xcodeproj`, `keyboard/Info.plist`, `keyboard/*.entitlements`, `app/Info.plist`, `app/*.entitlements`, `keyboard/KeyboardViewController.swift`, `app/App.swift` | Skeleton with app and extension targets, no engine dependency yet | Both schemes build with zero warnings, `RequestsOpenAccess` false, synchronized folders confirmed |
| W1 | P1, E3 | small | `project.pbxproj` package reference | Engine linked into the keyboard target | Keyboard builds importing `HangulEngine` |
| K1 | P1 | strong | `keyboard/Layout/**`, `keyboard/Views/**`, `keyboard/KeyboardModel.swift` | Grid, key descriptors, symbol pages, long-press digits, delete repeat, globe key, dismiss key, accessibility labels, bold text. Model shell declaring the `InsertionAdapter`, `PredictionProvider`, `SettingsReader`, `FeedbackPlayer` protocols | Builds. Screenshot matches the layout row of the fixed points table on the simulator |
| K2 | W1, S2 | strongest | `keyboard/Insertion/**` | `InsertionAdapter` on marked text. Fallback only if S2 recorded a failing host | Builds. Verifier types a sentence in Notes and Messages on the simulator with screenshots |
| K3 | W1 | mid | `keyboard/Composer/**`, `keyboard/Settings/**` | Engine driver, space and backspace policy, `SettingsReader` from the App Group read on appear and on foreground | Builds. Driver logic unit-tested in the engine package where pure |
| K4 | P1, S1 | strong | `keyboard/Predictions/Lexicon*.swift` | Lexicon `PredictionProvider`, shortcut match on the current word, expansion on space, punctuation, and tap, re-request on every appearance | Builds. Matching logic unit-tested |
| K5 | W1 | strongest | `keyboard/Predictions/Completion*.swift` | `UITextChecker` completions on the committed prefix, filtered with `canExtend(to:)` | Builds. Filter unit-tested |
| K6 | K1, K4, K5 | mid | `keyboard/Predictions/PredictionBar*.swift` | Three-slot bar, merge rules, shortcut in slot one, hidden when the setting is off | Builds. Screenshot with three candidates |
| K7 | P1, S4 | mid | `keyboard/Feedback/**` | `FeedbackPlayer` with `playInputClick()` and haptics behind the setting | Builds |
| K8 | P1, S3 | mid | `keyboard/Height*.swift` | Height constraint driven by the key-size setting | Builds. Three sizes captured on the simulator |
| H1 | P1 | mid | `app/Settings/**` | Settings screen writing the App Group. Key size, haptics, predictions, cycle-lock duration | Builds. A changed value appears in the App Group container |
| H2 | P1 | small | `app/Home/**` | Install guide, website, share, review prompt, mail, GitHub links carried over from the 1.1 container app | Builds |
| P2 | P1, K3, K6 | mid | `keyboardTests/**`, the `keyboardTests` target in `*.xcodeproj` | Unit test target for the keyboard extension, its sources reached through the synchronized root group, K3's driver tests and K6's merge tests moved in | `xcodebuild test -scheme keyboard` green |
| I1 | E5, K2, K3, K6, K7, K8, H1, H2, P2 | strong | `keyboard/KeyboardViewController.swift` | Composition root wiring every protocol. Checklist of every feature in this file | Both schemes build, all tests green, swiftformat lint clean, checklist in `docs/status/I1.md` |
| Q1 | I1 | strong | `docs/status/Q1.md` | Simulator QA matrix. iPhone and iPad, Messages, Notes, Safari, Mail, password and search fields | Matrix filled with evidence |
| Q2 | Q1, S5 | owner | `docs/status/Q2.md` | Device QA, KakaoTalk, Slack, hardware keyboard on iPad, haptics, TestFlight | Owner fills the file |
| R1 | Q2 | small | `docs/release/2.0.md` | Release note, screenshot list, App Store metadata diff | Owner submits |

## Edges

```
A1 -> A2
A2 -> S1, S2, S3, S4, E1, E2, P1
E1, E2 -> E3
E3 -> E5, W1
P1 -> W1, K1, K4, K7, K8, H1, H2
S1 -> K4
S2 -> K2
S3 -> K8
S4 -> K7
W1 -> K2, K3, K5
K1, K4, K5 -> K6
P1, K3, K6 -> P2
P2 -> I1
E5, K2, K3, K6, K7, K8, H1, H2 -> I1
I1 -> Q1
Q1, S5 -> Q2
Q2 -> R1
```

## Waves

Nodes in one wave run concurrently, one subagent each.

| Wave | Nodes |
| --- | --- |
| 0 | A2, S1, S2, S3, S4, E1, E2, P1, S5 by owner |
| 1 | E3, K1, K4, K7, K8, H1, H2 |
| 2 | W1 |
| 3 | E5, K2, K3, K5 |
| 4 | K6, P2 |
| 5 | I1 |
| 6 | Q1, then Q2 by owner, then R1 |

## Execution protocol

- Integration branch is `rebuild`, created from `main` by A2. Every node runs in its own worktree on branch `node/<id>` cut from `rebuild` at spawn time.
- One subagent per node. The subagent commits with conventional commits and never merges, pushes, rebases, or touches files outside its Owns column.
- The orchestrator runs each node's gate in the node worktree. A failing gate goes back to the same subagent with the output.
- Nodes E3, K2, K5, K6, I1 get a fresh verifier subagent after the gate passes. The verifier receives the branch and this file only. Findings land in `docs/status/<id>.md` and block the merge until resolved.
- Merges into `rebuild` are `git merge --no-ff node/<id>` by a merge subagent, serialized by the orchestrator. Conflicts are resolved by merging `rebuild` into the node branch, never by rebase.
- Each node writes `docs/status/<id>.md` with its result, commit SHA, and gate output summary before it reports.
- Spike subagents build throwaway projects outside the repository and commit only their `docs/spikes/<id>.md`. Simulator Settings changes go through XCUITest against `com.apple.Preferences`.
- Pushes to GitHub happen at wave boundaries, each with a named yes from the owner. The draft PR `rebuild` into `main` opens after the wave 1 push. The owner marks it ready after Q2.
- No `rm -rf`, no `git clean`, no force flags, no secrets in any file.

## Owner tasks

- Decisions in the table above, at any time before the blocking node starts.
- S5 on a physical device.
- Q2 on a physical device plus TestFlight.
- Named yes for each push and for the App Store submission.
- App Store Connect review export if the feedback items should be re-checked against real reviews.
