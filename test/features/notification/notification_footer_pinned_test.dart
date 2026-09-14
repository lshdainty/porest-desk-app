// 알림 화면의 '알림 설정 ›' 는 **바닥에 고정**이고 가운데 목록만 스크롤한다
// (사용자 신고 2026-09-14 — 알림 다섯 개 바로 아래에 붙어 같이 흘러갔다).
//
// 원래는 헤더·행·footer 를 한 ListView 의 children 으로 넣고 있었다. 목록이 짧으면
// footer 가 목록 끝(화면 가운데쯤)에 붙고, 길면 끝까지 내려야 보였다.
//
// 위젯 테스트는 레이아웃이 있으므로 **실제로 재서** 잠근다 — 스크롤 전후의
// footer dy 가 같고, 그 값이 화면 바닥에 닿아 있는지.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/notification/application/notification_providers.dart';
import 'package:porest_desk_app/features/notification/domain/notification.dart';
import 'package:porest_desk_app/features/notification/presentation/notification_screen.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

List<AppNotification> _items(int n) => [
  for (int i = 0; i < n; i++)
    AppNotification(
      rowId: i + 1,
      title: '알림 ${i + 1}',
      message: '내용 ${i + 1}',
      isRead: i > 2,
      createAt: '2026-09-14T00:00:00',
      notificationType: 'BUDGET',
    ),
];

Future<void> _pump(WidgetTester tester, List<AppNotification> items) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        builder: (_, _) => const SizedBox.shrink(),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationListProvider.overrideWith((ref) async => items),
        unreadCountProvider.overrideWith(
          (ref) async => items.where((n) => !n.isRead).length,
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// footer 상자 — '알림 설정' 버튼을 감싼 Container.
Finder _footer() =>
    find.ancestor(of: find.text('알림 설정'), matching: find.byType(Container));

void main() {
  testWidgets('행이 20개여도 footer 는 화면 바닥에 있다', (tester) async {
    await _pump(tester, _items(20));

    final screenH =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final footer = tester.getRect(_footer().first);

    // 목록 끝에 붙어 있었다면 화면 밖(아래)으로 밀려 아예 안 보인다.
    expect(_footer(), findsWidgets, reason: 'footer 가 화면에 없다');
    expect(
      footer.bottom,
      closeTo(screenH, 1),
      reason: 'footer 가 화면 바닥에 닿아 있어야 한다',
    );
  });

  testWidgets('목록을 스크롤해도 footer 의 dy 가 변하지 않는다', (tester) async {
    await _pump(tester, _items(20));
    final before = tester.getRect(_footer().first).top;

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    final after = tester.getRect(_footer().first).top;
    // 한 ListView 안에 있었다면 이 드래그로 위로 올라갔을 것이다.
    expect(after, closeTo(before, 0.5), reason: 'footer 가 목록과 같이 움직였다');
  });

  testWidgets('안읽음 헤더도 고정 — 스크롤해도 그대로다', (tester) async {
    await _pump(tester, _items(20));
    final before = tester.getRect(find.textContaining('읽지 않은').first).top;

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.textContaining('읽지 않은').first).top,
      closeTo(before, 0.5),
    );
  });

  testWidgets('알림이 없어도 footer 는 바닥에 있다', (tester) async {
    await _pump(tester, const []);

    final screenH =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(_footer(), findsWidgets);
    expect(tester.getRect(_footer().first).bottom, closeTo(screenH, 1));
  });

  testWidgets('행 좌우 여백이 24 다', (tester) async {
    await _pump(tester, _items(3));
    // 행은 [3px 좌측 엣지바][좌우 24 패딩][아이콘 · 글] 순이다. 그래서 내용이
    // 시작하는 자리는 목록 왼쪽에서 27 — 엣지바는 읽은 행에서도 폭을 차지한다
    // (색만 투명해진다). 여기서 벌어지면 좌우 여백이 24 가 아니라는 뜻이다.
    final list = tester.getRect(find.byType(ListView));
    final content = tester.getRect(
      find
          .descendant(of: find.byType(ListView), matching: find.byType(Row))
          .first,
    );
    expect(content.left - list.left, closeTo(3 + 24, 1));
    expect(list.right - content.right, closeTo(24, 1));
  });

  testWidgets('안읽음 헤더도 좌우 24 다', (tester) async {
    await _pump(tester, _items(3));
    final header = tester.getRect(find.textContaining('읽지 않은').first);
    expect(header.left, closeTo(24, 1));
  });
}
