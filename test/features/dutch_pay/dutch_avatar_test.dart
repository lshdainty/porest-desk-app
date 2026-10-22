// 더치페이 아바타가 ds Avatar 의 이니셜 · 이름 색 규칙을 따르는지(03E-011) — 같은 사람은 웹 · 앱 · PAvatar 에서 같은 색이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/dutch_pay/presentation/dutch_pay_screen.dart';
import 'package:groo_damda_app/shared/ds/avatar/p_avatar.dart';

Widget _host(Brightness mode, Widget child) => MaterialApp(
  theme: mode == Brightness.dark ? GrooTheme.dark() : GrooTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  for (final mode in Brightness.values) {
    testWidgets('${mode.name} — 이름 색 · 이니셜 · 글자색이 ds Avatar 와 같다', (
      tester,
    ) async {
      final c = mode == Brightness.dark ? PColors.dark : PColors.light;
      // 한글 · 영문(두 글자가 아니라 한 글자) · 특수 글자
      for (final name in ['김하나', 'Kim Hana', 'ßeta', '이서연', '박지훈']) {
        await tester.pumpWidget(_host(mode, DutchAvatar(name: name, size: 36)));
        final box = tester.widget<Container>(find.byType(Container).first);
        expect(
          (box.decoration! as BoxDecoration).color,
          avatarHueColor(c, name),
          reason: '$name 색',
        );
        final text = tester.widget<Text>(find.byType(Text));
        expect(text.data, avatarInitial(name), reason: '$name 이니셜');
        expect(text.data!.characters.length, 1);
        expect(text.style!.color, c.fgNeutralInverted);
      }
    });
  }

  testWidgets('안 낸 사람을 흐리게 하지 않는다 — Opacity 가 없다', (tester) async {
    await tester.pumpWidget(
      _host(Brightness.light, const DutchAvatar(name: '김하나')),
    );
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('이름이 비면 ? 를 보인다', (tester) async {
    await tester.pumpWidget(
      _host(Brightness.light, const DutchAvatar(name: '  ')),
    );
    expect(find.text('?'), findsOneWidget);
  });
}
