import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';

/// 증권 라우트 가드 — 구독(SECURITIES) 미보유 시 홈으로 리다이렉트(딥링크 직접 접근 차단).
/// 메뉴 숨김은 UX, 이 가드는 클라이언트 차단(서버는 별도 403 게이트).
class SecuritiesGate extends ConsumerWidget {
  const SecuritiesGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(myFeaturesProvider);
    if (features.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final ok = features.asData?.value.hasSecurities ?? false;
    if (!ok) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold(body: SizedBox.shrink());
    }
    return child;
  }
}
