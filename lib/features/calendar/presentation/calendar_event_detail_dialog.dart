import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 일정 상세 시트 — 일별 시트 행 탭 → 읽기 전용 상세 → 수정 버튼 → 편집 폼.
/// tx_detail_dialog(웹 EventDetailPopover 흐름) 패턴 미러: hero + field rows + 뷰 footer.
void showCalendarEventDetailDialog(BuildContext context, CalendarEvent event) {
  final l = AppLocalizations.of(context);
  final controller = PSheetController();
  showPSheet<void>(
    context,
    title: l.calEventDetailTitle,
    contentBuilder: (ctx, scrollCtrl) => _DetailBody(
      event: event,
      scrollController: scrollCtrl,
      controller: controller,
    ),
    footerBuilder: (ctx) => _DetailFooter(event: event, controller: controller),
  ).whenComplete(controller.dispose);
}

class _DetailFooter extends StatelessWidget {
  const _DetailFooter({required this.event, required this.controller});
  final CalendarEvent event;
  final PSheetController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        final busy = controller.submitting;
        return PViewFooter(
          onDelete: controller.onDelete,
          deleting: busy,
          onEdit: busy
              ? null
              : () {
                  Navigator.of(ctx).pop();
                  showCalendarEventDialog(ctx, edit: event);
                },
          onConfirm: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.event,
    required this.scrollController,
    required this.controller,
  });
  final CalendarEvent event;
  final ScrollController scrollController;
  final PSheetController controller;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  @override
  void initState() {
    super.initState();
    widget.controller.onDelete = _delete;
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final e = widget.event;
    final ok = await showPConfirmDialog(
      context,
      title: l.calEventDelete,
      message: l.calEventDeleteConfirm(e.title),
      confirmLabel: l.actionDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    widget.controller.setSubmitting(true);
    try {
      final repo = await ref.read(calendarRepositoryProvider.future);
      await repo.deleteEvent(e.rowId);
      ref.invalidate(
        monthEventsProvider((year: e.start.year, month: e.start.month)),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } on ApiException catch (ex) {
      if (!mounted) return;
      showPSnackBar(
        context,
        '${l.calDeleteFailed}: ${ex.message}',
        severity: PSnackSeverity.error,
      );
    } finally {
      if (mounted) widget.controller.setSubmitting(false);
    }
  }

  /// ISO LocalDateTime → 'YYYY-MM-DD HH:MM' (종일이면 날짜만).
  String _fmt(String iso, {required bool allDay}) {
    if (iso.length < 10) return iso;
    final day = iso.substring(0, 10);
    if (allDay || iso.length < 16) return day;
    return '$day ${iso.substring(11, 16)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final e = widget.event;
    final allDay = e.isAllDayBool;
    // 색 우선순위: label > calendar > event (일별 시트 색 바와 동일 규칙)
    final color = solidSwatchColor(
      context,
      e.labelColor ?? e.calendarColor ?? e.color,
      fallback: t.fgBrand,
    );
    final bg = softBg(context, color);
    final desc = (e.description ?? '').trim();
    final location = (e.location ?? '').trim();

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.x20, 0, PSpace.x20, PSpace.x16),
      children: [
        // Hero — 라벨/캘린더 색 틴트
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bg, t.bgSurface],
              stops: const [0.0, 0.85],
            ),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            borderRadius: PRadius.brXl,
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: PRadius.tile(40),
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.calendarDays, size: 19, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                e.title,
                textAlign: TextAlign.center,
                style: PTypo.h4.copyWith(
                  color: t.fgPrimary,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                allDay
                    ? '${_fmt(e.startDate, allDay: true)} · ${l.calAllDay}'
                    : '${_fmt(e.startDate, allDay: false)} ~ ${_fmt(e.endDate, allDay: false)}',
                textAlign: TextAlign.center,
                style: PTypo.caption.copyWith(color: t.fgTertiary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // Field rows
        Container(
          decoration: BoxDecoration(
            color: t.borderSubtle,
            border: Border.all(color: t.borderSubtle),
            borderRadius: PRadius.brLg,
          ),
          child: Column(
            children: [
              _FieldRow(
                label: l.calStartDate,
                tokens: t,
                isFirst: true,
                child: Text(
                  _fmt(e.startDate, allDay: allDay),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
              _FieldRow(
                label: l.calEndDate,
                tokens: t,
                child: Text(
                  _fmt(e.endDate, allDay: allDay),
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
              _FieldRow(
                label: l.calFieldLabel,
                tokens: t,
                child: (e.labelName ?? '').isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: PRadius.brXs,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e.labelName!,
                            style: PTypo.bodySm.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.semi,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        l.calDetailNone,
                        style: PTypo.bodySm.copyWith(color: t.fgTertiary),
                      ),
              ),
              _FieldRow(
                label: l.calLocation,
                tokens: t,
                child: Text(
                  location.isEmpty ? l.calDetailNone : location,
                  style: PTypo.bodySm.copyWith(
                    color: location.isEmpty ? t.fgTertiary : t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
              _FieldRow(
                label: l.calFieldDescription,
                tokens: t,
                isLast: true,
                child: Text(
                  desc.isEmpty ? l.calDetailNone : desc,
                  textAlign: TextAlign.right,
                  style: PTypo.bodySm.copyWith(
                    color: desc.isEmpty ? t.fgTertiary : t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.child,
    required this.tokens,
    this.isFirst = false,
    this.isLast = false,
  });
  final String label;
  final Widget child;
  final PorestTokens tokens;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.bgSurface,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(PRadius.lg) : Radius.zero,
          bottom: isLast ? const Radius.circular(PRadius.lg) : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: PTypo.caption.copyWith(color: tokens.fgTertiary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: child),
          ),
        ],
      ),
    );
  }
}
