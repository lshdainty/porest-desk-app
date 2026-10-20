import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/shared/ds/icon_picker/category_icons.g.dart';
import 'package:groo_damda_app/shared/icons/lucide_icon_map.dart';

/// 카테고리 아이콘 한 줄(category-icons.yaml 의 entries). 이름은 한국어 하나 — 칸의 이름(보조 기술 · 툴팁)과 트리거의 값
/// 글이다. 영어 lucide 이름([id])은 저장 값일 뿐 화면에 내지 않는다.
@immutable
class PCategoryIcon {
  const PCategoryIcon({
    required this.id,
    required this.group,
    required this.name,
    required this.aliases,
    this.lucideAliases = const [],
  });

  /// 스펙 JSON 의 한 줄(`data.entries[i]`)에서 읽는다.
  factory PCategoryIcon.fromJson(Map<String, dynamic> json) => PCategoryIcon(
    id: json['id'] as String,
    group: json['group'] as String,
    name: json['name'] as String,
    aliases: ((json['aliases'] as List?) ?? const []).cast<String>(),
    lucideAliases: ((json['lucideAliases'] as List?) ?? const [])
        .cast<String>(),
  );

  /// lucide 이름(kebab) — 저장 값.
  final String id;

  /// 묶음 — "식비" · "카페" …
  final String group;

  /// 한국어 이름 — 세트 안에서 겹치지 않는다.
  final String name;

  /// 찾는 말 — 이름 말고 이 아이콘으로 찾을 말("월세" → 집).
  final List<String> aliases;

  /// 같은 아이콘의 다른 lucide 이름(옛 이름) — 저장 값이 이 이름이어도 이 아이콘을 고른 것으로 본다(서버 시드의 home).
  final List<String> lucideAliases;
}

/// 묶음 하나 — 묶음 차례 · 표 차례 그대로.
@immutable
class PCategoryIconSection {
  const PCategoryIconSection(this.group, this.icons);

  final String group;
  final List<PCategoryIcon> icons;
}

final Map<String, dynamic> _data =
    kCategoryIconsSpec['data'] as Map<String, dynamic>;

/// 기본 아이콘(태그) — 아이콘이 없는 항목 · 새 카테고리의 처음 값.
final String kDefaultCategoryIcon = _data['default'] as String;

/// 묶음 차례.
final List<String> kCategoryIconGroups = (_data['groups'] as List)
    .cast<String>();

/// 세트 — 표 차례 그대로(148개).
final List<PCategoryIcon> kCategoryIcons = [
  for (final e in (_data['entries'] as List))
    PCategoryIcon.fromJson(e as Map<String, dynamic>),
];

/// 묶음마다 아이콘 — 아이콘이 없는 묶음은 두지 않는다.
final List<PCategoryIconSection> kCategoryIconSections = [
  for (final group in kCategoryIconGroups)
    if (kCategoryIcons.any((i) => i.group == group))
      PCategoryIconSection(group, [
        for (final i in kCategoryIcons)
          if (i.group == group) i,
      ]),
];

// 찾는 말 · 표의 글 — 소문자로 바꾸고 공백을 모두 뺀다(웹 · 앱이 같은 규칙으로)
String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), '');

// 저장 값 → 세트의 한 줄(id 와 lucideAliases 모두)
final Map<String, PCategoryIcon> _byId = {
  for (final icon in kCategoryIcons) ...{
    icon.id: icon,
    for (final alias in icon.lucideAliases) alias: icon,
  },
};

// 아이콘마다 찾는 글(이름 · 찾는 말 · id) — 표 차례 그대로
final List<({PCategoryIcon icon, List<String> keys})> _haystack = [
  for (final icon in kCategoryIcons)
    (
      icon: icon,
      keys: [icon.name, ...icon.aliases, icon.id].map(_normalize).toList(),
    ),
];

/// 저장 값(lucide 이름) → 세트의 한 줄. id 또는 lucideAliases 로 찾고, 세트 밖 · 빈 값이면 null.
PCategoryIcon? findCategoryIcon(String? id) {
  final key = id?.trim() ?? '';
  if (key.isEmpty) return null;
  return _byId[key];
}

/// 찾는 말 → 걸린 아이콘(세트 차례). 이름 · 찾는 말 · id 의 부분 일치 — 소문자로 바꾸고 공백을 뺀 뒤. 빈 찾는 말이면 세트 전체.
List<PCategoryIcon> searchCategoryIcons(String query) {
  final q = _normalize(query);
  if (q.isEmpty) return kCategoryIcons;
  return [
    for (final h in _haystack)
      if (h.keys.any((k) => k.contains(q))) h.icon,
  ];
}

/// 세트 안 아이콘의 그림(선 2 · 고른 칸은 선 2.5). 세트 밖 저장 값은 lucide 전체에서 찾고 없으면 태그.
IconData categoryGlyph(String id, {bool bold = false}) {
  final table = bold ? kCategoryIconGlyphsBold : kCategoryIconGlyphs;
  final known = table[id] ?? table[findCategoryIcon(id)?.id];
  if (known != null) return known;
  return lucideByName(id, fallback: table[kDefaultCategoryIcon]!);
}
