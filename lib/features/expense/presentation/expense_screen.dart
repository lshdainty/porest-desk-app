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
import 'add_tx_sheet.dart';
import 'filter_dialog.dart';
import 'widgets/expense_row.dart';

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
        padding: const EdgeInsets.fromLTRB(
            PSpace.x16, PSpace.x4, PSpace.x16, PSpace.x24),
        children: [
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
                if (_advFilter.types.length < 2 &&
                    e.expenseType != null &&
                    !_advFilter.types.contains(e.expenseType)) {
                  return false;
                }
                if (_advFilter.min != null && e.amount < _advFilter.min!) {
                  return false;
                }
                if (_advFilter.max != null && e.amount > _advFilter.max!) {
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
                    month: _month,
                    income: monthIncome,
                    expense: monthExpense,
                    masked: settings.hideAmounts,
                    onPrev: () => setState(() => _month =
                        DateTime(_month.year, _month.month - 1, 1)),
                    onNext: () => setState(() => _month =
                        DateTime(_month.year, _month.month + 1, 1)),
                  ),
                  const SizedBox(height: PSpace.x12),
                  _FilterRow(
                    value: _filter,
                    onChanged: (v) => setState(() => _filter = v),
                    advActive: !_advFilter.isEmpty,
                    advCount: _advFilter.categoryIds.length +
                        _advFilter.assetIds.length +
                        (_advFilter.types.length < 2 ? 1 : 0) +
                        (_advFilter.min != null ? 1 : 0) +
                        (_advFilter.max != null ? 1 : 0),
                    onOpenFilter: _openFilter,
                    onAddTx: () => showAddTxSheet(context),
                  ),
                  const SizedBox(height: PSpace.x12),
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

/// 월 요약 카드 — front ExpenseMobile/Desktop 미러.
/// 헤더: "YYYY년 M월" + 우측 prev/next 화살표 (멀리 떨어진 월은 상세 필터에서).
/// 본문: 수입/지출/합계 3-col grid.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.month,
    required this.income,
    required this.expense,
    required this.masked,
    required this.onPrev,
    required this.onNext,
  });
  final DateTime month;
  final int income;
  final int expense;
  final bool masked;
  final VoidCallback onPrev;
  final VoidCallback onNext;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${month.year}년 ${month.month}월',
                style: TextStyle(
                  color: t.fgPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.32,
                ),
              ),
              const Spacer(),
              _ArrowBtn(
                  icon: LucideIcons.chevronLeft, onTap: onPrev, tokens: t),
              const SizedBox(width: 4),
              _ArrowBtn(
                  icon: LucideIcons.chevronRight, onTap: onNext, tokens: t),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                    label: '수입',
                    value: krwMasked(income, masked, sign: true),
                    color: t.statusSuccessFg),
              ),
              Expanded(
                child: _Stat(
                    label: '지출',
                    value: krwMasked(-expense, masked, sign: true),
                    color: t.statusDangerFg),
              ),
              Expanded(
                child: _Stat(
                    label: '합계',
                    value: krwMasked(balance, masked, sign: true),
                    color: t.fgBrandStrong),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 월 prev/next 화살표 — _SummaryCard 헤더 우측에 사용.
class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn(
      {required this.icon, required this.onTap, required this.tokens});
  final IconData icon;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brSm,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: tokens.borderSubtle),
          borderRadius: PRadius.brSm,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: tokens.fgSecondary),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: PTypo.micro.copyWith(
                color: t.fgTertiary, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.24,
              fontFamily: 'monospace',
            )),
      ],
    );
  }
}

/// 필터 행 — front ExpenseMobile 레이아웃 미러.
/// 좌측: 가로 스크롤 가능한 칩 그룹 (전체/지출/수입). 우측: 필터 아이콘 + 추가(+) 아이콘.
class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.value,
    required this.onChanged,
    required this.advActive,
    required this.advCount,
    required this.onOpenFilter,
    required this.onAddTx,
  });
  final _Filter value;
  final ValueChanged<_Filter> onChanged;
  final bool advActive;
  final int advCount;
  final VoidCallback onOpenFilter;
  final VoidCallback onAddTx;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in _Filter.values) ...[
                  _Chip(
                    label: switch (f) {
                      _Filter.all => '전체',
                      _Filter.expense => '지출',
                      _Filter.income => '수입',
                    },
                    active: f == value,
                    onTap: () => onChanged(f),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 고급 필터 아이콘 (sliders-horizontal)
        InkWell(
          onTap: onOpenFilter,
          borderRadius: PRadius.brSm,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: advActive ? t.bgBrandSubtle : Colors.transparent,
              border: Border.all(
                  color: advActive ? t.borderBrand : t.borderSubtle),
              borderRadius: PRadius.brSm,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(LucideIcons.slidersHorizontal,
                    size: 18,
                    color: advActive ? t.fgBrand : t.fgSecondary),
                if (advActive && advCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: t.bgBrand,
                        borderRadius: PRadius.brPill,
                      ),
                      child: Text('$advCount',
                          style: PTypo.micro.copyWith(
                              color: t.fgOnBrand,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        // 거래 추가 (+) 버튼 — front 의 brand-bg primary 액션 미러
        InkWell(
          onTap: onAddTx,
          borderRadius: PRadius.brSm,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: t.bgBrand,
              borderRadius: PRadius.brSm,
            ),
            child: Icon(LucideIcons.plus, size: 18, color: t.fgOnBrand),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brPill,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: PSpace.x12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? t.bgBrand : t.bgSurface,
          border: Border.all(color: active ? t.bgBrand : t.borderSubtle),
          borderRadius: PRadius.brPill,
        ),
        child: Text(label,
            style: PTypo.caption.copyWith(
              color: active ? t.fgOnBrand : t.fgSecondary,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

/// 월 선택 BottomSheet — 12개월 grid + 좌우 화살표로 연도 이동.

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
                    category: items[i].categoryRowId == null
                        ? null
                        : categories.byRowId(items[i].categoryRowId!),
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
