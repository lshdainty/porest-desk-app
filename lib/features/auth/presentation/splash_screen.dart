import 'package:flutter/material.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';

/// 첫 부팅 시 세션 검증(`/auth/check`) 동안 보여주는 splash.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bgCanvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Porest Desk', style: PTypo.displayMd.copyWith(color: t.fgPrimary)),
            const SizedBox(height: PSpace.x24),
            CircularProgressIndicator(color: t.bgBrand),
          ],
        ),
      ),
    );
  }
}
