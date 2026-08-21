// 실행 시각 필드가 탭에 반응하지 않던 원인 회귀 테스트.
// GestureDetector 는 child 가 있으면 기본 behavior 가 deferToChild 라
// child 가 IgnorePointer 면 히트테스트가 전부 실패해 onTap 이 죽는다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(HitTestBehavior? behavior, VoidCallback onTap) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: GestureDetector(
            behavior: behavior,
            onTap: onTap,
            child: const IgnorePointer(
              child: SizedBox(
                width: 200,
                height: 48,
                child: TextField(),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  testWidgets('deferToChild + IgnorePointer 면 탭이 죽는다(버그 재현)',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(null, () => taps++));
    await tester.tap(find.byType(TextField), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('behavior: opaque 면 탭이 전달된다(수정)', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(HitTestBehavior.opaque, () => taps++));
    await tester.tap(find.byType(TextField), warnIfMissed: false);
    await tester.pump();
    expect(taps, 1);
  });
}
