import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/amount_limits.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_icon_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_color_picker.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';

void showSavingGoalEditDialog(BuildContext context, {SavingGoal? edit}) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: edit == null ? l.savingGoalAdd : l.savingGoalEdit,
    contentBuilder: (ctx, scrollCtrl) =>
        _Body(edit: edit, scrollController: scrollCtrl, controller: controller),
    footerBuilder: (ctx) => PSheetFooter(
      controller: controller,
      submitLabel: edit == null ? l.savingGoalSubmitAdd : l.actionEdit,
    ),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({
    this.edit,
    required this.scrollController,
    required this.controller,
  });
  final SavingGoal? edit;
  final ScrollController scrollController;
  final PSheetController controller;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _currentCtrl;
  DateTime? _deadline;
  late String _icon;
  late String _color;
  bool _submitting = false;
  bool _touched = false;
  bool get _isEdit => widget.edit != null;

  /// 이름 길이 상한 — 웹 `GOAL_NAME_MAX` · 카테고리와 같은 값(QA #52).
  static const _kNameMax = 12;

  String get _titleTrim => _titleCtrl.text.trim();

  /// 같은 이름 목표가 둘이면 목록·알림에서 어느 쪽인지 알 수 없다.
  /// 목록 캐시가 비어 있으면 못 잡는다 — 최종 게이트는 서버다.
  bool get _duplicate =>
      _titleTrim.isNotEmpty &&
      (ref.read(savingGoalListProvider).value ?? const <SavingGoal>[]).any(
        (g) => g.title.trim() == _titleTrim && g.rowId != widget.edit?.rowId,
      );

  /// 카테고리 다이얼로그와 같은 규칙 — touched 전에는 에러를 안 보여 준다.
  /// 100자로 저장된 기존 목표를 열자마자 빨개지면 안 된다.
  String? get _nameError {
    if (!_touched) return null;
    final l = AppLocalizations.of(context);
    if (_titleTrim.length > _kNameMax) return l.nameTooLong(_kNameMax);
    if (_duplicate) return l.savingGoalNameDuplicate;
    return null;
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.edit?.title ?? '');
    _amountCtrl = TextEditingController(
      text: widget.edit?.targetAmount.toString() ?? '',
    );
    _currentCtrl = TextEditingController(
      text: widget.edit == null || widget.edit!.currentAmount == 0
          ? ''
          : widget.edit!.currentAmount.toString(),
    );
    _deadline = widget.edit?.deadlineDate == null
        ? null
        : DateTime.tryParse(widget.edit!.deadlineDate!);
    // 전체 아이콘 픽커 도입으로 저장된 이름을 그대로 존중한다(10종 강제 대체 제거).
    final editIcon = widget.edit?.icon;
    _icon = editIcon != null && editIcon.isNotEmpty ? editIcon : 'piggy-bank';
    final editColor = widget.edit?.color?.toLowerCase();
    _color = editColor != null && kChartBaseHexes.contains(editColor)
        ? editColor
        : kChartBaseHexes.first;
    widget.controller.onSubmit = _submit;
  }

  void _setSubmitting(bool v) {
    setState(() => _submitting = v);
    widget.controller.setSubmitting(v);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _currentCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  int get _current => int.tryParse(_currentCtrl.text.replaceAll(',', '')) ?? 0;

  bool get _canSubmit {
    if (_submitting) return false;
    if (_titleTrim.isEmpty) return false;
    // 카테고리와 같은 흐름 — touched 전엔 막지 않는다. 100자로 저장된 기존 목표를
    // 열자마자 저장이 죽으면 왜 안 되는지 알 길이 없다(QA #55 와 같은 실패다).
    if (_touched && (_titleTrim.length > _kNameMax || _duplicate)) return false;
    final amt = int.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (amt == null || amt <= 0) return false;
    // 웹 SavingGoalAddDialog 정합 — 현재 모은 금액은 목표 금액을 넘을 수 없다.
    return _current <= amt;
  }

  Future<void> _submit() async {
    _setSubmitting(true);
    try {
      final repo = await ref.read(savingGoalRepositoryProvider.future);
      final amt = int.parse(_amountCtrl.text.replaceAll(',', ''));
      final color = _color;
      // 현재 모은 금액은 update/create 필드가 아니라 contribute API 로 차액 반영
      // (웹 SavingGoalAddDialog 동일 로직).
      if (_isEdit) {
        await repo.update(
          id: widget.edit!.rowId,
          title: _titleTrim,
          targetAmount: amt,
          deadlineDate: _deadline == null ? null : _fmtDate(_deadline!),
          color: color,
          icon: _icon,
        );
        final diff = _current - widget.edit!.currentAmount;
        if (diff != 0) {
          await repo.contribute(widget.edit!.rowId, amount: diff);
        }
      } else {
        final created = await repo.create(
          title: _titleTrim,
          targetAmount: amt,
          deadlineDate: _deadline == null ? null : _fmtDate(_deadline!),
          color: color,
          icon: _icon,
        );
        if (_current > 0) {
          await repo.contribute(created.rowId, amount: _current);
        }
      }
      ref.invalidate(savingGoalListProvider);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.setCanSubmit(_canSubmit);
    });
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        // 입력값 실시간 미리보기 — 웹 SavingGoalAddDialog Preview 정합.
        // 이름·금액 PTextInput 의 onChanged setState 가 있어 별도 리스너 없이 갱신된다.
        _Preview(
          title: _titleCtrl.text.trim(),
          deadline: _deadline,
          icon: _icon,
          colorHex: _color,
          current: _current,
          target: int.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0,
        ),
        const SizedBox(height: PSpace.x16),
        Text(
          l.savingGoalNameLabel,
          style: PTypo.caption.copyWith(color: t.fgSecondary),
        ),
        const SizedBox(height: PSpace.x4),
        PTextInput(
          controller: _titleCtrl,
          placeholder: l.savingGoalNameHint,
          onChanged: (_) => setState(() => _touched = true),
        ),
        const SizedBox(height: PSpace.x4),
        // 카운터 N/12 또는 에러 — 카테고리 다이얼로그와 같은 모양.
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _nameError ?? '${_titleTrim.length}/$_kNameMax',
            style: PTypo.micro.copyWith(
              color: _nameError != null ? t.fgExpense : t.fgTertiary,
            ),
          ),
        ),
        const SizedBox(height: PSpace.x8),
        // 목표 금액 / 현재 모은 금액 — design GoalEditDialog 2열 grid 정합.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.savingGoalAmountLabel,
                    style: PTypo.caption.copyWith(color: t.fgSecondary),
                  ),
                  const SizedBox(height: PSpace.x4),
                  PTextInput(
                    controller: _amountCtrl,
                    numbersOnly: true,
                    amountMax: kAmountMax,
                    placeholder: '0',
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.savingGoalCurrentLabel,
                    style: PTypo.caption.copyWith(color: t.fgSecondary),
                  ),
                  const SizedBox(height: PSpace.x4),
                  PTextInput(
                    controller: _currentCtrl,
                    numbersOnly: true,
                    amountMax: kAmountMax,
                    placeholder: '0',
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x12),
        Text(
          l.savingGoalDeadlineLabel,
          style: PTypo.caption.copyWith(color: t.fgSecondary),
        ),
        const SizedBox(height: PSpace.x4),
        PDateInput(
          value: _deadline,
          onChanged: (d) => setState(() => _deadline = d),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          placeholder: l.savingGoalDeadlineHint,
          allowClear: true,
        ),
        const SizedBox(height: PSpace.x16),
        Text(
          l.savingGoalIconLabel,
          style: PTypo.caption.copyWith(color: t.fgSecondary),
        ),
        const SizedBox(height: PSpace.x8),
        // 전체 아이콘 검색·선택 — 웹 SavingGoalAddDialog 와 동일한 공통 픽커.
        // '없음' 선택은 저축 목표 기본 아이콘(piggy-bank)으로 대체(웹 정합).
        PIconPicker(
          value: _icon,
          onChanged: (v) =>
              setState(() => _icon = v.isEmpty ? 'piggy-bank' : v),
        ),
        const SizedBox(height: PSpace.x16),
        Text(
          l.savingGoalColorLabel,
          style: PTypo.caption.copyWith(color: t.fgSecondary),
        ),
        const SizedBox(height: PSpace.x8),
        PColorPicker(
          selected: _color,
          onChanged: (hex) => setState(() => _color = hex),
        ),
      ],
    );
  }
}

/// 입력값 실시간 미리보기 — 웹 SavingGoalAddDialog Preview(bg-canvas 박스) 미러.
/// 아이콘 타일·게이지는 목록 화면 `_GoalCard` 와 같은 다크 스왑 팔레트를 쓴다.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.title,
    required this.deadline,
    required this.icon,
    required this.colorHex,
    required this.current,
    required this.target,
  });
  final String title;
  final DateTime? deadline;
  final String icon;
  final String colorHex;
  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final color = resolveChartColor(context, colorHex, fallback: t.fgBrand);
    final bg = softBg(context, color);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final pct = target > 0 ? (current / target * 100).round() : 0;
    final deadlineLabel = deadline == null
        ? l.savingGoalNoDeadline
        : '${deadline!.year}.${deadline!.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(PSpace.x16),
      decoration: BoxDecoration(
        color: t.bgCanvas,
        borderRadius: PRadius.brLg,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: PRadius.tile(36),
                ),
                alignment: Alignment.center,
                child: Icon(lucideByName(icon), size: 17, color: color),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? l.savingGoalNameLabel : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PTypo.bodySm.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    Text(
                      deadlineLabel,
                      style: PTypo.caption.copyWith(color: t.fgTertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PSpace.x12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$pct%',
                    style: PTypo.bodySm.copyWith(
                      color: t.fgPrimary,
                      fontWeight: PFontWeight.bold,
                    ),
                  ),
                  Text(
                    '${krw(current)} / ${krw(target)}',
                    style: PTypo.micro.copyWith(color: t.fgTertiary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          ClipRRect(
            borderRadius: PRadius.brXs,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: t.bgTrack,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
