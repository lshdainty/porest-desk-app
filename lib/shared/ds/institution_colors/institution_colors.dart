import 'package:flutter/widgets.dart';
import 'package:groo_damda_app/shared/ds/institution_colors/institution_colors.g.dart';

/// 기관 색 한 줄의 글자색 — white 는 static-white, dark 는 라이트 fg-neutral · 다크 fg-neutral-inverted.
enum PInstitutionText { white, dark }

/// 기관 색 표의 한 줄(institution-colors.yaml). 면 색은 모드를 따르지 않는다(라이트 · 다크 같다).
@immutable
class PInstitutionColor {
  const PInstitutionColor({
    required this.name,
    required this.category,
    required this.aliases,
    required this.color,
    required this.text,
    this.ci,
  });

  /// 스펙 JSON 의 한 줄(`data.entries[i]`)에서 읽는다.
  factory PInstitutionColor.fromJson(Map<String, dynamic> json) =>
      PInstitutionColor(
        name: json['name'] as String,
        category: json['category'] as String,
        aliases: ((json['aliases'] as List?) ?? const []).cast<String>(),
        color: _hex(json['color'] as String),
        ci: json['ci'] == null ? null : _hex(json['ci'] as String),
        text: PInstitutionText.values.byName(json['text'] as String),
      );

  /// 기관 이름 — 표의 대표 이름.
  final String name;

  /// 묶음 — 시중은행 · 인터넷은행 · 증권사 · 카드사 …
  final String category;

  /// 별칭 — 같은 기관으로 찾는 다른 이름.
  final List<String> aliases;

  /// 면 색 — 모드를 따르지 않는다.
  final Color color;

  /// 대비를 맞추려 명도를 고친 곳의 원래 색.
  final Color? ci;

  final PInstitutionText text;

  static Color _hex(String value) =>
      Color(0xFF000000 | int.parse(value.substring(1), radix: 16));
}

// 공백을 모두 뺀다 — 찾는 이름과 표의 name · aliases 모두
String _squash(String value) => value.replaceAll(RegExp(r'\s+'), '');

/// 기관 색 표 + 찾기. 웹 institutionColor 와 같은 순서로 찾는다.
///
/// 1. 찾는 이름과 표의 name · aliases 의 공백을 모두 뺀다
/// 2. name 또는 aliases 와 같으면 그 기관이다
/// 3. 아니면 찾는 이름에 들어 있는 name · aliases 가운데 가장 긴 것("NH농협카드 올원" → NH농협카드). 길이가 같으면 표에서
///    먼저 나온 기관이다. 표의 이름이 찾는 이름을 품는 거꾸로 맞추기("NH" ↔ "NH농협")는 하지 않는다
/// 4. 없으면 null — Logo Tile 은 Avatar 의 이름 색, 카드 면은 Content Placeholder(credit-card)
///
/// 저장된 자산 색(asset.color)은 읽지 않는다. 기관 이름(자산의 기관 · 카드의 카드사)으로만 찾는다.
class PInstitutionTable {
  PInstitutionTable(Iterable<PInstitutionColor> entries)
    : entries = List.unmodifiable(entries),
      _keys = [
        for (final e in entries)
          (
            entry: e,
            keys: [
              for (final k in [e.name, ...e.aliases])
                if (_squash(k).isNotEmpty) _squash(k),
            ],
          ),
      ];

  /// 스펙 JSON(`test/fixtures/design_spec/institution-colors.json` 과 같은 모양) 전체에서 읽는다.
  factory PInstitutionTable.fromSpecJson(Map<String, dynamic> spec) =>
      PInstitutionTable([
        for (final e in ((spec['data'] as Map)['entries'] as List))
          PInstitutionColor.fromJson((e as Map).cast<String, dynamic>()),
      ]);

  /// 아직 표가 없다 — 모두 "없음"(이름 색 · 대체 그림)으로 찾아진다.
  static final PInstitutionTable empty = PInstitutionTable(const []);

  final List<PInstitutionColor> entries;
  final List<({PInstitutionColor entry, List<String> keys})> _keys;

  /// 기관 이름 → 표의 한 줄, 없으면 null.
  PInstitutionColor? find(String? name) {
    final query = _squash(name ?? '');
    if (query.isEmpty) return null;
    for (final k in _keys) {
      if (k.keys.contains(query)) return k.entry;
    }
    PInstitutionColor? found;
    var longest = 0;
    for (final k in _keys) {
      for (final key in k.keys) {
        if (key.length > longest && query.contains(key)) {
          found = k.entry;
          longest = key.length;
        }
      }
    }
    return found;
  }
}

/// 앱이 쓰는 기관 색 표 하나. 표의 원본은 groo-design 의 YAML → 스펙 JSON 이다 — 표를 Dart 로 손으로 옮겨 적지 않는다.
///
/// 표는 `scripts/sync_design.sh` 가 스펙 JSON 에서 만든 `institution_colors.g.dart`(`kInstitutionColorsSpec`)에서 읽는다.
/// 테스트는 스펙 JSON 을 읽어 [table] 에 꽂아 생성 파일과 같은지도 본다.
abstract final class PInstitutionColors {
  static PInstitutionTable table = PInstitutionTable.fromSpecJson(
    kInstitutionColorsSpec,
  );

  /// 기관 이름 → 기관 색, 없으면 null.
  static PInstitutionColor? find(String? name) => table.find(name);
}
