// 통계·분석 3탭(카테고리/추이/비교)을 좌우 스와이프로 넘길 수 있는지.
//
// 칩 탭으로만 넘어가던 걸 PageView 로 바꿨다. 칩과 스와이프가 같은 인덱스를 공유해야
// 하므로 양방향(칩→본문 / 스와이프→칩)을 모두 확인한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/stats/application/stats_providers.dart';
import 'package:porest_desk_app/features/stats/domain/stats_models.dart';
import 'package:porest_desk_app/features/stats/presentation/stats_screen.dart';

Future<void> _pumpStats(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // 데이터는 이 테스트의 관심사가 아니다 — 탭 전환만 본다.
        categoriesProvider.overrideWith((ref) async => const []),
        rangeExpensesProvider.overrideWith((ref, key) async => const []),
        rangeSummaryProvider.overrideWith(
          (ref, range) async => RangeSummary(
            startDate: range.startDate,
            endDate: range.endDate,
          ),
        ),
        heatmapProvider.overrideWith((ref, range) async => const <HeatmapCell>[]),
        merchantSummaryProvider
            .overrideWith((ref, range) async => const <MerchantSummary>[]),
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
}

int _pageIndex(WidgetTester tester) {
  final pv = tester.widget<PageView>(find.byType(PageView));
  return (pv.controller!.page ?? pv.controller!.initialPage.toDouble()).round();
}

/// 칩이 선택 상태인지 — _StatsChipTab 은 active 일 때 글자를 semi 굵기로 그린다.
bool _chipSelected(WidgetTester tester, String label) {
  final texts = tester.widgetList<Text>(find.text(label));
  return texts.any((t) => t.style?.fontWeight == PFontWeight.semi);
}

void main() {
  testWidgets('좌우로 밀면 탭이 넘어간다', (tester) async {
    await _pumpStats(tester);
    expect(_pageIndex(tester), 0, reason: '처음엔 카테고리 탭');

    // 왼쪽으로 밀기 → 다음 탭(추이)
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(_pageIndex(tester), 1);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(_pageIndex(tester), 2, reason: '비교 탭까지');

    // 마지막에서 더 밀어도 넘어가지 않는다(순환 없음)
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(_pageIndex(tester), 2);

    // 오른쪽으로 밀기 → 이전 탭
    await tester.fling(find.byType(PageView), const Offset(400, 0), 1200);
    await tester.pumpAndSettle();
    expect(_pageIndex(tester), 1);
  });

  testWidgets('스와이프로 넘어가면 칩 선택 상태도 따라온다', (tester) async {
    await _pumpStats(tester);
    final l = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(_pageIndex(tester), 1);

    // 칩은 선택되면 글자가 semi 굵기로 바뀐다(_StatsChipTab). 본문만 넘어가고
    // 칩이 그대로면 사용자는 지금 어느 탭인지 알 수 없다.
    expect(_chipSelected(tester, l.statsTabTrend), isTrue, reason: '추이 칩이 선택돼야');
    expect(_chipSelected(tester, l.expCategory), isFalse,
        reason: '카테고리 칩은 풀려야');
  });

  testWidgets('칩을 누르면 본문도 같이 넘어간다', (tester) async {
    await _pumpStats(tester);
    final l = await AppLocalizations.delegate.load(const Locale('ko'));

    await tester.tap(find.text(l.statsTabCompare));
    await tester.pumpAndSettle();
    expect(_pageIndex(tester), 2);

    await tester.tap(find.text(l.expCategory).first);
    await tester.pumpAndSettle();
    expect(_pageIndex(tester), 0);
  });
}
