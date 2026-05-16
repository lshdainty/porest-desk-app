import 'package:flutter/material.dart';

import '../../app/theme/elevation.dart';
import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';

/// porest-desk-front `<Card>` 미러 + desk-app 실사용 bordered/muted variant 확장.
///
/// specs/components/card.md 기본 spec:
/// - radius `radius-lg` (12px)
/// - **border 없음** — shadow-only elevation (`shadow-sm`)
/// - 시각 padding `spacing-xl` (24px) 권장
///
/// variant:
/// - [PCardVariant.shadow] *(spec default)*: border 없음, shadow-sm
/// - [PCardVariant.bordered]: bgSurface + 1px borderSubtle, shadow 없음
///   (desk-app 리스트/요약 카드 — 시각 noise 최소화, dense 구성)
/// - [PCardVariant.muted]: bgMuted + border 없음, shadow 없음
///   (정보 박스 — surface와 톤 분리해 secondary 위계 표현)
/// - [PCardVariant.brand]: bgBrandSubtle + borderBrand
///   (강조 카드 — selected/active 상태)
enum PCardVariant { shadow, bordered, muted, brand }

class PCard extends StatelessWidget {
  const PCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = PRadius.brLg,
    this.variant = PCardVariant.shadow,
    this.color,
    this.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final PCardVariant variant;

  /// bg 색상 명시 override (variant 기본값 무시).
  final Color? color;

  /// border 명시 override (variant 기본값 무시).
  final BoxBorder? border;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (defaultBg, defaultBorder, useShadow) = switch (variant) {
      PCardVariant.shadow => (t.bgSurface, null, true),
      PCardVariant.bordered =>
        (t.bgSurface, Border.all(color: t.borderSubtle), false),
      PCardVariant.muted => (t.bgMuted, null, false),
      PCardVariant.brand =>
        (t.bgBrandSubtle, Border.all(color: t.borderBrand), false),
    };
    final wrap = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? defaultBg,
        borderRadius: borderRadius,
        border: border ?? defaultBorder,
        boxShadow: useShadow ? PorestElevation.sm : null,
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
