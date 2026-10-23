import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/brand/groo_wordmark.dart';
import 'package:groo_damda_app/shared/ds/progress_circle/p_progress_circle.dart';

/// 나무 아래 원까지의 간격 — 화면 값(I-05 85), 스펙으로 만들지 않는다.
const double kSplashCircleGap = PSpacing.x8;

/// 첫 부팅 시 세션 검증(`/auth/check`) 동안 보여주는 splash.
///
/// 나무 96 + 16 + "그루 담다" 한 묶음을 화면 정중앙에 두고, 원 40 은 그 아래 32 에 둔다.
/// 원이 묶음을 위로 밀지 않는다 — 묶음의 위치는 원과 상관없이 정중앙이다(로고 결정 4A).
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 셸 밖 화면은 흰 면 하나(Q11 11B) — OS 시작 화면 바탕과 같다
      backgroundColor: context.colors.bgLayerDefault,
      body: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const GrooWordmark.vertical(),
            // 묶음 바로 아래 32 — 묶음 크기에 넣지 않아 묶음이 정중앙에 남는다
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: 0,
              child: OverflowBox(
                alignment: Alignment.bottomCenter,
                minWidth: 0,
                minHeight: 0,
                maxHeight: double.infinity,
                child: Transform.translate(
                  offset: const Offset(0, kSplashCircleGap + 40),
                  child: const SizedBox(
                    width: 40,
                    child: PProgressCircle(tone: PProgressCircleTone.brand),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
