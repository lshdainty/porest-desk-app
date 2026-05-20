import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_notifier.dart';
import '../features/asset/presentation/asset_screen.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/card/presentation/card_detail_screen.dart';
import '../features/card/presentation/card_screen.dart';
import '../features/category/presentation/category_screen.dart';
import '../features/dutch_pay/presentation/dutch_pay_screen.dart';
import '../features/group/presentation/group_detail_screen.dart';
import '../features/group/presentation/group_screen.dart';
import '../features/memo/presentation/memo_screen.dart';
import '../features/notification/presentation/notification_screen.dart';
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
      GoRoute(path: '/assets', builder: (_, _) => const AssetScreen()),
      GoRoute(path: '/budget', builder: (_, _) => const BudgetScreen()),
      GoRoute(path: '/recurring', builder: (_, _) => const RecurringScreen()),
      GoRoute(path: '/categories', builder: (_, _) => const CategoryScreen()),
      GoRoute(path: '/presets', builder: (_, _) => const PresetScreen()),
      GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
      // 통계 — branch 에서 빠져 More 메뉴에서 진입하는 standalone screen.
      // (branch 2 가 캘린더로 변경됨, mobile_tab_bar 의 '캘린더' 메뉴 정합)
      GoRoute(path: '/stats', builder: (_, _) => const StatsScreen()),
      GoRoute(path: '/memos', builder: (_, _) => const MemoScreen()),
      GoRoute(path: '/todos', builder: (_, _) => const TodoScreen()),
      GoRoute(path: '/groups', builder: (_, _) => const GroupScreen()),
      GoRoute(
        path: '/groups/:id',
        builder: (_, state) => GroupDetailScreen(
          groupId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(path: '/dutch-pay', builder: (_, _) => const DutchPayScreen()),
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationScreen()),
      GoRoute(path: '/saving-goals', builder: (_, _) => const SavingGoalScreen()),
      GoRoute(path: '/cards', builder: (_, _) => const CardScreen()),
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
