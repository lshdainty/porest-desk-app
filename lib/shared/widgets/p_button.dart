import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';
import 'package:porest_desk_app/shared/widgets/p_tooltip.dart';

/// front `<Button>` (shadcn) 미러 — variant 별 일관 스타일.
///
/// variants: primary / secondary / outline / ghost(중립) / accent(brand 강조) / danger
/// size: sm / md / lg / iconLg(모바일 크롬 헤더 icon-only 전용 — 36×36 원형, glyph 20px)
enum PButtonVariant { primary, secondary, dangerSoft, outline, ghost, accent, danger }

enum PButtonSize { sm, md, lg, iconLg }

/// 컨테이너 edge 에 붙는 ghost 버튼 광학 정렬용 — 해당 방향 좌/우 padding 제거.
/// front `<Button flush="left|right">` 미러. box·hover 영역 위치는 그대로.
enum PButtonFlush { left, right }

class PButton extends StatelessWidget {
  const PButton({
    super.key,
    this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = PButtonVariant.primary,
    this.size = PButtonSize.md,
    this.loading = false,
    this.fullWidth = false,
    this.tooltip,
    this.iconColor,
    this.dangerous = false,
    this.flush,
  })  : assert(label != null || icon != null,
            'PButton requires either a label or an icon'),
        assert(size != PButtonSize.iconLg || label == null,
            'iconLg는 icon-only 전용 (모바일 크롬 헤더)');

  /// icon-only 생성자 — front `<Button size="icon" variant="ghost">` 대응.
  /// 가로 = 높이 (정사각), padding 작게.
  const PButton.icon({
    super.key,
    required IconData this.icon,
    this.onPressed,
    this.variant = PButtonVariant.ghost,
    this.size = PButtonSize.md,
    this.loading = false,
    this.tooltip,
    this.iconColor,
    this.dangerous = false,
  })  : label = null,
        fullWidth = false,
        trailingIcon = null,
        flush = null;

  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  /// 라벨 우측 아이콘 (chevron / external-link 등) — spec button.md ⓓ trailing icon.
  final IconData? trailingIcon;
  final PButtonVariant variant;
  final PButtonSize size;
  final bool loading;
  final bool fullWidth;
  final String? tooltip;
  /// icon-only ghost 버튼에서 아이콘 색만 override (예: trash danger).
  /// label 모드에서도 icon 만 분리 색 적용.
  final Color? iconColor;
  /// ghost variant 에 위험(파괴적) 액션 색을 입힌다 — fg/icon → statusDangerFg.
  /// dialog footer 의 "삭제" 같이 filled `danger` 보다 절제된 표현이 필요한 곳.
  /// 다른 variant 와 함께 쓰면 무시.
  final bool dangerous;
  /// 컨테이너 edge flush — 해당 방향 좌/우 padding 제거 (ghost 버튼 광학 정렬).
  /// label 모드에만 의미 있음 (icon-only/iconLg 는 padding 0 이라 무관).
  final PButtonFlush? flush;

  // DESIGN.desk.md / specs/components/button.md spec:
  // sm: h=32, padY=4 padX=8, font=caption(12), radius=sm(4), icon=14
  // md: h=40, padY=8 padX=12, font=body-md(15), radius=sm(4), icon=16
  // lg: h=48, padY=12 padX=16, font=title-sm(16), radius=md(8), icon=18
  // iconLg: 36×36, radius=full, glyph=20 — 모바일 크롬 헤더 icon-only (v97)
  double _height() => switch (size) {
        PButtonSize.sm => 32,
        PButtonSize.md => 40,
        PButtonSize.lg => 48,
        PButtonSize.iconLg => 36,
      };

  EdgeInsetsGeometry _padding() {
    final (double h, double v) = switch (size) {
      PButtonSize.sm => (8, 4),
      PButtonSize.md => (12, 8),
      PButtonSize.lg => (16, 12),
      // icon-only 전용이라 build()에서 EdgeInsets.zero 경로만 탐 — 도달 불가.
      PButtonSize.iconLg => (0, 0),
    };
    // flush: 해당 방향 padding 만 0 (edge 광학 정렬).
    return EdgeInsets.fromLTRB(
      flush == PButtonFlush.left ? 0 : h,
      v,
      flush == PButtonFlush.right ? 0 : h,
      v,
    );
  }

  TextStyle _textStyle(PorestTokens t) => switch (size) {
        PButtonSize.sm => TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.caption,
              fontWeight: PFontWeight.medium,
              height: 1.0,
            ),
        PButtonSize.md => TextStyle(
              fontFamily: PTypo.sans,
              // button.md Sizes 표의 md = 15px. 표는 라벨을 body-lg 라 적었지만
              // 토큰 표(DESIGN.md)에서 15px 은 body-md 다 — px 를 따른다.
              fontSize: PFontSize.bodyMd,
              fontWeight: PFontWeight.medium,
              height: 1.0,
            ),
        PButtonSize.lg => TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.titleSm,
              fontWeight: PFontWeight.medium,
              height: 1.0,
            ),
        // icon-only 전용 (label 금지 assert) — 도달 불가, md와 동일값.
        PButtonSize.iconLg => TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.bodyMd,
              fontWeight: PFontWeight.medium,
              height: 1.0,
            ),
      };

  double _iconSize() => switch (size) {
        PButtonSize.sm => 14,
        PButtonSize.md => 16,
        PButtonSize.lg => 18,
        PButtonSize.iconLg => 20,
      };

  // button.md Sizes: sm=radius sm(4), md·lg=radius md(8).
  BorderRadius _radius() => switch (size) {
        PButtonSize.sm => PRadius.brSm,
        PButtonSize.md => PRadius.brMd,
        PButtonSize.lg => PRadius.brMd,
        PButtonSize.iconLg => PRadius.brFull,
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final iconOnly = label == null;
    Color bg;
    Color fg;
    BorderSide border;
    switch (variant) {
      case PButtonVariant.primary:
        // 채움색은 brand primary(#0147AD, 남색) 가 아니라 info(#1D6FCB) — 버튼 채움에
        // 한정한다(탭 선택·토글 등 brand 채움 자리는 bgBrandSolid 그대로).
        // 다크에서도 같은 값 고정 — 웹 --status-info 정합.
        // spec button.md Migration notes 2026-08.
        bg = t.statusInfo;
        fg = t.fgOnBrand;
        border = BorderSide.none;
        break;
      case PButtonVariant.secondary:
        // spec Color tokens 표에 border 가 없다 — 구현에만 있던 1px 을 뺐다(2026-08).
        bg = t.bgMuted;
        fg = t.fgPrimary;
        border = BorderSide.none;
        break;
      case PButtonVariant.dangerSoft:
        // 모달 footer 의 삭제 — 옅은 빨강 채움. 전체 폭 두 버튼이 나란히 설 때 ghost 는
        // 배경이 없어 버튼으로 안 보인다. 삭제 *확정* 은 danger(솔리드).
        bg = t.statusDangerSubtle;
        fg = t.statusDangerFg;
        border = BorderSide.none;
        break;
      case PButtonVariant.outline:
        bg = Colors.transparent;
        fg = t.fgPrimary;
        border = BorderSide(color: t.borderDefault);
        break;
      case PButtonVariant.ghost:
        bg = Colors.transparent;
        // icon-only ghost(아이콘 액션)는 보조톤 fgSecondary — front button.md v96 정합.
        // iconLg(모바일 크롬 헤더)는 페이지당 1개 주 액션 — 약화 없이 중립 fgPrimary (v97).
        fg = dangerous
            ? t.statusDangerFg
            : (iconOnly && size != PButtonSize.iconLg
                ? t.fgSecondary
                : t.fgPrimary);
        border = BorderSide.none;
        break;
      case PButtonVariant.accent:
        bg = Colors.transparent;
        fg = dangerous ? t.statusDangerFg : t.fgBrand;
        border = BorderSide.none;
        break;
      case PButtonVariant.danger:
        bg = t.statusDanger;
        fg = t.fgOnDanger;
        border = BorderSide.none;
        break;
    }

    final disabled = onPressed == null || loading;
    // icon-only는 radius-md 둥근 박스 (정사각 + 또렷한 hover/splash) — front button.md v96 정합.
    // iconLg는 원형(radius-full) — 모바일 크롬 헤더 (v97).
    final radius = iconOnly
        ? (size == PButtonSize.iconLg ? PRadius.brFull : PRadius.brMd)
        : _radius();
    final h = _height();
    final btn = Material(
      // disabled 약화는 아래 Opacity(0.5)로 버튼 전체(글자·아이콘 포함)에 적용
      // — button.md States(disabled = opacity 0.5) + 웹 disabled:opacity-50 정합.
      // bg.withValues(alpha)는 transparent(ghost/accent/outline)에서 RGB 0,0,0이
      // 남아 50% 검정으로 깔리고, 글자색은 안 흐려져 disabled 구분이 안 되던 버그.
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: border,
      ),
      child: InkWell(
        onTap: disabled ? null : onPressed,
        borderRadius: radius,
        child: SizedBox(
          height: h,
          width: iconOnly ? h : null,
          child: Padding(
            padding: iconOnly ? EdgeInsets.zero : _padding(),
            child: Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  PCircularProgressIndicator(
                    size: _iconSize(),
                    strokeWidth: 2,
                    color: fg,
                  )
                else if (icon != null)
                  Icon(icon, size: _iconSize(), color: iconColor ?? fg),
                if (!iconOnly && (loading || icon != null))
                  const SizedBox(width: PSpace.sm),
                if (!iconOnly)
                  Text(label!, style: _textStyle(t).copyWith(color: fg)),
                if (!iconOnly && trailingIcon != null) ...[
                  const SizedBox(width: PSpace.sm),
                  Icon(trailingIcon, size: _iconSize(), color: iconColor ?? fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final dimmed = disabled ? Opacity(opacity: 0.5, child: btn) : btn;
    final tipped = tooltip != null
        ? PTooltip(message: tooltip!, child: dimmed)
        : dimmed;
    return fullWidth ? SizedBox(width: double.infinity, child: tipped) : tipped;
  }
}

/// front `<Field>` 등가 — 라벨 + 입력 + 헬퍼/에러 텍스트 묶음.
class PField extends StatelessWidget {
  const PField({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.errorText,
    this.required = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final String? errorText;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: PTypo.caption.copyWith(
                    color: t.fgSecondary, fontWeight: PFontWeight.semi)),
            if (required) ...[
              const SizedBox(width: 2),
              Text('*',
                  style: PTypo.caption.copyWith(color: t.statusDanger)),
            ],
          ],
        ),
        const SizedBox(height: PSpace.x4),
        child,
        if (errorText != null) ...[
          const SizedBox(height: 2),
          Text(errorText!,
              style: PTypo.caption.copyWith(color: t.statusDanger)),
        ] else if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!,
              style: PTypo.caption.copyWith(color: t.fgTertiary)),
        ],
      ],
    );
  }
}
