"""Reference 천지인 automaton, replayed against keyboard/한글.min.json as an oracle.

State = list of blocks. Block = [cho_idx|None, vowel_fst_state|None, jong_idx|None].
Rendering follows the JSON's conventions (compat jamo for lone jamo, U+1100 choseong + U+119E/U+11A2
for pending araea, precomposed syllables otherwise).
"""
import json, sys, collections

CHO = "ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ"
JUNG = "ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ"
JONG = [None] + list("ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ")
COMPOUND = {("ㄱ", "ㅅ"): "ㄳ", ("ㄴ", "ㅈ"): "ㄵ", ("ㄴ", "ㅎ"): "ㄶ", ("ㄹ", "ㄱ"): "ㄺ", ("ㄹ", "ㅁ"): "ㄻ",
            ("ㄹ", "ㅂ"): "ㄼ", ("ㄹ", "ㅅ"): "ㄽ", ("ㄹ", "ㅌ"): "ㄾ", ("ㄹ", "ㅍ"): "ㄿ", ("ㄹ", "ㅎ"): "ㅀ", ("ㅂ", "ㅅ"): "ㅄ"}
SPLIT = {v: k for k, v in COMPOUND.items()}

CYCLES = {"ㄱㅋ": "ㄱㅋㄲ", "ㄴㄹ": "ㄴㄹ", "ㄷㅌ": "ㄷㅌㄸ", "ㅂㅍ": "ㅂㅍㅃ", "ㅅㅎ": "ㅅㅎㅆ", "ㅈㅊ": "ㅈㅊㅉ", "ㅇㅁ": "ㅇㅁ"}
VKEY = {"천": "·", "지": "ㅡ", "인": "ㅣ"}

# Vowel FST from patent KR100291839B1 fig. 6a/6b. state -> (emit, {key: next})
ARAE, SSANG = "ᆞ", "ᆢ"
FST = {
    0: (None, {"·": 1, "ㅡ": 12, "ㅣ": 18}),
    1: (ARAE, {"·": 2, "ㅡ": 6, "ㅣ": 10}),
    2: (SSANG, {"·": 1, "ㅡ": 3, "ㅣ": 4}),
    3: ("ㅛ", {}), 4: ("ㅕ", {"ㅣ": 5}), 5: ("ㅖ", {}),
    6: ("ㅗ", {"ㅣ": 7}), 7: ("ㅚ", {"·": 8}), 8: ("ㅘ", {"ㅣ": 9}), 9: ("ㅙ", {}),
    10: ("ㅓ", {"ㅣ": 11}), 11: ("ㅔ", {}),
    12: ("ㅡ", {"·": 13, "ㅣ": 20}), 13: ("ㅜ", {"·": 14, "ㅣ": 16}), 14: ("ㅠ", {"·": 13, "ㅣ": 15}),
    15: ("ㅝ", {"ㅣ": 21}), 16: ("ㅟ", {}), 20: ("ㅢ", {}), 21: ("ㅞ", {}),
    18: ("ㅣ", {"·": 19}), 19: ("ㅏ", {"·": 22, "ㅣ": 23}), 22: ("ㅑ", {"ㅣ": 24}), 24: ("ㅒ", {}), 23: ("ㅐ", {}),
}
STATE_OF_VOWEL = {emit: s for s, (emit, _) in FST.items() if emit and emit not in (ARAE, SSANG)}
PENDING = {ARAE: 1, SSANG: 2}


def is_complete(vs):
    return vs is not None and FST[vs][0] not in (ARAE, SSANG)


def jong_idx(ch):
    return JONG.index(ch) if ch in JONG else None


def render(blocks):
    out = []
    for cho, vs, jong in blocks:
        if cho is not None and vs is None:
            out.append(CHO[cho])
        elif cho is None and vs is not None:
            out.append(FST[vs][0])
        elif not is_complete(vs):
            out.append(chr(0x1100 + cho) + FST[vs][0])
        else:
            j = JUNG.index(FST[vs][0])
            out.append(chr(0xAC00 + (cho * 21 + j) * 28 + (jong or 0)))
    return "".join(out)


def parse(s):
    blocks, i = [], 0
    while i < len(s):
        ch = s[i]
        cp = ord(ch)
        if 0xAC00 <= cp <= 0xD7A3:
            n = cp - 0xAC00
            blocks.append([n // 588, STATE_OF_VOWEL[JUNG[(n % 588) // 28]], n % 28 or None])
        elif ch in CHO:
            blocks.append([CHO.index(ch), None, None])
        elif ch in STATE_OF_VOWEL:
            blocks.append([None, STATE_OF_VOWEL[ch], None])
        elif ch in PENDING:
            blocks.append([None, PENDING[ch], None])
        elif 0x1100 <= cp <= 0x1112 and i + 1 < len(s) and s[i + 1] in PENDING:
            blocks.append([cp - 0x1100, PENDING[s[i + 1]], None])
            i += 1
        else:
            return None
        i += 1
    return blocks


def press_vowel(blocks, v):
    if not blocks:
        return [[None, FST[0][1][v], None]]
    cho, vs, jong = blocks[-1]
    if jong is not None:
        jch = JONG[jong]
        if jch in SPLIT:
            a, b = SPLIT[jch]
            blocks[-1][2] = jong_idx(a)
            blocks.append([CHO.index(b), FST[0][1][v], None])
        else:
            blocks[-1][2] = None
            blocks.append([CHO.index(jch), FST[0][1][v], None])
        return blocks
    if vs is None:
        blocks[-1][1] = FST[0][1][v]
        return blocks
    nxt = FST[vs][1].get(v)
    if nxt is None:
        blocks.append([None, FST[0][1][v], None])
    else:
        blocks[-1][1] = nxt
    return blocks


def cycle(cyc, ch):
    return cyc[(cyc.index(ch) + 1) % len(cyc)]


def press_consonant(blocks, cyc):
    first = CHO.index(cyc[0])
    if not blocks:
        return [[first, None, None]]
    cho, vs, jong = blocks[-1]
    if vs is None and cho is not None:
        if CHO[cho] in cyc:
            new = cycle(cyc, CHO[cho])
            blocks[-1][0] = CHO.index(new)
            if len(blocks) >= 2:
                pcho, pvs, pjong = blocks[-2]
                if pcho is not None and is_complete(pvs):
                    if pjong is None and jong_idx(new) is not None:
                        blocks[-2][2] = jong_idx(new)
                        blocks.pop()
                    elif pjong is not None and (JONG[pjong], new) in COMPOUND:
                        blocks[-2][2] = jong_idx(COMPOUND[(JONG[pjong], new)])
                        blocks.pop()
            return blocks
        blocks.append([first, None, None])
        return blocks
    if cho is None or not is_complete(vs):
        blocks.append([first, None, None])
        return blocks
    if jong is None:
        blocks[-1][2] = jong_idx(cyc[0])
        return blocks
    jch = JONG[jong]
    if jch in SPLIT:
        a, b = SPLIT[jch]
        if b in cyc:
            nb = cycle(cyc, b)
            if (a, nb) in COMPOUND:
                blocks[-1][2] = jong_idx(COMPOUND[(a, nb)])
            else:
                blocks[-1][2] = jong_idx(a)
                blocks.append([CHO.index(nb), None, None])
            return blocks
        blocks.append([first, None, None])
        return blocks
    if jch in cyc:
        nj = cycle(cyc, jch)
        if jong_idx(nj) is not None:
            blocks[-1][2] = jong_idx(nj)
        else:
            blocks[-1][2] = None
            blocks.append([CHO.index(nj), None, None])
        return blocks
    if (jch, cyc[0]) in COMPOUND:
        blocks[-1][2] = jong_idx(COMPOUND[(jch, cyc[0])])
        return blocks
    blocks.append([first, None, None])
    return blocks


def automaton(s, key):
    blocks = parse(s)
    if blocks is None:
        return None
    if key in VKEY:
        return render(press_vowel(blocks, VKEY[key]))
    return render(press_consonant(blocks, CYCLES[key]))


def engine(s, key, maps, fallback):
    """Mirror of KeyboardInputEngine.insertHangul lookup order on a rendered state string."""
    m = maps[key]
    if len(s) > 1 and s[-2:] in m:
        return s[:-2] + m[s[-2:]]
    if s and s[-1:] in m:
        return s[:-1] + m[s[-1:]]
    if s == "" and "" in m:
        return m[""]
    return s + fallback[key]


def main():
    maps = json.load(open(sys.argv[1], encoding="utf-8"))
    fallback = {"ㄱㅋ": "ㄱ", "ㄴㄹ": "ㄴ", "ㄷㅌ": "ㄷ", "ㅂㅍ": "ㅂ", "ㅅㅎ": "ㅅ", "ㅈㅊ": "ㅈ", "ㅇㅁ": "ㅇ",
                "인": "ㅣ", "천": ARAE, "지": "ㅡ"}
    universe = set()
    for m in maps.values():
        universe.update(m.keys())
        universe.update(m.values())
    universe.discard("")
    unparsable = sorted(s for s in universe if parse(s) is None)
    total = match = 0
    mism = collections.defaultdict(list)
    entry_total = entry_match = 0
    entry_mism = collections.defaultdict(list)
    for key in maps:
        for s in sorted(universe):
            if parse(s) is None:
                continue
            e = engine(s, key, maps, fallback)
            a = automaton(s, key)
            total += 1
            in_map = (len(s) > 1 and s[-2:] in maps[key]) or (s[-1:] in maps[key])
            if e == a:
                match += 1
                if in_map:
                    entry_match += 1
            else:
                mism[key].append((s, e, a, in_map))
            if in_map:
                entry_total += 1
    print(f"universe states: {len(universe)}  unparsable: {len(unparsable)} {unparsable[:10]}")
    print(f"all (state,key) pairs: {total}  agree: {match}  disagree: {total - match}")
    print(f"pairs covered by a JSON entry: {entry_total}  agree: {entry_match}  disagree: {entry_total - entry_match}")
    for key, items in mism.items():
        print(f"\n== {key}: {len(items)} disagreements ({sum(1 for i in items if i[3])} inside JSON entries)")
        for s, e, a, in_map in items[:8]:
            print(f"   {s!r} -> json/engine {e!r} | automaton {a!r} {'(entry)' if in_map else '(fallback)'}")


if __name__ == "__main__":
    main()
