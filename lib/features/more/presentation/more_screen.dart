import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';

/// 모바일 전용 "전체" 탭 — 잘 안 쓰는 메뉴를 한 화면에 모음.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final items = <_MoreItem>[
      _MoreItem(LucideIcons.wallet, '자산',
          onTap: (ctx, _) => ctx.push('/assets')),
      _MoreItem(LucideIcons.target, '예산',
          onTap: (ctx, _) => ctx.push('/budget')),
      _MoreItem(LucideIcons.calendarDays, '캘린더'),
      _MoreItem(LucideIcons.repeat, '반복 거래',
          onTap: (ctx, _) => ctx.push('/recurring')),
      _MoreItem(LucideIcons.creditCard, '카드 관리'),
      _MoreItem(LucideIcons.users, '그룹'),
      _MoreItem(LucideIcons.divide, '더치페이'),
      _MoreItem(LucideIcons.fileText, '메모'),
      _MoreItem(LucideIcons.checkSquare, '할 일'),
      _MoreItem(LucideIcons.bell, '알림'),
      _MoreItem(LucideIcons.settings, '설정', onTap: (ctx, _) => ctx.push('/settings')),
      _MoreItem(LucideIcons.logOut, '로그아웃',
          onTap: (_, ref) => ref.read(authProvider.notifier).logout()),
    ];

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
              for (int i = 0; i < items.length; i++) ...[
                _MoreRow(item: items[i], onTap: items[i].onTap == null
                    ? null
                    : () => items[i].onTap!(context, ref)),
                if (i < items.length - 1)
                  Divider(height: 1, color: t.borderSubtle, indent: 52),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreItem {
  const _MoreItem(this.icon, this.label, {this.onTap});
  final IconData icon;
  final String label;
  final void Function(BuildContext, WidgetRef)? onTap;
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({required this.item, required this.onTap});
  final _MoreItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: enabled ? t.fgSecondary : t.fgDisabled),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Text(item.label,
                  style: PTypo.body.copyWith(
                      color: enabled ? t.fgPrimary : t.fgDisabled)),
            ),
            Icon(LucideIcons.chevronRight, size: 16,
                color: enabled ? t.fgTertiary : t.fgDisabled),
          ],
        ),
      ),
    );
  }
}
