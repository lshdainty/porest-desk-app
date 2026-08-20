// 확인 다이얼로그의 버튼 구성 — acknowledge 는 확인 하나만 그린다.
//
// 눈으로는 "버튼이 둘 있다" 만 보이고 그중 하나가 아무 일도 안 한다는 건 안 보인다.
// 실제로 카테고리 삭제 차단 화면이 그 상태로 굴러갔다 — 제목은 "카테고리 삭제",
// 본문은 "삭제할 수 없어요", 버튼은 눌러도 아무 일 없는 빨간 [삭제].
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

/// 다이얼로그를 여는 버튼 하나만 있는 최소 앱.
Future<void> _open(WidgetTester tester, {required bool acknowledge}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PorestTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Builder(
          builder: (ctx) => TextButton(
            onPressed: () => showPConfirmDialog(
              ctx,
              title: '삭제 불가',
              message: '하위 카테고리를 먼저 정리해 주세요.',
              acknowledge: acknowledge,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('기본은 취소·확인 둘', (tester) async {
    await _open(tester, acknowledge: false);

    expect(find.text('삭제 불가'), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
  });

  testWidgets('acknowledge 는 확인 하나만 — 취소를 그리지 않는다', (tester) async {
    await _open(tester, acknowledge: true);

    expect(find.text('삭제 불가'), findsOneWidget);
    expect(find.text('확인'), findsOneWidget);
    expect(find.text('취소'), findsNothing);
  });

  testWidgets('acknowledge 의 확인을 누르면 닫힌다 — 탈출 경로가 그 버튼이다', (tester) async {
    await _open(tester, acknowledge: true);

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('삭제 불가'), findsNothing);
  });
}
