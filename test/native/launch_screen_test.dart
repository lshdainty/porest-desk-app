// 지시서 91 — OS 시작 화면: 바탕 = bg-layer-default(토큰 생성 파일과 대조) + 가운데 나무 96.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'logo_paths.dart';
import 'png_probe.dart';

const _res = 'android/app/src/main/res';
const _ios = 'ios/Runner/Assets.xcassets';

String _hex(String argb) => '#${argb.substring(2).toUpperCase()}';

void main() {
  // 토큰 생성 파일에서 bg-layer-default 의 라이트(첫째) · 다크(둘째) 값을 읽는다.
  final tokens = File('lib/app/theme/groo_tokens.g.dart').readAsStringSync();
  final found = RegExp(
    r'^\s+bgLayerDefault: Color\(0x([0-9A-Fa-f]{8})\),',
    multiLine: true,
  ).allMatches(tokens).map((m) => _hex(m.group(1)!)).toList();
  final light = found[0], dark = found[1];

  test('토큰 값 자체(전제): 라이트 #FFFFFF · 다크 #242938', () {
    expect([light, dark], ['#FFFFFF', '#242938']);
  });

  String item(String file, String name) {
    final x = File(file).readAsStringSync();
    return RegExp('name="$name">([^<]+)<').firstMatch(x)!.group(1)!;
  }

  test('안드로이드 12+ values-v31 · values-night-v31 = 토큰 hex + 나무 아이콘', () {
    expect(
      item(
        '$_res/values-v31/styles.xml',
        'android:windowSplashScreenBackground',
      ),
      light,
    );
    expect(
      item(
        '$_res/values-night-v31/styles.xml',
        'android:windowSplashScreenBackground',
      ),
      dark,
    );
    for (final d in ['values-v31', 'values-night-v31']) {
      expect(
        item('$_res/$d/styles.xml', 'android:windowSplashScreenAnimatedIcon'),
        '@drawable/ic_splash_tree',
      );
    }
  });

  test('안드로이드 11 이하 바탕 색 리소스 = 토큰 hex, launch_background 가 쓴다', () {
    final l = File('$_res/values/colors.xml').readAsStringSync();
    final n = File('$_res/values-night/colors.xml').readAsStringSync();
    expect(l, contains('<color name="splash_background">$light</color>'));
    expect(n, contains('<color name="splash_background">$dark</color>'));
    for (final d in ['drawable', 'drawable-v21']) {
      final x = File('$_res/$d/launch_background.xml').readAsStringSync();
      expect(x, contains('@color/splash_background'));
      expect(x, contains('@drawable/launch_tree'));
      expect(x, contains('android:gravity="center"'));
      expect(x, isNot(contains('?android:colorBackground')));
    }
    for (final d in ['values', 'values-night']) {
      expect(
        File('$_res/$d/styles.xml').readAsStringSync(),
        contains(
          '<item name="android:windowBackground">@color/splash_background</item>',
        ),
      );
    }
  });

  test('밀도별 나무 PNG = 96dp(96 · 144 · 192 · 288 · 384), 투명 바탕', () {
    const dens = {
      'mdpi': 96,
      'hdpi': 144,
      'xhdpi': 192,
      'xxhdpi': 288,
      'xxxhdpi': 384,
    };
    dens.forEach((d, h) {
      final img = PngImage.read('$_res/drawable-$d/launch_tree.png');
      expect(img.height, h);
      expect(img.width, (h * 154 / 166).round());
      expect(img.px(0, 0)[3], 0);
      final b = img.bbox(isInk: (p) => p[3] > 128)!;
      expect(
        b[3] - b[1] + 1,
        closeTo(h * 146.26 / 166, 1.5),
        reason: "보기 상자 높이 166 안의 나무 146.26",
      );
    });
  });

  test('12+ 아이콘 벡터 = 288dp 캔버스 가운데 나무 높이 96dp · 바탕 없음 · 192 원 안', () {
    final v = File('$_res/drawable/ic_splash_tree.xml').readAsStringSync();
    expect(v, contains('android:width="288dp"'));
    expect(v, contains('android:viewportWidth="288"'));
    final paths = readVectorPaths(v);
    expect(paths.map((p) => p.$2).toList(), grooTreePaths.values.toList());
    expect(paths.map((p) => p.$1).toList(), grooTreeFills.values.toList());
    double g(String k) =>
        double.parse(RegExp('$k="(-?[\\d.]+)"').firstMatch(v)!.group(1)!);
    final s = g('scaleX'), tx = g('translateX'), ty = g('translateY');
    expect(s * 166, closeTo(96, 0.01));
    expect(tx + s * 224, closeTo(144, 0.01));
    expect(ty + s * 266, closeTo(144, 0.01));
    var far = 0.0;
    for (final d in grooTreePaths.values) {
      for (final pt in pathPoints(d)) {
        final dx = tx + s * pt.$1 - 144, dy = ty + s * pt.$2 - 144;
        far = far > dx * dx + dy * dy ? far : dx * dx + dy * dy;
      }
    }
    expect(far, lessThan(96 * 96), reason: '반지름 96dp(192 원) 안');
  });

  test('iOS 색 세트 LaunchBackground = 토큰(라이트 · 다크), storyboard 가 쓴다', () {
    final j =
        jsonDecode(
              File(
                '$_ios/LaunchBackground.colorset/Contents.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final cs = (j['colors'] as List).cast<Map<String, dynamic>>();
    String hexOf(Map<String, dynamic> c) {
      final k = c['color']['components'] as Map<String, dynamic>;
      return '#${[k['red'], k['green'], k['blue']].map((e) => (e as String).substring(2)).join()}'
          .toUpperCase();
    }

    expect(hexOf(cs.firstWhere((c) => c['appearances'] == null)), light);
    expect(hexOf(cs.firstWhere((c) => c['appearances'] != null)), dark);
    final sb = File(
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
    ).readAsStringSync();
    expect(
      sb,
      contains('<color key="backgroundColor" name="LaunchBackground"/>'),
    );
    expect(sb, isNot(contains('key="backgroundColor" red="1"')));
    expect(sb, contains('<image name="LaunchImage" width="89" height="96"/>'));
  });

  test('iOS LaunchImage = 나무 96pt @1x @2x @3x 투명 바탕', () {
    const f = {
      'LaunchImage.png': 96,
      'LaunchImage@2x.png': 192,
      'LaunchImage@3x.png': 288,
    };
    f.forEach((n, h) {
      final img = PngImage.read('$_ios/LaunchImage.imageset/$n');
      expect(img.height, h);
      expect(img.hasAlpha, isTrue);
      expect(img.px(0, 0)[3], 0);
      final b = img.bbox(isInk: (p) => p[3] > 128)!;
      expect(
        b[3] - b[1] + 1,
        closeTo(h * 146.26 / 166, 1.5),
        reason: "보기 상자 높이 166 안의 나무 146.26",
      );
    });
  });
}
