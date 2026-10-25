import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 채운 별 — lucide 에는 채운 모양이 없어(선 아이콘뿐) 그린다. 웹 `<Star fill="currentColor">` 와 같은 모양이다: 24 칸 격자의
/// 오각 별을 [color] 로 채우고 같은 색 둥근 선 2 를 두른다(끝이 둥글다). 장식이라 읽지 않는다 — 뜻은 쓰는 쪽(칸 이름)이 말한다.
class PFilledStar extends StatelessWidget {
  const PFilledStar({super.key, required this.size, required this.color});

  /// 한 변(정사각).
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      key: const ValueKey('filled-star'),
      size: Size.square(size),
      painter: FilledStarPainter(color),
    ),
  );
}

/// [PFilledStar] 의 그림 — 시험이 모양(점 열 개 · 가운데)과 색을 본다.
@visibleForTesting
class FilledStarPainter extends CustomPainter {
  const FilledStarPainter(this.color);

  final Color color;

  /// 24 칸 격자에서 별의 바깥 반지름 · 안쪽 반지름 · 가운데(선 두께 2 의 절반이 더 나간다).
  static const double outer = 9;
  static const double inner = 4.7;
  static const Offset center = Offset(12, 12.9);

  /// 24 칸 격자 안의 별 — 위 꼭짓점부터 시계 방향으로 바깥 · 안쪽을 번갈아 열 점.
  static Path path24() {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final path = path24();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(FilledStarPainter old) => old.color != color;
}
