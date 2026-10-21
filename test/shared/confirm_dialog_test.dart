// 확인창(03-F 1A · 03F-013a · 03A-013) — 바깥을 눌러도 닫히지 않고, 화면보다 커지면 버튼까지 전체가 스크롤되며,
// 라벨이 반 폭을 넘으면 세로로 쌓인다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/widgets/p_modal.dart';

Future<void> _open(
  WidgetTester tester, {
  required String message,
  String? confirmLabel,
  Size size = const Size(390, 844),
  bool dark = false,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? GrooTheme.dark() : GrooTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showPConfirmDialog(
              context,
              title: '삭제할까요?',
              message: message,
              confirmLabel: confirmLabel,
              destructive: true,
            ),
            child: const Text('열기'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('바깥(딤)을 눌러도 닫히지 않고 딤은 overlay-dim 이다', (tester) async {
    await _open(tester, message: '지우면 되돌릴 수 없어요.');
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('삭제할까요?'), findsOneWidget);
    final barrier = tester.widget<ModalBarrier>(find.byType(ModalBarrier).last);
    expect(barrier.color, PColors.light.overlayDim);
    expect(barrier.dismissible, isFalse);
    // 취소는 그대로 닫는다
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('삭제할까요?'), findsNothing);
  });

  testWidgets('화면보다 커지면 버튼까지 확인창 전체가 스크롤된다', (tester) async {
    await _open(
      tester,
      message: List.filled(80, '긴 안내 문장이 이어져요.').join(' '),
      size: const Size(390, 500),
    );
    expect(tester.takeException(), isNull);
    final confirm = find.text('확인');
    expect(confirm, findsOneWidget);
    // 처음에는 화면 밖에 있을 수 있다 — 스크롤하면 닿는다
    await tester.dragUntilVisible(
      confirm,
      find.byType(SingleChildScrollView).last,
      const Offset(0, -150),
    );
    expect(tester.getRect(confirm).bottom, lessThanOrEqualTo(500));
  });

  testWidgets('긴 라벨은 세로로 쌓이고 확정이 위다', (tester) async {
    await _open(tester, message: '정산 기록까지 지워요.', confirmLabel: '정산 기록 모두 삭제하기');
    expect(find.byKey(const ValueKey('confirm-stacked')), findsOneWidget);
    expect(
      tester.getRect(find.text('정산 기록 모두 삭제하기')).top,
      lessThan(tester.getRect(find.text('취소')).top),
    );
  });

  testWidgets('짧은 라벨은 한 줄에 반씩', (tester) async {
    await _open(tester, message: '지울까요?');
    expect(find.byKey(const ValueKey('confirm-stacked')), findsNothing);
    expect(
      tester.getRect(find.text('취소')).center.dy,
      tester.getRect(find.text('확인')).center.dy,
    );
  });
}
