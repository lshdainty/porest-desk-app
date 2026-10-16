import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 띠 사이 · 맨 위 간격 — 회색 바닥이 8 만큼 비친다(SEED Divider "강함"). 02-005 / Q-019-3 사용자 결정.
const double kScreenBandGap = PSpacing.x2;

/// 띠 안쪽 위 · 아래 여백.
const double kScreenBandPaddingTop = PSpacing.x1;
const double kScreenBandPaddingBottom = PSpacing.x2;

/// 화면 폭 흰 띠(`bg-layer-default`) 하나 — 띠 화면(설정 · 전체 · 캘린더 · 알림 · 폼)이 묶음마다 이것을 둔다.
/// 바닥은 `bg-layer-basement` 이고 띠는 그 위에 8 띄워 쌓인다([PScreenBands]). 띠 안은 위 4 · 아래 8 이며 좌우는
/// 안의 내용이 정한다(화면 가장자리 24). 카드 화면(홈 · 자산 · 통계 · 예산)은 띠가 아니라 회색 바닥 위 카드이고,
/// 흰 화면은 가계부 거래 목록뿐이다.
class PScreenBand extends StatelessWidget {
  const PScreenBand({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('screen-band'),
      color: context.colors.bgLayerDefault,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(
            top: kScreenBandPaddingTop,
            bottom: kScreenBandPaddingBottom,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 띠를 세로로 쌓는다 — 맨 위 8 · 띠 사이 8. 스크롤 목록 안의 자식으로 풀어 쓸 때는 [PScreenBands.children] 을 쓴다.
class PScreenBands {
  const PScreenBands._();

  /// 맨 위 8 을 먼저 두고 띠 사이마다 8 을 낀 자식 목록.
  static List<Widget> children(List<Widget> bands) => [
    const SizedBox(height: kScreenBandGap),
    for (var i = 0; i < bands.length; i++) ...[
      if (i > 0) const SizedBox(height: kScreenBandGap),
      bands[i],
    ],
  ];
}
