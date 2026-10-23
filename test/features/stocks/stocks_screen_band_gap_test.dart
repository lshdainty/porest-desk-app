// 증권 화면(I-05 74) — 증권사 탭 띠와 본문 첫 띠 사이 8 은 남고, 머리 바로 아래는 0 이다.
// 본문은 모르는 증권사 안내(띠 하나)로 그려 네트워크 없이 잰다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/stocks/presentation/stocks_screen.dart';
import 'package:groo_damda_app/features/subscription/application/subscription_providers.dart';
import 'package:groo_damda_app/features/subscription/data/subscription_repository.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

Future<void> _pump(WidgetTester tester, List<String> brokers) async {
  tester.view.physicalSize = const Size(360 * 3, 780 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myFeaturesProvider.overrideWith(
          (ref) async => MyFeatures(
            features: const ['SECURITIES'],
            connectedBrokers: brokers,
            primaryBroker: brokers.first,
          ),
        ),
      ],
      child: MaterialApp(
        theme: GrooTheme.light(),
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const StocksScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('연결 둘 — 탭 띠와 본문 띠 사이 8', (tester) async {
    await _pump(tester, ['ZZZ', 'YYY']);
    final bands = find.byKey(const ValueKey('screen-section'));
    expect(bands, findsNWidgets(2), reason: '탭 띠 + 본문 띠');
    final tabs = tester.getRect(bands.at(0));
    final body = tester.getRect(bands.at(1));
    expect(body.top - tabs.bottom, 8);
  });

  testWidgets('연결 하나 — 탭이 없고 본문 띠가 머리 바로 아래(틈 0)', (tester) async {
    await _pump(tester, ['ZZZ']);
    final bands = find.byKey(const ValueKey('screen-section'));
    expect(bands, findsOneWidget);
    expect(
      tester.getRect(bands).top,
      tester.getRect(find.byType(AppBar)).bottom,
    );
  });
}
