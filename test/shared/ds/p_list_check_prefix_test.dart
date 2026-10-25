// List 체크 줄 — 체크를 앞에 두고 앞 붙이개(색 점)를 같이 쓴다: 체크 24 → 12 → 점 → 제목. 높이 · 낭독이 그대로다.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/checkbox/p_checkbox.dart';
import 'package:groo_damda_app/shared/ds/list/p_list.dart';

import '../../support/plain_text.dart';

Widget _host(Widget child) => MaterialApp(
  theme: GrooTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('ko'),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: 360, child: child),
    ),
  ),
);

const _dot = SizedBox.square(
  key: ValueKey('dot'),
  dimension: 10,
  child: DecoratedBox(
    decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
  ),
);

void main() {
  testWidgets('체크 앞 + 앞 붙이개 — 체크 24 · 사이 12 · 점 · 제목 차례, 줄 높이 그대로', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        PListCheckGroup(
          semanticLabel: '캘린더',
          children: [
            PListCheckItem(
              title: '개인',
              checked: true,
              onChanged: (_) {},
              prefix: _dot,
            ),
            PListCheckItem(title: '점 없음', checked: false, onChanged: (_) {}),
          ],
        ),
      ),
    );
    final dot = tester.getRect(find.byKey(const ValueKey('dot')));
    final check = tester.getRect(find.byType(PCheckmark).first);
    final title = tester.getRect(findPlain('개인'));
    expect(check.width, 24);
    expect(check.left, 24, reason: '체크가 줄 왼쪽 24 에 선다');
    expect(dot.left - check.right, 12, reason: '체크 ↔ 점 12');
    expect(dot.width, 10);
    expect(title.left - dot.right, 12, reason: '점 ↔ 제목 12');
    // 점이 있어도 점 없는 줄과 높이가 같다(체크 24 + 위아래 12 = 최소 줄 높이)
    final rows = find.byType(PListCheckItem);
    expect(
      tester.getSize(rows.at(0)).height,
      tester.getSize(rows.at(1)).height,
    );
  });

  testWidgets('낭독 — 줄 전체가 체크 하나로 읽히고 점은 읽지 않는다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        PListCheckGroup(
          semanticLabel: '캘린더',
          children: [
            PListCheckItem(
              title: '개인',
              checked: true,
              onChanged: (_) {},
              prefix: _dot,
            ),
          ],
        ),
      ),
    );
    final node = find.semantics.byLabel(RegExp('개인')).evaluate().single;
    expect(node.label, contains('개인'));
    expect(node.getSemanticsData().hasFlag(SemanticsFlag.isChecked), isTrue);
    handle.dispose();
  });

  testWidgets('체크 앞 + 앞 붙이개 줄을 눌러도 바뀐다', (tester) async {
    var v = false;
    await tester.pumpWidget(
      _host(
        PListCheckItem(
          title: '개인',
          checked: v,
          onChanged: (n) => v = n,
          prefix: _dot,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('dot')));
    expect(v, isTrue);
  });
}
