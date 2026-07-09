import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/colors.dart';
import 'package:porest_desk_app/features/constellation/domain/constellation.dart';

/// colorKey(blue/violet/...) → 차트 팔레트 색. 다크모드는 light variant
/// (웹 --color-cat-* 별칭 = resolveChartColor 정합, chart palette 는 raw 인용 허용 영역).
Color constellationColor(BuildContext context, String colorKey) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return switch (colorKey) {
    'red' => isDark ? PorestPalette.chartRedLight : PorestPalette.chartRed,
    'orange' => isDark ? PorestPalette.chartOrangeLight : PorestPalette.chartOrange,
    'yellow' => isDark ? PorestPalette.chartYellowLight : PorestPalette.chartYellow,
    'green' => isDark ? PorestPalette.chartGreenLight : PorestPalette.chartGreen,
    'blue' => isDark ? PorestPalette.chartBlueLight : PorestPalette.chartBlue,
    'indigo' => isDark ? PorestPalette.chartIndigoLight : PorestPalette.chartIndigo,
    'violet' => isDark ? PorestPalette.chartVioletLight : PorestPalette.chartViolet,
    'pink' => isDark ? PorestPalette.chartPinkLight : PorestPalette.chartPink,
    'brown' => isDark ? PorestPalette.chartBrownLight : PorestPalette.chartBrown,
    _ => isDark ? PorestPalette.chartGrayLight : PorestPalette.chartGray,
  };
}

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
    this.uniformScale = true,
  });

  final StarMapData map;
  final Color color;
  final int? lit;
  final bool dim;
  final bool glow;

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

    final linePaint = Paint()
      ..color = color.withValues(alpha: dim ? 0.35 : 0.55)
      ..strokeWidth = size.shortestSide * 0.022
      ..strokeCap = StrokeCap.round;

    for (final e in map.edges) {
      if (e.length < 2) continue;
      final a = e[0];
      final b = e[1];
      if (a >= n || b >= n || a >= map.pts.length || b >= map.pts.length) continue;
      canvas.drawLine(at(map.pts[a]), at(map.pts[b]), linePaint);
    }

    final litPaint = Paint()..color = color.withValues(alpha: dim ? 0.55 : 1);
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final unlitPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.014;

    final rLit = size.shortestSide * 0.034;
    final rUnlit = size.shortestSide * 0.026;
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
      old.map != map || old.color != color || old.lit != lit || old.dim != dim || old.glow != glow;
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
  });

  final ConstellationInfo info;
  final Color color;
  final double size;
  final int? lit;
  final bool dim;
  final bool glow;

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
        ),
      ),
    );
  }
}
