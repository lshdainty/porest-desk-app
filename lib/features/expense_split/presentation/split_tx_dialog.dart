import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_select.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../../expense/domain/expense_category.dart';
import '../application/expense_split_providers.dart';
import '../data/expense_split_repository.dart';
import '../domain/expense_split.dart';

/// 거래 분할 다이얼로그.
void showSplitTxDialog(BuildContext context, Expense expense) {
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
  });
  final Expense expense;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_SplitBody> createState() => _SplitBodyState();
}

class _SplitBodyState extends ConsumerState<_SplitBody> {
  List<_Row>? _rows;
  bool _submitting = false;
  bool _hasExisting = false;

  int get _totalAbs => widget.expense.amount.abs();
  bool get _isIncome => widget.expense.expenseType == 'INCOME';

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
      widget.controller.onDelete = _hasExisting ? _deleteAll : null;
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
        child: Center(child: CircularProgressIndicator()),
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

  Future<void> _save() async {
    if (!_matched || _submitting) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(expenseSplitRepositoryProvider.future);
      await repo.replace(
        widget.expense.rowId,
        splits: [
          for (int i = 0; i < _rows!.length; i++)
            SplitInput(
              categoryRowId: _rows![i].categoryRowId!,
              amount: _rows![i].amount,
              label: _rows![i].label.trim().isEmpty
                  ? null
                  : _rows![i].label.trim(),
              sortOrder: i,
            ),
        ],
      );
      ref.invalidate(expenseSplitsProvider(widget.expense.rowId));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('분할이 저장되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: ${e.message}')),
      );
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
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해제 실패: ${e.message}')),
      );
    } finally {
      if (mounted) _setSubmitting(false);
    }
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
                    Text(
                      '${_isIncome ? '+' : '-'}${krw(_totalAbs)}',
                      style: PTypo.h3.copyWith(
                          color: _isIncome
                              ? t.statusSuccess
                              : t.fgPrimary,
                          fontWeight: PFontWeight.heavy),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          // Rows
          Column(
            children: [
              for (int i = 0; i < _rows!.length; i++) ...[
                _SplitRowCard(
                  index: i,
                  row: _rows![i],
                  categories: categories,
                  canRemove: _rows!.length > 1,
                  disabled: _submitting,
                  tokens: t,
                  onChange: () => setState(() {}),
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
    final t = context.tokens;
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final state = bodyKey.currentState;
        final remainder = state?._rows == null ? 0 : state!._remainder;
        final matched = state?._rows == null ? false : state!._matched;
        final hasExisting = state?._hasExisting ?? false;
        return Row(
          children: [
            if (hasExisting)
              TextButton.icon(
                onPressed: controller.submitting ? null : controller.onDelete,
                icon: Icon(LucideIcons.trash2,
                    size: PSpace.x12, color: t.statusDangerFg),
                label: Text('분할 해제',
                    style: PTypo.body.copyWith(color: t.statusDangerFg)),
              ),
            const SizedBox(width: PSpace.x4),
            _MatchPill(
              matched: matched,
              remainder: remainder,
              tokens: t,
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
    required this.categories,
    required this.canRemove,
    required this.disabled,
    required this.tokens,
    required this.onChange,
    required this.onRemove,
  });
  final int index;
  final _Row row;
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

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    // front 1행 layout 미러: [# circle] [label] [category dropdown] [amount + 원] [X]
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
                color: t.bgMuted, borderRadius: PRadius.brFull),
            alignment: Alignment.center,
            child: Text('${widget.index + 1}',
                style: PTypo.caption.copyWith(
                    color: t.fgSecondary, fontWeight: PFontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 14,
            child: TextField(
              controller: _labelCtrl,
              style: PTypo.caption.copyWith(color: t.fgPrimary),
              decoration: InputDecoration(
                hintText: '항목 이름',
                hintStyle: PTypo.caption.copyWith(color: t.fgTertiary),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: false,
                border: OutlineInputBorder(
                    borderRadius: PRadius.brSm,
                    borderSide: BorderSide(color: t.borderSubtle)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: PRadius.brSm,
                    borderSide: BorderSide(color: t.borderSubtle)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: PRadius.brSm,
                    borderSide: BorderSide(color: t.borderBrand)),
              ),
              enabled: !widget.disabled,
              onChanged: (v) {
                widget.row.label = v;
              },
            ),
          ),
          const SizedBox(width: 6),
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
          const SizedBox(width: 6),
          Expanded(
            flex: 11,
            child: TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.right,
              enabled: !widget.disabled,
              style: PTypo.caption.copyWith(
                  color: t.fgPrimary, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: PTypo.caption.copyWith(color: t.fgTertiary),
                suffixText: '원',
                suffixStyle: PTypo.caption.copyWith(color: t.fgTertiary),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: false,
                border: OutlineInputBorder(
                    borderRadius: PRadius.brSm,
                    borderSide: BorderSide(color: t.borderSubtle)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: PRadius.brSm,
                    borderSide: BorderSide(color: t.borderSubtle)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: PRadius.brSm,
                    borderSide: BorderSide(color: t.borderBrand)),
              ),
              onChanged: (v) {
                widget.row.amount = int.tryParse(v) ?? 0;
                widget.onChange();
              },
            ),
          ),
          IconButton(
            onPressed: widget.disabled || !widget.canRemove
                ? null
                : widget.onRemove,
            icon: Icon(LucideIcons.x, size: 14, color: t.fgTertiary),
            tooltip: '항목 삭제',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints.tightFor(width: 24, height: 24),
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
                    color: parseColor(
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
          _legendChip(r),
      ],
    );
  }

  Widget _legendChip(_Row r) {
    final cat = _cat(r.categoryRowId);
    final color = parseColor(cat?.color, fallback: tokens.fgBrand);
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

class _MatchPill extends StatelessWidget {
  const _MatchPill({
    required this.matched,
    required this.remainder,
    required this.tokens,
  });
  final bool matched;
  final int remainder;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final bg = matched
        ? tokens.statusSuccessSubtle
        : tokens.statusDangerSubtle;
    final fg = matched ? tokens.statusSuccessFg : tokens.statusDangerFg;
    final label = matched
        ? '합계 일치'
        : (remainder > 0
            ? '${krw(remainder)}원 부족'
            : '${krw(-remainder)}원 초과');
    final icon = matched ? LucideIcons.check : LucideIcons.alertTriangle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: PRadius.brFull),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: PTypo.caption.copyWith(
                  color: fg, fontWeight: PFontWeight.bold)),
        ],
      ),
    );
  }
}
