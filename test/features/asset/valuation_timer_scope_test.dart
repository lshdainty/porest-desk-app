// 자산 화면의 평가액 10초 타이머는 **그 화면을 보고 있을 때만** 돈다.
//
// 타이머를 끄는 `cancel` 은 처음부터 `dispose` 에 있었다. 문제는 이 화면이 dispose
// 되지 않는다는 것이다 — 탭 셸(`IndexedStack`)이 여섯 화면을 계속 mount 해 둔다.
// 그래서 앱을 켜 두면 다른 탭에 있어도, 화면이 꺼져 있어도 10초마다 시세를 다시
// 받으라고 밀었다. 아무도 안 보는 값이라 화면에 쓰이지도 않고 배터리·데이터만 썼다.
//
// 멈추는 조건이 둘이라 둘 다 본다 — **다른 탭**(셸 라우트)과 **백그라운드**(앱 lifecycle).
// 어느 한쪽만 막으면 나머지 한쪽으로 그대로 샌다.
//
// 탭은 **홈**(branch 0)으로 옮긴다. 가계부·통계·예산은 자산과 **같은 branch** 라 그쪽으로
// 가면 자산 화면이 실제로 dispose 되어 예전 코드로도 타이머가 꺼진다 — 그걸로 재면
// 고치기 전 코드도 통과한다. 상주한 채로 안 보이게 되는 건 branch 를 건너뛸 때다.
//
// 여기서 세는 건 "invalidate 한 줄이 있다" 가 아니라 **평가액 조회가 실제로 몇 번
// 나갔는가** 다. 시간은 위젯 테스트의 가짜 시계로 민다 — 진짜 10초를 기다리지 않는다.
//
// 그 조회를 **자산 화면 말고 한 곳 더**(`_CoReader`) 읽는다. 안 그러면 타이머가 계속
// 도는지가 요청 수에 안 드러난다 — 읽는 곳이 자산 화면 하나뿐이면, 그 화면이 안 보이는
// 동안의 무효화는 Riverpod 이 뭉쳐 뒀다가 돌아올 때 한 번만 다시 받기 때문이다.
// 앱에서도 같은 조회를 읽는 곳이 하나만 더 있으면(자산 상세 다이얼로그가 그렇다) 곧바로
// 10초마다 나간다. 뭉쳐지는 건 우연이지 타이머를 멈춘 게 아니다.
//
// 라우트는 **실제 셸**(`MobileScaffold`)로 옮긴다. 화면이 "내가 보인다" 를 아는 배선이
// 거기 있으므로, 셸을 흉내 내면 정작 그 배선이 끊겨도 테스트는 통과한다.
// lifecycle 도 엔진이 보내는 것과 같은 플랫폼 메시지로 넣는다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/lifecycle/screen_visibility.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_screen.dart';
import 'package:porest_desk_app/features/notification/application/notification_providers.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/saving_goal/data/saving_goal_repository.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/mobile_scaffold.dart';

const _tick = Duration(seconds: 10);

void main() {
  // ─── 다른 탭 ────────────────────────────────────────────────
  testWidgets('다른 탭에 가 있으면 10초가 몇 번 지나도 평가액을 안 받는다', (tester) async {
    final h = await _pumpShell(tester, at: assetRoute);
    expect(h.calls, 1, reason: '자산 탭에 들어왔으면 평가액을 한 번은 받는다');

    await h.go('/home');
    expect(
      find.byType(AssetScreen, skipOffstage: false),
      findsOneWidget,
      reason: '자산 화면이 셸에서 사라졌다 — 상주하지 않으면 이 테스트가 재려는 것이 없다',
    );
    final atLeave = h.calls;

    for (var i = 0; i < 3; i++) {
      await h.advance(_tick);
    }

    expect(
      h.calls,
      atLeave,
      reason:
          '다른 탭에 있는데 평가액 조회가 나갔다. 셸(IndexedStack)이 자산 화면을 계속 mount 해 두므로 '
          'dispose 의 cancel 은 여기서 안 돈다 — 보고 있지 않으면 타이머를 멈춰야 한다',
    );
  });

  testWidgets('자산 탭으로 돌아오면 바로 한 번 받고, 다시 10초마다 받는다', (tester) async {
    final h = await _pumpShell(tester, at: assetRoute);

    await h.go('/home');
    await h.advance(_tick);
    final atLeave = h.calls;

    await h.go(assetRoute);
    expect(
      h.calls,
      atLeave + 1,
      reason: '돌아온 직후 한 번은 바로 받아야 한다 — 안 그러면 10초 동안 떠나기 전 시세를 본다',
    );

    await h.advance(_tick);
    expect(h.calls, atLeave + 2, reason: '돌아왔는데 10초 주기가 다시 안 돈다');
  });

  // ─── 백그라운드 ─────────────────────────────────────────────
  testWidgets('앱이 백그라운드면 안 받고, 돌아오면 바로 한 번 받고 다시 돈다', (tester) async {
    final h = await _pumpShell(tester, at: assetRoute);
    expect(h.calls, 1);

    await h.background();
    final atBackground = h.calls;

    for (var i = 0; i < 3; i++) {
      await h.advance(_tick);
    }
    expect(
      h.calls,
      atBackground,
      reason: '화면이 꺼져 있는데 10초마다 시세를 받았다 — 아무도 못 보는 값이다',
    );

    await h.foreground();
    expect(h.calls, atBackground + 1, reason: '복귀 직후 한 번은 바로 받아야 한다');

    await h.advance(_tick);
    expect(h.calls, atBackground + 2, reason: '복귀했는데 10초 주기가 다시 안 돈다');
  });

  testWidgets('자산 탭이 아닐 때 복귀하면 여전히 안 받는다 — 조건은 둘 다 성립해야 한다', (tester) async {
    final h = await _pumpShell(tester, at: assetRoute);

    await h.go('/home');
    await h.background();
    await h.foreground();
    final atForeground = h.calls;

    await h.advance(_tick);
    expect(
      h.calls,
      atForeground,
      reason: '포그라운드로 돌아왔다고 안 보이는 탭의 타이머까지 되살리면 안 된다',
    );
  });

  // ─── 타이머는 하나뿐 ────────────────────────────────────────
  testWidgets('시작 경로를 여러 번 밟아도 10초에 한 번만 받는다 — 타이머가 겹치지 않는다', (tester) async {
    // 시작을 부르는 자리는 둘(라우트·포그라운드)이고 mount 때는 둘 다 한 번씩 부른다.
    // 이미 돌고 있는데 새로 만들면 타이머가 겹쳐 요청이 배로 나가고, 멈추는 쪽은
    // 한 번뿐이라 겹친 하나는 앱을 끌 때까지 안 꺼진다.
    final h = await _pumpShell(tester, at: assetRoute);

    // 라우트로 한 번, 포그라운드로 한 번 — 둘 다 "다시 시작" 을 거친다.
    await h.go('/home');
    await h.go(assetRoute);
    await h.background();
    await h.foreground();

    final before = h.calls;
    await h.advance(_tick);
    expect(
      h.calls,
      before + 1,
      reason: '10초에 한 번이어야 한다 — 여러 번 늘었으면 타이머가 겹쳐 돌고 있다',
    );

    await h.advance(_tick);
    expect(h.calls, before + 2, reason: '다음 10초도 한 번이어야 한다');
  });

  // ─── lifecycle 해석 ─────────────────────────────────────────
  test('inactive 는 보이는 것으로 센다 — 알림 센터를 잠깐 내린 것뿐이다', () {
    expect(isForegroundLifecycle(AppLifecycleState.resumed), isTrue);
    expect(isForegroundLifecycle(AppLifecycleState.inactive), isTrue);
    expect(isForegroundLifecycle(AppLifecycleState.hidden), isFalse);
    expect(isForegroundLifecycle(AppLifecycleState.paused), isFalse);
    expect(isForegroundLifecycle(AppLifecycleState.detached), isFalse);
  });
}

// ─── 하네스 ───────────────────────────────────────────────────

/// 평가액 조회 대역 — provider 본문 대신 **몇 번 불렸는지**만 센다.
/// 진짜 본문은 시세 API·기능 게이트를 물고 있어, 여기서 재려는 "언제 도느냐" 와 섞인다.
class _Harness {
  _Harness(this.tester, this.router, this._calls);
  final WidgetTester tester;
  final GoRouter router;
  final List<int> _calls;

  int get calls => _calls.first;

  /// 탭 이동. 탭바 모드 전환은 `Future.delayed` 스태거라 남겨 두면
  /// "A Timer is still pending" 으로 깨진다 — 여기서 흘려보낸다(130+420+슬롯).
  Future<void> go(String path) async {
    router.go(path);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();
  }

  /// 가짜 시계를 [d] 만큼 민다 — 진짜로 기다리지 않는다.
  Future<void> advance(Duration d) async {
    await tester.pump(d);
    await tester.pumpAndSettle();
  }

  /// 앱을 백그라운드로 — 엔진이 보내는 순서 그대로.
  Future<void> background() => _lifecycle(const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]);

  /// 앱이 앞으로 돌아온다 — 역순.
  Future<void> foreground() => _lifecycle(const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]);

  Future<void> _lifecycle(List<AppLifecycleState> states) async {
    for (final s in states) {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StringCodec().encodeMessage(s.toString()),
        (_) {},
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }
}

class _EmptyAssetRepo extends AssetRepository {
  _EmptyAssetRepo() : super(Dio());

  @override
  Future<List<Asset>> list() async => const <Asset>[];

  @override
  Future<AssetSummary> summary({int? year, int? month}) async =>
      const AssetSummary();
}

class _EmptySavingGoalRepo extends SavingGoalRepository {
  _EmptySavingGoalRepo() : super(Dio());

  @override
  Future<List<SavingGoal>> list() async => const <SavingGoal>[];
}

/// 실제 라우터 셸 모양 — 자산 탭만 진짜 화면이고 나머지는 대역이다.
/// `MobileScaffold` 는 진짜를 쓴다: "지금 어느 화면이 앞인가" 를 적는 자리가 거기다.
GoRouter _buildRouter(String initialLocation) {
  Widget stub(String name) => Center(child: Text(name));
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MobileScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, _) => stub('home'))],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/expense', builder: (_, _) => stub('expense')),
              GoRoute(path: assetRoute, builder: (_, _) => const AssetScreen()),
              GoRoute(path: '/stats', builder: (_, _) => stub('stats')),
              GoRoute(path: '/budget', builder: (_, _) => stub('budget')),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/calendar', builder: (_, _) => stub('calendar')),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/more', builder: (_, _) => stub('more'))],
          ),
        ],
      ),
    ],
  );
}

Future<_Harness> _pumpShell(WidgetTester tester, {required String at}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(const <String, Object>{});

  final calls = <int>[0];
  final router = _buildRouter(at);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        investmentValuationMapProvider.overrideWith((ref) async {
          calls[0]++;
          return const <int, InvestmentValuation>{};
        }),
        assetRepositoryProvider.overrideWith((ref) async => _EmptyAssetRepo()),
        savingGoalRepositoryProvider.overrideWith(
          (ref) async => _EmptySavingGoalRepo(),
        ),
        // 셸 헤더의 알림 벨 — 네트워크를 태우지 않는다.
        unreadCountProvider.overrideWith((ref) async => 0),
      ],
      child: MaterialApp.router(
        // 같은 조회를 읽는 곳 하나 더 — 셸 밖이라 탭을 옮겨도 계속 보인다.
        builder: (context, child) => Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const Positioned(width: 0, height: 0, child: _CoReader()),
          ],
        ),
        routerConfig: router,
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(tester, router, calls);
}

/// 평가액을 같이 읽는 화면 대역 — 앱의 자산 상세 다이얼로그 자리다.
/// 읽는 곳이 하나뿐이면 안 보이는 동안의 무효화가 뭉쳐져, 타이머가 도는지가 안 드러난다.
class _CoReader extends ConsumerWidget {
  const _CoReader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(investmentValuationMapProvider);
    return const SizedBox.shrink();
  }
}
