// 나무 로고 부품 — groo_logo.svg 를 Chromium 으로 그린 기준 그림(308×332)과 픽셀로 대조한다.
// 기준 그림 생성기: ~/qa/design-work/logo-assets/gen-tree-ref.mjs · Path 생성기: gen-tree-painter.py.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/brand/groo_tree.dart';
import 'package:groo_damda_app/shared/brand/groo_tree_painter.dart';

void main() {
  testWidgets('폭 : 높이 = 154 : 166 이고 의미 트리에 없다', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: GrooTree(height: 56)),
      ),
    );
    final size = tester.getSize(find.byKey(const ValueKey('groo-tree')));
    expect(size.height, 56);
    expect(size.width, closeTo(56 * 154 / 166, 0.001));
    expect(kGrooTreeAspect, closeTo(154 / 166, 1e-9));
    expect(find.bySemanticsLabel(RegExp('.')), findsNothing);
  });

  test('svg 와 픽셀 대조 — 308×332 에서 어긋난 픽셀이 0.3% 미만', () async {
    const w = 308;
    const h = 332;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const GrooTreePainter().paint(canvas, const Size(308, 332));
    final mine = await recorder.endRecording().toImage(w, h);
    final mineBytes = (await mine.toByteData())!.buffer.asUint8List();

    final refCodec = await ui.instantiateImageCodec(
      File('test/fixtures/brand/groo_tree_308x332.png').readAsBytesSync(),
    );
    final ref = (await refCodec.getNextFrame()).image;
    expect(ref.width, w);
    expect(ref.height, h);
    final refBytes = (await ref.toByteData())!.buffer.asUint8List();

    var bad = 0;
    var opaque = 0;
    for (var i = 0; i < w * h; i++) {
      var d = 0;
      for (var k = 0; k < 4; k++) {
        final a = mineBytes[i * 4 + k];
        final b = refBytes[i * 4 + k];
        d = d > (a - b).abs() ? d : (a - b).abs();
      }
      if (refBytes[i * 4 + 3] > 0) opaque++;
      if (d > 64) bad++;
    }
    debugPrint('tree-pixel bad=$bad of ${w * h}');
    expect(opaque, greaterThan(w * h * 0.3), reason: '기준 그림에 나무가 있다');
    expect(bad / (w * h), lessThan(0.003), reason: '어긋난 픽셀 $bad / ${w * h}');
  });
}
