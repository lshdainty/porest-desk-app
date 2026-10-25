import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/format/chart_palette.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/calendar/application/calendar_providers.dart';
import 'package:groo_damda_app/features/calendar/domain/user_calendar.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/badge/p_badge.dart';
import 'package:groo_damda_app/shared/ds/bottom_sheet/p_bottom_sheet.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_header.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';

/// 캘린더 고르기 시트(I-09 7) — 내 캘린더 · 기타 소스(공휴일) · "캘린더 관리 · 공유 설정". 구조와 동작은 그대로,
/// 부품만 ds(Bottom Sheet 고르기 · List 체크 줄 · List Header)다.
Future<void> showCalendarFilterSheet(
  BuildContext context, {
  required VoidCallback onManage,
}) {
  return PBottomSheet.show<void>(
    context,
    builder: (_) => _CalendarFilterSheet(onManage: onManage),
  );
}

class _CalendarFilterSheet extends ConsumerWidget {
  const _CalendarFilterSheet({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.colors;
    final calendars =
        ref.watch(userCalendarListProvider).value ?? const <UserCalendar>[];
    final holidayVisible = ref.watch(holidayVisibleProvider);

    Future<void> toggle(UserCalendar cal) async {
      try {
        final repo = await ref.read(userCalendarRepositoryProvider.future);
        await repo.toggleVisibility(cal.rowId);
        ref.invalidate(userCalendarListProvider);
      } on ApiException {
        // 서버 에러는 ErrorToastInterceptor 가 띄운다.
      } catch (_) {
        // API 가 아닌 예외는 인터셉터가 못 잡는다 — 여기서 알린다.
        if (context.mounted) {
          showPSnackBar(
            context,
            l.calUpdateFailed,
            severity: PSnackSeverity.error,
          );
        }
      }
    }

    return PBottomSheetContent(
      title: l.calFieldCalendar,
      closeLabel: l.actionClose,
      flushBody: true,
      scrollFog: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          PListHeader(
            title: l.calMyCalendars,
            variant: PListHeaderVariant.boldSolid,
          ),
          if (calendars.isEmpty)
            PList(
              semanticLabel: l.calMyCalendars,
              children: [PListItem(title: l.calNoCalendars)],
            )
          else
            PListCheckGroup(
              semanticLabel: l.calMyCalendars,
              children: [
                for (final cal in calendars)
                  // 기본 캘린더는 표시를 끌 수 없다 — 서버가 이 토글을 400 으로 막는다. 체크 없이 늘 켜진 줄로
                  // 두고 "기본" 배지로 왜 이 줄만 다른지 남긴다(9-09 사용자 결정).
                  if (cal.isDefault)
                    PListItem(
                      title: cal.calendarName,
                      // 체크 자리(24)에 늘 켜진 표식(캘린더 색 체크 16) — 끌 수 없는 줄이고 이름이 체크 줄과 한 세로선에 선다(웹과 같다)
                      prefix: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: PSpacing.x3,
                        children: [
                          ExcludeSemantics(
                            child: SizedBox(
                              key: const ValueKey(
                                'calendar-filter-default-mark',
                              ),
                              width: PSpacing.x6,
                              height: PSpacing.x6,
                              child: Center(
                                child: Icon(
                                  LucideIcons.check,
                                  size: PSpacing.x4,
                                  color: chartToneOf(context, cal.color).solid,
                                ),
                              ),
                            ),
                          ),
                          _Dot(chartToneOf(context, cal.color).solid),
                        ],
                      ),
                      titleSuffix: [PBadge(label: l.calDefault)],
                    )
                  else
                    PListCheckItem(
                      title: cal.calendarName,
                      checked: cal.isVisible,
                      onChanged: (_) => toggle(cal),
                      prefix: _Dot(chartToneOf(context, cal.color).solid),
                    ),
              ],
            ),
          PListHeader(
            title: l.calOtherSources,
            variant: PListHeaderVariant.boldSolid,
          ),
          PListCheckGroup(
            semanticLabel: l.calOtherSources,
            children: [
              PListCheckItem(
                title: l.calHolidays,
                checked: holidayVisible,
                onChanged: (_) =>
                    ref.read(holidayVisibleProvider.notifier).toggle(),
                prefix: ExcludeSemantics(
                  child: Icon(
                    LucideIcons.flag,
                    size: PSpacing.x4,
                    color: chartToneOfKey(context, 'red').solid,
                  ),
                ),
              ),
            ],
          ),
          // 화면을 옮기는 줄 — 오른쪽 꺾쇠. 사이 Separator 는 목록 제목이 가르므로 두지 않는다.
          PList(
            children: [
              PListButtonItem(
                title: l.calManageShareSettings,
                suffix: Icon(
                  LucideIcons.chevronRight,
                  color: c.fgNeutralSubtle,
                ),
                onTap: () {
                  PBottomSheet.of(context).close();
                  onManage();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 줄 앞 캘린더 색 점 — 지름 10.
class _Dot extends StatelessWidget {
  const _Dot(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    // 공휴일 줄 flag(16) 와 이름이 한 세로선에 서도록 점(10)을 16 칸 가운데에 둔다
    child: SizedBox(
      key: const ValueKey('calendar-filter-row-dot'),
      width: PSpacing.x4,
      child: Center(
        child: Container(
          width: PSpacing.x2_5,
          height: PSpacing.x2_5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    ),
  );
}
