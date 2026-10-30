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

/// 일정을 지운 뒤 다시 받을 것 — **반복 일정이면 받아 둔 모든 달**(회차가 다른 달에도 있다), 아니면 그 달만. 홈 위젯(오늘 · 다가오는
/// 일정)의 원본도 함께 비운다(셸 상주라 스스로 안 받는다).
void invalidateAfterCalendarEventDelete(WidgetRef ref, CalendarEvent event) {
  if (event.rrule != null) {
    ref.invalidate(monthEventsProvider);
  } else {
    ref.invalidate(
      monthEventsProvider((year: event.start.year, month: event.start.month)),
    );
  }
  ref.invalidate(dashboardSummaryProvider);
}
