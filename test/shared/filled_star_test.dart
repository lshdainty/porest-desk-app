// 채운 별 — 모양(오각 별 열 점) · 색 · 크기 · 낭독(읽지 않는다).
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/shared/icons/filled_star.dart';

void main() {
  test('모양 — 위 꼭짓점이 가운데 위, 바깥 · 안쪽 열 점, 좌우 대칭', () {
    final path = FilledStarPainter.path24();
    final b = path.getBounds();
    // 격자 24 안에 든다 · 선 두께 2 가 더 나가도 24 를 넘지 않는다
    expect(b.top - 1, greaterThanOrEqualTo(0));
    expect(b.bottom + 1, lessThanOrEqualTo(24));
    expect(b.left - 1, greaterThanOrEqualTo(0));
    expect(b.right + 1, lessThanOrEqualTo(24));
    // 좌우 대칭 — 가운데 12
    expect((b.left + b.right) / 2, closeTo(12, 0.01));
    // 안이 채워진다 — 가운데는 들고 모서리 밖은 아니다
    expect(path.contains(FilledStarPainter.center), isTrue);
    expect(path.contains(const Offset(1, 1)), isFalse);
    // 위 꼭짓점이 가장 위
    expect(
      b.top,
      closeTo(FilledStarPainter.center.dy - FilledStarPainter.outer, 0.01),
    );
  });

  testWidgets('크기 10 · 색은 그대로 채움 · 선도 같은 색 · 낭독 0', (tester) async {
    const color = Color(0xFF8B4DBA);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: PFilledStar(size: 10, color: color)),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('filled-star'))),
      const Size(10, 10),
    );
    final box = tester.renderObject(find.byKey(const ValueKey('filled-star')));
    expect(
      box,
      paints
        ..path(color: color, style: PaintingStyle.fill)
        ..path(color: color, style: PaintingStyle.stroke, strokeWidth: 2),
    );
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('filled-star')),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    final handle = tester.ensureSemantics();
    expect(tester.getSemantics(find.byType(PFilledStar)).label, isEmpty);
    handle.dispose();
  });

  testWidgets('색이 바뀌면 다시 그린다', (tester) async {
    Future<void> pump(Color c) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: PFilledStar(size: 24, color: c)),
      ),
    );
    await pump(const Color(0xFF2C70BF));
    await pump(const Color(0xFFC73838));
    expect(
      tester.renderObject(find.byKey(const ValueKey('filled-star'))),
      paints..path(color: const Color(0xFFC73838)),
    );
  });
}
