// 예측형 뒤로가기(OnBackInvokedCallback)에서 앱이 꺼지던 문제를 고정한다
// (사용자 신고 2026-09-12 — 통계에서 뒤로가기를 누르면 앱이 그대로 종료).
//
// mobile_scaffold_back_test.dart 는 이걸 못 잡는다. 거기서는 뒤로가기를
// `flutter/navigation` 채널의 popRoute(옛 방식)로 넣는데, 예측형에서는 OS 가
// 그 채널을 쓰지 않는다 — 먼저 "프레임워크가 뒤로가기를 받을 수 있나" 를 묻고
// (SystemNavigator.setFrameworkHandlesBack) 앱이 false 라고 답해 둔 상태면
// Flutter 를 아예 부르지 않고 액티비티를 끝낸다. 그래서 셸에 PopScope 를 걸어도
// 옛 방식 테스트 7건은 전부 통과하면서 실기기에서는 앱이 꺼졌다.
//
// 여기서 보는 건 그 답 하나다 — Flutter 가 OS 에 올려 보내는 canHandlePop.
// 테스트 바인딩에서는 setFrameworkHandlesBack 플랫폼 호출이 실제로 나가지 않으므로
// (앱 라이프사이클이 null 이면 WidgetsApp 이 건너뛴다) 채널을 엿보는 대신
// MaterialApp.router 의 onNavigationNotification 으로 같은 값을 잡는다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/notification/application/notification_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/branch_back_to_home.dart';
import 'package:porest_desk_app/shared/widgets/mobile_scaffold.dart';

class _Screen extends StatelessWidget {
  const _Screen(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => Center(child: Text(name));
}

/// 실제 `lib/app/router.dart` 와 같은 모양 — 홈만 감싸지 않는다.
GoRouter _buildRouter(String initialLocation) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MobileScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const _Screen('home')),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expense',
                builder: (_, _) =>
                    const BranchBackToHome(child: _Screen('expense')),
              ),
              GoRoute(
                path: '/assets',
                builder: (_, _) =>
                    const BranchBackToHome(child: _Screen('assets')),
              ),
              GoRoute(
                path: '/stats',
                builder: (_, _) =>
                    const BranchBackToHome(child: _Screen('stats')),
              ),
              GoRoute(
                path: '/budget',
                builder: (_, _) =>
                    const BranchBackToHome(child: _Screen('budget')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (_, _) =>
                    const BranchBackToHome(child: _Screen('calendar')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (_, _) =>
                    const BranchBackToHome(child: _Screen('more')),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  /// 앱이 OS 에 "뒤로가기 받을 수 있다" 고 답한 마지막 값.
  ///
  /// Navigator 는 자기 이력이 바뀔 때 NavigationNotification 을 위로 올리고, 위
  /// Navigator 는 자기가 pop 할 게 있을 때만 true 로 바꿔 올린다. 마지막에 남는
  /// 값이 OS 에 나가므로, 중간에 true 가 있었는지가 아니라 **마지막 값**을 본다.
  Future<bool> lastCanHandlePop(
    WidgetTester tester,
    String initialLocation, {
    String? thenGo,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final seen = <bool>[];
    final router = _buildRouter(initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [unreadCountProvider.overrideWith((ref) async => 0)],
        child: MaterialApp.router(
          routerConfig: router,
          theme: PorestTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          onNavigationNotification: (n) {
            seen.add(n.canHandlePop);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (thenGo != null) {
      router.go(thenGo);
      await tester.pumpAndSettle();
      // 탭바 모드 전환 스태거를 흘려보낸다(130+420+슬롯) — 안 흘리면 pending timer.
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
    }

    expect(seen, isNotEmpty, reason: '알림이 하나도 안 올라왔다 — 테스트가 무의미하다');
    return seen.last;
  }

  testWidgets('홈에서 통계로 가면 앱은 여전히 "뒤로가기 받을 수 있다" 고 답한다', (tester) async {
    // 이 한 줄이 예측형 뒤로가기 회귀를 막는다. 셸에만 PopScope 가 있던 코드에서는
    // 마지막 값이 false 로 남아 OS 가 앱을 끝냈다.
    expect(
      await lastCanHandlePop(tester, '/home', thenGo: '/stats'),
      isTrue,
      reason: 'false 면 안드로이드가 Flutter 를 부르지 않고 앱을 끝낸다',
    );
  });

  testWidgets('통계로 시작해도 같다', (tester) async {
    expect(await lastCanHandlePop(tester, '/stats'), isTrue);
  });

  testWidgets('가계부에서 자산으로 전환한 뒤에도 같다', (tester) async {
    expect(
      await lastCanHandlePop(tester, '/expense', thenGo: '/assets'),
      isTrue,
    );
  });

  testWidgets('캘린더·더보기 branch 도 같다', (tester) async {
    for (final path in ['/calendar', '/more']) {
      expect(
        await lastCanHandlePop(tester, '/home', thenGo: path),
        isTrue,
        reason: path,
      );
    }
  });

  testWidgets('홈에서는 false — 뒤로가기가 앱을 끄는 게 맞다', (tester) async {
    // 홈을 감싸지 않았다는 것을 뒤집어 고정한다. true 가 되면 홈에서 뒤로가기를
    // 눌러도 앱이 안 꺼져 사용자가 나갈 방법을 잃는다.
    expect(await lastCanHandlePop(tester, '/home'), isFalse);
  });
}
