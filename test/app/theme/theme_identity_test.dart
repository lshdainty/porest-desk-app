// PorestTheme 은 늘 같은 ThemeData 를 돌려준다 — 부를 때마다 새로 만들면 MaterialApp 이 다시 그려질 때마다 같은 테마끼리
// 200ms 섞고(AnimatedTheme), 그동안 테마를 읽는 위젯이 매 프레임 다시 그려진다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';

void main() {
  test('light · dark 는 부를 때마다 같은 ThemeData 다', () {
    expect(identical(PorestTheme.light(), PorestTheme.light()), isTrue);
    expect(identical(PorestTheme.dark(), PorestTheme.dark()), isTrue);
    expect(identical(PorestTheme.light(), PorestTheme.dark()), isFalse);
  });

  testWidgets('MaterialApp 을 다시 그려도 테마를 섞지 않는다', (tester) async {
    var builds = 0;
    Widget app() => MaterialApp(
      theme: PorestTheme.light(),
      darkTheme: PorestTheme.dark(),
      home: Builder(
        builder: (context) {
          Theme.of(context);
          builds++;
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    final settled = builds;
    // 다시 그리기 — 테마가 같으면 섞는 애니메이션이 없어 테마를 읽는 위젯이 매 프레임 다시 그려지지 않는다
    await tester.pumpWidget(app());
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(builds - settled, lessThanOrEqualTo(1));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
