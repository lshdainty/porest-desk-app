/// 백엔드 `DashboardApiDto.SummaryResponse` 매핑 (plain class).
library;

class TodoCountSummary {
  const TodoCountSummary({
    required this.totalCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.todayDueCount,
    required this.overDueCount,
  });
  final int totalCount;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;
  final int todayDueCount;
  final int overDueCount;
  factory TodoCountSummary.fromJson(Map<String, dynamic> j) {
    int p(String k) => (j[k] as num?)?.toInt() ?? 0;
    return TodoCountSummary(
      totalCount: p('totalCount'),
      pendingCount: p('pendingCount'),
      inProgressCount: p('inProgressCount'),
      completedCount: p('completedCount'),
      todayDueCount: p('todayDueCount'),
      overDueCount: p('overDueCount'),
    );
  }
}

class CalendarCountSummary {
  const CalendarCountSummary({
    required this.todayEventCount,
    required this.upcomingEventCount,
    this.nextEventDate,
  });
  final int todayEventCount;
  final int upcomingEventCount;
  final String? nextEventDate; // YYYY-MM-DD
  factory CalendarCountSummary.fromJson(Map<String, dynamic> j) =>
      CalendarCountSummary(
        todayEventCount: (j['todayEventCount'] as num?)?.toInt() ?? 0,
        upcomingEventCount:
            (j['upcomingEventCount'] as num?)?.toInt() ?? 0,
        nextEventDate: j['nextEventDate'] as String?,
      );
}

class ExpenseCountSummary {
  const ExpenseCountSummary({
    required this.todayIncome,
    required this.todayExpense,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });
  final int todayIncome;
  final int todayExpense;
  final int monthlyIncome;
  final int monthlyExpense;
  factory ExpenseCountSummary.fromJson(Map<String, dynamic> j) =>
      ExpenseCountSummary(
        todayIncome: (j['todayIncome'] as num?)?.toInt() ?? 0,
        todayExpense: (j['todayExpense'] as num?)?.toInt() ?? 0,
        monthlyIncome: (j['monthlyIncome'] as num?)?.toInt() ?? 0,
        monthlyExpense: (j['monthlyExpense'] as num?)?.toInt() ?? 0,
      );
}

class MemoCountSummary {
  const MemoCountSummary({
    required this.totalCount,
    required this.pinnedCount,
    this.recentMemoTitle,
  });
  final int totalCount;
  final int pinnedCount;
  final String? recentMemoTitle;
  factory MemoCountSummary.fromJson(Map<String, dynamic> j) => MemoCountSummary(
        totalCount: (j['totalCount'] as num?)?.toInt() ?? 0,
        pinnedCount: (j['pinnedCount'] as num?)?.toInt() ?? 0,
        recentMemoTitle: j['recentMemoTitle'] as String?,
      );
}

class UpcomingEvent {
  const UpcomingEvent({
    required this.rowId,
    required this.title,
    this.eventType,
    this.color,
    this.startDate,
    required this.daysUntil,
  });
  final int rowId;
  final String title;
  final String? eventType;
  final String? color;
  final String? startDate; // ISO datetime
  final int daysUntil;
  factory UpcomingEvent.fromJson(Map<String, dynamic> j) => UpcomingEvent(
        rowId: (j['rowId'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        eventType: j['eventType'] as String?,
        color: j['color'] as String?,
        startDate: j['startDate'] as String?,
        daysUntil: (j['daysUntil'] as num?)?.toInt() ?? 0,
      );
}

class RecentTodo {
  const RecentTodo({
    required this.rowId,
    required this.title,
    this.priority,
    this.status,
    this.dueDate,
  });
  final int rowId;
  final String title;
  final String? priority;
  final String? status;
  final String? dueDate; // YYYY-MM-DD
  factory RecentTodo.fromJson(Map<String, dynamic> j) => RecentTodo(
        rowId: (j['rowId'] as num).toInt(),
        title: (j['title'] as String?) ?? '',
        priority: j['priority'] as String?,
        status: j['status'] as String?,
        dueDate: j['dueDate'] as String?,
      );
}

class DailyExpenseTrendPoint {
  const DailyExpenseTrendPoint({
    required this.date,
    required this.income,
    required this.expense,
  });
  final String date;
  final int income;
  final int expense;
  factory DailyExpenseTrendPoint.fromJson(Map<String, dynamic> j) =>
      DailyExpenseTrendPoint(
        date: (j['date'] as String?) ?? '',
        income: (j['income'] as num?)?.toInt() ?? 0,
        expense: (j['expense'] as num?)?.toInt() ?? 0,
      );
}

class DashboardSummary {
  const DashboardSummary({
    required this.todoSummary,
    required this.calendarSummary,
    required this.expenseSummary,
    required this.memoSummary,
    this.upcomingEvents = const [],
    this.recentTodos = const [],
    this.expenseTrend = const [],
  });
  final TodoCountSummary todoSummary;
  final CalendarCountSummary calendarSummary;
  final ExpenseCountSummary expenseSummary;
  final MemoCountSummary memoSummary;
  final List<UpcomingEvent> upcomingEvents;
  final List<RecentTodo> recentTodos;
  final List<DailyExpenseTrendPoint> expenseTrend;
  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    List<T> mapList<T>(String k, T Function(Map<String, dynamic>) f) {
      final raw = (j[k] as List?) ?? const [];
      return raw
          .map((e) => f(e as Map<String, dynamic>))
          .toList(growable: false);
    }

    return DashboardSummary(
      todoSummary:
          TodoCountSummary.fromJson(j['todoSummary'] as Map<String, dynamic>? ?? const {}),
      calendarSummary: CalendarCountSummary.fromJson(
          j['calendarSummary'] as Map<String, dynamic>? ?? const {}),
      expenseSummary: ExpenseCountSummary.fromJson(
          j['expenseSummary'] as Map<String, dynamic>? ?? const {}),
      memoSummary:
          MemoCountSummary.fromJson(j['memoSummary'] as Map<String, dynamic>? ?? const {}),
      upcomingEvents: mapList('upcomingEvents', UpcomingEvent.fromJson),
      recentTodos: mapList('recentTodos', RecentTodo.fromJson),
      expenseTrend: mapList('expenseTrend', DailyExpenseTrendPoint.fromJson),
    );
  }
}
