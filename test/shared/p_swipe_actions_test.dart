import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_swipe_actions.dart';

/// 스와이프는 제스처라 눈으로만 확인하기 어렵다. 특히 <b>안 일어나야 하는 일</b>이
/// 중요하다 — 끝까지 밀어도 지워지지 않고, 확인을 거치지 않으면 실행되지 않는다.
/// 이게 무너지면 사용자가 밀다가 데이터를 잃는다.
Widget _host(List<PSwipeAction> actions, {String label = '행'}) {
  return MaterialApp(
    theme: PorestTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: SlidableAutoCloseBehavior(
        child: ListView(
          children: [
            PSwipeActions(
              actions: actions,
              child: SizedBox(height: 64, child: Center(child: Text(label))),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 트레이가 열릴 만큼 왼쪽으로 민다.
Future<void> _swipeOpen(WidgetTester tester, String label) async {
  await tester.drag(find.text(label), const Offset(-250, 0));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('밀면 액션이 드러난다', (tester) async {
    await tester.pumpWidget(_host([
      PSwipeAction(label: '편집', kind: PSwipeKind.primary, onSelect: () {}),
    ]));

    expect(find.text('편집'), findsNothing); // 접혀 있을 땐 안 보인다
    await _swipeOpen(tester, '행');
    expect(find.text('편집'), findsOneWidget);
  });

  testWidgets('확인 문구가 없는 액션은 바로 실행된다', (tester) async {
    var ran = false;
    await tester.pumpWidget(_host([
      PSwipeAction(label: '편집', kind: PSwipeKind.primary, onSelect: () => ran = true),
    ]));

    await _swipeOpen(tester, '행');
    await tester.tap(find.text('편집'));
    await tester.pumpAndSettle();

    expect(ran, isTrue);
  });

  testWidgets('삭제는 확인을 받는다 — 누르는 즉시 실행되지 않는다', (tester) async {
    var deleted = false;
    await tester.pumpWidget(_host([
      PSwipeAction(
        label: '삭제',
        kind: PSwipeKind.destructive,
        confirmMessage: '정말 지울까요?',
        onSelect: () => deleted = true,
      ),
    ]));

    await _swipeOpen(tester, '행');
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    // 다이얼로그가 떴을 뿐 아직 안 지워졌다
    expect(find.text('정말 지울까요?'), findsOneWidget);
    expect(deleted, isFalse);
  });

  testWidgets('확인을 취소하면 실행되지 않는다', (tester) async {
    var deleted = false;
    await tester.pumpWidget(_host([
      PSwipeAction(
        label: '삭제',
        kind: PSwipeKind.destructive,
        confirmMessage: '정말 지울까요?',
        onSelect: () => deleted = true,
      ),
    ]));

    await _swipeOpen(tester, '행');
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
  });

  testWidgets('확인하면 실행된다', (tester) async {
    var deleted = false;
    await tester.pumpWidget(_host([
      PSwipeAction(
        label: '삭제',
        kind: PSwipeKind.destructive,
        confirmMessage: '정말 지울까요?',
        onSelect: () => deleted = true,
      ),
    ]));

    await _swipeOpen(tester, '행');
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    // 확인 버튼 라벨은 액션 이름이라 트레이의 '삭제' 와 같다 — 다이얼로그 안의 것을 고른다.
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(PButton, '삭제'),
    ));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });

  testWidgets('끝까지 밀어도 실행되지 않는다 — 되돌리기가 없다', (tester) async {
    var deleted = false;
    await tester.pumpWidget(_host([
      PSwipeAction(
        label: '삭제',
        kind: PSwipeKind.destructive,
        confirmMessage: '정말 지울까요?',
        onSelect: () => deleted = true,
      ),
    ]));

    // 화면 밖까지 크게 민다 — DismissiblePane 을 썼다면 여기서 지워진다
    await tester.drag(find.text('행'), const Offset(-2000, 0));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(find.text('행'), findsOneWidget); // 행이 사라지지도 않았다
  });

  testWidgets('enabled=false 면 감싸지 않고 행을 그대로 통과시킨다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: PorestTheme.light(),
      home: Scaffold(
        body: PSwipeActions(
          enabled: false,
          actions: [PSwipeAction(label: '삭제', onSelect: () {})],
          child: const Text('행'),
        ),
      ),
    ));

    // 데스크톱·태블릿에서 래핑 자체를 걷어내는 경로
    expect(find.byType(Slidable), findsNothing);
    expect(find.text('행'), findsOneWidget);
  });

  testWidgets('액션이 없으면 감싸지 않는다', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: PorestTheme.light(),
      home: const Scaffold(
        body: PSwipeActions(actions: [], child: Text('행')),
      ),
    ));

    expect(find.byType(Slidable), findsNothing);
  });
}
