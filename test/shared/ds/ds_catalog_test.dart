// 컴포넌트 카탈로그(/dev/ds)가 그려지는지 본다 — debug 빌드에서만 길이 있어 다른 테스트가
// 이 화면을 지나지 않는다. 컴포넌트를 만들 때마다 demo 가 여기 붙으므로, 깨진 demo 도 여기서 걸린다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/ds/catalog/ds_catalog_screen.dart';
import 'package:porest_desk_app/shared/ds/catalog/ds_registry.dart';

void main() {
  testWidgets('앱 카탈로그는 39개를 싣고 라이트 · 다크 판을 그린다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: PorestTheme.light(), home: const DsCatalogScreen()),
    );

    final entries = dsFamilies.expand((f) => f.entries).toList();
    // 웹 42개 중 Dialog · Menu · Popover(1280 이상 전용)를 뺀 39개
    expect(entries, hasLength(39));
    expect(
      entries.map((e) => e.spec),
      isNot(anyOf(contains('dialog'), contains('menu'), contains('popover'))),
    );

    final built = entries.where((e) => e.demo != null).length;
    expect(find.textContaining('확정 스펙 39개 중 $built개'), findsOneWidget);
    expect(find.textContaining(PDesignSource.sha256), findsOneWidget);
    // 역할 색 판 — 라이트 · 다크 하나씩
    expect(find.text('라이트'), findsWidgets);
    expect(find.text('다크'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다크 판 안에서는 역할 색이 다크 값이다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: PorestTheme.light(), home: const DsCatalogScreen()),
    );

    final darkLabel = find.text('다크').first;
    final ctx = tester.element(darkLabel);
    expect(ctx.colors.bgLayerDefault, PColors.dark.bgLayerDefault);
    final lightCtx = tester.element(find.text('라이트').first);
    expect(lightCtx.colors.bgLayerDefault, PColors.light.bgLayerDefault);
  });
}
