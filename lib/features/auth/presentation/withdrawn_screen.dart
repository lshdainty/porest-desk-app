import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';

/// 해지 완료 화면 — 웹 `WithdrawnPage` 와 같은 화면·같은 문구.
///
/// **로그인 없이 열린다.** 두 자리에서 온다.
///  - 방금 해지한 사람 — 해지 시트가 이 화면으로 보낸 뒤 로그아웃한다
///  - 해지한 계정으로 다시 로그인하려다 `USER_021` 을 받은 사람 — 라우터가 보낸다
///
/// 둘이 알아야 할 것이 같다. 끝났고, 남은 데이터는 처리방침대로 보관 후 파기되고, 같은
/// 아이디로는 다시 못 들어온다. 예전엔 앞은 6초짜리 토스트(폰에서 4줄, 재가입 안내 없음),
/// 뒤는 로그인 화면의 빨간 에러 글(데이터 안내 없음)이었다 — 사라지거나 서로 다른 말을
/// 했다(2026-09-22 사용자 결정: 앱도 웹처럼 화면으로).
///
/// 치수는 웹 그대로다 — 아이콘 40, 줄 사이 20, 본문 두 줄 사이 8, 폭 420 까지.
class WithdrawnScreen extends ConsumerWidget {
  const WithdrawnScreen({super.key});

  void _toLogin(BuildContext context, WidgetRef ref) {
    // 에러를 먼저 걷는다 — 남아 있으면 라우터가 다시 이 화면으로 돌려보낸다.
    ref.read(authProvider.notifier).dismissLoginError();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final body = PTypo.body.copyWith(color: t.fgSecondary);
    return PopScope(
      // 리다이렉트로 들어온 화면이라 되돌아갈 곳이 없다 — 뒤로가기는 버튼과 같다.
      // 막아 두지 않으면 예측형 뒤로가기가 앱을 닫는다(update_gate_screen 과 같은 방식).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _toLogin(context, ref);
      },
      child: Scaffold(
        backgroundColor: t.bgCanvas,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x20,
                vertical: PSpace.x40,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.circleCheck,
                      size: 40,
                      color: t.statusSuccessFg,
                    ),
                    const SizedBox(height: PSpace.x20),
                    Text(
                      l.withdrawnTitle,
                      textAlign: TextAlign.center,
                      style: PTypo.h4.copyWith(color: t.fgPrimary),
                    ),
                    const SizedBox(height: PSpace.x20),
                    Text(
                      l.withdrawnBody,
                      textAlign: TextAlign.center,
                      style: body,
                    ),
                    const SizedBox(height: PSpace.sm),
                    Text(
                      l.withdrawIrreversibleRejoin,
                      textAlign: TextAlign.center,
                      style: body,
                    ),
                    const SizedBox(height: PSpace.x20),
                    PButton(
                      label: l.withdrawnToLogin,
                      variant: PButtonVariant.secondary,
                      onPressed: () => _toLogin(context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
