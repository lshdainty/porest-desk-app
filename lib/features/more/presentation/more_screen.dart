import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';

/// 모바일 전용 "전체" 탭 — 잘 안 쓰는 메뉴를 한 화면에 모음.
/// Phase 7+ 에서 각 항목이 자체 화면으로 push 라우팅.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _items = <(IconData, String)>[
    (LucideIcons.wallet, '자산'),
    (LucideIcons.target, '예산'),
    (LucideIcons.calendarDays, '캘린더'),
    (LucideIcons.repeat, '반복 거래'),
    (LucideIcons.creditCard, '카드 관리'),
    (LucideIcons.users, '그룹'),
    (LucideIcons.divide, '더치페이'),
    (LucideIcons.fileText, '메모'),
    (LucideIcons.checkSquare, '할 일'),
    (LucideIcons.bell, '알림'),
    (LucideIcons.settings, '설정'),
    (LucideIcons.logOut, '로그아웃'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return ListView(
      padding: const EdgeInsets.all(PSpace.x20),
      children: [
        Text('전체 / More', style: PTypo.h2.copyWith(color: t.fgPrimary)),
        const SizedBox(height: PSpace.x16),
        Container(
          decoration: BoxDecoration(
            color: t.bgSurface,
            borderRadius: PRadius.brLg,
            border: Border.all(color: t.borderSubtle),
          ),
          child: Column(
            children: [
              for (int i = 0; i < _items.length; i++) ...[
                _MoreRow(icon: _items[i].$1, label: _items[i].$2),
                if (i < _items.length - 1)
                  Divider(height: 1, color: t.borderSubtle, indent: 52),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: () {}, // Phase 7+ 라우팅
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: t.fgSecondary),
            const SizedBox(width: PSpace.x12),
            Expanded(child: Text(label, style: PTypo.body.copyWith(color: t.fgPrimary))),
            Icon(LucideIcons.chevronRight, size: 16, color: t.fgTertiary),
          ],
        ),
      ),
    );
  }
}
