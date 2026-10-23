// 지시서 90 — 적응형 아이콘 background · foreground · monochrome 셋.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'logo_paths.dart';

void main() {
  const res = 'android/app/src/main/res';
  final xml = File('$res/mipmap-anydpi-v26/ic_launcher.xml').readAsStringSync();

  test('ic_launcher.xml 에 background · foreground · monochrome 셋', () {
    expect(xml, contains('<adaptive-icon'));
    expect(
      xml,
      contains('<background android:drawable="@color/ic_launcher_background"'),
    );
    expect(
      xml,
      contains(
        '<foreground android:drawable="@drawable/ic_launcher_foreground"',
      ),
    );
    expect(
      xml,
      contains(
        '<monochrome android:drawable="@drawable/ic_launcher_monochrome"',
      ),
    );
  });

  test('뒤 층 = 흰색', () {
    expect(
      File('$res/values/colors.xml').readAsStringSync(),
      contains('<color name="ic_launcher_background">#FFFFFF</color>'),
    );
  });

  test('매니페스트 아이콘 참조는 그대로, 옛 PNG 다섯 장은 남는다', () {
    expect(
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      contains('android:icon="@mipmap/ic_launcher"'),
    );
    for (final d in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      expect(File('$res/mipmap-$d/ic_launcher.png').existsSync(), isTrue);
    }
  });

  for (final (name, fills) in [
    ('ic_launcher_foreground', grooTreeFills.values.toList()),
    ('ic_launcher_monochrome', List.filled(4, '#FFFFFF')),
  ]) {
    test('$name — 108dp · path 는 svg 그대로 · 칠', () {
      final v = File('$res/drawable/$name.xml').readAsStringSync();
      expect(v, contains('android:width="108dp"'));
      final paths = readVectorPaths(v);
      expect(paths.map((p) => p.$2).toList(), grooTreePaths.values.toList());
      expect(paths.map((p) => p.$1).toList(), fills);
    });

    test('$name — 모든 점이 66dp 안전 원 안 · 타일 가운데가 캔버스 가운데', () {
      final v = File('$res/drawable/$name.xml').readAsStringSync();
      double g(String k) =>
          double.parse(RegExp('$k="(-?[\\d.]+)"').firstMatch(v)!.group(1)!);
      final s = g('scaleX'), tx = g('translateX'), ty = g('translateY');
      expect(s, closeTo(33 / 101.6, 1e-5));
      // 타일 가운데 (224, 263) → (54, 54)
      expect(tx + s * 224, closeTo(54, 0.01));
      expect(ty + s * 263, closeTo(54, 0.01));
      // path 의 모든 점(끝점 · 제어점 — 곡선은 이 점들의 볼록 껍질 안이라 보수적인 상한)을
      // 변환해 캔버스 가운데에서의 거리를 잰다 — 66dp 안전 원 = 반지름 33dp.
      var far = 0.0;
      for (final d in grooTreePaths.values) {
        for (final pt in pathPoints(d)) {
          final dx = tx + s * pt.$1 - 54, dy = ty + s * pt.$2 - 54;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist > far) far = dist;
        }
      }
      expect(
        far,
        lessThanOrEqualTo(33.0 + 1e-6),
        reason: '가장 먼 점 ${far.toStringAsFixed(3)}dp',
      );
    });
  }
}
