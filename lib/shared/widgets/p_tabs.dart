import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// specs/components/tabs.md 미러.
///
/// 같은 영역에서 view group 간 전환. 3 variants:
/// - [PTabsVariant.container] *(default)*: surface-input wrapper + active pill에
///   surface-default + shadow-sm. 설정/form section.
/// - [PTabsVariant.underline]: colorless + active 시 primary 색 + 2px 하단 라인.
///   profile/detail page (Toss 절제 톤).
/// - [PTabsVariant.pills]: radius-md soft rectangle + active 시 primary fill +
///   on-accent 흰색 600. 모바일 navigation (큰 hit area).
enum PTabsVariant { container, underline, pills }

/// container 전용 size (tabs.md Container size variant). underline/pills 미적용.
enum PTabsSize { defaultSize, sm }

class PTabItem<T> {
  const PTabItem({required this.value, required this.label, this.icon, this.disabled = false});
  final T value;
  final String label;
  final IconData? icon;
  final bool disabled;
}

class PTabs<T> extends StatelessWidget {
  const PTabs({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.variant = PTabsVariant.container,
    this.size = PTabsSize.defaultSize,
    this.expand = false,
  });

  final List<PTabItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final PTabsVariant variant;

  /// container 전용 size (default 40 / sm 32). underline/pills 무시.
  final PTabsSize size;

  /// `true` 면 trigger 균등 분배 (`Expanded`로 wrap).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    switch (variant) {
      case PTabsVariant.container:
        return _container(t);
      case PTabsVariant.underline:
        return _underline(t);
      case PTabsVariant.pills:
        return _pills(t);
    }
  }

  Widget _container(PorestTokens t) {
    // tabs.md Container size variant — default(list 40 / trigger 32 · 4×12 · 14) ·
    //   sm(list 32 / trigger 28 · 4×8 · 13). track=surface-input(bgMuted), active=surface-default+shadow-sm.
    final sm = size == PTabsSize.sm;
    final children = [
      for (final it in items)
        _trigger(t, it,
            padX: sm ? 8 : 12,
            padY: 4,
            radius: PRadius.brXs,
            fontSize: sm ? PFontSize.bodySm : PFontSize.body,
            height: sm ? 28 : 32),
    ];
    return Container(
      height: sm ? 32 : 40,
      padding: EdgeInsets.all(sm ? 2 : 4),
      decoration: BoxDecoration(
        color: t.bgMuted,
        borderRadius: PRadius.brSm,
      ),
      child: expand
          ? Row(children: [for (final c in children) Expanded(child: c)])
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _underline(PorestTokens t) {
    final children = [
      for (final it in items)
        _trigger(t, it, padX: 12, padY: 8, radius: BorderRadius.zero),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.borderDefault)),
      ),
      child: expand
          ? Row(children: [for (final c in children) Expanded(child: c)])
          : Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _pills(PorestTokens t) {
    final children = [
      for (final it in items)
        _trigger(t, it, padX: 12, padY: 8, radius: PRadius.brMd),
    ];
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: PSpace.x4),
          if (expand) Expanded(child: children[i]) else children[i],
        ],
      ],
    );
  }

  Widget _trigger(
    PorestTokens t,
    PTabItem<T> item, {
    required double padX,
    required double padY,
    required BorderRadius radius,
    double fontSize = PFontSize.body,
    double? height,
  }) {
    final active = item.value == value;
    final disabled = item.disabled;

    Color textColor;
    Color? bgColor;
    BoxDecoration? decoration;
    FontWeight weight = PFontWeight.medium;

    switch (variant) {
      case PTabsVariant.container:
        textColor = active ? t.fgPrimary : t.fgSecondary;
        decoration = active
            ? BoxDecoration(
                color: t.bgSurface,
                borderRadius: radius,
                boxShadow: t.shadowSm,
              )
            : null;
        break;
      case PTabsVariant.underline:
        textColor = active ? t.fgBrand : t.fgSecondary;
        decoration = BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? t.borderBrand : Colors.transparent,
              width: 2,
            ),
          ),
        );
        break;
      case PTabsVariant.pills:
        textColor = active ? t.fgOnBrand : t.fgSecondary;
        bgColor = active ? t.bgBrand : Colors.transparent;
        decoration = BoxDecoration(
          color: bgColor,
          borderRadius: radius,
        );
        weight = active ? PFontWeight.semi : PFontWeight.medium;
        break;
    }

    final inner = Padding(
      padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.icon != null) ...[
            Icon(item.icon, size: 16, color: textColor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              item.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: PTypo.sans,
                fontSize: fontSize,
                fontWeight: weight,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );

    return AnimatedContainer(
      duration: PMotion.fast,
      curve: PMotion.standard,
      height: height,
      decoration: decoration,
      child: Opacity(
        opacity: disabled ? 0.5 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled || active ? null : () => onChanged(item.value),
            borderRadius: radius == BorderRadius.zero ? null : radius,
            child: inner,
          ),
        ),
      ),
    );
  }
}

/// Tabs + content 묶음 helper. content은 [valueToContent] 콜백으로 lazy 빌드.
class PTabsView<T> extends StatelessWidget {
  const PTabsView({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.valueToContent,
    this.variant = PTabsVariant.container,
    this.size = PTabsSize.defaultSize,
    this.expand = false,
    this.contentTopGap,
  });

  final List<PTabItem<T>> items;
  final T value;
  final ValueChanged<T> onChanged;
  final Widget Function(BuildContext, T) valueToContent;
  final PTabsVariant variant;
  final PTabsSize size;
  final bool expand;
  final double? contentTopGap;

  @override
  Widget build(BuildContext context) {
    final gap = contentTopGap ?? switch (variant) {
          PTabsVariant.container => PSpace.x8,
          PTabsVariant.pills => PSpace.x12,
          PTabsVariant.underline => PSpace.x16,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        PTabs<T>(
          items: items,
          value: value,
          onChanged: onChanged,
          variant: variant,
          size: size,
          expand: expand,
        ),
        SizedBox(height: gap),
        valueToContent(context, value),
      ],
    );
  }
}
