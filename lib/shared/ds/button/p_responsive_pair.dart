import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/button/p_button.dart';

/// 짝 버튼 사이 간격.
const double kResponsivePairGap = PSpacing.x2;

/// 짝 버튼(SEED ResponsivePair, 03A-013) — 주 버튼과 보조 버튼 둘을 폭이 허락하면 한 줄에 반씩 놓고, **한 라벨이 짝 폭의
/// 절반을 넘으면 세로로 쌓는다**(주 버튼이 위, 둘 다 전체 폭). 라벨은 어느 쪽이든 한 줄이다 — 줄바꿈하거나 말줄이지 않는다.
///
/// 한 줄일 때 보조(왼쪽) · 주(오른쪽) 순서고, 쌓으면 주 · 보조 순서다. 글자 크기 설정으로 라벨이 커지면 폭을 다시 재서
/// 알아서 쌓인다(200% 에서 가장 긴 라벨이 반 폭을 넘는 대가는 쌓는 것으로 받는다).
class PResponsivePair extends StatelessWidget {
  const PResponsivePair({
    super.key,
    required this.primary,
    required this.secondary,
  });

  final PButton primary;
  final PButton secondary;

  /// 한 줄에 반씩 들어가는 폭인가.
  @visibleForTesting
  static bool fitsInRow(
    double pairWidth,
    double primaryWidth,
    double secondaryWidth,
  ) {
    final half = (pairWidth - kResponsivePairGap) / 2;
    return primaryWidth <= half && secondaryWidth <= half;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fits = fitsInRow(
          constraints.maxWidth,
          primary.naturalWidth(context),
          secondary.naturalWidth(context),
        );
        if (fits) {
          return Row(
            key: const ValueKey('pair-row'),
            spacing: kResponsivePairGap,
            children: [
              Expanded(child: secondary),
              Expanded(child: primary),
            ],
          );
        }
        return Column(
          key: const ValueKey('pair-column'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: kResponsivePairGap,
          children: [primary, secondary],
        );
      },
    );
  }
}
