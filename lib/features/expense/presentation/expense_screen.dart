import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/format_locale.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/expense/presentation/filter_dialog.dart';
import 'package:porest_desk_app/features/expense/presentation/widgets/expense_row.dart';

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

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  late DateTime _month = _resolveInitialMonth();
  ExpenseFilter _advFilter = const ExpenseFilter();
  int? _assetIdFilter;
  final Map<int, GlobalKey> _rowKeys = {};
  bool _scrolledToFocus = false;

  // txm 통합 뷰 상태 — 접이식 캘린더/소비 요약/선택일.
  bool _expanded = false;
  bool _sumOpen = false;
  String? _selected;
  final Map<String, GlobalKey> _dayKeys = {};
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _assetIdFilter = widget.initialAssetId;
    final today = DateTime.now();
    if (today.year == _month.year && today.month == _month.month) {
      _selected = _ymdOf(today);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
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
    final m = _month;
    final monthQ = '${m.year}-${m.month.toString().padLeft(2, '0')}';
    context.go('/expense?month=$monthQ');
  }

  MonthKey get _key => (year: _month.year, month: _month.month);
  MonthKey get _prevKey {
    final p = DateTime(_month.year, _month.month - 1, 1);
    return (year: p.year, month: p.month);
  }

  Future<void> _openFilter() async {
    final result = await showFilterDialog(context, _advFilter);
    if (result != null && mounted) setState(() => _advFilter = result);
  }

  /// 기간 필터 범위 — web computeFilterRange 미러 (클라 필터, v0.1).
  /// null = 제한 없음(custom+날짜 미입력·month 는 월 뷰 그대로).
  (String?, String?) _periodRange(ExpenseFilter f) {
    switch (f.period) {
      case FilterPeriod.custom:
        if ((f.startDate ?? '').isNotEmpty && (f.endDate ?? '').isNotEmpty) {
          return (f.startDate, f.endDate);
        }
        return (null, null);
      case FilterPeriod.month:
        return (null, null);
      case FilterPeriod.week:
        final today = DateTime.now();
        final dow = today.weekday % 7; // 0=Sun
        final monday = today.add(Duration(days: dow == 0 ? -6 : 1 - dow));
        return (_ymdOf(monday), _ymdOf(monday.add(const Duration(days: 6))));
      case FilterPeriod.threeMonth:
        final today = DateTime.now();
        return (
          _ymdOf(DateTime(today.year, today.month - 2, 1)),
          _ymdOf(today),
        );
    }
  }

  static String _ymdOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 월 라벨 — ko "7월" / en "Jul" (monthnav·prevbtn·empty 공용, web txmMonthLabel 정합).
  static String _monthLabel(DateTime m) => localeIsEn()
      ? const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m.month - 1]
      : '${m.month}월';

  void _goMonth(int dir) {
    final next = DateTime(_month.year, _month.month + dir, 1);
    final today = DateTime.now();
    setState(() {
      _month = next;
      _expanded = false;
      _selected = (today.year == next.year && today.month == next.month)
          ? _ymdOf(today)
          : null;
    });
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _scrollToDay(String ds) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _dayKeys[ds]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 300), alignment: 0.05);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final categoriesAsync = ref.watch(categoriesProvider);
    final expensesAsync = ref.watch(monthExpensesProvider(_key));
    // 인사이트(지난달 대비) — 지난달 거래도 함께 구독(family 캐시).
    final prevAsync = ref.watch(monthExpensesProvider(_prevKey));

    return RefreshIndicator(
      color: t.bgBrand,
      onRefresh: () async {
        ref.invalidate(monthExpensesProvider(_key));
        await ref.read(monthExpensesProvider(_key).future);
      },
      // txm 통합 뷰(design tx-mobile.jsx) — 페이지 좌우 0, 섹션별 자체 inset.
      child: ListView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(0, 10, 0, 28),
        children: [
          expensesAsync.when(
            loading: () => const _TxmSkeleton(),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: PSpace.x20),
              child: _ErrorBox(
                message: '${l.expLoadError}\n$e',
                onRetry: () => ref.invalidate(monthExpensesProvider(_key)),
              ),
            ),
            data: (raw) {
              final selectedCats = _advFilter.categoryIds;
              final cats = categoriesAsync.value;
              final Set<int>? allowedCats = selectedCats.isEmpty
                  ? null
                  : {
                      ...selectedCats,
                      if (cats != null)
                        for (final c in cats)
                          if (c.parentRowId != null &&
                              selectedCats.contains(c.parentRowId))
                            c.rowId,
                    };
              final (pStart, pEnd) = _periodRange(_advFilter);
              final filtered =
                  raw
                      .where((e) {
                        // 기간 필터(클라) — 월 데이터와의 교집합만 표시.
                        final d = e.expenseDateOnly ?? '';
                        if (pStart != null && d.compareTo(pStart) < 0) {
                          return false;
                        }
                        if (pEnd != null && d.compareTo(pEnd) > 0) {
                          return false;
                        }
                        if (_assetIdFilter != null &&
                            e.assetRowId != _assetIdFilter) {
                          return false;
                        }
                        if (allowedCats != null &&
                            !(allowedCats.contains(e.categoryRowId) ||
                                e.splitCategoryRowIds.any(allowedCats.contains))) {
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

              // 일별 합계 — 캘린더 셀 밑 금액 (필터 적용분 기준).
              final byDay = <String, ({int out, int inn})>{};
              for (final e in filtered) {
                final d = e.expenseDateOnly ?? '';
                final cur = byDay[d] ?? (out: 0, inn: 0);
                byDay[d] = e.expenseType == 'EXPENSE'
                    ? (out: cur.out + e.amount.abs(), inn: cur.inn)
                    : (out: cur.out, inn: cur.inn + e.amount.abs());
              }

              final groups = <String, List<Expense>>{};
              for (final e in filtered) {
                final d = e.expenseDateOnly ?? '';
                groups.putIfAbsent(d, () => []).add(e);
              }
              final groupKeys = groups.keys.toList();
              _dayKeys.removeWhere((k, _) => !groups.containsKey(k));
              for (final k in groupKeys) {
                _dayKeys.putIfAbsent(k, () => GlobalKey());
              }

              final advCount =
                  _advFilter.categoryIds.length +
                  _advFilter.assetIds.length +
                  // web filterActiveCount 정합 — 기본(custom) 외 기간 선택도 카운트.
                  (_advFilter.period != FilterPeriod.custom ? 1 : 0) +
                  (pStart != null && _advFilter.period == FilterPeriod.custom ? 1 : 0) +
                  (_advFilter.types.length < 2 ? 1 : 0) +
                  (_advFilter.min != null ? 1 : 0) +
                  (_advFilter.max != null ? 1 : 0);

              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TxmMonthNav(
                    label: _monthLabel(_month),
                    onPrev: () => _goMonth(-1),
                    onNext: () => _goMonth(1),
                    filterActive: advCount > 0,
                    filterCount: advCount,
                    onOpenFilter: _openFilter,
                    onAddTx: () => showAddTxSheet(context),
                    tokens: t,
                  ),
                  if (_assetIdFilter != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(PSpace.x20, 8, PSpace.x20, 0),
                      child: _AssetFilterBadge(
                        assetId: _assetIdFilter!,
                        onClear: _clearAssetFilter,
                      ),
                    ),
                  // 총액 + 인사이트 + [소비 요약]
                  Padding(
                    padding: const EdgeInsets.fromLTRB(PSpace.x20, 8, PSpace.x20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                krwSigned(monthExpense, settings.hideAmounts, unit: true),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.56,
                                  height: 1.15,
                                  color: t.fgPrimary,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              Builder(builder: (_) {
                                final ins = _insight(
                                  l, t, raw, monthExpense,
                                  prevAsync.value, categoriesAsync.value,
                                );
                                if (ins == null) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: ins,
                                );
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: PSpace.x12),
                        _TxmSumBtn(
                          on: _sumOpen,
                          label: l.txmSpendSummary,
                          onTap: () => setState(() => _sumOpen = !_sumOpen),
                          tokens: t,
                        ),
                      ],
                    ),
                  ),
                  if (_sumOpen)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(PSpace.x20, 14, PSpace.x20, 0),
                      child: PCard(
                        variant: PCardVariant.raised,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            _TxmSummaryRow(
                              label: l.expSummaryIncome,
                              value: krwSigned(monthIncome, settings.hideAmounts, sign: '+', unit: true),
                              valueColor: t.fgBrand,
                              tokens: t,
                            ),
                            Divider(height: 1, thickness: 1, color: t.borderSubtle),
                            _TxmSummaryRow(
                              label: l.expSummaryExpense,
                              value: krwSigned(monthExpense, settings.hideAmounts, sign: '−', unit: true),
                              valueColor: t.fgExpense,
                              tokens: t,
                            ),
                            Divider(height: 1, thickness: 1, color: t.borderSubtle),
                            _TxmSummaryRow(
                              label: l.expTotal,
                              value: krwSigned(
                                (monthIncome - monthExpense).abs(),
                                settings.hideAmounts,
                                sign: monthIncome - monthExpense >= 0 ? '+' : '−',
                                unit: true,
                              ),
                              valueColor: t.fgPrimary,
                              emphasize: true,
                              tokens: t,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // 캘린더 — 필터 적용 시 숨김(리스트만, 사용자 결정·web 정합).
                  if (!(advCount > 0 || _assetIdFilter != null)) ...[
                  _TxmCalendar(
                    month: _month,
                    selected: _selected,
                    expanded: _expanded,
                    byDay: byDay,
                    masked: settings.hideAmounts,
                    onSelect: (ds) {
                      setState(() => _selected = ds);
                      if (byDay.containsKey(ds)) _scrollToDay(ds);
                    },
                    onToggleExpand: () => setState(() => _expanded = !_expanded),
                    tokens: t,
                  ),
                  ],
                  Container(height: 1, color: t.borderDefault),
                  // 거래 리스트 — 날짜 그룹
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: PSpace.x20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (groupKeys.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(LucideIcons.receiptText, size: 36, color: t.fgTertiary),
                                  const SizedBox(height: 12),
                                  Text(
                                    l.txmEmptyMonth(_monthLabel(_month)),
                                    style: PTypo.bodySm.copyWith(
                                      color: t.fgPrimary,
                                      fontWeight: PFontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l.txmEmptyMonthDesc,
                                    textAlign: TextAlign.center,
                                    style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final key in groupKeys)
                            KeyedSubtree(
                              key: _dayKeys[key],
                              child: _DayGroup(
                                date: parseIsoDate(key),
                                items: groups[key]!,
                                categoriesAsync: categoriesAsync,
                                masked: settings.hideAmounts,
                                rowKeys: _rowKeys,
                                focusTxId: widget.focusTxId,
                              ),
                            ),
                      ],
                    ),
                  ),
                  // 이전 달 이용 내역 보기
                  Padding(
                    padding: const EdgeInsets.fromLTRB(PSpace.x20, 28, PSpace.x20, 0),
                    child: Material(
                      color: t.bgSunken,
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                      child: InkWell(
                        onTap: () => _goMonth(-1),
                        borderRadius: const BorderRadius.all(Radius.circular(14)),
                        child: SizedBox(
                          height: 52,
                          child: Center(
                            child: Text(
                              l.txmPrevMonthBtn(_monthLabel(
                                DateTime(_month.year, _month.month - 1, 1),
                              )),
                              style: TextStyle(
                                fontSize: PFontSize.bodyMd,
                                color: t.fgPrimary,
                                fontWeight: PFontWeight.semi,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
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
  }

  /// 인사이트 한 줄 — 지난달 대비(덜/더/비슷) / 없으면 최다 지출 카테고리.
  Widget? _insight(
    AppLocalizations l,
    PorestTokens t,
    List<Expense> raw,
    int monthExpense,
    List<Expense>? prevRaw,
    List<ExpenseCategory>? categories,
  ) {
    final subStyle = PTypo.bodySm.copyWith(color: t.fgSecondary);
    if (raw.isEmpty) return Text(l.txmInsightNone, style: subStyle);
    final prevOut = (prevRaw ?? const <Expense>[])
        .where((e) => e.expenseType == 'EXPENSE')
        .fold<int>(0, (s, e) => s + e.amount);
    if (prevOut > 0) {
      final diff = prevOut - monthExpense;
      final man = (diff.abs() / 10000).round();
      if (man < 1) return Text(l.txmInsightSame, style: subStyle);
      final amount = localeIsEn() ? '₩${krw(diff.abs())}' : '${krw(man)}만원';
      final less = diff > 0;
      return Text.rich(
        TextSpan(
          style: subStyle,
          children: [
            TextSpan(text: less ? l.txmInsightLessPre : l.txmInsightMorePre),
            TextSpan(
              text: less ? l.txmInsightLessHl(amount) : l.txmInsightMoreHl(amount),
              style: TextStyle(
                fontWeight: PFontWeight.bold,
                color: less ? t.fgBrand : t.fgExpense,
              ),
            ),
            TextSpan(text: less ? l.txmInsightLessPost : l.txmInsightMorePost),
          ],
        ),
      );
    }
    // 최다 지출 카테고리 fallback.
    final byCat = <int?, int>{};
    for (final e in raw.where((e) => e.expenseType == 'EXPENSE')) {
      byCat[e.categoryRowId] = (byCat[e.categoryRowId] ?? 0) + e.amount.abs();
    }
    if (byCat.isEmpty) return null;
    final topId = (byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;
    final topName = topId == null ? null : categories?.byRowId(topId)?.categoryName;
    if (topName == null) return null;
    return Text.rich(
      TextSpan(
        style: subStyle,
        children: [
          TextSpan(text: l.txmInsightTopCatPre),
          TextSpan(
            text: topName,
            style: TextStyle(fontWeight: PFontWeight.bold, color: t.fgBrand),
          ),
          TextSpan(text: l.txmInsightTopCatPost),
        ],
      ),
    );
  }
}

/// 월 네비 — ‹ M월 › + 우측 필터·추가 (design .txm-monthnav).
class _TxmMonthNav extends StatelessWidget {
  const _TxmMonthNav({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.filterActive,
    required this.filterCount,
    required this.onOpenFilter,
    required this.onAddTx,
    required this.tokens,
  });
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool filterActive;
  final int filterCount;
  final VoidCallback onOpenFilter;
  final VoidCallback onAddTx;
  final PorestTokens tokens;

  Widget _btn(IconData icon, VoidCallback onTap,
      {Color? bg, Color? fg, Widget? badge}) {
    return Material(
      color: bg ?? Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 19, color: fg ?? tokens.fgSecondary),
              if (badge != null) Positioned(right: -2, top: -2, child: badge),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _btn(LucideIcons.chevronLeft, onPrev),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.17,
                color: t.fgPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          _btn(LucideIcons.chevronRight, onNext),
          const Spacer(),
          _btn(
            LucideIcons.slidersHorizontal,
            onOpenFilter,
            bg: filterActive ? t.bgBrandSubtle : null,
            fg: filterActive ? t.fgBrandStrong : t.fgSecondary,
            badge: filterActive && filterCount > 0
                ? PBadge(label: '$filterCount', variant: PBadgeVariant.primary)
                : null,
          ),
          _btn(LucideIcons.plus, onAddTx),
        ],
      ),
    );
  }
}

/// [소비 요약] 토글 버튼 (design .txm-sumbtn).
class _TxmSumBtn extends StatelessWidget {
  const _TxmSumBtn({
    required this.on,
    required this.label,
    required this.onTap,
    required this.tokens,
  });
  final bool on;
  final String label;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Material(
      color: on ? t.bgBrandSubtle : Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: on ? t.borderBrand : t.borderDefault),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Text(
            label,
            style: PTypo.bodySm.copyWith(
              color: on ? t.fgBrandStrong : t.fgPrimary,
              fontWeight: PFontWeight.semi,
            ),
          ),
        ),
      ),
    );
  }
}

/// 소비 요약 패널 행 (design .txm-summary__row).
class _TxmSummaryRow extends StatelessWidget {
  const _TxmSummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.tokens,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final Color valueColor;
  final bool emphasize;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: PTypo.body.copyWith(
              color: emphasize ? t.fgPrimary : t.fgSecondary,
              fontWeight: emphasize ? PFontWeight.semi : PFontWeight.regular,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: PFontSize.bodyMd,
              color: valueColor,
              fontWeight: PFontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// 접이식 캘린더 — 접힘: 선택 주 1줄 / 펼침: 월 전체 (design .txm-cal).
class _TxmCalendar extends StatelessWidget {
  const _TxmCalendar({
    required this.month,
    required this.selected,
    required this.expanded,
    required this.byDay,
    required this.masked,
    required this.onSelect,
    required this.onToggleExpand,
    required this.tokens,
  });
  final DateTime month;
  final String? selected;
  final bool expanded;
  final Map<String, ({int out, int inn})> byDay;
  final bool masked;
  final ValueChanged<String> onSelect;
  final VoidCallback onToggleExpand;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final today = DateTime.now();
    final todayStr = _ExpenseScreenState._ymdOf(today);
    final firstDow = DateTime(month.year, month.month, 1).weekday % 7;
    final dim = DateTime(month.year, month.month + 1, 0).day;
    final cells = <({int d, String ds})?>[];
    for (var i = 0; i < firstDow; i++) {
      cells.add(null);
    }
    for (var d = 1; d <= dim; d++) {
      cells.add((
        d: d,
        ds: '${month.year}-${month.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}',
      ));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final weeks = <List<({int d, String ds})?>>[];
    for (var i = 0; i < cells.length; i += 7) {
      weeks.add(cells.sublist(i, i + 7));
    }
    var selWeek = weeks.indexWhere((w) => w.any((c) => c != null && c.ds == selected));
    if (selWeek < 0) {
      selWeek = weeks.indexWhere((w) => w.any((c) => c != null && c.ds == todayStr));
    }
    if (selWeek < 0) selWeek = 0;

    Color numColor(String ds, int dow) {
      if (ds.compareTo(todayStr) > 0) return t.fgTertiary;
      if (dow == 0) return t.fgExpense;
      if (dow == 6) return t.fgBrand;
      return t.fgPrimary;
    }

    Widget cell(({int d, String ds})? c, int i) {
      if (c == null) return const Expanded(child: SizedBox(height: 56));
      final isSel = c.ds == selected;
      final data = byDay[c.ds];
      final amt = data == null
          ? ''
          : data.out > 0
              ? '-${masked ? '••••' : krw(data.out)}'
              : '+${masked ? '••••' : krw(data.inn)}';
      final future = c.ds.compareTo(todayStr) > 0;
      return Expanded(
        child: InkWell(
          onTap: () => onSelect(c.ds),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
            child: Column(
              children: [
                Container(
                  width: 33,
                  height: 33,
                  alignment: Alignment.center,
                  decoration: isSel
                      // 채움은 다크에서도 primary 고정(bgBrandSolid) — 캘린더 선택일.
                      ? BoxDecoration(color: t.bgBrandSolid, shape: BoxShape.circle)
                      : null,
                  child: Opacity(
                    opacity: !isSel && future ? 0.55 : 1,
                    child: Text(
                      '${c.d}',
                      style: TextStyle(
                        fontSize: PFontSize.bodyMd,
                        fontWeight: isSel ? PFontWeight.bold : PFontWeight.semi,
                        color: isSel ? t.fgOnBrand : numColor(c.ds, i % 7),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  height: 12,
                  child: Text(
                    amt,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSel ? PFontWeight.bold : PFontWeight.semi,
                      letterSpacing: -0.2,
                      // 지출 빨강·수입 파랑 — 아래 리스트와 동일(사용자 결정).
                      color: data == null
                          ? t.fgTertiary
                          : (data.out > 0 ? t.fgExpense : t.fgBrand),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final dows = weekdayLabels();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                    child: Text(
                      dows[i],
                      textAlign: TextAlign.center,
                      style: PTypo.caption.copyWith(
                        fontWeight: PFontWeight.semi,
                        color: i == 0
                            ? t.fgExpense
                            : i == 6
                                ? t.fgBrand
                                : t.fgTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final w in expanded ? weeks : [weeks[selWeek]])
            Row(children: [for (var i = 0; i < 7; i++) cell(w[i], i)]),
          InkWell(
            onTap: onToggleExpand,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 2, 0, 10),
              child: Center(
                child: Icon(
                  expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 20,
                  color: t.fgTertiary,
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
    final l = AppLocalizations.of(context);
    final ds = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final now = DateTime.now();
    final todayStr = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yest = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yest.year.toString().padLeft(4, '0')}-${yest.month.toString().padLeft(2, '0')}-${yest.day.toString().padLeft(2, '0')}';
    final rel = ds == todayStr ? l.txmToday : ds == yesterdayStr ? l.txmYesterday : null;
    final label = formatDay(date);
    final dayExpense = items
        .where((e) => e.expenseType == 'EXPENSE')
        .fold<int>(0, (s, e) => s + e.amount);
    final dayIncome = items
        .where((e) => e.expenseType == 'INCOME')
        .fold<int>(0, (s, e) => s + e.amount);
    final categories = ref.watch(categoriesProvider).value ?? const [];

    // 카드 다이어트 — design `.m-scroll .tx-list`: day-head(라벨, 아래 10) + 플랫 행.
    // 날짜 그룹 사이는 넓은 여백(24)으로 구분 (헤어라인·카드 없음).
    return Padding(
      padding: const EdgeInsets.only(top: PSpace.x24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // txm dayhead — "yy. m. d(요일) · 오늘/어제" + 일 합계 (design .txm-dayhead).
          Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${date.year % 100}. ${date.month}. ${date.day}(${label.dow})',
                  style: PTypo.bodySm.copyWith(
                    color: t.fgSecondary,
                    fontWeight: PFontWeight.semi,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (rel != null)
                  Text(
                    ' · $rel',
                    style: PTypo.bodySm.copyWith(color: t.fgTertiary),
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
          const SizedBox(height: 6),
          // 행 리스트 — 카드/구분선 없이 행 리듬만.
          Column(
            children: [
              for (int i = 0; i < items.length; i++)
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
            ],
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
    final l = AppLocalizations.of(context);
    // assetsProvider 캐시 우선, 없으면 단건 fetch.
    final all = ref.watch(assetsProvider).value;
    final cached = all?.byRowId(assetId);
    final asyncFallback = cached == null
        ? ref.watch(assetByIdProvider(assetId))
        : null;
    final name = cached?.assetName ?? asyncFallback?.value?.assetName;
    final label = name == null ? l.expFiltering : l.expFilteringBy(name);
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

/// txm 통합 뷰 skeleton — 월네비 + 총액/인사이트 + 캘린더 1주 + 리스트 (web 정합).
class _TxmSkeleton extends StatelessWidget {
  const _TxmSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: const [
              PSkeleton(width: 36, height: 36),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: PSkeleton.line(width: 40, height: 20),
              ),
              PSkeleton(width: 36, height: 36),
              Spacer(),
              PSkeleton(width: 36, height: 36),
              SizedBox(width: 4),
              PSkeleton(width: 36, height: 36),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(PSpace.x20, 8, PSpace.x20, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PSkeleton.line(width: 160, height: 32),
                    SizedBox(height: 8),
                    PSkeleton.line(width: 200, height: 16),
                  ],
                ),
              ),
              SizedBox(width: PSpace.x12),
              PSkeleton(width: 74, height: 36),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 6, 0, 8),
                        child: Center(child: PSkeleton.line(width: 16, height: 14)),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  for (var i = 0; i < 7; i++)
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 4, 0, 8),
                        child: Column(
                          children: [
                            PSkeleton(width: 33, height: 33, borderRadius: PRadius.brFull),
                            SizedBox(height: 3),
                            PSkeleton.line(width: 32, height: 10),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 2, 0, 10),
                child: Center(child: PSkeleton.line(width: 20, height: 16)),
              ),
            ],
          ),
        ),
        Container(height: 1, color: context.tokens.borderSubtle),
        Padding(
          padding: const EdgeInsets.fromLTRB(PSpace.x20, 24, PSpace.x20, 0),
          child: Column(
            children: const [
              _ExpenseDayGroupSkeleton(rows: 3),
              SizedBox(height: PSpace.x16),
              _ExpenseDayGroupSkeleton(rows: 2),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExpenseDayGroupSkeleton extends StatelessWidget {
  const _ExpenseDayGroupSkeleton({required this.rows});
  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 날짜 헤더 — 플랫 day-head (_DayGroup 정합: 위 2 / 아래 10).
        Padding(
          padding: EdgeInsets.zero, // 실제 날짜 헤더 padding 제거 정합
          child: Row(
            children: const [
              PSkeleton.line(width: 48, height: 13),
              SizedBox(width: PSpace.x8),
              PSkeleton.line(width: 24, height: 11),
              Spacer(),
              PSkeleton.line(width: 60, height: 11),
              SizedBox(width: PSpace.x8),
              PSkeleton.line(width: 60, height: 11),
            ],
          ),
        ),
        // 행 placeholder — 카드 다이어트: 카드/구분선 없이 행 리듬(12/10)만.
        Column(
            children: [
              for (int i = 0; i < rows; i++) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    2, PSpace.x12, 0, PSpace.x12, // 실제 ExpenseRow(좌2/우0) 정합
                  ),
                  child: Row(
                    children: [
                      // ExpenseRow icon tile 정합 — 40px → tile(40)=12=brLg.
                      PSkeleton(
                        width: 40,
                        height: 40,
                        borderRadius: PRadius.brLg,
                      ),
                      SizedBox(width: PSpace.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PSkeleton.line(width: 120, height: 14),
                            SizedBox(height: 2),
                            PSkeleton.line(width: 80, height: 11),
                          ],
                        ),
                      ),
                      SizedBox(width: PSpace.x8),
                      PSkeleton.line(width: 80, height: 14),
                    ],
                  ),
                ),
              ],
            ],
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
    final l = AppLocalizations.of(context);
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
            label: l.actionRetry,
            variant: PButtonVariant.outline,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

