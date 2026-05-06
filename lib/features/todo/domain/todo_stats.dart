/// 백엔드 `TodoApiDto.StatsResponse` 매핑.
class TodoStats {
  const TodoStats({
    required this.totalCount,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.todayDueCount,
    required this.overDueCount,
    required this.noteCount,
  });

  final int totalCount;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;
  final int todayDueCount;
  final int overDueCount;
  final int noteCount;

  factory TodoStats.fromJson(Map<String, dynamic> json) {
    int p(String k) => (json[k] as num?)?.toInt() ?? 0;
    return TodoStats(
      totalCount: p('totalCount'),
      pendingCount: p('pendingCount'),
      inProgressCount: p('inProgressCount'),
      completedCount: p('completedCount'),
      todayDueCount: p('todayDueCount'),
      overDueCount: p('overDueCount'),
      noteCount: p('noteCount'),
    );
  }
}
