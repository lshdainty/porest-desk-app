// 지시서 89 — iOS 다크 · 틴트 변형(Contents.json + 1024 그림).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'png_probe.dart';

const _dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';

void main() {
  final json =
      jsonDecode(File('$_dir/Contents.json').readAsStringSync())
          as Map<String, dynamic>;
  final images = (json['images'] as List).cast<Map<String, dynamic>>();

  Map<String, dynamic> variant(String v) => images.singleWhere(
    (i) => ((i['appearances'] as List?) ?? const []).any(
      (a) => a['appearance'] == 'luminosity' && a['value'] == v,
    ),
  );

  test('Contents.json 에 dark · tinted 변형이 1024 한 장씩, 파일이 있다', () {
    for (final (v, f) in [
      ('dark', 'Icon-App-1024x1024-dark.png'),
      ('tinted', 'Icon-App-1024x1024-tinted.png'),
    ]) {
      final e = variant(v);
      expect(e['filename'], f);
      expect(e['size'], '1024x1024');
      expect(e['idiom'], 'universal');
      expect(e['platform'], 'ios');
      expect(File('$_dir/$f').existsSync(), isTrue);
    }
    // 크기별 15장을 다시 만들지 않았다 — 변형은 둘뿐
    expect(
      images.where((i) => (i['appearances'] as List?)?.isNotEmpty ?? false),
      hasLength(2),
    );
    // 밝은(기본) 1024 는 그대로
    expect(
      images.any((i) => i['filename'] == 'Icon-App-1024x1024@1x.png'),
      isTrue,
    );
  });

  test('다크 = 투명 바탕 + 시안 나무(타일 높이의 69.6%, 가운데)', () {
    final img = PngImage.read('$_dir/Icon-App-1024x1024-dark.png');
    expect([img.width, img.height, img.hasAlpha], [1024, 1024, true]);
    for (final c in [
      [0, 0],
      [1023, 0],
      [0, 1023],
      [1023, 1023],
      [512, 20],
    ]) {
      expect(img.px(c[0], c[1])[3], 0);
    }
    final b = img.bbox(isInk: (p) => p[3] > 128)!;
    final h = b[3] - b[1] + 1;
    expect(h / 1024, closeTo(146.26 / 210, 0.003));
    // 시안 칠: 겹침 가운데 #218D49, 왼 잎 #075B3C, 오른 잎 #43BF5E
    expect(img.px(512, 440).sublist(0, 3), [0x21, 0x8D, 0x49]);
    expect(img.px(300, 300).sublist(0, 3), [0x07, 0x5B, 0x3C]);
    expect(img.px(720, 300).sublist(0, 3), [0x43, 0xBF, 0x5E]);
  });

  test('틴트 = 한 색(흰) 실루엣, 바탕 투명, 다크와 같은 자리', () {
    final t = PngImage.read('$_dir/Icon-App-1024x1024-tinted.png');
    final d = PngImage.read('$_dir/Icon-App-1024x1024-dark.png');
    expect(t.hasAlpha, isTrue);
    var inkCount = 0;
    for (var y = 0; y < 1024; y += 1) {
      for (var x = 0; x < 1024; x += 1) {
        final p = t.px(x, y);
        if (p[3] > 0) {
          inkCount++;
          expect(p.sublist(0, 3), [255, 255, 255]);
        }
      }
    }
    expect(inkCount, greaterThan(100000));
    expect(t.bbox(isInk: (p) => p[3] > 128), d.bbox(isInk: (p) => p[3] > 128));
    expect(t.px(0, 0)[3], 0);
  });
}
