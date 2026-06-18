import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/sync/keep_alive_refresh.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/expense_split/application/expense_split_providers.dart';
import 'package:porest_desk_app/features/expense_split/data/expense_split_repository.dart';
import 'package:porest_desk_app/features/expense_split/domain/expense_split.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 거래 분할 다이얼로그.
///
/// [onReconciled] 가 주어지면 "분할 저장"이 서버 저장(replace) 대신 이 콜백으로 분할을 반환한다
/// (거래 편집 화면이 금액+분할을 한 번에 원자적으로 저장하기 위한 일치화 모드).
/// [overrideTotal] 은 일치화 목표 총액(편집 중 바뀐 금액), [recordedTotal] 은 변경 전 총액(전/후 배지),
/// [initialSplits] 는 진행 중 분할 시드.
void showSplitTxDialog(
  BuildContext context,
  Expense expense, {
  int? overrideTotal,
  int? recordedTotal,
  List<SplitInput>? initialSplits,
  void Function(List<SplitInput> splits)? onReconciled,
}) {
  final controller = PSheetController();
  final bodyKey = GlobalKey<_SplitBodyState>();
  showPSheet<void>(
    context,
    title: '내역 분할',
    contentBuilder: (ctx, scrollCtrl) => _SplitBody(
      key: bodyKey,
      expense: expense,
      scrollController: scrollCtrl,
      controller: controller,
      overrideTotal: overrideTotal,
      recordedTotal: recordedTotal,
      initialSplits: initialSplits,
      onReconciled: onReconciled,
    ),
    footerBuilder: (ctx) => _SplitFooter(controller: controller, bodyKey: bodyKey),
  );
}

class _Row {
  _Row({this.categoryRowId, required this.amount, this.label = ''});
  int? categoryRowId;
  int amount;
  String label;
}

class _SplitBody extends ConsumerStatefulWidget {
  const _SplitBody({
    super.key,
    required this.expense,
    required this.scrollController,
    required this.controller,
    this.overrideTotal,
    this.recordedTotal,
    this.initialSplits,
    this.onReconciled,
  });
  final Expense expense;
  final ScrollController scrollController;
  final PSheetController controller;
  final int? overrideTotal;
  final int? recordedTotal;
  final List<SplitInput>? initialSplits;
  final void Function(List<SplitInput> splits)? onReconciled;

  @override
  ConsumerState<_SplitBody> createState() => _SplitBodyState();
}

class _SplitBodyState extends ConsumerState<_SplitBody> {
  List<_Row>? _rows;
  bool _submitting = false;
  bool _hasExisting = false;
  String? _lastApplied; // 방금 적용한 정합 전략 ('prop'|'largest'|'add')
  bool _quickOpen = false; // '빠르게 맞추기' 접힘 상태(기본 접힘)

  // 일치화 목표 총액 = overrideTotal(편집 중 바뀐 금액) ?? 거래 금액.
  int get _totalAbs => widget.overrideTotal ?? widget.expense.amount.abs();
  int get _recordedTotal => widget.recordedTotal ?? widget.expense.amount.abs();
  bool get _isIncome => widget.expense.expenseType == 'INCOME';
  bool get _reconcileMode => widget.onReconciled != null;
  // 전/후 배지: 편집 일치화로 목표 총액이 기존 총액과 다를 때만.
  bool get _totalChanged =>
      widget.overrideTotal != null && widget.overrideTotal != _recordedTotal;

  @override
  void initState() {
    super.initState();
    widget.controller.onSubmit = _save;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  void _syncFooter() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.setCanSubmit(_matched);
      // 일치화 모드에선 '분할 해제' 숨김(편집 흐름에서 분할 제거는 별도 동작).
      widget.controller.onDelete =
          (_hasExisting && !_reconcileMode) ? _deleteAll : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final splitsAsync =
        ref.watch(expenseSplitsProvider(widget.expense.rowId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return splitsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(PSpace.x32),
        child: Center(child: PCircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(PSpace.x16),
        child: Text('분할 내역 로드 실패\n$e',
            style: PTypo.bodySm.copyWith(color: t.statusDanger)),
      ),
      data: (splits) {
        if (_rows == null) _initRows(splits);
        final categories = categoriesAsync.value ?? const <ExpenseCategory>[];
        final sameTypeCategories = categories
            .where((c) =>
                c.expenseType == null ||
                c.expenseType == widget.expense.expenseType)
            .toList();
        _syncFooter();
        return _build(t, sameTypeCategories);
      },
    );
  }

  void _initRows(List<ExpenseSplit> splits) {
    _hasExisting = splits.isNotEmpty;
    // 편집 일치화: 진행 중 분할(initialSplits)로 시드
    if (widget.initialSplits != null && widget.initialSplits!.isNotEmpty) {
      _rows = widget.initialSplits!
          .map((s) => _Row(
              categoryRowId: s.categoryRowId, amount: s.amount, label: s.label ?? ''))
          .toList();
      return;
    }
    if (splits.isNotEmpty) {
      _rows = splits
          .map((s) => _Row(
              categoryRowId: s.categoryRowId,
              amount: s.amount,
              label: s.label ?? ''))
          .toList();
    } else {
      final half = _totalAbs ~/ 2;
      _rows = [
        _Row(
            categoryRowId: widget.expense.categoryRowId,
            amount: _totalAbs - half,
            label: widget.expense.merchant ??
                widget.expense.description ??
                ''),
        _Row(
            categoryRowId: widget.expense.categoryRowId,
            amount: half,
            label: ''),
      ];
    }
  }

  int get _sum => _rows!.fold(0, (s, r) => s + r.amount);
  int get _remainder => _totalAbs - _sum;
  bool get _matched =>
      _remainder == 0 &&
      _rows!.length >= 2 &&
      _rows!.every((r) => r.categoryRowId != null && r.amount > 0);
  // 잔액 0(합계 일치)이지만 카테고리 누락·행 부족으로 미저장 가능 — '0원 초과' 오표기 방지.
  bool get _balanced => _remainder == 0;

  void _addRow() {
    setState(() {
      _rows!.add(_Row(
        categoryRowId: widget.expense.categoryRowId,
        amount: _remainder > 0 ? _remainder : 0,
      ));
    });
  }

  void _removeRow(int idx) {
    if (_rows!.length <= 1) return;
    setState(() => _rows!.removeAt(idx));
  }

  void _splitEvenly() {
    if (_rows!.isEmpty) return;
    final each = _totalAbs ~/ _rows!.length;
    final rest = _totalAbs - each * _rows!.length;
    setState(() {
      for (int i = 0; i < _rows!.length; i++) {
        _rows![i].amount = i == 0 ? each + rest : each;
      }
    });
  }

  // ── 일치화(reconcile) 전략 ─────────────────────────────────────────────
  /// 금액 배열의 합이 정확히 target 이 되도록 잔차를 분배(항상 균형). target≥행수면 모든 행 1 이상 유지.
  static List<int> _settleRemainder(List<int> amts, int target) {
    final n = amts.length;
    if (n == 0) return amts;
    final floor = target >= n ? 1 : 0;
    final out = [for (final v in amts) v < floor ? floor : v];
    final diff = target - out.fold<int>(0, (s, v) => s + v);
    final order = [for (int i = 0; i < n; i++) i]..sort((a, b) => out[b] - out[a]);
    if (diff > 0) {
      out[order[0]] += diff;
    } else if (diff < 0) {
      var need = -diff;
      for (final idx in order) {
        if (need <= 0) break;
        final cap = out[idx] - floor;
        final take = cap < need ? cap : need;
        out[idx] -= take;
        need -= take;
      }
    }
    return out;
  }

  /// ① 비례 배분 — 현재 비중대로 새 총액에 맞춰 재분배(잔차까지 정확히 흡수).
  void _reconcileProportional() {
    final base = _rows!.fold<int>(0, (s, r) => s + r.amount);
    final b = base == 0 ? 1 : base;
    final scaled = [for (final r in _rows!) ((r.amount * _totalAbs) / b).round()];
    final settled = _settleRemainder(scaled, _totalAbs);
    setState(() {
      for (int i = 0; i < _rows!.length; i++) {
        _rows![i].amount = settled[i];
      }
      _lastApplied = 'prop';
    });
  }

  /// ② 가장 큰 항목에 차액 반영(부족하면 다음 큰 항목으로 흘려보냄).
  void _reconcileToLargest() {
    final amts = [for (final r in _rows!) r.amount];
    final settled = _settleRemainder(amts, _totalAbs);
    setState(() {
      for (int i = 0; i < _rows!.length; i++) {
        _rows![i].amount = settled[i];
      }
      _lastApplied = 'largest';
    });
  }

  /// ③ 부족분을 새 조정 항목으로 추가(부족할 때만 노출).
  void _reconcileAddRow() {
    if (_remainder <= 0) return;
    setState(() {
      _rows!.add(_Row(
          categoryRowId: widget.expense.categoryRowId,
          amount: _remainder,
          label: '추가 금액'));
      _lastApplied = 'add';
    });
  }

  /// 수동 편집 시 전략 활성 표시 해제.
  void _onRowEdited() => setState(() => _lastApplied = null);

  /// 분할은 실제 금액(자산 잔액)·거래 목록에 영향 — 관련 캐시 무효화.
  void _invalidateExpenseAndAssets() {
    final iso = widget.expense.expenseDate;
    if (iso != null && iso.length >= 10) {
      final p = iso.substring(0, 10).split('-');
      ref.invalidate(
        monthExpensesProvider((year: int.parse(p[0]), month: int.parse(p[1]))),
      );
    }
    invalidateAssetsAfterExpense(ref);
  }

  Future<void> _save() async {
    if (!_matched || _submitting) return;
    final inputs = <SplitInput>[
      for (int i = 0; i < _rows!.length; i++)
        SplitInput(
          categoryRowId: _rows![i].categoryRowId!,
          amount: _rows![i].amount,
          label: _rows![i].label.trim().isEmpty ? null : _rows![i].label.trim(),
          sortOrder: i,
        ),
    ];
    // 일치화 모드: 서버 저장 대신 콜백으로 분할 반환(편집 화면이 금액+분할을 원자적으로 저장).
    if (widget.onReconciled != null) {
      Navigator.of(context).pop();
      widget.onReconciled!(inputs);
      return;
    }
    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseSplitRepositoryProvider.future);
      await repo.replace(widget.expense.rowId, splits: inputs);
      ref.invalidate(expenseSplitsProvider(widget.expense.rowId));
      _invalidateExpenseAndAssets();
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, '분할이 저장되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '저장 실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _deleteAll() async {
    if (_submitting) return;
    final ok = await showPConfirmDialog(
      context,
      title: '분할 해제',
      message: '이 거래의 분할 내역을 모두 삭제하시겠습니까?',
      confirmLabel: '해제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseSplitRepositoryProvider.future);
      await repo.deleteAll(widget.expense.rowId);
      ref.invalidate(expenseSplitsProvider(widget.expense.rowId));
      _invalidateExpenseAndAssets();
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '해제 실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  /// 상태 패널 — 일치(success) / 불일치(warning). footer 검증 pill 대체.
  Widget _statusPanel(PorestTokens t) =>
      _matched ? _successPanel(t) : _reconcilePanel(t);

  Widget _successPanel(PorestTokens t) {
    return Container(
      padding: const EdgeInsets.all(PSpace.x12),
      decoration: BoxDecoration(
        color: t.statusSuccessSubtle,
        borderRadius: PRadius.brLg,
        border: Border.all(color: t.statusSuccessBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.check, size: 15, color: t.statusSuccessFg),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: Text('분할 합계가 총액과 일치해요',
                    style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary, fontWeight: PFontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x4),
          Text.rich(
            TextSpan(
              style: PTypo.caption
                  .copyWith(color: t.fgSecondary, height: PLineHeight.normal),
              children: [
                const TextSpan(text: '분할 합계 '),
                TextSpan(
                    text: '${krw(_sum)}원',
                    style: const TextStyle(fontWeight: PFontWeight.bold)),
                const TextSpan(text: ' · 총액 '),
                TextSpan(
                    text: '${krw(_totalAbs)}원',
                    style: const TextStyle(fontWeight: PFontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reconcilePanel(PorestTokens t) {
    final shortage = _remainder > 0;
    return Container(
      padding: const EdgeInsets.all(PSpace.x12),
      decoration: BoxDecoration(
        color: t.statusWarningSubtle,
        borderRadius: PRadius.brLg,
        border: Border.all(color: t.statusWarningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.alertTriangle, size: 15, color: t.statusWarningFg),
              const SizedBox(width: PSpace.x8),
              Expanded(
                child: Text(
                  !_balanced
                      ? (_totalChanged ? '총액이 바뀌어 분할을 맞춰야 해요' : '분할 합계가 총액과 달라요')
                      : '분할 항목을 확인해주세요',
                  style: PTypo.bodySm
                      .copyWith(color: t.fgPrimary, fontWeight: PFontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x4),
          // 숫자 강조(웹 정합): 분할 합계·총액 bold, 초과/부족은 bold + warning 색.
          Text.rich(
            TextSpan(
              style: PTypo.caption
                  .copyWith(color: t.fgSecondary, height: PLineHeight.normal),
              children: [
                const TextSpan(text: '분할 합계 '),
                TextSpan(
                    text: '${krw(_sum)}원',
                    style: const TextStyle(fontWeight: PFontWeight.bold)),
                const TextSpan(text: ' · 총액 '),
                TextSpan(
                    text: '${krw(_totalAbs)}원',
                    style: const TextStyle(fontWeight: PFontWeight.bold)),
                if (!_balanced) ...[
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: '${shortage ? '부족' : '초과'} ${krw(_remainder.abs())}원',
                    style: TextStyle(
                        fontWeight: PFontWeight.bold, color: t.statusWarningFg),
                  ),
                ],
              ],
            ),
          ),
          // 합계가 어긋날 때만 '빠르게 맞추기' 토글 노출(잔액 조정 전략이라 의미 있음).
          if (!_balanced) ...[
            const SizedBox(height: PSpace.x8),
            InkWell(
              onTap: _submitting
                  ? null
                  : () => setState(() => _quickOpen = !_quickOpen),
              borderRadius: PRadius.brSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.sparkles, size: 14, color: t.fgBrand),
                    const SizedBox(width: 6),
                    Text('빠르게 맞추기',
                        style: PTypo.caption.copyWith(
                            color: t.fgBrand, fontWeight: PFontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(
                        _quickOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 14,
                        color: t.fgBrand),
                  ],
                ),
              ),
            ),
            if (_quickOpen) ...[
              const SizedBox(height: 6),
              _reconcileBtn(t,
                  icon: LucideIcons.scale,
                  title: '비례 배분',
                  desc: '비중대로 자동 조정',
                  active: _lastApplied == 'prop',
                  recommended: _totalChanged,
                  onTap: _reconcileProportional),
              const SizedBox(height: 6),
              _reconcileBtn(t,
                  icon: LucideIcons.moveUp,
                  title: '큰 항목 반영',
                  desc: '가장 큰 항목에 차액',
                  active: _lastApplied == 'largest',
                  onTap: _reconcileToLargest),
              if (_remainder > 0) ...[
                const SizedBox(height: 6),
                _reconcileBtn(t,
                    icon: LucideIcons.plusCircle,
                    title: '조정 항목',
                    desc: '부족분을 새 항목으로',
                    active: _lastApplied == 'add',
                    onTap: _reconcileAddRow),
              ],
            ],
          ],
        ],
      ),
    );
  }

  Widget _reconcileBtn(
    PorestTokens t, {
    required IconData icon,
    required String title,
    required String desc,
    required bool active,
    bool recommended = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _submitting ? null : onTap,
      borderRadius: PRadius.brMd,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: active ? t.statusWarningSubtle : t.bgSurface,
          borderRadius: PRadius.brMd,
          border: Border.all(
              color: active ? t.statusWarningFg : t.statusWarningBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: t.statusWarningFg),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(title,
                            style: PTypo.caption.copyWith(
                                color: t.fgPrimary,
                                fontWeight: PFontWeight.bold)),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: t.statusWarningSubtle,
                              borderRadius: PRadius.brFull),
                          child: Text('추천',
                              style: PTypo.caption.copyWith(
                                  color: t.statusWarningFg,
                                  fontWeight: PFontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  Text(desc,
                      style: PTypo.caption.copyWith(color: t.fgSecondary)),
                ],
              ),
            ),
            if (active)
              Icon(LucideIcons.check, size: 14, color: t.statusWarningFg),
          ],
        ),
      ),
    );
  }

  Widget _build(PorestTokens t, List<ExpenseCategory> categories) {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x20, 0, PSpace.x20, PSpace.x16),
      children: [
        Text(
            '하나의 결제를 카테고리·항목별로 나누어 기록합니다. 예: 마트에서 식품과 생활품을 함께 결제한 경우.',
            style: PTypo.caption
                .copyWith(color: t.fgSecondary, height: PLineHeight.normal)),
        const SizedBox(height: PSpace.x12),

        // 원 거래 요약
        Container(
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x12, vertical: PSpace.x12),
            decoration: BoxDecoration(
              borderRadius: PRadius.brMd,
              border: Border.all(color: t.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('원 거래',
                          style:
                              PTypo.caption.copyWith(color: t.fgTertiary)),
                      const SizedBox(height: 2),
                      Text(
                        widget.expense.merchant ??
                            widget.expense.description ??
                            '거래',
                        style: PTypo.body.copyWith(
                            color: t.fgPrimary, fontWeight: PFontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('총액',
                        style: PTypo.caption.copyWith(color: t.fgTertiary)),
                    const SizedBox(height: 2),
                    if (_totalChanged)
                      // 총액 변경: 기존(취소선) → 새 총액(warning)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(krw(_recordedTotal),
                              style: PTypo.caption.copyWith(
                                  color: t.fgTertiary,
                                  decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 4),
                          Icon(LucideIcons.arrowRight, size: 12, color: t.fgTertiary),
                          const SizedBox(width: 4),
                          Text('${_isIncome ? '+' : '−'}${krw(_totalAbs)}원',
                              style: PTypo.h3.copyWith(
                                  color: t.statusWarningFg,
                                  fontWeight: PFontWeight.bold)),
                        ],
                      )
                    else
                      Text(
                        '${_isIncome ? '+' : '−'}${krw(_totalAbs)}원',
                        style: PTypo.h3.copyWith(
                            // 수입 금액 = primary(다크 primary-light). success(초록) 아님 — web 정합
                            color: _isIncome ? t.fgBrandStrong : t.fgPrimary,
                            fontWeight: PFontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // 상태 패널 — 일치(success)/불일치(warning). footer 검증 pill 대체.
          if (_rows!.isNotEmpty) ...[
            _statusPanel(t),
            const SizedBox(height: PSpace.x16),
          ],

          // Rows
          Column(
            children: [
              for (int i = 0; i < _rows!.length; i++) ...[
                _SplitRowCard(
                  index: i,
                  row: _rows![i],
                  total: _totalAbs,
                  categories: categories,
                  canRemove: _rows!.length > 1,
                  disabled: _submitting,
                  tokens: t,
                  onChange: _onRowEdited,
                  onRemove: () => _removeRow(i),
                ),
                if (i < _rows!.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
          const SizedBox(height: PSpace.x12),

          Row(
            children: [
              PButton(
                label: '항목 추가',
                icon: LucideIcons.plus,
                variant: PButtonVariant.ghost,
                size: PButtonSize.sm,
                onPressed: _submitting ? null : _addRow,
              ),
              const Spacer(),
              PButton(
                label: '균등 분배',
                icon: LucideIcons.scissors,
                variant: PButtonVariant.ghost,
                size: PButtonSize.sm,
                onPressed: _submitting ? null : _splitEvenly,
              ),
            ],
          ),
          const SizedBox(height: PSpace.x16),

          // 분할 비율
          Text('분할 비율',
              style: PTypo.caption
                  .copyWith(color: t.fgSecondary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          _RatioBar(rows: _rows!, total: _totalAbs, categories: categories, tokens: t),
          const SizedBox(height: PSpace.x8),
          _RatioLegend(rows: _rows!, total: _totalAbs, categories: categories, tokens: t),
          const SizedBox(height: PSpace.x16),
      ],
    );
  }
}

class _SplitFooter extends StatelessWidget {
  const _SplitFooter({required this.controller, required this.bodyKey});
  final PSheetController controller;
  final GlobalKey<_SplitBodyState> bodyKey;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final state = bodyKey.currentState;
        final matched = state?._rows == null ? false : state!._matched;
        final hasExisting = state?._hasExisting ?? false;
        return Row(
          children: [
            if (hasExisting && !(state?._reconcileMode ?? false))
              PButton(
                label: '분할 해제',
                icon: LucideIcons.trash2,
                variant: PButtonVariant.ghost,
                dangerous: true,
                flush: PButtonFlush.left,
                onPressed: controller.submitting ? null : controller.onDelete,
              ),
            const Spacer(),
            PButton(
              label: '취소',
              variant: PButtonVariant.ghost,
              onPressed: controller.submitting
                  ? null
                  : () => Navigator.of(ctx).pop(),
            ),
            const SizedBox(width: PSpace.x8),
            PButton(
              label: '분할 저장',
              loading: controller.submitting,
              onPressed: (matched && !controller.submitting)
                  ? controller.onSubmit
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _SplitRowCard extends StatefulWidget {
  const _SplitRowCard({
    required this.index,
    required this.row,
    required this.total,
    required this.categories,
    required this.canRemove,
    required this.disabled,
    required this.tokens,
    required this.onChange,
    required this.onRemove,
  });
  final int index;
  final _Row row;
  final int total;
  final List<ExpenseCategory> categories;
  final bool canRemove;
  final bool disabled;
  final PorestTokens tokens;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  State<_SplitRowCard> createState() => _SplitRowCardState();
}

class _SplitRowCardState extends State<_SplitRowCard> {
  late final TextEditingController _labelCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.row.label);
    _amountCtrl =
        TextEditingController(text: widget.row.amount > 0 ? widget.row.amount.toString() : '');
  }

  @override
  void didUpdateWidget(_SplitRowCard old) {
    super.didUpdateWidget(old);
    final newAmt = widget.row.amount.toString();
    if (_amountCtrl.text != (widget.row.amount > 0 ? newAmt : '') &&
        widget.row.amount.toString() != _amountCtrl.text) {
      // 외부(균등 분배 등)로 amount 변경됐을 때 동기화
      _amountCtrl.value = TextEditingValue(
        text: widget.row.amount > 0 ? newAmt : '',
        selection: TextSelection.collapsed(
            offset: widget.row.amount > 0 ? newAmt.length : 0),
      );
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  String? _catColor() {
    final id = widget.row.categoryRowId;
    if (id == null) return null;
    for (final c in widget.categories) {
      if (c.rowId == id) return c.color;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    // 스택형 카드 layout(front 미러): 헤더(색 점·항목N·비율%·삭제) / 라벨 / 카테고리+금액
    final pct =
        widget.total > 0 ? ((widget.row.amount / widget.total) * 100).round() : 0;
    final dotColor =
        resolveChartColor(context, _catColor(), fallback: t.fgBrand);
    return Container(
      padding: const EdgeInsets.all(PSpace.x12),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 색 점 + 항목 N + 비율% + 삭제
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: dotColor, borderRadius: PRadius.brXs),
              ),
              const SizedBox(width: 6),
              Text('항목 ${widget.index + 1}',
                  style: PTypo.caption.copyWith(
                      color: t.fgSecondary, fontWeight: PFontWeight.semi)),
              const Spacer(),
              Text('$pct%',
                  style: PTypo.caption.copyWith(
                      color: t.fgTertiary, fontWeight: PFontWeight.bold)),
              const SizedBox(width: 4),
              PButton.icon(
                icon: LucideIcons.x,
                size: PButtonSize.sm,
                iconColor: t.fgTertiary,
                tooltip: '항목 삭제',
                onPressed: widget.disabled || !widget.canRemove
                    ? null
                    : widget.onRemove,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 항목 이름 — 전체폭
          PTextInput(
            controller: _labelCtrl,
            placeholder: '항목 이름 (선택)',
            enabled: !widget.disabled,
            onChanged: (v) {
              widget.row.label = v;
            },
          ),
          const SizedBox(height: 8),
          // 카테고리 + 금액
          Row(
            children: [
              Expanded(
                flex: 10,
                child: _CategoryDropdown(
                  value: widget.row.categoryRowId,
                  categories: widget.categories,
                  onChanged: widget.disabled
                      ? null
                      : (v) {
                          widget.row.categoryRowId = v;
                          widget.onChange();
                        },
                  tokens: t,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 14,
                child: PTextInput(
                  controller: _amountCtrl,
                  numbersOnly: true,
                  textAlign: TextAlign.right,
                  enabled: !widget.disabled,
                  placeholder: '0',
                  suffixText: '원',
                  onChanged: (v) {
                    widget.row.amount = int.tryParse(v) ?? 0;
                    widget.onChange();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.value,
    required this.categories,
    required this.onChanged,
    required this.tokens,
  });
  final int? value;
  final List<ExpenseCategory> categories;
  final ValueChanged<int?>? onChanged;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return PSelect<int>(
      value: value != null && categories.any((c) => c.rowId == value)
          ? value
          : null,
      placeholder: '카테고리',
      enabled: onChanged != null,
      items: [
        for (final c in categories)
          PSelectItem<int>(value: c.rowId, label: c.categoryName),
      ],
      onChanged: onChanged ?? (_) {},
    );
  }
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({
    required this.rows,
    required this.total,
    required this.categories,
    required this.tokens,
  });
  final List<_Row> rows;
  final int total;
  final List<ExpenseCategory> categories;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: PRadius.brFull,
      child: Container(
        height: 10,
        color: tokens.bgTrack,
        child: Row(
          children: [
            for (final r in rows)
              if (total > 0 && r.amount > 0)
                Flexible(
                  flex: r.amount,
                  child: Container(
                    // 카테고리 색도 light/dark 테마 적응(base↔light) — legend dot 과 동일.
                    color: resolveChartColor(context,
                        _catColor(r.categoryRowId),
                        fallback: tokens.fgBrand),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String? _catColor(int? rowId) {
    if (rowId == null) return null;
    for (final c in categories) {
      if (c.rowId == rowId) return c.color;
    }
    return null;
  }
}

class _RatioLegend extends StatelessWidget {
  const _RatioLegend({
    required this.rows,
    required this.total,
    required this.categories,
    required this.tokens,
  });
  final List<_Row> rows;
  final int total;
  final List<ExpenseCategory> categories;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final r in rows)
          _legendChip(context, r),
      ],
    );
  }

  Widget _legendChip(BuildContext context, _Row r) {
    final cat = _cat(r.categoryRowId);
    final color = resolveChartColor(context, cat?.color, fallback: tokens.fgBrand);
    final pct = total > 0 ? ((r.amount / total) * 100).round() : 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: PRadius.brFull),
        ),
        const SizedBox(width: 5),
        Text(cat?.categoryName ?? '미선택',
            style: PTypo.caption.copyWith(color: tokens.fgSecondary)),
        const SizedBox(width: 4),
        Text('$pct%',
            style: PTypo.caption.copyWith(
                color: tokens.fgPrimary, fontWeight: PFontWeight.bold)),
      ],
    );
  }

  ExpenseCategory? _cat(int? rowId) {
    if (rowId == null) return null;
    for (final c in categories) {
      if (c.rowId == rowId) return c;
    }
    return null;
  }
}
