import 'package:flutter/material.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/features/constellation/domain/constellation.dart';

/// colorKey(blue/violet/...) → 차트 역할 색 `chart-{색}`. 다크는 토큰이 바꾼다(v110) — 라이트 · 다크 분기를 두지 않는다.
Color constellationColor(BuildContext context, String colorKey) =>
    constellationRoleColors(context.colors, colorKey).strong;

/// colorKey → 차트 역할 색 한 쌍 — 선 · 아이콘 `chart-{색}`, 옅은 바탕 `chart-{색}-weak`(v110 · v111).
({Color strong, Color weak}) constellationRoleColors(
  PColors c,
  String colorKey,
) => switch (colorKey) {
  'red' => (strong: c.chartRed, weak: c.chartRedWeak),
  'orange' => (strong: c.chartOrange, weak: c.chartOrangeWeak),
  'yellow' => (strong: c.chartYellow, weak: c.chartYellowWeak),
  'green' => (strong: c.chartGreen, weak: c.chartGreenWeak),
  'blue' => (strong: c.chartBlue, weak: c.chartBlueWeak),
  'indigo' => (strong: c.chartIndigo, weak: c.chartIndigoWeak),
  'violet' => (strong: c.chartViolet, weak: c.chartVioletWeak),
  'pink' => (strong: c.chartPink, weak: c.chartPinkWeak),
  'brown' => (strong: c.chartBrown, weak: c.chartBrownWeak),
  _ => (strong: c.chartGray, weak: c.chartGrayWeak),
};

/// 별자리 페인터 — 0-100 정규 좌표를 캔버스에 스케일해 연결선+별을 그린다.
/// [lit]: 켜진 별 개수(그 인덱스 미만 점등, null=전부). [dim]: 미수집 실루엣 톤.
/// [glow]: 점등 별에 은은한 발광(히어로/상세 감상용).
class ConstellationPainter extends CustomPainter {
  ConstellationPainter({
    required this.map,
    required this.color,
    this.lit,
    this.dim = false,
    this.glow = false,
    this.linesOnly = false,
    this.uniformScale = true,
  });

  final StarMapData map;
  final Color color;
  final int? lit;
  final bool dim;
  final bool glow;

  /// 썸네일 모드 — 선만 그려 작은 크기에서 뭉침 방지 (점등 상태 무관 전체 골격).
  final bool linesOnly;

  /// true: 정비율(썸네일/감상), false: 박스에 늘림(히어로 figure — 웹 preserveAspectRatio=none 정합).
  final bool uniformScale;

  @override
  void paint(Canvas canvas, Size size) {
    final n = lit ?? map.pts.length;
    final sx = size.width / 100;
    final sy = size.height / 100;
    final s = uniformScale ? (sx < sy ? sx : sy) : 0.0;
    final ox = uniformScale ? (size.width - 100 * s) / 2 : 0.0;
    final oy = uniformScale ? (size.height - 100 * s) / 2 : 0.0;

    Offset at(List<double> p) => uniformScale
        ? Offset(ox + p[0] * s, oy + p[1] * s)
        : Offset(p[0] * sx, p[1] * sy);

    // 별 수 적응형 크기 — 실좌표 별자리(2~27별)의 밀집 구간 겹침 방지
    final count = map.pts.length;
    final strokeScale = count <= 8
        ? 0.022
        : count <= 15
        ? 0.016
        : 0.012;
    final linePaint = Paint()
      ..color = color.withValues(alpha: dim ? 0.35 : 0.55)
      ..strokeWidth = size.shortestSide * strokeScale
      ..strokeCap = StrokeCap.round;

    for (final e in map.edges) {
      if (e.length < 2) continue;
      final a = e[0];
      final b = e[1];
      if (a >= map.pts.length || b >= map.pts.length) continue;
      // linesOnly(썸네일)는 점등 상태와 무관하게 전체 골격을 보여준다
      if (!linesOnly && (a >= n || b >= n)) continue;
      canvas.drawLine(at(map.pts[a]), at(map.pts[b]), linePaint);
    }
    if (linesOnly) return;

    final litPaint = Paint()..color = color.withValues(alpha: dim ? 0.55 : 1);
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final unlitPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.014;

    final rLit =
        size.shortestSide *
        (count <= 8
            ? 0.034
            : count <= 15
            ? 0.024
            : 0.018);
    final rUnlit =
        size.shortestSide *
        (count <= 8
            ? 0.026
            : count <= 15
            ? 0.019
            : 0.015);
    for (var i = 0; i < map.pts.length; i++) {
      final c = at(map.pts[i]);
      if (i < n) {
        if (glow) canvas.drawCircle(c, rLit * 2, glowPaint);
        canvas.drawCircle(c, rLit, litPaint);
      } else {
        canvas.drawCircle(c, rUnlit, unlitPaint);
      }
    }
  }

  @override
  bool shouldRepaint(ConstellationPainter old) =>
      old.map != map ||
      old.color != color ||
      old.lit != lit ||
      old.dim != dim ||
      old.glow != glow ||
      old.linesOnly != linesOnly;
}

/// 별자리 썸네일 아이콘 — 도감/밤하늘 그리드용.
class ConstellationIcon extends StatelessWidget {
  const ConstellationIcon({
    super.key,
    required this.info,
    required this.color,
    this.size = 24,
    this.lit,
    this.dim = false,
    this.glow = false,
    this.linesOnly = false,
  });

  final ConstellationInfo info;
  final Color color;
  final double size;
  final int? lit;
  final bool dim;
  final bool glow;
  final bool linesOnly;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ConstellationPainter(
          map: info.starMap,
          color: color,
          lit: lit,
          dim: dim,
          glow: glow,
          linesOnly: linesOnly,
        ),
      ),
    );
  }
}
