import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/core/auth/auth_notifier.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';
import 'package:groo_damda_app/shared/ds/result_section/p_result_section.dart';

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
/// ds Result Section(large · done)이 화면 가운데에, [로그인 화면으로] 는 화면 바닥 Bottom CTA(좌우 24 ·
/// 안전 영역 위)다. 폭 420 까지. 바닥은 셸 밖 흰 면이다(I-05 26 · 27 · 77).
class WithdrawnScreen extends ConsumerWidget {
  const WithdrawnScreen({super.key});

  void _toLogin(BuildContext context, WidgetRef ref) {
    // 에러를 먼저 걷는다 — 남아 있으면 라우터가 다시 이 화면으로 돌려보낸다.
    ref.read(authProvider.notifier).dismissLoginError();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return PopScope(
      // 리다이렉트로 들어온 화면이라 되돌아갈 곳이 없다 — 뒤로가기는 버튼과 같다.
      // 막아 두지 않으면 예측형 뒤로가기가 앱을 닫는다(update_gate_screen 과 같은 방식).
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _toLogin(context, ref);
      },
      child: Scaffold(
        // 셸 밖 화면은 흰 면 하나(Q11 11B)
        backgroundColor: context.colors.bgLayerDefault,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: PResultSection(
                          kind: PResultKind.done,
                          // 화면 제목이라 머리말 1단계
                          headingLevel: 1,
                          title: l.withdrawnTitle,
                          // 두 문장을 두 문단으로 — 문구는 줄이지 않는다
                          description:
                              '${l.withdrawnBody}\n\n${l.withdrawIrreversibleRejoin}',
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PSpacing.x6,
                      PSpacing.x4,
                      PSpacing.x6,
                      PSpacing.x6,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: PButton(
                        label: l.withdrawnToLogin,
                        size: PButtonSize.large,
                        onPressed: () => _toLogin(context, ref),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
