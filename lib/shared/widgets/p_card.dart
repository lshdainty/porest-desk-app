import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';

/// porest-desk-front `<Card>` (variant: default) 미러.
///
///  className="rounded-[var(--radius-lg)] border bg-card shadow-[var(--shadow-sm)]"
///  --shadow-sm: 0 1px 2px rgba(28,36,20,0.06), 0 1px 3px rgba(28,36,20,0.04)
class PCard extends StatelessWidget {
  const PCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = PRadius.brLg,
    this.color,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? color;
  final BoxBorder? border;
  final VoidCallback? onTap;

  static const _shadow = [
    BoxShadow(
      color: Color(0x0F1C2414), // rgba(28,36,20, 0.06)
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
    BoxShadow(
      color: Color(0x0A1C2414), // rgba(28,36,20, 0.04)
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final wrap = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? t.bgSurface,
        borderRadius: borderRadius,
        border: border ?? Border.all(color: t.borderSubtle),
        boxShadow: _shadow,
      ),
      child: child,
    );
    if (onTap == null) return wrap;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: wrap,
      ),
    );
  }
}
