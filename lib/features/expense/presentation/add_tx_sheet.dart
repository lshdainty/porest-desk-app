import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../asset/application/asset_providers.dart';
import '../../preset/application/preset_providers.dart';
import '../../preset/domain/expense_template.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';

/// 거래 추가/편집 시트 (front `AddTxSheet` 미러).
///
/// [edit] 가 주어지면 편집 모드 (PUT /expense/{id}), 아니면 신규 (POST /expense).
/// 성공 시 해당 월 expensesProvider invalidate.
void showAddTxSheet(BuildContext context, {String? defaultDate, Expense? edit}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor:
        Theme.of(context).extension<PorestTokens>()?.bgSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => _AddTxBody(
        defaultDate: defaultDate,
        edit: edit,
        scrollController: scrollCtrl,
      ),
    ),
  );
}

class _AddTxBody extends ConsumerStatefulWidget {
  const _AddTxBody({
    this.defaultDate,
    this.edit,
    required this.scrollController,
  });
  final String? defaultDate;
  final Expense? edit;
  final ScrollController scrollController;

  @override
  ConsumerState<_AddTxBody> createState() => _AddTxBodyState();
}

class _AddTxBodyState extends ConsumerState<_AddTxBody> {
  late String _type;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _paymentCtrl;
  late final TextEditingController _feeCtrl;
  int? _categoryRowId;
  int? _assetRowId; // EXPENSE/INCOME 자산, TRANSFER 의 출금 자산
  int? _toAssetRowId; // TRANSFER 입금 자산
  late DateTime _date;
  bool _submitting = false;

  /// 프리셋을 통해 폼이 초기화된 경우 해당 프리셋 ID — 저장 성공 후 /touch.
  int? _appliedPresetId;
  bool _amountLocked = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _type = e?.expenseType ?? 'EXPENSE';
    _amountCtrl = TextEditingController(text: e == null ? '' : e.amount.toString());
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _merchantCtrl = TextEditingController(text: e?.merchant ?? '');
    _paymentCtrl = TextEditingController(text: e?.paymentMethod ?? '');
    _feeCtrl = TextEditingController();
    _categoryRowId = e?.categoryRowId;
    _assetRowId = e?.assetRowId;
    if (e?.expenseDate != null) {
      _date = parseIsoDate(e!.expenseDate!.substring(0, 10));
    } else if (widget.defaultDate != null) {
      _date = parseIsoDate(widget.defaultDate!);
    } else {
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _merchantCtrl.dispose();
    _paymentCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(ExpenseTemplate p) {
    setState(() {
      _appliedPresetId = p.rowId;
      _type = p.expenseType;
      _amountCtrl.text = p.amount.toString();
      _categoryRowId = p.categoryRowId;
      _assetRowId = p.assetRowId;
      _descCtrl.text = p.description ?? '';
      _merchantCtrl.text = p.merchant ?? '';
      _paymentCtrl.text = p.paymentMethod ?? '';
      _amountLocked = (p.lockAmount ?? 'N') == 'Y';
    });
  }

  bool get _canSubmit {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (_submitting || amount == null || amount <= 0) return false;
    if (_type == 'TRANSFER') {
      return _assetRowId != null &&
          _toAssetRowId != null &&
          _assetRowId != _toAssetRowId;
    }
    return _categoryRowId != null && _assetRowId != null;
  }

  Future<void> _submit() async {
    final amount = int.parse(_amountCtrl.text.replaceAll(',', ''));
    final isoDate =
        '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final dateStr = '${isoDate}T00:00:00';
    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    final merchant = _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim();
    final payment = _paymentCtrl.text.trim().isEmpty ? null : _paymentCtrl.text.trim();

    if (_type == 'TRANSFER') {
      setState(() => _submitting = true);
      try {
        final fee = int.tryParse(_feeCtrl.text.replaceAll(',', ''));
        final aRepo = await ref.read(assetRepositoryProvider.future);
        await aRepo.createTransfer(
          fromAssetRowId: _assetRowId!,
          toAssetRowId: _toAssetRowId!,
          amount: amount,
          fee: fee,
          description: desc,
          transferDate: isoDate,
        );
        ref.invalidate(assetsProvider);
        ref.invalidate(monthExpensesProvider(
            (year: _date.year, month: _date.month)));
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이체가 완료되었습니다')),
        );
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('실패: ${e.message}')),
        );
      } finally {
        if (mounted) setState(() => _submitting = false);
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          categoryRowId: _categoryRowId!,
          assetRowId: _assetRowId!,
          expenseType: _type,
          amount: amount,
          expenseDate: dateStr,
          description: desc,
          merchant: merchant,
          paymentMethod: payment,
        );
      } else {
        await repo.create(
          categoryRowId: _categoryRowId!,
          assetRowId: _assetRowId!,
          expenseType: _type,
          amount: amount,
          expenseDate: dateStr,
          description: desc,
          merchant: merchant,
          paymentMethod: payment,
        );
      }
      // 프리셋으로 채운 뒤 일반 저장한 경우 useCount/lastUsedAt 갱신.
      if (!_isEdit && _appliedPresetId != null) {
        try {
          final pRepo = await ref.read(presetRepositoryProvider.future);
          await pRepo.touch(_appliedPresetId!);
          ref.invalidate(presetListProvider);
        } catch (_) {/* touch 실패는 본 거래 저장에 영향 없음 */}
      }
      // 원래 거래의 월 + 새 월 모두 invalidate (날짜 변경 가능성)
      if (_isEdit && widget.edit!.expenseDate != null) {
        final orig = parseIsoDate(widget.edit!.expenseDate!.substring(0, 10));
        if (orig.year != _date.year || orig.month != _date.month) {
          ref.invalidate(monthExpensesProvider(
              (year: orig.year, month: orig.month)));
        }
      }
      ref.invalidate(monthExpensesProvider(
          (year: _date.year, month: _date.month)));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '거래가 수정되었습니다' : '거래가 추가되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final t = context.tokens;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('거래 삭제'),
        content: const Text('이 거래를 삭제하시겠습니까? 연결된 자산 잔액이 함께 조정됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: t.statusDanger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      await repo.delete(widget.edit!.rowId);
      if (widget.edit!.expenseDate != null) {
        final orig = parseIsoDate(widget.edit!.expenseDate!.substring(0, 10));
        ref.invalidate(monthExpensesProvider(
            (year: orig.year, month: orig.month)));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거래가 삭제되었습니다')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);

    final presetsAsync = _isEdit
        ? const AsyncValue<List<ExpenseTemplate>>.data(<ExpenseTemplate>[])
        : ref.watch(presetListProvider);

    final amountInt =
        int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    final amountColor = _type == 'EXPENSE'
        ? t.statusDangerFg
        : (_type == 'INCOME' ? t.fgBrand : t.fgPrimary);
    final amountPrefix = _type == 'EXPENSE'
        ? '−'
        : (_type == 'INCOME' ? '+' : '');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: t.borderDefault,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
                PSpace.x16, PSpace.x12, PSpace.x8, PSpace.x4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? '거래 편집' : '내역 추가',
                    style: PTypo.h3.copyWith(
                        color: t.fgPrimary, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: Icon(LucideIcons.x, color: t.fgTertiary, size: 20),
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x16, 0, PSpace.x16, PSpace.x16),
              children: [
                if (!_isEdit)
                  presetsAsync.maybeWhen(
                    data: (presets) => presets.isEmpty
                        ? const SizedBox.shrink()
                        : _PresetStrip(
                            presets: presets,
                            appliedId: _appliedPresetId,
                            onTap: _applyPreset,
                            tokens: t,
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                if (!_isEdit && (presetsAsync.value?.isNotEmpty ?? false))
                  const SizedBox(height: PSpace.x12),

                _TypeSegment(
                  value: _type,
                  onChanged: _isEdit
                      ? (_) {} // 편집 모드 — 타입 변경 막음
                      : (v) => setState(() => _type = v),
                  tokens: t,
                  allowTransfer: !_isEdit,
                  lockedToValue: _isEdit ? _type : null,
                ),
                const SizedBox(height: PSpace.x20),

                // 큰 금액 디스플레이 (front 와 동일)
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      PSpace.x4, PSpace.x16, PSpace.x4, PSpace.x16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: t.borderSubtle),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('금액',
                              style: PTypo.caption.copyWith(
                                  color: t.fgTertiary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6)),
                          if (_amountLocked) ...[
                            const SizedBox(width: 6),
                            Icon(LucideIcons.lock,
                                size: 11, color: t.fgTertiary),
                            const SizedBox(width: 3),
                            Text('프리셋 잠금',
                                style: PTypo.caption
                                    .copyWith(color: t.fgTertiary)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                            text:
                                '$amountPrefix${krw(amountInt)}',
                            style: TextStyle(
                              color: amountColor,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.08,
                              fontFamily: 'monospace',
                            ),
                          ),
                          TextSpan(
                            text: '원',
                            style: TextStyle(
                              color: t.fgTertiary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        enabled: !_amountLocked,
                        textAlign: TextAlign.center,
                        style: PTypo.body.copyWith(
                            color: t.fgPrimary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          hintText: '0',
                          isDense: true,
                          filled: true,
                          fillColor: t.bgSurface,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: PSpace.x20),

                if (_type != 'TRANSFER') ...[
                  _SectionLabel('카테고리'),
                  const SizedBox(height: PSpace.x8),
                  categoriesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('카테고리 로드 실패: $e',
                        style: PTypo.caption
                            .copyWith(color: t.statusDanger)),
                    data: (categories) {
                      if (categories.isEmpty) {
                        return Text('등록된 카테고리가 없습니다',
                            style: PTypo.caption
                                .copyWith(color: t.fgTertiary));
                      }
                      // 부모 카테고리만 (parentRowId == null) 또는 전체 — 부모 우선
                      final parents = categories
                          .where((c) =>
                              (c.parentRowId == null) ||
                              (c.parentRowId == 0))
                          .toList();
                      final list = parents.isNotEmpty ? parents : categories;
                      return GridView.count(
                        crossAxisCount: 5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.85,
                        children: [
                          for (final c in list)
                            _CategoryGridItem(
                              category: c,
                              selected: _categoryRowId == c.rowId,
                              onTap: () => setState(() {
                                _categoryRowId = c.rowId;
                                _appliedPresetId = null;
                              }),
                              tokens: t,
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: PSpace.x16),
                ],

          _Label(_type == 'TRANSFER' ? '보낼 자산' : '자산'),
          const SizedBox(height: PSpace.x8),
          assetsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('자산 로드 실패: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (assets) => Wrap(
              spacing: PSpace.x8,
              runSpacing: PSpace.x8,
              children: [
                for (final a in assets)
                  _Chip(
                    label: a.assetName,
                    selected: _assetRowId == a.rowId,
                    onTap: () => setState(() => _assetRowId = a.rowId),
                    tokens: t,
                  ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x16),

          if (_type == 'TRANSFER') ...[
            _Label('받을 자산'),
            const SizedBox(height: PSpace.x8),
            assetsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (assets) => Wrap(
                spacing: PSpace.x8,
                runSpacing: PSpace.x8,
                children: [
                  for (final a in assets)
                    _Chip(
                      label: a.assetName,
                      selected: _toAssetRowId == a.rowId,
                      onTap: () => setState(() => _toAssetRowId = a.rowId),
                      tokens: t,
                    ),
                ],
              ),
            ),
            if (_assetRowId != null && _assetRowId == _toAssetRowId)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('보낼/받을 자산은 달라야 합니다',
                    style: PTypo.caption.copyWith(color: t.statusDanger)),
              ),
            const SizedBox(height: PSpace.x16),

            _Label('수수료 (선택)'),
            const SizedBox(height: PSpace.x4),
            TextField(
              controller: _feeCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: '0'),
            ),
            const SizedBox(height: PSpace.x16),
          ],

          _Label('날짜'),
          const SizedBox(height: PSpace.x4),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030, 12, 31),
              );
              if (picked != null) setState(() => _date = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: t.bgMuted,
                borderRadius: PRadius.brMd,
                border: Border.all(color: t.borderDefault),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendar, size: 18, color: t.fgSecondary),
                  const SizedBox(width: PSpace.x8),
                  Text(
                      '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                      style: PTypo.body.copyWith(color: t.fgPrimary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: PSpace.x16),

          if (_type != 'TRANSFER') ...[
            _Label('가맹점 (선택)'),
            const SizedBox(height: PSpace.x4),
            TextField(
              controller: _merchantCtrl,
              decoration: const InputDecoration(hintText: '예: 스타벅스'),
            ),
            const SizedBox(height: PSpace.x12),

            _Label('결제 수단 (선택)'),
            const SizedBox(height: PSpace.x4),
            TextField(
              controller: _paymentCtrl,
              decoration: const InputDecoration(hintText: '예: 신용카드, 현금'),
            ),
            const SizedBox(height: PSpace.x12),
          ],

                _Label('메모 (선택)'),
                const SizedBox(height: PSpace.x4),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: '예: 점심, 회식 등',
                    filled: true,
                    fillColor: t.bgSurface,
                  ),
                ),
                const SizedBox(height: PSpace.x16),
              ],
            ),
          ),
          // Footer — 삭제 (편집 시) + 취소 + 저장/추가
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x20, vertical: PSpace.x12),
            color: t.bgSurface,
            child: Row(
              children: [
                if (_isEdit)
                  TextButton.icon(
                    onPressed: _submitting ? null : _confirmDelete,
                    icon: Icon(LucideIcons.trash2,
                        size: 14, color: t.statusDangerFg),
                    label: Text('삭제',
                        style: TextStyle(color: t.statusDangerFg)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: _submitting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? '저장' : '추가'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(text, style: PTypo.caption.copyWith(color: t.fgSecondary));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(text,
        style: PTypo.caption.copyWith(
            color: t.fgTertiary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6));
  }
}

class _CategoryGridItem extends StatelessWidget {
  const _CategoryGridItem({
    required this.category,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });
  final dynamic category; // ExpenseCategory shape — duck-typed to avoid extra import
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final fg = parseColor((category.color as String?), fallback: tokens.fgBrand);
    final iconData = lucideByName((category.icon as String?) ?? 'tag');
    final name = (category.categoryName as String?) ?? '';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : Colors.transparent,
          border: Border.all(
            color:
                selected ? tokens.borderBrand : tokens.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(iconData, size: 18, color: fg),
            ),
            const SizedBox(height: 4),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: PTypo.caption.copyWith(
                    color: selected
                        ? tokens.fgBrandStrong
                        : tokens.fgSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 10.5)),
          ],
        ),
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  const _TypeSegment(
      {required this.value,
      required this.onChanged,
      required this.tokens,
      this.allowTransfer = true,
      this.lockedToValue});
  final String value;
  final ValueChanged<String> onChanged;
  final PorestTokens tokens;
  final bool allowTransfer;

  /// 편집 모드 — 이 값 외 다른 옵션은 비활성(disabled).
  final String? lockedToValue;

  static const _baseOpts = [
    ('EXPENSE', '지출', Color(0xFFB85458)),
    ('INCOME', '수입', null),
    ('TRANSFER', '이체', null),
  ];

  @override
  Widget build(BuildContext context) {
    final opts = allowTransfer
        ? _baseOpts
        : _baseOpts.where((o) => o.$1 != 'TRANSFER').toList();
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
          color: tokens.bgMuted, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          for (final o in opts)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (lockedToValue != null && o.$1 != lockedToValue) return;
                  onChanged(o.$1);
                },
                child: Opacity(
                  opacity: (lockedToValue != null && o.$1 != lockedToValue)
                      ? 0.4
                      : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: o.$1 == value
                          ? tokens.bgSurface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: o.$1 == value
                          ? [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1)),
                            ]
                          : null,
                    ),
                    child: Text(o.$2,
                        textAlign: TextAlign.center,
                        style: PTypo.bodySm.copyWith(
                          color: o.$1 == value
                              ? (o.$1 == 'EXPENSE'
                                  ? tokens.statusDangerFg
                                  : (o.$1 == 'INCOME'
                                      ? tokens.fgBrand
                                      : tokens.fgPrimary))
                              : tokens.fgSecondary,
                          fontWeight: o.$1 == value
                              ? FontWeight.w700
                              : FontWeight.w500,
                        )),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PresetStrip extends StatelessWidget {
  const _PresetStrip(
      {required this.presets,
      required this.appliedId,
      required this.onTap,
      required this.tokens});
  final List<ExpenseTemplate> presets;
  final int? appliedId;
  final ValueChanged<ExpenseTemplate> onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: PSpace.x8),
        itemBuilder: (_, i) {
          final p = presets[i];
          final selected = p.rowId == appliedId;
          return GestureDetector(
            onTap: () => onTap(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? tokens.bgBrand : tokens.bgMuted,
                borderRadius: PRadius.brPill,
                border: Border.all(
                    color:
                        selected ? tokens.borderBrand : tokens.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.zap,
                      size: 11,
                      color: selected ? tokens.fgOnBrand : tokens.fgSecondary),
                  const SizedBox(width: 4),
                  Text(p.templateName,
                      style: PTypo.caption.copyWith(
                          color: selected
                              ? tokens.fgOnBrand
                              : tokens.fgSecondary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.tokens});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color: selected ? tokens.borderBrand : tokens.borderDefault,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: PRadius.brMd,
        ),
        child: Text(label,
            style: PTypo.bodySm.copyWith(
                color: selected ? tokens.fgPrimary : tokens.fgSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
      ),
    );
  }
}
