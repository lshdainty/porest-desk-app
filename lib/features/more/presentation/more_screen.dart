import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../expense/presentation/export_dialog.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';

/// 모바일 전용 "전체" 탭 — 잘 안 쓰는 메뉴를 한 화면에 모음.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final items = <_MoreItem>[
      _MoreItem(LucideIcons.wallet, l.navAsset,
          onTap: (ctx, _) => ctx.push('/assets')),
      _MoreItem(LucideIcons.target, l.navBudget,
          onTap: (ctx, _) => ctx.push('/budget')),
      _MoreItem(LucideIcons.calendarDays, l.navCalendar,
          onTap: (ctx, _) => ctx.push('/calendar')),
      _MoreItem(LucideIcons.repeat, l.navRecurring,
          onTap: (ctx, _) => ctx.push('/recurring')),
      _MoreItem(LucideIcons.tag, l.navCategories,
          onTap: (ctx, _) => ctx.push('/categories')),
      _MoreItem(LucideIcons.zap, l.navPresets,
          onTap: (ctx, _) => ctx.push('/presets')),
      _MoreItem(LucideIcons.search, l.navSearch,
          onTap: (ctx, _) => ctx.push('/search')),
      _MoreItem(LucideIcons.creditCard, l.navCards,
          onTap: (ctx, _) => ctx.push('/cards')),
      _MoreItem(LucideIcons.users, l.navGroup,
          onTap: (ctx, _) => ctx.push('/groups')),
      _MoreItem(LucideIcons.divide, l.navDutchPay,
          onTap: (ctx, _) => ctx.push('/dutch-pay')),
      _MoreItem(LucideIcons.fileText, l.navMemo,
          onTap: (ctx, _) => ctx.push('/memos')),
      _MoreItem(LucideIcons.checkSquare, l.navTodo,
          onTap: (ctx, _) => ctx.push('/todos')),
      _MoreItem(LucideIcons.bell, l.navNotifications,
          onTap: (ctx, _) => ctx.push('/notifications')),
      _MoreItem(LucideIcons.piggyBank, l.navSavingGoals,
          onTap: (ctx, _) => ctx.push('/saving-goals')),
      _MoreItem(LucideIcons.download, l.navExport,
          onTap: (ctx, _) => showExportDialog(ctx)),
      _MoreItem(LucideIcons.settings, l.navSettings,
          onTap: (ctx, _) => ctx.push('/settings')),
      _MoreItem(LucideIcons.logOut, l.navLogout,
          onTap: (_, ref) => ref.read(authProvider.notifier).logout()),
    ];

    return ListView(
      padding: const EdgeInsets.all(PSpace.x20),
      children: [
        Text(l.navMore, style: PTypo.h2.copyWith(color: t.fgPrimary)),
        const SizedBox(height: PSpace.x16),
        PCard(
          variant: PCardVariant.bordered,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _MoreRow(item: items[i], onTap: items[i].onTap == null
                    ? null
                    : () => items[i].onTap!(context, ref)),
                if (i < items.length - 1)
                  PDivider(indent: 52),
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
