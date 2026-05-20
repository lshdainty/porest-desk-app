import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/chart_palette.dart';
import '../../../core/format/color_parse.dart';
import '../../../core/format/date.dart';
import '../../../core/format/krw.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/icons/lucide_icon_map.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_category_tile.dart';
import '../../../shared/widgets/p_checkbox.dart';
import '../../../shared/widgets/p_date_input.dart';
import '../../../shared/widgets/p_modal.dart';
import '../../../shared/widgets/p_progress.dart';
import '../../../shared/widgets/p_section_label.dart';
import '../../../shared/widgets/p_select.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_text_input.dart';
import '../../../shared/widgets/p_toggle.dart';
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
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? '내역 추가' : '거래 편집',
    contentBuilder: (ctx, scrollCtrl) => _AddTxBody(
      defaultDate: defaultDate,
      edit: edit,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit != null ? '저장' : '추가',
    ),
  ).whenComplete(controller.dispose);
}

class _AddTxBody extends ConsumerStatefulWidget {
  const _AddTxBody({
    this.defaultDate,
    this.edit,
    required this.scrollController,
    required this.controller,
  });
  final String? defaultDate;
  final Expense? edit;
  final ScrollController scrollController;
  final PSheetController controller;

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
    widget.controller.onSubmit = _submit;
    if (widget.edit != null) widget.controller.onDelete = _confirmDelete;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _syncController());
  }

  void _syncController() {
    widget.controller.setCanSubmit(_canSubmit);
    widget.controller.setSubmitting(_submitting);
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
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
      _setSubmitting(true);
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
        showPSnackBar(context, '이체가 완료되었습니다', severity: PSnackSeverity.success);
      } on ApiException catch (e) {
        if (!mounted) return;
        showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
      } finally {
        if (mounted) _setSubmitting(false);
      }
      return;
    }

    _setSubmitting(true);
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
      showPSnackBar(context, _isEdit ? '거래가 수정되었습니다' : '거래가 추가되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showPConfirmDialog(
      context,
      title: '거래 삭제',
      message: '이 거래를 삭제하시겠습니까? 연결된 자산 잔액이 함께 조정됩니다.',
      confirmLabel: '삭제',
      destructive: true,
    );
    if (!ok || !mounted) return;
    _setSubmitting(true);
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
      showPSnackBar(context, '거래가 삭제되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(context, '삭제 실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) _setSubmitting(false);
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
        ? t.fgExpense
        : (_type == 'INCOME' ? t.fgIncome : t.fgTransfer);
    final amountPrefix = _type == 'EXPENSE'
        ? '−'
        : (_type == 'INCOME' ? '+' : '');

    // controller 와 매 build 마다 동기화 (setState 위치 무관).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
                PToggleGroupSingle<String>(
                  expanded: true,
                  visual: PToggleGroupVisual.solid,
                  value: _type,
                  onChanged: _isEdit
                      ? (_) {}
                      : (v) => setState(() => _type = v),
                  items: [
                    PToggleGroupItem(
                      value: 'EXPENSE',
                      label: '지출',
                      disabled: _isEdit && _type != 'EXPENSE',
                    ),
                    PToggleGroupItem(
                      value: 'INCOME',
                      label: '수입',
                      disabled: _isEdit && _type != 'INCOME',
                    ),
                    if (!_isEdit || _type == 'TRANSFER')
                      PToggleGroupItem(
                        value: 'TRANSFER',
                        label: '이체',
                        disabled: _isEdit && _type != 'TRANSFER',
                      ),
                  ],
                ),
                const SizedBox(height: PSpace.x12),

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
                    Expanded(child: PSectionLabel('금액')),
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
                PTextInput(
                  controller: _amountCtrl,
                  numbersOnly: true,
                  enabled: !_amountLocked,
                  placeholder: '0',
                  prefixText: amountInt > 0 ? amountPrefix : null,
                  suffixText: '원',
                  style: PTypo.h4.copyWith(
                      color: amountColor,
                      fontWeight: PFontWeight.bold),
                  onChanged: (_) {
                    setState(() {});
                    _syncController();
                  },
                ),
                const SizedBox(height: PSpace.x16),

                if (_type != 'TRANSFER') ...[
                  PSectionLabel('카테고리', variant: PSectionLabelVariant.eyebrow),
                  const SizedBox(height: PSpace.x8),
                  categoriesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: PCircularProgressIndicator()),
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
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const gap = 6.0;
                              const columns = 5;
                              final cellWidth = (constraints.maxWidth -
                                      gap * (columns - 1)) /
                                  columns;
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: [
                                  for (final c in topCategories)
                                    SizedBox(
                                      width: cellWidth,
                                      child: PCategoryTile(
                                        name: c.categoryName,
                                        color: resolveChartColor(
                                            context,
                                            c.color,
                                            fallback: t.fgBrand),
                                        icon: lucideByName(c.icon ?? 'tag'),
                                        active: selectedParentId == c.rowId,
                                        onTap: () => setState(() {
                                          final firstChild =
                                              childrenByParent[c.rowId]?.first;
                                          _categoryRowId = firstChild != null
                                              ? firstChild.rowId
                                              : c.rowId;
                                          _appliedPresetId = null;
                                        }),
                                      ),
                                    ),
                                ],
                              );
                            },
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
                  const SizedBox(height: PSpace.x12),
                ],

                if (_type != 'TRANSFER') ...[
                  // 거래처
                  PSectionLabel(_type == 'INCOME' ? '수입처' : '거래처'),
                  const SizedBox(height: PSpace.x4),
                  PTextInput(
                    controller: _merchantCtrl,
                    placeholder:
                        _type == 'INCOME' ? '예: (주)포레스트' : '예: 스타벅스 강남점',
                  ),
                  const SizedBox(height: PSpace.x12),

                  // 결제 수단 (Select)
                  PSectionLabel(_type == 'INCOME' ? '수입 방식' : '결제 수단'),
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
                  PSectionLabel(_type == 'INCOME' ? '입금 계좌' : '계좌·카드'),
                  const SizedBox(height: PSpace.x4),
                  assetsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: PCircularProgressIndicator()),
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
                      // Web AddTxSheet 정합 — '선택 안 함' 첫 항목으로 reset 가능.
                      // sentinel value -1 → null 변환 (자산 rowId 는 양수).
                      return _SelectField<int>(
                        value: _assetRowId,
                        hint: '선택 안 함',
                        items: [
                          const _SelectOption<int>(-1, '선택 안 함'),
                          for (final a in filtered)
                            _SelectOption<int>(
                              a.rowId,
                              a.institution != null
                                  ? '${a.institution} · ${a.assetName}'
                                  : a.assetName,
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          _assetRowId = v == -1 ? null : v;
                          _appliedPresetId = null;
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: PSpace.x12),
                ] else ...[
                  // 이체 — 출금/입금/수수료
                  PSectionLabel('출금 계좌'),
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
                  PSectionLabel('입금 계좌'),
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
                  PSectionLabel('수수료 (선택)'),
                  const SizedBox(height: PSpace.x4),
                  PTextInput(
                    controller: _feeCtrl,
                    numbersOnly: true,
                    placeholder: '0',
                  ),
                  const SizedBox(height: PSpace.x12),
                ],

                // 날짜·시간
                PSectionLabel(_type == 'TRANSFER' ? '날짜' : '날짜·시간'),
                const SizedBox(height: PSpace.x4),
                _type == 'TRANSFER'
                    ? PDateInput(
                        value: _date,
                        onChanged: (d) {
                          if (d != null) setState(() => _date = d);
                        },
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030, 12, 31),
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: PDateInput(
                              value: _date,
                              onChanged: (d) {
                                if (d != null) setState(() => _date = d);
                              },
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030, 12, 31),
                            ),
                          ),
                          const SizedBox(width: PSpace.x8),
                          SizedBox(
                            width: 116,
                            child: PTimeInput(
                              value: _time,
                              onChanged: (tm) {
                                if (tm != null) setState(() => _time = tm);
                              },
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: PSpace.x16),

                PSectionLabel('메모'),
                const SizedBox(height: PSpace.x4),
                PTextInput(
                  controller: _descCtrl,
                  maxLines: 2,
                  placeholder: '예: 점심, 회식 등',
                ),
                const SizedBox(height: PSpace.x16),
              ],
            );
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
    return PSelect<T>(
      value: items.any((i) => i.value == value) ? value : null,
      placeholder: hint,
      onChanged: onChanged,
      items: [
        for (final opt in items)
          PSelectItem<T>(value: opt.value, label: opt.label),
      ],
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
                const PBadge(
                    label: '적용됨', variant: PBadgeVariant.softBrand),
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
              separatorBuilder: (_, _) => const SizedBox(width: 6),
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
        resolveChartColor(context, category?.color, fallback: tokens.fgBrand);
    final iconData = lucideByName(category?.icon, fallback: LucideIcons.tag);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: active ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
              color: active ? tokens.borderBrand : tokens.borderSubtle),
          borderRadius: PRadius.brFull,
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
        borderRadius: PRadius.brFull,
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
      showPSnackBar(context, '저장 실패: ${e.message}', severity: PSnackSeverity.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PFormAlertDialog(
      title: '프리셋으로 저장',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PTextInput(
            controller: _nameCtrl,
            autofocus: true,
            placeholder: '예: 점심 도시락',
          ),
          const SizedBox(height: PSpace.x12),
          InkWell(
            onTap: () => setState(() => _lockAmount = !_lockAmount),
            borderRadius: PRadius.brSm,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  PCheckbox(
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
        PButton(
          label: '취소',
          variant: PButtonVariant.ghost,
          onPressed: _submitting ? null : Navigator.of(context).pop,
        ),
        PButton(
          label: '저장',
          loading: _submitting,
          onPressed:
              (_submitting || _nameCtrl.text.trim().isEmpty) ? null : _submit,
        ),
      ],
    );
  }
}

