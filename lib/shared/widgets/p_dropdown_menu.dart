import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// specs/components/dropdown-menu.md 미러 — click trigger floating action menu.
///
/// 웹(Radix DropdownMenu) 시각 1:1:
/// - container: surface-default + border 1px border-default + radius-md(8)
///   + padding-xs(4) + min-width 160 + shadow-md
/// - item: (선택)icon 16 좌측 + gap 8 + text body-md(15), padding 10·12, radius-sm(4)
/// - hover/press: surface-input (destructive: error 12%)
/// - separator: 1px border-subtle, margin-y xs(4)
/// - destructive item: text/icon error
///
/// 기존 [PopupMenuButton] 직접 사용처(kebab ⋮ 액션 메뉴)를 대체하는 공통 위젯.
///
/// ```dart
/// PDropdownMenu(
///   entries: [
///     PDropdownItem(icon: LucideIcons.pencil, label: '수정', onTap: _edit),
///     const PDropdownDivider(),
///     PDropdownItem(icon: LucideIcons.trash2, label: '삭제',
///         onTap: _delete, destructive: true),
///   ],
/// )
/// ```
sealed class PDropdownEntry {
  const PDropdownEntry();
}

/// 실행 가능한 메뉴 항목.
class PDropdownItem extends PDropdownEntry {
  const PDropdownItem({
    required this.label,
    this.icon,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;

  /// (선택) 좌측 16px 아이콘. 한 메뉴 안에선 전부 표기 또는 전부 생략(정렬 일관).
  final IconData? icon;
  final VoidCallback? onTap;

  /// 삭제 등 위험 액션 — text/icon error 색 + hover error 12%.
  final bool destructive;
  final bool enabled;
}

/// 의미 그룹 사이 구분선.
class PDropdownDivider extends PDropdownEntry {
  const PDropdownDivider();
}

class PDropdownMenu extends StatelessWidget {
  const PDropdownMenu({
    super.key,
    required this.entries,
    this.icon = LucideIcons.moreVertical,
    this.iconSize = 18,
    this.iconColor,
    this.enabled = true,
    this.tooltip,
    this.minWidth = 160,
  });

  final List<PDropdownEntry> entries;

  /// trigger 아이콘 — 기본 kebab(⋮).
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final bool enabled;
  final String? tooltip;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return PopupMenuButton<int>(
      enabled: enabled,
      tooltip: tooltip ?? '',
      icon: Icon(icon, size: iconSize, color: iconColor ?? t.fgTertiary),
      position: PopupMenuPosition.under,
      offset: const Offset(0, PSpace.x4), // sideOffset 4
      color: t.bgSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0x1A0F121C), // shadow-md tone
      elevation: 6,
      menuPadding: const EdgeInsets.all(PSpace.x4), // padding-xs
      constraints: BoxConstraints(minWidth: minWidth),
      shape: RoundedRectangleBorder(
        borderRadius: PRadius.brMd,
        side: BorderSide(color: t.borderDefault),
      ),
      onSelected: (i) {
        final e = entries[i];
        if (e is PDropdownItem) e.onTap?.call();
      },
      itemBuilder: (context) {
        final out = <PopupMenuEntry<int>>[];
        for (var i = 0; i < entries.length; i++) {
          final e = entries[i];
          switch (e) {
            case PDropdownDivider():
              out.add(
                PopupMenuItem<int>(
                  enabled: false,
                  height: 1,
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x4),
                  child: Container(height: 1, color: t.borderSubtle),
                ),
              );
            case PDropdownItem():
              final fg = e.destructive ? t.statusDangerFg : t.fgPrimary;
              final iconClr = e.destructive ? t.statusDangerFg : t.fgSecondary;
              out.add(
                PopupMenuItem<int>(
                  value: i,
                  enabled: e.enabled,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: PSpace.x12),
                  child: Row(
                    children: [
                      if (e.icon != null) ...[
                        Icon(e.icon, size: 16, color: iconClr),
                        const SizedBox(width: PSpace.x8),
                      ],
                      Expanded(
                        child: Text(
                          e.label,
                          style: TextStyle(
                            fontFamily: PTypo.sans,
                            fontSize: PFontSize.bodyMd,
                            height: 1.4,
                            color: fg,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
          }
        }
        return out;
      },
    );
  }
}
