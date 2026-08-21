import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_category_tile.dart';
import 'package:porest_desk_app/shared/widgets/p_checkbox.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/features/preset/application/preset_providers.dart';
import 'package:porest_desk_app/features/preset/domain/expense_template.dart';

/// 웹 `PresetEditDialog` 미러 — 결제 수단 목록.
const _kPaymentMethodValues = <String>['CASH', 'CARD', 'TRANSFER', 'OTHER'];

String _payLabel(AppLocalizations l, String v) => switch (v) {
      'CASH' => l.expPayCash,
      'CARD' => l.expPayCard,
      'TRANSFER' => l.expPayTransfer,
      _ => l.expPayOther,
    };

void showPresetEditDialog(BuildContext context, {ExpenseTemplate? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.presetAdd : l.presetEditTitle,
    contentBuilder: (ctx, scrollCtrl) =>
        _Body(edit: edit, scrollController: scrollCtrl, controller: controller),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? l.presetSubmitAdd : l.actionSave,
    ),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    this.edit,
    required this.scrollController,
    required this.controller,
  });
  final ExpenseTemplate? edit;
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _merchantCtrl;
  late final TextEditingController _amountCtrl;
  late String _type;
  int? _categoryRowId;
  int? _assetRowId;
  late String _paymentMethod;
  late bool _lockAmount;
  bool _submitting = false;

  bool get _isEdit => widget.edit != null;

  @override
  void initState() {
    super.initState();
    final t = widget.edit;
    _type = t?.expenseType ?? 'EXPENSE';
    _nameCtrl = TextEditingController(text: t?.templateName ?? '');
    _categoryRowId = t?.categoryRowId;
    _merchantCtrl = TextEditingController(text: t?.merchant ?? '');
    _paymentMethod = t?.paymentMethod ?? '';
    _assetRowId = t?.assetRowId;
    _lockAmount = (t?.lockAmount ?? 'N') == 'Y';
    _amountCtrl = TextEditingController(
      text: t?.amount != null ? '${t!.amount}' : '',
    );
    widget.controller.onSubmit = _submit;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  // 웹 canSave: name.trim().length > 0 && categoryRowId != null
  /// 금액은 선택이다 — 프리셋은 금액을 모르는 채로 양식만 저장하려고 만든 것이다.
  /// 고정 금액을 켰을 때만 값이 있어야 한다(불러오는 거래가 그 값을 그대로 받는다).
  bool get _canSubmit =>
      !_submitting &&
      _nameCtrl.text.trim().isNotEmpty &&
      _categoryRowId != null &&
      (!_lockAmount || _amountValue > 0);

  int get _amountValue =>
      int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  /// 타입 변경 시 현재 카테고리가 새 타입과 안 맞으면 리셋 (웹 effect 정합).
  void _onTypeChanged(String next, List<ExpenseCategory> categories) {
    setState(() {
      _type = next;
      final id = _categoryRowId;
      if (id != null) {
        final cat = categories.byRowId(id);
        if (cat == null || cat.expenseType != next) {
          _categoryRowId = null;
        }
      }
    });
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    _setSubmitting(true);
    try {
      final repo = await ref.read(presetRepositoryProvider.future);
      final name = _nameCtrl.text.trim();
      final merchant = _merchantCtrl.text.trim();
      // 웹: amount = lockAmount ? Number(amount||0) : undefined
      final amount = _lockAmount
          ? (int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
                0)
          : null;
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          templateName: name,
          categoryRowId: _categoryRowId,
          assetRowId: _assetRowId,
          expenseType: _type,
          amount: amount,
          merchant: merchant.isEmpty ? null : merchant,
          paymentMethod: _paymentMethod.isEmpty ? null : _paymentMethod,
          lockAmount: _lockAmount,
        );
      } else {
        await repo.create(
          templateName: name,
          categoryRowId: _categoryRowId,
          assetRowId: _assetRowId,
          expenseType: _type,
          amount: amount,
          merchant: merchant.isEmpty ? null : merchant,
          paymentMethod: _paymentMethod.isEmpty ? null : _paymentMethod,
          lockAmount: _lockAmount,
        );
      }
      ref.invalidate(presetListProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) _setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final assetsAsync = ref.watch(assetsProvider);
    final categories = categoriesAsync.value ?? const <ExpenseCategory>[];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });

    return ListView(
      controller: widget.scrollController,
      // 시트 좌우 여백은 xl(24) — porest-design drawer.md 정합.
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.lg),
      children: [
        // ① 지출/수입 세그먼트
        PTabs<String>(
          value: _type,
          variant: PTabsVariant.container,
          size: PTabsSize.sm,
          expand: true,
          items: [
            PTabItem(value: 'EXPENSE', label: l.expTypeExpense),
            PTabItem(value: 'INCOME', label: l.expTypeIncome),
          ],
          onChanged: (v) => _onTypeChanged(v, categories),
        ),
        const SizedBox(height: PSpace.lg),

        // ② 프리셋 이름
        _FieldLabel(l.presetName),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _nameCtrl,
          placeholder: l.expPresetNamePlaceholder,
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),

        // ③ 카테고리 (5열 그룹 타일 grid)
        _FieldLabel(l.expCategory),
        const SizedBox(height: PSpace.x8),
        categoriesAsync.when(
          loading: () => _categoryGridSkeleton(),
          error: (e, _) => Text(
            l.categoryLoadError,
            style: PTypo.caption.copyWith(color: t.statusDanger),
          ),
          data: (cats) => _CategoryGrid(
            categories: cats,
            type: _type,
            categoryRowId: _categoryRowId,
            onSelect: (id) => setState(() => _categoryRowId = id),
          ),
        ),
        // 세부 카테고리 — 반복거래와 동일 패턴: 자식이 있으면 상위/세부 선택으로 변경 가능
        categoriesAsync.maybeWhen(
          data: (cats) => _buildSubcategorySelect(l, cats),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 14),

        // ④ 기본 내역
        _FieldLabel(l.presetMerchant),
        const SizedBox(height: PSpace.x4),
        PTextInput(controller: _merchantCtrl, placeholder: l.presetMerchantPlaceholder),
        const SizedBox(height: 14),

        // ⑤ 결제 수단
        _FieldLabel(l.expPaymentMethod),
        const SizedBox(height: PSpace.x4),
        PSelect<String>(
          value: _paymentMethod.isEmpty ? null : _paymentMethod,
          placeholder: l.presetSelectNone,
          title: l.expPaymentMethod,
          items: [
            PSelectItem(value: '', label: l.presetSelectNone),
            for (final v in _kPaymentMethodValues)
              PSelectItem(value: v, label: _payLabel(l, v)),
          ],
          onChanged: (v) => setState(() => _paymentMethod = v ?? ''),
        ),
        const SizedBox(height: 14),

        // ⑥ 계좌·카드
        _FieldLabel(l.presetAssetCard),
        const SizedBox(height: PSpace.x4),
        assetsAsync.when(
          loading: () => const PSkeleton(width: double.infinity, height: 40),
          error: (e, _) => Text(
            l.presetAssetLoadError,
            style: PTypo.caption.copyWith(color: t.statusDanger),
          ),
          data: (assets) => PSelect<int>(
            value: _assetRowId,
            placeholder: l.presetSelectNone,
            title: l.presetAssetCard,
            items: [
              PSelectItem(value: -1, label: l.presetSelectNone),
              for (final a in assets)
                PSelectItem(
                  value: a.rowId,
                  label: a.institution != null && a.institution!.isNotEmpty
                      ? '${a.institution} · ${a.assetName}'
                      : a.assetName,
                ),
            ],
            onChanged: (v) =>
                setState(() => _assetRowId = (v == null || v == -1) ? null : v),
          ),
        ),
        const SizedBox(height: 14),

        // ⑦ '고정 금액 사용' 체크 카드
        _LockAmountCard(
          lockAmount: _lockAmount,
          amountCtrl: _amountCtrl,
          onToggle: (v) => setState(() => _lockAmount = v),
        ),
      ],
    );
  }

  /// 세부 카테고리 선택 — 반복거래(recurring_settings_drawer)와 동일 패턴.
  /// 선택된 상위에 자식이 있으면 [상위 (상위), ...자식들] PSelect 로 변경 가능하게.
  Widget _buildSubcategorySelect(AppLocalizations l, List<ExpenseCategory> cats) {
    bool isTop(ExpenseCategory c) => c.parentRowId == null || c.parentRowId == 0;

    final childrenByParent = <int, List<ExpenseCategory>>{};
    for (final c in cats) {
      if (isTop(c) || c.expenseType != _type) continue;
      childrenByParent.putIfAbsent(c.parentRowId!, () => []).add(c);
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    }

    final selectedCat =
        _categoryRowId == null ? null : cats.byRowId(_categoryRowId!);
    final selectedParentId = selectedCat == null
        ? null
        : (isTop(selectedCat) ? selectedCat.rowId : selectedCat.parentRowId);
    final children = selectedParentId == null
        ? const <ExpenseCategory>[]
        : (childrenByParent[selectedParentId] ?? const []);
    if (selectedParentId == null || children.isEmpty) {
      return const SizedBox.shrink();
    }

    final parentName = cats.byRowId(selectedParentId)?.categoryName ?? '';
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: PSelect<int>(
        value: _categoryRowId,
        placeholder: l.expSubcategory,
        title: l.expSubcategory,
        items: [
          PSelectItem(
            value: selectedParentId,
            label: l.recurringParentCategory(parentName),
          ),
          for (final child in children)
            PSelectItem(value: child.rowId, label: child.categoryName),
        ],
        onChanged: (v) {
          if (v != null) setState(() => _categoryRowId = v);
        },
      ),
    );
  }

  Widget _categoryGridSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        const columns = 5;
        final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (int i = 0; i < 10; i++)
              SizedBox(
                width: cell,
                height: 64,
                child: const PSkeleton(
                  width: double.infinity,
                  height: 64,
                  borderRadius: PRadius.brLg,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 웹 `FieldLabel` 미러 — text-label-sm(13) / fg-secondary / 600.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      text,
      style: TextStyle(
        fontFamily: PTypo.sans,
        fontSize: PFontSize.bodySm, // --text-label-sm = 13
        fontWeight: PFontWeight.semi,
        color: t.fgSecondary,
      ),
    );
  }
}

/// 5열 그룹 타일 grid + 첫 자식 매핑 (웹 `topCategories`/`childrenByParent` 정합).
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.type,
    required this.categoryRowId,
    required this.onSelect,
  });

  final List<ExpenseCategory> categories;
  final String type;
  final int? categoryRowId;
  final ValueChanged<int> onSelect;

  bool _isTop(ExpenseCategory c) => c.parentRowId == null || c.parentRowId == 0;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    final topCategories =
        categories.where((c) => c.expenseType == type && _isTop(c)).toList()
          ..sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));

    if (topCategories.isEmpty) {
      return Text(
        l.expNoCategoryForType,
        style: PTypo.caption.copyWith(color: t.fgTertiary),
      );
    }

    final childrenByParent = <int, List<ExpenseCategory>>{};
    for (final c in categories) {
      if (_isTop(c) || c.expenseType != type) continue;
      childrenByParent.putIfAbsent(c.parentRowId!, () => []).add(c);
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) => (a.sortOrder ?? 0).compareTo(b.sortOrder ?? 0));
    }

    // 선택된 카테고리를 부모로 환원해 active 타일 판정.
    final selectedCat = categoryRowId == null
        ? null
        : categories.byRowId(categoryRowId!);
    final selectedParentId = selectedCat == null
        ? null
        : (_isTop(selectedCat) ? selectedCat.rowId : selectedCat.parentRowId);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        const columns = 5;
        final cell = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final c in topCategories)
              SizedBox(
                width: cell,
                child: PCategoryTile(
                  name: c.categoryName,
                  color: resolveChartColor(
                    context,
                    c.color,
                    fallback: t.fgBrand,
                  ),
                  icon: lucideByName(c.icon),
                  active: selectedParentId == c.rowId,
                  onTap: () {
                    final firstChild = childrenByParent[c.rowId]?.first;
                    onSelect(firstChild != null ? firstChild.rowId : c.rowId);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

/// '고정 금액 사용' 체크 카드 + 조건부 금액 입력.
class _LockAmountCard extends StatelessWidget {
  const _LockAmountCard({
    required this.lockAmount,
    required this.amountCtrl,
    required this.onToggle,
  });
  final bool lockAmount;
  final TextEditingController amountCtrl;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(PSpace.md),
      decoration: BoxDecoration(
        color: t.bgSunken,
        borderRadius: PRadius.brLg, // --radius-tile = 12
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PCheckbox(
                size: PCheckboxSize.sm,
                value: lockAmount,
                semanticLabel: l.presetLockToggle,
                onChanged: (v) => onToggle(v == true),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onToggle(!lockAmount),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.presetLockToggle,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.bodySm, // --text-label-sm
                          fontWeight: PFontWeight.bold,
                          color: t.fgPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.presetLockDesc,
                        style: PTypo.caption.copyWith(color: t.fgTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (lockAmount) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(l.presetLockAmountLabel),
                  const SizedBox(height: PSpace.x4),
                  PTextInput(
                    controller: amountCtrl,
                    numbersOnly: true,
                    placeholder: '0',
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.bodyLg, // --text-body-lg
                      fontWeight: PFontWeight.bold,
                      color: t.fgPrimary,
                    ),
                    // 우측 '원' 접미사 (웹 absolute 접미사 정합).
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 12, left: 4),
                      child: Text(
                        wonUnit(),
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.bodySm, // --text-label-sm
                          fontWeight: PFontWeight.bold,
                          color: t.fgTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
