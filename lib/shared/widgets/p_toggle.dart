import 'package:flutter/material.dart';

import '../../app/theme/motion.dart';
import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

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
  });

  final List<PToggleGroupItem<T>> items;
  final T? value;
  final ValueChanged<T> onChanged;
  final PToggleSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: PRadius.brMd,
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) VerticalDivider(width: 1, thickness: 1, color: t.borderDefault),
                _GroupItem<T>(
                  item: items[i],
                  selected: items[i].value == value,
                  onTap: () => onChanged(items[i].value),
                  size: size,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
  });

  final List<PToggleGroupItem<T>> items;
  final Set<T> value;
  final ValueChanged<Set<T>> onChanged;
  final PToggleSize size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: PRadius.brMd,
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) VerticalDivider(width: 1, thickness: 1, color: t.borderDefault),
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
                ),
              ],
            ],
          ),
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
  });
  final PToggleGroupItem<T> item;
  final bool selected;
  final VoidCallback onTap;
  final PToggleSize size;

  (double padX, double padY, double minH) get _metrics => switch (size) {
        PToggleSize.sm => (8, 4, 28),
        PToggleSize.defaultSize => (12, 4, 32),
        PToggleSize.lg => (16, 8, 40),
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = item.disabled;
    final fg = selected ? t.fgPrimary : t.fgSecondary;
    final (padX, padY, minH) = _metrics;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: selected ? t.bgMuted : Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
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
                      fontWeight: selected ? PFontWeight.semi : PFontWeight.medium,
                      color: fg,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
