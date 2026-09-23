import Foundation

struct Block: Hashable, Sendable {
  var initial: Int?
  var vowel: Int?
  var final: Int?
}

struct VowelState: Sendable {
  let emit: Unicode.Scalar
  let next: [Key: Int]
}

enum Automaton {
  static let initials: [Unicode.Scalar] = Array("ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ".unicodeScalars)
  static let medials: [Unicode.Scalar] = Array("ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ".unicodeScalars)
  static let finals: [Unicode.Scalar?] = [nil] + Array("ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ".unicodeScalars)

  static let compound: [Unicode.Scalar: [Unicode.Scalar: Unicode.Scalar]] = [
    "ㄱ": ["ㅅ": "ㄳ"],
    "ㄴ": ["ㅈ": "ㄵ", "ㅎ": "ㄶ"],
    "ㄹ": ["ㄱ": "ㄺ", "ㅁ": "ㄻ", "ㅂ": "ㄼ", "ㅅ": "ㄽ", "ㅌ": "ㄾ", "ㅍ": "ㄿ", "ㅎ": "ㅀ"],
    "ㅂ": ["ㅅ": "ㅄ"],
  ]

  static let split: [Unicode.Scalar: (first: Unicode.Scalar, second: Unicode.Scalar)] = [
    "ㄳ": ("ㄱ", "ㅅ"), "ㄵ": ("ㄴ", "ㅈ"), "ㄶ": ("ㄴ", "ㅎ"), "ㄺ": ("ㄹ", "ㄱ"), "ㄻ": ("ㄹ", "ㅁ"),
    "ㄼ": ("ㄹ", "ㅂ"), "ㄽ": ("ㄹ", "ㅅ"), "ㄾ": ("ㄹ", "ㅌ"), "ㄿ": ("ㄹ", "ㅍ"), "ㅀ": ("ㄹ", "ㅎ"),
    "ㅄ": ("ㅂ", "ㅅ"),
  ]

  static let cycles: [Key: [Unicode.Scalar]] = [
    .gk: ["ㄱ", "ㅋ", "ㄲ"], .nr: ["ㄴ", "ㄹ"], .dt: ["ㄷ", "ㅌ", "ㄸ"], .bp: ["ㅂ", "ㅍ", "ㅃ"],
    .sh: ["ㅅ", "ㅎ", "ㅆ"], .jc: ["ㅈ", "ㅊ", "ㅉ"], .om: ["ㅇ", "ㅁ"],
  ]

  static let araea: Unicode.Scalar = "\u{119E}"
  static let doubleAraea: Unicode.Scalar = "\u{11A2}"
  static let pending: Set<Int> = [1, 2]

  static let start: [Key: Int] = [.arae: 1, .eu: 12, .i: 18]

  static let fst: [Int: VowelState] = [
    1: VowelState(emit: araea, next: [.arae: 2, .eu: 6, .i: 10]),
    2: VowelState(emit: doubleAraea, next: [.arae: 1, .eu: 3, .i: 4]),
    3: VowelState(emit: "ㅛ", next: [:]),
    4: VowelState(emit: "ㅕ", next: [.i: 5]),
    5: VowelState(emit: "ㅖ", next: [:]),
    6: VowelState(emit: "ㅗ", next: [.i: 7]),
    7: VowelState(emit: "ㅚ", next: [.arae: 8]),
    8: VowelState(emit: "ㅘ", next: [.i: 9]),
    9: VowelState(emit: "ㅙ", next: [:]),
    10: VowelState(emit: "ㅓ", next: [.i: 11]),
    11: VowelState(emit: "ㅔ", next: [:]),
    12: VowelState(emit: "ㅡ", next: [.arae: 13, .i: 20]),
    13: VowelState(emit: "ㅜ", next: [.arae: 14, .i: 16]),
    14: VowelState(emit: "ㅠ", next: [.arae: 13, .i: 15]),
    15: VowelState(emit: "ㅝ", next: [.i: 21]),
    16: VowelState(emit: "ㅟ", next: [:]),
    18: VowelState(emit: "ㅣ", next: [.arae: 19]),
    19: VowelState(emit: "ㅏ", next: [.arae: 22, .i: 23]),
    20: VowelState(emit: "ㅢ", next: [:]),
    21: VowelState(emit: "ㅞ", next: [:]),
    22: VowelState(emit: "ㅑ", next: [.i: 24]),
    23: VowelState(emit: "ㅐ", next: [:]),
    24: VowelState(emit: "ㅒ", next: [:]),
  ]

  static func isComplete(_ vowel: Int?) -> Bool {
    guard let vowel else { return false }
    return !pending.contains(vowel)
  }

  static func render(_ blocks: [Block]) -> String {
    var out = ""
    for block in blocks {
      switch (block.initial, block.vowel) {
      case let (initial?, nil):
        out.unicodeScalars.append(initials[initial])
      case let (nil, vowel?):
        out.unicodeScalars.append(fst[vowel]!.emit)
      case let (initial?, vowel?) where !isComplete(vowel):
        out.unicodeScalars.append(Unicode.Scalar(0x1100 + initial)!)
        out.unicodeScalars.append(fst[vowel]!.emit)
      case let (initial?, vowel?):
        let medial = medials.firstIndex(of: fst[vowel]!.emit)!
        out.unicodeScalars.append(Unicode.Scalar(0xAC00 + (initial * 21 + medial) * 28 + (block.final ?? 0))!)
      case (nil, nil):
        preconditionFailure("block without initial or vowel")
      }
    }
    return out
  }

  static func press(_ blocks: inout [Block], _ key: Key, cycling: Bool) {
    if let cycle = cycles[key] {
      pressConsonant(&blocks, cycle, cycling: cycling)
    } else {
      pressVowel(&blocks, key)
    }
  }

  static func pressVowel(_ blocks: inout [Block], _ key: Key) {
    let fresh = start[key]!
    guard let index = blocks.indices.last else {
      blocks.append(Block(initial: nil, vowel: fresh, final: nil))
      return
    }
    let last = blocks[index]
    if let final = last.final {
      let coda = finals[final]!
      if let pair = split[coda] {
        blocks[index].final = finals.firstIndex(of: pair.first)!
        blocks.append(Block(initial: initials.firstIndex(of: pair.second)!, vowel: fresh, final: nil))
      } else {
        blocks[index].final = nil
        blocks.append(Block(initial: initials.firstIndex(of: coda)!, vowel: fresh, final: nil))
      }
      return
    }
    guard let vowel = last.vowel else {
      blocks[index].vowel = fresh
      return
    }
    if let next = fst[vowel]!.next[key] {
      blocks[index].vowel = next
    } else {
      blocks.append(Block(initial: nil, vowel: fresh, final: nil))
    }
  }

  static func pressConsonant(_ blocks: inout [Block], _ cycle: [Unicode.Scalar], cycling: Bool) {
    let fresh = Block(initial: initials.firstIndex(of: cycle[0])!, vowel: nil, final: nil)
    guard let index = blocks.indices.last else {
      blocks.append(fresh)
      return
    }
    let last = blocks[index]
    if let initial = last.initial, last.vowel == nil {
      guard cycling, let position = cycle.firstIndex(of: initials[initial]) else {
        blocks.append(fresh)
        return
      }
      let new = cycle[(position + 1) % cycle.count]
      blocks[index].initial = initials.firstIndex(of: new)!
      guard index >= 1 else { return }
      let previous = blocks[index - 1]
      guard previous.initial != nil, isComplete(previous.vowel) else { return }
      if previous.final == nil, let code = finals.firstIndex(of: new) {
        blocks[index - 1].final = code
        blocks.removeLast()
      } else if let final = previous.final, let joined = compound[finals[final]!]?[new] {
        blocks[index - 1].final = finals.firstIndex(of: joined)!
        blocks.removeLast()
      }
      return
    }
    guard last.initial != nil, isComplete(last.vowel) else {
      blocks.append(fresh)
      return
    }
    guard let final = last.final else {
      blocks[index].final = finals.firstIndex(of: cycle[0])!
      return
    }
    let coda = finals[final]!
    if let pair = split[coda] {
      guard cycling, let position = cycle.firstIndex(of: pair.second) else {
        blocks.append(fresh)
        return
      }
      let new = cycle[(position + 1) % cycle.count]
      if let joined = compound[pair.first]?[new] {
        blocks[index].final = finals.firstIndex(of: joined)!
      } else {
        blocks[index].final = finals.firstIndex(of: pair.first)!
        blocks.append(Block(initial: initials.firstIndex(of: new)!, vowel: nil, final: nil))
      }
      return
    }
    if cycling, let position = cycle.firstIndex(of: coda) {
      let new = cycle[(position + 1) % cycle.count]
      if let code = finals.firstIndex(of: new) {
        blocks[index].final = code
      } else {
        blocks[index].final = nil
        blocks.append(Block(initial: initials.firstIndex(of: new)!, vowel: nil, final: nil))
      }
      return
    }
    if let joined = compound[coda]?[cycle[0]] {
      blocks[index].final = finals.firstIndex(of: joined)!
      return
    }
    blocks.append(fresh)
  }
}

extension Automaton {
  static let keyOf: [Unicode.Scalar: Key] = Dictionary(
    uniqueKeysWithValues: cycles.flatMap { key, jamo in jamo.map { ($0, key) } }
  )

  static let vowelOf: [Unicode.Scalar: Int] = Dictionary(uniqueKeysWithValues: fst.map { ($0.value.emit, $0.key) })

  static let presses: [(key: Key, cycling: Bool)] = Key.allCases.flatMap { key in
    cycles[key] == nil ? [(key, false)] : [(key, true), (key, false)]
  }

  static let onward: [Int: Set<Int>] = {
    var closure = Dictionary(uniqueKeysWithValues: fst.keys.map { ($0, Set([$0])) })
    var grew = true
    while grew {
      grew = false
      for (state, seen) in closure {
        let wider = seen.union(seen.flatMap { fst[$0]!.next.values })
        if wider.count > seen.count {
          closure[state] = wider
          grew = true
        }
      }
    }
    return closure
  }()

  static func sameKey(_ one: Unicode.Scalar, _ other: Unicode.Scalar) -> Bool {
    keyOf[one] == keyOf[other]
  }

  /// The blocks whose rendering is the longest readable prefix of the scalars. Rendering is one to one,
  /// so a rendering is a prefix of the text exactly when its blocks are a prefix of these.
  static func parse(_ scalars: String.UnicodeScalarView, limit: Int) -> [Block] {
    var blocks: [Block] = []
    var lead: Int?
    for scalar in scalars {
      guard blocks.count < limit else { break }
      if let initial = lead {
        guard let vowel = vowelOf[scalar], pending.contains(vowel) else { return blocks }
        blocks.append(Block(initial: initial, vowel: vowel, final: nil))
        lead = nil
      } else if (0xAC00 ... 0xD7A3).contains(scalar.value) {
        let index = Int(scalar.value - 0xAC00)
        let final = index % 28
        blocks.append(Block(initial: index / 588, vowel: vowelOf[medials[index % 588 / 28]]!, final: final == 0 ? nil : final))
      } else if (0x1100 ... 0x1112).contains(scalar.value) {
        lead = Int(scalar.value - 0x1100)
      } else if let initial = initials.firstIndex(of: scalar) {
        blocks.append(Block(initial: initial, vowel: nil, final: nil))
      } else if let vowel = vowelOf[scalar] {
        blocks.append(Block(initial: nil, vowel: vowel, final: nil))
      } else {
        return blocks
      }
    }
    return blocks
  }

  /// Whether the final of a syllable can still end as the wanted one. A final changes by cycling on its
  /// own key, by growing into a compound, by a lone consonant behind it folding in, and by leaving: a
  /// vowel moves a simple final or the second half of a compound into the next block, and a cycle step
  /// onto a jamo that is no final detaches it. What leaves becomes the initial of the next block, so it
  /// must share a key with the initial the target has there. `trailing` is a lone consonant right
  /// behind the syllable. Every rule errs toward true, the search decides.
  static func finalSettles(
    _ held: Unicode.Scalar?,
    trailing: Unicode.Scalar?,
    as wanted: Unicode.Scalar?,
    leaving: Unicode.Scalar?
  ) -> Bool {
    let departs = { (jamo: Unicode.Scalar) in leaving.map { sameKey($0, jamo) } ?? false }
    let heldPair = held.flatMap { split[$0] }
    let wantedPair = wanted.flatMap { split[$0] }
    if let trailing {
      guard let held else {
        return (wantedPair?.first ?? wanted).map { sameKey($0, trailing) } ?? departs(trailing)
      }
      if heldPair == nil, let wantedPair, wantedPair.first == held, sameKey(wantedPair.second, trailing) {
        return true
      }
      return held == wanted && departs(trailing)
    }
    guard let held, held != wanted else { return true }
    switch (heldPair, wantedPair) {
    case let (nil, wantedPair?):
      return sameKey(held, wantedPair.first)
    case (nil, nil):
      return wanted.map { sameKey($0, held) } ?? departs(held)
    case let (heldPair?, nil):
      return heldPair.first == wanted && departs(heldPair.second)
    case let (heldPair?, wantedPair?):
      return heldPair.first == wantedPair.first && sameKey(heldPair.second, wantedPair.second)
    }
  }

  /// Whether the state can still become a prefix of the target. Blocks before the last two never change.
  /// The block before the last changes only when the last is a lone consonant that folds into it. A
  /// block keeps its initial once it has a vowel, its vowel only moves along the automaton, and no
  /// vowel moves once a final sits behind it. One block past the target is allowed only for a lone
  /// consonant that can still fold back.
  static func viable(_ state: [Block], toward target: [Block]) -> Bool {
    let last = state.count - 1
    guard last <= target.count else { return false }
    let tail = state[last]
    var settled = last
    if tail.vowel == nil, last >= 1, state[last - 1].initial != nil, isComplete(state[last - 1].vowel) {
      let host = state[last - 1]
      let want = target[last - 1]
      guard host.initial == want.initial, host.vowel == want.vowel, finalSettles(
        host.final.map { finals[$0]! },
        trailing: initials[tail.initial!],
        as: want.final.map { finals[$0]! },
        leaving: last < target.count ? target[last].initial.map { initials[$0] } : nil
      ) else { return false }
      settled = last - 1
    } else {
      guard last < target.count else { return false }
      let want = target[last]
      guard let vowel = tail.vowel else {
        guard let initial = want.initial, sameKey(initials[initial], initials[tail.initial!]) else { return false }
        return state.prefix(settled).elementsEqual(target.prefix(settled))
      }
      guard tail.initial == want.initial, let wantVowel = want.vowel else { return false }
      if let final = tail.final {
        guard vowel == wantVowel, finalSettles(
          finals[final]!,
          trailing: nil,
          as: want.final.map { finals[$0]! },
          leaving: last + 1 < target.count ? target[last + 1].initial.map { initials[$0] } : nil
        ) else { return false }
      } else {
        guard onward[vowel]!.contains(wantVowel) else { return false }
      }
    }
    return state.prefix(settled).elementsEqual(target.prefix(settled))
  }

  /// The head of the text the parse can read, precomposed. A candidate that is canonically equal to a
  /// reachable rendering must be accepted, and the renderings compared are precomposed, so the text is
  /// normalized before it is read. Only the head is normalized, because normalizing the whole of a
  /// candidate would put the call back to a cost linear in the candidate's length. The parse reads at
  /// most two scalars per block and stops at one block past `blocks`, and a canonical decomposition of a
  /// syllable is three scalars, so three scalars per block plus three cover every block it can reach.
  static func precomposedHead(_ text: String, blocks: Int) -> String {
    String(String.UnicodeScalarView(text.unicodeScalars.prefix(3 * blocks + 6)))
      .precomposedStringWithCanonicalMapping
  }

  /// Whether some run of presses, each inside or outside the cycle lock, the empty run included, leaves a
  /// rendering that is a non-empty prefix of the text. The search is directed by the text: a state is
  /// kept only while `viable` holds. If any such rendering exists, one exists with at most one block
  /// more than the blocks have now, because a block past that is only ever created behind a block that
  /// already rendered its part of the text. So the target is cut there, and the search runs on the last
  /// two blocks plus the one that may follow.
  static func extends(_ blocks: [Block], to text: String) -> Bool {
    let goal = parse(precomposedHead(text, blocks: blocks.count).unicodeScalars, limit: blocks.count + 1)
    let base = max(blocks.count - 2, 0)
    guard goal.count >= base, goal.prefix(base).elementsEqual(blocks.prefix(base)) else { return false }
    let target = Array(goal[base...])
    let start = Array(blocks[base...])
    guard viable(start, toward: target) else { return false }
    var seen: Set<[Block]> = [start]
    var frontier = [start]
    while let state = frontier.popLast() {
      if state.count <= target.count, state.elementsEqual(target.prefix(state.count)) {
        return true
      }
      for (key, cycling) in presses {
        var next = state
        press(&next, key, cycling: cycling)
        if viable(next, toward: target), seen.insert(next).inserted {
          frontier.append(next)
        }
      }
    }
    return false
  }
}
