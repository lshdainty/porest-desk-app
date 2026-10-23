// 지시서 83 — 앱 아이콘 PNG 크기마다 픽셀 검사(생성기: ~/qa/design-work/logo-assets/gen-icons.mjs).
import 'package:flutter_test/flutter_test.dart';

import 'png_probe.dart';

const _ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
const _res = 'android/app/src/main/res';

// 나무 높이 / 타일 높이 = 146.26 / 210 (svg 좌표).
const _ratio = 146.26 / 210;

bool _nonWhite(List<int> p) =>
    p[3] > 0 && (255 - p[0] > 40 || 255 - p[1] > 40 || 255 - p[2] > 40);

void main() {
  final ios = <String, int>{
    'Icon-App-20x20@1x.png': 20,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-1024x1024@1x.png': 1024,
  };

  group('iOS 15장 — 정사각 흰 바탕 + 나무', () {
    ios.forEach((name, px) {
      test('$name = $px', () {
        final img = PngImage.read('$_ios/$name');
        expect([img.width, img.height], [px, px]);
        expect(img.hasAlpha, isFalse, reason: '알파 없이(RGB)');
        for (final c in [
          [0, 0],
          [px - 1, 0],
          [0, px - 1],
          [px - 1, px - 1],
        ]) {
          expect(img.px(c[0], c[1]), [255, 255, 255, 255], reason: '네 모서리 흰색');
        }
        final b = img.bbox(isInk: _nonWhite)!;
        final h = b[3] - b[1] + 1;
        expect(
          (h / px - _ratio).abs() * px,
          lessThan(2.0),
          reason: '나무 높이 비율 ${(h / px).toStringAsFixed(4)} ≈ 0.6965',
        );
        final cx = (b[0] + b[2] + 1) / 2;
        expect((cx - px / 2).abs(), lessThan(px * 0.02 + 1), reason: '가로 가운데');
      });
    });
  });

  group('Android 5장 — 모서리 투명 · 가운데 흰 불투명', () {
    const dens = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    dens.forEach((d, px) {
      test('mipmap-$d = $px', () {
        final img = PngImage.read('$_res/mipmap-$d/ic_launcher.png');
        expect([img.width, img.height], [px, px]);
        expect(img.hasAlpha, isTrue);
        for (final c in [
          [0, 0],
          [px - 1, 0],
          [0, px - 1],
          [px - 1, px - 1],
        ]) {
          expect(img.px(c[0], c[1])[3], 0, reason: '모서리 투명');
        }
        // 타일 위쪽 가운데(나무 위)는 흰 불투명
        expect(img.px(px ~/ 2, (px * 0.04).round() + 1), [255, 255, 255, 255]);
        // 나무 가운데(잎 겹침 자리)는 불투명
        expect(img.px(px ~/ 2, (px * 0.45).round())[3], 255);
        final b = img.bbox(isInk: _nonWhite)!;
        final h = b[3] - b[1] + 1;
        expect((h / px - _ratio).abs() * px, lessThan(2.0));
      });
    });
  });
}
