// 스펙 값 한 줄과 그려진 값을 견주고 실패를 모으는 도우미 — 화면 틀 · 이동 묶음 테스트가 쓴다(p_tabs_spec_test 의 `_Check` 와 같다).
import 'package:flutter/widgets.dart';

import 'design_spec.dart';

class SpecCheck {
  SpecCheck(this.mode, this.want, this.where);

  final Brightness mode;
  final Map<String, Object?> want;
  final String where;
  final failures = <String>[];
  final measured = <String>{};

  void fail(String message) => failures.add('$where — $message');

  void m(Iterable<String> keys) => measured.addAll(keys);

  void color(String key, Color actual) {
    final w = pickMode(want[key], mode);
    measured.add(key);
    if (w == null) return;
    if (!sameColor(specColor(w), actual)) {
      fail('$key: 스펙 $w · 실제 ${colorHex(actual)}');
    }
  }

  void px(String key, num actual) {
    measured.add(key);
    final w = want[key];
    if (w is num && (w - actual).abs() > 0.5) {
      fail('$key: 스펙 $w · 실제 $actual');
    }
  }

  void typo(String key, TextStyle style) {
    measured.add(key);
    final t = want[key] as Map?;
    if (t == null) return;
    final lineHeight = style.fontSize! * (style.height ?? 1);
    if (t['fontSize'] != style.fontSize ||
        ((t['lineHeight'] as num) - lineHeight).abs() > 0.01) {
      fail(
        '$key: 스펙 ${t['fontSize']}/${t['lineHeight']} · 실제 ${style.fontSize}/$lineHeight',
      );
    }
    final family = '${t['fontFamily']}'.split(',').first.trim();
    if (style.fontFamily != family) {
      fail('$key 글꼴: 스펙 $family · 실제 ${style.fontFamily}');
    }
  }

  void weight(String key, TextStyle style) {
    measured.add(key);
    final w = want[key];
    if (w is num && style.fontWeight?.value != w) {
      fail('$key: 스펙 $w · 실제 ${style.fontWeight}');
    }
  }

  void cursor(String key, MouseCursor actual) {
    measured.add(key);
    final expected = switch (want[key]) {
      'pointer' => SystemMouseCursors.click,
      'not-allowed' => SystemMouseCursors.forbidden,
      _ => null,
    };
    if (expected != null && actual != expected) {
      fail('$key: 스펙 ${want[key]} · 실제 $actual');
    }
  }

  /// 누름 축소 — "2px 거리 축소" 면 (기준 − 2) ÷ 기준, 기준은 [basis]. 값이 없으면 줄지 않는다.
  void pressScale(String key, double actual, double basis) {
    measured.add(key);
    final expected = want[key] != null ? (basis - 2) / basis : 1.0;
    if ((expected - actual).abs() > 1e-3) {
      fail('$key: 배율 스펙 $expected · 실제 $actual');
    }
  }

  void motion(String durationKey, String easingKey, Duration d, Curve curve) {
    measured.addAll([durationKey, easingKey]);
    if (want[durationKey] != null && specMs(want[durationKey]) != d) {
      fail('$durationKey: 스펙 ${want[durationKey]} · 실제 $d');
    }
    if (want[easingKey] != null) {
      final cubic = specCubic(want[easingKey]);
      if (curve is! Cubic ||
          [curve.a, curve.b, curve.c, curve.d].join(',') != cubic.join(',')) {
        fail('$easingKey: 스펙 ${want[easingKey]} · 실제 $curve');
      }
    }
  }

  /// 스펙에 있는데 아무도 재지 않는 값이 없게 — [elsewhere] 는 다른 테스트(동작 · 웹 전용)가 맡는 값이다.
  void coverage(Set<String> elsewhere) {
    for (final key in want.keys) {
      if (!measured.contains(key) && !elsewhere.contains(key)) {
        fail('$key: 스펙에 있는데 이 테스트가 재지 않는다 — 재는 곳을 더한다');
      }
    }
  }
}
