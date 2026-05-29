import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/radius.dart';
import '../../app/theme/shadow.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';

/// 5칸 탭바 (홈 / 가계부 / [중앙 FAB +] / 캘린더 / 전체).
///
/// porest-desk-front `MobileTabBar.tsx` 매핑.
/// - 일반 탭 4개는 [currentBranch] 와 비교해 활성 표시
/// - 중앙 FAB 는 분기 X — [onAddTx] 콜백으로 거래 추가 시트 열기
class MobileTabBar extends StatelessWidget {
  const MobileTabBar({
    required this.currentBranch,
    required this.onTapBranch,
    required this.onAddTx,
    super.key,
  });

  /// StatefulNavigationShell 기준 현재 분기 인덱스 (0~3).
  final int currentBranch;
  final void Function(int branchIndex) onTapBranch;
  final VoidCallback onAddTx;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final mq = MediaQuery.of(context);
    final slots = <_Slot>[
      _Slot(icon: LucideIcons.home, label: l.navHome, branch: 0),
      _Slot(icon: LucideIcons.receipt, label: l.navExpense, branch: 1),
      const _Slot.fab(),
      _Slot(icon: LucideIcons.calendarDays, label: l.navCalendar, branch: 2),
      _Slot(icon: LucideIcons.menu, label: l.navMore, branch: 3),
    ];
    return Material(
      color: t.bgSurface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: t.borderSubtle)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: PSpace.x8,
            right: PSpace.x8,
            top: 6,
            // 안전영역 + 디자인 12px 마진
            bottom: 12 + mq.padding.bottom,
          ),
          child: SizedBox(
            height: 54, // 본문 높이; 안전영역은 padding 으로 추가됨
            child: Row(
              children: [
                for (final s in slots)
                  Expanded(
                    child: s.isFab
                        ? _CenterFab(onTap: onAddTx, tokens: t)
                        : _TabItem(
                            icon: s.icon!,
                            label: s.label!,
                            selected: currentBranch == s.branch,
                            onTap: () => onTapBranch(s.branch!),
                            tokens: t,
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

class _Slot {
  const _Slot({required this.icon, required this.label, required this.branch})
    : isFab = false;
  const _Slot.fab() : icon = null, label = null, branch = null, isFab = true;

  final IconData? icon;
  final String? label;
  final int? branch;
  final bool isFab;
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tokens,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = selected ? tokens.fgBrand : tokens.fgTertiary;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(PRadius.md)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: PTypo.micro.copyWith(
                color: color,
                fontWeight: selected ? PFontWeight.semi : PFontWeight.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.onTap, required this.tokens});
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      // + 버튼은 light/dark 무관하게 primary(#0147AD) 고정 — bgBrand는 dark에서
      // primary-light(cobalt400)로 밝아지므로 palette 직접 참조. card shadow(sm) 적용.
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: PorestPalette.cobalt500, // primary 고정
          shape: BoxShape.circle,
          boxShadow: PShadow.sm,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(LucideIcons.plus, color: tokens.fgOnBrand, size: 26),
            ),
          ),
        ),
      ),
    );
  }
}
