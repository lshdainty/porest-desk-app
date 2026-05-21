import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

/// 금액 sub-navigation 하단바 — 가계부 진입 시 표시되는 5칸 탭.
///
/// 구조: 좌측 [← 뒤로] + [가계부 / 자산 / 통계 / 예산] 4 sub-tab.
/// 기본 [MobileTabBar] (홈/가계부/+/캘린더/전체) 와 mutually exclusive —
/// 4 페이지 (`/expense`, `/assets`, `/stats`, `/budget`) 에서만 표시.
///
/// porest-desk-front `MoneyTabBar.tsx` 매핑.
enum MoneyTab { expense, assets, stats, budget }

class MoneyTabBar extends StatelessWidget {
  const MoneyTabBar({
    required this.current,
    required this.onTap,
    required this.onBack,
    super.key,
  });

  /// 현재 활성 sub-tab.
  final MoneyTab current;
  final ValueChanged<MoneyTab> onTap;

  /// 좌측 ← 클릭 — 일반적으로 main shell 의 home 탭으로 이동.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final mq = MediaQuery.of(context);
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
            bottom: 12 + mq.padding.bottom,
          ),
          child: SizedBox(
            height: 54,
            child: Row(
              children: [
                Expanded(
                  child: _BackItem(onTap: onBack, tokens: t),
                ),
                Expanded(
                  child: _MoneyTabItem(
                    icon: LucideIcons.receipt,
                    label: '가계부',
                    selected: current == MoneyTab.expense,
                    onTap: () => onTap(MoneyTab.expense),
                    tokens: t,
                  ),
                ),
                Expanded(
                  child: _MoneyTabItem(
                    icon: LucideIcons.wallet,
                    label: '자산',
                    selected: current == MoneyTab.assets,
                    onTap: () => onTap(MoneyTab.assets),
                    tokens: t,
                  ),
                ),
                Expanded(
                  child: _MoneyTabItem(
                    icon: LucideIcons.pieChart,
                    label: '통계',
                    selected: current == MoneyTab.stats,
                    onTap: () => onTap(MoneyTab.stats),
                    tokens: t,
                  ),
                ),
                Expanded(
                  child: _MoneyTabItem(
                    icon: LucideIcons.target,
                    label: '예산',
                    selected: current == MoneyTab.budget,
                    onTap: () => onTap(MoneyTab.budget),
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

class _BackItem extends StatelessWidget {
  const _BackItem({required this.onTap, required this.tokens});
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    // back 버튼 — 라벨 없어 비어 보이는 현상 fix. 클로드 정합 spec.
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(PRadius.md)),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tokens.bgSunken,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(LucideIcons.arrowLeft, size: 18, color: tokens.fgPrimary),
        ),
      ),
    );
  }
}

class _MoneyTabItem extends StatelessWidget {
  const _MoneyTabItem({
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
