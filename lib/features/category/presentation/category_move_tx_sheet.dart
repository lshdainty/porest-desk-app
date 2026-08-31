import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/features/expense/application/expense_providers.dart';
import 'package:porest_desk_app/features/expense/domain/expense_category.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_segmented.dart';
import 'package:porest_desk_app/shared/widgets/p_select.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';

/// 카테고리에 달린 거래를 다른 카테고리로 옮긴다 (web `CategoryMoveTxDialog` 미러).
///
/// 거래가 직접 달린 카테고리는 하위 분류를 만들 수 없다(거래는 말단에만 달 수 있어서).
/// 그런데 옮길 하위가 없으면 거래도 못 옮기는 교착이 생기므로,
/// "새 하위 만들기" 는 생성과 이동을 서버에서 한 트랜잭션으로 처리한다.
void showCategoryMoveTxSheet(
  BuildContext context, {
  required ExpenseCategory source,
  required List<ExpenseCategory> categories,
}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.categoryMoveTxTitle,
    contentBuilder: (ctx, scrollCtrl) => _MoveTxBody(
      source: source,
      categories: categories,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: l.categoryMoveTxAction,
    ),
  ).whenComplete(controller.dispose);
}

class _MoveTxBody extends ConsumerStatefulWidget {
  const _MoveTxBody({
    required this.source,
    required this.categories,
    required this.scrollController,
    required this.controller,
  });
  final ExpenseCategory source;
  final List<ExpenseCategory> categories;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_MoveTxBody> createState() => _MoveTxBodyState();
}

class _MoveTxBodyState extends ConsumerState<_MoveTxBody> {
  final _nameCtrl = TextEditingController();
  int? _targetRowId;
  late bool _newMode;

  /// 하위가 없는 최상위만 "새 하위 만들기" 대상 — 교착이 생기는 자리가 정확히 여기다.
  /// 하위 카테고리엔 또 하위를 만들 수 없다(최대 2단계).
  bool get _canSplit =>
      widget.source.parentRowId == null &&
      !widget.categories.any((c) => c.parentRowId == widget.source.rowId);

  /// 옮길 수 있는 곳 = 같은 유형이고, 자기 자신이 아니고, 자식이 없는 말단.
  /// 서버도 같은 규칙으로 거부하므로 미리 걸러 고를 수 없게 한다.
  List<ExpenseCategory> get _options {
    final parentIds = widget.categories
        .where((c) => c.parentRowId != null)
        .map((c) => c.parentRowId!)
        .toSet();
    return widget.categories
        .where(
          (c) =>
              c.rowId != widget.source.rowId &&
              c.expenseType == widget.source.expenseType &&
              !parentIds.contains(c.rowId),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _newMode = _canSplit;
    widget.controller.onSubmit = _submit;
    // 초기엔 아무것도 안 고른 상태 — 제출 버튼을 잠가둔다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCanSubmit());
  }

  /// 모드에 따라 제출 가능 조건이 다르다 — 새 하위는 이름, 기존 이동은 대상 선택.
  void _syncCanSubmit() {
    final ok = _newMode
        ? _nameCtrl.text.trim().isNotEmpty
        : _targetRowId != null;
    widget.controller.setCanSubmit(ok);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// 이름이 같은 말단이 여럿일 수 있어 부모 경로를 함께 보여준다.
  String _label(ExpenseCategory c) {
    if (c.parentRowId == null) return c.categoryName;
    final parent = widget.categories
        .where((p) => p.rowId == c.parentRowId)
        .map((p) => p.categoryName)
        .firstOrNull;
    return parent == null ? c.categoryName : '$parent > ${c.categoryName}';
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    if (_newMode ? name.isEmpty : _targetRowId == null) return;

    widget.controller.setSubmitting(true);
    try {
      final repo = await ref.read(expenseRepositoryProvider.future);
      final moved = _newMode
          ? await repo.splitCategoryIntoChild(
              widget.source.rowId,
              childName: name,
              icon: widget.source.icon ?? 'tag',
              color: widget.source.color ?? '#9E9E9E',
            )
          : await repo.moveCategoryTransactions(
              widget.source.rowId,
              _targetRowId!,
            );
      // 거래의 카테고리가 바뀌므로 목록·통계까지 새로 받는다.
      ref.invalidate(categoriesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showPSnackBar(
        context,
        l.categoryMoveTxDone(moved),
        severity: PSnackSeverity.success,
      );
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) widget.controller.setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    return ListView(
      controller: widget.scrollController,
      children: [
        Text(
          l.categoryMoveTxDesc(widget.source.categoryName),
          style: PTypo.bodySm.copyWith(color: t.fgSecondary),
        ),
        const SizedBox(height: PSpace.x16),
        if (_canSplit) ...[
          PSegmented<bool>(
            value: _newMode,
            onChanged: (v) => setState(() {
              _newMode = v;
              _syncCanSubmit();
            }),
            options: [
              PSegmentOption(value: true, label: l.categoryMoveTxModeNew),
              PSegmentOption(value: false, label: l.categoryMoveTxModeExisting),
            ],
          ),
          const SizedBox(height: PSpace.x16),
        ],
        if (_newMode) ...[
          PSectionLabel(l.categoryMoveTxChildName),
          const SizedBox(height: PSpace.x4),
          PTextInput(
            controller: _nameCtrl,
            placeholder: l.categoryMoveTxChildPlaceholder,
            onChanged: (_) => _syncCanSubmit(),
          ),
          const SizedBox(height: PSpace.x4),
          Text(
            l.categoryMoveTxNewHint(widget.source.categoryName),
            style: PTypo.caption.copyWith(color: t.fgTertiary),
          ),
        ] else ...[
          PSectionLabel(l.categoryMoveTxTarget),
          const SizedBox(height: PSpace.x4),
          PSelect<int>(
            value: _targetRowId,
            enabled: _options.isNotEmpty,
            placeholder: l.categoryMoveTxTargetPlaceholder,
            helperText: _options.isEmpty
                ? l.categoryMoveTxNoTarget
                : l.categoryMoveTxHint,
            items: [
              for (final c in _options)
                PSelectItem(value: c.rowId, label: _label(c)),
            ],
            onChanged: (v) => setState(() {
              _targetRowId = v;
              _syncCanSubmit();
            }),
          ),
        ],
      ],
    );
  }
}
