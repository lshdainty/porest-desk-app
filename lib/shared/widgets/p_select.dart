import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// specs/components/select.md 미러.
///
/// Trigger spec:
/// - h-10 (40), padding sm·md (8·12), font body-md (15)
/// - radius-sm (4), border 1px border-default, bg surface-input
/// - 우측 chevron-down 16px
///
/// Content (모바일 친화):
/// - showModalBottomSheet 로 띄움. 각 item h-44 + 선택 시 checkmark.
class PSelectItem<T> {
  const PSelectItem({required this.value, required this.label});
  final T value;
  final String label;
}

class PSelect<T> extends StatelessWidget {
  const PSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.items,
    this.placeholder = '선택',
    this.title,
    this.enabled = true,
    this.errorText,
    this.helperText,
  });

  final T? value;
  final ValueChanged<T?> onChanged;
  final List<PSelectItem<T>> items;
  final String placeholder;

  /// bottom-sheet 헤더에 표시할 제목 (선택).
  final String? title;
  final bool enabled;

  /// 검증 실패 메시지 — 있으면 invalid state (border-error + helper color text-error).
  /// specs/components/select.md error state 정합.
  final String? errorText;

  /// idle state 보조 텍스트 — control 아래 caption. errorText 우선.
  final String? helperText;

  Future<void> _open(BuildContext context) async {
    final picked = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: context.tokens.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PRadius.xl2)),
      ),
      builder: (ctx) {
        final t = ctx.tokens;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: PSpace.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.bgMuted,
                  borderRadius: PRadius.brFull,
                ),
              ),
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      PSpace.lg, PSpace.md, PSpace.lg, PSpace.xs),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(title!,
                        style: PTypo.h4.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold)),
                  ),
                ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    final selected = it.value == value;
                    return InkWell(
                      onTap: () => Navigator.of(ctx).pop(it.value),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(
                            horizontal: PSpace.lg),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(it.label,
                                  style: PTypo.bodyLg.copyWith(
                                    color: t.fgPrimary,
                                    fontWeight: selected
                                        ? PFontWeight.semi
                                        : PFontWeight.regular,
                                  )),
                            ),
                            if (selected)
                              Icon(LucideIcons.check,
                                  size: 18, color: t.fgBrand),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: PSpace.sm),
            ],
          ),
        );
      },
    );
    if (picked != null && picked != value) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final hasValue = value != null;
    final hasError = errorText != null;
    final label = hasValue
        ? items
            .firstWhere(
              (i) => i.value == value,
              orElse: () => PSelectItem<T>(value: value as T, label: ''),
            )
            .label
        : placeholder;
    final trigger = Material(
      color: enabled ? t.bgMuted : t.bgDisabled,
      borderRadius: PRadius.brSm,
      child: InkWell(
        onTap: enabled ? () => _open(context) : null,
        borderRadius: PRadius.brSm,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.md, vertical: PSpace.sm),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? t.statusDanger : t.borderDefault,
              width: hasError ? 1.5 : 1,
            ),
            borderRadius: PRadius.brSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: PTypo.bodyLg.copyWith(
                    color: hasValue ? t.fgPrimary : t.fgTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(LucideIcons.chevronDown,
                  size: 16, color: t.fgSecondary),
            ],
          ),
        ),
      ),
    );
    final caption = hasError ? errorText! : helperText;
    if (caption == null) return trigger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        trigger,
        const SizedBox(height: PSpace.x4),
        Text(
          caption,
          style: PTypo.caption.copyWith(
            color: hasError ? t.statusDanger : t.fgTertiary,
          ),
        ),
      ],
    );
  }
}
