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
import '../../../shared/widgets/p_category_tile.dart';
import '../../asset/application/asset_providers.dart';
import '../../preset/application/preset_providers.dart';
import '../../preset/domain/expense_template.dart';
import '../application/expense_providers.dart';
import '../domain/expense.dart';
import '../domain/expense_category.dart';

const _paymentMethods = [
  ('CASH', '현금'),
  ('CARD', '카드'),
  ('TRANSFER', '계좌이체'),
  ('OTHER', '기타'),
];

/// 결제 수단별 허용 자산 타입. null = 전체 허용.
const Map<String, List<String>?> _paymentAssetTypes = {
  'CASH': ['CASH'],
  'CARD': ['CREDIT_CARD', 'CHECK_CARD'],
  'TRANSFER': ['BANK_ACCOUNT', 'SAVINGS'],
  'OTHER': null,
};

String _formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
      borderRadius: BorderRadius.vertical(top: Radius.circular(PRadius.xl2)),
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
  late final TextEditingController _feeCtrl;
  String _paymentMethod = ''; // '' | CASH | CARD | TRANSFER | OTHER
  int? _categoryRowId;
  int? _assetRowId; // EXPENSE/INCOME 자산, TRANSFER 의 출금 자산
  int? _toAssetRowId; // TRANSFER 입금 자산
  late DateTime _date;
  TimeOfDay _time = TimeOfDay.now();
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
    _feeCtrl = TextEditingController();
    _paymentMethod = e?.paymentMethod ?? '';
    _categoryRowId = e?.categoryRowId;
    _assetRowId = e?.assetRowId;
    if (e?.expenseDate != null) {
      _date = parseIsoDate(e!.expenseDate!.substring(0, 10));
      // 시간 추출 (T 또는 공백 뒤 HH:mm)
      final raw = e.expenseDate!;
      final m = RegExp(r'[T ](\d{2}):(\d{2})').firstMatch(raw);
      if (m != null) {
        _time = TimeOfDay(
            hour: int.parse(m.group(1)!), minute: int.parse(m.group(2)!));
      }
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
    _feeCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(ExpenseTemplate p) {
    final locked = (p.lockAmount ?? 'N') == 'Y';
    setState(() {
      _appliedPresetId = p.rowId;
      _type = p.expenseType;
      // 웹과 동일: lockAmount === 'Y' 일 때만 금액 채움, 아니면 비워둠
      _amountCtrl.text = locked ? p.amount.toString() : '';
      _categoryRowId = p.categoryRowId;
      _assetRowId = p.assetRowId;
      _descCtrl.text = p.description ?? '';
      _merchantCtrl.text = p.merchant ?? '';
      _paymentMethod = p.paymentMethod ?? '';
      _amountLocked = locked;
    });
  }

  void _clearPresetMark() {
    if (_appliedPresetId == null) return;
    setState(() => _appliedPresetId = null);
  }

  Future<void> _showSavePresetDialog() async {
    final amount = int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
    if (amount <= 0 || _categoryRowId == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _SavePresetDialog(
        seedExpenseType: _type == 'TRANSFER' ? 'EXPENSE' : _type,
        seedAmount: amount,
        seedCategoryRowId: _categoryRowId!,
        seedAssetRowId: _assetRowId,
        seedMerchant: _merchantCtrl.text.trim(),
        seedDescription: _descCtrl.text.trim(),
        seedPaymentMethod: _paymentMethod,
      ),
    );
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
    final dateStr = '${isoDate}T${_formatTime(_time)}:00';
    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    final merchant = _merchantCtrl.text.trim().isEmpty ? null : _merchantCtrl.text.trim();
    final payment = _paymentMethod.isEmpty ? null : _paymentMethod;

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
              borderRadius: PRadius.brXs2,
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
                        color: t.fgPrimary, fontWeight: PFontWeight.heavy),
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

                if (!_isEdit && _type != 'TRANSFER') ...[
                  _PresetSection(
                    presets: presetsAsync.value ?? const [],
                    categories: categoriesAsync.value ?? const [],
                    appliedId: _appliedPresetId,
                    canSave: amountInt > 0 && _categoryRowId != null,
                    onTap: _applyPreset,
                    onSave: _showSavePresetDialog,
                    onClear: _clearPresetMark,
                    tokens: t,
                  ),
                  const SizedBox(height: PSpace.x20),
                ],

                // 금액 — 다른 필드와 동일한 단순 label + input
                Row(
                  children: [
                    Expanded(child: _Label('금액')),
                    if (_amountLocked) ...[
                      Icon(LucideIcons.lock, size: 11, color: t.fgTertiary),
                      const SizedBox(width: 3),
                      Text('프리셋 잠금',
                          style:
                              PTypo.caption.copyWith(color: t.fgTertiary)),
                    ],
                  ],
                ),
                const SizedBox(height: PSpace.x4),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !_amountLocked,
                  style: PTypo.h4.copyWith(
                      color: amountColor,
                      fontWeight: PFontWeight.bold,
                      fontFamily: 'monospace'),
                  decoration: InputDecoration(
                    hintText: '0',
                    filled: true,
                    fillColor: t.bgSurface,
                    prefixText:
                        amountInt > 0 ? amountPrefix : null,
                    suffixText: '원',
                    suffixStyle:
                        PTypo.bodySm.copyWith(color: t.fgTertiary),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: PSpace.x16),

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
                      // 현재 type 의 최상위 카테고리만 그리드로 노출
                      final topCategories = categories
                          .where((c) =>
                              c.expenseType == _type &&
                              (c.parentRowId == null || c.parentRowId == 0))
                          .toList()
                        ..sort((a, b) =>
                            (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
                      if (topCategories.isEmpty) {
                        return Text('이 타입에 해당하는 카테고리가 없습니다',
                            style: PTypo.caption
                                .copyWith(color: t.fgTertiary));
                      }

                      // 자식 카테고리 맵
                      final childrenByParent = <int, List<dynamic>>{};
                      for (final c in categories) {
                        if (c.parentRowId == null ||
                            c.parentRowId == 0 ||
                            c.expenseType != _type) {
                          continue;
                        }
                        childrenByParent
                            .putIfAbsent(c.parentRowId!, () => [])
                            .add(c);
                      }
                      for (final list in childrenByParent.values) {
                        list.sort((a, b) =>
                            ((a.sortOrder ?? 0) as int)
                                .compareTo((b.sortOrder ?? 0) as int));
                      }

                      // 선택된 카테고리의 부모 ID (자식이면 그 부모, 부모면 자기 자신)
                      final selectedCat = _categoryRowId == null
                          ? null
                          : categories
                              .where((c) => c.rowId == _categoryRowId)
                              .firstOrNull;
                      final selectedParentId = selectedCat == null
                          ? null
                          : (selectedCat.parentRowId == null ||
                                  selectedCat.parentRowId == 0
                              ? selectedCat.rowId
                              : selectedCat.parentRowId);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.count(
                            crossAxisCount: 5,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 0.85,
                            children: [
                              for (final c in topCategories)
                                PCategoryTile(
                                  name: (c.categoryName as String?) ?? '',
                                  color: parseColor(
                                      c.color as String?,
                                      fallback: t.fgBrand),
                                  icon: lucideByName(
                                      (c.icon as String?) ?? 'tag'),
                                  active: selectedParentId == c.rowId,
                                  onTap: () => setState(() {
                                    // 자식이 있으면 첫 자식, 없으면 자기 자신
                                    final firstChild =
                                        childrenByParent[c.rowId]?.first;
                                    _categoryRowId = firstChild != null
                                        ? firstChild.rowId as int
                                        : c.rowId;
                                    _appliedPresetId = null;
                                  }),
                                ),
                            ],
                          ),
                          // 세부 카테고리 Select — 선택된 부모에 자식이 있으면
                          if (selectedParentId != null &&
                              (childrenByParent[selectedParentId]?.isNotEmpty ??
                                  false)) ...[
                            const SizedBox(height: 10),
                            _SelectField<int>(
                              value: _categoryRowId,
                              hint: '세부 카테고리',
                              items: [
                                _SelectOption<int>(
                                  selectedParentId,
                                  '${topCategories.firstWhere((c) => c.rowId == selectedParentId).categoryName} (상위)',
                                ),
                                for (final child
                                    in childrenByParent[selectedParentId]!)
                                  _SelectOption<int>(
                                    child.rowId as int,
                                    child.categoryName as String,
                                  ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _categoryRowId = v),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: PSpace.x16),
                ],

                if (_type != 'TRANSFER') ...[
                  // 거래처
                  _Label(_type == 'INCOME' ? '수입처' : '거래처'),
                  const SizedBox(height: PSpace.x4),
                  TextField(
                    controller: _merchantCtrl,
                    decoration: InputDecoration(
                      hintText: _type == 'INCOME' ? '예: (주)포레스트' : '예: 스타벅스 강남점',
                      filled: true,
                      fillColor: t.bgSurface,
                    ),
                  ),
                  const SizedBox(height: PSpace.x12),

                  // 결제 수단 (Select)
                  _Label(_type == 'INCOME' ? '수입 방식' : '결제 수단'),
                  const SizedBox(height: PSpace.x4),
                  _SelectField<String>(
                    value: _paymentMethod.isEmpty ? null : _paymentMethod,
                    hint: '선택 안 함',
                    items: [
                      const _SelectOption<String>('', '선택 안 함'),
                      for (final pm in _paymentMethods)
                        _SelectOption<String>(pm.$1, pm.$2),
                    ],
                    onChanged: (v) => setState(() {
                      _paymentMethod = v ?? '';
                      _appliedPresetId = null;
                      // 결제 수단 변경 시 현재 자산이 허용되지 않으면 리셋
                      if (_paymentMethod.isNotEmpty && _assetRowId != null) {
                        final allowed = _paymentAssetTypes[_paymentMethod];
                        if (allowed != null) {
                          final assets = assetsAsync.value ?? const [];
                          final cur = assets
                              .where((a) => a.rowId == _assetRowId)
                              .firstOrNull;
                          if (cur != null && !allowed.contains(cur.assetType)) {
                            _assetRowId = null;
                          }
                        }
                      }
                    }),
                  ),
                  const SizedBox(height: PSpace.x12),

                  // 계좌·카드 (Select, payment method 로 필터)
                  _Label(_type == 'INCOME' ? '입금 계좌' : '계좌·카드'),
                  const SizedBox(height: PSpace.x4),
                  assetsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('자산 로드 실패: $e',
                        style: PTypo.caption.copyWith(color: t.statusDanger)),
                    data: (assets) {
                      final allowed = _paymentMethod.isNotEmpty
                          ? _paymentAssetTypes[_paymentMethod]
                          : null;
                      final filtered = allowed == null
                          ? assets
                          : assets
                              .where((a) => allowed.contains(a.assetType))
                              .toList();
                      return _SelectField<int>(
                        value: _assetRowId,
                        hint: '선택 안 함',
                        items: [
                          for (final a in filtered)
                            _SelectOption<int>(
                              a.rowId,
                              a.institution != null
                                  ? '${a.institution} · ${a.assetName}'
                                  : a.assetName,
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          _assetRowId = v;
                          _appliedPresetId = null;
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: PSpace.x12),
                ] else ...[
                  // 이체 — 출금/입금/수수료
                  _Label('출금 계좌'),
                  const SizedBox(height: PSpace.x4),
                  assetsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (assets) => _SelectField<int>(
                      value: _assetRowId,
                      hint: '선택',
                      items: [
                        for (final a in assets)
                          _SelectOption<int>(
                            a.rowId,
                            a.institution != null
                                ? '${a.institution} · ${a.assetName}'
                                : a.assetName,
                          ),
                      ],
                      onChanged: (v) => setState(() => _assetRowId = v),
                    ),
                  ),
                  const SizedBox(height: PSpace.x12),
                  _Label('입금 계좌'),
                  const SizedBox(height: PSpace.x4),
                  assetsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (assets) => _SelectField<int>(
                      value: _toAssetRowId,
                      hint: '선택',
                      items: [
                        for (final a
                            in assets.where((a) => a.rowId != _assetRowId))
                          _SelectOption<int>(
                            a.rowId,
                            a.institution != null
                                ? '${a.institution} · ${a.assetName}'
                                : a.assetName,
                          ),
                      ],
                      onChanged: (v) => setState(() => _toAssetRowId = v),
                    ),
                  ),
                  if (_assetRowId != null && _assetRowId == _toAssetRowId)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('보낼/받을 자산은 달라야 합니다',
                          style: PTypo.caption
                              .copyWith(color: t.statusDanger)),
                    ),
                  const SizedBox(height: PSpace.x12),
                  _Label('수수료 (선택)'),
                  const SizedBox(height: PSpace.x4),
                  TextField(
                    controller: _feeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '0',
                      filled: true,
                      fillColor: t.bgSurface,
                    ),
                  ),
                  const SizedBox(height: PSpace.x12),
                ],

                // 날짜·시간
                _Label(_type == 'TRANSFER' ? '날짜' : '날짜·시간'),
                const SizedBox(height: PSpace.x4),
                _type == 'TRANSFER'
                    ? _DateBox(
                        date: _date,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030, 12, 31),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _DateBox(
                              date: _date,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030, 12, 31),
                                );
                                if (picked != null) {
                                  setState(() => _date = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: PSpace.x8),
                          SizedBox(
                            width: 116,
                            child: _TimeBox(
                              time: _time,
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _time,
                                );
                                if (picked != null) {
                                  setState(() => _time = picked);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: PSpace.x16),

                _Label('메모'),
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

class _SelectOption<T> {
  const _SelectOption(this.value, this.label);
  final T value;
  final String label;
}

class _SelectField<T> extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hint,
  });
  final T? value;
  final List<_SelectOption<T>> items;
  final ValueChanged<T?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DropdownButtonFormField<T>(
      initialValue: items.any((i) => i.value == value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: t.bgSurface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
      ),
      hint: Text(hint,
          style: PTypo.bodySm.copyWith(color: t.fgPlaceholder)),
      icon: Icon(LucideIcons.chevronDown, size: 16, color: t.fgTertiary),
      items: [
        for (final opt in items)
          DropdownMenuItem<T>(
            value: opt.value,
            child: Text(opt.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.bgSurface,
          border: Border.all(color: t.borderDefault),
          borderRadius: PRadius.brMd,
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 16, color: t.fgSecondary),
            const SizedBox(width: 8),
            Text(
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              style: PTypo.bodySm.copyWith(color: t.fgPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.time, required this.onTap});
  final TimeOfDay time;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: PRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.bgSurface,
          border: Border.all(color: t.borderDefault),
          borderRadius: PRadius.brMd,
        ),
        child: Row(
          children: [
            Icon(LucideIcons.clock, size: 16, color: t.fgSecondary),
            const SizedBox(width: 8),
            Text(_formatTime(time),
                style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
          ],
        ),
      ),
    );
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
            fontWeight: PFontWeight.semi,
            letterSpacing: 0.6));
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
          color: tokens.bgMuted, borderRadius: PRadius.brTile),
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
                      borderRadius: PRadius.brMd,
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
                              ? PFontWeight.bold
                              : PFontWeight.medium,
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

/// 프리셋 섹션 — 헤더 (라벨 + 적용됨 뱃지 + 저장 버튼) + 칩 strip + 적용 배너.
/// 웹 `AddTxSheet` 의 "프리셋 불러오기" 영역 1:1 미러.
class _PresetSection extends StatelessWidget {
  const _PresetSection({
    required this.presets,
    required this.categories,
    required this.appliedId,
    required this.canSave,
    required this.onTap,
    required this.onSave,
    required this.onClear,
    required this.tokens,
  });

  final List<ExpenseTemplate> presets;
  final List<ExpenseCategory> categories;
  final int? appliedId;
  final bool canSave;
  final ValueChanged<ExpenseTemplate> onTap;
  final VoidCallback onSave;
  final VoidCallback onClear;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    // 사용 빈도 desc 로 8개 (웹과 동일).
    final sorted = [...presets]
      ..sort((a, b) => (b.useCount ?? 0).compareTo(a.useCount ?? 0));
    final top = sorted.take(8).toList();
    final hasMore = presets.length > top.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: PSpace.x8),
          child: Row(
            children: [
              Icon(LucideIcons.bookmark,
                  size: 13, color: tokens.fgTertiary),
              const SizedBox(width: 6),
              Text(
                '프리셋 불러오기',
                style: TextStyle(
                  fontSize: PFontSize.micro,
                  color: tokens.fgTertiary,
                  fontWeight: PFontWeight.semi,
                  letterSpacing: 0.44, // micro size × wide tracking
                ),
              ),
              if (appliedId != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tokens.bgBrandSubtle,
                    borderRadius: PRadius.brXs,
                  ),
                  child: Text(
                    '적용됨',
                    style: TextStyle(
                      fontSize: PFontSize.micro,
                      color: tokens.fgBrandStrong,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: canSave ? onSave : null,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.plus,
                        size: 12,
                        color: canSave
                            ? tokens.fgBrandStrong
                            : tokens.fgTertiary),
                    const SizedBox(width: 3),
                    Text(
                      '현재 입력값 저장',
                      style: TextStyle(
                        fontSize: PFontSize.caption,
                        color: canSave
                            ? tokens.fgBrandStrong
                            : tokens.fgTertiary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Strip
        if (top.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: top.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                if (i == top.length) return _MorePresetsHint(tokens: tokens);
                final p = top[i];
                final active = p.rowId == appliedId;
                final showAmount =
                    (p.lockAmount ?? 'N') == 'Y' && p.amount > 0;
                final cat = categories.byRowId(p.categoryRowId);
                return _PresetChip(
                  preset: p,
                  category: cat,
                  active: active,
                  showAmount: showAmount,
                  onTap: () => onTap(p),
                  tokens: tokens,
                );
              },
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgMuted,
              border: Border.all(color: tokens.borderDefault),
              borderRadius: PRadius.brSm,
            ),
            child: Text(
              '저장된 프리셋이 없어요. 자주 쓰는 내역을 입력 후 “현재 입력값 저장”을 눌러보세요.',
              style: TextStyle(
                fontSize: PFontSize.caption,
                color: tokens.fgTertiary,
              ),
            ),
          ),

        // Active preset banner
        if (appliedId != null) ...[
          const SizedBox(height: PSpace.x8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgBrandSubtle,
              border: Border.all(color: tokens.borderBrand),
              borderRadius: PRadius.brSm,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info,
                    size: 13, color: tokens.fgBrandStrong),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '프리셋 값이 채워졌어요. 금액·내역만 수정해서 저장하세요.',
                    style: TextStyle(
                      fontSize: PFontSize.caption,
                      color: tokens.fgBrandStrong,
                      fontWeight: PFontWeight.semi,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClear,
                  child: Text(
                    '해제',
                    style: TextStyle(
                      fontSize: PFontSize.micro,
                      color: tokens.fgBrandStrong,
                      fontWeight: PFontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.category,
    required this.active,
    required this.showAmount,
    required this.onTap,
    required this.tokens,
  });

  final ExpenseTemplate preset;
  final ExpenseCategory? category;
  final bool active;
  final bool showAmount;
  final VoidCallback onTap;
  final PorestTokens tokens;

  String _shortAmount(int n) {
    if (n >= 10000) return '${(n / 1000).floor()}k';
    return krw(n);
  }

  @override
  Widget build(BuildContext context) {
    final catColor =
        parseColor(category?.color, fallback: tokens.fgBrand);
    final iconData = lucideByName(category?.icon, fallback: LucideIcons.tag);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: active ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
              color: active ? tokens.borderBrand : tokens.borderSubtle),
          borderRadius: PRadius.brPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != null) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: softBg(catColor),
                  borderRadius: PRadius.brSm,
                ),
                alignment: Alignment.center,
                child: Icon(iconData, size: 11, color: catColor),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              preset.templateName,
              style: TextStyle(
                fontSize: PFontSize.bodySm,
                fontWeight:
                    active ? PFontWeight.bold : PFontWeight.semi,
                color:
                    active ? tokens.fgBrandStrong : tokens.fgPrimary,
              ),
            ),
            if (showAmount) ...[
              const SizedBox(width: 7),
              Text(
                _shortAmount(preset.amount),
                style: TextStyle(
                  fontSize: PFontSize.micro,
                  color:
                      active ? tokens.fgBrandStrong : tokens.fgTertiary,
                  fontWeight: PFontWeight.semi,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MorePresetsHint extends StatelessWidget {
  const _MorePresetsHint({required this.tokens});
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(
            color: tokens.borderDefault, style: BorderStyle.solid),
        borderRadius: PRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.moreHorizontal, size: 14, color: tokens.fgTertiary),
          const SizedBox(width: 4),
          Text(
            '설정 → 프리셋 관리',
            style: TextStyle(
              fontSize: PFontSize.caption,
              fontWeight: PFontWeight.semi,
              color: tokens.fgTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 현재 입력값을 프리셋으로 저장. 웹 `SavePresetDialog` 1:1 미러.
class _SavePresetDialog extends ConsumerStatefulWidget {
  const _SavePresetDialog({
    required this.seedExpenseType,
    required this.seedAmount,
    required this.seedCategoryRowId,
    required this.seedAssetRowId,
    required this.seedMerchant,
    required this.seedDescription,
    required this.seedPaymentMethod,
  });

  final String seedExpenseType;
  final int seedAmount;
  final int seedCategoryRowId;
  final int? seedAssetRowId;
  final String seedMerchant;
  final String seedDescription;
  final String seedPaymentMethod;

  @override
  ConsumerState<_SavePresetDialog> createState() =>
      _SavePresetDialogState();
}

class _SavePresetDialogState extends ConsumerState<_SavePresetDialog> {
  late final TextEditingController _nameCtrl;
  bool _lockAmount = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.seedMerchant);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _submitting) return;
    if (widget.seedAssetRowId == null) return;
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      await repo.create(
        templateName: name,
        categoryRowId: widget.seedCategoryRowId,
        assetRowId: widget.seedAssetRowId!,
        expenseType: widget.seedExpenseType,
        amount: _lockAmount ? widget.seedAmount : 0,
        description:
            widget.seedDescription.isEmpty ? null : widget.seedDescription,
        merchant: widget.seedMerchant.isEmpty ? null : widget.seedMerchant,
        paymentMethod:
            widget.seedPaymentMethod.isEmpty ? null : widget.seedPaymentMethod,
        lockAmount: _lockAmount,
      );
      ref.invalidate(presetListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AlertDialog(
      title: Text('프리셋으로 저장',
          style: TextStyle(
              color: t.fgPrimary, fontWeight: PFontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '프리셋 이름',
              hintText: '예: 점심 도시락',
            ),
          ),
          const SizedBox(height: PSpace.x12),
          InkWell(
            onTap: () => setState(() => _lockAmount = !_lockAmount),
            borderRadius: PRadius.brSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: _lockAmount,
                    onChanged: (v) =>
                        setState(() => _lockAmount = v ?? false),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '금액 잠금 — 적용 시 ${krw(widget.seedAmount)}원 자동 채움',
                      style: TextStyle(
                          fontSize: PFontSize.caption,
                          color: t.fgSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : Navigator.of(context).pop,
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed:
              (_submitting || _nameCtrl.text.trim().isEmpty) ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('저장'),
        ),
      ],
    );
  }
}

