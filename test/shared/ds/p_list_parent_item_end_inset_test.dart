// PListParentItem 의 endInset(줄 오른쪽 끝 여백 — PListItem 과 같은 이름 · 같은 뜻) · readOnly(보기만 하는 줄 — 보통 색, 누름 막힘).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';
import 'package:groo_damda_app/shared/ds/list/p_list_parent_item.dart';

Widget _app(Widget child) => MaterialApp(
  theme: GrooTheme.light(),
  home: Scaffold(
    body: SizedBox(width: 360, child: PList(children: [child])),
  ),
);

Color _titleColor(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const ValueKey('plist-title')))
    .style!
    .color!;

void main() {
  const grip = SizedBox.square(key: ValueKey('grip'), dimension: 40);

  Future<double> gripRight(WidgetTester tester, {double? endInset}) async {
    tester.view.physicalSize = const Size(360, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        PListParentItem(
          title: '식비',
          onTap: () {},
          collapsible: false,
          suffix: grip,
          endInset: endInset,
        ),
      ),
    );
    return tester.getRect(find.byKey(const ValueKey('grip'))).right;
  }

  testWidgets('endInset — 값이 없으면 좌우 여백 24, 주면 그 값만큼 끝에서 떨어진다', (tester) async {
    expect(await gripRight(tester), 360 - PSpacing.globalGutter);
    expect(await gripRight(tester, endInset: PSpacing.x3), 360 - PSpacing.x3);
    expect(await gripRight(tester, endInset: 0), 360);
  });

  testWidgets('readOnly — 누르지 못하고 글 색은 보통 줄과 같다(막힌 줄과 다르다)', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        PListParentItem(
          title: '식비',
          onTap: () => taps++,
          collapsible: false,
          readOnly: true,
        ),
      ),
    );
    final readOnlyColor = _titleColor(tester);
    await tester.tap(find.byKey(const ValueKey('plist-title')));
    expect(taps, 0);

    await tester.pumpWidget(
      _app(PListParentItem(title: '식비', onTap: () {}, collapsible: false)),
    );
    final normalColor = _titleColor(tester);
    await tester.pumpWidget(
      _app(PListParentItem(title: '식비', onTap: null, collapsible: false)),
    );
    final disabledColor = _titleColor(tester);
    expect(readOnlyColor, normalColor);
    expect(disabledColor, isNot(normalColor));
  });
}
