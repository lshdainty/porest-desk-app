import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// specs/components/radio-list.md 미러.
///
/// 전체 폭 row 리스트에서 single-select 도메인 컴포넌트 — 통화/언어/국가 등
/// **목록형 선택지** 패턴. 좌측 pill + label/sub + 우측 active check.
///
/// container = border + radius-lg + divider 사이 row만. active 표시는 우측
/// check ✓ 만 (row bg 변화 없음 — 비교 가독성 유지).
class PRadioListItem<T> {
  const PRadioListItem({
    required this.value,
    required this.label,
    this.subLabel,
    this.pillText,
    this.pillIcon,
    this.pillColor,
    this.trailing,
  });

  final T value;
  final String label;
  final String? subLabel;

  /// pill 안 텍스트 심볼 (₩/$/€/EN 등). pillIcon 우선.
  final String? pillText;
  final IconData? pillIcon;

  /// pill 배경 (지정 없으면 [PorestTokens.bgCanvas]).
  final Color? pillColor;

  /// 우측 옵션 영역 (badge 등).
  final Widget? trailing;
}

enum PRadioListSize { sm, md, lg }

class PRadioList<T> extends StatelessWidget {
  const PRadioList({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.size = PRadioListSize.md,
  });

  final List<PRadioListItem<T>> items;
  final T? value;
  final ValueChanged<T>? onChanged;
  final PRadioListSize size;

  (double padX, double padY, double pillSize, double gap, double checkSize)
      get _metrics => switch (size) {
            PRadioListSize.sm => (12, 10, 28, 10, 14),
            PRadioListSize.md => (16, 14, 32, 12, 16),
            PRadioListSize.lg => (20, 16, 40, 14, 18),
          };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(color: t.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: PRadius.brLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: t.borderSubtle),
              _row(context, items[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, PRadioListItem<T> item) {
    final t = context.tokens;
    final (padX, padY, pillSize, gap, checkSize) = _metrics;
    final selected = item.value == value;
    final disabled = onChanged == null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled || selected ? null : () => onChanged!(item.value),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
          child: Row(
            children: [
              if (item.pillIcon != null || item.pillText != null)
                Container(
                  width: pillSize,
                  height: pillSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.pillColor ?? t.bgCanvas,
                    borderRadius: PRadius.brMd,
                  ),
                  child: item.pillIcon != null
                      ? Icon(item.pillIcon, size: pillSize * 0.5, color: t.fgPrimary)
                      : Text(
                          item.pillText!,
                          style: TextStyle(
                            fontFamily: PTypo.sans,
                            fontSize: PFontSize.bodyLg,
                            fontWeight: PFontWeight.bold,
                            color: t.fgPrimary,
                          ),
                        ),
                ),
              if (item.pillIcon != null || item.pillText != null)
                SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.body,
                        fontWeight: PFontWeight.semi,
                        color: disabled ? t.fgDisabled : t.fgPrimary,
                      ),
                    ),
                    if (item.subLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.micro,
                          fontWeight: PFontWeight.regular,
                          color: t.fgTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.trailing != null) ...[
                const SizedBox(width: 8),
                item.trailing!,
              ],
              if (selected) ...[
                SizedBox(width: gap),
                Icon(LucideIcons.check, size: checkSize, color: t.fgBrand),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
