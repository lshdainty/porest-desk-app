import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/domain/todo_meta.dart';

/// 할 일 모델 — 폰 원장이 쓰는 셈을 화면에서 꺼냈다(I-10 4 · 웹 `pages/todo/model/todo-ledger.ts` 와 같은 모양).
///
/// 달 + 거르기를 적용한 목록, 날짜 묶음, 묶음 안 차례, 오늘 남은 수, 달력 칸 표시의 판정(무엇을 그릴지만 — 그리기는
/// 화면), 상대 날. 화면은 이 파일의 값만 읽는다.

/// 마감일 없는 묶음의 열쇠 — 정렬하면 맨 뒤로 간다.
const kTodoNoDueKey = '9999-99-99';

String todoYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// 마감일의 `YYYY-MM-DD` — 없으면 null.
String? todoDueYmd(Todo t) {
  final d = t.dueDate;
  if (d == null || d.length < 10) return null;
  return d.substring(0, 10);
}

/// 거르기 상태 — 태그(묶음 키) · 우선순위 코드 · 완료 숨기기.
class TodoFilterState {
  const TodoFilterState({
    this.tags = const {},
    this.prios = const {},
    this.hideDone = false,
  });

  final Set<String> tags;
  final Set<String> prios;
  final bool hideDone;

  static const empty = TodoFilterState();

  bool get active => tags.isNotEmpty || prios.isNotEmpty || hideDone;

  TodoFilterState copyWith({
    Set<String>? tags,
    Set<String>? prios,
    bool? hideDone,
  }) => TodoFilterState(
    tags: tags ?? this.tags,
    prios: prios ?? this.prios,
    hideDone: hideDone ?? this.hideDone,
  );
}

/// 이 할 일이 속할 태그 묶음 키 — 태그가 없으면 '태그 없음' sentinel.
String todoTagOf(Todo t) => todoTagKey(t.category);

/// 월 + 거르기를 적용한 목록. 마감일 없는 할 일은 월과 무관하게 꼬리 묶음으로 낸다.
///
/// [held] — 방금 완료를 누른 줄은 '완료 숨기기' 를 켰어도 잠깐 남는다. 빠지면 아래 줄이 그 자리로 올라와 두 번째 누름이
/// 다른 할 일을 완료시킨다(QA #29).
List<Todo> monthTodos(
  List<Todo> todos,
  String ym,
  TodoFilterState filter, {
  Set<int> held = const {},
}) {
  bool pass(Todo x) =>
      (filter.tags.isEmpty || filter.tags.contains(todoTagOf(x))) &&
      (filter.prios.isEmpty || filter.prios.contains(x.priority ?? 'MEDIUM')) &&
      (!filter.hideDone || !x.done || held.contains(x.rowId));
  return [
    for (final x in todos)
      if ((todoDueYmd(x)?.startsWith(ym) ?? true) && pass(x)) x,
  ];
}

int _prioRank(String? code) => switch (code) {
  'HIGH' => 0,
  'LOW' => 2,
  _ => 1,
};

/// 묶음 안 차례(I-10 15) — 남은 일 위 · 끝낸 일 아래, 각각 우선순위(중요 → 보통 → 여유), 같으면 서버 차례(안정 정렬).
///
/// [held] — 방금 끝냄을 누른 줄은 누르기 전 자리 차례로 센다(QA #29). 낙관 갱신이 상태를 뒤집어도 잠깐 그 자리에 남아야
/// 아래 줄이 올라와 두 번째 누름을 대신 받지 않는다. 붙들기가 풀리면(700ms) 제 차례로 내려간다.
List<Todo> sortDayItems(List<Todo> items, {Set<int> held = const {}}) {
  bool doneForOrder(Todo x) => held.contains(x.rowId) ? !x.done : x.done;
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final da = doneForOrder(a.$2) ? 1 : 0;
    final db = doneForOrder(b.$2) ? 1 : 0;
    if (da != db) return da - db;
    final pa = _prioRank(a.$2.priority);
    final pb = _prioRank(b.$2.priority);
    if (pa != pb) return pa - pb;
    return a.$1 - b.$1;
  });
  return [for (final e in indexed) e.$2];
}

/// 날짜 묶음 — 열쇠는 `YYYY-MM-DD` 또는 [kTodoNoDueKey]. 열쇠는 오름차순(마감일 없음이 맨 뒤), 묶음 안은 [sortDayItems] 차례.
Map<String, List<Todo>> groupByDay(
  List<Todo> list, {
  Set<int> held = const {},
}) {
  final map = <String, List<Todo>>{};
  for (final x in list) {
    (map[todoDueYmd(x) ?? kTodoNoDueKey] ??= <Todo>[]).add(x);
  }
  final keys = map.keys.toList()..sort();
  return {for (final k in keys) k: sortDayItems(map[k]!, held: held)};
}

/// 오늘 남은(안 끝낸) 할 일 수.
int todayLeft(List<Todo> todos, String today) =>
    todos.where((x) => !x.done && todoDueYmd(x) == today).length;

/// 달력 칸 아래 표시의 판정 — 오늘: 수집 ★ 또는 남은 수 · 지난 날: 키운 별자리 ★ · 놓친 날 구름 · 남은 수 · 다 끝냄 ✓ ·
/// 오는 날: 남은 수.
sealed class TodoCellMark {
  const TodoCellMark();
}

class TodoCellCollected extends TodoCellMark {
  const TodoCellCollected(this.colorKey);
  final String colorKey;
}

class TodoCellGrown extends TodoCellMark {
  const TodoCellGrown(this.colorKey);
  final String colorKey;
}

class TodoCellMissed extends TodoCellMark {
  const TodoCellMissed();
}

class TodoCellLeft extends TodoCellMark {
  const TodoCellLeft(this.count, {required this.today});
  final int count;
  final bool today;
}

class TodoCellDone extends TodoCellMark {
  const TodoCellDone();
}

TodoCellMark? todoCellMarkOf(
  String ds,
  String today,
  Map<String, List<Todo>> byDay,
  Map<String, SkyDay> skyByDate, {
  required ConstellationToday? constToday,
}) {
  final items = byDay[ds];
  final left = items == null ? 0 : items.where((x) => !x.done).length;
  if (ds == today) {
    if (constToday?.collected == true) {
      return TodoCellCollected(constToday!.constellation.colorKey);
    }
    return left > 0 ? TodoCellLeft(left, today: true) : null;
  }
  final sky = skyByDate[ds];
  if (sky != null && sky.isGrown && sky.colorKey != null) {
    return TodoCellGrown(sky.colorKey!);
  }
  if (sky != null && sky.isWithered) return const TodoCellMissed();
  if (items != null) {
    return left > 0 ? TodoCellLeft(left, today: false) : const TodoCellDone();
  }
  return null;
}

/// 상대 날 — 오늘 · 내일 · 어제만.
enum TodoRelDay { today, tomorrow, yesterday }

TodoRelDay? todoRelDayOf(DateTime d, DateTime today) {
  final diff = dateOnly(d).difference(dateOnly(today)).inDays;
  return switch (diff) {
    0 => TodoRelDay.today,
    1 => TodoRelDay.tomorrow,
    -1 => TodoRelDay.yesterday,
    _ => null,
  };
}
