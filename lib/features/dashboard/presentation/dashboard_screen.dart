import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_card.dart';
import '../../asset/application/asset_providers.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../../expense/presentation/tx_detail_dialog.dart';
import '../../stats/application/stats_providers.dart';
import '../../stats/domain/stats_models.dart';

/// 홈 / 대시보드 — porest-desk-front HomeMobile 정확 미러.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;

    final now = DateTime.now();
    final monthKey = (year: now.year, month: now.month);
    final summaryAsync = ref.watch(
        assetSummaryProvider((year: now.year, month: now.month)));
    final expensesAsync = ref.watch(monthExpensesProvider(monthKey));
    final categoriesAsync = ref.watch(categoriesProvider);
    final trendAsync = ref.watch(monthlyTrendProvider(6));

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(
            assetSummaryProvider((year: now.year, month: now.month)));
        ref.invalidate(monthExpensesProvider(monthKey));
        ref.invalidate(monthlyTrendProvider(6));
      },
      child: ListView(
        // .m-scroll : padding: 0 → child 가 직접 padding
        // HomeMobile.tsx: padding: '4px 20px 24px', gap: 16
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _BalanceHero(
              summaryAsync: summaryAsync, masked: settings.hideAmounts),
          const SizedBox(height: 16),
          const _QuickActions(),
          const SizedBox(height: 16),
          _MonthExpenseCard(
            month: now.month,
            expensesAsync: expensesAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: 16),
          _MonthlyTrendCard(async: trendAsync),
          const SizedBox(height: 16),
          _RecentTxCard(
            expensesAsync: expensesAsync,
            categoriesAsync: categoriesAsync,
            masked: settings.hideAmounts,
          ),
        ],
      ),
    );
  }
}

/// 최근 6개월 수입/지출 BarChart — front HomeDesktop `IncomeExpenseBarChart` 의 모바일 카드 버전.
class _MonthlyTrendCard extends StatelessWidget {
  const _MonthlyTrendCard({required this.async});
  final AsyncValue<List<MonthlyTrend>> async;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.barChart3, size: 16, color: t.fgSecondary),
              const SizedBox(width: 6),
              Text('최근 6개월',
                  style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/stats'),
                child: Row(
                  children: [
                    Text('자세히',
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                    const SizedBox(width: 2),
                    Icon(LucideIcons.chevronRight, size: 12, color: t.fgTertiary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          SizedBox(height: 140, child: _MiniBars(async: async, tokens: t)),
        ],
      ),
    );
  }
}

class _MiniBars extends StatelessWidget {
  const _MiniBars({required this.async, required this.tokens});
  final AsyncValue<List<MonthlyTrend>> async;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final list = async.value ?? const <MonthlyTrend>[];
    if (async.isLoading && list.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return Center(
        child: Text('데이터 없음',
            style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
      );
    }
    final maxY = list
        .fold<int>(0, (m, t) =>
            [m, t.totalIncome, t.totalExpense].reduce((a, b) => a > b ? a : b))
        .toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY > 0 ? maxY * 1.15 : 100,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= list.length) return const SizedBox();
                return Text('${list[i].month}월',
                    style: PTypo.micro.copyWith(color: tokens.fgTertiary));
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 0; i < list.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 3,
              barRods: [
                BarChartRodData(
                  toY: list[i].totalIncome.toDouble(),
                  color: tokens.statusSuccess,
                  width: 6,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(2)),
                ),
                BarChartRodData(
                  toY: list[i].totalExpense.toDouble(),
                  color: tokens.statusDanger,
                  width: 6,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── BalanceHero (gradient olive card) ─────────────────────

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summaryAsync, required this.masked});
  final AsyncValue summaryAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final loading = summaryAsync.isLoading && !summaryAsync.hasValue;
    final s = summaryAsync.value;
    final netWorth = (s?.netWorth as int?) ?? 0;
    final totalAssets = (s?.totalAssets as int?) ?? 0;
    final totalDebt = (s?.totalDebt as int?) ?? 0;
    final changePct = (s?.changePercent as double?) ?? 0.0;
    final isUp = changePct >= 0;

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          decoration: BoxDecoration(
            // .balance-hero CSS: linear-gradient(135deg, mossy-700, mossy-900)
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [PorestPalette.mossy700, PorestPalette.mossy900],
            ),
            borderRadius: PRadius.brXl2, // 20px
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // __eyebrow: 12px / 500 / opacity 0.72
              Row(
                children: [
                  Icon(LucideIcons.wallet,
                      size: 13, color: Colors.white.withValues(alpha: 0.72)),
                  const SizedBox(width: 8),
                  Text(
                    '순자산',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.06,
                    ),
                  ),
                  const Spacer(),
                  // 우측 작은 eye (현재는 정적, 본인 hide-amounts 와 동기화)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Icon(
                      masked ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // __amount: 34px / 800 / -0.03em / line-height 1.1, baseline align with unit (18px)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    loading ? '—' : krwMasked(netWorth, masked),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.02, // -0.03em × 34
                      height: 1.1,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '원',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // __sub: 12.5px / opacity 0.78
              Row(
                children: [
                  Text(
                    '지난달 대비',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                    size: 13,
                    color: isUp
                        ? PorestPalette.heroChgUp
                        : PorestPalette.heroChgDown,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${isUp ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: isUp
                          ? PorestPalette.heroChgUp
                          : PorestPalette.heroChgDown,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // __split: 2-col grid mt 20px pt 18px border-top white/0.14
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.only(top: 18),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14)),
                  ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroSplitCol(
                          label: '자산',
                          value: krwMasked(totalAssets, masked),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: _HeroSplitCol(
                            label: '부채',
                            value: '-${krwMasked(totalDebt, masked)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ::after radial spot upper-right
        Positioned(
          right: -40,
          top: -80,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    PorestPalette.heroSpot.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSplitCol extends StatelessWidget {
  const _HeroSplitCol({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // .l: 11.5px opacity 0.7
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 4),
        // .v: 16px / 700 / -0.015em / tabular-nums
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.24,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ─── Quick actions 4-grid ──────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final items = <(IconData, String, String)>[
      (LucideIcons.wallet, '자산', '/assets'),
      (LucideIcons.receipt, '가계부', '/expense'),
      (LucideIcons.target, '예산', '/budget'),
      (LucideIcons.users, '더치페이', '/dutch-pay'),
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(
            child: _QuickAction(
              icon: items[i].$1,
              label: items[i].$2,
              onTap: () => context.push(items[i].$3),
              tokens: t,
            ),
          ),
          if (i < items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tokens,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    // padding: 14px 8px, gap 6, items center
    return PCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      borderRadius: PRadius.brXl, // 14px in front but xl=16 is closest
      onTap: onTap,
      child: Column(
        children: [
          // 32×32 round-rect, bg-brand-subtle, fg-brand-strong, radius 10
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tokens.bgBrandSubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: tokens.fgBrandStrong),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: tokens.fgPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 5월 가계부 카드 ──────────────────────────────────────

class _MonthExpenseCard extends StatelessWidget {
  const _MonthExpenseCard({
    required this.month,
    required this.expensesAsync,
    required this.masked,
  });
  final int month;
  final AsyncValue<List<Expense>> expensesAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final list = expensesAsync.value ?? const <Expense>[];
    final income = list
        .where((e) => e.expenseType == 'INCOME')
        .fold<int>(0, (s, e) => s + e.amount);
    final expense = list
        .where((e) => e.expenseType == 'EXPENSE')
        .fold<int>(0, (s, e) => s + e.amount);
    final hasError = expensesAsync.hasError && !expensesAsync.hasValue;

    return PCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 15px / 700 / -0.015em + 우측 trending icon
          Row(
            children: [
              Text(
                '$month월 가계부',
                style: TextStyle(
                  color: t.fgPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.225,
                ),
              ),
              const Spacer(),
              Icon(LucideIcons.trendingUp,
                  size: 14, color: t.statusSuccessFg),
            ],
          ),
          const SizedBox(height: 14),
          if (hasError)
            Text(
              '이번달 거래를 불러오지 못했습니다',
              style: TextStyle(color: t.statusDanger, fontSize: 12.5),
            )
          else
            Row(
              children: [
                Expanded(
                  child: _IncomeExpenseCol(
                    label: '수입',
                    value: '+${krwMasked(income, masked)}',
                    color: t.statusSuccessFg,
                  ),
                ),
                Expanded(
                  child: _IncomeExpenseCol(
                    label: '지출',
                    value: '-${krwMasked(expense, masked)}',
                    color: t.statusDangerFg,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _IncomeExpenseCol extends StatelessWidget {
  const _IncomeExpenseCol(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: t.fgTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

// ─── 최근 거래 카드 ───────────────────────────────────────

class _RecentTxCard extends StatelessWidget {
  const _RecentTxCard({
    required this.expensesAsync,
    required this.categoriesAsync,
    required this.masked,
  });
  final AsyncValue<List<Expense>> expensesAsync;
  final AsyncValue categoriesAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final list = expensesAsync.value ?? const <Expense>[];
    final categories = categoriesAsync.value as List? ?? const [];

    final sorted = [...list]
      ..sort((a, b) =>
          (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''));
    final recent = sorted.take(4).toList();

    return PCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CardHeader (.all 우측 링크)
          Row(
            children: [
              Text(
                '최근 거래',
                style: TextStyle(
                  color: t.fgPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.225,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/expense'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '전체',
                      style: TextStyle(
                        color: t.fgTertiary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                    expensesAsync.hasError
                        ? '거래를 불러오지 못했습니다'
                        : '거래가 없어요',
                    style:
                        TextStyle(color: t.fgTertiary, fontSize: 12)),
              ),
            )
          else
            for (final e in recent)
              _ExpenseRow(
                expense: e,
                category: _findCategory(categories, e.categoryRowId),
                masked: masked,
                tokens: t,
              ),
        ],
      ),
    );
  }

  dynamic _findCategory(List categories, int? rowId) {
    if (rowId == null) return null;
    for (final c in categories) {
      try {
        if (c.rowId == rowId) return c;
      } catch (_) {}
    }
    return null;
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.category,
    required this.masked,
    required this.tokens,
  });
  final Expense expense;
  final dynamic category;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final fg = parseColor((category?.color as String?) ?? expense.categoryColor,
        fallback: tokens.fgBrand);
    final bg = softBg(fg);
    final isExpense = expense.expenseType == 'EXPENSE';
    final dayLabel = expense.expenseDate != null
        ? formatDay(parseIsoDate(expense.expenseDate!.substring(0, 10)))
        : null;

    return InkWell(
      onTap: () => showTxDetailDialog(context, expense),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // 카테고리 아이콘 ~36×36 round-square
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: bg, borderRadius: PRadius.brSm),
              alignment: Alignment.center,
              child: Icon(
                lucideByName(
                    (category?.icon as String?) ?? expense.categoryIcon,
                    fallback: LucideIcons.tag),
                size: 18,
                color: fg,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.merchant ??
                        expense.description ??
                        expense.categoryName ??
                        '거래',
                    style: TextStyle(
                      color: tokens.fgPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      expense.categoryName,
                      if (dayLabel != null)
                        '${dayLabel.md} (${dayLabel.dow})',
                    ].whereType<String>().join(' · '),
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isExpense ? '-' : '+'}${krwMasked(expense.amount, masked)}원',
              style: TextStyle(
                color: isExpense
                    ? tokens.statusDangerFg
                    : tokens.statusSuccessFg,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
