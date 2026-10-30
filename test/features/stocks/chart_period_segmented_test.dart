// 차트 기간 5칸(I-13 18) — 전용 생성자만 5칸을 받고, 글자 200% 에서도 "3개월" 이 꺾이지 않는다.
// (사용자 지시 10-30: 만들기만 하고 로컬에서 돌리지 않는다 — CI 가 돈다)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/shared/ds/segmented_control/p_segmented_control.dart';

List<PSegmentedItem<String>> _items() => [
  for (final l in ['1일', '1주', '1개월', '3개월', '1년'])
    PSegmentedItem(value: l, label: l),
];

void main() {
  test('일반 생성자는 5칸을 받지 않는다', () {
    expect(
      () => PSegmentedControl<String>(
        value: '1일',
        onChanged: (_) {},
        items: _items(),
        semanticLabel: '기간',
      ),
      throwsAssertionError,
    );
  });

  testWidgets('chartPeriod — 폭 312 · 글자 200% 에서 "3개월" 한 줄', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GrooTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 312,
                child: PSegmentedControl<String>.chartPeriod(
                  value: '1일',
                  onChanged: (_) {},
                  items: _items(),
                  semanticLabel: '기간',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final label = find.byWidgetPredicate(
      (w) => w is Text && (w.data ?? '').replaceAll('⁠', '') == '3개월',
    );
    expect(label, findsOneWidget);
    expect(tester.getSize(label).height, lessThan(24), reason: '한 줄(16/22)');
    expect(tester.takeException(), isNull);
  });
}
