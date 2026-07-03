import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_checkbox.dart';
import 'package:porest_desk_app/shared/widgets/p_date_input.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_text_input.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/domain/holiday.dart';

/// 공휴일 관리 다이얼로그 — front `HolidayManagementDialog` 미러.
///
/// 현재 연도의 공휴일을 조회하고 사용자 정의(CUSTOM) 휴일 추가/수정/삭제.
void showHolidayManagementDialog(BuildContext context) {
  showPSheet<void>(
    context,
    title: AppLocalizations.of(context).calHolidayMgmt,
    contentBuilder: (ctx, scrollCtrl) => _Body(scrollController: scrollCtrl),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.scrollController});
  final ScrollController scrollController;
  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late int _year = DateTime.now().year;
  final _nameCtrl = TextEditingController();
  late DateTime _newDate = DateTime(_year, 1, 1);
  bool _newRecurring = false;
  bool _adding = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  HolidayRange get _range => (
        startDate: '$_year-01-01',
        endDate: '$_year-12-31',
      );

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _adding) return;
    setState(() => _adding = true);
    try {
      final repo = await ref.read(holidayRepositoryProvider.future);
      await repo.create(
        holidayDate: _fmt(_newDate),
        holidayName: name,
        holidayType: 'CUSTOM',
        isRecurring: _newRecurring,
      );
      ref.invalidate(holidayListProvider(_range));
      _nameCtrl.clear();
      setState(() {
        _newRecurring = false;
        _adding = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _adding = false);
      showPSnackBar(context, '${AppLocalizations.of(context).calAddFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final async = ref.watch(holidayListProvider(_range));
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x16, 0, PSpace.x16, PSpace.x16),
      children: [
          // 연도 선택
          Row(
            children: [
              PButton.icon(
                icon: LucideIcons.chevronLeft,
                onPressed: () => setState(() => _year -= 1),
              ),
              Expanded(
                child: Center(
                  child: Text('$_year년',
                      style: PTypo.h4.copyWith(color: t.fgPrimary)),
                ),
              ),
              PButton.icon(
                icon: LucideIcons.chevronRight,
                onPressed: () => setState(() => _year += 1),
              ),
            ],
          ),
          const SizedBox(height: PSpace.x12),

          // 사용자 정의 추가 폼
          Text(l.calAddCustomHoliday,
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: PTextInput(
                  controller: _nameCtrl,
                  enabled: !_adding,
                  placeholder: l.calHolidayNamePlaceholder,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: PDateInput(
                  value: _newDate,
                  onChanged: (d) {
                    if (d != null) setState(() => _newDate = d);
                  },
                  firstDate: DateTime(_year, 1, 1),
                  lastDate: DateTime(_year, 12, 31),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              PCheckbox(
                value: _newRecurring,
                onChanged: (v) =>
                    setState(() => _newRecurring = v ?? false),
              ),
              Text(l.calRepeatYearlyLabel,
                  style: PTypo.caption.copyWith(color: t.fgSecondary)),
              const Spacer(),
              PButton(
                label: l.calAdd,
                loading: _adding,
                onPressed:
                    (_nameCtrl.text.trim().isEmpty || _adding) ? null : _add,
              ),
            ],
          ),
          const SizedBox(height: PSpace.x16),
          PDivider(),
          const SizedBox(height: PSpace.x16),

          Text(l.calYearHolidays(_year),
              style: PTypo.bodySm.copyWith(
                  color: t.fgPrimary, fontWeight: PFontWeight.bold)),
          const SizedBox(height: PSpace.x8),
          async.when(
            loading: () => const Center(child: PCircularProgressIndicator()),
            error: (e, _) => Text('${l.calHolidayLoadError}: $e',
                style: PTypo.caption.copyWith(color: t.statusDanger)),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x16),
                  child: Center(
                    child: Text(l.calNoHolidays,
                        style:
                            PTypo.caption.copyWith(color: t.fgTertiary)),
                  ),
                );
              }
              final sorted = [...list]
                ..sort((a, b) =>
                    a.holidayDate.compareTo(b.holidayDate));
              return Column(
                children: [
                  for (final h in sorted) _Row(holiday: h, tokens: t),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _Row extends ConsumerStatefulWidget {
  const _Row({required this.holiday, required this.tokens});
  final Holiday holiday;
  final PorestTokens tokens;
  @override
  ConsumerState<_Row> createState() => _RowState();
}

class _RowState extends ConsumerState<_Row> {
  bool _busy = false;

  Future<void> _delete() async {
    if (widget.holiday.holidayType != 'CUSTOM') return;
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.calDeleteHolidayTitle,
      message: l.calDeleteHolidayConfirm(widget.holiday.holidayName),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(holidayRepositoryProvider.future);
      await repo.delete(widget.holiday.rowId);
      ref.invalidate(holidayListProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showPSnackBar(context, '${l.calDeleteFailed}: ${e.message}',
          severity: PSnackSeverity.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final l = AppLocalizations.of(context);
    final h = widget.holiday;
    Color badgeColor;
    String typeLabel;
    switch (h.holidayType) {
      case 'CUSTOM':
        badgeColor = t.statusInfo;
        typeLabel = l.calHolidayTypeCustom;
        break;
      case 'SUBSTITUTE':
        badgeColor = t.statusWarning;
        typeLabel = l.calHolidayTypeSubstitute;
        break;
      default:
        badgeColor = t.statusDanger;
        typeLabel = l.calHolidayTypePublic;
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brSm,
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(h.holidayDate.substring(5),
                style: PTypo.caption.copyWith(
                    color: t.fgSecondary, fontWeight: PFontWeight.bold)),
          ),
          Expanded(
            child: Text(h.holidayName,
                style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
          ),
          if (h.isRecurring) ...[
            Icon(LucideIcons.repeat, size: 12, color: t.fgTertiary),
            const SizedBox(width: 6),
          ],
          PBadge.softColor(label: typeLabel, color: badgeColor),
          if (h.holidayType == 'CUSTOM')
            PButton.icon(
              icon: LucideIcons.trash2,
              size: PButtonSize.sm,
              iconColor: t.statusDanger,
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
    );
  }
}
