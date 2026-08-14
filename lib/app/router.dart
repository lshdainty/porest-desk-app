import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/update/app_update.dart';
import 'package:porest_desk_app/features/asset/presentation/account_card_manage_screen.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_screen.dart';
import 'package:porest_desk_app/features/budget/presentation/budget_screen.dart';
import 'package:porest_desk_app/features/budget/presentation/budget_settings_screen.dart';
import 'package:porest_desk_app/features/calendar/presentation/calendar_labels_screen.dart';
import 'package:porest_desk_app/features/calendar/presentation/calendar_screen.dart';
import 'package:porest_desk_app/features/card/presentation/card_benefits_screen.dart';
import 'package:porest_desk_app/features/card/presentation/card_detail_screen.dart';
import 'package:porest_desk_app/features/card/presentation/card_screen.dart';
import 'package:porest_desk_app/features/category/presentation/category_screen.dart';
import 'package:porest_desk_app/features/dutch_pay/presentation/dutch_pay_screen.dart';
import 'package:porest_desk_app/features/calendar/presentation/calendar_share_screen.dart';
import 'package:porest_desk_app/features/export/presentation/export_screen.dart';
import 'package:porest_desk_app/features/sms/presentation/sms_paste_screen.dart';
import 'package:porest_desk_app/features/memo/presentation/memo_screen.dart';
import 'package:porest_desk_app/features/notification/presentation/notification_screen.dart';
import 'package:porest_desk_app/features/notification/presentation/notification_settings_screen.dart';
import 'package:porest_desk_app/features/preset/presentation/preset_screen.dart';
import 'package:porest_desk_app/features/saving_goal/presentation/saving_goal_screen.dart';
import 'package:porest_desk_app/features/search/presentation/search_screen.dart';
import 'package:porest_desk_app/features/constellation/presentation/forest_report_screen.dart';
import 'package:porest_desk_app/features/constellation/presentation/night_sky_screen.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_screen.dart';
import 'package:porest_desk_app/features/todo/presentation/todo_tag_management_screen.dart';
import 'package:porest_desk_app/features/auth/presentation/login_screen.dart';
import 'package:porest_desk_app/features/auth/presentation/splash_screen.dart';
import 'package:porest_desk_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:porest_desk_app/features/expense/presentation/expense_screen.dart';
import 'package:porest_desk_app/features/more/presentation/more_screen.dart';
import 'package:porest_desk_app/features/recurring/presentation/recurring_screen.dart';
import 'package:porest_desk_app/features/settings/presentation/account_screen.dart';
import 'package:porest_desk_app/features/settings/presentation/appearance_section.dart';
import 'package:porest_desk_app/features/settings/presentation/settings_screen.dart';
import 'package:porest_desk_app/features/settings/presentation/update_screen.dart';
import 'package:porest_desk_app/features/stats/presentation/stats_screen.dart';
import 'package:porest_desk_app/features/stocks/presentation/stocks_screen.dart';
import 'package:porest_desk_app/features/subscription/presentation/securities_gate.dart';
import 'package:porest_desk_app/shared/widgets/mobile_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;

      // 첫 부팅 세션 검증 중 (값 없음) → splash 유지
      if (auth.isLoading && !auth.hasValue) return null;

      final loggedIn = auth.hasValue && auth.value != null;
      final atSplash = loc == '/';
      final atLogin = loc == '/login';

      if (!loggedIn) {
        // 로그아웃 상태에서 splash/login 외 접근 시 → /login
        return atLogin ? null : '/login';
      }

      // 더 못 쓰는 버전이면 업데이트 화면에 가둔다.
      //
      // 서버와 앱이 어긋나 잘못된 값을 주고받을 수 있는 상태라, 받기 전에는 어디로도
      // 못 간다. 확인이 끝나기 전(로딩)이나 서버를 못 읽었을 때는 막지 않는다 —
      // 네트워크가 끊겼다고 사람을 앱 밖에 세워 둘 이유가 없다.
      final mustUpdate =
          ref.read(updateStatusProvider).value?.mustUpdate ?? false;
      final atUpdate = loc == '/settings/update';
      if (mustUpdate && !atUpdate) return '/settings/update?forced=1';

      // 로그인 상태에서 splash/login 머무르면 → /home
      if (atSplash || atLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/account-card-manage', builder: (_, _) => const AccountCardManageScreen()),
      // /assets, /budget, /stats 는 shell branch 1 (가계부) 안 sub-routes 로
      // 이동 — 하단바 (MoneyTabBar) 가 shell scaffold 가 한 번 build 되어
      // sub-tab 전환 시 사라지지 않게 (사용자 의도: 안정적 고정 bottom bar).
      GoRoute(path: '/recurring', builder: (_, _) => const RecurringScreen()),
      GoRoute(path: '/categories', builder: (_, _) => const CategoryScreen()),
      GoRoute(path: '/presets', builder: (_, _) => const PresetScreen()),
      // 결제 문자로 기록 — 배너·알림에서 들어올 땐 문자를 extra 로 실어 바로 해석한다.
      GoRoute(
          path: '/sms-paste',
          builder: (_, state) => SmsPasteScreen(initialText: state.extra as String?)),
      // 예산 설정(웹 BudgetManager 정합) — 예산 개요 설정 버튼·설정 메뉴에서 push.
      GoRoute(
          path: '/budget/settings',
          builder: (_, _) => const BudgetSettingsScreen()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/memos', builder: (_, _) => const MemoScreen()),
      GoRoute(path: '/todos', builder: (_, _) => const TodoScreen()),
      // 밤하늘(성장·수집)·관측 리포트 — 할일 화면 [밤하늘] 패널에서 push 진입.
      GoRoute(path: '/night-sky', builder: (_, _) => const NightSkyScreen()),
      GoRoute(
          path: '/forest-report',
          builder: (_, _) => const ForestReportScreen()),
      GoRoute(
          path: '/settings/calendar-share',
          builder: (_, _) => const CalendarShareScreen()),
      GoRoute(
          path: '/settings/calendar-labels',
          builder: (_, _) => const CalendarLabelsScreen()),
      GoRoute(
          path: '/settings/todo-tags',
          builder: (_, _) => const TodoTagManagementScreen()),
      GoRoute(
          // 화면의 눈 버튼이 ?hide=1 로 보낸다 — 그때는 금액 가리기를 펼친 채로 연다.
          path: '/settings/appearance',
          builder: (_, st) => AppearanceScreen(
              openHideAmounts: st.uri.queryParameters['hide'] == '1')),
      GoRoute(
          path: '/settings/export-data',
          builder: (_, _) => const ExportScreen()),
      // 업데이트 — 평소엔 설정에서 들어와 확인하고, 강제일 때는 redirect 가 여기로
      // 몰아넣는다(그때는 뒤로 갈 수 없다).
      GoRoute(
          path: '/settings/update',
          builder: (_, st) =>
              UpdateScreen(forced: st.uri.queryParameters['forced'] == '1')),
      GoRoute(path: '/dutch-pay', builder: (_, _) => const DutchPayScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationScreen()),
      GoRoute(
          path: '/settings/notifications',
          builder: (_, _) => const NotificationSettingsScreen()),
      GoRoute(path: '/saving-goals', builder: (_, _) => const SavingGoalScreen()),
      GoRoute(path: '/cards', builder: (_, _) => const CardScreen()),
      GoRoute(
          path: '/card-benefits',
          builder: (_, _) => const CardBenefitsScreen()),
      // 증권 — 카드 혜택과 동일하게 전체(more)에서 push 진입, 뒤로가기로 복귀. 구독 게이트.
      GoRoute(path: '/stocks', builder: (_, _) => const SecuritiesGate(child: StocksScreen())),
      GoRoute(
        path: '/cards/:id',
        builder: (_, state) => CardDetailScreen(
          catalogId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // 모바일 셸 (홈/가계부/캘린더/전체 4개 분기)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MobileScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (_, _) => const NoTransitionPage(child: DashboardScreen()),
            ),
          ]),
          // 가계부 branch — 4 페이지 (money group) 모두 같은 branch:
          //   /expense, /assets, /stats, /budget — MoneyTabBar 로 전환.
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/expense',
              pageBuilder: (_, state) {
                final month = state.uri.queryParameters['month'];
                final txId =
                    int.tryParse(state.uri.queryParameters['txId'] ?? '');
                final assetId = int.tryParse(
                    state.uri.queryParameters['assetId'] ?? '');
                return NoTransitionPage(
                  child: ExpenseScreen(
                    key: ValueKey(
                        'expense-${month ?? ''}-${txId ?? ''}-${assetId ?? ''}'),
                    initialMonth: month,
                    focusTxId: txId,
                    initialAssetId: assetId,
                  ),
                );
              },
            ),
            GoRoute(
              path: '/assets',
              pageBuilder: (_, _) => const NoTransitionPage(child: AssetScreen()),
            ),
            GoRoute(
              path: '/stats',
              pageBuilder: (_, _) => const NoTransitionPage(child: StatsScreen()),
            ),
            GoRoute(
              path: '/budget',
              pageBuilder: (_, _) => const NoTransitionPage(child: BudgetScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendar',
              pageBuilder: (_, _) => const NoTransitionPage(child: CalendarScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/more',
              pageBuilder: (_, _) => const NoTransitionPage(child: MoreScreen()),
            ),
          ]),
        ],
      ),
    ],
  );
});

/// 로그인 상태·업데이트 상태 변화를 GoRouter 에 알려 redirect 를 재평가하게 만드는 브릿지.
///
/// 업데이트 확인은 비동기라 첫 redirect 때는 값이 없다. 여기서 듣지 않으면 "더 못 쓰는
/// 버전" 이라는 답이 와도 이미 지나간 뒤라 아무도 다시 묻지 않는다.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _subs = [
      ref.listen(authProvider, (_, _) => notifyListeners()),
      ref.listen(updateStatusProvider, (_, _) => notifyListeners()),
    ];
  }
  late final List<ProviderSubscription> _subs;

  @override
  void dispose() {
    for (final s in _subs) {
      s.close();
    }
    super.dispose();
  }
}
