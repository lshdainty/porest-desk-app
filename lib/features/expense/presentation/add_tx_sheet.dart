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

String _formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// 거래 추가/편집 시트 (front `AddTxSheet` 미러).
///
/// [edit] 가 주어지면 편집 모드 (PUT /expense/{id}), 아니면 신규 (POST /expense).
/// 성공 시 해당 월 expensesProvider invalidate.
void showAddTxSheet(
  BuildContext context, {
  String? defaultDate,
  Expense? edit,
}) {
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
  late final _TxInputController _input;
  bool _submitting = false;

  /// 프리셋을 통해 폼이 초기화된 경우 해당 프리셋 ID — 저장 성공 후 /touch.
  int? _appliedPresetId;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    DateTime date;
    TimeOfDay time = TimeOfDay.now();
    if (e?.expenseDate != null) {
      date = parseIsoDate(e!.expenseDate!.substring(0, 10));
      // 시간 추출 (T 또는 공백 뒤 HH:mm)
      final raw = e.expenseDate!;
      final m = RegExp(r'[T ](\d{2}):(\d{2})').firstMatch(raw);
      if (m != null) {
        time = TimeOfDay(
          hour: int.parse(m.group(1)!),
          minute: int.parse(m.group(2)!),
        );
      }
    } else if (widget.defaultDate != null) {
      date = parseIsoDate(widget.defaultDate!);
    } else {
      date = DateTime.now();
    }
    _input = _TxInputController(
      type: e?.expenseType ?? 'EXPENSE',
      amount: e == null ? '' : e.amount.toString(),
      memo: e?.description ?? '',
      merchant: e?.merchant ?? '',
      paymentMethod: e?.paymentMethod ?? '',
      categoryRowId: e?.categoryRowId,
      assetRowId: e?.assetRowId,
      date: date,
      time: time,
    );
    widget.controller.onSubmit = _submit;
    if (widget.edit != null) widget.controller.onDelete = _confirmDelete;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncController());
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
    _input.dispose();
    super.dispose();
  }

  void _applyPreset(ExpenseTemplate p) {
    final locked = (p.lockAmount ?? 'N') == 'Y';
    setState(() {
      _appliedPresetId = p.rowId;
      _input.type = p.expenseType;
      // 웹과 동일: lockAmount === 'Y' 일 때만 금액 채움, 아니면 비워둠
      _input.amountCtrl.text = locked ? p.amount.toString() : '';
      _input.categoryRowId = p.categoryRowId;
      _input.assetRowId = p.assetRowId;
      _input.memoCtrl.text = p.description ?? '';
      _input.merchantCtrl.text = p.merchant ?? '';
      _input.paymentMethod = p.paymentMethod ?? '';
      _input.amountLocked = locked;
    });
  }

  void _clearPresetMark() {
    if (_appliedPresetId == null) return;
    setState(() => _appliedPresetId = null);
  }

  Future<void> _showSavePresetDialog() async {
    final amount = _input.amountInt;
    if (amount <= 0 || _input.categoryRowId == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _SavePresetDialog(
        seedExpenseType: _input.type == 'TRANSFER' ? 'EXPENSE' : _input.type,
        seedAmount: amount,
        seedCategoryRowId: _input.categoryRowId!,
        seedAssetRowId: _input.assetRowId,
        seedMerchant: _input.merchantCtrl.text.trim(),
        seedDescription: _input.memoCtrl.text.trim(),
        seedPaymentMethod: _input.paymentMethod,
      ),
    );
  }

  bool get _canSubmit {
    final amount = _input.amountInt;
    if (_submitting || amount <= 0) return false;
    if (_input.type == 'TRANSFER') {
      return _input.assetRowId != null &&
          _input.toAssetRowId != null &&
          _input.assetRowId != _input.toAssetRowId;
    }
    return _input.categoryRowId != null && _input.assetRowId != null;
  }

  Future<void> _submit() async {
    final amount = _input.amountInt;
    final isoDate = _input.isoDate;
    final dateStr = '${isoDate}T${_formatTime(_input.time)}:00';
    final desc = _input.memoOrNull;
    final merchant = _input.merchantOrNull;
    final payment = _input.paymentMethodOrNull;
    final d = _input.date;

    if (_input.type == 'TRANSFER') {
      _setSubmitting(true);
      try {
        final fee = int.tryParse(_input.feeCtrl.text.replaceAll(',', ''));
        final aRepo = await ref.read(assetRepositoryProvider.future);
        await aRepo.createTransfer(
          fromAssetRowId: _input.assetRowId!,
          toAssetRowId: _input.toAssetRowId!,
          amount: amount,
          fee: fee,
          description: desc,
          transferDate: isoDate,
        );
        ref.invalidate(assetsProvider);
        ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
        if (!mounted) return;
        Navigator.of(context).pop();
        showPSnackBar(context, '이체가 완료되었습니다', severity: PSnackSeverity.success);
      } on ApiException catch (e) {
        if (!mounted) return;
        showPSnackBar(
          context,
          '실패: ${e.message}',
          severity: PSnackSeverity.error,
        );
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
          categoryRowId: _input.categoryRowId!,
          assetRowId: _input.assetRowId!,
          expenseType: _input.type,
          amount: amount,
          expenseDate: dateStr,
          description: desc,
          merchant: merchant,
          paymentMethod: payment,
        );
      } else {
        await repo.create(
          categoryRowId: _input.categoryRowId!,
          assetRowId: _input.assetRowId!,
          expenseType: _input.type,
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
        } catch (_) {
          /* touch 실패는 본 거래 저장에 영향 없음 */
        }
      }
      // 원래 거래의 월 + 새 월 모두 invalidate (날짜 변경 가능성)
      if (_isEdit && widget.edit!.expenseDate != null) {
        final orig = parseIsoDate(widget.edit!.expenseDate!.substring(0, 10));
        if (orig.year != d.year || orig.month != d.month) {
          ref.invalidate(
            monthExpensesProvider((year: orig.year, month: orig.month)),
          );
        }
      }
      ref.invalidate(monthExpensesProvider((year: d.year, month: d.month)));
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(
        context,
        _isEdit ? '거래가 수정되었습니다' : '거래가 추가되었습니다',
        severity: PSnackSeverity.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
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
        ref.invalidate(
          monthExpensesProvider((year: orig.year, month: orig.month)),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(context, '거래가 삭제되었습니다', severity: PSnackSeverity.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '삭제 실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final presetsAsync = _isEdit
        ? const AsyncValue<List<ExpenseTemplate>>.data(<ExpenseTemplate>[])
        : ref.watch(presetListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
        _TxInputForm(
          controller: _input,
          onChanged: () => setState(_syncController),
          typeReadOnly: _isEdit,
          typeDisabledFor: _isEdit ? _input.type : null,
          presetSlot: _isEdit
              ? null
              : _PresetSection(
                  presets: presetsAsync.value ?? const [],
                  categories: categoriesAsync.value ?? const [],
                  appliedId: _appliedPresetId,
                  canSave: _input.amountInt > 0 && _input.categoryRowId != null,
                  onTap: _applyPreset,
                  onSave: _showSavePresetDialog,
                  onClear: _clearPresetMark,
                  tokens: t,
                ),
        ),
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
              Icon(LucideIcons.bookmark, size: 13, color: tokens.fgTertiary),
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
                const PBadge(label: '적용됨', variant: PBadgeVariant.softBrand),
              ],
              const Spacer(),
              GestureDetector(
                onTap: canSave ? onSave : null,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.plus,
                      size: 12,
                      color: canSave ? tokens.fgBrandStrong : tokens.fgTertiary,
                    ),
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
                final showAmount = (p.lockAmount ?? 'N') == 'Y' && p.amount > 0;
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.bgBrandSubtle,
              border: Border.all(color: tokens.borderBrand),
              borderRadius: PRadius.brSm,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.info, size: 13, color: tokens.fgBrandStrong),
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
    final catColor = resolveChartColor(
      context,
      category?.color,
      fallback: tokens.fgBrand,
    );
    final iconData = lucideByName(category?.icon, fallback: LucideIcons.tag);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: active ? tokens.bgBrandSubtle : tokens.bgSurface,
          border: Border.all(
            color: active ? tokens.borderBrand : tokens.borderSubtle,
          ),
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
                fontWeight: active ? PFontWeight.bold : PFontWeight.semi,
                color: active ? tokens.fgBrandStrong : tokens.fgPrimary,
              ),
            ),
            if (showAmount) ...[
              const SizedBox(width: 7),
              Text(
                _shortAmount(preset.amount),
                style: TextStyle(
                  fontSize: PFontSize.micro,
                  color: active ? tokens.fgBrandStrong : tokens.fgTertiary,
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
          color: tokens.borderDefault,
          style: BorderStyle.solid,
        ),
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
  ConsumerState<_SavePresetDialog> createState() => _SavePresetDialogState();
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
        description: widget.seedDescription.isEmpty
            ? null
            : widget.seedDescription,
        merchant: widget.seedMerchant.isEmpty ? null : widget.seedMerchant,
        paymentMethod: widget.seedPaymentMethod.isEmpty
            ? null
            : widget.seedPaymentMethod,
        lockAmount: _lockAmount,
      );
      ref.invalidate(presetListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '저장 실패: ${e.message}',
        severity: PSnackSeverity.error,
      );
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
                    onChanged: (v) => setState(() => _lockAmount = v ?? false),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '금액 잠금 — 적용 시 ${krw(widget.seedAmount)}원 자동 채움',
                      style: TextStyle(
                        fontSize: PFontSize.caption,
                        color: t.fgSecondary,
                      ),
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
          onPressed: (_submitting || _nameCtrl.text.trim().isEmpty)
              ? null
              : _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// 거래 입력 (inline) — recurring 과 독립. tx_input_form.dart 해체 후 add_tx 자체 보유.

const _txPaymentMethods = [
  ('CASH', '현금'),
  ('CARD', '카드'),
  ('TRANSFER', '계좌이체'),
  ('OTHER', '기타'),
];

const Map<String, List<String>?> _txPaymentAssetTypes = {
  'CASH': ['CASH'],
  'CARD': ['CREDIT_CARD', 'CHECK_CARD'],
  'TRANSFER': ['BANK_ACCOUNT', 'SAVINGS'],
  'OTHER': null,
};

/// 거래 입력 상태 (지출/수입/이체).
class _TxInputController {
  _TxInputController({
    this.type = 'EXPENSE',
    String amount = '',
    String merchant = '',
    String memo = '',
    this.categoryRowId,
    this.assetRowId,
    this.paymentMethod = '',
    DateTime? date,
    TimeOfDay? time,
  })  : date = date ?? DateTime.now(),
        time = time ?? TimeOfDay.now(),
        amountCtrl = TextEditingController(text: amount),
        merchantCtrl = TextEditingController(text: merchant),
        memoCtrl = TextEditingController(text: memo),
        feeCtrl = TextEditingController();

  final TextEditingController amountCtrl;
  final TextEditingController merchantCtrl;
  final TextEditingController memoCtrl;
  final TextEditingController feeCtrl;

  String type; // EXPENSE / INCOME / TRANSFER
  int? categoryRowId;
  int? assetRowId; // EXPENSE/INCOME 자산, TRANSFER 출금 자산
  int? toAssetRowId; // TRANSFER 입금 자산 (이체 시 폼에서 set)
  String paymentMethod;
  DateTime date;
  TimeOfDay time;
  bool amountLocked = false; // 프리셋 금액 잠금 (applyPreset 에서 set)

  int get amountInt => int.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0;
  String get isoDate =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  String? get merchantOrNull =>
      merchantCtrl.text.trim().isEmpty ? null : merchantCtrl.text.trim();
  String? get memoOrNull =>
      memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim();
  String? get paymentMethodOrNull =>
      paymentMethod.isEmpty ? null : paymentMethod;

  void dispose() {
    amountCtrl.dispose();
    merchantCtrl.dispose();
    memoCtrl.dispose();
    feeCtrl.dispose();
  }
}

/// 거래 입력 폼 (지출/수입/이체) — add_tx_sheet 자체 보유.
class _TxInputForm extends ConsumerWidget {
  const _TxInputForm({
    required this.controller,
    required this.onChanged,
    this.typeReadOnly = false,
    this.typeDisabledFor,
    this.presetSlot,
  });

  final _TxInputController controller;
  final VoidCallback onChanged;
  final bool typeReadOnly;
  final String? typeDisabledFor;
  final Widget? presetSlot;

  void _set(VoidCallback mutate) {
    mutate();
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final c = controller;
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);

    final amountInt = c.amountInt;
    final amountColor = c.type == 'EXPENSE'
        ? t.fgExpense
        : (c.type == 'INCOME' ? t.fgIncome : t.fgTransfer);
    final amountPrefix = c.type == 'EXPENSE'
        ? '−'
        : (c.type == 'INCOME' ? '+' : '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타입 토글
        PToggleGroupSingle<String>(
          expanded: true,
          visual: PToggleGroupVisual.solid,
          value: c.type,
          onChanged: typeReadOnly ? (_) {} : (v) => _set(() => c.type = v),
          items: [
            PToggleGroupItem(
              value: 'EXPENSE',
              label: '지출',
              disabled: typeReadOnly && typeDisabledFor != 'EXPENSE',
            ),
            PToggleGroupItem(
              value: 'INCOME',
              label: '수입',
              disabled: typeReadOnly && typeDisabledFor != 'INCOME',
            ),
            if (!typeReadOnly || c.type == 'TRANSFER')
              PToggleGroupItem(
                value: 'TRANSFER',
                label: '이체',
                disabled: typeReadOnly && typeDisabledFor != 'TRANSFER',
              ),
          ],
        ),
        const SizedBox(height: PSpace.x12),

        if (presetSlot != null) ...[
          presetSlot!,
          const SizedBox(height: PSpace.x20),
        ],

        // 금액
        Row(
          children: [
            Expanded(child: PSectionLabel('금액')),
            if (c.amountLocked) ...[
              Icon(LucideIcons.lock, size: 11, color: t.fgTertiary),
              const SizedBox(width: 3),
              Text(
                '프리셋 잠금',
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ],
        ),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.amountCtrl,
          numbersOnly: true,
          enabled: !c.amountLocked,
          placeholder: '0',
          prefixText: amountInt > 0 ? amountPrefix : null,
          suffixText: '원',
          style: PTypo.h4.copyWith(
            color: amountColor,
            fontWeight: PFontWeight.bold,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: PSpace.x16),

        if (c.type != 'TRANSFER') ...[
          PSectionLabel('카테고리', variant: PSectionLabelVariant.eyebrow),
          const SizedBox(height: PSpace.x8),
          categoriesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: PCircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              '카테고리 로드 실패: $e',
              style: PTypo.caption.copyWith(color: t.statusDanger),
            ),
            data: (categories) {
              final topCategories =
                  categories
                      .where(
                        (cat) =>
                            cat.expenseType == c.type &&
                            (cat.parentRowId == null || cat.parentRowId == 0),
                      )
                      .toList()
                    ..sort(
                      (a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0),
                    );
              if (topCategories.isEmpty) {
                return Text(
                  '이 타입에 해당하는 카테고리가 없습니다',
                  style: PTypo.caption.copyWith(color: t.fgTertiary),
                );
              }

              final childrenByParent = <int, List<dynamic>>{};
              for (final cat in categories) {
                if (cat.parentRowId == null ||
                    cat.parentRowId == 0 ||
                    cat.expenseType != c.type) {
                  continue;
                }
                childrenByParent
                    .putIfAbsent(cat.parentRowId!, () => [])
                    .add(cat);
              }
              for (final list in childrenByParent.values) {
                list.sort(
                  (a, b) => ((a.sortOrder ?? 0) as int).compareTo(
                    (b.sortOrder ?? 0) as int,
                  ),
                );
              }

              final selectedCat = c.categoryRowId == null
                  ? null
                  : categories
                        .where((cat) => cat.rowId == c.categoryRowId)
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
                      final cellWidth =
                          (constraints.maxWidth - gap * (columns - 1)) /
                          columns;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (final cat in topCategories)
                            SizedBox(
                              width: cellWidth,
                              child: PCategoryTile(
                                name: cat.categoryName,
                                color: resolveChartColor(
                                  context,
                                  cat.color,
                                  fallback: t.fgBrand,
                                ),
                                icon: lucideByName(cat.icon ?? 'tag'),
                                active: selectedParentId == cat.rowId,
                                onTap: () => _set(() {
                                  final firstChild =
                                      childrenByParent[cat.rowId]?.first;
                                  c.categoryRowId = firstChild != null
                                      ? firstChild.rowId
                                      : cat.rowId;
                                }),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (selectedParentId != null &&
                      (childrenByParent[selectedParentId]?.isNotEmpty ??
                          false)) ...[
                    const SizedBox(height: 10),
                    _SelectField<int>(
                      value: c.categoryRowId,
                      hint: '세부 카테고리',
                      items: [
                        _SelectOption<int>(
                          selectedParentId,
                          '${topCategories.firstWhere((cat) => cat.rowId == selectedParentId).categoryName} (상위)',
                        ),
                        for (final child in childrenByParent[selectedParentId]!)
                          _SelectOption<int>(
                            child.rowId as int,
                            child.categoryName as String,
                          ),
                      ],
                      onChanged: (v) => _set(() => c.categoryRowId = v),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: PSpace.x12),
        ],

        if (c.type != 'TRANSFER') ...[
          // 거래처
          PSectionLabel(c.type == 'INCOME' ? '수입처' : '거래처'),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: c.merchantCtrl,
            placeholder: c.type == 'INCOME' ? '예: (주)포레스트' : '예: 스타벅스 강남점',
          ),
          const SizedBox(height: PSpace.x12),

          // 결제 수단 (Select)
          PSectionLabel(c.type == 'INCOME' ? '수입 방식' : '결제 수단'),
          const SizedBox(height: PSpace.x4),
          _SelectField<String>(
            value: c.paymentMethod.isEmpty ? null : c.paymentMethod,
            hint: '선택 안 함',
            items: [
              const _SelectOption<String>('', '선택 안 함'),
              for (final pm in _txPaymentMethods)
                _SelectOption<String>(pm.$1, pm.$2),
            ],
            onChanged: (v) => _set(() {
              c.paymentMethod = v ?? '';
              if (c.paymentMethod.isNotEmpty && c.assetRowId != null) {
                final allowed = _txPaymentAssetTypes[c.paymentMethod];
                if (allowed != null) {
                  final assets = assetsAsync.value ?? const [];
                  final cur = assets
                      .where((a) => a.rowId == c.assetRowId)
                      .firstOrNull;
                  if (cur != null && !allowed.contains(cur.assetType)) {
                    c.assetRowId = null;
                  }
                }
              }
            }),
          ),
          const SizedBox(height: PSpace.x12),

          // 계좌·카드 (Select, payment method 로 필터)
          PSectionLabel(c.type == 'INCOME' ? '입금 계좌' : '계좌·카드'),
          const SizedBox(height: PSpace.x4),
          assetsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: PCircularProgressIndicator()),
            ),
            error: (e, _) => Text(
              '자산 로드 실패: $e',
              style: PTypo.caption.copyWith(color: t.statusDanger),
            ),
            data: (assets) {
              final allowed = c.paymentMethod.isNotEmpty
                  ? _txPaymentAssetTypes[c.paymentMethod]
                  : null;
              final filtered = allowed == null
                  ? assets
                  : assets.where((a) => allowed.contains(a.assetType)).toList();
              return _SelectField<int>(
                value: c.assetRowId,
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
                onChanged: (v) => _set(() => c.assetRowId = v == -1 ? null : v),
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
              value: c.assetRowId,
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
              onChanged: (v) => _set(() => c.assetRowId = v),
            ),
          ),
          const SizedBox(height: PSpace.x12),
          PSectionLabel('입금 계좌'),
          const SizedBox(height: PSpace.x4),
          assetsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (assets) => _SelectField<int>(
              value: c.toAssetRowId,
              hint: '선택',
              items: [
                for (final a in assets.where((a) => a.rowId != c.assetRowId))
                  _SelectOption<int>(
                    a.rowId,
                    a.institution != null
                        ? '${a.institution} · ${a.assetName}'
                        : a.assetName,
                  ),
              ],
              onChanged: (v) => _set(() => c.toAssetRowId = v),
            ),
          ),
          if (c.assetRowId != null && c.assetRowId == c.toAssetRowId)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '보낼/받을 자산은 달라야 합니다',
                style: PTypo.caption.copyWith(color: t.statusDanger),
              ),
            ),
          const SizedBox(height: PSpace.x12),
          PSectionLabel('수수료 (선택)'),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: c.feeCtrl,
            numbersOnly: true,
            placeholder: '0',
          ),
          const SizedBox(height: PSpace.x12),
        ],

        // 날짜(·시간)
        PSectionLabel(c.type != 'TRANSFER' ? '날짜·시간' : '날짜'),
        const SizedBox(height: PSpace.x4),
        (c.type == 'TRANSFER')
            ? PDateInput(
                value: c.date,
                onChanged: (d) {
                  if (d != null) _set(() => c.date = d);
                },
                firstDate: DateTime(2020),
                lastDate: DateTime(2030, 12, 31),
              )
            : Row(
                children: [
                  Expanded(
                    child: PDateInput(
                      value: c.date,
                      onChanged: (d) {
                        if (d != null) _set(() => c.date = d);
                      },
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030, 12, 31),
                    ),
                  ),
                  const SizedBox(width: PSpace.x8),
                  SizedBox(
                    width: 116,
                    child: PTimeInput(
                      value: c.time,
                      onChanged: (tm) {
                        if (tm != null) _set(() => c.time = tm);
                      },
                    ),
                  ),
                ],
              ),
        const SizedBox(height: PSpace.x16),

        PSectionLabel('메모'),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: c.memoCtrl,
          maxLines: 2,
          placeholder: '예: 점심, 회식 등',
        ),
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
