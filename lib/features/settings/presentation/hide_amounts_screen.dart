import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/features/settings/presentation/hide_amounts_panel.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';

/// 금액 가리기 화면 — 계정 > 보안 > 금액 가리기.
///
/// 화면별로 37장을 훑어야 하는 목록이라 다른 설정에 끼워 두면 그 화면을 통째로
/// 밀어낸다. 잠금·인증과 한 묶음이니 보안 아래 자기 화면을 준다.
class HideAmountsScreen extends StatelessWidget {
  const HideAmountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.hideAmountsTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x20,
          vertical: PSpace.x24,
        ),
        children: const [HideAmountsPanel()],
      ),
    );
  }
}
