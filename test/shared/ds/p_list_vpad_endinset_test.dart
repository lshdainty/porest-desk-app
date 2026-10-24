import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

Future<void> _pump(WidgetTester t, Widget row) async {
  t.view.physicalSize = const Size(360, 400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: GrooTheme.light(),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: row),
      ),
    ),
  );
}

void main() {
  testWidgets(
    '08-1 verticalPadding(키-값 줄 8)과 07-1 endInset 이 함께 산다 — 기본값은 그대로',
    (t) async {
      const mark = SizedBox(key: ValueKey('end'), width: 40, height: 20);
      await _pump(t, const PListItem(title: '기본', suffix: mark));
      final base = t.getSize(find.byType(PListItem)).height;
      final baseRight = t.getTopRight(find.byKey(const ValueKey('end'))).dx;
      expect(baseRight, 360 - 24, reason: '기본 끝 여백 24');

      await _pump(
        t,
        const PListItem(title: '키-값', suffix: mark, verticalPadding: 8),
      );
      expect(
        t.getSize(find.byType(PListItem)).height,
        base - 8,
        reason: '위아래 8 → 4+4 줄어든다',
      );
      expect(t.getTopRight(find.byKey(const ValueKey('end'))).dx, 360 - 24);

      await _pump(
        t,
        const PListItem(
          title: '둘 다',
          suffix: mark,
          verticalPadding: 8,
          endInset: 16,
        ),
      );
      expect(t.getSize(find.byType(PListItem)).height, base - 8);
      expect(t.getTopRight(find.byKey(const ValueKey('end'))).dx, 360 - 16);
      expect(t.getRect(find.byType(PListItem)).right, 360, reason: '줄은 화면 끝까지');
    },
  );

  testWidgets('PListButtonItem 통로도 endInset 이 끝 여백을 정하고 줄은 화면 끝까지 간다', (
    t,
  ) async {
    const mark = SizedBox(key: ValueKey('end'), width: 40, height: 20);
    await _pump(
      t,
      PListButtonItem(title: '누르는 줄', suffix: mark, endInset: 16, onTap: () {}),
    );
    expect(t.getRect(find.byType(PListButtonItem)).right, 360);
    expect(t.getTopRight(find.byKey(const ValueKey('end'))).dx, 360 - 16);
    await _pump(t, PListButtonItem(title: '기본', suffix: mark, onTap: () {}));
    expect(t.getTopRight(find.byKey(const ValueKey('end'))).dx, 360 - 24);
  });
}
