import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 스낵바는 화면을 띄워 봐야 깨지는 게 보인다 — Material 은 behavior/padding/margin
/// 조합에 assert 가 걸려 있어 analyze 로는 안 잡힌다.
///
/// 색 자체보다 "severity 색으로 배경을 칠하지 않는다" 를 못 박는다. 예전엔 성공 한 번에
/// 화면 하단이 통째로 초록 막대가 됐다.
Widget _host(void Function(BuildContext) onTap, {Brightness? brightness}) {
  return MaterialApp(
    theme: brightness == Brightness.dark
        ? PorestTheme.dark()
        : PorestTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () => onTap(context),
            child: const Text('show'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  for (final severity in PSnackSeverity.values) {
    testWidgets('$severity — 예외 없이 뜨고 메시지가 보인다', (tester) async {
      await tester.pumpWidget(
        _host((c) => showPSnackBar(c, '테스트 메시지', severity: severity)),
      );
      await tester.tap(find.text('show'));
      await tester.pump(); // 스낵바 삽입
      await tester.pump(const Duration(milliseconds: 400)); // 등장 애니메이션

      expect(find.text('테스트 메시지'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('severity 색이 배경이 아니라 아이콘에만 쓰인다', (tester) async {
    await tester.pumpWidget(
      _host((c) =>
          showPSnackBar(c, '저장했어요', severity: PSnackSeverity.success)),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Material SnackBar 자체는 투명 — 색은 우리가 그린 컨테이너가 쥔다.
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.backgroundColor, Colors.transparent);

    // 아이콘이 붙어야 성공을 알아볼 수 있다(neutral 만 아이콘 없음).
    expect(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Icon)),
      findsOneWidget,
    );
  });

  testWidgets('neutral 은 아이콘 없이 글만', (tester) async {
    await tester.pumpWidget(_host((c) => showPSnackBar(c, '그냥 알림')));
    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.descendant(of: find.byType(SnackBar), matching: find.byType(Icon)),
      findsNothing,
    );
  });

  testWidgets('다크 모드에서도 예외 없이 뜬다', (tester) async {
    await tester.pumpWidget(
      _host(
        (c) => showPSnackBar(c, '다크', severity: PSnackSeverity.error),
        brightness: Brightness.dark,
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('다크'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
