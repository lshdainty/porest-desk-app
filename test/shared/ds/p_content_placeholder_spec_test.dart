// Content Placeholder 가 스펙 값(test/fixtures/design_spec/content-placeholder.json)대로인지 — 라이트 · 다크의 면 ·
// 그림 색, 틀에 따른 그림 크기(높이의 50% · 16 ~ 160 · 폭에 맞춤), 선 굵기 1.5. 웹은 같은 JSON 을 크로미움에서 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/ds/content_placeholder/p_content_placeholder.dart';

import '../../support/design_spec.dart';

final _want = DesignSpec.load('content-placeholder').resolve({}, 'enabled');

Widget _host(Brightness mode, Size frame) => MaterialApp(
  theme: mode == Brightness.dark ? PorestTheme.dark() : PorestTheme.light(),
  home: Scaffold(
    body: Center(
      child: SizedBox.fromSize(size: frame, child: const PContentPlaceholder()),
    ),
  ),
);

void main() {
  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 면 · 그림 색 · 틀을 채움이 스펙 값이다', (tester) async {
      await tester.pumpWidget(_host(mode, const Size(120, 80)));
      final face = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(PContentPlaceholder),
          matching: find.byType(DecoratedBox),
        ),
      );
      final deco = face.decoration as BoxDecoration;
      expect(
        sameColor(
          specColor(pickMode(_want['root.background'], mode)),
          deco.color!,
        ),
        isTrue,
      );
      // 제 모서리가 없다 — 담는 틀이 자른다
      expect(_want['root.radius'], 0);
      expect(deco.borderRadius, isNull);
      // 틀을 채운다
      expect(
        tester.getSize(find.byType(PContentPlaceholder)),
        const Size(120, 80),
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(
        sameColor(specColor(pickMode(_want['glyph.color'], mode)), icon.color!),
        isTrue,
      );
    });
  }

  testWidgets('그림은 틀 높이의 50% — 16 이상 160 이하, 틀 폭이 좁으면 폭에 맞춘다', (tester) async {
    expect(_want['glyph.minWidth'], 16);
    expect(_want['glyph.maxWidth'], 160);
    for (final (frame, size) in [
      (const Size(100, 100), 50.0),
      (const Size(100, 20), 16.0),
      (const Size(800, 600), 160.0),
      (const Size(12, 100), 12.0),
    ]) {
      await tester.pumpWidget(_host(Brightness.light, frame));
      expect(
        tester.widget<Icon>(find.byType(Icon)).size,
        size,
        reason: '$frame',
      );
    }
  });

  testWidgets('선 굵기 1.5 — lucide 300 굵기 글꼴', (tester) async {
    expect(_want['glyph.strokeWidth'], '1.5');
    await tester.pumpWidget(_host(Brightness.light, const Size(100, 100)));
    expect(
      tester.widget<Icon>(find.byType(Icon)).icon!.fontFamily,
      'Lucide300',
    );
  });

  testWidgets('장식이라 읽지 않는다', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(Brightness.light, const Size(100, 100)));
    expect(
      find.descendant(
        of: find.byType(PContentPlaceholder),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
    semantics.dispose();
  });
}
