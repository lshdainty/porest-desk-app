import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
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
import 'package:porest_desk_app/shared/widgets/p_chart_tooltip.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_aggregates.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/expense/presentation/filter_dialog.dart';
import 'package:porest_desk_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:porest_desk_app/features/expense/presentation/widgets/transfer_row.dart';
import 'package:porest_desk_app/features/expense/presentation/transfer_detail_sheet.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/shared/widgets/p_tab_bar.dart';



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
  bool _compact = false; // 스크롤 시 총액 영역 접힘 (design txm-pin--compact)
  String? _selected;
  final Map<String, GlobalKey> _dayKeys = {};
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _collapseKey = GlobalKey();
  final GlobalKey _listKey = GlobalKey();
  bool _lock = false; // 프로그램 스크롤 중 스파이 무시
  Timer? _lockTimer;

  @override
  void initState() {
    super.initState();
    _assetIdFilter = widget.initialAssetId;
    final today = DateTime.now();
    if (today.year == _month.year && today.month == _month.month) {
      _selected = _ymdOf(today);
    }
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _lockFor(int ms) {
    _lock = true;
    _lockTimer?.cancel();
    _lockTimer = Timer(Duration(milliseconds: ms), () => _lock = false);
  }

  /// 스크롤 스파이 — compact 토글(히스테리시스 72/24) + 맨 위 날짜 그룹을 선택일로 동기.
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final st = _scrollCtrl.offset;
    // 콘텐츠가 짧으면 접힘(−collapse 높이) 순간 offset이 maxScrollExtent에
    // clamp돼 해제 임계 아래로 떨어지며 접힘↔펼침 무한 플리커 — 접힌 뒤에도
    // 진입 임계(72) 위에 남을 스크롤 여유가 있을 때만 진입.
    final collapseH = _compact
        ? 0.0
        : (_collapseKey.currentContext?.size?.height ?? 0.0);
    final canStay =
        _scrollCtrl.position.maxScrollExtent - collapseH > 72;
    final next = _compact ? st > 24 : st > 72 && canStay;
    if (next != _compact) {
      setState(() {
        _compact = next;
        if (next) _expanded = false;
      });
    }
    if (_lock) return;
    final listBox = _listKey.currentContext?.findRenderObject() as RenderBox?;
    if (listBox == null) return;
    final listTop = listBox.localToGlobal(Offset.zero).dy;
    // 리스트 상단(+28) 을 지난 그룹 중 화면상 가장 아래 그룹 = 현재 보는 날짜.
    double best = double.negativeInfinity;
    String? cur;
    for (final e in _dayKeys.entries) {
      final box = e.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final top = box.localToGlobal(Offset.zero).dy - listTop;
      if (top <= 28 && top > best) {
        best = top;
        cur = e.key;
      }
    }
    if (cur != null && cur != _selected) {
      setState(() => _selected = cur);
    }
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
    _lockFor(800);
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _scrollToDay(String ds) {
    _lockFor(800);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _dayKeys[ds]?.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 300), alignment: 0.02);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final expensesAsync = ref.watch(monthExpensesProvider(_key));
    // 이체는 asset_transfer 별도 테이블이라 거래 목록에 섞여 오지 않는다.
    // 같은 달 범위로 따로 받아 화면 단에서만 합친다(통계·예산 같은 지출 전용 경로 보호).
    final transfersAsync = ref.watch(assetTransfersProvider((
      startDate: _ymdOf(DateTime(_month.year, _month.month, 1)),
      endDate: _ymdOf(DateTime(_month.year, _month.month + 1, 0)),
    )));
    // 인사이트(지난달 대비) — 지난달 거래도 함께 구독(family 캐시).
    final prevAsync = ref.watch(monthExpensesProvider(_prevKey));

    // txm 통합 뷰(design tx-mobile.jsx) — pin(월네비+총액+캘린더) 고정, 리스트만 스크롤.
    return expensesAsync.when(
      loading: () => _TxmSkeleton(monthLabel: _monthLabel(_month)),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(PSpace.x24),
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

              // 환불은 지출 상계, 아직 안 온 건 제외 — 서버 월 요약과 같은 규칙.
              final monthIncome = incomeSum(raw);
              final monthExpense = expenseSum(raw);

              // 일별 합계 — 캘린더 셀 밑 금액 (필터 적용분 기준).
              final byDay = <String, ({int out, int inn})>{};
              for (final e in countableTx(filtered)) {
                final d = e.expenseDateOnly ?? '';
                final cur = byDay[d] ?? (out: 0, inn: 0);
                // 환불은 그날 지출에서 빠진다 — 파랑 '+' 로 그리면 월 헤더와 어긋난다.
                byDay[d] = isRefundTx(e)
                    ? (out: cur.out - e.amount.abs(), inn: cur.inn)
                    : e.expenseType == 'EXPENSE'
                        ? (out: cur.out + e.amount.abs(), inn: cur.inn)
                        : (out: cur.out, inn: cur.inn + e.amount.abs());
              }

              final groups = <String, List<Expense>>{};
              for (final e in filtered) {
                final d = e.expenseDateOnly ?? '';
                groups.putIfAbsent(d, () => []).add(e);
              }

              // 이체 필터 — 이체에 개념이 없는 필터(카테고리·유형)가 걸리면 대상에서 뺀다.
              // 자산 필터는 보내는 쪽·받는 쪽 둘 다 매칭(한 건이 자산 두 개에 걸침).
              final transferGroups = <String, List<AssetTransfer>>{};
              final typeFiltered = _advFilter.types.length == 1;
              if (!typeFiltered && _advFilter.categoryIds.isEmpty) {
                for (final tr in (transfersAsync.value ?? const <AssetTransfer>[])) {
                  if (_advFilter.assetIds.isNotEmpty &&
                      !_advFilter.assetIds.contains(tr.fromAssetRowId) &&
                      !_advFilter.assetIds.contains(tr.toAssetRowId)) {
                    continue;
                  }
                  if (_advFilter.min != null && tr.amount < _advFilter.min!) continue;
                  if (_advFilter.max != null && tr.amount > _advFilter.max!) continue;
                  // transferDate 가 DATETIME 이라 그룹 키는 날짜 부분만 쓴다.
                  final raw = tr.transferDate ?? '';
                  if (raw.length < 10) continue;
                  final d = raw.substring(0, 10);
                  transferGroups.putIfAbsent(d, () => []).add(tr);
                }
              }

              // 이체만 있는 날도 그룹이 나와야 한다.
              final groupKeys = <String>{...groups.keys, ...transferGroups.keys}.toList()
                ..sort((a, b) => b.compareTo(a));
              _dayKeys.removeWhere(
                  (k, _) => !groups.containsKey(k) && !transferGroups.containsKey(k));
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

              // 필터 활성 시 — 월선택/총액/캘린더/divider 숨기고 온전히 리스트만(사용자 결정).
              final filterActive = advCount > 0 || _assetIdFilter != null;

              final pin = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _TxmMonthNav(
                    label: _monthLabel(_month),
                    showMonth: !filterActive,
                    onPrev: () => _goMonth(-1),
                    onNext: () => _goMonth(1),
                    filterActive: advCount > 0,
                    filterCount: advCount,
                    onOpenFilter: _openFilter,
                    onAddTx: () => showAddTxSheet(context),
                    tokens: t,
                  ),
                  if (filterActive)
                    _FilterChipsRow(
                      filter: _advFilter,
                      assetId: _assetIdFilter,
                      onClearAsset: _clearAssetFilter,
                      onChange: (f) => setState(() => _advFilter = f),
                      categories: categoriesAsync.value ?? const [],
                      tokens: t,
                    ),
                  // 총액 + 인사이트 + [소비 요약] — 스크롤 시 접힘. 필터 활성 시 숨김.
                  if (!filterActive)
                  ClipRect(
                    key: _collapseKey,
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      alignment: Alignment.topCenter,
                      child: _compact
                          ? const SizedBox(width: double.infinity)
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(PSpace.x24, 8, PSpace.x24, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                krwSigned(monthExpense, ref.watch(hideCardProvider('ledger.monthSummary')), unit: true),
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
                          // 월 전체 캘린더와 동시 열면 고정 pin이 화면을
                          // 초과(overflow) — 상호 배타로 접는다.
                          onTap: () => setState(() {
                            _sumOpen = !_sumOpen;
                            if (_sumOpen) _expanded = false;
                          }),
                          tokens: t,
                        ),
                      ],
                    ),
                  ),
                  if (_sumOpen)
                    Padding(
                      // 하단 28 은 그림자 자리다 — 이 Padding 은 위쪽 ClipRect 안이라
                      // 0 이면 raised 의 shadow-lg 가 카드 바닥선에서 칼같이 잘린다.
                      // 28 = dy 8 + blur 24 + spread −4 (그림자가 아래로 퍼지는 거리).
                      padding: const EdgeInsets.fromLTRB(
                          PSpace.x24, 14, PSpace.x24, PSpace.x28),
                      child: PCard(
                        variant: PCardVariant.raised,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            _TxmSummaryRow(
                              label: l.expSummaryIncome,
                              value: krwSigned(monthIncome, ref.watch(hideCardProvider('ledger.monthSummary')), sign: '+', unit: true),
                              valueColor: t.fgBrand,
                              tokens: t,
                            ),
                            Divider(height: 1, thickness: 1, color: t.borderSubtle),
                            _TxmSummaryRow(
                              label: l.expSummaryExpense,
                              value: krwSigned(monthExpense, ref.watch(hideCardProvider('ledger.monthSummary')), sign: '−', unit: true),
                              valueColor: t.fgExpense,
                              tokens: t,
                            ),
                            Divider(height: 1, thickness: 1, color: t.borderSubtle),
                            _TxmSummaryRow(
                              label: l.expTotal,
                              value: krwSigned(
                                (monthIncome - monthExpense).abs(),
                                ref.watch(hideCardProvider('ledger.monthSummary')),
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
                              ],
                            ),
                    ),
                  ),
                  // 캘린더 — 필터 적용 시 숨김(리스트만, 사용자 결정·web 정합).
                  if (!filterActive) ...[
                  _TxmCalendar(
                    month: _month,
                    selected: _selected,
                    expanded: _expanded,
                    byDay: byDay,
                    masked: ref.watch(hideCardProvider('ledger.calendar')),
                    onSelect: (ds) {
                      setState(() => _selected = ds);
                      if (byDay.containsKey(ds)) _scrollToDay(ds);
                    },
                    onToggleExpand: () => setState(() {
                      _expanded = !_expanded;
                      if (_expanded) _sumOpen = false;
                    }),
                    tokens: t,
                  ),
                  ],
                  if (!filterActive)
                    Container(height: 1, color: t.borderDefault),
                ],
              );

              final listChildren = <Widget>[
                        if (groupKeys.isEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(PSpace.x24, 56, PSpace.x24, 20),
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
                                items: groups[key] ?? const [],
                                transfers: transferGroups[key] ?? const [],
                                categoriesAsync: categoriesAsync,
                                masked: ref.watch(hideCardProvider('ledger.txList')),
                                rowKeys: _rowKeys,
                                focusTxId: widget.focusTxId,
                              ),
                            ),
                  // 이전 달 이용 내역 보기 — 필터 활성 시 숨김(사용자 결정).
                  if (!filterActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: Material(
                      // design .txm-prevbtn bg-sunken 다크(#2D3346)=web 정합 — 앱 bgMuted 사용
                      // (앱 bgSunken 은 다크에서 페이지색이라 버튼이 사라짐).
                      color: t.bgMuted,
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
              ];

              final content = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  pin,
                  Expanded(
                    child: RefreshIndicator(
                      color: t.bgBrand,
                      onRefresh: () async {
                        ref.invalidate(monthExpensesProvider(_key));
                        await ref.read(monthExpensesProvider(_key).future);
                      },
                      child: ListView(
                        key: _listKey,
                        controller: _scrollCtrl,
                        // 하단 — 플로팅 탭바 보상.
                        padding: EdgeInsets.fromLTRB(PSpace.x24, 0,
                            PSpace.x24, pTabBarBottomInset(context)),
                        children: listChildren,
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
    // 이번 달 지출(monthExpense)과 비교하므로 같은 규칙으로 세야 한다.
    final prevOut = expenseSum(prevRaw ?? const <Expense>[]);
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
    // 환불은 그 카테고리 지출을 깎는다 — 안 그러면 전액 환불한 카테고리가 1위가 된다.
    for (final e in countableTx(raw)) {
      if (isRefundTx(e)) {
        byCat[e.categoryRowId] = (byCat[e.categoryRowId] ?? 0) - e.amount.abs();
      } else if (e.expenseType == 'EXPENSE') {
        byCat[e.categoryRowId] = (byCat[e.categoryRowId] ?? 0) + e.amount.abs();
      }
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
    this.showMonth = true,
  });
  final String label;
  final bool showMonth;
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
      padding: const EdgeInsets.symmetric(horizontal: PSpace.x24),
      child: Row(
        children: [
          if (showMonth) ...[
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
          ],
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
      // 일요일 — 캘린더 화면 정합(fgExpense, 사용자 결정)
      if (dow == 0) return t.fgExpense;
      if (dow == 6) return t.fgBrand;
      return t.fgPrimary;
    }

    Widget cell(({int d, String ds})? c, int i) {
      if (c == null) return const Expanded(child: SizedBox(height: 56));
      final isSel = c.ds == selected;
      final data = byDay[c.ds];
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
                // 지출·수입 병기(각 줄) — 말줄임 + 차트형 툴팁(지출·수입 모두, 사용자 결정).
                if (data != null)
                  Tooltip(
                    richMessage: WidgetSpan(
                      child: PChartTooltipBox(
                        title: '${int.parse(c.ds.substring(5, 7))}. ${c.d}',
                        rows: [
                          PChartTooltipRowData(
                            color: t.fgExpense,
                            label: AppLocalizations.of(context).expSummaryExpense,
                            amount: krwSigned(data.out, masked, sign: '−', unit: true),
                            amountColor: t.fgExpense,
                          ),
                          PChartTooltipRowData(
                            color: t.fgBrand,
                            label: AppLocalizations.of(context).expSummaryIncome,
                            amount: krwSigned(data.inn, masked, sign: '+', unit: true),
                            amountColor: t.fgBrand,
                          ),
                        ],
                      ),
                    ),
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data.out > 0)
                          Text(
                            '-${masked ? '••••' : krw(data.out)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSel ? PFontWeight.bold : PFontWeight.semi,
                              letterSpacing: -0.2,
                              color: t.fgExpense,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        if (data.inn > 0)
                          Text(
                            '+${masked ? '••••' : krw(data.inn)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSel ? PFontWeight.bold : PFontWeight.semi,
                              letterSpacing: -0.2,
                              color: t.fgBrand,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                      ],
                    ),
                  ),
                if (data == null) const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }

    final dows = weekdayLabels();
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.x16, 12, PSpace.x16, 0),
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
                      // 일=날짜와 동일(fgExpense)·토=fgBrand·평일=일반 텍스트색(사용자 결정)
                      style: PTypo.caption.copyWith(
                        fontWeight: PFontWeight.semi,
                        color: i == 0
                            ? t.fgExpense
                            : i == 6
                                ? t.fgBrand
                                : t.fgPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final w in expanded ? weeks : [weeks[selWeek]])
            Row(
                // 금액 줄 수가 달라도 날짜 숫자 y 고정 — Row 기본 center 가
                // 낮은 셀을 세로 중앙으로 밀던 문제(토스 정렬 정합).
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (var i = 0; i < 7; i++) cell(w[i], i)]),
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
    this.transfers = const [],
    this.rowKeys,
    this.focusTxId,
  });
  final DateTime date;
  final List<Expense> items;
  /// 그날의 이체. 지출/수입 합계에는 넣지 않고 행만 뒤에 붙인다
  /// (이체는 자산 간 이동이라 순자산 증감이 0 — 합계에 넣으면 월 통계가 부풀어 오른다).
  final List<AssetTransfer> transfers;
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
    // 월 헤더와 같은 규칙 — 환불 상계 + 예정 제외.
    final dayExpense = expenseSum(items);
    final dayIncome = incomeSum(items);
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
              // 이체는 시각이 없어(LocalDate) 그날의 맨 뒤 — web 정렬(내림차순)과 동일한 자리.
              for (final tr in transfers)
                TransferRow(
                  key: ValueKey('t${tr.rowId}'),
                  transfer: tr,
                  masked: masked,
                  onTap: () => showTransferDetailSheet(context, tr),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 필터 활성 시 — 적용 항목별 칩 가로 스크롤(스크롤바 없음), 개별 ✕ 제거 (사용자 결정, web 정합).
class _FilterChipsRow extends ConsumerWidget {
  const _FilterChipsRow({
    required this.filter,
    required this.assetId,
    required this.onClearAsset,
    required this.onChange,
    required this.categories,
    required this.tokens,
  });
  final ExpenseFilter filter;
  final int? assetId;
  final VoidCallback onClearAsset;
  final ValueChanged<ExpenseFilter> onChange;
  final List<ExpenseCategory> categories;
  final PorestTokens tokens;

  /// copyWith 는 null 대입이 불가(`?? this`) — 제거 칩용 직접 재구성.
  static ExpenseFilter _rebuild(
    ExpenseFilter f, {
    FilterPeriod? period,
    bool clearDates = false,
    Set<String>? types,
    Set<int>? categoryIds,
    Set<int>? assetIds,
    bool clearMin = false,
    bool clearMax = false,
  }) =>
      ExpenseFilter(
        period: period ?? f.period,
        startDate: clearDates ? null : f.startDate,
        endDate: clearDates ? null : f.endDate,
        types: types ?? f.types,
        categoryIds: categoryIds ?? f.categoryIds,
        assetIds: assetIds ?? f.assetIds,
        min: clearMin ? null : f.min,
        max: clearMax ? null : f.max,
      );

  Widget _chip(PorestTokens t, String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
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
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            borderRadius: PRadius.brFull,
            child: Icon(LucideIcons.x, size: 14, color: t.fgBrand),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final f = filter;
    final chips = <Widget>[];

    if (assetId != null) {
      final all = ref.watch(assetsProvider).value;
      final name = all?.byRowId(assetId!)?.assetName;
      chips.add(_chip(
        t,
        name == null ? l.expFiltering : l.expFilteringBy(name),
        onClearAsset,
      ));
    }
    if (f.period != FilterPeriod.custom) {
      final label = switch (f.period) {
        FilterPeriod.week => l.expPeriodWeek,
        FilterPeriod.month => l.expThisMonth,
        _ => l.expPeriod3Month,
      };
      chips.add(_chip(t, label,
          () => onChange(_rebuild(f, period: FilterPeriod.custom, clearDates: true))));
    } else if ((f.startDate ?? '').isNotEmpty && (f.endDate ?? '').isNotEmpty) {
      String md(String d) => '${int.parse(d.substring(5, 7))}.${int.parse(d.substring(8, 10))}';
      chips.add(_chip(t, '${md(f.startDate!)}~${md(f.endDate!)}',
          () => onChange(_rebuild(f, clearDates: true))));
    }
    if (f.types.length < 2) {
      chips.add(_chip(
        t,
        f.types.contains('EXPENSE') ? l.expFilterExpense : l.expFilterIncome,
        () => onChange(_rebuild(f, types: const {'EXPENSE', 'INCOME'})),
      ));
    }
    for (final id in f.categoryIds) {
      final name = categories.byRowId(id)?.categoryName ?? '$id';
      chips.add(_chip(t, name, () {
        final next = Set<int>.from(f.categoryIds)..remove(id);
        onChange(_rebuild(f, categoryIds: next));
      }));
    }
    if (f.assetIds.isNotEmpty) {
      final all = ref.watch(assetsProvider).value;
      for (final id in f.assetIds) {
        final name = all?.byRowId(id)?.assetName ?? '$id';
        chips.add(_chip(t, name, () {
          final next = Set<int>.from(f.assetIds)..remove(id);
          onChange(_rebuild(f, assetIds: next));
        }));
      }
    }
    if (f.min != null) {
      chips.add(_chip(t, l.expChipMin(krwSigned(f.min!, false, unit: true)),
          () => onChange(_rebuild(f, clearMin: true))));
    }
    if (f.max != null) {
      chips.add(_chip(t, l.expChipMax(krwSigned(f.max!, false, unit: true)),
          () => onChange(_rebuild(f, clearMax: true))));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(PSpace.x24, 8, PSpace.x24, 0),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }
}

/// txm 통합 뷰 skeleton — 정적 틀(월네비/소비요약 버튼/요일/expand)은 실제 렌더,
/// 서버 데이터(총액·인사이트·셀 금액·리스트)만 스켈레톤. feedback_skeleton_server_data_only.
class _TxmSkeleton extends StatelessWidget {
  const _TxmSkeleton({required this.monthLabel});
  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final now = DateTime.now();
    final weekDays = List.generate(
      7,
      (i) => now.subtract(Duration(days: (now.weekday % 7) - i)),
    );
    final dows = weekdayLabels();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // 월 네비 — 실제 틀 (탭은 로딩 중 no-op).
        _TxmMonthNav(
          label: monthLabel,
          onPrev: () {},
          onNext: () {},
          filterActive: false,
          filterCount: 0,
          onOpenFilter: () {},
          onAddTx: () {},
          tokens: t,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(PSpace.x24, 8, PSpace.x24, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PSkeleton.line(width: 160, height: 32),
                    SizedBox(height: 8),
                    PSkeleton.line(width: 200, height: 16),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x12),
              _TxmSumBtn(
                on: false,
                label: l.txmSpendSummary,
                onTap: () {},
                tokens: t,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(PSpace.x16, 12, PSpace.x16, 0),
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
                                ? chartRedOf(context)
                                : i == 6
                                    ? t.fgBrand
                                    : t.fgTertiary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Row(
                children: [
                  for (final d in weekDays)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 33,
                              height: 33,
                              child: Center(
                                child: Text(
                                  '${d.day}',
                                  style: TextStyle(
                                    fontSize: PFontSize.bodyMd,
                                    fontWeight: PFontWeight.semi,
                                    color: t.fgPrimary,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            const PSkeleton.line(width: 32, height: 10),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 2, 0, 10),
                child: Center(
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 20,
                    color: t.fgTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: t.borderDefault),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(PSpace.x24, 24, PSpace.x24, 28),
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

