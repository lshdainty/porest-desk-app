import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/colors.dart';
import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// specs/components/toggle.md 미러.
///
/// 단일 옵션의 on/off button-style 컨트롤. 텍스트 에디터 toolbar, filter chip 등.
/// 즉시 효과 binary 설정은 [PSwitch], form binary 입력은 [PCheckbox].
///
/// 2 variants(default/outline) × 3 sizes(sm/default/lg).
enum PToggleVariant { defaultVariant, outline }

enum PToggleSize { sm, defaultSize, lg }

class PToggle extends StatelessWidget {
  const PToggle({
    super.key,
    required this.pressed,
    required this.onChanged,
    this.label,
    this.icon,
    this.variant = PToggleVariant.defaultVariant,
    this.size = PToggleSize.defaultSize,
    this.semanticLabel,
  });

  final bool pressed;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final IconData? icon;
  final PToggleVariant variant;
  final PToggleSize size;
  final String? semanticLabel;

  (double padX, double padY, double minH) get _metrics => switch (size) {
    PToggleSize.sm => (8, 4, 28),
    PToggleSize.defaultSize => (12, 4, 32),
    PToggleSize.lg => (16, 8, 40),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = onChanged == null;
    final (padX, padY, minH) = _metrics;

    final bg = pressed ? t.bgMuted : Colors.transparent;
    final fg = pressed ? t.fgPrimary : t.fgSecondary;
    Border? border;
    if (variant == PToggleVariant.outline) {
      border = Border.all(color: pressed ? t.borderStrong : t.borderDefault);
    }

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Semantics(
        label: semanticLabel ?? label,
        toggled: pressed,
        enabled: !disabled,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : () => onChanged!(!pressed),
            borderRadius: PRadius.brMd,
            child: AnimatedContainer(
              duration: PMotion.fast,
              curve: PMotion.standard,
              constraints: BoxConstraints(minHeight: minH),
              padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: PRadius.brMd,
                border: border,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) Icon(icon, size: 16, color: fg),
                  if (icon != null && label != null) const SizedBox(width: 4),
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.caption,
                        fontWeight: PFontWeight.semi,
                        color: fg,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// specs/components/toggle-group.md 미러.
///
/// 여러 [PToggle]을 segmented connected 형태로 묶음. type=single (mutex) 또는
/// multiple (multi-select). root border + radius + divider만 — item별 border
/// 없음.
///
/// visual variants (intensity) — spec toggle-group.md Visual variants 정합:
/// - subtle (default) — active 회색 채움 + 검정 글씨 (토스 절제 톤)
/// - solid — active primary cobalt 채움 + 흰 글씨 + bold + subtle shadow (강조 톤)
enum PToggleGroupVisual { subtle, solid }

class PToggleGroupItem<T> {
  const PToggleGroupItem({
    required this.value,
    this.label,
    this.icon,
    this.disabled = false,
  });
  final T value;
  final String? label;
  final IconData? icon;
  final bool disabled;
}

/// type=single — 한 번에 1개만 selected. `value`/`onChanged`로 단일 값 관리.
class PToggleGroupSingle<T> extends StatelessWidget {
  const PToggleGroupSingle({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.size = PToggleSize.defaultSize,
    this.expanded = false,
    this.visual = PToggleGroupVisual.subtle,
  });

  final List<PToggleGroupItem<T>> items;
  final T? value;
  final ValueChanged<T> onChanged;
  final PToggleSize size;

  /// 가로 full-width + 자식 균등 분할 (Row 안 자식 Expanded). form 안 type
  /// segment 같이 부모 가로 가득 차야 하는 경우. desk-front segmented variant
  /// `w-full + flex-1` 패턴 parity.
  final bool expanded;

  /// active item 시각 강조도. spec toggle-group.md Visual variants 정합.
  final PToggleGroupVisual visual;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // spec toggle-group.md root + desk-front .p-seg wrapper 정합:
    //   inline-flex + gap-[2px] + rounded-md + border + bg-sunken + p-0.5(=2)
    final group = Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.bgSunken,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderDefault),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              if (expanded)
                Expanded(
                  child: _GroupItem<T>(
                    item: items[i],
                    selected: items[i].value == value,
                    onTap: () => onChanged(items[i].value),
                    size: size,
                    visual: visual,
                  ),
                )
              else
                _GroupItem<T>(
                  item: items[i],
                  selected: items[i].value == value,
                  onTap: () => onChanged(items[i].value),
                  size: size,
                  visual: visual,
                ),
            ],
          ],
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: group) : group;
  }
}

/// type=multiple — Set 으로 다중 선택 관리.
class PToggleGroupMultiple<T> extends StatelessWidget {
  const PToggleGroupMultiple({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.size = PToggleSize.defaultSize,
    this.visual = PToggleGroupVisual.subtle,
  });

  final List<PToggleGroupItem<T>> items;
  final Set<T> value;
  final ValueChanged<Set<T>> onChanged;
  final PToggleSize size;

  /// active item 시각 강조도. spec toggle-group.md Visual variants 정합.
  final PToggleGroupVisual visual;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.bgSunken,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderDefault),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _GroupItem<T>(
                item: items[i],
                selected: value.contains(items[i].value),
                onTap: () {
                  final next = {...value};
                  next.contains(items[i].value)
                      ? next.remove(items[i].value)
                      : next.add(items[i].value);
                  onChanged(next);
                },
                size: size,
                visual: visual,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupItem<T> extends StatelessWidget {
  const _GroupItem({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.size,
    required this.visual,
  });
  final PToggleGroupItem<T> item;
  final bool selected;
  final VoidCallback onTap;
  final PToggleSize size;
  final PToggleGroupVisual visual;

  (double padX, double padY, double minH) get _metrics => switch (size) {
    PToggleSize.sm => (8, 4, 28),
    PToggleSize.defaultSize => (12, 4, 32),
    PToggleSize.lg => (16, 8, 40),
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = item.disabled;
    final isSolid = visual == PToggleGroupVisual.solid;
    final fg = selected ? (isSolid ? t.fgOnBrand : t.fgPrimary) : t.fgSecondary;
    final bg = selected
        // solid active = primary 고정(cobalt500) — web --bg-brand(=--color-primary
        // 양모드 고정) 정합. bgBrand 는 다크에서 cobalt400(light)이라 더 밝아 어긋났음.
        ? (isSolid ? PorestPalette.cobalt500 : t.bgMuted)
        : Colors.transparent;
    final selectedWeight = isSolid ? PFontWeight.bold : PFontWeight.semi;
    final (padX, padY, minH) = _metrics;
    // spec / desk-front segmented item — 개별 radius-sm(4px) + 부모 sunken bar
    // 안에서 active 시 background 채움 (clipping 없음 — 자체 radius 보존).
    final tile = Material(
      color: bg,
      borderRadius: PRadius.brSm,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: PRadius.brSm,
        child: Container(
          constraints: BoxConstraints(minHeight: minH),
          padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (item.icon != null) Icon(item.icon, size: 16, color: fg),
              if (item.icon != null && item.label != null)
                const SizedBox(width: 4),
              if (item.label != null)
                Text(
                  item.label!,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: PFontSize.caption,
                    fontWeight: selected ? selectedWeight : PFontWeight.semi,
                    color: fg,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // spec solid 의 subtle shadow `0 1px 3px rgba(0,0,0,0.15)` — Flutter BoxShadow.
    final decorated = (isSolid && selected)
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: PRadius.brSm,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  offset: Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: tile,
          )
        : tile;
    return Opacity(opacity: disabled ? 0.5 : 1, child: decorated);
  }
}
