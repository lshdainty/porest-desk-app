// porest-design 스펙 값(test/fixtures/design_spec/<이름>.json)을 읽고 푼다 — scripts/sync_design.sh 가 가져온다.
//
// 새 컴포넌트(lib/shared/ds)는 생성 토큰으로 값을 적고, 테스트가 이 값과 같은지 본다.
// 푸는 법은 웹 검사기(desk-front scripts/check-ds-spec.mjs) · 사이트와 같다 — when 이 맞는 규칙의
// enabled 를 차례로 겹치고, 그 위에 그 상태의 값을 겹친다.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Brightness, Color;

class DesignSpec {
  DesignSpec._(this._json);

  factory DesignSpec.load(String name) => DesignSpec._(
    jsonDecode(File('test/fixtures/design_spec/$name.json').readAsStringSync())
        as Map<String, dynamic>,
  );

  final Map<String, dynamic> _json;

  Map<String, List<String>> get axes => {
    for (final e in (_json['axes'] as Map<String, dynamic>).entries)
      e.key: (e.value as List).cast<String>(),
  };

  Map<String, String> get defaults =>
      (_json['defaults'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, '$v'),
      );

  List<String> get states => (_json['states'] as List).cast<String>();

  /// 고른 축의 모든 조합(곱).
  List<Map<String, String>> combos(List<String> names) {
    var out = <Map<String, String>>[{}];
    for (final name in names) {
      out = [
        for (final partial in out)
          for (final value in axes[name]!) {...partial, name: value},
      ];
    }
    return out;
  }

  /// 조합 · 상태의 값 — {"root.height": 40, …}. 값은 JSON 그대로({light, dark} · 숫자 · 글).
  Map<String, Object?> resolve(Map<String, String> combo, String state) {
    final full = {...defaults, ...combo};
    final base = states.first;
    final rules = (_json['rules'] as List).cast<Map<String, dynamic>>().where(
      (r) => (r['when'] as Map<String, dynamic>).entries.every(
        (e) => full[e.key] == '${e.value}',
      ),
    );
    final out = <String, Object?>{};
    for (final s in state == base ? [base] : [base, state]) {
      for (final r in rules) {
        final block = r[s] as Map<String, dynamic>?;
        if (block == null) continue;
        for (final slot in block.entries) {
          for (final p in (slot.value as Map<String, dynamic>).entries) {
            out['${slot.key}.${p.key}'] = p.value;
          }
        }
      }
    }
    return out;
  }
}

/// 모드 값 — {light, dark} 면 그 모드, 아니면 그대로.
Object? pickMode(Object? value, Brightness mode) {
  if (value is Map && value.containsKey('light') && value.containsKey('dark')) {
    return value[mode == Brightness.dark ? 'dark' : 'light'];
  }
  return value;
}

/// "#RRGGBB(AA)" · "transparent" → Color
Color specColor(Object? value) {
  final s = '$value';
  if (s == 'transparent') return const Color(0x00000000);
  final m = RegExp(r'^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$').firstMatch(s);
  if (m == null) throw ArgumentError('색이 아니다: $s');
  final rgb = int.parse(m.group(1)!, radix: 16);
  final a = m.group(2) == null ? 0xFF : int.parse(m.group(2)!, radix: 16);
  return Color((a << 24) | rgb);
}

/// 같은 색인가 — 채널마다 1/255, 불투명도는 0.01 까지 봐준다(흰 30% = 0x4D 처럼 반올림이 갈린다).
/// 둘 다 완전히 투명하면 색은 상관없다.
bool sameColor(Color expected, Color actual) {
  if (expected.a == 0 && actual.a == 0) return true;
  return (expected.r - actual.r).abs() <= 1.5 / 255 &&
      (expected.g - actual.g).abs() <= 1.5 / 255 &&
      (expected.b - actual.b).abs() <= 1.5 / 255 &&
      (expected.a - actual.a).abs() <= 0.01;
}

String colorHex(Color c) =>
    '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
