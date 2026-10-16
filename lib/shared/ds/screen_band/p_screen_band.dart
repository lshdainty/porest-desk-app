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

/// 카드 화면의 카드 하나 — 회색 바닥(`bg-layer-basement`) 위 `bg-layer-default` 면 + 1px `stroke-neutral-weak` + 모서리 12 +
/// 안쪽 24. 그림자는 없다(Elevation v104 — 카드는 선과 바닥으로 가른다). 카드 사이는 [kScreenBandGap](8).
/// 카드 화면(홈 · 자산 · 통계 · 예산 · 상세)이 쓴다. 띠 화면의 띠는 [PScreenBand] 다.
class PScreenCard extends StatelessWidget {
  const PScreenCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PSpacing.x6),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      key: const ValueKey('screen-card'),
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: c.bgLayerDefault,
        borderRadius: BorderRadius.circular(PRounded.r3),
        border: Border.all(color: c.strokeNeutralWeak),
      ),
      child: child,
    );
  }
}

/// 띠 화면의 본문 전체를 **하나의 흰 띠**로 감싼다 — 맨 위 8 은 회색 바닥, 그 아래는 화면 폭 흰 띠가 남은 높이를 채운다.
/// 묶음마다 띠를 나누지 않은 화면(목록 · 폼)이 쓰는 한 장 띠다. 묶음이 나뉘는 화면은 [PScreenBands] 로 띠를 직접 쌓는다.
class PScreenBandBody extends StatelessWidget {
  const PScreenBandBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: kScreenBandGap),
      child: ColoredBox(
        key: const ValueKey('screen-band-body'),
        color: context.colors.bgLayerDefault,
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
