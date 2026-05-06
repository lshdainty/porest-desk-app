import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/calendar_repository.dart';
import '../domain/calendar_event.dart';
import '../domain/event_label.dart';

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
