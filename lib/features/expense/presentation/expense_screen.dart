import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';
import 'filter_dialog.dart';
import 'widgets/expense_row.dart';
import 'widgets/month_picker.dart';

/// 가계부 화면 — 백엔드 `/expenses` 직접 호출.
class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

enum _Filter { all, expense, income }

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  late DateTime _month = monthStart(DateTime.now());
  _Filter _filter = _Filter.all;
  ExpenseFilter _advFilter = const ExpenseFilter();

  MonthKey get _key => (year: _month.year, month: _month.month);

  Future<void> _openFilter() async {
    final result = await showFilterDialog(context, _advFilter);
    if (result != null && mounted) setState(() => _advFilter = result);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final categoriesAsync = ref.watch(categoriesProvider);
    final expensesAsync = ref.watch(monthExpensesProvider(_key));

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(monthExpensesProvider(_key));
        await ref.read(monthExpensesProvider(_key).future);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x16),
        children: [
          Row(
            children: [
              Expanded(
                child: MonthPicker(
                  month: _month,
                  onPrev: () => setState(() =>
                      _month = DateTime(_month.year, _month.month - 1, 1)),
                  onNext: () => setState(() =>
                      _month = DateTime(_month.year, _month.month + 1, 1)),
                ),
              ),
              _FilterButton(
                active: !_advFilter.isEmpty,
                count: _advFilter.categoryIds.length + _advFilter.assetIds.length,
                onTap: _openFilter,
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),

          // 본문 — 비동기 상태에 따라 분기
          expensesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: PSpace.x32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _ErrorBox(
              message: '거래를 불러오지 못했습니다\n$e',
              onRetry: () => ref.invalidate(monthExpensesProvider(_key)),
            ),
            data: (raw) {
              final filtered = raw.where((e) {
                switch (_filter) {
                  case _Filter.all:
                    return true;
                  case _Filter.expense:
                    return e.expenseType == 'EXPENSE';
                  case _Filter.income:
                    return e.expenseType == 'INCOME';
                }
              }).where((e) {
                if (_advFilter.categoryIds.isNotEmpty &&
                    !_advFilter.categoryIds.contains(e.categoryRowId)) {
                  return false;
                }
                if (_advFilter.assetIds.isNotEmpty &&
                    !_advFilter.assetIds.contains(e.assetRowId)) {
                  return false;
                }
                return true;
              }).toList()
                ..sort((a, b) =>
                    (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''));

              final monthIncome = raw
                  .where((e) => e.expenseType == 'INCOME')
                  .fold<int>(0, (s, e) => s + e.amount);
              final monthExpense = raw
                  .where((e) => e.expenseType == 'EXPENSE')
                  .fold<int>(0, (s, e) => s + e.amount);

              final groups = <String, List<Expense>>{};
              for (final e in filtered) {
                final d = e.expenseDateOnly ?? '';
                groups.putIfAbsent(d, () => []).add(e);
              }
              final groupKeys = groups.keys.toList();

              return Column(
                children: [
                  _SummaryCard(
                    income: monthIncome,
                    expense: monthExpense,
                    masked: settings.hideAmounts,
                  ),
                  const SizedBox(height: PSpace.x16),
                  _FilterSeg(
                    value: _filter,
                    onChanged: (v) => setState(() => _filter = v),
                  ),
                  const SizedBox(height: PSpace.x16),
                  if (groupKeys.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: PSpace.x32),
                      child: Center(
                        child: Text('이 달에는 거래가 없습니다',
                            style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
                      ),
                    ),
                  for (final key in groupKeys)
                    _DayGroup(
                      date: parseIsoDate(key),
                      items: groups[key]!,
                      categoriesAsync: categoriesAsync,
                      masked: settings.hideAmounts,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.income, required this.expense, required this.masked});
  final int income;
  final int expense;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final balance = income - expense;
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: [
          _Stat(label: '수입', value: krwMasked(income, masked), color: t.statusSuccess),
          _StatDivider(t: t),
          _Stat(label: '지출', value: krwMasked(expense, masked), color: t.fgPrimary),
          _StatDivider(t: t),
          _Stat(
            label: '잔액',
            value: krwMasked(balance, masked, sign: true),
            color: balance >= 0 ? t.statusSuccess : t.statusDanger,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Expanded(
      child: Column(
        children: [
          Text(label, style: PTypo.caption.copyWith(color: t.fgTertiary)),
          const SizedBox(height: 4),
          Text(value,
              style: PTypo.money.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.t});
  final PorestTokens t;
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: t.borderSubtle);
}

class _FilterSeg extends StatelessWidget {
  const _FilterSeg({required this.value, required this.onChanged});
  final _Filter value;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brMd),
      child: Row(
        children: [
          for (final f in _Filter.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: f == value ? t.bgSurface : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    switch (f) {
                      _Filter.all => '전체',
                      _Filter.expense => '지출',
                      _Filter.income => '수입',
                    },
                    textAlign: TextAlign.center,
                    style: PTypo.bodySm.copyWith(
                      color: f == value ? t.fgPrimary : t.fgTertiary,
                      fontWeight: f == value ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayGroup extends ConsumerWidget {
  const _DayGroup({
    required this.date,
    required this.items,
    required this.categoriesAsync,
    required this.masked,
  });
  final DateTime date;
  final List<Expense> items;
  final AsyncValue<dynamic> categoriesAsync;
  final bool masked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final label = formatDay(date);
    final daySum = items.fold<int>(0, (s, e) => s + e.signedAmount);
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return Padding(
      padding: const EdgeInsets.only(bottom: PSpace.x12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x4, vertical: PSpace.x8),
            child: Row(
              children: [
                Text(label.md,
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(width: PSpace.x8),
                Text(label.dow,
                    style: PTypo.caption.copyWith(color: t.fgTertiary)),
                const Spacer(),
                Text(
                  krwMasked(daySum, masked, sign: true),
                  style: PTypo.caption.copyWith(
                    color: daySum > 0
                        ? t.statusSuccess
                        : daySum < 0
                            ? t.fgPrimary
                            : t.fgTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: t.bgSurface,
              borderRadius: PRadius.brLg,
              border: Border.all(color: t.borderSubtle),
            ),
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  ExpenseRow(
                    expense: items[i],
                    category: categories.byRowId(items[i].categoryRowId),
                    masked: masked,
                  ),
                  if (i < items.length - 1)
                    Divider(height: 1, color: t.borderSubtle, indent: 60),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.statusDangerSubtle,
        borderRadius: PRadius.brLg,
      ),
      child: Column(
        children: [
          Text(message, style: PTypo.bodySm.copyWith(color: t.statusDangerFg)),
          const SizedBox(height: PSpace.x8),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.active,
    required this.count,
    required this.onTap,
  });
  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? t.bgBrandSubtle : Colors.transparent,
          border: Border.all(
            color: active ? t.borderBrand : t.borderDefault,
          ),
          borderRadius: PRadius.brMd,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.filter,
                size: 16, color: active ? t.fgBrand : t.fgSecondary),
            if (active) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: t.bgBrand,
                  borderRadius: PRadius.brPill,
                ),
                child: Text('$count',
                    style: PTypo.micro.copyWith(
                        color: t.fgOnBrand, fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
