import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:wolt_modal_sheet/wolt_modal_sheet.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../expense/application/expense_providers.dart';
import '../../expense/domain/expense.dart';
import '../../expense/domain/expense_category.dart';
import '../application/expense_split_providers.dart';
import '../data/expense_split_repository.dart';
import '../domain/expense_split.dart';

/// 거래 분할 다이얼로그.
void showSplitTxDialog(BuildContext context, Expense expense) {
  WoltModalSheet.show<void>(
    context: context,
    pageListBuilder: (modalCtx) => [
      WoltModalSheetPage(
        topBarTitle: const Text('내역 분할'),
        isTopBarLayerAlwaysVisible: true,
        backgroundColor:
            Theme.of(modalCtx).extension<PorestTokens>()?.bgSurface,
        trailingNavBarWidget: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: Navigator.of(modalCtx).pop,
        ),
        child: _SplitBody(expense: expense),
      ),
    ],
  );
}

class _Row {
  _Row({this.categoryRowId, required this.amount, this.label = ''});
  int? categoryRowId;
  int amount;
  String label;
}

class _SplitBody extends ConsumerStatefulWidget {
  const _SplitBody({required this.expense});
  final Expense expense;

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
    setState(() => _submitting = true);
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteAll() async {
    if (_submitting) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('분할 해제'),
        content: const Text('이 거래의 분할 내역을 모두 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: context.tokens.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('해제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _submitting = true);
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
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _build(PorestTokens t, List<ExpenseCategory> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, PSpace.x8, PSpace.x16, PSpace.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('하나의 결제를 카테고리·항목별로 나누어 기록합니다.',
              style: PTypo.caption.copyWith(color: t.fgSecondary)),
          const SizedBox(height: PSpace.x12),

          // 원 거래 요약
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x12, vertical: PSpace.x12),
            decoration: BoxDecoration(
              color: t.bgMuted,
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
                            color: t.fgPrimary, fontWeight: FontWeight.w700),
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
                          fontWeight: FontWeight.w800),
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : _addRow,
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('항목 추가'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : _splitEvenly,
                  icon: const Icon(LucideIcons.scissors, size: 14),
                  label: const Text('균등 분배'),
                ),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x16),

          // 분할 비율
          Text('분할 비율',
              style: PTypo.caption
                  .copyWith(color: t.fgSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: PSpace.x8),
          _RatioBar(rows: _rows!, total: _totalAbs, categories: categories, tokens: t),
          const SizedBox(height: PSpace.x8),
          _RatioLegend(rows: _rows!, total: _totalAbs, categories: categories, tokens: t),
          const SizedBox(height: PSpace.x16),

          // 합계 상태 표시
          _MatchPill(
            matched: _matched,
            remainder: _remainder,
            tokens: t,
          ),
          const SizedBox(height: PSpace.x12),

          // 액션
          Row(
            children: [
              if (_hasExisting) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: t.statusDanger,
                      side: BorderSide(
                          color: t.statusDanger.withValues(alpha: 0.5)),
                    ),
                    onPressed: _submitting ? null : _deleteAll,
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('분할 해제'),
                  ),
                ),
                const SizedBox(width: PSpace.x8),
              ],
              Expanded(
                flex: _hasExisting ? 1 : 2,
                child: FilledButton(
                  onPressed: (_matched && !_submitting) ? _save : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('분할 저장'),
                ),
              ),
            ],
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                    color: t.bgMuted, borderRadius: PRadius.brPill),
                alignment: Alignment.center,
                child: Text('${widget.index + 1}',
                    style: PTypo.caption.copyWith(
                        color: t.fgSecondary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _labelCtrl,
                  decoration: const InputDecoration(
                      hintText: '항목 이름 (선택)',
                      isDense: true,
                      border: InputBorder.none),
                  enabled: !widget.disabled,
                  onChanged: (v) {
                    widget.row.label = v;
                  },
                ),
              ),
              IconButton(
                onPressed:
                    widget.disabled || !widget.canRemove ? null : widget.onRemove,
                icon: Icon(LucideIcons.x, size: 14, color: t.fgTertiary),
                tooltip: '항목 삭제',
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints.tightFor(width: 28, height: 28),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 5,
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
                flex: 4,
                child: TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.right,
                  enabled: !widget.disabled,
                  decoration: const InputDecoration(
                    hintText: '0',
                    suffixText: '원',
                    isDense: true,
                  ),
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
    return DropdownButtonFormField<int>(
      initialValue:
          value != null && categories.any((c) => c.rowId == value) ? value : null,
      isDense: true,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        hintText: '카테고리',
      ),
      items: [
        for (final c in categories)
          DropdownMenuItem<int>(
            value: c.rowId,
            child: Text(c.categoryName,
                style: PTypo.bodySm.copyWith(color: tokens.fgPrimary)),
          ),
      ],
      onChanged: onChanged,
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
      borderRadius: PRadius.brPill,
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
          decoration: BoxDecoration(color: color, borderRadius: PRadius.brPill),
        ),
        const SizedBox(width: 5),
        Text(cat?.categoryName ?? '미선택',
            style: PTypo.caption.copyWith(color: tokens.fgSecondary)),
        const SizedBox(width: 4),
        Text('$pct%',
            style: PTypo.caption.copyWith(
                color: tokens.fgPrimary, fontWeight: FontWeight.w700)),
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
      decoration: BoxDecoration(color: bg, borderRadius: PRadius.brPill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: PTypo.caption.copyWith(
                  color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
