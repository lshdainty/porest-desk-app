import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/calendar_event.dart';
import 'package:groo_damda_app/features/dashboard/application/dashboard_providers.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';

/// 일정 삭제 확인창(I-09b 8) — ds Alert Dialog. **반복 일정은 모든 회차가 함께 지워진다고 말한다**: 서버는 일정 행 하나를 지우고
/// 회차는 그 행에서 펼쳐지므로 회차만 지우는 길이 없다. 상세 [삭제] · 수정 폼 [삭제] 가 같은 창을 쓴다.
Future<bool> confirmDeleteCalendarEvent(
  BuildContext context,
  CalendarEvent event,
) {
  final l = AppLocalizations.of(context);
  return PAlertDialog.show(
    context,
    title: l.calEventDelete,
    description: event.rrule == null
        ? l.calEventDeleteConfirm(event.title)
        : l.calEventDeleteConfirmRecurring(event.title),
    cancelLabel: l.actionCancel,
    actionLabel: l.actionDelete,
    destructive: true,
  );
}

/// [start] ~ [end] 가 걸친 모든 달(둘 다 포함).
List<MonthYM> calendarMonthsSpanned(DateTime start, DateTime end) {
  final out = <MonthYM>[];
  var y = start.year, m = start.month;
  final last = end.isBefore(start) ? start : end;
  while (y < last.year || (y == last.year && m <= last.month)) {
    out.add((year: y, month: m));
    m++;
    if (m > 12) {
      m = 1;
      y++;
    }
  }
  return out;
}

/// 일정을 쓴(저장 · 삭제) 뒤 다시 받을 달 — **반복 일정이면 받아 둔 모든 달**(회차가 다른 달에도 있다), 아니면 일정이 걸친 모든 달
/// ([ranges] — 옛 날짜 · 새 날짜). 달을 걸친 일정을 뒤쪽 달에서 고치거나 지워도 그 달 키가 함께 비워진다.
void invalidateCalendarMonths(
  WidgetRef ref, {
  required bool recurring,
  required Iterable<(DateTime, DateTime)> ranges,
}) {
  if (recurring) {
    ref.invalidate(monthEventsProvider);
    return;
  }
  final seen = <MonthYM>{};
  for (final (s, e) in ranges) {
    for (final k in calendarMonthsSpanned(s, e)) {
      if (seen.add(k)) ref.invalidate(monthEventsProvider(k));
    }
  }
}

/// 일정을 지운 뒤 다시 받을 것 — [invalidateCalendarMonths] + 홈 위젯(오늘 · 다가오는 일정)의 원본(셸 상주라 스스로 안 받는다).
void invalidateAfterCalendarEventDelete(WidgetRef ref, CalendarEvent event) {
  invalidateCalendarMonths(
    ref,
    recurring: event.rrule != null,
    ranges: [(event.start, event.end)],
  );
  ref.invalidate(dashboardSummaryProvider);
}
