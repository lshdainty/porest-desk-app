import 'package:flutter/material.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration:
          BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brSm),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(o.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        o.value == value ? t.bgBrand : Colors.transparent,
                    borderRadius: PRadius.brXs,
                  ),
                  alignment: Alignment.center,
                  child: Text(o.label,
                      style: PTypo.caption.copyWith(
                          color: o.value == value
                              ? t.fgOnBrand
                              : t.fgSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
