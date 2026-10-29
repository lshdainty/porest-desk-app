// I-29 웹 · 앱 같은 장면 — P7 달 줄 오른쪽 동작 내림 자리.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/forms/month_row.dart';

void main() {
  testWidgets('P7 큰 글자에서 오른쪽 동작이 아래 줄 오른쪽 끝으로 내려간다', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    const key = Key('trailing');
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: MonthRow(
            month: DateTime(2026, 10),
            onPick: () {},
            trailing: const SizedBox(key: key, width: 120, height: 40),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            labelStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byKey(key));
    final title = tester.getRect(find.textContaining('2026').first);
    expect(
      box.top,
      greaterThanOrEqualTo(title.bottom - 1),
      reason: '아래 줄로 내려간다',
    );
    expect(box.right, closeTo(360 - 24, 0.5), reason: '오른쪽 끝');
  });
}
