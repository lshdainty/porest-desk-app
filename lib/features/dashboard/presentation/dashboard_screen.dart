import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../asset/application/asset_providers.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../../expense/presentation/tx_detail_dialog.dart';

/// 홈 / 대시보드 — porest-desk-front HomeMobile 미러.
///
/// 1. 그라데이션 hero 카드 (순자산 + 지난달 대비 + 자산/부채)
/// 2. 4-grid 빠른 진입 (자산/가계부/예산/더치페이)
/// 3. 이번달 가계부 요약 (수입/지출)
/// 4. 최근 거래 리스트 (탭 → 상세)
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

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(assetSummaryProvider(
            (year: now.year, month: now.month)));
        ref.invalidate(monthExpensesProvider(monthKey));
        await Future.wait([
          ref
              .read(assetSummaryProvider(
                  (year: now.year, month: now.month)).future)
              .catchError((_) => null as dynamic),
          ref
              .read(monthExpensesProvider(monthKey).future)
              .catchError((_) => <Expense>[]),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x4, PSpace.x16, PSpace.x24),
        children: [
          // 1. 그라데이션 순자산 hero
          _BalanceHero(
            summaryAsync: summaryAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: PSpace.x16),

          // 2. 빠른 진입 4-grid
          _QuickActionsGrid(),
          const SizedBox(height: PSpace.x16),

          // 3. 이번달 가계부
          _MonthExpenseCard(
            month: now.month,
            expensesAsync: expensesAsync,
            masked: settings.hideAmounts,
          ),
          const SizedBox(height: PSpace.x16),

          // 4. 최근 거래
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

// ─── Balance Hero ──────────────────────────────────────────

class _BalanceHero extends ConsumerWidget {
  const _BalanceHero({required this.summaryAsync, required this.masked});
  final AsyncValue summaryAsync;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grad = isDark
        ? const [Color(0xFF374431), Color(0xFF1F2A1B)]
        : const [Color(0xFF6B7C56), Color(0xFF424F37)];

    final loading = summaryAsync.isLoading && !summaryAsync.hasValue;
    final s = summaryAsync.value;
    final netWorth = (s?.netWorth as int?) ?? 0;
    final totalAssets = (s?.totalAssets as int?) ?? 0;
    final totalDebt = (s?.totalDebt as int?) ?? 0;
    final changePct = (s?.changePercent as double?) ?? 0.0;
    final isUp = changePct >= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x24, PSpace.x20, PSpace.x24, PSpace.x16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grad,
        ),
        borderRadius: PRadius.brXl,
      ),
      child: Stack(
        children: [
          // 우측 상단 라이트 dot (front ::after 흉내)
          Positioned(
            right: -40,
            top: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.wallet,
                      size: 13, color: Colors.white.withValues(alpha: 0.72)),
                  const SizedBox(width: 6),
                  Text('순자산',
                      style: PTypo.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: PSpace.x4),
              Text(
                loading ? '—' : krwMasked(netWorth, masked),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: PSpace.x8),
              Row(
                children: [
                  Text('지난달 대비',
                      style: PTypo.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.72))),
                  const SizedBox(width: 6),
                  Icon(
                      isUp
                          ? LucideIcons.trendingUp
                          : LucideIcons.trendingDown,
                      size: 13,
                      color: isUp
                          ? const Color(0xFFB8E0A0)
                          : const Color(0xFFF7B0B0)),
                  const SizedBox(width: 3),
                  Text(
                    '${isUp ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                    style: PTypo.caption.copyWith(
                        color: isUp
                            ? const Color(0xFFB8E0A0)
                            : const Color(0xFFF7B0B0),
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: PSpace.x16),
              Row(
                children: [
                  Expanded(
                      child: _HeroSplitCol(
                          label: '자산',
                          value: krwMasked(totalAssets, masked))),
                  Expanded(
                      child: _HeroSplitCol(
                          label: '부채',
                          value: '-${krwMasked(totalDebt, masked)}')),
                ],
              ),
            ],
          ),
        ],
      ),
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
        Text(label,
            style: PTypo.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: PTypo.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15)),
      ],
    );
  }
}

// ─── Quick Actions Grid ─────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();
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
          if (i < items.length - 1) const SizedBox(width: PSpace.x8),
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
    return Material(
      color: tokens.bgSurface,
      borderRadius: PRadius.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: PRadius.brLg,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
          decoration: BoxDecoration(
            borderRadius: PRadius.brLg,
            border: Border.all(color: tokens.borderSubtle),
          ),
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tokens.bgBrandSubtle,
                  borderRadius: PRadius.brSm,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: tokens.fgBrandStrong),
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: PTypo.caption.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Month Expense Summary ─────────────────────────────────

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
    final income =
        list.where((e) => e.expenseType == 'INCOME').fold<int>(0, (s, e) => s + e.amount);
    final expense =
        list.where((e) => e.expenseType == 'EXPENSE').fold<int>(0, (s, e) => s + e.amount);
    final loading = expensesAsync.isLoading && !expensesAsync.hasValue;
    final hasError = expensesAsync.hasError && !expensesAsync.hasValue;

    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$month월 가계부',
                  style: PTypo.body.copyWith(
                      color: t.fgPrimary, fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(LucideIcons.trendingUp, size: 14, color: t.statusSuccess),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          if (hasError)
            Text('이번달 거래를 불러오지 못했습니다',
                style: PTypo.bodySm.copyWith(color: t.statusDanger))
          else
            Row(
              children: [
                Expanded(
                  child: _IncomeExpenseCol(
                    label: '수입',
                    value: loading
                        ? '—'
                        : '+${krwMasked(income, masked)}',
                    color: t.statusSuccess,
                    tokens: t,
                  ),
                ),
                Expanded(
                  child: _IncomeExpenseCol(
                    label: '지출',
                    value: loading
                        ? '—'
                        : '-${krwMasked(expense, masked)}',
                    color: t.statusDanger,
                    tokens: t,
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
      {required this.label,
      required this.value,
      required this.color,
      required this.tokens});
  final String label;
  final String value;
  final Color color;
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: PTypo.caption.copyWith(
                color: tokens.fgTertiary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: PTypo.body.copyWith(
                color: color, fontWeight: FontWeight.w800, fontSize: 17)),
      ],
    );
  }
}

// ─── Recent Transactions ────────────────────────────────────

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

    final sorted = [...list]..sort((a, b) =>
        (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''));
    final recent = sorted.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('최근 거래',
                  style: PTypo.body.copyWith(
                      color: t.fgPrimary, fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/expense'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('전체',
                        style: PTypo.caption.copyWith(color: t.fgSecondary)),
                    Icon(LucideIcons.chevronRight,
                        size: 14, color: t.fgTertiary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x4),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
              child: Center(
                child: Text(
                    expensesAsync.hasError
                        ? '거래를 불러오지 못했습니다'
                        : '거래가 없어요',
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
              ),
            )
          else
            for (int i = 0; i < recent.length; i++) ...[
              _RecentTxRow(
                expense: recent[i],
                categoryColor: _findCategoryColor(categories, recent[i].categoryRowId),
                categoryIcon: _findCategoryIcon(categories, recent[i].categoryRowId, recent[i].categoryIcon),
                masked: masked,
                tokens: t,
              ),
              if (i < recent.length - 1)
                Divider(height: 1, color: t.borderSubtle),
            ],
        ],
      ),
    );
  }

  String? _findCategoryColor(List categories, int? rowId) {
    if (rowId == null) return null;
    for (final c in categories) {
      try {
        if (c.rowId == rowId) return c.color as String?;
      } catch (_) {}
    }
    return null;
  }

  String? _findCategoryIcon(List categories, int? rowId, String? fallback) {
    if (rowId == null) return fallback;
    for (final c in categories) {
      try {
        if (c.rowId == rowId) return c.icon as String?;
      } catch (_) {}
    }
    return fallback;
  }
}

class _RecentTxRow extends StatelessWidget {
  const _RecentTxRow({
    required this.expense,
    required this.categoryColor,
    required this.categoryIcon,
    required this.masked,
    required this.tokens,
  });
  final Expense expense;
  final String? categoryColor;
  final String? categoryIcon;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final fg = parseColor(categoryColor ?? expense.categoryColor,
        fallback: tokens.fgBrand);
    final bg = softBg(fg);
    final isExpense = expense.expenseType == 'EXPENSE';
    final dayLabel = expense.expenseDate != null
        ? formatDay(parseIsoDate(expense.expenseDate!.substring(0, 10)))
        : null;

    return InkWell(
      onTap: () => showTxDetailDialog(context, expense),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bg, borderRadius: PRadius.brSm),
              alignment: Alignment.center,
              child: Icon(
                  lucideByName(categoryIcon ?? expense.categoryIcon,
                      fallback: LucideIcons.tag),
                  size: 18,
                  color: fg),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.merchant ??
                        expense.description ??
                        expense.categoryName ??
                        '거래',
                    style: PTypo.bodySm.copyWith(
                        color: tokens.fgPrimary,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      expense.categoryName,
                      if (dayLabel != null) '${dayLabel.md} (${dayLabel.dow})',
                    ].whereType<String>().join(' · '),
                    style:
                        PTypo.caption.copyWith(color: tokens.fgTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Text(
              '${isExpense ? '-' : '+'}${krwMasked(expense.amount, masked)}',
              style: PTypo.bodySm.copyWith(
                  color: isExpense
                      ? tokens.fgPrimary
                      : tokens.statusSuccess,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
