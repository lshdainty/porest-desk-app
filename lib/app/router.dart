import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_notifier.dart';
import '../features/asset/presentation/account_card_manage_screen.dart';
import '../features/asset/presentation/asset_screen.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/calendar/presentation/calendar_labels_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/card/presentation/card_benefits_screen.dart';
import '../features/card/presentation/card_detail_screen.dart';
import '../features/card/presentation/card_screen.dart';
import '../features/category/presentation/category_screen.dart';
import '../features/dutch_pay/presentation/dutch_pay_screen.dart';
import '../features/calendar/presentation/calendar_share_screen.dart';
import '../features/export/presentation/export_screen.dart';
import '../features/memo/presentation/memo_screen.dart';
import '../features/notification/presentation/notification_screen.dart';
import '../features/notification/presentation/notification_settings_screen.dart';
import '../features/preset/presentation/preset_screen.dart';
import '../features/saving_goal/presentation/saving_goal_screen.dart';
import '../features/search/presentation/search_screen.dart';
import '../features/todo/presentation/todo_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/expense/presentation/expense_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/recurring/presentation/recurring_screen.dart';
import '../features/settings/presentation/account_screen.dart';
import '../features/settings/presentation/appearance_section.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../shared/widgets/mobile_scaffold.dart';

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
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      GoRoute(path: '/memos', builder: (_, _) => const MemoScreen()),
      GoRoute(path: '/todos', builder: (_, _) => const TodoScreen()),
      GoRoute(
          path: '/settings/calendar-share',
          builder: (_, _) => const CalendarShareScreen()),
      GoRoute(
          path: '/settings/calendar-labels',
          builder: (_, _) => const CalendarLabelsScreen()),
      GoRoute(
          path: '/settings/appearance',
          builder: (_, _) => const AppearanceScreen()),
      GoRoute(
          path: '/settings/export-data',
          builder: (_, _) => const ExportScreen()),
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

/// authProvider 변화를 GoRouter 에 알려 redirect 재평가하게 만드는 브릿지.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _sub = ref.listen(authProvider, (_, _) => notifyListeners());
  }
  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
