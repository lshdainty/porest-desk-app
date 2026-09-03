// 히트맵 셀 라벨 — 도넛 중앙·차트 축과 **같은 함수**로 줄이는가.
//
// 셀만 1만 아래를 `5천` 으로 한 번 더 줄이고 있었다. 칸이 좁아서였는데, `천` 은
// 합의한 단위가 아니다 — 만·억·조 뿐이고 1만 미만은 `4,900` 처럼 천단위 콤마
// 정수로 낸다(QA #73). 같은 화면에서 도넛 중앙이 `4,900`, 그 아래 히트맵이 `5천`
// 이면 같은 값이 두 글자로 보인다. 칸 폭은 셀의 FittedBox 가 글자를 줄여 해결한다.
//
// 에뮬레이터를 못 쓰는 환경이라(QA #23) 화면을 띄워 글자를 읽는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';
import 'package:porest_desk_app/features/stats/presentation/stats_screen.dart';

/// 히트맵이 있는 '카테고리' 탭(기본 탭)을 띄우고 히트맵 카드까지 스크롤한다.
Future<void> _pumpHeatmap(WidgetTester tester, int cellAmount) async {
  tester.view.physicalSize = const Size(480 * 3, 900 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => const []),
        rangeExpensesProvider.overrideWith((ref, key) async => const []),
        rangeSummaryProvider.overrideWith(
          (ref, range) async => RangeSummary(
            startDate: range.startDate,
            endDate: range.endDate,
            totalExpense: cellAmount,
          ),
        ),
        merchantSummaryProvider.overrideWith(
          (ref, range) async => const <MerchantSummary>[],
        ),
        heatmapProvider.overrideWith(
          // 월요일 12시 한 칸만 채운다 — 나머지 칸은 0(`—`)이다.
          (ref, range) async => [
            HeatmapCell(dayOfWeek: 1, hour: 12, totalAmount: cellAmount),
          ],
        ),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: const StatsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(
    find.text('요일·시간대 지출 패턴'),
    300,
    scrollable: find
        .descendant(
          of: find.byKey(const PageStorageKey('stats-category')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1만 아래 셀은 `5천` 이 아니라 `4,900` 이다', (tester) async {
    await _pumpHeatmap(tester, 4900);

    expect(find.text('5천'), findsNothing);
    expect(find.text('4,900'), findsWidgets);
  });

  testWidgets('1만 위 셀은 예전과 같은 만 단위 축약', (tester) async {
    await _pumpHeatmap(tester, 11881);

    expect(find.text('1.2만'), findsWidgets);
  });
}
