import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

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
/// - [PCardVariant.raised]: bgSurfaceRaised + shadow-lg
///   (모바일 카드 다이어트의 keep 카드 — design app.css `.m-scroll .p-card--keep`:
///   플랫 화면(배경=surface)에서 강조 요약/히어로만 raised 면 + lg 그림자로 띄운다.
///   다크=#2d3346 패널 / 라이트=흰 카드 + 그림자)
enum PCardVariant { shadow, bordered, muted, brand, raised }

class PCard extends StatelessWidget {
  const PCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = PRadius.brLg,
    this.variant = PCardVariant.shadow,
    this.color,
    this.border,
    this.onTap,
  });

  final Widget child;

  /// 명시 지정 시 그대로, 미지정 시 variant 기본값:
  /// - shadow: `EdgeInsets.all(24)` (card.md spec — `spacing-xl`)
  /// - bordered/muted/brand: `EdgeInsets.zero`
  ///   (list shell 패턴 — 자식 row가 자체 padding 가지는 게 일반적)
  final EdgeInsetsGeometry? padding;
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
    final (defaultBg, defaultBorder, shadow) = switch (variant) {
      PCardVariant.shadow => (t.bgSurface, null, t.shadowSm),
      PCardVariant.bordered =>
        (t.bgSurface, Border.all(color: t.borderSubtle), null),
      PCardVariant.muted => (t.bgMuted, null, null),
      PCardVariant.brand =>
        (t.bgBrandSubtle, Border.all(color: t.borderBrand), null),
      PCardVariant.raised => (t.bgSurfaceRaised, null, t.shadowLg),
    };
    final effectivePadding = padding ??
        (variant == PCardVariant.shadow || variant == PCardVariant.raised
            ? const EdgeInsets.all(PSpace.lg)
            : EdgeInsets.zero);
    final wrap = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: color ?? defaultBg,
        borderRadius: borderRadius,
        border: border ?? defaultBorder,
        boxShadow: shadow,
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

/// shadcn `<CardHeader>` 미러. title + description 세로 stack용 padding 컨테이너.
/// caller 가 `PCard(padding: EdgeInsets.zero, child: Column([PCardHeader(...), PCardContent(...)]))`
/// 형태로 조립. spec card.md `flex flex-col gap-xs p-xl` 매핑.
class PCardHeader extends StatelessWidget {
  const PCardHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(PSpace.lg),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}

/// shadcn `<CardContent>` 미러. caller 가 [afterHeader] true 면 top padding 0
/// (shadcn 의 `:not(:first-child) pt-0` 자연 연결 패턴 대응).
class PCardContent extends StatelessWidget {
  const PCardContent({
    super.key,
    required this.child,
    this.afterHeader = false,
    this.padding,
  });
  final Widget child;

  /// PCardHeader 또는 다른 PCard 섹션 다음에 오면 true — top padding 0.
  final bool afterHeader;

  /// 명시 padding (예: 안에 list rows 이라 horizontal 만). 미지정 시:
  /// - afterHeader = true: `EdgeInsets.fromLTRB(xl, 0, xl, xl)`
  /// - false: `EdgeInsets.all(xl)`
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = padding ??
        (afterHeader
            ? const EdgeInsets.fromLTRB(
                PSpace.lg, 0, PSpace.lg, PSpace.lg)
            : const EdgeInsets.all(PSpace.lg));
    return Padding(padding: p, child: child);
  }
}

/// shadcn `<CardFooter>` 미러. [afterHeader] 동일 의미 (content 다음이면 top 0).
class PCardFooter extends StatelessWidget {
  const PCardFooter({
    super.key,
    required this.child,
    this.afterHeader = true,
    this.padding,
  });
  final Widget child;
  final bool afterHeader;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) {
    final p = padding ??
        (afterHeader
            ? const EdgeInsets.fromLTRB(
                PSpace.lg, 0, PSpace.lg, PSpace.lg)
            : const EdgeInsets.all(PSpace.lg));
    return Padding(padding: p, child: child);
  }
}

/// shadcn `<CardTitle>` 미러 — `body-lg` (16) + bold (Web 의 `text-title-md` 와
/// 동일 16px 매핑).
class PCardTitle extends StatelessWidget {
  const PCardTitle(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      text,
      style: (style ?? PTypo.bodyLg).copyWith(
        color: t.fgPrimary,
        fontWeight: PFontWeight.bold,
        letterSpacing: -0.225,
      ),
    );
  }
}

/// shadcn `<CardDescription>` 미러 — `body-sm` + fgSecondary.
class PCardDescription extends StatelessWidget {
  const PCardDescription(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text(
      text,
      style: PTypo.bodySm.copyWith(color: t.fgSecondary),
    );
  }
}
