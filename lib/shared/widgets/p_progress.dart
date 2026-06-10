import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/tokens.dart';

/// 디자인 시스템 표준 spinner — porest-design `specs/components/spinner.md` 미러.
///
/// Material 기본 `CircularProgressIndicator`(가변 호) 가 아니라, 웹 `<Spinner>` 와
/// **동일한 ring 시각**: `border-default` track 풀 링 + 상단 90° arc(`fg-brand`,
/// 다크 자동 primary-light swap) 가 360° 회전(`motion-duration-loop` 1500ms linear).
///
/// 사용:
/// ```dart
/// const PCircularProgressIndicator()                       // md 24
/// PCircularProgressIndicator(size: 16)                     // sm inline
/// PCircularProgressIndicator(size: 18, strokeWidth: 2, color: fg) // 버튼 안
/// ```
class PCircularProgressIndicator extends StatefulWidget {
  const PCircularProgressIndicator({
    super.key,
    this.size = 24,
    this.strokeWidth = 2.5,
    this.color,
  });

  /// 위젯 크기(정사각). spec: sm 16 / md 24 / lg 32 / xl 48.
  final double size;
  final double strokeWidth;

  /// arc 색 override (기본 `fg-brand`). 버튼 위에선 버튼 fg 전달.
  final Color? color;

  @override
  State<PCircularProgressIndicator> createState() =>
      _PCircularProgressIndicatorState();
}

class _PCircularProgressIndicatorState extends State<PCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500), // motion-duration-loop
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => CustomPaint(
          painter: _SpinnerPainter(
            turns: _ctrl.value,
            arc: widget.color ?? t.fgBrand,
            track: t.borderDefault,
            stroke: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({
    required this.turns,
    required this.arc,
    required this.track,
    required this.stroke,
  });

  final double turns; // 0..1 (한 바퀴)
  final Color arc;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    if (radius <= 0) return;

    // track — 회전 안 보이는 풀 링 (border-default).
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    // arc — 상단 90° (web border-top-color 정합), 회전.
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = -math.pi / 2 + turns * 2 * math.pi;
    canvas.drawArc(
      rect,
      start,
      math.pi / 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = arc,
    );
  }

  @override
  bool shouldRepaint(covariant _SpinnerPainter old) =>
      old.turns != turns ||
      old.arc != arc ||
      old.track != track ||
      old.stroke != stroke;
}
