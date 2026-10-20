import 'dart:ui' show PathMetric;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';
import 'package:groo_damda_app/shared/ds/aspect_ratio/p_aspect_ratio.dart';
import 'package:groo_damda_app/shared/ds/catalog/demo_kit.dart';

const Map<PAspectRatioValue, String> _labels = {
  PAspectRatioValue.r1x1: '정사각',
  PAspectRatioValue.r2x1: '넓은 띠',
  PAspectRatioValue.r16x9: '동영상',
  PAspectRatioValue.r4x3: '기본',
  PAspectRatioValue.r6x7: '조금 세로',
  PAspectRatioValue.r4x5: '세로',
  PAspectRatioValue.r2x3: '긴 세로',
  PAspectRatioValue.card: '카드 1.586',
};

/// 카탈로그(/dev/ds) — 비율 여덟 가지(폭 120, 점선은 상자 자리 — 상자는 바탕 · 모서리가 없다), 자식이 상자를 채우고
/// 넘치는 그림은 가운데를 남겨 자른다(cover).
class AspectRatioDemo extends StatelessWidget {
  const AspectRatioDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DemoBlock(
          title: '비율 여덟 가지 — 폭 120, 점선은 상자 자리(상자는 바탕 · 모서리가 없다)',
          children: [
            Wrap(
              spacing: PSpacing.x4,
              runSpacing: PSpacing.x4,
              crossAxisAlignment: WrapCrossAlignment.start,
              children: [
                for (final ratio in PAspectRatioValue.values)
                  SizedBox(
                    width: 120,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: PSpacing.x2,
                      children: [
                        CustomPaint(
                          foregroundPainter: _DashedOutlinePainter(
                            c.fgNeutralSubtle,
                          ),
                          child: PAspectRatio(
                            ratio: ratio,
                            child: CustomPaint(painter: _HatchPainter(c)),
                          ),
                        ),
                        Text(
                          '${ratio.id} — ${_labels[ratio]}',
                          style: PTypography.t2.copyWith(
                            color: c.fgNeutralSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        DemoBlock(
          title: '자식 — 그림은 상자를 채우고 가운데를 남겨 자른다(cover), 지도는 상자 크기 그대로',
          children: [
            DemoRow(
              label: '1:1 지도',
              children: [
                SizedBox(
                  width: 200,
                  child: PAspectRatio(
                    ratio: PAspectRatioValue.r1x1,
                    child: _CoverMap(c),
                  ),
                ),
              ],
            ),
            DemoRow(
              label: '16:9 넓은 그림',
              children: [
                SizedBox(
                  width: 280,
                  child: PAspectRatio(
                    ratio: PAspectRatioValue.r16x9,
                    child: _CoverMap(c),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// 정사각 지도 그림을 상자에 cover 로 — 가운데를 남겨 자른다.
class _CoverMap extends StatelessWidget {
  const _CoverMap(this.colors);

  final PColors colors;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox.square(
        dimension: 600,
        child: CustomPaint(painter: _MapPainter(colors)),
      ),
    );
  }
}

/// 상자 자리를 보이는 빗금 — 상자는 바탕이 없다(미리보기용 덧칠).
class _HatchPainter extends CustomPainter {
  const _HatchPainter(this.colors);

  final PColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final paint = Paint()
      ..color = colors.bgNeutralWeak
      ..strokeWidth = 6;
    // 위에서 아래로 135° 빗금 — 6 칠하고 6 비운다(웹 repeating-linear-gradient 0 6 · 6 12)
    final span = size.width + size.height;
    for (var d = 0.0; d < span + 12; d += 12 * 1.4142135) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d - size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.colors != colors;
}

class _DashedOutlinePainter extends CustomPainter {
  const _DashedOutlinePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addRect((Offset.zero & size).deflate(0.5));
    for (final PathMetric metric in path.computeMetrics()) {
      var at = 0.0;
      while (at < metric.length) {
        canvas.drawPath(metric.extractPath(at, at + 4), paint);
        at += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutlinePainter old) => old.color != color;
}

/// 지도 대역 — 그림이 아닌 자리의 예(길 · 건물 · 현재 위치).
class _MapPainter extends CustomPainter {
  const _MapPainter(this.colors);

  final PColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = colors.bgNeutralWeak;
    canvas.drawRect(Offset.zero & size, land);
    final road = Paint()
      ..color = colors.bgLayerDefault
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28;
    final edge = Paint()
      ..color = colors.strokeNeutralWeak
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final line in [
      [const Offset(0, 380), const Offset(600, 300)],
      [const Offset(180, 0), const Offset(260, 600)],
      [const Offset(0, 140), const Offset(600, 220)],
    ]) {
      canvas.drawLine(line[0], line[1], road);
      canvas.drawLine(line[0], line[1], edge);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(330, 360, 150, 110),
        const Radius.circular(10),
      ),
      Paint()..color = colors.bgPositiveWeak,
    );
    canvas.drawCircle(
      const Offset(300, 270),
      22,
      Paint()..color = colors.bgBrandSolid,
    );
    canvas.drawCircle(
      const Offset(300, 270),
      8,
      Paint()..color = colors.bgLayerDefault,
    );
  }

  @override
  bool shouldRepaint(_MapPainter old) => old.colors != colors;
}
