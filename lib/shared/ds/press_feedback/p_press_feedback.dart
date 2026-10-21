import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 옛 부품(`lib/shared/widgets`)에 누름 축소를 더한다(State › Feedback, 01A-063) — 누르는 동안 세로 2px 거리만큼 줄고(기준
/// 길이 max(높이, 폭 ÷ 4, 24)) 손을 떼면 돌아온다. 포인터만 듣고 제스처 경쟁에는 끼지 않는다(안쪽 InkWell · GestureDetector 가
/// 그대로 받는다). 모션 줄이기면 줄지 않는다. 새 부품([PressScale])은 자기 축소를 이미 가진다.
class PPressFeedback extends StatefulWidget {
  const PPressFeedback({super.key, this.enabled = true, required this.child});

  final bool enabled;
  final Widget child;

  @override
  State<PPressFeedback> createState() => _PPressFeedbackState();
}

class _PPressFeedbackState extends State<PPressFeedback> {
  bool _pressed = false;
  double _basis = 24;

  void _down() {
    final size = context.size;
    if (size != null) {
      _basis = math.max(size.height, math.max(size.width / 4, 24));
    }
    setState(() => _pressed = true);
  }

  void _up() {
    if (_pressed) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _down(),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: AnimatedScale(
        scale: _pressed && !reduce ? (_basis - 2) / _basis : 1,
        duration: PDuration.pressedScale,
        curve: PEasing.pressedScale,
        child: widget.child,
      ),
    );
  }
}
