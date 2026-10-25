// 할 일 모델 — 월 + 거르기 · 묶음 안 차례(남은 일 위 · 끝낸 일 아래) · 붙들기(QA #29) · 달력 칸 표시 판정.
// 웹 `todo-ledger.test.ts` 와 같은 사례를 같은 이름으로 잠근다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/constellation/domain/constellation.dart';
import 'package:groo_damda_app/features/todo/domain/todo.dart';
import 'package:groo_damda_app/features/todo/domain/todo_ledger.dart';
import 'package:groo_damda_app/features/todo/domain/todo_meta.dart';

Todo _t(
  int id, {
  String? due = '2026-10-22',
  String prio = 'MEDIUM',
  bool done = false,
  String? tag,
}) => Todo(
  rowId: id,
  title: '할 일 $id',
  dueDate: due,
  priority: prio,
  status: done ? 'COMPLETED' : 'PENDING',
  category: tag,
);

void main() {
  group('monthTodos', () {
    final all = [
      _t(1, due: '2026-10-03', tag: '업무'),
      _t(2, due: '2026-11-03'),
      _t(3, due: null, done: true),
      _t(4, due: '2026-10-09', prio: 'HIGH', done: true),
    ];

    test('그 달 + 마감일 없는 할 일(월과 무관)', () {
      final r = monthTodos(all, '2026-10', TodoFilterState.empty);
      expect(r.map((x) => x.rowId), [1, 3, 4]);
    });

    test('태그 · 우선순위 · 완료 숨기기를 모두 만족해야 한다', () {
      const f = TodoFilterState(tags: {'업무'}, prios: {'MEDIUM'});
      expect(monthTodos(all, '2026-10', f).map((x) => x.rowId), [1]);
      const g = TodoFilterState(hideDone: true);
      expect(monthTodos(all, '2026-10', g).map((x) => x.rowId), [1]);
    });

    test('태그 없음 sentinel 로 태그 없는 할 일만 거른다', () {
      const f = TodoFilterState(tags: {kTodoNoTagKey});
      expect(monthTodos(all, '2026-10', f).map((x) => x.rowId), [3, 4]);
    });

    test('붙든 줄은 완료 숨기기를 켜도 남는다', () {
      const g = TodoFilterState(hideDone: true);
      expect(monthTodos(all, '2026-10', g, held: {4}).map((x) => x.rowId), [
        1,
        4,
      ]);
    });
  });

  group('sortDayItems', () {
    test('남은 일 위 · 끝낸 일 아래, 각각 중요 → 보통 → 여유, 같으면 서버 차례', () {
      final items = [
        _t(1, prio: 'LOW'),
        _t(2, done: true, prio: 'HIGH'),
        _t(3, prio: 'HIGH'),
        _t(4, prio: 'MEDIUM'),
        _t(5, prio: 'MEDIUM'),
        _t(6, done: true, prio: 'LOW'),
      ];
      expect(sortDayItems(items).map((x) => x.rowId), [3, 4, 5, 1, 2, 6]);
    });

    test('붙든 줄은 누르기 전 자리 차례로 센다 — 낙관 갱신으로 끝내도 아래로 안 간다', () {
      // 3 번을 방금 눌러 끝냄이 됐지만 아직 700ms 안이다.
      final items = [_t(3, prio: 'HIGH', done: true), _t(4, prio: 'MEDIUM')];
      expect(sortDayItems(items).map((x) => x.rowId), [4, 3]);
      expect(sortDayItems(items, held: {3}).map((x) => x.rowId), [3, 4]);
    });

    test('QA #29 — 따닥 누른 두 번째 누름이 다른 할 일을 완료시키지 않는다', () {
      // 첫 줄이 끝냄으로 바뀐 직후에도 그 줄이 제자리라 같은 자리의 두 번째 누름은 같은 줄에 떨어진다.
      final before = [_t(1), _t(2), _t(3)];
      final after = [_t(1, done: true), _t(2), _t(3)];
      final held = sortDayItems(after, held: {1});
      expect(held.first.rowId, before.first.rowId);
      // 붙들기가 풀리면 제 차례(아래)로 간다.
      expect(sortDayItems(after).map((x) => x.rowId), [2, 3, 1]);
    });
  });

  group('groupByDay', () {
    test('열쇠 오름차순, 마감일 없음이 맨 뒤, 묶음 안은 sortDayItems', () {
      final g = groupByDay([
        _t(1, due: '2026-10-05', done: true),
        _t(2, due: null),
        _t(3, due: '2026-10-05'),
        _t(4, due: '2026-10-01'),
      ]);
      expect(g.keys.toList(), ['2026-10-01', '2026-10-05', kTodoNoDueKey]);
      expect(g['2026-10-05']!.map((x) => x.rowId), [3, 1]);
    });
  });

  test('todayLeft 는 오늘 안 끝낸 것만 센다', () {
    expect(
      todayLeft([
        _t(1),
        _t(2, done: true),
        _t(3, due: '2026-10-23'),
      ], '2026-10-22'),
      1,
    );
  });

  group('todoCellMarkOf', () {
    final byDay = {
      '2026-10-21': [_t(1, due: '2026-10-21', done: true)],
      '2026-10-22': [_t(2), _t(3)],
      '2026-10-24': [_t(4, due: '2026-10-24')],
    };
    const grown = SkyDay(
      date: '2026-10-19',
      status: 'GROWN',
      constellationKey: 'orion',
      colorKey: 'blue',
      points: 5,
      guardUsed: false,
    );
    const withered = SkyDay(
      date: '2026-10-20',
      status: 'WITHERED',
      constellationKey: null,
      colorKey: null,
      points: 0,
      guardUsed: false,
    );
    final sky = {'2026-10-19': grown, '2026-10-20': withered};

    TodoCellMark? m(String ds) =>
        todoCellMarkOf(ds, '2026-10-22', byDay, sky, constToday: null);

    test('오늘 — 남은 수(오늘 표시)', () {
      final r = m('2026-10-22');
      expect(r, isA<TodoCellLeft>());
      expect((r! as TodoCellLeft).count, 2);
      expect((r as TodoCellLeft).today, isTrue);
    });
    test('지난 날 — 별자리 · 놓친 날 · 다 끝냄', () {
      expect(m('2026-10-19'), isA<TodoCellGrown>());
      expect(m('2026-10-20'), isA<TodoCellMissed>());
      expect(m('2026-10-21'), isA<TodoCellDone>());
    });
    test('오는 날 — 남은 수, 없으면 표시 없음', () {
      expect((m('2026-10-24')! as TodoCellLeft).today, isFalse);
      expect(m('2026-10-25'), isNull);
    });
  });

  test('todoRelDayOf 는 오늘 · 내일 · 어제만', () {
    final today = DateTime(2026, 10, 22);
    expect(todoRelDayOf(DateTime(2026, 10, 22), today), TodoRelDay.today);
    expect(todoRelDayOf(DateTime(2026, 10, 23), today), TodoRelDay.tomorrow);
    expect(todoRelDayOf(DateTime(2026, 10, 21), today), TodoRelDay.yesterday);
    expect(todoRelDayOf(DateTime(2026, 10, 25), today), isNull);
  });
}
