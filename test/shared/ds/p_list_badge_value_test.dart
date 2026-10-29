// I-29 — List 뒤 붙이개의 배지는 값이다: 큰 글자(좁은 줄)에서 설명 아래 왼쪽, 보통 글자(한 줄)에서는 줄 끝.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/list/list_row.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

Widget _host(Widget child) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: child),
    ),
  ),
);

Widget _row() => PList(
  semanticLabel: '할 일',
  children: [
    PListItem(
      title: '주간 회의록',
      detail: '업무',
      suffix: const PBadge(key: ValueKey('badge'), label: '여유'),
    ),
  ],
);

void main() {
  test('splitListSuffix — PBadge 는 값', () {
    final r = splitListSuffix(const PBadge(label: '여유'));
    expect(r.values, hasLength(1));
    expect(r.controls, isEmpty);
  });

  testWidgets('글자 200% — 배지가 설명 아래 왼쪽', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(_host(_row()));
    expect(find.byKey(const ValueKey('plist-value-below')), findsOneWidget);
    final badge = tester.getRect(find.byKey(const ValueKey('badge')));
    final title = tester.getRect(find.byKey(const ValueKey('plist-title')));
    expect(badge.top, greaterThan(title.bottom));
    expect(badge.left, closeTo(title.left, 1));
  });

  testWidgets('글자 100% — 한 줄이면 줄 끝', (tester) async {
    await tester.pumpWidget(_host(_row()));
    expect(find.byKey(const ValueKey('plist-value-below')), findsNothing);
    final badge = tester.getRect(find.byKey(const ValueKey('badge')));
    expect(badge.right, closeTo(360 - 24, 1));
  });
}
