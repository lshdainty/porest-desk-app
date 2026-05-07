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
import '../application/dashboard_providers.dart';
import '../domain/dashboard_summary.dart';

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
    final dashboardAsync = ref.watch(dashboardSummaryProvider);

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(
            assetSummaryProvider((year: now.year, month: now.month)));
        ref.invalidate(monthExpensesProvider(monthKey));
        ref.invalidate(dashboardSummaryProvider);
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
          _UpcomingCard(async: dashboardAsync),
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

/// 다가오는 일정 + 최근 할 일 카드 (#230 활용).
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.async});
  final AsyncValue<DashboardSummary> async;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    if (async.isLoading && !async.hasValue) {
      return PCard(
        padding: const EdgeInsets.all(18),
        child: const SizedBox(
            height: 80, child: Center(child: CircularProgressIndicator())),
      );
    }
    final s = async.value;
    if (s == null) return const SizedBox.shrink();
    final events = s.upcomingEvents.take(3).toList();
    final todos = s.recentTodos.take(3).toList();
    if (events.isEmpty && todos.isEmpty) return const SizedBox.shrink();

    return PCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (events.isNotEmpty) ...[
            Row(
              children: [
                Icon(LucideIcons.calendarClock,
                    size: 16, color: t.fgSecondary),
                const SizedBox(width: 6),
                Text('다가오는 일정',
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/calendar'),
                  child: Icon(LucideIcons.chevronRight,
                      size: 14, color: t.fgTertiary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final e in events)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: parseColor(e.color, fallback: t.fgBrand),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.bodySm
                              .copyWith(color: t.fgPrimary)),
                    ),
                    Text(
                        e.daysUntil == 0
                            ? '오늘'
                            : (e.daysUntil == 1
                                ? '내일'
                                : 'D-${e.daysUntil}'),
                        style: PTypo.caption
                            .copyWith(color: t.fgTertiary)),
                  ],
                ),
              ),
            if (todos.isNotEmpty) const SizedBox(height: 12),
          ],
          if (todos.isNotEmpty) ...[
            Row(
              children: [
                Icon(LucideIcons.checkSquare,
                    size: 16, color: t.fgSecondary),
                const SizedBox(width: 6),
                Text('최근 할 일',
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary, fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => context.push('/todos'),
                  child: Icon(LucideIcons.chevronRight,
                      size: 14, color: t.fgTertiary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final tdo in todos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      tdo.status == 'COMPLETED'
                          ? LucideIcons.checkCircle
                          : LucideIcons.circle,
                      size: 14,
                      color: tdo.status == 'COMPLETED'
                          ? t.statusSuccess
                          : t.fgTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tdo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PTypo.bodySm.copyWith(
                            color: t.fgPrimary,
                            decoration: tdo.status == 'COMPLETED'
                                ? TextDecoration.lineThrough
                                : null,
                          )),
                    ),
                    if (tdo.dueDate != null)
                      Text(tdo.dueDate!.substring(5),
                          style: PTypo.caption
                              .copyWith(color: t.fgTertiary)),
                  ],
                ),
              ),
          ],
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

    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    final sorted = [...list]
      ..sort((a, b) =>
          (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''));
    // 오늘 포함 이전 거래만 — 미래 거래(테스트 데이터 등) 제외
    final recent = sorted
        .where((e) =>
            (e.expenseDate ?? '').isEmpty ||
            e.expenseDate!.substring(0, 10).compareTo(todayStr) <= 0)
        .take(4)
        .toList();

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
      onTap: () {
        final dateStr = expense.expenseDate?.substring(0, 7);
        if (dateStr != null && dateStr.length == 7) {
          context.go('/expense?month=$dateStr&txId=${expense.rowId}');
        } else {
          context.go('/expense?txId=${expense.rowId}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // 카테고리 아이콘 40×40 round-square (front CategoryChip md 미러)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
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
                      expense.assetName,
                      if (dayLabel != null)
                        '${dayLabel.md} (${dayLabel.dow})',
                    ].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                    style: PTypo.caption.copyWith(color: tokens.fgTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
