import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/shared/scroll/scroll_to_keyed.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/format/format_locale.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/mask_flags.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_chart_tooltip.dart';
import 'package:porest_desk_app/shared/widgets/p_day_group.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_filter.dart';
import 'package:porest_desk_app/features/expense/domain/expense_aggregates.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense/presentation/add_tx_sheet.dart';
import 'package:porest_desk_app/features/expense/presentation/filter_dialog.dart';
import 'package:porest_desk_app/features/expense/presentation/expense_actions.dart';
import 'package:porest_desk_app/features/expense/presentation/widgets/expense_row.dart';
import 'package:porest_desk_app/shared/widgets/p_swipe_actions.dart';
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
    final canStay = _scrollCtrl.position.maxScrollExtent - collapseH > 72;
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

  static String _ymdOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 월 라벨 — ko "7월" / en "Jul" (monthnav·prevbtn·empty 공용, web txmMonthLabel 정합).
  static String _monthLabel(DateTime m) => localeIsEn()
      ? const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ][m.month - 1]
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
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// [order] 는 리스트에 **그려진 순서 그대로**의 날짜 그룹 목록이다. 필드로 들고
  /// 있지 않고 받는 이유 — 그리는 쪽과 어긋날 여지를 아예 없앤다. 필드로 두면 누가
  /// 대입 한 줄을 지우는 순간 순번이 -1 이 되어 **아무 일도 안 하는 상태로 조용히**
  /// 돌아간다(이 버그가 정확히 그렇게 조용했다).
  void _scrollToDay(String ds, List<String> order) {
    // 먼 날짜는 아직 안 만들어져 있어 `ensureVisible` 만으로는 못 간다 —
    // 그래서 순번을 함께 넘긴다(`scroll_to_keyed.dart` 설명 참고).
    // 여러 프레임에 걸쳐 뛰므로 스크롤 스파이를 그동안 재운다.
    _lockFor(1200);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      scrollToKeyedItem(
        controller: _scrollCtrl,
        key: _dayKeys[ds],
        index: order.indexOf(ds),
        count: order.length,
      );
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
    final transfersAsync = ref.watch(
      assetTransfersProvider((
        startDate: _ymdOf(DateTime(_month.year, _month.month, 1)),
        endDate: _ymdOf(DateTime(_month.year, _month.month + 1, 0)),
      )),
    );
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
        final cats = categoriesAsync.value;
        // 부모 카테고리를 고르면 자식 rowId 까지 함께 본다 — **빼고(exclude)에도 같이**
        // 건다. 한쪽만 펼치면 "식비 빼고" 가 하위 '카페' 를 못 걸러 낸다.
        Set<int> expand(Set<int> ids) => ids.isEmpty
            ? ids
            : {
                ...ids,
                if (cats != null)
                  for (final c in cats)
                    if (c.parentRowId != null && ids.contains(c.parentRowId))
                      c.rowId,
              };
        final effective = _advFilter.copyWith(
          categories: IncludeExclude(
            include: expand(_advFilter.categories.include),
            exclude: expand(_advFilter.categories.exclude),
          ),
        );

        final filtered =
            raw
                .where(
                  (e) => matchesFilter(
                    FilterRow(
                      date: e.expenseDateOnly ?? '',
                      amount: e.amount,
                      type: e.expenseType,
                      // 분할 항목 카테고리까지 넣는다 — 포함은 "하나라도",
                      // 제외는 "하나라도 걸리면".
                      categoryIds: [
                        if (e.categoryRowId != null) e.categoryRowId!,
                        ...e.splitCategoryRowIds,
                      ],
                      assetIds: [if (e.assetRowId != null) e.assetRowId!],
                    ),
                    effective,
                  ),
                )
                .toList()
              ..sort(
                (a, b) => (b.expenseDate ?? '').compareTo(a.expenseDate ?? ''),
              );

        // 환불은 지출 상계, 아직 안 온 건 제외 — 서버 월 요약과 같은 규칙.
        // 필터가 걸려 있으면 **걸러진 목록으로** 다시 센다(조합 15, 사용자 결정).
        final filterOn = !_advFilter.isEmpty;
        final monthIncome = incomeSum(filterOn ? filtered : raw);
        final monthExpense = expenseSum(filterOn ? filtered : raw);

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

        // 이체도 **같은 술어**로 본다. v1 은 카테고리가 걸리면 통째로 뺐는데,
        // v2 는 이체를 type=null·categoryIds=[] 로 눕혀 규칙이 알아서 판정한다 —
        // '모두 일치' 면 카테고리 조건에서 빠지고, '하나라도' 면 계좌·금액으로 남는다.
        final transferGroups = <String, List<AssetTransfer>>{};
        for (final tr in (transfersAsync.value ?? const <AssetTransfer>[])) {
          final rawDate = tr.transferDate ?? '';
          if (rawDate.length < 10) continue;
          final d = rawDate.substring(0, 10);
          final ok = matchesFilter(
            FilterRow(
              date: d,
              amount: tr.amount,
              type: null,
              assetIds: [tr.fromAssetRowId, tr.toAssetRowId],
            ),
            effective,
          );
          if (!ok) continue;
          transferGroups.putIfAbsent(d, () => []).add(tr);
        }

        // 이체만 있는 날도 그룹이 나와야 한다.
        final groupKeys = <String>{
          ...groups.keys,
          ...transferGroups.keys,
        }.toList()..sort((a, b) => b.compareTo(a));
        _dayKeys.removeWhere(
          (k, _) => !groups.containsKey(k) && !transferGroups.containsKey(k),
        );
        for (final k in groupKeys) {
          _dayKeys.putIfAbsent(k, () => GlobalKey());
        }

        // 배지 — 켜진 **포함 조건 수**(웹 filterActiveCount 정합).
        // 기간은 항상 걸려 있고 '빼고' 는 포함 조건이 아니라 세지 않지만, 사람 눈에는
        // 그 둘도 "필터가 걸린 상태" 라 조건이 0 이어도 1 로 쳐서 배지를 띄운다.
        final baseCount = activeConditionCount(_advFilter);
        final hasExclude =
            _advFilter.categories.exclude.isNotEmpty ||
            _advFilter.assets.exclude.isNotEmpty;
        final advCount = baseCount > 0
            ? baseCount
            : (_advFilter.periods.length > 1 || hasExclude ? 1 : 0);

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
                              padding: const EdgeInsets.fromLTRB(
                                PSpace.x24,
                                8,
                                PSpace.x24,
                                0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          krwSigned(
                                            monthExpense,
                                            ref
                                                .watch(
                                                  maskFlagsProvider(
                                                    'ledger.monthSummary',
                                                  ),
                                                )
                                                .of(MaskKind.expense),
                                            unit: true,
                                          ),
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.56,
                                            height: 1.15,
                                            color: t.fgPrimary,
                                            fontFeatures: const [
                                              FontFeature.tabularFigures(),
                                            ],
                                          ),
                                        ),
                                        Builder(
                                          builder: (_) {
                                            final ins = _insight(
                                              l,
                                              t,
                                              raw,
                                              monthExpense,
                                              prevAsync.value,
                                              categoriesAsync.value,
                                            );
                                            if (ins == null) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 7,
                                              ),
                                              child: ins,
                                            );
                                          },
                                        ),
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
                                  PSpace.x24,
                                  14,
                                  PSpace.x24,
                                  PSpace.x28,
                                ),
                                child: PCard(
                                  variant: PCardVariant.raised,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  child: Column(
                                    children: [
                                      _TxmSummaryRow(
                                        label: l.expSummaryIncome,
                                        value: krwSigned(
                                          monthIncome,
                                          ref
                                              .watch(
                                                maskFlagsProvider(
                                                  'ledger.monthSummary',
                                                ),
                                              )
                                              .of(MaskKind.income),
                                          sign: '+',
                                          unit: true,
                                        ),
                                        valueColor: t.fgBrand,
                                        tokens: t,
                                      ),
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: t.borderSubtle,
                                      ),
                                      _TxmSummaryRow(
                                        label: l.expSummaryExpense,
                                        value: krwSigned(
                                          monthExpense,
                                          ref
                                              .watch(
                                                maskFlagsProvider(
                                                  'ledger.monthSummary',
                                                ),
                                              )
                                              .of(MaskKind.expense),
                                          sign: '−',
                                          unit: true,
                                        ),
                                        valueColor: t.fgExpense,
                                        tokens: t,
                                      ),
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: t.borderSubtle,
                                      ),
                                      _TxmSummaryRow(
                                        label: l.expTotal,
                                        value: krwSigned(
                                          (monthIncome - monthExpense).abs(),
                                          ref
                                              .watch(
                                                maskFlagsProvider(
                                                  'ledger.monthSummary',
                                                ),
                                              )
                                              .of(MaskKind.net),
                                          sign: monthIncome - monthExpense >= 0
                                              ? '+'
                                              : '−',
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
                flags: ref.watch(maskFlagsProvider('ledger.calendar')),
                onSelect: (ds) {
                  setState(() => _selected = ds);
                  if (byDay.containsKey(ds)) _scrollToDay(ds, groupKeys);
                },
                onToggleExpand: () => setState(() {
                  _expanded = !_expanded;
                  if (_expanded) _sumOpen = false;
                }),
                tokens: t,
              ),
            ],
            if (!filterActive) Container(height: 1, color: t.borderDefault),
          ],
        );

        final listChildren = <Widget>[
          if (groupKeys.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PSpace.x24,
                56,
                PSpace.x24,
                20,
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.receiptText,
                      size: 36,
                      color: t.fgTertiary,
                    ),
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
                  flags: ref.watch(maskFlagsProvider('ledger.txList')),
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
                        l.txmPrevMonthBtn(
                          _monthLabel(
                            DateTime(_month.year, _month.month - 1, 1),
                          ),
                        ),
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
                  padding: EdgeInsets.fromLTRB(
                    PSpace.x24,
                    0,
                    PSpace.x24,
                    pTabBarBottomInset(context),
                  ),
                  children: listChildren,
                ),
              ),
            ),
          ],
        );
        if (widget.focusTxId != null && !_scrolledToFocus) {
          // 알림·검색에서 들어온 거래는 목록 한참 아래일 수 있다 — 그 행은 아직
          // 안 만들어져 있어 바로 `ensureVisible` 하면 조용히 아무 일도 안 했다.
          // 먼저 **그 거래가 속한 날짜 그룹**으로 간 다음(그러면 행이 만들어진다)
          // 행이 만들어지는 것을 기다려 정확히 맞춘다.
          String? focusDay;
          for (final e in filtered) {
            if (e.rowId == widget.focusTxId) {
              focusDay = e.expenseDateOnly;
              break;
            }
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrolledToFocus = true;
            if (focusDay != null && focusDay.isNotEmpty) {
              _lockFor(1200);
              scrollToKeyedItem(
                controller: _scrollCtrl,
                key: _dayKeys[focusDay],
                index: groupKeys.indexOf(focusDay),
                count: groupKeys.length,
                alignment: 0.02,
              );
            }
            // 그룹 이동은 여러 프레임에 걸쳐 끝난다 — 한 프레임 뒤에 한 번만 보면
            // 두 홉 이상 걸린 경우 행이 아직 없어 조용히 건너뛴다(QA 22차 추정).
            ensureVisibleWhenReady(key: _rowKeys[widget.focusTxId!]);
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
      // 5,000원 미만이면 "비슷해요" — 표기와 무관한 제품 문턱이라 그대로 둔다
      // (예전엔 만원 반올림 결과가 0 이냐로 갈랐다. 경계가 같은 5,000 이다).
      if (diff.abs() < 5000) return Text(l.txmInsightSame, style: subStyle);
      // 축약은 차트 축·도넛 중앙과 같은 함수 하나를 쓴다. 예전엔 여기서 만원으로
      // 반올림해 11,881 을 `1만원` 이라고 했다 — 문장이 실제보다 16% 적게 말했다
      // (QA #38). 이제 `1.2만원` 이다.
      final amount = localeIsEn()
          ? '₩${krw(diff.abs())}'
          : '${formatChartAxis(diff.abs().toDouble())}원';
      final less = diff > 0;
      return Text.rich(
        TextSpan(
          style: subStyle,
          children: [
            TextSpan(text: less ? l.txmInsightLessPre : l.txmInsightMorePre),
            TextSpan(
              text: less
                  ? l.txmInsightLessHl(amount)
                  : l.txmInsightMoreHl(amount),
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
    final topId =
        (byCat.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;
    final topName = topId == null
        ? null
        : categories?.byRowId(topId)?.categoryName;
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

  Widget _btn(
    IconData icon,
    VoidCallback onTap, {
    Color? bg,
    Color? fg,
    Widget? badge,
  }) {
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
    required this.flags,
    required this.onSelect,
    required this.onToggleExpand,
    required this.tokens,
  });
  final DateTime month;
  final String? selected;
  final bool expanded;
  final Map<String, ({int out, int inn})> byDay;

  /// 화면 카드 + 종류 카드 — 금액마다 자기 종류로 판정한다.
  final MaskFlags flags;
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
    var selWeek = weeks.indexWhere(
      (w) => w.any((c) => c != null && c.ds == selected),
    );
    if (selWeek < 0) {
      selWeek = weeks.indexWhere(
        (w) => w.any((c) => c != null && c.ds == todayStr),
      );
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
                      ? BoxDecoration(
                          color: t.bgBrandSolid,
                          shape: BoxShape.circle,
                        )
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
                            label: AppLocalizations.of(
                              context,
                            ).expSummaryExpense,
                            amount: krwSigned(
                              data.out,
                              flags.of(MaskKind.expense),
                              sign: '−',
                              unit: true,
                            ),
                            amountColor: t.fgExpense,
                          ),
                          PChartTooltipRowData(
                            color: t.fgBrand,
                            label: AppLocalizations.of(
                              context,
                            ).expSummaryIncome,
                            amount: krwSigned(
                              data.inn,
                              flags.of(MaskKind.income),
                              sign: '+',
                              unit: true,
                            ),
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
                            '-${flags.of(MaskKind.expense) ? '••••' : krw(data.out)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSel
                                  ? PFontWeight.bold
                                  : PFontWeight.semi,
                              letterSpacing: -0.2,
                              color: t.fgExpense,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        if (data.inn > 0)
                          Text(
                            '+${flags.of(MaskKind.income) ? '••••' : krw(data.inn)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSel
                                  ? PFontWeight.bold
                                  : PFontWeight.semi,
                              letterSpacing: -0.2,
                              color: t.fgBrand,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
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
              children: [for (var i = 0; i < 7; i++) cell(w[i], i)],
            ),
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
    required this.flags,
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

  /// 화면 카드 + 종류 카드 — 금액마다 자기 종류로 판정한다.
  final MaskFlags flags;
  final Map<int, GlobalKey>? rowKeys;
  final int? focusTxId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 날짜 라벨·오늘/어제·일 합계는 PDayHeader 가 들고 있다.
    final categories = ref.watch(categoriesProvider).value ?? const [];

    // 카드 다이어트 — design `.m-scroll .tx-list`: day-head(라벨, 아래 10) + 플랫 행.
    // 날짜 그룹 사이는 넓은 여백(24)으로 구분 (헤어라인·카드 없음).
    return Padding(
      padding: const EdgeInsets.only(top: PSpace.x24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PDayHeader(date: date, items: items, flags: flags),
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
                    final e = items[i];
                    return Container(
                      key: k,
                      decoration: isFocus
                          ? BoxDecoration(
                              color: t.bgBrandSubtle,
                              borderRadius: PRadius.brSm,
                            )
                          : null,
                      // 밀면 편집·삭제가 바로 나온다. 탭은 그대로 상세로 —
                      // 스와이프는 지름길이지 유일한 경로가 아니다.
                      // 삭제는 expenseActions 가 한다(상세 시트와 같은 것).
                      child: PSwipeActions(
                        groupTag: 'expense-list',
                        actions: [
                          if (expenseActions.canEdit(e))
                            PSwipeAction(
                              label: l.actionEdit,
                              icon: LucideIcons.pencil,
                              kind: PSwipeKind.primary,
                              onSelect: () =>
                                  expenseActions.edit(context, ref, e),
                            ),
                          if (expenseActions.canDelete(e))
                            PSwipeAction(
                              label: l.actionDelete,
                              icon: LucideIcons.trash2,
                              kind: PSwipeKind.destructive,
                              confirmTitle: expenseActions.deleteConfirmTitle(
                                context,
                                e,
                              ),
                              confirmMessage: expenseActions
                                  .deleteConfirmMessage(context, e),
                              onSelect: () =>
                                  expenseActions.delete(context, ref, e),
                            ),
                        ],
                        child: ExpenseRow(
                          expense: e,
                          category: e.categoryRowId == null
                              ? null
                              : categories.byRowId(e.categoryRowId!),
                          flags: flags,
                        ),
                      ),
                    );
                  },
                ),
              // 이체는 시각이 없어(LocalDate) 그날의 맨 뒤 — web 정렬(내림차순)과 동일한 자리.
              for (final tr in transfers)
                TransferRow(
                  key: ValueKey('t${tr.rowId}'),
                  transfer: tr,
                  flags: flags,
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
      chips.add(
        _chip(
          t,
          name == null ? l.expFiltering : l.expFilteringBy(name),
          onClearAsset,
        ),
      );
    }
    // v2 는 조건이 여러 칸이라 항목마다 칩을 세우면 줄이 넘친다.
    // **칸 단위 요약 칩**으로 줄이고, × 는 그 칸을 통째로 비운다(웹 정합).
    if (activeConditionCount(f) > 1 && f.match == MatchMode.any) {
      chips.add(
        _chip(
          t,
          l.expFilterMatchAny,
          () => onChange(f.copyWith(match: MatchMode.all)),
        ),
      );
    }
    if (f.periods.length > 1) {
      chips.add(
        _chip(
          t,
          '${l.expFilterPeriod} ${f.periods.length}',
          () => onChange(f.copyWith(periods: [f.periods.first])),
        ),
      );
    } else if (f.periods.length == 1) {
      final p = f.periods.first;
      String md(String d) => d.length < 10
          ? d
          : '${int.parse(d.substring(5, 7))}.${int.parse(d.substring(8, 10))}';
      final label = switch (p.preset) {
        FilterPeriodPreset.week => l.expPeriodWeek,
        FilterPeriodPreset.month => l.expThisMonth,
        FilterPeriodPreset.threeMonth => l.expPeriod3Month,
        FilterPeriodPreset.custom => '${md(p.start)}~${md(p.end)}',
      };
      chips.add(_chip(t, label, () => onChange(f.copyWith(periods: const []))));
    }
    if (f.types.length < 2) {
      chips.add(
        _chip(
          t,
          f.types.contains('EXPENSE') ? l.expFilterExpense : l.expFilterIncome,
          () => onChange(f.copyWith(types: const {'EXPENSE', 'INCOME'})),
        ),
      );
    }
    if (f.categories.include.isNotEmpty) {
      final label = f.categories.include.length == 1
          ? (categories.byRowId(f.categories.include.first)?.categoryName ??
                '${f.categories.include.first}')
          : '${l.expCategory} ${f.categories.include.length}';
      chips.add(
        _chip(
          t,
          label,
          () => onChange(
            f.copyWith(categories: f.categories.copyWith(include: const {})),
          ),
        ),
      );
    }
    if (f.categories.exclude.isNotEmpty) {
      chips.add(
        _chip(
          t,
          l.expFilterExcluded(f.categories.exclude.length),
          () => onChange(
            f.copyWith(categories: f.categories.copyWith(exclude: const {})),
          ),
        ),
      );
    }
    if (f.assets.include.isNotEmpty) {
      final all = ref.watch(assetsProvider).value;
      final label = f.assets.include.length == 1
          ? (all?.byRowId(f.assets.include.first)?.assetName ??
                '${f.assets.include.first}')
          : '${l.expAccountCard} ${f.assets.include.length}';
      chips.add(
        _chip(
          t,
          label,
          () => onChange(
            f.copyWith(assets: f.assets.copyWith(include: const {})),
          ),
        ),
      );
    }
    if (f.assets.exclude.isNotEmpty) {
      chips.add(
        _chip(
          t,
          l.expFilterExcluded(f.assets.exclude.length),
          () => onChange(
            f.copyWith(assets: f.assets.copyWith(exclude: const {})),
          ),
        ),
      );
    }
    if (f.amountRanges.isNotEmpty) {
      chips.add(
        _chip(
          t,
          '${l.expAmountRange} ${f.amountRanges.length}',
          () => onChange(f.copyWith(amountRanges: const [])),
        ),
      );
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
              PDayGroupSkeleton(rows: 3),
              SizedBox(height: PSpace.x16),
              PDayGroupSkeleton(rows: 2),
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
