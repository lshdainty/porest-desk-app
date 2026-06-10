import 'package:flutter/material.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';

/// front shadcn `<ToggleGroup variant="segmented">` 미러.
///
/// 기간 선택, 거래종류 등 — track(`bgMuted`) + active(`bgBrand`) 패턴.
/// 사용 예:
/// ```dart
/// PSegmented<FilterPeriod>(
///   value: _period,
///   onChanged: (v) => setState(() => _period = v),
///   options: const [
///     PSegmentOption(value: FilterPeriod.week, label: '이번 주'),
///     ...
///   ],
/// )
/// ```
class PSegmentOption<T> {
  const PSegmentOption({required this.value, required this.label});
  final T value;
  final String label;
}

class PSegmented<T> extends StatelessWidget {
  const PSegmented({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<PSegmentOption<T>> options;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // ToggleGroup variant="segmented" spec (desk-front .p-seg):
    // wrapper: bg-sunken + border-default + radius-md + p-0.5 (2px)
    // item: h-7 (28) + caption(12/600) + active=bg-brand
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.bgSunken,
        borderRadius: PRadius.brMd,
        border: Border.all(color: t.borderDefault),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.value),
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color:
                        o.value == value ? t.bgBrand : Colors.transparent,
                    borderRadius: PRadius.brSm,
                  ),
                  alignment: Alignment.center,
                  child: Text(o.label,
                      style: PTypo.caption.copyWith(
                          color: o.value == value
                              ? t.fgOnBrand
                              : t.fgSecondary,
                          fontWeight: PFontWeight.semi)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
