import 'package:flutter/widgets.dart';

import 'package:porest_desk_app/app/theme/porest_tokens.g.dart';

/// 들임 — full(끝까지, 기본) · inset(양끝 16).
enum PDividerInset { full, inset }

/// Divider — 1px 선. 구조는 SEED Divider, 수치 원본은 porest-design `specs/components/divider.yaml`(값은
/// `test/fixtures/design_spec/divider.json`). 웹(desk-front `src/shared/ds/divider`)과 같은 값이다.
///
/// 모든 방향 · 자리 1px, stroke-neutral-subtle(장식). 바깥 여백이 없다 — 선 위아래 · 좌우 간격은 쓰는 자리가 정하고
/// 들임(inset — 양끝 16)만 Divider 가 갖는다. 세로 선은 부모가 높이를 정한다(Row 안에서 IntrinsicHeight 등) —
/// 높이가 정해지지 않으면 0 이다(웹과 같다).
/// 장식이라 읽지 않는다 — 문서의 장처럼 구분선을 알려야 할 자리만 [semanticsLabel] 을 준다.
class PDivider extends StatelessWidget {
  const PDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.inset = PDividerInset.full,
    this.semanticsLabel,
  });

  /// 가로(세로로 쌓인 내용 사이, 기본) · 세로(가로로 놓인 칸 사이).
  final Axis axis;
  final PDividerInset inset;
  final String? semanticsLabel;

  static const double thickness = 1;

  @override
  Widget build(BuildContext context) {
    final pad = inset == PDividerInset.inset ? PSpacing.x4 : 0.0;
    // 길이를 정하지 않은 Container — 부모가 길이를 주면 채우고, 안 주면 0 이다(웹 flex 안의 선과 같다).
    // IntrinsicHeight 안에서도 잴 수 있다.
    final Widget divider = axis == Axis.horizontal
        ? Container(
            height: thickness,
            margin: EdgeInsets.symmetric(horizontal: pad),
            color: context.colors.strokeNeutralSubtle,
          )
        : Container(
            width: thickness,
            margin: EdgeInsets.symmetric(vertical: pad),
            color: context.colors.strokeNeutralSubtle,
          );
    if (semanticsLabel == null) return ExcludeSemantics(child: divider);
    return Semantics(container: true, label: semanticsLabel, child: divider);
  }
}
