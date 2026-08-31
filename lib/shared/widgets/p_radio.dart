import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// specs/components/radio-group.md 미러.
///
/// 2개+ mutually exclusive 옵션 단일 선택 (form submit 필요 시). 즉시 효과는
/// SegmentedControl, 5+ 옵션은 [PSelect].
///
/// 18×18 item + 16×16 dot. unchecked=borderStrong 1px, checked=borderBrand 1px
/// + fgBrand dot.
class PRadio<T> extends StatelessWidget {
  const PRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.semanticLabel,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;

  static const double _itemSize = 18;
  static const double _dotSize = 14;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = onChanged == null;
    final selected = value == groupValue;

    final item = AnimatedContainer(
      duration: PMotion.fast,
      curve: PMotion.standard,
      width: _itemSize,
      height: _itemSize,
      decoration: BoxDecoration(
        color: t.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: disabled
              ? t.borderDefault
              : (selected ? t.borderBrand : t.borderStrong),
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: PMotion.fast,
          curve: PMotion.standard,
          width: selected ? _dotSize : 0,
          height: selected ? _dotSize : 0,
          decoration: BoxDecoration(
            color: disabled ? t.fgDisabled : t.fgBrand,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );

    return Semantics(
      label: semanticLabel,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: !disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled || selected ? null : () => onChanged!(value),
        child: SizedBox(width: 44, height: 44, child: Center(child: item)),
      ),
    );
  }
}

/// item + label row — label 클릭 toggle, vertical group은 `gap-sm`(8) 권장.
class PRadioTile<T> extends StatelessWidget {
  const PRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    this.subtitle,
  });

  final T value;
  final T? groupValue;
  final ValueChanged<T>? onChanged;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final disabled = onChanged == null;
    final selected = value == groupValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled || selected ? null : () => onChanged!(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              PRadio<T>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                semanticLabel: label,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.body,
                        fontWeight: PFontWeight.medium,
                        color: disabled ? t.fgDisabled : t.fgPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.caption,
                          fontWeight: PFontWeight.regular,
                          color: t.fgTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
