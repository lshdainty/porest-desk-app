import 'package:flutter/material.dart';

import '../../app/theme/elevation.dart';
import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';

/// porest-desk-front `<Card>` (variant: default) 미러.
///
/// specs/components/card.md spec:
/// - radius `radius-lg` (12px)
/// - **border 없음** — shadow-only elevation (`shadow-sm`)
/// - 시각 padding `spacing-xl` (24px) 권장 (사용처별 조정 가능)
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

  /// 명시적 border 지정 (선택). 기본값 없음 — spec: shadow-only elevation.
  final BoxBorder? border;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final wrap = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? t.bgSurface,
        borderRadius: borderRadius,
        border: border,
        boxShadow: PorestElevation.sm,
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
