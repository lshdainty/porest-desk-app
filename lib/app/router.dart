import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'env.dart';
import 'theme/spacing.dart';
import 'theme/tokens.dart';
import 'theme/typography.dart';

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
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(title: const Text('Porest Desk')),
      body: ListView(
        padding: const EdgeInsets.all(PSpace.x24),
        children: [
          Text('🚧 Phase 3 디자인 시스템 적용 완료',
              style: PTypo.h3.copyWith(color: t.fgPrimary)),
          const SizedBox(height: PSpace.x8),
          Text('다크/라이트 모드는 OS 설정을 따라간다 (Phase 7에서 설정 화면 추가).',
              style: PTypo.bodySm.copyWith(color: t.fgTertiary)),
          const SizedBox(height: PSpace.x24),

          _envRow('API_BASE', Env.apiBase, t),
          _envRow('SSO_URL', Env.ssoUrl, t),
          _envRow('AUTH_CALLBACK', Env.authCallbackUri, t),

          const SizedBox(height: PSpace.x32),
          Text('컬러 팔레트', style: PTypo.h4.copyWith(color: t.fgPrimary)),
          const SizedBox(height: PSpace.x12),
          _swatch('Brand', t.bgBrand, t.fgOnBrand),
          _swatch('Surface', t.bgSurface, t.fgPrimary),
          _swatch('Muted', t.bgMuted, t.fgSecondary),
          _swatch('Success', t.statusSuccess, t.fgOnBrand),
          _swatch('Warning', t.statusWarning, t.fgOnBrand),
          _swatch('Danger', t.statusDanger, t.fgOnDanger),
          _swatch('Info', t.statusInfo, t.fgOnBrand),

          const SizedBox(height: PSpace.x32),
          FilledButton(onPressed: () {}, child: const Text('Filled Button')),
          const SizedBox(height: PSpace.x8),
          OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
          const SizedBox(height: PSpace.x8),
          TextButton(onPressed: () {}, child: const Text('Text')),
          const SizedBox(height: PSpace.x16),
          const TextField(decoration: InputDecoration(hintText: '입력 예시')),
        ],
      ),
    );
  }

  Widget _envRow(String k, String v, PorestTokens t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(k, style: PTypo.caption.copyWith(color: t.fgSecondary)),
            ),
            Expanded(
              child: Text(v, style: PTypo.bodySm.copyWith(color: t.fgPrimary)),
            ),
          ],
        ),
      );

  Widget _swatch(String label, Color bg, Color fg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: PSpace.x12, vertical: PSpace.x12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
          child: Text(label, style: PTypo.body.copyWith(color: fg)),
        ),
      );
}
