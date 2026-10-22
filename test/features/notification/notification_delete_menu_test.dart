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

import 'package:groo_damda_app/app/theme/theme_data.dart';
import 'package:groo_damda_app/features/notification/application/notification_providers.dart';
import 'package:groo_damda_app/features/notification/data/notification_repository.dart';
import 'package:groo_damda_app/features/notification/domain/notification.dart';
import 'package:groo_damda_app/features/notification/presentation/notification_screen.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/text/keep_all.dart';

class _FakeRepo extends NotificationRepository {
  _FakeRepo(this.deleted) : super(Dio());
  final List<int> deleted;

  @override
  Future<void> delete(int id) async => deleted.add(id);
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
          (ref) async => _FakeRepo(deleted),
        ),
        notificationListProvider.overrideWith((ref) async => _items),
        unreadCountProvider.overrideWith((ref) async => 1),
      ],
      child: MaterialApp.router(
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
    expect(find.byTooltip('$_longTitle 더보기'), findsOneWidget);
    expect(find.byTooltip('할 일 알림 더보기'), findsOneWidget);
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
}
