// 짝 버튼(03A-013) — 한 라벨이 짝 폭의 절반을 넘으면 세로로 쌓는다(주 버튼 위, 라벨 한 줄).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/button/p_responsive_pair.dart';

Widget _host(double width, double scale, String secondary, String primary) =>
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: PResponsivePair(
                secondary: PButton(
                  label: secondary,
                  size: PButtonSize.large,
                  variant: PButtonVariant.neutralWeak,
                  onPressed: () {},
                ),
                primary: PButton(
                  label: primary,
                  size: PButtonSize.large,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('짧은 라벨은 한 줄에 반씩', (tester) async {
    await tester.pumpWidget(_host(342, 1, '취소', '저장'));
    expect(find.byKey(const ValueKey('pair-row')), findsOneWidget);
    final a = tester.getRect(find.text('취소'));
    final b = tester.getRect(find.text('저장'));
    expect(a.center.dy, b.center.dy);
    expect(a.left, lessThan(b.left), reason: '보조 왼쪽 · 주 오른쪽');
  });

  testWidgets('긴 라벨(360 폭 "엑셀로 내보내기")은 세로로 쌓고 주 버튼이 위다', (tester) async {
    await tester.pumpWidget(_host(312, 1, '취소', '엑셀로 내보내기'));
    expect(find.byKey(const ValueKey('pair-column')), findsOneWidget);
    final primary = tester.getRect(find.text('엑셀로 내보내기'));
    final secondary = tester.getRect(find.text('취소'));
    expect(primary.top, lessThan(secondary.top), reason: '주 버튼이 위');
    // 라벨은 한 줄 — 넘치지 않는다
    expect(tester.takeException(), isNull);
    expect(primary.height, lessThan(30));
  });

  testWidgets('글자 크기 200% 에서는 짧은 라벨도 쌓이고 넘치지 않는다', (tester) async {
    await tester.pumpWidget(_host(312, 2, '취소', '저장하고 닫기'));
    expect(find.byKey(const ValueKey('pair-column')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('반 폭 판정 — (짝 폭 − 간격) ÷ 2', () {
    expect(PResponsivePair.fitsInRow(312, 150, 100), isTrue);
    expect(PResponsivePair.fitsInRow(312, 155, 100), isFalse);
  });
}
