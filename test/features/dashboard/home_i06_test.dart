// I-06 홈 — 실제 화면을 띄워 지시서 값을 잰다(폰 360, 가장 나쁜 값).
//
// 띠 넷 · 틈(0 · 8) · 구역 머리(9 · 10) · 순자산(11 ~ 15) · 이번 달(16) · 도넛(18 ~ 21) · 예산(22) ·
// 일정 · 할 일(24 · 25) · 오늘 쓴 돈(27 · 28) · 실패(33).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/env.dart';
import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/hide_amounts_cards.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/asset/application/asset_providers.dart';
import 'package:groo_damda_app/features/asset/domain/asset_summary.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/features/dashboard/domain/dashboard_summary.dart';
import 'package:groo_damda_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/chart/p_chart.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';
import '../../support/plain_text.dart';

String _monthStart() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-01';
}

String _todayKey() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
}

const _longCat = '카페·간식·디저트 모임 지출 항목';

DashboardSummary _dash({
  int events = 3,
  int todos = 3,
  int overdue = 23,
}) => DashboardSummary.fromJson({
  'todoSummary': {'overDueCount': overdue},
  'upcomingEvents': [
    for (var i = 0; i < events; i++)
      {
        'rowId': i,
        'title': i == 0
            ? '분기 회고 · 다음 분기 목표 정리 회의 — 팀 전원 참석, 발표 자료는 전날 오후까지 공유 폴더에 올려 두기'
            : '치과 정기 검진 $i',
        'color': '#2c70bf',
        'daysUntil': i == 0 ? 0 : (i == 1 ? 1 : 12),
      },
  ],
  'recentTodos': [
    for (var i = 0; i < todos; i++)
      {
        'rowId': i,
        'title': '자동차 보험 갱신 서류 챙기기 — 만기 전에 비교 견적 세 군데 받아 두기 $i',
        'status': i == 1 ? 'COMPLETED' : 'PENDING',
        'dueDate': i == 0 ? '2020-01-02' : '2999-12-30',
      },
  ],
});

RangeSummary _range(String start, String end, {int categories = 5}) =>
    RangeSummary(
      startDate: start,
      endDate: end,
      totalIncome: start == _monthStart() ? 1350000000 : 0,
      totalExpense: start == _monthStart() ? 3912345678 : 3000000000,
      categoryBreakdown: [
        for (var i = 0; i < categories; i++)
          CategoryBreakdown(
            categoryRowId: i + 1,
            categoryName: i == 0 ? _longCat : '분류 $i',
            expenseType: 'EXPENSE',
            totalAmount: 987654321 - i * 1000,
          ),
      ],
    );

class _H {
  _H(this.tester);
  final WidgetTester tester;
}

Future<void> _pump(
  WidgetTester tester, {
  double width = 360,
  double textScale = 1,
  AssetSummary? summary,
  Object? summaryError,
  DashboardSummary? dash,
  int categories = 5,
  List<Budget>? budgets,
  List<Expense>? today,
  Object? rangeError,
  Set<String> hidden = const {},
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = Size(width * 2, 4000 * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final overrides = [
    assetSummaryProvider.overrideWith((ref, key) async {
      if (summaryError != null) throw summaryError;
      return summary ??
          const AssetSummary(
            netWorth: 98765432100,
            totalAssets: 99998888777,
            totalDebt: 1233456677,
            lastMonthNetWorth: 90000000000,
            changePercent: 9.74,
          );
    }),
    rangeSummaryProvider.overrideWith((ref, r) async {
      if (rangeError != null) throw rangeError;
      return _range(r.startDate, r.endDate, categories: categories);
    }),
    monthExpensesProvider.overrideWith((ref, key) async => today ?? const []),
    categoriesProvider.overrideWith(
      (ref) async => [
        for (var i = 0; i < categories; i++)
          ExpenseCategory(
            rowId: i + 1,
            categoryName: 'c$i',
            expenseType: 'EXPENSE',
          ),
      ],
    ),
    monthBudgetsProvider.overrideWith(
      (ref, key) async =>
          budgets ??
          [
            Budget(
              rowId: 1,
              budgetAmount: 3000000,
              budgetYear: key.year,
              budgetMonth: key.month,
            ),
            Budget(
              rowId: 2,
              categoryRowId: 1,
              categoryName: _longCat,
              budgetAmount: 1000000000,
              budgetYear: key.year,
              budgetMonth: key.month,
            ),
          ],
    ),
    dashboardSummaryProvider.overrideWith((ref) async => dash ?? _dash()),
  ];
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: overrides,
      child: MaterialApp(
        theme: brightness == Brightness.dark
            ? GrooTheme.dark()
            : GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const Scaffold(body: DashboardScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  if (hidden.isNotEmpty) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen)),
    );
    await container.read(settingsProvider.notifier).hideCards(hidden);
    await tester.pump();
  }
}

/// 순자산 띠는 브랜드 채움 면(`home-hero-face`)이고 나머지는 흰 구역 띠(`screen-section`)다.
Finder get _whiteBands => find.byKey(const ValueKey('screen-section'));
int _bandCount() => 1 + _whiteBands.evaluate().length;
List<Rect> _bandRects(WidgetTester t) => [
  t.getRect(find.byKey(const ValueKey('home-hero-face'))),
  for (var i = 0; i < _whiteBands.evaluate().length; i++)
    t.getRect(_whiteBands.at(i)),
];

Expense _tx(int id, {String type = 'EXPENSE', int amount = 1234567890}) =>
    Expense(
      rowId: id,
      expenseType: type,
      amount: amount,
      merchant: '아주 길고 긴 이름의 온라인 종합 쇼핑몰 본점 (서울 중앙 물류센터 직영)',
      categoryName: _longCat,
      assetName: '아주 길게 지은 통장 별칭 — 생활비 · 비상금 · 공과금 겸용 통장',
      expenseDate: '${_todayKey()}T00:00:00',
    );

void main() {
  group('띠 넷 — 1A · 5 · 6 · 8', () {
    testWidgets('띠 넷 · 사이 8 셋 · 머리 아래 틈 0 · 마지막 띠 아래 8 없음', (tester) async {
      await _pump(tester, today: [_tx(1)]);
      expect(_bandCount(), 4);
      final rects = _bandRects(tester);
      final top = tester.getRect(find.byType(DashboardScreen)).top;
      // 테스트 빌드는 dev 라 배지 줄(위 8 + 20 + 아래 8)이 순자산 위에 선다 — 운영(prod)이면 틈 0
      final devRow = Env.appEnv != 'prod' ? 36.0 : 0.0;
      expect(
        rects.first.top - top,
        devRow,
        reason: '머리 바로 아래 첫 띠 — 틈 없음(배지 줄 말고는)',
      );
      for (var i = 0; i < 3; i++) {
        expect(rects[i + 1].top - rects[i].bottom, 8, reason: '띠 사이 8');
      }
    });

    testWidgets('일정 · 할 일이 비는 네 갈래 — 띠 수 4 · 4 · 4 · 3', (tester) async {
      await _pump(tester, dash: _dash());
      expect(_bandCount(), 4);
      await _pump(tester, dash: _dash(todos: 0));
      expect(_bandCount(), 4);
      await _pump(tester, dash: _dash(events: 0));
      expect(_bandCount(), 4);
      await _pump(tester, dash: _dash(events: 0, todos: 0));
      expect(_bandCount(), 3, reason: '둘 다 비면 띠 ③ 자체가 없다');
      final rects = _bandRects(tester);
      for (var i = 0; i < rects.length - 1; i++) {
        expect(rects[i + 1].top - rects[i].bottom, 8, reason: '빈 띠 · 겹친 틈 없음');
      }
    });

    testWidgets('띠 ② 구역 사이 48 · 띠 위 24 · 구역 머리 제목 t5 · 700', (tester) async {
      await _pump(tester);
      final headers = find.byKey(const ValueKey('card-header'));
      // 순자산 띠는 머리가 없다 — 가계부 · 카테고리 · 예산 · 일정 · 할 일 · 오늘 쓴 돈
      expect(headers, findsNWidgets(6));
      final band2 = _bandRects(tester)[1];
      expect(
        tester.getRect(find.byKey(const ValueKey('card-title')).first).top -
            band2.top,
        24,
        reason: '띠 맨 위 = 첫 머리 위 24',
      );
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('card-title')).first,
      );
      expect(title.style?.fontSize, 16);
      expect(title.style?.fontWeight, FontWeight.w700);
    });
  });

  group('구역 머리 — 9 · 10', () {
    testWidgets('동작 "전체 보기"(이름 "{제목} 전체 보기") · 앞 아이콘 0 · 덧붙임이 heading 밖', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      expect(find.text('전체 보기'), findsNWidgets(5));
      expect(find.bySemanticsLabel('카테고리 전체 보기'), findsOneWidget);
      expect(find.bySemanticsLabel('최근 할 일 전체 보기'), findsOneWidget);
      // 연체 배지는 제목 줄에 붙고 heading 노드 밖이다
      final badge = find.widgetWithText(PBadge, '연체 23건');
      expect(badge, findsOneWidget);
      expect(
        find.ancestor(
          of: badge,
          matching: find.byWidgetPredicate(
            (w) => w is Semantics && w.properties.header == true,
          ),
        ),
        findsNothing,
      );
      // 일정 · 할 일 머리에 앞 아이콘이 없다
      expect(find.byIcon(LucideIcons.calendarClock), findsNothing);
      expect(find.byIcon(LucideIcons.squareCheckBig), findsNothing);
      handle.dispose();
    });
  });

  group('순자산 — 11 ~ 15', () {
    testWidgets('금액 · 원 같은 줄 · 라벨 불투명 · 눈 40 · 이름 · 토글 아님', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      expect(findPlain('98,765,432,100원'), findsOneWidget);
      final amount = tester.widget<Text>(
        find.byKey(const ValueKey('card-hero-amount')),
      );
      expect(amount.style?.fontSize, 32);
      expect(amount.style?.fontWeight, FontWeight.w700);
      final label = tester.widget<Text>(
        find.byKey(const ValueKey('card-hero-label')),
      );
      expect(label.style?.color?.a, 1.0, reason: '흐리게 두지 않는다');
      // 눈
      final eye = find.byKey(const ValueKey('home-hero-eye'));
      expect(tester.getSize(eye), const Size(40, 40));
      final node = tester.getSemantics(find.bySemanticsLabel('금액 가리기 설정'));
      expect(
        node.flagsCollection.isToggled.toBoolOrNull(),
        isNull,
        reason: '토글이 아니다',
      );
      expect(find.byIcon(LucideIcons.eye), findsOneWidget);
      // 두 칸 — 원까지, 부채는 U+2212
      expect(findPlain('99,998,888,777원'), findsOneWidget);
      expect(findPlain('−1,233,456,677원'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('가리면 눈 꺼짐 아이콘 · 금액 ••••••', (tester) async {
      await _pump(tester, hidden: {'home.netWorth'});
      expect(find.byIcon(LucideIcons.eyeOff), findsOneWidget);
      expect(findPlain('98,765,432,100원'), findsNothing);
    });

    testWidgets('지난달 기록 없음(14) — 증감 대신 글, ▲ 없음', (tester) async {
      await _pump(
        tester,
        summary: const AssetSummary(netWorth: 5000000, lastMonthNetWorth: 0),
      );
      expect(findPlain('지난달 기록 없음'), findsOneWidget);
      expect(find.byType(PDelta), findsNothing);
    });

    testWidgets('360 · 200% 넘침 없음', (tester) async {
      await _pump(tester, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('이번 달 가계부 — 16', () {
    testWidgets('수입 · 지출 줄 원까지 · 수입 brand · 지출 neutral · 안내 % 색 없음', (
      tester,
    ) async {
      await _pump(tester);
      final income = tester.widget<Text>(findPlain('+1,350,000,000원'));
      expect(income.style?.color, PColors.light.fgBrand);
      final expense = tester.widget<Text>(findPlain('−3,912,345,678원'));
      expect(expense.style?.color, PColors.light.fgNeutral);
      // 안내 문장의 % 는 fg-neutral · 700(색으로 좋고 나쁨을 말하지 않는다)
      final note = tester.widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().startsWith('하루 평균'),
        ),
      );
      final spans = <TextSpan>[];
      note.text.visitChildren((s) {
        if (s is TextSpan) spans.add(s);
        return true;
      });
      final pct = spans.firstWhere((s) => (s.text ?? '').endsWith('%'));
      expect(pct.style?.color, PColors.light.fgNeutral);
      expect(pct.style?.fontWeight, FontWeight.w700);
    });
  });

  group('카테고리 도넛 — 18 ~ 21', () {
    testWidgets('조각 10(기타 회색) · 가운데 글 없음 · 합계 줄 원까지 · 범례 말줄임 0', (
      tester,
    ) async {
      await _pump(tester, categories: 11);
      final donut = tester.widget<PDonutChart>(find.byType(PDonutChart));
      expect(donut.slices, hasLength(10));
      expect(donut.slices.last.label, '기타');
      expect(donut.slices.last.color, PChartColor.gray);
      expect(donut.centerAmount, isNull, reason: '폰은 가운데 글을 그리지 않는다');
      expect(donut.diameter, 120);
      // 합계 줄(목록 위 한 줄)
      expect(find.text('이번 달 지출'), findsOneWidget);
      // 범례 이름은 줄을 바꾼다 — 말줄임 · 줄 수 제한 없음
      final names = tester.widgetList<Text>(
        find.byKey(const ValueKey('chart-donut-label')),
      );
      for (final t in names) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
        expect(t.maxLines, isNull);
      }
      expect(find.text(_longCat), findsOneWidget, reason: '긴 이름이 모든 글자 보인다');
    });

    testWidgets('가리면 합계 · 범례 금액 ••••', (tester) async {
      await _pump(tester, hidden: {'home.categoryDonut'});
      final legend = tester.widgetList<Text>(
        find.byKey(const ValueKey('chart-donut-amount')),
      );
      expect(legend, isNotEmpty);
      for (final t in legend) {
        expect(t.data, '••••');
      }
    });

    testWidgets('200% 에서도 넘침 없음 · 범례 % · 금액이 이름 아래로', (tester) async {
      await _pump(tester, textScale: 2, categories: 5);
      expect(tester.takeException(), isNull);
    });

    testWidgets('데이터가 없으면 "이번 달 지출이 없어요"', (tester) async {
      await _pump(tester, categories: 0);
      expect(findPlain('이번 달 지출이 없어요'), findsOneWidget);
    });
  });

  group('예산 — 22', () {
    testWidgets('Progress 줄 · 이름 "{이름} 예산" · 타일 0 · 초과는 fg-critical', (
      tester,
    ) async {
      await _pump(tester);
      final bars = tester.widgetList<PProgress>(find.byType(PProgress));
      expect(bars, hasLength(2));
      expect(bars.first.label, '전체 예산');
      expect(bars.last.label, 'c0 예산', reason: '카테고리 이름 + 예산');
      // 전체 예산은 넘쳤다(3,912,345,678 > 3,000,000)
      expect(find.textContaining('초과'), findsWidgets);
      expect(find.byType(PListTile), findsNothing, reason: '카테고리 타일을 뺀다');
    });

    testWidgets('85 ~ 100% 는 경고 색이 없다 — 채움 fg-brand', (tester) async {
      final now = DateTime.now();
      await _pump(
        tester,
        budgets: [
          Budget(
            rowId: 1,
            categoryRowId: 1,
            budgetAmount: 1000000000,
            budgetYear: now.year,
            budgetMonth: now.month,
          ),
        ],
      );
      // 987,654,321 / 1,000,000,000 = 99%
      final fill = tester.widget<Container>(
        find.byKey(const ValueKey('progress-fill')),
      );
      expect((fill.decoration! as BoxDecoration).color, PColors.light.fgBrand);
    });

    testWidgets('빈 예산 글', (tester) async {
      await _pump(tester, budgets: const []);
      expect(findPlain('등록된 예산이 없어요'), findsOneWidget);
    });

    testWidgets('가림 시 금액 줄 · 초과 글 · 막대 이름이 ••••', (tester) async {
      await _pump(tester, hidden: {'home.budget'});
      final texts = find.descendant(
        of: find.byType(PProgress),
        matching: find.byType(Text),
      );
      for (final t in tester.widgetList<Text>(texts)) {
        expect(plainOf(t.data ?? ''), isNot(contains('987,654,321')));
        expect(plainOf(t.data ?? ''), isNot(contains('3,912,345,678')));
      }
      expect(
        tester
            .widgetList<PProgress>(find.byType(PProgress))
            .every((p) => p.formatValue!(1) == '••••'),
        isTrue,
      );
    });
  });

  group('일정 · 할 일 — 24 · 25', () {
    testWidgets('긴 제목 말줄임 0 · 두 줄을 넘으면 위 맞춤 · 뒤 값 글자 · 사흘 안 critical', (
      tester,
    ) async {
      await _pump(tester);
      final rows = tester.widgetList<PListButtonItem>(
        find.byType(PListButtonItem),
      );
      // 일정 셋 + 할 일 셋
      expect(rows, hasLength(6));
      for (final r in rows) {
        expect(r.align, PListAlign.top, reason: '긴 제목이 있어 목록이 위 맞춤');
      }
      final titles = tester.widgetList<Text>(
        find.byKey(const ValueKey('plist-title')),
      );
      for (final t in titles) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
        expect(t.maxLines, isNull);
      }
      final today = tester.widget<Text>(find.text('오늘'));
      expect(today.style?.color, PColors.light.fgCritical);
      final far = tester.widget<Text>(find.text('D-12').first);
      expect(far.style?.color, isNull, reason: '사흘 밖은 값 글자 기본색');
    });

    testWidgets('완료 할 일은 취소선', (tester) async {
      await _pump(tester);
      final done = tester
          .widgetList<PListButtonItem>(find.byType(PListButtonItem))
          .where((r) => r.titleStrike);
      expect(done, hasLength(1));
    });
  });

  group('오늘 쓴 돈 · 거래 줄 — 27 · 28', () {
    testWidgets('가맹점 말줄임 0 · 금액 쉼표 뒤 줄바꿈 · 수입만 brand', (tester) async {
      await _pump(
        tester,
        today: [
          _tx(1),
          _tx(2, type: 'INCOME', amount: 150000),
        ],
      );
      final titles = tester.widgetList<Text>(
        find.byKey(const ValueKey('plist-title')),
      );
      expect(titles, isNotEmpty);
      for (final t in titles) {
        expect(t.overflow, isNot(TextOverflow.ellipsis));
        expect(t.maxLines, isNull);
      }
      final exp = tester.widget<Text>(findPlain('−1,234,567,890원').last);
      expect(exp.style?.color, PColors.light.fgNeutral);
      final inc = tester.widget<Text>(findPlain('+150,000원'));
      expect(inc.style?.color, PColors.light.fgBrand);
      // 머리 오늘 합계 = 지출만(수입은 오늘 쓴 돈이 아니다)
      expect(findPlain('−1,234,567,890원'), findsNWidgets(2));
    });

    testWidgets('home.todaySpend 만 가리면 머리 합계 · 줄 금액 모두 ••••', (tester) async {
      await _pump(tester, today: [_tx(1)], hidden: {'home.todaySpend'});
      expect(findPlainContaining('1,234,567,890'), findsNothing);
    });

    testWidgets('ledger.txList 만 가려도 홈 줄 금액은 보인다(앱 회귀)', (tester) async {
      await _pump(tester, today: [_tx(1)], hidden: {'ledger.txList'});
      expect(findPlain('−1,234,567,890원'), findsNWidgets(2));
    });
  });

  group('실패 — 33', () {
    testWidgets('기간 합계 실패 → 가계부 · 카테고리 · 예산만 실패, 0원 없음, 다시 시도', (tester) async {
      await _pump(tester, rangeError: Exception('x'));
      expect(find.byType(PResultSection), findsNWidgets(3));
      expect(findPlain('0원'), findsNothing, reason: '조용한 0원이 없다');
      // 순자산 · 일정 · 오늘 쓴 돈은 그대로
      expect(findPlain('98,765,432,100원'), findsOneWidget);
      expect(find.text('오늘'), findsOneWidget);
    });

    testWidgets('순자산 실패 → 그 구역만 실패', (tester) async {
      await _pump(tester, summaryError: Exception('x'));
      expect(find.byType(PResultSection), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(findPlain('0원'), findsNothing);
    });
  });
}
