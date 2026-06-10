import 'package:porest_desk_app/features/expense/domain/expense.dart';
import 'package:porest_desk_app/features/todo/domain/todo.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';

/// 캘린더 통합 집계 응답 — `CalendarAggregateApiDto.AggregateResponse` 매핑.
///
/// 단일 호출(GET /calendar/aggregate?startDate&endDate)로 events/todos/expenses
/// 3종 데이터를 가져와 캘린더 화면 진입 시 N+1 호출을 1로 축소.
class CalendarAggregate {
  const CalendarAggregate({
    required this.events,
    required this.todos,
    required this.expenses,
  });

  final List<CalendarEvent> events;
  final List<Todo> todos;
  final List<Expense> expenses;

  factory CalendarAggregate.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
      final raw = (json[key] as List?) ?? const [];
      return raw
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    return CalendarAggregate(
      events: mapList('events', CalendarEvent.fromJson),
      todos: mapList('todos', Todo.fromJson),
      expenses: mapList('expenses', Expense.fromJson),
    );
  }
}
