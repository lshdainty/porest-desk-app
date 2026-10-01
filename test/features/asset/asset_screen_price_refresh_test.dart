// 자산 화면의 10초 타이머가 **시세를 실제로 다시 받는지**, 다시 받는 동안 금액이 깜빡이지
// 않는지 — 진짜 `AssetScreen` 과 진짜 셸로 잰다.
//
// 2026-08-25 ~ 09-30 회귀: 타이머가 평가 맵만 무효화해서 시세 요청이 한 번도 다시 나가지
// 않았다. 평가 맵을 가짜로 바꾼 기존 테스트(`valuation_timer_scope_test.dart`)는 "평가 맵을
// 몇 번 다시 만들었나" 만 세서 이걸 못 잡았다 — 그래서 여기서는 평가 맵을 그대로 두고
// **맨 끝 시세 저장소의 요청 수**를 센다.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/data/asset_repository.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_screen.dart';
import 'package:porest_desk_app/features/notification/application/notification_providers.dart';
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/saving_goal/data/saving_goal_repository.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';
import 'package:porest_desk_app/features/stocks/application/securities_providers.dart';
import 'package:porest_desk_app/features/stocks/data/securities_repository.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/mobile_scaffold.dart';

const _tick = Duration(seconds: 10);

/// 시세 저장소 대역. 부를 때마다 100원 오른다. [delay] 만큼 늦게 답한다(다시 받는 동안을 보려고).
class _Prices extends SecuritiesRepository {
  _Prices() : super(Dio());

  int calls = 0;
  int price = 70000;
  Duration delay = Duration.zero;

  @override
  Future<List<BrokerQuote>> getPrices(List<String> symbols) async {
    calls++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    price += 100;
    return [
      BrokerQuote(
        symbol: '005930',
        price: price.toDouble(),
        currency: 'KRW',
        previousClose: 69000,
      ),
    ];
  }

  @override
  Future<double?> getExchangeRate({
    String base = 'USD',
    String quote = 'KRW',
  }) async => null;
}

class _OneInvestmentRepo extends AssetRepository {
  _OneInvestmentRepo() : super(Dio());

  /// 목록을 다시 받을 때 걸리는 시간 — 다시 받는 동안 화면을 보려고.
  Duration delay = Duration.zero;

  @override
  Future<List<Asset>> list() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return _assets;
  }

  static final _assets = [
    Asset(
      rowId: 1,
      assetName: '주식 계좌',
      assetType: 'INVESTMENT',
      balance: 500000, // 서버 잔액 — 시세를 못 받으면 이 값이 보인다
      holdings: const [
        AssetHolding(linked: true, tossSymbol: '005930', quantity: '10'),
      ],
    ),
  ];

  @override
  Future<AssetSummary> summary({int? year, int? month}) async =>
      const AssetSummary();
}

class _EmptySavingGoalRepo extends SavingGoalRepository {
  _EmptySavingGoalRepo() : super(Dio());

  @override
  Future<List<SavingGoal>> list() async => const <SavingGoal>[];
}

GoRouter _router() {
  Widget stub(String name) => Center(child: Text(name));
  return GoRouter(
    initialLocation: assetRoute,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MobileScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, _) => stub('home'))],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: assetRoute, builder: (_, _) => const AssetScreen()),
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

Future<(_Prices, _OneInvestmentRepo)> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(const <String, Object>{});

  final prices = _Prices();
  final assets = _OneInvestmentRepo();
  final router = _router();
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        assetRepositoryProvider.overrideWith((ref) async => assets),
        savingGoalRepositoryProvider.overrideWith(
          (ref) async => _EmptySavingGoalRepo(),
        ),
        unreadCountProvider.overrideWith((ref) async => 0),
        myFeaturesProvider.overrideWith(
          (ref) async => const MyFeatures(
            features: ['SECURITIES'],
            connectedBrokers: ['TOSS'],
            primaryBroker: 'TOSS',
          ),
        ),
        securitiesRepositoryProvider.overrideWith((ref) async => prices),
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
  await _settle(tester);
  return (prices, assets);
}

/// 짧게 여러 번 민다 — 응답·탭바 스태거 타이머를 흘려보낸다.
///
/// `pumpAndSettle` 을 쓰지 않는다. 그건 애니메이션이 멎을 때까지 가짜 시계를 계속 미는데,
/// 이 화면은 값이 바뀔 때 움직이는 게 있어서 한 번에 수십 초가 흐른다 — 그 사이 10초
/// 타이머가 몇 번 더 돌아 "몇 초에 몇 번" 을 잴 수 없게 된다(실제로 들어오자마자 4번이 셌다).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// 가짜 시계를 [d] 만큼 민 뒤 응답을 흘려보낸다. 마지막 1초는 [_settle] 몫이다.
Future<void> _advance(WidgetTester tester, Duration d) async {
  await tester.pump(d - const Duration(seconds: 1));
  await _settle(tester);
}

void main() {
  testWidgets('자산 화면을 보고 있으면 10초마다 시세를 다시 받고 평가액이 바뀐다', (tester) async {
    final (prices, _) = await _pump(tester);
    expect(prices.calls, 1, reason: '들어오면 한 번은 받는다');
    expect(
      find.textContaining('701,000'),
      findsWidgets,
      reason: '70,100 × 10주',
    );

    await _advance(tester, _tick);
    expect(
      prices.calls,
      2,
      reason: '10초가 지났는데 시세를 다시 안 받았다 — 평가 맵만 밀면 받아 둔 시세로 다시 계산할 뿐이다',
    );
    expect(find.textContaining('702,000'), findsWidgets);

    await _advance(tester, _tick);
    expect(prices.calls, 3);
    expect(find.textContaining('703,000'), findsWidgets);
  });

  // 시세를 새로 받는 동안은 원래도 안 깜빡였다 — 직접 무효화한 provider 는 riverpod 이
  // 앞 값을 든 채로 다시 받는다(seamless refresh). 깜빡이는 건 **평가 맵이 기대는 다른 값이
  // 바뀌어** 다시 만들어질 때다(reload — 그때는 잠깐 로딩 상태가 된다). 앱으로 돌아올 때
  // 자산 목록을 다시 받는 게(keep_alive_refresh) 그 경우다. `asData` 로 읽으면 그 사이에
  // 평가 맵이 비어 평가액이 서버 잔액(500,000)으로 뛰었다가 돌아온다.
  testWidgets('자산 목록을 다시 받는 동안에도 평가액이 그대로 보인다 — 서버 잔액으로 깜빡이지 않는다', (
    tester,
  ) async {
    final (_, assets) = await _pump(tester);
    expect(find.textContaining('701,000'), findsWidgets);

    assets.delay = const Duration(seconds: 2); // 목록 응답이 2초 걸린다
    ProviderScope.containerOf(
      tester.element(find.byType(AssetScreen)),
    ).invalidate(assetsProvider); // 앱으로 돌아올 때 하는 일
    await tester.pump(const Duration(milliseconds: 500)); // 아직 응답 전

    expect(
      find.textContaining('701,000'),
      findsWidgets,
      reason: '받는 동안 앞 평가액이 보여야 한다 — asData 로 읽으면 이때 비어 서버 잔액이 보인다',
    );
    expect(find.textContaining('500,000'), findsNothing);

    await _settle(tester);
    await _settle(tester);
    expect(
      find.textContaining('701,000'),
      findsWidgets,
      reason: '목록이 오면 같은 시세로 다시 계산',
    );
  });
}
