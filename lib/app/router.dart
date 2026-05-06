import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/expense/presentation/expense_screen.dart';
import '../features/more/presentation/more_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../shared/widgets/mobile_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,
    routes: [
      // 모바일 셸 (홈/가계부/통계/전체 4개 분기)
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
              pageBuilder: (_, _) => const NoTransitionPage(child: ExpenseScreen()),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/stats',
              pageBuilder: (_, _) => const NoTransitionPage(child: StatsScreen()),
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

      // 셸 외부 라우트 (Phase 5 에서 LoginScreen, AuthCallback 추가)
    ],
  );
});
