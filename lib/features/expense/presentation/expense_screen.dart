import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_chip.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../../asset/application/asset_providers.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';
import 'add_tx_sheet.dart';
import 'filter_dialog.dart';
import 'widgets/expense_row.dart';

/// 가계부 화면 — 백엔드 `/expenses` 직접 호출.
class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({
    this.initialMonth,
    this.focusTxId,
    this.initialAssetId,
    super.key,
  });

  /// "YYYY-MM" — 홈 최근 거래 → 해당 월로 자동 이동.
  final String? initialMonth;

  /// 진입 후 자동 스크롤할 거래 rowId.
  final int? focusTxId;

  /// 자산 상세 → 전체 보기 클릭 시 진입. 해당 자산만 필터링.
  final int? initialAssetId;

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

enum _Filter { all, expense, income }

/// 보기 모드 — 달력(grid + day-summary) / 목록(date-grouped list).
enum _ViewMode { calendar, list }

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  late DateTime _month = _resolveInitialMonth();
  _Filter _filter = _Filter.all;
  _ViewMode _viewMode = _ViewMode.calendar;
  ExpenseFilter _advFilter = const ExpenseFilter();
  int? _assetIdFilter;
  final Map<int, GlobalKey> _rowKeys = {};
  bool _scrolledToFocus = false;

  @override
  void initState() {
    super.initState();
    _assetIdFilter = widget.initialAssetId;
  }

  DateTime _resolveInitialMonth() {
    final raw = widget.initialMonth;
    if (raw != null && RegExp(r'^\d{4}-\d{2}$').hasMatch(raw)) {
      final parts = raw.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    }
    return monthStart(DateTime.now());
  }

  @override
  void didUpdateWidget(covariant ExpenseScreen old) {
    super.didUpdateWidget(old);
    // 라우트 query param 변경 시 (예: 다른 tx 클릭) 월/스크롤 상태 재초기화
    if (old.initialMonth != widget.initialMonth) {
      setState(() => _month = _resolveInitialMonth());
    }
    if (old.focusTxId != widget.focusTxId) {
      _scrolledToFocus = false;
    }
    if (old.initialAssetId != widget.initialAssetId) {
      setState(() => _assetIdFilter = widget.initialAssetId);
    }
  }

  void _clearAssetFilter() {
    setState(() => _assetIdFilter = null);
    // URL 동기화 — assetId 쿼리 제거 (다른 param 은 유지).
    final m = _month;
    final monthQ = '${m.year}-${m.month.toString().padLeft(2, '0')}';
    context.go('/expense?month=$monthQ');
  }

  MonthKey get _key => (year: _month.year, month: _month.month);

  Future<void> _openFilter() async {
    final result = await showFilterDialog(context, _advFilter);
    if (result != null && mounted) setState(() => _advFilter = result);
  }

  /// 캘린더 셀 클릭 → 하단 시트로 그날 거래 내역 표시 (shrinkWrap 모드 — 자연 wrap).
  void _openDayDetailSheet(
    DateTime date,
    List<Expense> items,
    AsyncValue<List<dynamic>> categoriesAsync,
    bool masked,
  ) {
    showPSheet<void>(
      context,
      title: '${date.month}월 ${date.day}일 ${_koWeekday(date.weekday)}요일',
      shrinkWrap: true,
      contentBuilder: (ctx, _) => _DayDetailBody(
        items: items,
        categoriesAsync: categoriesAsync,
        masked: masked,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final categoriesAsync = ref.watch(categoriesProvider);
    final expensesAsync = ref.watch(monthExpensesProvider(_key));

    // LayoutBuilder 로 Scaffold body 가용 영역 측정 — calendar 모드는 viewport
    // 의 남은 공간을 캘린더가 정확히 채우도록 (스크롤 없이). Web 의 flex-1
    // min-h-0 과 동일 패턴.
    return LayoutBuilder(
      builder: (context, constraints) {
        // ListView padding 48 + Summary card(~130) + gap(12) = 190 차감
        // AssetFilterBadge 있으면 추가 52 차감
        final hasAssetBadge = _assetIdFilter != null;
        final calendarH = (constraints.maxHeight -
                190 -
                (hasAssetBadge ? 52 : 0))
            .clamp(280.0, double.infinity);
        return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(monthExpensesProvider(_key));
        await ref.read(monthExpensesProvider(_key).future);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x20,
          vertical: PSpace.x24,
        ),
        children: [
          // 본문 — 비동기 상태에 따라 분기
          expensesAsync.when(
            loading: () => _ExpensePageSkeleton(
              viewMode: _viewMode,
              calendarHeight: calendarH,
            ),
            error: (e, _) => _ErrorBox(
              message: '거래를 불러오지 못했습니다\n$e',
              onRetry: () => ref.invalidate(monthExpensesProvider(_key)),
            ),
            data: (raw) {
              final filtered =
                  raw
                      .where((e) {
                        switch (_filter) {
                          case _Filter.all:
                            return true;
                          case _Filter.expense:
                            return e.expenseType == 'EXPENSE';
                          case _Filter.income:
                            return e.expenseType == 'INCOME';
                        }
                      })
                      .where((e) {
                        if (_assetIdFilter != null &&
                            e.assetRowId != _assetIdFilter) {
                          return false;
                        }
                        if (_advFilter.categoryIds.isNotEmpty &&
                            !_advFilter.categoryIds.contains(e.categoryRowId)) {
                          return false;
                        }
                        if (_advFilter.assetIds.isNotEmpty &&
                            !_advFilter.assetIds.contains(e.assetRowId)) {
                          return false;
                        }
                        if (_advFilter.types.length < 2 &&
                            !_advFilter.types.contains(e.expenseType)) {
                          return false;
                        }
                        if (_advFilter.min != null &&
                            e.amount < _advFilter.min!) {
                          return false;
                        }
                        if (_advFilter.max != null &&
                            e.amount > _advFilter.max!) {
                          return false;
                        }
                        return true;
                      })
                      .toList()
                    ..sort(
                      (a, b) =>
                          (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''),
                    );

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

              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_assetIdFilter != null) ...[
                    _AssetFilterBadge(
                      assetId: _assetIdFilter!,
                      onClear: _clearAssetFilter,
                    ),
                    const SizedBox(height: PSpace.x12),
                  ],
                  _SummaryCard(
                    month: _month,
                    income: monthIncome,
                    expense: monthExpense,
                    masked: settings.hideAmounts,
                    onPrev: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1, 1),
                    ),
                    onNext: () => setState(
                      () => _month = DateTime(_month.year, _month.month + 1, 1),
                    ),
                    headerRight: _ViewModeToggle(
                      value: _viewMode,
                      onChanged: (v) => setState(() => _viewMode = v),
                    ),
                  ),
                  const SizedBox(height: PSpace.x12),
                  if (_viewMode == _ViewMode.calendar)
                    // 월 변경 시 refetch 중이면 (data + isLoading 동시) 캘린더 자체를
                    // skeleton 으로 대체 — cell 들이 "사용 금액 없는 것처럼" 보이는 현상 fix.
                    expensesAsync.isLoading
                        ? _ExpenseCalendarSkeleton(height: calendarH)
                        : _CalendarGrid(
                            month: _month,
                            expenses: raw,
                            masked: settings.hideAmounts,
                            height: calendarH,
                            onTapDate: (date, items) => _openDayDetailSheet(
                              date,
                              items,
                              categoriesAsync,
                              settings.hideAmounts,
                            ),
                          )
                  else ...[
                    _FilterRow(
                      value: _filter,
                      onChanged: (v) => setState(() => _filter = v),
                      advActive: !_advFilter.isEmpty,
                      advCount:
                          _advFilter.categoryIds.length +
                          _advFilter.assetIds.length +
                          (_advFilter.types.length < 2 ? 1 : 0) +
                          (_advFilter.min != null ? 1 : 0) +
                          (_advFilter.max != null ? 1 : 0),
                      onOpenFilter: _openFilter,
                      onAddTx: () => showAddTxSheet(context),
                    ),
                    const SizedBox(height: PSpace.x12),
                    if (expensesAsync.isLoading) ...const [
                      _ExpenseDayGroupSkeleton(rows: 3),
                      SizedBox(height: PSpace.x16),
                      _ExpenseDayGroupSkeleton(rows: 2),
                      SizedBox(height: PSpace.x16),
                      _ExpenseDayGroupSkeleton(rows: 2),
                    ] else if (groupKeys.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: PSpace.x32,
                        ),
                        child: Center(
                          child: Text(
                            '이 달에는 거래가 없습니다',
                            style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                          ),
                        ),
                      )
                    else
                      for (final key in groupKeys)
                        _DayGroup(
                          date: parseIsoDate(key),
                          items: groups[key]!,
                          categoriesAsync: categoriesAsync,
                          masked: settings.hideAmounts,
                          rowKeys: _rowKeys,
                          focusTxId: widget.focusTxId,
                        ),
                  ],
                ],
              );
              // focusTxId 가 있으면 첫 렌더 후 한 번만 스크롤.
              // 키 조회는 반드시 postFrameCallback 안에서 — _DayGroup 의 Builder
              // 자식이 build 된 뒤에야 _rowKeys 가 채워지기 때문.
              if (widget.focusTxId != null && !_scrolledToFocus) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final ctx = _rowKeys[widget.focusTxId!]?.currentContext;
                  if (ctx == null) return;
                  Scrollable.ensureVisible(
                    ctx,
                    duration: const Duration(milliseconds: 300),
                    alignment: 0.2,
                  );
                  _scrolledToFocus = true;
                });
              }
              return content;
            },
          ),
        ],
      ),
    );
      },
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
    this.headerRight,
  });
  final DateTime month;
  final int income;
  final int expense;
  final bool masked;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  /// month header row 우측 슬롯 (예: _ViewModeToggle). 클로드 디자인 정합.
  final Widget? headerRight;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final balance = income - expense;
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ArrowBtn(
                icon: LucideIcons.chevronLeft,
                onTap: onPrev,
                tokens: t,
              ),
              const SizedBox(width: 8),
              Text(
                '${month.year}년 ${month.month}월',
                style: TextStyle(
                  color: t.fgPrimary,
                  fontSize: PFontSize.bodyLg,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.32,
                ),
              ),
              const SizedBox(width: 8),
              _ArrowBtn(
                icon: LucideIcons.chevronRight,
                onTap: onNext,
                tokens: t,
              ),
              if (headerRight != null) ...[const Spacer(), headerRight!],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: '수입',
                  value: krwMasked(income, masked, sign: true),
                  color: t.fgIncome,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: '지출',
                  value: krwMasked(-expense, masked, sign: true),
                  color: t.fgExpense,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: '합계',
                  value: krwMasked(balance, masked, sign: true),
                  color: t.fgBrandStrong,
                ),
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
  const _ArrowBtn({
    required this.icon,
    required this.onTap,
    required this.tokens,
  });
  final IconData icon;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brFull,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Icon(icon, size: 18, color: tokens.fgSecondary),
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
        Text(
          label,
          style: PTypo.micro.copyWith(
            color: t.fgTertiary,
            fontWeight: PFontWeight.medium,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: PFontSize.bodyLg,
            fontWeight: PFontWeight.bold,
            letterSpacing: -0.24,
          ),
        ),
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
                  PChip(
                    label: switch (f) {
                      _Filter.all => '전체',
                      _Filter.expense => '지출',
                      _Filter.income => '수입',
                    },
                    selected: f == value,
                    size: PChipSize.sm,
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
                color: advActive ? t.borderBrand : t.borderSubtle,
              ),
              borderRadius: PRadius.brSm,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.slidersHorizontal,
                  size: 18,
                  color: advActive ? t.fgBrand : t.fgSecondary,
                ),
                if (advActive && advCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: PBadge(
                      label: '$advCount',
                      variant: PBadgeVariant.primary,
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
              color: t.bgBrandSolid,
              borderRadius: PRadius.brSm,
            ),
            child: Icon(LucideIcons.plus, size: 18, color: t.fgOnBrand),
          ),
        ),
      ],
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
    this.rowKeys,
    this.focusTxId,
  });
  final DateTime date;
  final List<Expense> items;
  final AsyncValue<dynamic> categoriesAsync;
  final bool masked;
  final Map<int, GlobalKey>? rowKeys;
  final int? focusTxId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final label = formatDay(date);
    final dayExpense = items
        .where((e) => e.expenseType == 'EXPENSE')
        .fold<int>(0, (s, e) => s + e.amount);
    final dayIncome = items
        .where((e) => e.expenseType == 'INCOME')
        .fold<int>(0, (s, e) => s + e.amount);
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return Padding(
      padding: const EdgeInsets.only(bottom: PSpace.x12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x4,
              vertical: PSpace.x8,
            ),
            child: Row(
              children: [
                Text(
                  label.md,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const SizedBox(width: PSpace.x8),
                Text(
                  label.dow,
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                ),
                const Spacer(),
                if (dayExpense > 0)
                  Text(
                    krwSigned(dayExpense, masked, sign: '−', unit: true),
                    style: PTypo.caption.copyWith(
                      color: t.fgExpense,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                if (dayIncome > 0) ...[
                  if (dayExpense > 0) const SizedBox(width: PSpace.x8),
                  Text(
                    krwSigned(dayIncome, masked, sign: '+', unit: true),
                    style: PTypo.caption.copyWith(
                      color: t.fgIncome,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  Builder(
                    builder: (_) {
                      final isFocus = focusTxId == items[i].rowId;
                      final k = isFocus
                          ? (rowKeys?.putIfAbsent(
                              items[i].rowId,
                              () => GlobalKey(),
                            ))
                          : null;
                      return Container(
                        key: k,
                        decoration: isFocus
                            ? BoxDecoration(
                                color: t.bgBrandSubtle,
                                borderRadius: PRadius.brSm,
                              )
                            : null,
                        child: ExpenseRow(
                          expense: items[i],
                          category: items[i].categoryRowId == null
                              ? null
                              : categories.byRowId(items[i].categoryRowId!),
                          masked: masked,
                        ),
                      );
                    },
                  ),
                  if (i < items.length - 1) PDivider(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 자산 필터 활성 시 상단에 표시되는 chip — '<자산명> 필터 중 ✕'.
/// front `AssetFilterBadge` 미러.
class _AssetFilterBadge extends ConsumerWidget {
  const _AssetFilterBadge({required this.assetId, required this.onClear});
  final int assetId;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    // assetsProvider 캐시 우선, 없으면 단건 fetch.
    final all = ref.watch(assetsProvider).value;
    final cached = all?.byRowId(assetId);
    final asyncFallback = cached == null
        ? ref.watch(assetByIdProvider(assetId))
        : null;
    final name = cached?.assetName ?? asyncFallback?.value?.assetName;
    final label = name == null ? '필터 중' : '$name 필터 중';
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: t.bgBrandSubtle,
        border: Border.all(color: t.borderBrand),
        borderRadius: PRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: PTypo.bodySm.copyWith(
              color: t.fgBrandStrong,
              fontWeight: PFontWeight.semi,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onClear,
            borderRadius: PRadius.brFull,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(LucideIcons.x, size: 14, color: t.fgBrand),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expense 페이지 구조 맞춤 skeleton — Web ExpensePageSkeleton 정합.
/// viewMode 따라 본문 분기 (calendar = grid placeholder, list = DayGroup x3).
class _ExpensePageSkeleton extends StatelessWidget {
  const _ExpensePageSkeleton({
    required this.viewMode,
    required this.calendarHeight,
  });
  final _ViewMode viewMode;
  final double calendarHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _ExpenseSummarySkeleton(),
        const SizedBox(height: PSpace.x12),
        if (viewMode == _ViewMode.calendar)
          _ExpenseCalendarSkeleton(height: calendarHeight)
        else ...const [
          _ExpenseChipsSkeleton(),
          SizedBox(height: PSpace.x12),
          _ExpenseDayGroupSkeleton(rows: 3),
          SizedBox(height: PSpace.x16),
          _ExpenseDayGroupSkeleton(rows: 2),
          SizedBox(height: PSpace.x16),
          _ExpenseDayGroupSkeleton(rows: 2),
        ],
      ],
    );
  }
}

/// Calendar grid skeleton — viewMode=calendar (default) 외곽 카드 + 7-col 요일 헤더 + 6주 cell grid.
/// SizedBox(height: 420) — ExpenseCalendar 본체와 동일 높이.
class _ExpenseCalendarSkeleton extends StatelessWidget {
  const _ExpenseCalendarSkeleton({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: height,
      child: PCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // 요일 헤더 (일~토)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.borderSubtle)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: PSpace.x8),
                child: Row(
                  children: [
                    for (int i = 0; i < 7; i++)
                      const Expanded(
                        child: Center(
                          child: PSkeleton.line(width: 16, height: 11),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // 6주 × 7일 cell grid — Expanded 로 남은 영역 균등 분배
            Expanded(
              child: Column(
                children: [
                  for (int w = 0; w < 6; w++)
                    Expanded(
                      child: Row(
                        children: [
                          for (int d = 0; d < 7; d++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(PSpace.x4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    PSkeleton(
                                      width: 16,
                                      height: 16,
                                      borderRadius: PRadius.brFull,
                                    ),
                                    Spacer(),
                                    PSkeleton.line(width: 32, height: 8),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseSummarySkeleton extends StatelessWidget {
  const _ExpenseSummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: const EdgeInsets.all(PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 월 헤더 (arrow + label + arrow)
          Row(
            children: const [
              PSkeleton(width: 28, height: 28, borderRadius: PRadius.brSm),
              SizedBox(width: PSpace.x8),
              PSkeleton.line(width: 96, height: 18),
              SizedBox(width: PSpace.x8),
              PSkeleton(width: 28, height: 28, borderRadius: PRadius.brSm),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          // 3-col (수입/지출/합계)
          Row(
            children: const [
              Expanded(child: _Stat3Placeholder()),
              Expanded(child: _Stat3Placeholder()),
              Expanded(child: _Stat3Placeholder()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat3Placeholder extends StatelessWidget {
  const _Stat3Placeholder();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        PSkeleton.line(width: 32, height: 11),
        SizedBox(height: PSpace.x8),
        PSkeleton.line(width: 80, height: 16),
      ],
    );
  }
}

class _ExpenseChipsSkeleton extends StatelessWidget {
  const _ExpenseChipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // chips (3개) — 좌측 flex
        Expanded(
          child: Row(
            children: const [
              PSkeleton(width: 56, height: 28, borderRadius: PRadius.brFull),
              SizedBox(width: PSpace.x4),
              PSkeleton(width: 56, height: 28, borderRadius: PRadius.brFull),
              SizedBox(width: PSpace.x4),
              PSkeleton(width: 56, height: 28, borderRadius: PRadius.brFull),
            ],
          ),
        ),
        const SizedBox(width: PSpace.x8),
        // 우측 icon button 2개 (view-mode + filter)
        const PSkeleton(width: 32, height: 32, borderRadius: PRadius.brSm),
        const SizedBox(width: PSpace.x4),
        const PSkeleton(width: 32, height: 32, borderRadius: PRadius.brSm),
      ],
    );
  }
}

/// list mode skeleton — viewMode='list' 일 때 날짜 헤더 + 카드 안 rows 모양.
class _ExpenseDayGroupSkeleton extends StatelessWidget {
  const _ExpenseDayGroupSkeleton({required this.rows});
  final int rows;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 날짜 헤더 — 카드 밖 평문
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x4,
            vertical: PSpace.x8,
          ),
          child: Row(
            children: const [
              PSkeleton.line(width: 48, height: 14),
              SizedBox(width: PSpace.x8),
              PSkeleton.line(width: 24, height: 14),
              Spacer(),
              PSkeleton.line(width: 60, height: 12),
              SizedBox(width: PSpace.x8),
              PSkeleton.line(width: 60, height: 12),
            ],
          ),
        ),
        // 거래 카드 — rows 만큼 row 들 + 사이 border
        PCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < rows; i++)
                Container(
                  decoration: BoxDecoration(
                    border: i > 0
                        ? Border(top: BorderSide(color: t.borderSubtle))
                        : null,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x12,
                    vertical: PSpace.x12,
                  ),
                  child: Row(
                    children: [
                      const PSkeleton(
                        width: 36,
                        height: 36,
                        borderRadius: PRadius.brSm,
                      ),
                      const SizedBox(width: PSpace.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            PSkeleton.line(width: 120, height: 14),
                            SizedBox(height: PSpace.x4),
                            PSkeleton.line(width: 80, height: 11),
                          ],
                        ),
                      ),
                      const SizedBox(width: PSpace.x8),
                      const PSkeleton.line(width: 80, height: 14),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
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
          PButton(
            label: '다시 시도',
            variant: PButtonVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// 보기 모드 토글 — 단일 button. 현재 mode 의 반대 표시 (calendar 모드면 '목록').
class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.value, required this.onChanged});
  final _ViewMode value;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final isCalendar = value == _ViewMode.calendar;
    return Align(
      alignment: Alignment.centerLeft,
      child: PButton(
        label: isCalendar ? '목록' : '달력',
        icon: isCalendar ? LucideIcons.list : LucideIcons.calendar,
        variant: PButtonVariant.ghost,
        size: PButtonSize.sm,
        onPressed: () =>
            onChanged(isCalendar ? _ViewMode.list : _ViewMode.calendar),
      ),
    );
  }
}

String _koWeekday(int weekday) =>
    const ['', '월', '화', '수', '목', '금', '토', '일'][weekday];

/// 7×6 캘린더 grid — 날짜 + 그 날의 income/expense 합계 표시.
/// 셀 클릭 시 [onTapDate] 으로 그날 거래 list 전달.
/// [height] 가 0 이면 부모(Expanded 등)가 size 결정 — 그 외에는 SizedBox 로 강제.
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.expenses,
    required this.masked,
    required this.onTapDate,
    required this.height,
  });
  final DateTime month;
  final List<Expense> expenses;
  final bool masked;
  final void Function(DateTime date, List<Expense> items) onTapDate;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final firstDay = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDay.weekday % 7; // Sunday = 0
    final gridStart = firstDay.subtract(Duration(days: firstWeekday));
    // 주 수 가변 (4~6) — Web getCalendarCells 정합. 다음 달 일주일 강제 표시 X.
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final weeksCount = ((firstWeekday + daysInMonth) / 7).ceil();
    final today = DateTime.now();
    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    // 거래를 날짜별로 group
    final byDay = <String, List<Expense>>{};
    for (final e in expenses) {
      final d = e.expenseDateOnly ?? '';
      byDay.putIfAbsent(d, () => []).add(e);
    }
    String key(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    // 셀 사이 border grid — 셀 자체 Container.decoration.border 로 그림.
    // outer 카드 시각: PCard default (shadow variant — spec card.md SoT).
    final borderColor = t.borderSubtle;
    // viewport 의 남은 공간을 채우도록 호출처에서 LayoutBuilder 로 정확 계산한
    // height 받음. Web 의 `flex-1 min-h-0` 와 동일 패턴.
    return SizedBox(
      height: height,
      child: PCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 요일 헤더 — 일/월/화/수/목/금/토. 일=fgExpense(빨강), 토=fgBrand(파랑).
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  for (final wd in const ['일', '월', '화', '수', '목', '금', '토'])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: PSpace.x8,
                        ),
                        child: Text(
                          wd,
                          textAlign: TextAlign.center,
                          style: PTypo.caption.copyWith(
                            color: wd == '일'
                                ? t.fgExpense
                                : wd == '토'
                                ? t.fgBrand
                                : t.fgSecondary,
                            fontWeight: PFontWeight.medium,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 4~6 주 × 7 요일 grid — 각 row 를 Expanded 로 균등 분배 (외곽 420 안).
            // 셀에 border (right + bottom). 마지막 row/col 은 외곽 border 와
            // 겹치지 않게 inner only.
            for (int week = 0; week < weeksCount; week++)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int dow = 0; dow < 7; dow++)
                      Expanded(
                        child: () {
                          final date = gridStart.add(
                            Duration(days: week * 7 + dow),
                          );
                          final inMonth = date.month == month.month;
                          final isToday = isSameDay(date, today);
                          final items = byDay[key(date)] ?? const <Expense>[];
                          final income = items
                              .where((e) => e.expenseType == 'INCOME')
                              .fold<int>(0, (s, e) => s + e.amount);
                          final expense = items
                              .where((e) => e.expenseType == 'EXPENSE')
                              .fold<int>(0, (s, e) => s + e.amount);
                          // 요일 기본색(일=빨강, 토=파랑, 평일=primary) — in/out-of-month 공통.
                          final weekdayColor = dow == 0
                              ? t.fgExpense // 일요일 빨강
                              : dow == 6
                              ? t.fgBrand // 토요일 파랑
                              : t.fgPrimary;
                          // web 정합: 이전/다음 달 셀도 요일색 유지 + opacity 음영만
                          // (요일 무관 회색 아님). 당월 오늘만 onBrand(원형 강조).
                          final dayColor = !inMonth
                              ? weekdayColor.withValues(alpha: 0.4)
                              : isToday
                              ? t.fgOnBrand
                              : weekdayColor;
                          // 모바일 — 셀 사이 grid 선 제거 (사용자 요청).
                          // 외곽 Container 의 border 만 남아 카드 외형 유지.
                          return DecoratedBox(
                            decoration: const BoxDecoration(),
                            child: InkWell(
                              onTap: items.isEmpty
                                  ? null
                                  : () => onTapDate(date, items),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 6,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 날짜 — today 면 동그라미 배경 + 흰 글씨. 22→20 으로 압축.
                                    Container(
                                      width: 22,
                                      height: 22,
                                      alignment: Alignment.center,
                                      decoration: isToday
                                          ? BoxDecoration(
                                              color: t.bgBrand,
                                              shape: BoxShape.circle,
                                            )
                                          : null,
                                      child: Text(
                                        '${date.day}',
                                        style: PTypo.caption.copyWith(
                                          color: dayColor,
                                          fontWeight: isToday
                                              ? PFontWeight.bold
                                              : PFontWeight.semi,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    // FittedBox(scaleDown) — 셀 폭 초과 시 폰트 자동 축소.
                                    if (expense > 0)
                                      SizedBox(
                                        width: double.infinity,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '${masked ? '' : '−'}${_compact(expense, masked)}',
                                            maxLines: 1,
                                            style: PTypo.micro.copyWith(
                                              color: t.fgExpense,
                                              fontWeight: PFontWeight.semi,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (income > 0)
                                      SizedBox(
                                        width: double.infinity,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            '${masked ? '' : '+'}${_compact(income, masked)}',
                                            maxLines: 1,
                                            style: PTypo.micro.copyWith(
                                              color: t.fgIncome,
                                              fontWeight: PFontWeight.semi,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }(),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 캘린더 셀용 짧은 금액 표기 — 천 단위 콤마 유지하되 dialog 의 풀 표시와 별개로
/// 셀 폭이 좁아서 약식 표기. masked 면 '••••'(compact 4점 — web 캘린더 셀 fallback).
String _compact(int amount, bool masked) {
  if (masked) return '••••';
  // amount 가 양수만 — formatter 가 부호는 caller 가 붙임.
  return krwMasked(amount, false);
}

/// 캘린더 셀 클릭 시트 본문 — 합계 카드 + 거래 list.
class _DayDetailBody extends StatelessWidget {
  const _DayDetailBody({
    required this.items,
    required this.categoriesAsync,
    required this.masked,
  });
  final List<Expense> items;
  final AsyncValue<List<dynamic>> categoriesAsync;
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categories = categoriesAsync.value ?? const <dynamic>[];
    final income = items
        .where((e) => e.expenseType == 'INCOME')
        .fold<int>(0, (s, e) => s + e.amount);
    final expense = items
        .where((e) => e.expenseType == 'EXPENSE')
        .fold<int>(0, (s, e) => s + e.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x20,
        PSpace.x4,
        PSpace.x20,
        PSpace.x16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 합계 카드 — bordered + 좌측 '건수' + 우측 수입/지출
          PCard(
            variant: PCardVariant.bordered,
            padding: const EdgeInsets.symmetric(
              horizontal: PSpace.lg,
              vertical: PSpace.md,
            ),
            child: Row(
              children: [
                Text(
                  '${items.length}건',
                  style: PTypo.bodySm.copyWith(
                    color: t.fgSecondary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const Spacer(),
                if (income > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '수입',
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        krwSigned(income, masked, sign: '+', unit: true),
                        style: PTypo.bodySm.copyWith(
                          color: t.fgIncome,
                          fontWeight: PFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (income > 0 && expense > 0) const SizedBox(width: PSpace.lg),
                if (expense > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '지출',
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        krwSigned(expense, masked, sign: '−', unit: true),
                        style: PTypo.bodySm.copyWith(
                          color: t.fgExpense,
                          fontWeight: PFontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.lg),
          // 거래 list — ExpenseRow 재사용
          for (final e in items)
            ExpenseRow(
              expense: e,
              category: e.categoryRowId == null
                  ? null
                  : categories
                        .cast<dynamic>()
                        .where((c) => c.rowId == e.categoryRowId)
                        .cast<dynamic>()
                        .firstOrNull,
              masked: masked,
            ),
        ],
      ),
    );
  }
}
