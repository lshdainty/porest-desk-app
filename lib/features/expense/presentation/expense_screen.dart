import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';
import 'widgets/expense_row.dart';
import 'widgets/month_picker.dart';

/// 가계부 화면.
///
/// porest-desk-front `ExpensePage` 모바일 모드 매핑:
/// 1) 월 선택기
/// 2) 필터 (전체/지출/수입)
/// 3) 일일 그룹 헤더 + 거래 행
class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

enum _Filter { all, expense, income }

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  late DateTime _month = monthStart(DateTime.now());
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final categories = ref.watch(categoriesProvider);
    final assets = ref.watch(assetsProvider);
    final allExpenses = ref.watch(expensesProvider);

    final inMonth = allExpenses.where((e) {
      final d = parseIsoDate(e.date);
      return d.year == _month.year && d.month == _month.month;
    }).where((e) {
      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.expense:
          return e.type == TxType.expense;
        case _Filter.income:
          return e.type == TxType.income;
      }
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final groups = <String, List<Expense>>{};
    for (final e in inMonth) {
      groups.putIfAbsent(e.date, () => []).add(e);
    }
    final groupKeys = groups.keys.toList();

    final monthIncome = inMonth
        .where((e) => e.type == TxType.income)
        .fold<int>(0, (s, e) => s + e.amount);
    final monthExpense = inMonth
        .where((e) => e.type == TxType.expense)
        .fold<int>(0, (s, e) => s + e.amount);

    return ListView(
      padding: EdgeInsets.symmetric(
          horizontal: PSpace.x16, vertical: settings.density.cardPad),
      children: [
        MonthPicker(
          month: _month,
          onPrev: () => setState(() =>
              _month = DateTime(_month.year, _month.month - 1, 1)),
          onNext: () => setState(() =>
              _month = DateTime(_month.year, _month.month + 1, 1)),
        ),
        const SizedBox(height: PSpace.x12),

        // 월 합계 카드
        Container(
          padding: EdgeInsets.all(settings.density.cardPad),
          decoration: BoxDecoration(
            color: t.bgSurface,
            borderRadius: PRadius.brLg,
            border: Border.all(color: t.borderSubtle),
          ),
          child: Row(
            children: [
              _Stat(
                label: '수입',
                value: krwMasked(monthIncome, settings.hideAmounts),
                color: t.statusSuccess,
              ),
              const _StatDivider(),
              _Stat(
                label: '지출',
                value: krwMasked(monthExpense, settings.hideAmounts),
                color: t.fgPrimary,
              ),
              const _StatDivider(),
              _Stat(
                label: '잔액',
                value: krwMasked(monthIncome - monthExpense, settings.hideAmounts, sign: true),
                color: monthIncome - monthExpense >= 0
                    ? t.statusSuccess
                    : t.statusDanger,
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 필터 세그먼트
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: t.bgMuted,
            borderRadius: PRadius.brMd,
          ),
          child: Row(
            children: [
              for (final f in _Filter.values)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: f == _filter ? t.bgSurface : Colors.transparent,
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
                          color: f == _filter ? t.fgPrimary : t.fgTertiary,
                          fontWeight:
                              f == _filter ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
            categories: categories,
            assets: assets,
            masked: settings.hideAmounts,
          ),
      ],
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
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(width: 1, height: 28, color: t.borderSubtle);
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.date,
    required this.items,
    required this.categories,
    required this.assets,
    required this.masked,
  });
  final DateTime date;
  final List<Expense> items;
  final List<Category> categories;
  final List<Asset> assets;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final label = formatDay(date);
    final daySum = items.fold<int>(0, (s, e) => s + e.signedAmount);

    return Padding(
      padding: const EdgeInsets.only(bottom: PSpace.x12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpace.x4, vertical: PSpace.x8),
            child: Row(
              children: [
                Text(label.md, style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(width: PSpace.x8),
                Text(label.dow, style: PTypo.caption.copyWith(color: t.fgTertiary)),
                const Spacer(),
                Text(
                  krwMasked(daySum, masked, sign: true),
                  style: PTypo.caption.copyWith(
                    color: daySum > 0 ? t.statusSuccess :
                           daySum < 0 ? t.fgPrimary : t.fgTertiary,
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
                    category: categories.byId(items[i].categoryId),
                    asset: assets.byId(items[i].assetId),
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
