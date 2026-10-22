// 알림 지우기 — 줄 끝 ⋮ → 메뉴 시트 → 확인창 (I-04 "알림 지우기", decisions/notif-delete.md).
//
// 줄마다 × 로 확인 없이 바로 지우던 것을 걷고, 줄 끝 ⋮(이름 "{알림 제목} 더보기") → Menu Sheet(제목 = 알림 제목, 위험 줄
// "삭제" 하나) → 시트가 다 닫힌 뒤 Alert Dialog "알림 삭제" / "삭제한 알림은 되돌릴 수 없어요." [취소][삭제] 로 지운다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/app/app.dart' show appMessengerKey;
import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/core/network/api_exception.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/features/notification/data/notification_repository.dart';
import 'package:groo_damda_app/features/notification/domain/notification.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/alert_dialog/p_alert_dialog.dart';
import 'package:groo_damda_app/shared/widgets/p_snack_bar.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

class _FakeRepo extends NotificationRepository {
  _FakeRepo(this.deleted, {this.fail = false}) : super(Dio());
  final List<int> deleted;
  final bool fail;

  @override
  Future<void> delete(int id) async {
    if (fail) throw ApiException(code: 'X', message: '삭제하지 못했어요');
    deleted.add(id);
  }
}

// 가장 나쁜 값 — 두 줄을 넘는 제목
const _longTitle = '이번 달 식비 예산의 90% 를 넘었어요 — 남은 기간 동안 하루에 쓸 수 있는 금액을 확인해 보세요';

const _items = [
  AppNotification(
    rowId: 1,
    title: _longTitle,
    message: '내용 1',
    isRead: false,
    createAt: '2026-09-14T00:00:00',
    notificationType: 'BUDGET_ALERT',
  ),
  AppNotification(
    rowId: 2,
    title: '할 일 알림',
    message: '내용 2',
    isRead: true,
    createAt: '2026-09-14T00:00:00',
    notificationType: 'TODO_REMINDER',
  ),
];

Future<void> _pump(
  WidgetTester tester,
  List<int> deleted, {
  double scale = 1,
  bool fail = false,
}) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/notifications',
    routes: [
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWith(
          (ref) async => _FakeRepo(deleted, fail: fail),
        ),
        notificationListProvider.overrideWith((ref) async => _items),
        unreadCountProvider.overrideWith((ref) async => 1),
      ],
      child: MaterialApp.router(
        // 앱 뿌리와 같은 구성 — 오류 알림이 지나는 전역 ScaffoldMessenger
        scaffoldMessengerKey: appMessengerKey,
        routerConfig: router,
        theme: GrooTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('× 는 없고 ⋮ 가 있다 — 이름은 "{알림 제목} 더보기", 읽음 줄 버튼과 형제다', (
    tester,
  ) async {
    await _pump(tester, []);
    expect(find.byIcon(LucideIcons.x), findsNothing);
    expect(find.byIcon(LucideIcons.ellipsisVertical), findsNWidgets(2));
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('$_longTitle 더보기'), findsOneWidget);
    expect(find.bySemanticsLabel('할 일 알림 더보기'), findsOneWidget);
    // ds 아이콘 버튼 — 보이는 크기 32(xsmall, 웹과 같다), 누르는 영역은 따로 44
    final more = find.byKey(const ValueKey('noti-more-1'));
    final visible = tester.getSize(
      find.descendant(of: more, matching: find.byType(DecoratedBox)).first,
    );
    expect(visible, const Size(32, 32));
    // 누르는 영역 44 — 보이는 상자 위 5px 도 눌린다(위아래 6 씩 넓힌다)
    final box = tester.getRect(
      find.descendant(of: more, matching: find.byType(DecoratedBox)).first,
    );
    await tester.tapAt(box.topCenter - const Offset(0, 5));
    await tester.pumpAndSettle();
    expect(find.text(keepAll('삭제')), findsOneWidget, reason: '넓힌 영역에서 메뉴가 열린다');
    handle.dispose();
    // ⋮ 는 읽음 처리 InkWell 안에 들어 있지 않다
    expect(
      find.descendant(
        of: find.byType(InkWell),
        matching: find.byKey(const ValueKey('noti-more-1')),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('⋮ → 메뉴 시트(제목 = 알림 제목, "삭제" 하나) → 확인창에서 취소하면 지우지 않는다', (
    tester,
  ) async {
    final deleted = <int>[];
    await _pump(tester, deleted);
    await tester.tap(find.byKey(const ValueKey('noti-more-2')));
    await tester.pumpAndSettle();
    // 시트: 제목 + 삭제 한 줄
    expect(find.text(keepAll('할 일 알림')), findsWidgets);
    expect(find.text(keepAll('삭제')), findsOneWidget);
    await tester.tap(find.text(keepAll('삭제')));
    await tester.pumpAndSettle();
    // 시트는 닫히고 확인창이 뜬다
    expect(find.text(keepAll('알림 삭제')), findsOneWidget);
    expect(find.text(keepAll('삭제한 알림은 되돌릴 수 없어요.')), findsOneWidget);
    expect(find.text('취소'), findsOneWidget);
    expect(deleted, isEmpty, reason: '확인 전에는 지우지 않는다');
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text(keepAll('알림 삭제')), findsNothing);
    expect(deleted, isEmpty);
  });

  testWidgets('확인창에서 삭제를 누르면 그 알림을 지운다', (tester) async {
    final deleted = <int>[];
    await _pump(tester, deleted);
    await tester.tap(find.byKey(const ValueKey('noti-more-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(keepAll('삭제')));
    await tester.pumpAndSettle();
    // 확인창의 삭제 버튼(시트의 삭제 줄은 이미 닫혔다)
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(deleted, [1]);
    expect(find.text(keepAll('알림 삭제')), findsNothing);
  });

  testWidgets('가장 나쁜 값 — 글자 200% · 긴 제목에서도 넘치지 않고 ⋮ 가 화면 안에 든다', (
    tester,
  ) async {
    await _pump(tester, [], scale: 2);
    expect(tester.takeException(), isNull);
    final more = tester.getRect(find.byKey(const ValueKey('noti-more-1')));
    expect(more.right, lessThanOrEqualTo(360));
    expect(more.left, greaterThanOrEqualTo(0));
  });

  testWidgets('지우기가 실패하면 확인창은 열려 있고 오류 알림이 뜬다(웹과 같다)', (tester) async {
    final deleted = <int>[];
    await _pump(tester, deleted, fail: true);
    await tester.tap(find.byKey(const ValueKey('noti-more-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(keepAll('삭제')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(deleted, isEmpty);
    // 창은 그대로
    expect(find.text(keepAll('알림 삭제')), findsOneWidget);
    // 오류 알림
    expect(find.textContaining('삭제하지 못했어요'), findsWidgets);
    // 확정 버튼이 다시 눌린다(로딩이 풀렸다)
    expect(find.text('삭제'), findsOneWidget);
  });

  testWidgets('실패 알림 띠는 확인창 딤 위에 그려진다 — 눌러서 동작한다(DESIGN Z-index)', (
    tester,
  ) async {
    await _pump(tester, <int>[], fail: true);
    await tester.tap(find.byKey(const ValueKey('noti-more-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(keepAll('삭제')));
    await tester.pumpAndSettle();
    expect(find.text(keepAll('알림 삭제')), findsOneWidget);
    // 확인창이 떠 있는 동안 액션이 달린 띠를 띄워 눌러 본다 — 딤 아래에 그려지면 딤이 받아 동작하지 않는다
    var taps = 0;
    final ctx = tester.element(find.byType(PAlertDialogView));
    showPSnackBar(
      ctx,
      '확인창 위 띠',
      actionLabel: '다시 시도',
      onAction: () => taps++,
      duration: const Duration(seconds: 20),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // 확인창 라우트의 Scaffold 안에도 띠가 그려진다
    final routeScaffold = find.ancestor(
      of: find.byType(PAlertDialogView),
      matching: find.byType(Scaffold),
    );
    expect(routeScaffold, findsOneWidget);
    expect(
      find.descendant(of: routeScaffold, matching: find.text('확인창 위 띠')),
      findsOneWidget,
    );
    await tester.tap(
      find.descendant(of: routeScaffold, matching: find.text('다시 시도')),
    );
    await tester.pump();
    expect(taps, 1, reason: '딤 위에 있어 눌린다');
    expect(
      find.text(keepAll('알림 삭제')),
      findsOneWidget,
      reason: '띠를 눌러도 확인창은 닫히지 않는다',
    );
  });
}
