import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/motion.dart';

/// specs/components/collapsible.md 미러.
///
/// 단일 토글 disclosure primitive — open/closed 상태에 따라 [content] mount/unmount.
/// 시각 spec 없음 (자유) — [trigger] 시각은 사용처가 결정. "show more"/"고급 옵션"
/// 같은 보조 콘텐츠 패턴. 여러 item은 [PAccordion] 사용.
///
/// trigger는 보통 [PButton] 또는 ListTile 형태. open 시 chevron 180° 회전 효과
/// 는 사용처에서 `Transform.rotate` + [PMotion.fast]로.
class PCollapsible extends StatefulWidget {
  const PCollapsible({
    super.key,
    required this.trigger,
    required this.content,
    this.initiallyOpen = false,
    this.open,
    this.onOpenChanged,
  });

  /// uncontrolled 시 초기 상태.
  final bool initiallyOpen;

  /// controlled 모드 — `open`이 null이 아니면 외부 상태 사용.
  final bool? open;

  /// trigger builder — `isOpen`을 받아 chevron 회전 등 처리.
  final Widget Function(BuildContext context, bool isOpen, VoidCallback toggle) trigger;

  final Widget content;

  final ValueChanged<bool>? onOpenChanged;

  @override
  State<PCollapsible> createState() => _PCollapsibleState();
}

class _PCollapsibleState extends State<PCollapsible>
    with SingleTickerProviderStateMixin {
  late bool _open;
  late final AnimationController _controller;
  late final Animation<double> _heightFactor;

  bool get _isOpen => widget.open ?? _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
    _controller = AnimationController(
      vsync: this,
      duration: PMotion.base,
      value: _isOpen ? 1 : 0,
    );
    _heightFactor = CurvedAnimation(parent: _controller, curve: PMotion.standard);
  }

  @override
  void didUpdateWidget(PCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.open != oldWidget.open && widget.open != null) {
      widget.open! ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !_isOpen;
    if (widget.open == null) {
      setState(() => _open = next);
      next ? _controller.forward() : _controller.reverse();
    }
    widget.onOpenChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.trigger(context, _isOpen, _toggle),
        SizeTransition(
          // 세로축 기준 위쪽 고정 — 기존 axisAlignment: -1 과 같은 값
          // (Axis.vertical 일 때 AlignmentDirectional(-1.0, axisAlignment)).
          sizeFactor: _heightFactor,
          alignment: AlignmentDirectional.topStart,
          child: widget.content,
        ),
      ],
    );
  }
}
