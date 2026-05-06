import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/calendar_repository.dart';
import '../data/event_comment_repository.dart';
import '../data/holiday_repository.dart';
import '../data/user_calendar_repository.dart';
import '../domain/calendar_aggregate.dart';
import '../domain/calendar_event.dart';
import '../domain/event_comment.dart';
import '../domain/event_label.dart';
import '../domain/holiday.dart';
import '../domain/user_calendar.dart';

final calendarRepositoryProvider =
    FutureProvider<CalendarRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return CalendarRepository(dio);
});

typedef MonthYM = ({int year, int month});

/// 월 단위 이벤트 목록.
final monthEventsProvider =
    FutureProvider.family<List<CalendarEvent>, MonthYM>((ref, key) async {
  final repo = await ref.watch(calendarRepositoryProvider.future);
  final start = '${key.year.toString().padLeft(4, '0')}-${key.month.toString().padLeft(2, '0')}-01T00:00:00';
  final lastDay = DateTime(key.year, key.month + 1, 0).day;
  final end =
      '${key.year.toString().padLeft(4, '0')}-${key.month.toString().padLeft(2, '0')}-${lastDay.toString().padLeft(2, '0')}T23:59:59';
  return repo.events(startDate: start, endDate: end);
});

final eventLabelsProvider =
    FutureProvider<List<EventLabel>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(calendarRepositoryProvider.future);
  return repo.labels();
});

/// 캘린더 통합 집계 — 단일 호출에 events/todos/expenses 묶음.
typedef AggregateRange = ({String startDate, String endDate});

final calendarAggregateProvider =
    FutureProvider.family<CalendarAggregate, AggregateRange>((ref, key) async {
  final repo = await ref.watch(calendarRepositoryProvider.future);
  return repo.aggregate(startDate: key.startDate, endDate: key.endDate);
});

/// 이벤트 코멘트 repository.
final eventCommentRepositoryProvider =
    FutureProvider<EventCommentRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return EventCommentRepository(dio);
});

/// 특정 이벤트의 코멘트 목록.
final eventCommentsProvider =
    FutureProvider.family<List<EventComment>, int>((ref, eventId) async {
  final repo = await ref.watch(eventCommentRepositoryProvider.future);
  return repo.list(eventId);
});

// ─── Holiday (#301) ─────────────────────────────────────────

final holidayRepositoryProvider =
    FutureProvider<HolidayRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return HolidayRepository(dio);
});

/// 기간 별 공휴일 (캘린더 화면 진입 시 활용).
typedef HolidayRange = ({String startDate, String endDate});

final holidayListProvider =
    FutureProvider.family<List<Holiday>, HolidayRange>((ref, key) async {
  final repo = await ref.watch(holidayRepositoryProvider.future);
  return repo.list(startDate: key.startDate, endDate: key.endDate);
});

// ─── UserCalendar (#302) ────────────────────────────────────

final userCalendarRepositoryProvider =
    FutureProvider<UserCalendarRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return UserCalendarRepository(dio);
});

final userCalendarListProvider =
    FutureProvider<List<UserCalendar>>((ref) async {
  ref.keepAlive();
  final repo = await ref.watch(userCalendarRepositoryProvider.future);
  return repo.list();
});
