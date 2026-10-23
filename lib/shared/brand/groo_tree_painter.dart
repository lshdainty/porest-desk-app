// 생성 파일 — 손으로 고치지 않는다.
// 생성기: ~/qa/design-work/logo-assets/gen-tree-painter.py (원본 /home/lshdainty/study/groo_logo.svg 의 path 를 그대로 옮김)
// 보기 상자 147 183 154 166 — 폭 : 높이 = 154 : 166.
import 'package:flutter/widgets.dart';

/// 나무 로고의 보기 상자(폭 : 높이).
const double kGrooTreeAspect = 154 / 166;

/// 시안 고정 칠의 나무 로고를 그린다 — 라이트 · 다크 같다. 크기는 [paint] 의 size.
class GrooTreePainter extends CustomPainter {
  const GrooTreePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 154;
    final sy = size.height / 166;
    double x(double v) => (v - 147) * sx;
    double y(double v) => (v - 183) * sy;
    // trunk #A96D57
    canvas.drawPath(
      Path()
        ..moveTo(x(212), y(282))
        ..lineTo(x(235), y(282))
        ..cubicTo(x(234), y(304), x(237), y(323), x(244), y(339))
        ..lineTo(x(203), y(339))
        ..cubicTo(x(210), y(321), x(212), y(303), x(212), y(282))
        ..close(),
      Paint()
        ..color = const Color(0xFFA96D57)
        ..isAntiAlias = true,
    );
    // left-leaf #075B3C
    canvas.drawPath(
      Path()
        ..moveTo(x(163), y(193))
        ..cubicTo(x(182), y(191), x(207), y(201), x(224), y(212))
        ..cubicTo(x(245), y(230), x(248), y(261), x(224), y(288))
        ..cubicTo(x(201), y(290), x(178), y(282), x(166), y(265))
        ..cubicTo(x(154), y(248), x(154), y(215), x(163), y(193))
        ..close(),
      Paint()
        ..color = const Color(0xFF075B3C)
        ..isAntiAlias = true,
    );
    // right-leaf #43BF5E
    canvas.drawPath(
      Path()
        ..moveTo(x(224), y(212))
        ..cubicTo(x(242), y(201), x(265), y(194), x(284), y(193))
        ..cubicTo(x(292), y(214), x(294), y(245), x(282), y(265))
        ..cubicTo(x(271), y(282), x(248), y(290), x(224), y(288))
        ..cubicTo(x(201), y(263), x(200), y(232), x(224), y(212))
        ..close(),
      Paint()
        ..color = const Color(0xFF43BF5E)
        ..isAntiAlias = true,
    );
    // overlap #218D49
    canvas.drawPath(
      Path()
        ..moveTo(x(224), y(212))
        ..cubicTo(x(245), y(230), x(248), y(261), x(224), y(288))
        ..cubicTo(x(201), y(263), x(200), y(232), x(224), y(212))
        ..close(),
      Paint()
        ..color = const Color(0xFF218D49)
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(GrooTreePainter oldDelegate) => false;
}
