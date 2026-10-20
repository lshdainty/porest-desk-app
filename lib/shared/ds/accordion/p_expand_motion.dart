import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:groo_damda_app/app/theme/groo_tokens.g.dart';

/// 펼치고 접는 모션 — Accordion · Collapsible · List 의 하위 줄([PListParentItem])이 모두 이 위젯 하나를 쓴다
/// (groo-design `accordion.yaml` motion "펼침 · 접힘 — 높이", list.yaml 은 "Accordion 과 같다"). 웹의 `useExpandMotion`
/// (desk-front `src/shared/ds/accordion/use-expand-motion.ts`)과 같은 값이다.
///
/// 높이 300ms([PDuration.d6] · [PEasing.easing]) — 지금 높이에서 목표까지 이어 가고(움직이는 도중에 다시 누르면 지금
/// 높이에서 되돌아간다), 모션 줄이기면 높이를 움직이지 않고 150ms([PDuration.d3]) 서서히 나타나고 사라진다. 처음 그릴 때는
/// 움직이지 않는다. 접힘이 끝나면 [child] 를 트리에서 뺀다(그리지 않고 · 읽지 않고 · 포커스도 받지 않는다 — 웹과 달리 안의
/// 상태는 접히면 사라진다).
///
/// 여백은 [child] 안에 둔다(바깥 감싸개는 높이만 움직인다). 테스트가 움직임을 짚을 수 있게 층마다 키를 단다 —
/// `<keyPrefix>-hidden`(접힘이 끝난 자리) · `<keyPrefix>-fade`(모션 줄이기) · `<keyPrefix>-clip`(높이).
class PExpandMotion extends StatefulWidget {
  const PExpandMotion({
    super.key,
    required this.open,
    required this.child,
    this.keyPrefix = 'pexpand',
  });

  final bool open;
  final Widget child;
  final String keyPrefix;

  @override
  State<PExpandMotion> createState() => _PExpandMotionState();
}

class _PExpandMotionState extends State<PExpandMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.open ? 1 : 0,
  )..addStatusListener(_onStatus);

  /// 이번 움직임이 모션 줄이기인지 — 움직이기 시작할 때 정한다.
  bool _fadeOnly = false;

  void _onStatus(AnimationStatus status) {
    // 접힘이 끝나면 내용을 트리에서 뺀다
    // (animateTo 는 방향이 늘 forward 라 0 에 닿아도 completed 로 끝난다 — 값으로 본다)
    final done =
        status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed;
    if (done && _controller.value == 0 && mounted) setState(() {});
  }

  @override
  void didUpdateWidget(PExpandMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open == widget.open) return;
    _fadeOnly = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _controller.animateTo(
      widget.open ? 1 : 0,
      duration: _fadeOnly ? PDuration.d3 : PDuration.d6,
      curve: PEasing.easing,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open && _controller.value == 0) {
      return SizedBox.shrink(key: ValueKey('${widget.keyPrefix}-hidden'));
    }
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => _fadeOnly
          ? Opacity(
              key: ValueKey('${widget.keyPrefix}-fade'),
              opacity: _controller.value,
              child: child,
            )
          : ClipRect(
              key: ValueKey('${widget.keyPrefix}-clip'),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                heightFactor: math.max(_controller.value, 0),
                child: child,
              ),
            ),
    );
  }
}
