import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'env.dart';

/// Phase 4 에서 StatefulShellRoute(홈/가계부/통계/전체) 로 교체된다.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const _ScaffoldPlaceholder(),
      ),
    ],
  );
});

class _ScaffoldPlaceholder extends StatelessWidget {
  const _ScaffoldPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Porest Desk')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚧 Phase 2 스캐폴드 완료', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            _kv('API_BASE', Env.apiBase),
            _kv('SSO_URL', Env.ssoUrl),
            _kv('AUTH_CALLBACK', Env.authCallbackUri),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('$k = $v', style: const TextStyle(fontFamily: 'monospace')),
      );
}
