// 목록 안 특정 항목으로 스크롤 — **화면 밖이어도 간다.**
//
// 가계부 달력에서 오래된 날짜를 눌러도 아무 일이 없었다(2026-09-17). `ListView` 는
// 보이는 범위에만 element 를 만들어서, 멀리 있는 그룹의 `GlobalKey.currentContext` 가
// null 이고 `Scrollable.ensureVisible` 이 조용히 no-op 이 됐기 때문이다.
//
// 여기서 잠그는 것은 셋이다.
// - 화면 밖 항목은 애초에 context 가 없다(문제의 뿌리 — 이게 깨지면 이 헬퍼가 필요 없어진다)
// - 그런 항목도 헬퍼를 거치면 화면에 들어온다
// - 목록에 없는 항목을 불러도 죽지 않는다
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/shared/scroll/scroll_to_keyed.dart';

const _rows = 40;
const _rowHeight = 120.0;

void main() {
  late Map<int, GlobalKey> keys;
  late ScrollController ctrl;

  Future<void> pumpList(WidgetTester tester) async {
    keys = {for (var i = 0; i < _rows; i++) i: GlobalKey()};
    ctrl = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            controller: ctrl,
            children: [
              for (var i = 0; i < _rows; i++)
                KeyedSubtree(
                  key: keys[i],
                  child: SizedBox(height: _rowHeight, child: Text('day $i')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  tearDown(() => ctrl.dispose());

  testWidgets('화면 밖 항목은 context 가 없다 — 이게 문제의 뿌리다', (tester) async {
    await pumpList(tester);
    expect(keys[0]!.currentContext, isNotNull);
    expect(keys[_rows - 1]!.currentContext, isNull);
  });

  testWidgets('맨 아래 항목으로 간다', (tester) async {
    await pumpList(tester);
    const target = _rows - 1;

    scrollToKeyedItem(
      controller: ctrl,
      key: keys[target],
      index: target,
      count: _rows,
    );
    await tester.pumpAndSettle();

    expect(find.text('day $target'), findsOneWidget);
    expect(keys[target]!.currentContext, isNotNull);
  });

  testWidgets('가운데 항목으로 간다 — 아래로 갔다가 위로도 돌아온다', (tester) async {
    await pumpList(tester);

    scrollToKeyedItem(
      controller: ctrl,
      key: keys[_rows - 1],
      index: _rows - 1,
      count: _rows,
    );
    await tester.pumpAndSettle();

    // 이제 위쪽이 화면 밖이다 — 반대 방향도 되어야 한다.
    expect(keys[2]!.currentContext, isNull);
    scrollToKeyedItem(controller: ctrl, key: keys[2], index: 2, count: _rows);
    await tester.pumpAndSettle();

    expect(find.text('day 2'), findsOneWidget);
  });

  testWidgets('이미 보이는 항목은 그대로 보인다', (tester) async {
    await pumpList(tester);

    scrollToKeyedItem(controller: ctrl, key: keys[0], index: 0, count: _rows);
    await tester.pumpAndSettle();

    expect(find.text('day 0'), findsOneWidget);
  });

  testWidgets('목록에 없는 항목을 불러도 죽지 않는다', (tester) async {
    await pumpList(tester);

    scrollToKeyedItem(controller: ctrl, key: null, index: 3, count: _rows);
    scrollToKeyedItem(
      controller: ctrl,
      key: GlobalKey(),
      index: -1,
      count: _rows,
    );
    await tester.pumpAndSettle();

    // 아무 일도 안 일어났고 화면은 처음 그대로다.
    expect(find.text('day 0'), findsOneWidget);
  });
}
