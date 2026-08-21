import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_picker_sheet.dart';

/// front `<InputDatePicker>` 등가 — 탭하면 DatePicker, 빈 값 처리.
class PDateInput extends StatelessWidget {
  const PDateInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.placeholder,
    this.allowClear = false,
    this.enabled = true,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? placeholder;
  final bool allowClear;

  /// false 면 값만 보여 준다 — 시스템이 만들어 못 고치는 값 등. PTextInput.enabled 와 같은 규약.
  final bool enabled;

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              final p = await showPDatePicker(
                context,
                initial: value ?? DateTime.now(),
                firstDate: firstDate,
                lastDate: lastDate,
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
            Icon(LucideIcons.calendar,
                size: 16, color: enabled ? t.fgSecondary : t.fgTertiary),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: Text(
                value != null ? _fmt(value!) : (placeholder ?? l.pickDate),
                style: PTypo.bodyLg.copyWith(
                  color: (value != null && enabled) ? t.fgPrimary : t.fgTertiary,
                ),
              ),
            ),
            if (allowClear && value != null && enabled)
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
    this.placeholder,
    this.enabled = true,
  });

  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;
  final String? placeholder;

  /// false 면 값만 보여 준다 — [PDateInput.enabled] 와 같은 규약.
  final bool enabled;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              final p = await showPTimePicker(
                context,
                initial: value ?? TimeOfDay.now(),
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
            Icon(LucideIcons.clock,
                size: 16, color: enabled ? t.fgSecondary : t.fgTertiary),
            const SizedBox(width: PSpace.x8),
            // 날짜 입력과 같은 처리 — 좁은 폭에서 라벨이 넘치지 않게.
            Expanded(
              child: Text(
                value != null ? _fmt(value!) : (placeholder ?? l.pickTime),
                style: PTypo.bodyLg.copyWith(
                  color: (value != null && enabled) ? t.fgPrimary : t.fgTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
