import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';

/// 첫 부팅 시 세션 검증(`/auth/check`) 동안 보여주는 splash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bgSurface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Porest Desk',
              style: PTypo.displayMd.copyWith(color: t.fgPrimary),
            ),
            const SizedBox(height: PSpace.x24),
            PCircularProgressIndicator(color: t.bgBrand),
          ],
        ),
      ),
    );
  }
}
