// 구독 시트의 기능 비교표는 **Pro 가 실제로 주는 것**만 적는다.
//
// 한동안 표가 없는 제한을 광고했다 — 월 100건 · CSV 가져오기/내보내기 ·
// 다중 캘린더 공유 · 카드 혜택 추천. 코드에는 그런 제한이 하나도 없고
// (플랜 features 는 `["SECURITIES"]` 뿐, 서버 게이트도 증권 API 뿐) Free 계정으로
// 전부 됐다. 줄이 되살아나면 여기서 깨진다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/presentation/subscription_sheet.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations_ko.dart';

/// 표에서 걷어 낸 네 줄의 한국어 문구. 키를 지웠으므로 문자열로 붙잡는다 —
/// 다시 넣으려면 arb 에 같은 문구를 되살려야 하고, 그 순간 이 테스트가 깨진다.
const _removedRows = <String>[
  '월 거래 기록',
  '100건',
  '무제한',
  'CSV · Excel 가져오기 / 내보내기',
  '다중 캘린더 공유',
  '카드 혜택 추천',
];

Widget _app() => ProviderScope(
  // Free 계정 고정 — 표 내용은 플랜과 무관하지만 네트워크를 타지 않게 막는다.
  overrides: [mySubscriptionProvider.overrideWith((ref) async => null)],
  child: MaterialApp(
    theme: PorestTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Builder(
      builder: (ctx) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showSubscriptionSheet(ctx),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  ),
);

/// 비교표 = '기능' 헤더를 감싼 가장 가까운 ClipRRect(표 전체를 라운딩하는 그것).
/// 플랜 카드의 'Free'/'Pro' 와 섞이지 않게 이 안쪽만 센다.
Finder _table(AppLocalizations l) => find
    .ancestor(
      of: find.text(l.subFeatureColumn),
      matching: find.byType(ClipRRect),
    )
    .first;

Future<void> _openSheet(WidgetTester tester) async {
  // 시트(0.92)가 표까지 한 번에 담기도록 세로를 넉넉히. 폭은 폰 폭 고정 —
  // 넓히면 Material 이 시트를 640 으로 잘라 가운데 정렬한다.
  tester.view.physicalSize = const Size(390 * 3, 1600 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_app());
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  final l = AppLocalizationsKo();

  testWidgets('비교표에 없는 제한을 광고하지 않는다 — 증권 한 줄만 Pro 전용', (tester) async {
    await _openSheet(tester);

    expect(_table(l), findsOneWidget);

    for (final gone in _removedRows) {
      expect(
        find.text(gone),
        findsNothing,
        reason: '"$gone" 은 코드에 없는 제한이다 — 표에 적으면 광고가 된다',
      );
    }

    // 남는 줄은 셋. 증권만 Pro 전용(별표).
    expect(
      find.descendant(of: _table(l), matching: find.text(l.subFeatLedger)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _table(l), matching: find.text(l.subFeatBudget)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: _table(l), matching: find.text(l.subFeatSecurities)),
      findsOneWidget,
    );
  });

  testWidgets('Free/Pro 표시가 깨지지 않는다 — 체크 5 · 대시 1', (tester) async {
    await _openSheet(tester);

    final table = _table(l);

    // 헤더 두 칸.
    expect(
      find.descendant(of: table, matching: find.text('Free')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: table, matching: find.text('Pro')),
      findsOneWidget,
    );

    // 가계부 ✓✓ · 예산 ✓✓ · 증권 −✓ → 체크 5, 대시 1.
    expect(
      find.descendant(of: table, matching: find.byIcon(LucideIcons.check)),
      findsNWidgets(5),
    );
    expect(
      find.descendant(of: table, matching: find.byIcon(LucideIcons.minus)),
      findsNWidgets(1),
    );
  });
}
