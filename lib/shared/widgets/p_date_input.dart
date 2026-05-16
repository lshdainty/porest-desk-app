import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// front `<InputDatePicker>` 등가 — 탭하면 DatePicker, 빈 값 처리.
class PDateInput extends StatelessWidget {
  const PDateInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.placeholder = '날짜 선택',
    this.allowClear = false,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String placeholder;
  final bool allowClear;

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: () async {
        final p = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime(2030, 12, 31),
        );
        if (p != null) onChanged(p);
      },
      borderRadius: PRadius.brSm,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x12),
        decoration: BoxDecoration(
          color: t.bgMuted,
          borderRadius: PRadius.brSm,
          border: Border.all(color: t.borderDefault),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.calendar, size: 16, color: t.fgSecondary),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: Text(
                value != null ? _fmt(value!) : placeholder,
                style: PTypo.bodyLg.copyWith(
                  color: value != null ? t.fgPrimary : t.fgTertiary,
                ),
              ),
            ),
            if (allowClear && value != null)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(LucideIcons.x, size: 14, color: t.fgTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

/// 시간 선택 input. value 는 [hour], [minute] tuple.
class PTimeInput extends StatelessWidget {
  const PTimeInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = '시간 선택',
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String placeholder;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: () async {
        final p = await showTimePicker(
          context: context,
          initialTime: value ?? TimeOfDay.now(),
        );
        if (p != null) onChanged(p);
      },
      borderRadius: PRadius.brSm,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x12),
        decoration: BoxDecoration(
          color: t.bgMuted,
          borderRadius: PRadius.brSm,
          border: Border.all(color: t.borderDefault),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.clock, size: 16, color: t.fgSecondary),
            const SizedBox(width: PSpace.x8),
            Text(
              value != null ? _fmt(value!) : placeholder,
              style: PTypo.bodyLg.copyWith(
                color: value != null ? t.fgPrimary : t.fgTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
