struct SymbolGlyph: Equatable, Sendable {
  let value: String
  let name: String
}

enum KeyboardLayout {
  static let symbolPages: [[SymbolGlyph]] = [
    [
      SymbolGlyph(value: "!", name: "느낌표"),
      SymbolGlyph(value: "?", name: "물음표"),
      SymbolGlyph(value: ".", name: "마침표"),
      SymbolGlyph(value: ",", name: "쉼표"),
      SymbolGlyph(value: "(", name: "여는 소괄호"),
      SymbolGlyph(value: ")", name: "닫는 소괄호"),
      SymbolGlyph(value: "@", name: "골뱅이"),
      SymbolGlyph(value: ":", name: "쌍점"),
      SymbolGlyph(value: "/", name: "빗금"),
      SymbolGlyph(value: "-", name: "붙임표"),
      SymbolGlyph(value: "★", name: "검은 별"),
      SymbolGlyph(value: "°", name: "도 기호"),
      SymbolGlyph(value: "*", name: "별표"),
      SymbolGlyph(value: "_", name: "밑줄"),
      SymbolGlyph(value: "%", name: "백분율 기호"),
      SymbolGlyph(value: "~", name: "물결표"),
      SymbolGlyph(value: "^", name: "꺾쇠"),
      SymbolGlyph(value: "#", name: "우물 정"),
    ],
    [
      SymbolGlyph(value: "$", name: "달러 기호"),
      SymbolGlyph(value: "₩", name: "원 기호"),
      SymbolGlyph(value: "€", name: "유로 기호"),
      SymbolGlyph(value: "↖", name: "왼쪽 위 화살표"),
      SymbolGlyph(value: "↑", name: "위쪽 화살표"),
      SymbolGlyph(value: "↗", name: "오른쪽 위 화살표"),
      SymbolGlyph(value: "£", name: "파운드 기호"),
      SymbolGlyph(value: "¥", name: "엔 기호"),
      SymbolGlyph(value: "=", name: "같음표"),
      SymbolGlyph(value: "←", name: "왼쪽 화살표"),
      SymbolGlyph(value: "♥", name: "하트"),
      SymbolGlyph(value: "→", name: "오른쪽 화살표"),
      SymbolGlyph(value: "+", name: "더하기표"),
      SymbolGlyph(value: "×", name: "곱하기표"),
      SymbolGlyph(value: "÷", name: "나누기표"),
      SymbolGlyph(value: "↙", name: "왼쪽 아래 화살표"),
      SymbolGlyph(value: "↓", name: "아래쪽 화살표"),
      SymbolGlyph(value: "↘", name: "오른쪽 아래 화살표"),
    ],
    [
      SymbolGlyph(value: "《", name: "여는 겹화살괄호"),
      SymbolGlyph(value: "》", name: "닫는 겹화살괄호"),
      SymbolGlyph(value: "『", name: "여는 겹낫표"),
      SymbolGlyph(value: "』", name: "닫는 겹낫표"),
      SymbolGlyph(value: "\"", name: "큰따옴표"),
      SymbolGlyph(value: "'", name: "작은따옴표"),
      SymbolGlyph(value: "`", name: "억음 부호"),
      SymbolGlyph(value: "※", name: "참고표"),
      SymbolGlyph(value: "|", name: "세로줄"),
      SymbolGlyph(value: "&", name: "앰퍼샌드"),
      SymbolGlyph(value: "\\", name: "역빗금"),
      SymbolGlyph(value: ";", name: "쌍반점"),
      SymbolGlyph(value: "<", name: "여는 홑화살괄호"),
      SymbolGlyph(value: ">", name: "닫는 홑화살괄호"),
      SymbolGlyph(value: "{", name: "여는 중괄호"),
      SymbolGlyph(value: "}", name: "닫는 중괄호"),
      SymbolGlyph(value: "[", name: "여는 대괄호"),
      SymbolGlyph(value: "]", name: "닫는 대괄호"),
    ],
  ]

  static let punctuationCycle = [".", ",", "?", "!"]

  static func rows(
    for keyboardType: KeyboardType,
    symbolPage: Int,
    showsNextKeyboardKey: Bool
  ) -> [[KeyDescriptor]] {
    switch keyboardType {
    case .hangul:
      hangulRows(showsNextKeyboardKey: showsNextKeyboardKey)
    case .number:
      numberRows(showsNextKeyboardKey: showsNextKeyboardKey)
    case .symbol:
      symbolRows(page: symbolPage, showsNextKeyboardKey: showsNextKeyboardKey)
    }
  }

  private static func hangulRows(showsNextKeyboardKey: Bool) -> [[KeyDescriptor]] {
    [
      [
        hangulKey(id: "hangul-1", label: "ㅣ", key: .i, digit: "1", accessibilityLabel: "이"),
        hangulKey(id: "hangul-2", label: "·", key: .arae, digit: "2", accessibilityLabel: "아래아"),
        hangulKey(id: "hangul-3", label: "ㅡ", key: .eu, digit: "3", accessibilityLabel: "으"),
        deleteKey(id: "hangul-delete"),
      ],
      [
        hangulKey(id: "hangul-4", label: "ㄱㅋ", key: .gk, digit: "4", accessibilityLabel: "기역 키읔"),
        hangulKey(id: "hangul-5", label: "ㄴㄹ", key: .nr, digit: "5", accessibilityLabel: "니은 리을"),
        hangulKey(id: "hangul-6", label: "ㄷㅌ", key: .dt, digit: "6", accessibilityLabel: "디귿 티읕"),
        returnKey(id: "hangul-return"),
      ],
      [
        hangulKey(id: "hangul-7", label: "ㅂㅍ", key: .bp, digit: "7", accessibilityLabel: "비읍 피읖"),
        hangulKey(id: "hangul-8", label: "ㅅㅎ", key: .sh, digit: "8", accessibilityLabel: "시옷 히읗"),
        hangulKey(id: "hangul-9", label: "ㅈㅊ", key: .jc, digit: "9", accessibilityLabel: "지읒 치읓"),
        punctuationKey(id: "hangul-punctuation"),
      ],
      bottomRow(
        leading: KeyDescriptor(
          id: "hangul-switch-number",
          label: .text("!#1"),
          style: .secondary,
          action: .switchKeyboard(.number),
          accessibilityLabel: "숫자 키보드"
        ),
        center: hangulKey(id: "hangul-0", label: "ㅇㅁ", key: .om, digit: "0", accessibilityLabel: "이응 미음"),
        idPrefix: "hangul",
        showsNextKeyboardKey: showsNextKeyboardKey
      ),
    ]
  }

  private static func numberRows(showsNextKeyboardKey: Bool) -> [[KeyDescriptor]] {
    [
      [
        digitKey(id: "number-1", digit: "1", accessibilityLabel: "일"),
        digitKey(id: "number-2", digit: "2", accessibilityLabel: "이"),
        digitKey(id: "number-3", digit: "3", accessibilityLabel: "삼"),
        deleteKey(id: "number-delete"),
      ],
      [
        digitKey(id: "number-4", digit: "4", accessibilityLabel: "사"),
        digitKey(id: "number-5", digit: "5", accessibilityLabel: "오"),
        digitKey(id: "number-6", digit: "6", accessibilityLabel: "육"),
        returnKey(id: "number-return"),
      ],
      [
        digitKey(id: "number-7", digit: "7", accessibilityLabel: "칠"),
        digitKey(id: "number-8", digit: "8", accessibilityLabel: "팔"),
        digitKey(id: "number-9", digit: "9", accessibilityLabel: "구"),
        punctuationKey(id: "number-punctuation"),
      ],
      bottomRow(
        leading: KeyDescriptor(
          id: "number-switch-symbol",
          label: .text("@#"),
          style: .secondary,
          action: .switchKeyboard(.symbol),
          accessibilityLabel: "기호 키보드"
        ),
        center: digitKey(id: "number-0", digit: "0", accessibilityLabel: "영"),
        idPrefix: "number",
        showsNextKeyboardKey: showsNextKeyboardKey
      ),
    ]
  }

  private static func symbolRows(page: Int, showsNextKeyboardKey: Bool) -> [[KeyDescriptor]] {
    let glyphs = symbolPages[page]
    return [
      symbolRow(glyphs: glyphs, row: 0, trailing: deleteKey(id: "symbol-delete")),
      symbolRow(glyphs: glyphs, row: 1, trailing: returnKey(id: "symbol-return")),
      symbolRow(glyphs: glyphs, row: 2, trailing: punctuationKey(id: "symbol-punctuation")),
      bottomRow(
        leading: KeyDescriptor(
          id: "symbol-switch-hangul",
          label: .text("한"),
          style: .secondary,
          action: .switchKeyboard(.hangul),
          accessibilityLabel: "한글 키보드"
        ),
        center: KeyDescriptor(
          id: "symbol-page",
          label: .text("\(page + 1)/\(symbolPages.count)"),
          style: .primary,
          action: .nextSymbolPage,
          accessibilityLabel: "기호 다음 쪽"
        ),
        idPrefix: "symbol",
        showsNextKeyboardKey: showsNextKeyboardKey
      ),
    ]
  }

  private static func symbolRow(
    glyphs: [SymbolGlyph],
    row: Int,
    trailing: KeyDescriptor
  ) -> [KeyDescriptor] {
    let start = row * 6
    var keys = glyphs[start ..< (start + 6)].enumerated().map { index, glyph in
      KeyDescriptor(
        id: "symbol-\(row)-\(index)",
        label: .text(glyph.value),
        style: .primary,
        action: .insert(glyph.value),
        accessibilityLabel: glyph.name
      )
    }
    keys.append(trailing)
    return keys
  }

  private static func bottomRow(
    leading: KeyDescriptor,
    center: KeyDescriptor,
    idPrefix: String,
    showsNextKeyboardKey: Bool
  ) -> [KeyDescriptor] {
    var keys = [leading]
    if showsNextKeyboardKey {
      keys.append(
        KeyDescriptor(
          id: "next-keyboard",
          label: .nextKeyboard,
          style: .secondary,
          action: nil,
          accessibilityLabel: "다음 키보드"
        )
      )
    }
    keys.append(center)
    keys.append(
      KeyDescriptor(
        id: "\(idPrefix)-space",
        label: .symbol("space"),
        style: .secondary,
        action: .space,
        accessibilityLabel: "띄어쓰기"
      )
    )
    keys.append(
      KeyDescriptor(
        id: "\(idPrefix)-dismiss",
        label: .symbol("keyboard.chevron.compact.down.fill"),
        style: .secondary,
        action: .dismiss,
        accessibilityLabel: "키보드 내리기"
      )
    )
    return keys
  }

  private static func hangulKey(
    id: String,
    label: String,
    key: HangulKey,
    digit: String,
    accessibilityLabel: String
  ) -> KeyDescriptor {
    KeyDescriptor(
      id: id,
      label: .text(label),
      style: .primary,
      action: .hangul(key),
      longPressAction: .insert(digit),
      accessibilityLabel: accessibilityLabel
    )
  }

  private static func digitKey(id: String, digit: String, accessibilityLabel: String) -> KeyDescriptor {
    KeyDescriptor(
      id: id,
      label: .text(digit),
      style: .primary,
      action: .insert(digit),
      accessibilityLabel: accessibilityLabel
    )
  }

  private static func deleteKey(id: String) -> KeyDescriptor {
    KeyDescriptor(
      id: id,
      label: .symbol("delete.left.fill"),
      style: .secondary,
      action: .delete,
      accessibilityLabel: "지우기"
    )
  }

  private static func returnKey(id: String) -> KeyDescriptor {
    KeyDescriptor(
      id: id,
      label: .symbol("return"),
      style: .secondary,
      action: .returnKey,
      accessibilityLabel: "줄 바꿈"
    )
  }

  private static func punctuationKey(id: String) -> KeyDescriptor {
    KeyDescriptor(
      id: id,
      label: .text(".,?!"),
      style: .secondary,
      action: .cycle(punctuationCycle),
      accessibilityLabel: "문장 부호"
    )
  }
}
