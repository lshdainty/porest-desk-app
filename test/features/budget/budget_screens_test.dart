// I-08-1 — 예산 · 예산 설정 · 저축 목표를 가장 나쁜 값(긴 이름 · 큰 금액)으로 실제 화면을 띄워 잰다.
//
// 잰 것: 넘침 오류 0 · 이름 말줄임 0 · 금액 원까지 · 띠 셋 사이 8 · 막대 색(넘침 critical, 경고 구간 색 없음) ·
// 카드 · 줄 사이 선 없음 · 저축 목표 막대 한 색 · 금액 가림.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/settings/settings_notifier.dart';
import 'package:groo_damda_app/features/budget/application/budget_providers.dart';
import 'package:groo_damda_app/features/budget/domain/budget.dart';
import 'package:groo_damda_app/features/budget/domain/budget_compliance.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_screen.dart';
import 'package:groo_damda_app/features/budget/presentation/budget_settings_screen.dart';
import 'package:groo_damda_app/features/expense/application/expense_providers.dart';
import 'package:groo_damda_app/features/expense/domain/expense_category.dart';
import 'package:groo_damda_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:groo_damda_app/features/saving_goal/domain/saving_goal.dart';
import 'package:groo_damda_app/features/saving_goal/presentation/saving_goal_screen.dart';
import 'package:groo_damda_app/features/stats/application/stats_providers.dart';
import 'package:groo_damda_app/features/stats/domain/stats_models.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/card/p_card.dart';
import 'package:groo_damda_app/shared/ds/progress/p_progress.dart';
import 'package:groo_damda_app/shared/ds/screen_band/p_screen_band.dart';

const _longName = '주거·관리비·공과금·통신 요금 자동이체 묶음';
const _goalName =
    '아주 오래 걸리는 목표 이름 테스트 '
    '가나다라마바사아자차카타파하 '
    '가나다라마바사';

final _cats = [
  const ExpenseCategory(
    rowId: 7,
    categoryName: _longName,
    expenseType: 'EXPENSE',
  ),
  const ExpenseCategory(rowId: 8, categoryName: '식비', expenseType: 'EXPENSE'),
];

List<Budget> _budgets(int y, int m) => [
  Budget(rowId: 1, budgetAmount: 100000000, budgetYear: y, budgetMonth: m),
  Budget(
    rowId: 2,
    categoryRowId: 7,
    budgetAmount: 800000,
    budgetYear: y,
    budgetMonth: m,
  ),
  Budget(
    rowId: 3,
    categoryRowId: 8,
    budgetAmount: 1000000,
    budgetYear: y,
    budgetMonth: m,
  ),
];

RangeSummary _summary(String s, String e) => RangeSummary(
  startDate: s,
  endDate: e,
  totalExpense: 12345678901,
  categoryBreakdown: const [
    CategoryBreakdown(
      categoryRowId: 7,
      expenseType: 'EXPENSE',
      totalAmount: 1234567890,
    ),
    CategoryBreakdown(
      categoryRowId: 8,
      expenseType: 'EXPENSE',
      totalAmount: 900000,
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  double textScale = 1.0,
  bool masked = false,
  Brightness brightness = Brightness.light,
  Future<List<Budget>> Function(BudgetMonthKey key)? budgets,
  List<BudgetComplianceMonth>? compliance,
}) async {
  tester.view.physicalSize = const Size(360, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        hideCardProvider.overrideWith((ref, card) => masked),
        monthBudgetsProvider.overrideWith(
          (ref, key) => budgets != null
              ? budgets(key)
              : Future.value(_budgets(key.year, key.month)),
        ),
        rangeSummaryProvider.overrideWith(
          (ref, r) async => _summary(r.startDate, r.endDate),
        ),
        categoriesProvider.overrideWith((ref) async => _cats),
        budgetComplianceProvider.overrideWith(
          (ref, months) async =>
              compliance ??
              const [
                BudgetComplianceMonth(
                  year: 2026,
                  month: 9,
                  totalLimit: 100,
                  totalSpent: 150,
                  compliancePercent: 150,
                ),
              ],
        ),
        ...overrides,
      ],
      child: MaterialApp(
        theme: brightness == Brightness.light
            ? GrooTheme.light()
            : GrooTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// 위젯 트리의 모든 글(읽는 이름 포함)에서 [pattern] 이 들어간 것이 있는가.
bool _hasText(WidgetTester tester, String pattern) => tester
    .widgetList<Text>(find.byType(Text))
    .any((t) => (t.semanticsLabel ?? t.data ?? '').contains(pattern));

List<PProgressBar> _bars(WidgetTester tester) =>
    tester.widgetList<PProgressBar>(find.byType(PProgressBar)).toList();

Color _fillOf(WidgetTester tester, int index) {
  final bar = find.byType(PProgressBar).at(index);
  final fill = find.descendant(
    of: bar,
    matching: find.byKey(const ValueKey('progress-fill')),
  );
  final box = tester.widget<Container>(fill);
  return (box.decoration! as BoxDecoration).color!;
}

void main() {
  group('예산', () {
    for (final scale in [1.0, 2.0]) {
      testWidgets('띠 셋 · 원까지 · 말줄임 0 · 넘침 0 (글자 ${scale * 100}%)', (
        tester,
      ) async {
        await _pump(tester, const BudgetScreen(), textScale: scale);
        expect(tester.takeException(), isNull);

        // 띠 셋 — 총 예산·페이스 / 현황·목록 / 이행률
        expect(find.byKey(const ValueKey('screen-section')), findsNWidgets(3));
        // 큰 금액은 원까지, 말줄임 없음
        expect(_hasText(tester, '12,345,678,901원'), isTrue);
        expect(_hasText(tester, '100,000,000원'), isTrue);
        // 긴 카테고리 이름은 모든 글자가 줄바꿈으로 보인다
        final name = tester
            .widgetList<Text>(find.byType(Text))
            .firstWhere((t) => (t.data ?? '').replaceAll('⁠', '') == _longName);
        expect(name.overflow, isNot(TextOverflow.ellipsis));
        expect(name.maxLines, isNull);
        // 줄 금액에도 원이 붙는다
        expect(_hasText(tester, '1,234,567,890원'), isTrue);
        expect(_hasText(tester, '/ 800,000원'), isTrue);
      });
    }

    testWidgets('띠 사이 8 둘 — 마지막 띠 아래에 빈 띠를 두지 않는다', (tester) async {
      await _pump(tester, const BudgetScreen());
      final bands = find.byKey(const ValueKey('screen-section'));
      final r0 = tester.getRect(bands.at(0));
      final r1 = tester.getRect(bands.at(1));
      final r2 = tester.getRect(bands.at(2));
      expect(r1.top - r0.bottom, kScreenBandGap);
      expect(r2.top - r1.bottom, kScreenBandGap);
      // 머리(화면 맨 위)와 첫 띠 사이 틈 0
      expect(r0.top, 0);
    });

    testWidgets('막대 — 넘치면 위험 색, 85~100% 경고 색 없음, 테두리 상자 0', (tester) async {
      await _pump(tester, const BudgetScreen());
      final c = tester.element(find.byType(BudgetScreen)).colors;
      // 총 예산 막대(첫째) = 12,345,678,901 / 100,000,000 → 넘침
      expect(_fillOf(tester, 0), c.fgCritical);
      // 식비 막대(90,000/1,000,000 = 90%) = 경고 구간이어도 브랜드 색
      final bars = _bars(tester);
      expect(bars.length, greaterThanOrEqualTo(4));
      expect(_fillOf(tester, bars.length - 1), c.fgBrand);
      // 띠 안 카드(테두리 상자) 0
      expect(find.byType(PCard), findsNothing);
    });

    testWidgets('금액 가림 — 점만 남고 원 · 부호도 사라진다', (tester) async {
      await _pump(tester, const BudgetScreen(), masked: true);
      expect(_hasText(tester, '12,345,678,901'), isFalse);
      expect(_hasText(tester, '••••'), isTrue);
    });

    testWidgets('실패는 0원이 아니라 그 자리의 다시 시도 — 오류 원문 0', (tester) async {
      await _pump(
        tester,
        const BudgetScreen(),
        budgets: (key) async => throw Exception('SECRET-RAW-ERROR'),
      );
      expect(_hasText(tester, '다시 시도'), isTrue);
      expect(_hasText(tester, 'SECRET-RAW-ERROR'), isFalse);
      expect(_hasText(tester, '0원'), isFalse);
    });

    testWidgets('이번 달 예산이 없으면 빈 결과 + 예산 설정 버튼, 한도 있는 달이 없으면 이행률도 없다', (
      tester,
    ) async {
      await _pump(
        tester,
        const BudgetScreen(),
        budgets: (key) async => const [],
        compliance: const [
          BudgetComplianceMonth(
            year: 2026,
            month: 9,
            totalLimit: 0,
            totalSpent: 0,
            compliancePercent: 0,
          ),
        ],
      );
      expect(find.byKey(const ValueKey('screen-section')), findsOneWidget);
      expect(_hasText(tester, '예산 설정'), isTrue);
      expect(_hasText(tester, '최근 6개월'), isFalse);
    });
  });

  group('예산 설정', () {
    testWidgets('글자 200% 다크 — 넘침 0', (tester) async {
      await _pump(
        tester,
        const BudgetSettingsScreen(),
        textScale: 2.0,
        brightness: Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('흰 면 하나 — 카드 · 줄 사이 선 0, 총 예산 막대 넘침 위험 색, 원까지', (tester) async {
      await _pump(tester, const BudgetSettingsScreen());
      expect(tester.takeException(), isNull);
      expect(find.byType(PCard), findsNothing);
      expect(find.byType(Divider), findsNothing);
      final c = tester.element(find.byType(BudgetSettingsScreen)).colors;
      expect(_fillOf(tester, 0), c.fgCritical, reason: '써서 넘치면 파랑이 아니다');
      expect(_hasText(tester, '12,345,678,901원'), isTrue);
      // 할당 가능: 음수 U+2212
      expect(_hasText(tester, '+98,200,000원'), isTrue);
      expect(_hasText(tester, _longName.substring(0, 6)), isTrue);
    });
  });

  group('저축 목표', () {
    final goals = [
      const SavingGoal(
        rowId: 1,
        title: _goalName,
        targetAmount: 10000000000,
        currentAmount: 2283000000,
        color: '#ef4444',
        isAchieved: 'N',
      ),
      const SavingGoal(
        rowId: 2,
        title: '비상금',
        targetAmount: 1000000,
        currentAmount: 1000000,
        color: '#3b82f6',
        isAchieved: 'Y',
      ),
    ];

    testWidgets('막대는 목표 색이 달라도 한 색 · 이름 말줄임 0 · 원까지 · 카드 0', (tester) async {
      await _pump(
        tester,
        const SavingGoalScreen(),
        overrides: [savingGoalListProvider.overrideWith((ref) async => goals)],
      );
      expect(tester.takeException(), isNull);
      final c = tester.element(find.byType(SavingGoalScreen)).colors;
      expect(_fillOf(tester, 0), c.fgBrand);
      expect(_fillOf(tester, 1), c.fgBrand);
      expect(find.byType(PCard), findsNothing);
      expect(find.byType(Divider), findsNothing);
      expect(_hasText(tester, '2,283,000,000원'), isTrue);
      expect(_hasText(tester, '10,000,000,000원'), isTrue);
      expect(_hasText(tester, '달성'), isTrue);
    });

    testWidgets('글자 200% 다크 — 넘침 0', (tester) async {
      await _pump(
        tester,
        const SavingGoalScreen(),
        textScale: 2.0,
        brightness: Brightness.dark,
        overrides: [savingGoalListProvider.overrideWith((ref) async => goals)],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('금액 가리기 — 금액은 점, % 는 보인다', (tester) async {
      await _pump(
        tester,
        const SavingGoalScreen(),
        masked: true,
        overrides: [savingGoalListProvider.overrideWith((ref) async => goals)],
      );
      expect(_hasText(tester, '2,283,000,000'), isFalse);
      expect(_hasText(tester, '••••'), isTrue);
      expect(_hasText(tester, '23%'), isTrue);
    });

    testWidgets('실패는 다시 시도 — 오류 원문 0', (tester) async {
      await _pump(
        tester,
        const SavingGoalScreen(),
        overrides: [
          savingGoalListProvider.overrideWith(
            (ref) async => throw Exception('SECRET-RAW-ERROR'),
          ),
        ],
      );
      expect(_hasText(tester, '다시 시도'), isTrue);
      expect(_hasText(tester, 'SECRET-RAW-ERROR'), isFalse);
    });
  });
}
