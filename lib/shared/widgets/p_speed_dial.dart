import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 빠른 액션 SpeedDial — 메인 FAB 탭 시 자식 액션이 펼쳐지는 패턴.
///
/// 모바일에서 거래 추가 / 빠른 메모 / 할 일 추가 등 다중 quick-action 에 활용.
class PSpeedDial extends StatefulWidget {
  const PSpeedDial({
    super.key,
    required this.icon,
    required this.children,
    this.tooltip,
  });

  final IconData icon;
  final List<PSpeedDialChild> children;
  final String? tooltip;

  @override
  State<PSpeedDial> createState() => _PSpeedDialState();
}

class _PSpeedDialChildBuilt extends StatelessWidget {
  const _PSpeedDialChildBuilt({
    required this.child,
    required this.onClose,
    required this.tokens,
  });
  final PSpeedDialChild child;
  final VoidCallback onClose;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (child.label != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tokens.bgSurface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Text(child.label!,
                  style: PTypo.caption.copyWith(
                      color: tokens.fgPrimary,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
          ],
          FloatingActionButton.small(
            heroTag: 'pspeed-${child.label ?? child.icon.codePoint}',
            backgroundColor: tokens.bgSurface,
            foregroundColor: tokens.fgPrimary,
            elevation: 2,
            onPressed: () {
              onClose();
              child.onPressed();
            },
            child: Icon(child.icon, size: 18),
          ),
        ],
      ),
    );
  }
}

class _PSpeedDialState extends State<PSpeedDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  bool _open = false;

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open)
          for (final c in widget.children)
            _PSpeedDialChildBuilt(child: c, onClose: _close, tokens: t),
        const SizedBox(height: 6),
        FloatingActionButton(
          backgroundColor: t.bgBrand,
          foregroundColor: t.fgOnBrand,
          tooltip: widget.tooltip,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_open ? LucideIcons.x : widget.icon),
          ),
        ),
      ],
    );
  }
}

class PSpeedDialChild {
  const PSpeedDialChild({
    required this.icon,
    required this.onPressed,
    this.label,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
}
