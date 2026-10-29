// List Header 의 위 · 좌우 여백 바꾸기(topInset · inset) — 기본은 스펙 그대로(좌우 24 · 위아래 8)이고, 묶음이 이어지는 자리
// (종류 고르기 1단계 첫 묶음 0 · 다음 묶음 16)와 이미 좌우 24 가 있는 칸 묶음 안(inset 0)이 값을 바꾼다. 웹 `className="pt-* px-0"` 와 같은 값이다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(360, 400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

void main() {
  const titleKey = ValueKey('plist-header-title');
  const headerKey = ValueKey('plist-header');

  testWidgets('기본 — 좌우 24 · 위아래 8', (tester) async {
    await _pump(tester, const PListHeader(title: '계좌'));
    final header = tester.getRect(find.byKey(headerKey));
    final title = tester.getRect(find.byKey(titleKey));
    expect(title.left, 24);
    expect(title.top - header.top, 8);
    expect(header.bottom - title.bottom, 8);
  });

  testWidgets('topInset 은 위 여백만 바꾼다(0 · 16)', (tester) async {
    await _pump(
      tester,
      const Column(
        children: [
          PListHeader(title: '계좌', topInset: 0),
          PListHeader(title: '카드', topInset: 16),
        ],
      ),
    );
    final first = tester.getRect(find.byKey(headerKey).first);
    final firstTitle = tester.getRect(find.byKey(titleKey).first);
    expect(firstTitle.top - first.top, 0);
    expect(first.bottom - firstTitle.bottom, 8, reason: '아래 8 은 그대로');
    final second = tester.getRect(find.byKey(headerKey).last);
    final secondTitle = tester.getRect(find.byKey(titleKey).last);
    expect(secondTitle.top - second.top, 16);
  });

  testWidgets('inset 0 이면 제목이 왼쪽 끝에 선다', (tester) async {
    await _pump(tester, const PListHeader(title: '주식', inset: 0));
    expect(tester.getRect(find.byKey(titleKey)).left, 0);
  });
}
