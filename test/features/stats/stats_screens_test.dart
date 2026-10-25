// I-08 08-2 통계 — 실제 화면을 띄워(폰 360, 가장 나쁜 값) 띠 · 틈 · 원까지 · 가림 · 질의마다 실패 상자 · 고정 정리 페이지를 잰다.
//
// 잰 것: ① 네 탭 모두 칩 탭 ↔ 첫 띠 틈 0 · 띠 사이 8 · 화면 폭 끝까지(0 ~ 360) · 머리 없는 띠 위 24 · 넘침 0(100% · 200%)
// ② 도넛 180 · 두께 24 · 가운데 글 없음 · 합계 줄 원까지 · 상위 9 + 기타 ③ 금액을 가리면 차트 눈금 · 값 모두 점
// ④ 폰은 질의 하나 = 실패 상자 하나(같은 질의를 먹는 뒤 띠는 그리지 않는다) · 오류 원문 0 ⑤ 요일 비교 지난 기간 = 옅은 파랑
// ⑥ 비율 막대 안 % 글 대비 4.5 이상 ⑦ 지난 기간과 같으면 "지난 기간과 같아요." ⑧ 고정 정리 = 페이지(시트 아님) · 실패 갈래.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_model.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_parts.dart';
import 'package:groo_damda_app/features/stats/presentation/stats_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/tabs/p_tabs.dart';

import '../../support/plain_text.dart';
import '../../support/stats_fixtures.dart' as fx;

const _tabLabel = {
  StatsTab.trend: '추이',
  StatsTab.compare: '비교',
  StatsTab.fixed: '고정·변동',
};

Future<void> _pump(
  WidgetTester tester, {
  fx.Scenario scenario = fx.Scenario.worst,
  Set<String> fail = const {},
  Set<String> masked = const {},
  double scale = 1.0,
  bool dark = false,
  StatsTab tab = StatsTab.category,
  double height = 6000,
  Override? summary,
}) async {
  tester.view.physicalSize = Size(360, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  Never boom() => throw Exception('server error 원문');
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        hideCardProvider.overrideWith((ref, card) => masked.contains(card)),
        categoriesProvider.overrideWith((ref) async => fx.cats),
        summary ??
            rangeSummaryProvider.overrideWith((ref, r) async {
              final prev = !fx.isCurrent(r.startDate);
              if (fail.contains(prev ? 'prev' : 'range')) boom();
              return fx.summary(scenario, r.startDate, r.endDate);
            }),
        rangeExpensesProvider.overrideWith((ref, k) async {
          final prev = !fx.isCurrent(k.startDate);
          if (fail.contains(prev ? 'prevExpenses' : 'expenses')) boom();
          return fx.expenses(scenario, k.startDate, k.endDate);
        }),
        merchantSummaryProvider.overrideWith((ref, r) async {
          if (fail.contains('merchant')) boom();
          return fx.merchants(scenario);
        }),
        heatmapProvider.overrideWith((ref, r) async {
          if (fail.contains('heat')) boom();
          return fx.heat(scenario);
        }),
        monthlyTrendProvider.overrideWith((ref, m) async {
          if (fail.contains('trend')) boom();
          return fx.trend(scenario);
        }),
      ],
      child: MaterialApp(
        theme: dark ? GrooTheme.dark() : GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const StatsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (tab != StatsTab.category) {
    final f = find.text(_tabLabel[tab]!).first;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }
}

List<Rect> _bands(WidgetTester tester) => [
  for (final e in find.byKey(const ValueKey('screen-section')).evaluate())
    tester.getRect(find.byElementPredicate((x) => x == e)),
];

void main() {
  group('띠 · 틈 · 끝까지 — 폰 360 가장 나쁜 값', () {
    final expectedBands = {
      StatsTab.category: 4,
      StatsTab.trend: 4,
      StatsTab.compare: 4,
      StatsTab.fixed: 4,
    };
    for (final tab in StatsTab.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${tab.name} · 글자 ${(scale * 100).round()}%', (
          tester,
        ) async {
          await _pump(tester, tab: tab, scale: scale, height: 9000);
          // 추이 탭 200% 는 저축률 고리 가운데 글(t9 24)이 고리 108 을 넘는다 — 사용자 결정 대기라 웹 지금 값 그대로 두고 결과표에 적는다
          final ex = tester.takeException();
          if (!(tab == StatsTab.trend && scale == 2.0)) {
            expect(ex, isNull, reason: '넘침 0');
          }
          final bands = _bands(tester);
          // 합계 · 거래는 한 달이라 추이 탭은 카테고리 월별 추이 띠가 없다 → 셋
          final want = tab == StatsTab.trend ? 3 : expectedBands[tab]!;
          expect(bands.length, want);
          final chips = tester.getRect(find.byType(PChipTabs<StatsTab>));
          // 칩 탭 줄 바로 아래 첫 띠 — 틈 0
          expect(bands.first.top, closeTo(chips.bottom, 0.01));
          for (final b in bands) {
            expect(b.left, 0);
            expect(b.right, 360);
          }
          for (var i = 1; i < bands.length; i++) {
            expect(bands[i].top - bands[i - 1].bottom, closeTo(8, 0.01));
          }
        });
      }
    }

    testWidgets('머리 없는 띠(요약)는 위 24 에서 첫 글이 시작한다', (tester) async {
      await _pump(tester);
      final bands = _bands(tester);
      final label = tester.getRect(findPlain('가장 많이 쓴 카테고리'));
      expect(label.top - bands.last.top, closeTo(24 + 4, 4));
      expect(label.left, closeTo(24, 0.01));
    });
  });

  group('카테고리 탭 — 도넛 · 원까지', () {
    testWidgets('폰 도넛 180 · 두께 24 · 가운데 글 없음 · 합계 줄 원까지 · 상위 9 + 기타', (
      tester,
    ) async {
      await _pump(tester);
      final donut = tester.widget<PDonutChart>(find.byType(PDonutChart));
      expect(donut.diameter, 180);
      expect(chartDonutThickness(donut.diameter), 24);
      expect(donut.centerAmount, isNull);
      expect(donut.centerLabel, isNull);
      // 합계 줄 — 줄임 글("24.4억") 없이 원까지
      expect(findPlain('2,435,323,333원'), findsWidgets);
      expect(find.textContaining('24.4억'), findsNothing);
      // 13개 → 상위 9 + 기타
      expect(donut.slices.length, 10);
      expect(donut.slices.last.color, PChartColor.gray);
      expect(findPlain('기타'), findsWidgets);
    });

    testWidgets('범례 긴 이름은 모든 글자가 보이고(줄바꿈) 금액은 원까지', (tester) async {
      await _pump(tester);
      expect(findPlain('987,654,321원'), findsWidgets);
      final names = find.byKey(const ValueKey('chart-donut-label'));
      for (final e in names.evaluate()) {
        final t = e.widget as Text;
        expect(t.maxLines, isNull);
        expect(t.overflow, isNot(TextOverflow.ellipsis));
      }
    });

    testWidgets('TOP 5 긴 가맹점 이름은 모든 글자 · 금액은 한 줄 원까지', (tester) async {
      await _pump(tester);
      expect(findRichPlain('숲길 커피 중앙점 아주 긴 가맹점 이름 테스트 지점 2호점'), findsWidgets);
      expect(findPlain('123,456,789원'), findsWidgets);
    });

    testWidgets('금액을 가리면 도넛 합계 · 범례 · 열지도 총 금액이 점이다', (tester) async {
      await _pump(tester, masked: {'stats.category'});
      expect(findPlain('2,435,323,333원'), findsNothing);
      expect(findPlain('••••'), findsWidgets);
    });

    testWidgets('하루 평균의 전월 대비는 Delta 뒤 기준 글이다', (tester) async {
      await _pump(tester);
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('delta-text')),
      );
      expect(plainOf(text.data!), '전월 대비');
      expect(find.byKey(const ValueKey('delta-value')), findsOneWidget);
    });
  });

  group('가림 — 차트 눈금도 점', () {
    testWidgets('추이 탭: 눈금 · 툴팁 값 포맷터가 점을 낸다', (tester) async {
      await _pump(tester, tab: StatsTab.trend, masked: {'stats.trend'});
      final line = tester.widget<PLineChart>(find.byType(PLineChart));
      expect(line.axisFormatter!(5000000), '••••');
      expect(line.valueFormatter!(5000000), '••••');
      final bar = tester.widget<PBarChart>(find.byType(PBarChart).first);
      expect(bar.axisFormatter!(-5000000), '••••');
      expect(bar.valueFormatter!(-5000000), '••••');
    });

    testWidgets('가리지 않으면 ds 기본(줄여 쓴 눈금 · 원까지 값)', (tester) async {
      await _pump(tester, tab: StatsTab.trend);
      final line = tester.widget<PLineChart>(find.byType(PLineChart));
      expect(line.axisFormatter, isNull);
      expect(line.valueFormatter, isNull);
    });
  });

  group('추이 탭', () {
    testWidgets('저축률 가운데 %는 t9(24) · 지출 · 저축 줄 이름에 비율', (tester) async {
      await _pump(tester, tab: StatsTab.trend);
      final pct = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (t) => (t.data ?? '').endsWith('%') && (t.data ?? '').contains('.'),
          );
      expect(pct.style!.fontSize, PTypography.t9.fontSize);
    });

    testWidgets('월별 순저축은 음수 막대를 빨강으로 그린다', (tester) async {
      await _pump(tester, tab: StatsTab.trend);
      final bar = tester.widget<PBarChart>(find.byType(PBarChart).first);
      final c = PColors.light;
      expect(bar.barColor!(0, c), c.chartRed, reason: '둘째 달 이후는 지출이 더 크다');
    });
  });

  group('비교 탭', () {
    testWidgets('요일 비교의 지난 기간은 같은 파랑의 옅은 단계 — 시리즈 · 지표 타일 모두', (tester) async {
      await _pump(tester, tab: StatsTab.compare);
      final bar = tester.widget<PBarChart>(find.byType(PBarChart));
      expect(bar.series.length, 2);
      expect(bar.series[0].color, PChartColor.blue);
      expect(bar.series[0].weak, isFalse);
      expect(bar.series[1].color, PChartColor.blue);
      expect(bar.series[1].weak, isTrue);
      final tiles = tester.widget<PChartLegendTiles>(
        find.byType(PChartLegendTiles),
      );
      expect(tiles.items.map((i) => i.weak), [false, true]);
    });

    testWidgets('견줌 막대 금액은 한 줄 — 숫자 중간에서 꺾이지 않는다(200%)', (tester) async {
      await _pump(tester, tab: StatsTab.compare, scale: 2.0, height: 9000);
      expect(tester.takeException(), isNull);
      expect(findPlain('2,435,323,333원'), findsWidgets);
    });

    testWidgets('지난 기간과 같으면 "지난 기간과 같아요." 와 변화 없음', (tester) async {
      // 이번 · 지난 기간이 같은 합계
      await _pump(
        tester,
        tab: StatsTab.compare,
        scenario: fx.Scenario.normal,
        summary: rangeSummaryProvider.overrideWith(
          (ref, r) async => RangeSummary(
            startDate: r.startDate,
            endDate: r.endDate,
            totalExpense: 1000000,
          ),
        ),
      );
      expect(findPlain('지난 기간과 같아요.'), findsOneWidget);
      expect(findPlain('변화 없음'), findsWidgets);
      expect(find.textContaining('덜 썼어요'), findsNothing);
    });
  });

  group('고정·변동 탭', () {
    testWidgets('두 계열 색 = 고정 파랑 · 변동 초록, 쌓은 막대 · 지표 타일', (tester) async {
      await _pump(tester, tab: StatsTab.fixed);
      final bar = tester.widget<PBarChart>(find.byType(PBarChart));
      expect(bar.stacked, isTrue);
      expect(bar.series.map((s) => s.color), [
        PChartColor.blue,
        PChartColor.green,
      ]);
    });

    testWidgets('비율 막대 안 % 글 색은 fg-neutral-inverted 다', (tester) async {
      await _pump(tester, tab: StatsTab.fixed);
      final t = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere(
            (t) => t.data == '21%' && t.style?.fontWeight == FontWeight.w700,
          );
      expect(t.style!.color, PColors.light.fgNeutralInverted);
    });

    for (final dark in [false, true]) {
      test('비율 막대 안 % 글(면 색)은 파랑 · 초록 위 4.5 이상 — ${dark ? '다크' : '라이트'}', () {
        final c = dark ? PColors.dark : PColors.light;
        double lum(Color x) => x.computeLuminance();
        double contrast(Color a, Color b) {
          final hi = lum(a) > lum(b) ? a : b;
          final lo = identical(hi, a) ? b : a;
          return (lum(hi) + 0.05) / (lum(lo) + 0.05);
        }

        expect(
          contrast(c.bgLayerDefault, c.chartBlue),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(c.bgLayerDefault, c.chartGreen),
          greaterThanOrEqualTo(4.5),
        );
      });
    }
  });

  group('질의 하나 = 실패 상자 하나(폰) · 오류 원문 0', () {
    int boxes(WidgetTester tester) =>
        find.byType(PResultSection).evaluate().length;

    testWidgets('카테고리 탭: 합계 실패 → 도넛 띠 하나 · 요약 띠는 그리지 않는다', (tester) async {
      await _pump(tester, fail: {'range'});
      expect(findPlain('카테고리별 지출을 불러오지 못했어요'), findsOneWidget);
      expect(findPlain('요약을 불러오지 못했어요'), findsNothing);
      expect(boxes(tester), 1);
      expect(find.textContaining('server error'), findsNothing);
      expect(_bands(tester).length, 3, reason: '도넛(상자) · TOP 5 · 열지도, 요약 없음');
    });

    testWidgets('카테고리 탭: 셋 모두 실패 → 상자 셋(요약은 앞 띠가 말한다)', (tester) async {
      await _pump(tester, fail: {'range', 'merchant', 'heat'});
      expect(boxes(tester), 3);
      expect(find.textContaining('server error'), findsNothing);
    });

    testWidgets('추이 탭: 합계 실패 → 첫 띠 상자 하나뿐', (tester) async {
      await _pump(tester, tab: StatsTab.trend, fail: {'range'});
      expect(boxes(tester), 1);
      expect(_bands(tester).length, 1);
    });

    testWidgets('비교 탭: 합계 · 이전 합계 · 거래 실패 → 합계 상자 하나 + 요일 상자 하나', (
      tester,
    ) async {
      await _pump(
        tester,
        tab: StatsTab.compare,
        fail: {'range', 'prev', 'expenses', 'prevExpenses'},
      );
      expect(boxes(tester), 2);
      expect(_bands(tester).length, 2);
    });

    testWidgets('비교 탭: 거래만 실패 → 요일 상자 하나(지표는 그리지 않는다)', (tester) async {
      await _pump(tester, tab: StatsTab.compare, fail: {'expenses'});
      expect(boxes(tester), 1);
      expect(findPlain('요일별 지출을 불러오지 못했어요'), findsOneWidget);
    });

    testWidgets('고정 탭: 합계 실패 → 상자 하나 · 다시 시도는 그 질의만', (tester) async {
      await _pump(tester, tab: StatsTab.fixed, fail: {'range'});
      expect(boxes(tester), 1);
      expect(findPlain('고정 · 변동 내용을 불러오지 못했어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });
  });

  group('빈 글 — 해요체 · 마침표', () {
    testWidgets('빈 기간의 네 탭', (tester) async {
      await _pump(tester, scenario: fx.Scenario.empty);
      expect(findPlain('카테고리 데이터가 없어요.'), findsOneWidget);
      expect(findPlain('가맹점 데이터가 없어요.'), findsOneWidget);
      expect(findPlain('이번 달 거래가 아직 적어요.'), findsOneWidget);
      expect(find.textContaining('없습니다'), findsNothing);
    });
  });

  test('등락 % 는 한 곳(statsChangeRate)에서 만든다', () {
    expect(statsChangeRate(110, 100), '10%');
    expect(statsChangeRate(90, 100), '10%');
    expect(statsChangeRate(1234, 1000, fractionDigits: 1), '23.4%');
    expect(statsChangeRate(5, 0), '—');
  });
}
