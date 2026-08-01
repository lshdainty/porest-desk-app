#!/usr/bin/env python3
"""lucide_icons_flutter 패키지에서 아이콘 매핑·이름 목록을 재생성한다.

생성물:
  lib/shared/icons/lucide_icon_map.dart   — 정규화 키 → IconData (lucideByName lookup)
  lib/shared/icons/lucide_icon_names.dart — kebab 이름 목록 (PIconPicker 소스)

패키지를 올릴 때마다 실행:  python3 tool/gen_lucide_icons.py
(경로는 pubspec.lock 의 lucide_icons_flutter 버전으로 자동 탐색)
"""
import re, sys, glob, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent

def pkg_version() -> str:
    lock = (ROOT / 'pubspec.lock').read_text(encoding='utf-8')
    m = re.search(r'^  lucide_icons_flutter:.*?^    version: "([^"]+)"', lock, re.S | re.M)
    if not m:
        sys.exit('pubspec.lock 에서 lucide_icons_flutter 버전을 찾지 못했습니다.')
    return m.group(1)

def pkg_dir(ver: str) -> pathlib.Path:
    cands = glob.glob(str(pathlib.Path.home() / f'.pub-cache/hosted/*/lucide_icons_flutter-{ver}'))
    if not cands:
        sys.exit(f'pub-cache 에 lucide_icons_flutter-{ver} 가 없습니다. flutter pub get 후 재시도.')
    return pathlib.Path(cands[0])

# 굵기(100~900)·dir 변형은 제외 — 웹(lucide-react)엔 없는 변형이라 매핑 대상이 아니다.
VARIANT = re.compile(r'((100|200|300|400|500|600|700|800|900)(Dir)?|Dir)$')
def is_base(ident: str) -> bool:
    return not VARIANT.search(ident)

def to_kebab(ident: str) -> str:
    s = re.sub(r'([a-z0-9])([A-Z])', r'\1-\2', ident)
    s = re.sub(r'([A-Za-z])([0-9])', r'\1-\2', s)
    return s.lower()

def normalize(s: str) -> str:
    return re.sub(r'[-_\s]', '', s.lower())

def main() -> None:
    ver = pkg_version()
    src = pkg_dir(ver)
    idents = set()
    for f in glob.glob(str(src / 'lib/**/*.dart'), recursive=True):
        if f.endswith('test_icons.dart'):
            continue
        idents |= set(re.findall(r'static const IconData ([A-Za-z0-9_]+)', pathlib.Path(f).read_text(encoding='utf-8', errors='ignore')))
    base = sorted(i for i in idents if is_base(i))

    # 정규화 키 충돌 시 먼저 온 식별자 유지(정렬 순) — 실제 충돌은 없어야 정상
    by_key: dict[str, str] = {}
    for ident in base:
        by_key.setdefault(normalize(ident), ident)

    entries = ''.join(f"  '{k}': LucideIcons.{v},\n" for k, v in sorted(by_key.items()))
    (ROOT / 'lib/shared/icons/lucide_icon_map.dart').write_text(f"""// ⚠️ 생성 파일 — tool/gen_lucide_icons.py 로 재생성(수작업 편집 금지).
// 원본: lucide_icons_flutter {ver} 의 static const IconData 전체(굵기·dir 변형 제외).
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 백엔드 카테고리/자산 `icon` 컬럼 (lucide-react kebab 이름) → Flutter `IconData`.
///
/// `_normalize` 가 소문자화 + `-_` 제거로 kebab(`building-2`)을 식별자 표기
/// (`building2`)로 맞춰 lookup. `_byName` 은 패키지 전체에서 생성돼 웹 DynamicIcon 과
/// 동일 universe — 카테고리가 어떤 lucide 아이콘을 써도 fallback(tag)로 새지 않는다.
IconData lucideByName(String? name, {{IconData fallback = LucideIcons.tag}}) {{
  if (name == null || name.isEmpty) return fallback;
  return _byName[_normalize(name)] ?? fallback;
}}

String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[-_\\s]'), '');

final Map<String, IconData> _byName = {{
{entries}}};
""", encoding='utf-8')

    names = sorted(to_kebab(v) for v in by_key.values())
    lines = ''.join(f"  '{n}',\n" for n in names)
    (ROOT / 'lib/shared/icons/lucide_icon_names.dart').write_text(f"""// ⚠️ 생성 파일 — tool/gen_lucide_icons.py 로 재생성(수작업 편집 금지).
// 원본: lucide_icons_flutter {ver} (굵기·dir 변형 제외).

/// 전체 아이콘의 lucide-react kebab 이름 — PIconPicker 검색·그리드 소스.
/// `lucideByName` 이 같은 universe 를 그리므로 목록의 모든 이름이 렌더 가능하다.
const List<String> kLucideIconNames = [
{lines}];
""", encoding='utf-8')

    print(f'lucide_icons_flutter {ver} → {len(by_key)} icons')

if __name__ == '__main__':
    main()
