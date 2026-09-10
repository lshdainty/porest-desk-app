import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/core/sync/query_freshness.dart';
import 'package:porest_desk_app/features/calendar/data/calendar_repository.dart';
import 'package:porest_desk_app/features/calendar/data/event_comment_repository.dart';
import 'package:porest_desk_app/features/calendar/data/holiday_repository.dart';
import 'package:porest_desk_app/features/calendar/data/user_calendar_repository.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/domain/event_comment.dart';
import 'package:porest_desk_app/features/calendar/domain/event_label.dart';
import 'package:porest_desk_app/features/calendar/domain/holiday.dart';
import 'package:porest_desk_app/features/calendar/domain/user_calendar.dart';

final calendarRepositoryProvider = FutureProvider<CalendarRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return CalendarRepository(dio);
});

typedef MonthYM = ({int year, int month});

/// 월 단위 이벤트 목록.
final monthEventsProvider = FutureProvider.family<List<CalendarEvent>, MonthYM>((
  ref,
  key,
) async {
  final repo = await ref.watch(calendarRepositoryProvider.future);
  final start =
      '${key.year.toString().padLeft(4, '0')}-${key.month.toString().padLeft(2, '0')}-01T00:00:00';
  final lastDay = DateTime(key.year, key.month + 1, 0).day;
  final end =
      '${key.year.toString().padLeft(4, '0')}-${key.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}T23:59:59';
  final events = await repo.events(startDate: start, endDate: end);
  ref.markQueryFetched(ServerQuery.monthEvents);
  return events;
});

final eventLabelsProvider = FutureProvider<List<EventLabel>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(calendarRepositoryProvider.future);
  final labels = await repo.labels();
  // 이 조회를 읽는 건 캘린더 화면이 아니라 **일정 등록·수정 dialog** 다.
  // 그래도 60초 규칙에 들어 있으므로 자기 칸에 시각을 남긴다 — 안 남기면
  // 캘린더 탭에 들어갈 때마다 stale 로 읽혀 비우는 일이 반복된다.
  ref.markQueryFetched(ServerQuery.eventLabels);
  return labels;
});

/// 이벤트 코멘트 repository.
final eventCommentRepositoryProvider = FutureProvider<EventCommentRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return EventCommentRepository(dio);
});

/// 특정 이벤트의 코멘트 목록.
final eventCommentsProvider = FutureProvider.family<List<EventComment>, int>((
  ref,
  eventId,
) async {
  final repo = await ref.watch(eventCommentRepositoryProvider.future);
  return repo.list(eventId);
});

// ─── Holiday (#301) ─────────────────────────────────────────

final holidayRepositoryProvider = FutureProvider<HolidayRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return HolidayRepository(dio);
});

/// 기간 별 공휴일 (캘린더 화면 진입 시 활용).
typedef HolidayRange = ({String startDate, String endDate});

final holidayListProvider = FutureProvider.family<List<Holiday>, HolidayRange>((
  ref,
  key,
) async {
  final repo = await ref.watch(holidayRepositoryProvider.future);
  final holidays = await repo.list(
    startDate: key.startDate,
    endDate: key.endDate,
  );
  ref.markQueryFetched(ServerQuery.holidayList);
  return holidays;
});

/// 캘린더 "기타 소스 > 공휴일" 표시 on/off (세션 상태). 웹 builtin source toggle 정합.
class HolidayVisibleNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
}

final holidayVisibleProvider = NotifierProvider<HolidayVisibleNotifier, bool>(
  HolidayVisibleNotifier.new,
);

// ─── UserCalendar (#302) ────────────────────────────────────

final userCalendarRepositoryProvider = FutureProvider<UserCalendarRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return UserCalendarRepository(dio);
});

final userCalendarListProvider = FutureProvider<List<UserCalendar>>((
  ref,
) async {
  ref.keepAlive();
  final repo = await ref.watch(userCalendarRepositoryProvider.future);
  final calendars = await repo.list();
  ref.markQueryFetched(ServerQuery.userCalendarList);
  return calendars;
});

/// 캘린더 공유 멤버.
final calendarMembersProvider =
    FutureProvider.family<List<CalendarMember>, int>((ref, calendarId) async {
      final repo = await ref.watch(userCalendarRepositoryProvider.future);
      return repo.members(calendarId);
    });
