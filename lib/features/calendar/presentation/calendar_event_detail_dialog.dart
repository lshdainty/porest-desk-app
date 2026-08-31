import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/calendar/application/calendar_providers.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/domain/user_calendar.dart';
import 'package:porest_desk_app/features/calendar/presentation/calendar_event_dialog.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 일정 상세 시트 — 일별 시트 행 탭 → 읽기 전용 상세 → 수정 버튼 → 편집 폼.
/// design calendar.jsx `EventDetailDialog` 미러: 좌측 컬러바 hero(캘린더 pill·D-day) +
/// 시작→종료 시간 블록 + tone 원형 아이콘 rows + 메모 박스. (웹 EventDetailPopover 동일 개편)
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
    } on ApiException {
      if (!mounted) return;
    } finally {
      if (mounted) widget.controller.setSubmitting(false);
    }
  }

  /// rrule → 반복 라벨 (편집 폼 _rruleToRecurrence 와 동일 매핑, 없으면 '안 함').
  String _repeatLabel(AppLocalizations l, String? rrule) {
    if (rrule == null || rrule.isEmpty) return l.calRepeatNone;
    if (rrule.contains('FREQ=DAILY')) return l.calRepeatDaily;
    if (rrule.contains('FREQ=WEEKLY')) return l.calRepeatWeekly;
    if (rrule.contains('FREQ=MONTHLY')) return l.calRepeatMonthly;
    if (rrule.contains('FREQ=YEARLY')) return l.calRepeatYearly;
    return rrule;
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
    // design CAL_PALETTE fg — 이벤트 색 70% + fgPrimary 30% 혼합
    final fg = Color.lerp(t.fgPrimary, color, 0.7)!;
    final desc = (e.description ?? '').trim();
    final location = (e.location ?? '').trim();

    final start = e.start;
    final end = e.end;
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    String shortDate(DateTime d) {
      final x = formatDay(d);
      return '${x.md} (${x.dow})';
    }

    final ml = MaterialLocalizations.of(context);
    String hm(DateTime d) => ml.formatTimeOfDay(TimeOfDay.fromDateTime(d));

    // D-day — 오늘 기준 시작일. 임박(D-0~3)은 danger 강조 (design).
    final now = DateTime.now();
    final dd = DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    final ddLabel = dd == 0
        ? l.calDetailDday
        : (dd > 0 ? l.calDetailDdayLeft(dd) : l.calDetailDdayPast(-dd));

    // 기간 — 같은 날 시간 일정만(다일은 날짜로 이미 표현), 종일은 '종일' 라벨.
    String? durLabel;
    if (!allDay && sameDay) {
      final durMin = end.difference(start).inMinutes;
      if (durMin > 0) {
        durLabel = durMin >= 60
            ? (durMin % 60 != 0
                  ? l.calDetailDurationHM(durMin ~/ 60, durMin % 60)
                  : l.calDetailDurationH(durMin ~/ 60))
            : l.calDetailDurationM(durMin);
      }
    }

    // 캘린더 이름 — 이벤트 응답엔 rowId·색만 있어 캘린더 목록에서 룩업.
    final calendars =
        ref.watch(userCalendarListProvider).value ?? const <UserCalendar>[];
    final calName = e.calendarRowId == null
        ? null
        : calendars
              .where((c) => c.rowId == e.calendarRowId)
              .firstOrNull
              ?.calendarName;
    final calColor = solidSwatchColor(
      context,
      e.calendarColor,
      fallback: color,
    );

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(PSpace.xl, 0, PSpace.xl, PSpace.x16),
      children: [
        // Hero — 좌측 컬러 바 + [캘린더 pill · 그룹 · D-day] + 큰 제목
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: PRadius.brFull,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if ((calName ?? '').isNotEmpty)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: softBg(context, calColor),
                                borderRadius: PRadius.brFull,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: calColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      calName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PTypo.micro.copyWith(
                                        color: Color.lerp(
                                          t.fgPrimary,
                                          calColor,
                                          0.7,
                                        ),
                                        fontWeight: PFontWeight.semi,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if ((e.groupName ?? '').isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              e.groupName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PTypo.micro.copyWith(color: t.fgTertiary),
                            ),
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: t.bgSunken,
                            borderRadius: PRadius.brFull,
                          ),
                          child: Text(
                            ddLabel,
                            style: PTypo.micro.copyWith(
                              color: dd >= 0 && dd <= 3
                                  ? t.statusDanger
                                  : t.fgTertiary,
                              fontWeight: PFontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      e.title,
                      style: PTypo.h3.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                        letterSpacing: -0.4,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 시간 블록 — 시작 → 종료 (sunken 박스)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brMd,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.calStartDate,
                      style: PTypo.micro.copyWith(
                        color: t.fgTertiary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shortDate(start),
                      style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    if (!allDay) ...[
                      const SizedBox(height: 2),
                      Text(
                        hm(start),
                        style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Icon(LucideIcons.arrowRight, size: 16, color: t.fgTertiary),
                    if (allDay || durLabel != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        allDay ? l.calAllDay : durLabel!,
                        style: PTypo.micro.copyWith(
                          color: t.fgTertiary,
                          fontWeight: PFontWeight.semi,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l.calEndDate,
                      style: PTypo.micro.copyWith(
                        color: t.fgTertiary,
                        fontWeight: PFontWeight.semi,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shortDate(sameDay ? start : end),
                      style: PTypo.body.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    if (!allDay) ...[
                      const SizedBox(height: 2),
                      Text(
                        hm(end),
                        style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Detail rows — 장소/라벨(있을 때만) · 반복(항상). 알림은 이벤트 응답에 없어 생략.
        if (location.isNotEmpty)
          _DetailIconRow(
            icon: LucideIcons.mapPin,
            caption: l.calLocation,
            label: location,
            bg: bg,
            fg: fg,
          ),
        if ((e.labelName ?? '').isNotEmpty)
          _DetailIconRow(
            icon: LucideIcons.tag,
            caption: l.calFieldLabel,
            label: e.labelName!,
            bg: bg,
            fg: fg,
          ),
        _DetailIconRow(
          icon: LucideIcons.repeat,
          caption: l.calDetailRepeat,
          label: _repeatLabel(l, e.rrule),
          bg: bg,
          fg: fg,
        ),
        // 메모
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: t.bgSunken,
              borderRadius: PRadius.brMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.calDetailMemo,
                  style: PTypo.micro.copyWith(
                    color: t.fgTertiary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    height: 1.55,
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

/// 원형 tone 아이콘 + 캡션/값 — design DetailRow 미러(34 원형, caption micro, label bodySm/500).
class _DetailIconRow extends StatelessWidget {
  const _DetailIconRow({
    required this.icon,
    required this.caption,
    required this.label,
    required this.bg,
    required this.fg,
  });
  final IconData icon;
  final String caption;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 15, color: fg),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: PTypo.micro.copyWith(
                    color: t.fgTertiary,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: PTypo.bodySm.copyWith(
                    color: t.fgPrimary,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
