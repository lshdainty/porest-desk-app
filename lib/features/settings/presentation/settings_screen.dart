import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_avatar.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';

class _SettingsItem {
  const _SettingsItem({required this.label, this.onTap});
  final String label;
  final void Function(BuildContext ctx)? onTap;
}

class _SettingsGroup {
  const _SettingsGroup({required this.label, required this.items});
  final String label;
  final List<_SettingsItem> items;
}

List<_SettingsGroup> _buildGroups(BuildContext ctx) {
  final l = AppLocalizations.of(ctx);
  return [
    _SettingsGroup(
      label: l.settingsGroupDataMgmt,
      items: [
        _SettingsItem(
          label: l.settingsMenuCategory,
          onTap: (c) => c.push('/categories'),
        ),
        _SettingsItem(
          label: l.settingsMenuAccountCard,
          onTap: (c) => c.push('/account-card-manage'),
        ),
        _SettingsItem(
          label: l.settingsMenuBudget,
          // 웹 정합: 전체 > 설정 > 예산 설정 → BudgetManager 페이지 (개요 /budget 아님).
          onTap: (c) => c.push('/budget/settings'),
        ),
        _SettingsItem(
          label: l.navSavingGoals,
          onTap: (c) => c.push('/saving-goals'),
        ),
        _SettingsItem(
          label: l.settingsMenuRecurring,
          onTap: (c) => c.push('/recurring'),
        ),
        _SettingsItem(
          label: l.settingsMenuPreset,
          onTap: (c) => c.push('/presets'),
        ),
      ],
    ),
    // 태그 · 라벨 — design screens-settings.jsx 신판(할일 태그 + 캘린더 라벨).
    _SettingsGroup(
      label: l.settingsGroupTagsLabels,
      items: [
        _SettingsItem(
          label: l.settingsMenuTodoTag,
          onTap: (c) => c.push('/settings/todo-tags'),
        ),
        _SettingsItem(
          label: l.settingsMenuCalendarLabel,
          onTap: (c) => c.push('/settings/calendar-labels'),
        ),
      ],
    ),
    _SettingsGroup(
      label: l.settingsGroupShare,
      items: [
        _SettingsItem(
          label: l.settingsMenuCalendarShare,
          onTap: (c) => c.push('/settings/calendar-share'),
        ),
      ],
    ),
    _SettingsGroup(
      label: l.settingsGroupApp,
      items: [
        _SettingsItem(
          label: l.settingsMenuAppearance,
          onTap: (c) => c.push('/settings/appearance'),
        ),
        _SettingsItem(
          label: l.navNotifications,
          onTap: (c) => c.push('/settings/notifications'),
        ),
      ],
    ),
    _SettingsGroup(
      label: l.settingsGroupData,
      items: [
        _SettingsItem(
          label: l.exportTitle,
          onTap: (c) => c.push('/settings/export-data'),
        ),
        _SettingsItem(label: l.settingsMenuStorage, onTap: null),
      ],
    ),
    _SettingsGroup(
      label: l.settingsGroupAccount,
      items: [
        _SettingsItem(
          label: l.settingsMenuAccountMgmt,
          onTap: (c) => c.push('/account'),
        ),
      ],
    ),
  ];
}

/// 설정 메뉴 — design MobileSettingsList (K뱅크 톤) 미러.
///
/// 카드 없이: 프로필 헤더 행(아바타+이름) + 헤어라인 + [그룹 라벨(16/700) +
/// 플랫 행(라벨 15/500 + chevron, 13px/20px)] 반복, 그룹 사이 헤어라인.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).value;
    final groups = _buildGroups(context);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.navSettings),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        // design m-settings-list: padding '8px 0 32px' — 좌우는 요소별 20.
        padding: const EdgeInsets.all(PSpace.x24),
        children: [
          // 내 정보 — 카드 없이 이름 헤더 행 (design ProfileCard 폐기판).
          if (user != null) ...[
            InkWell(
              onTap: () => context.push('/account'),
              child: Padding(
                padding:
                    const EdgeInsets.only(top: 14, bottom: 18),
                child: Row(
                  children: [
                    PAvatar(
                      size: PAvatarSize.lg,
                      fill: PAvatarFill.primary,
                      fallbackText: user.userName.isNotEmpty
                          ? user.userName[0].toUpperCase()
                          : '?',
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.userName,
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: 17,
                              fontWeight: PFontWeight.bold,
                              letterSpacing: -0.26,
                              color: t.fgPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user.userEmail.isNotEmpty
                                ? user.userEmail
                                : l.settingsMenuAccountMgmt,
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: 12.5,
                              color: t.fgTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight,
                        size: 18, color: t.fgTertiary),
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.only(bottom: 4),
              color: t.borderSubtle,
            ),
          ],

          // 그룹 — 라벨 + 플랫 행, 그룹 사이 헤어라인 (design flat-div 12px 20px).
          for (int gi = 0; gi < groups.length; gi++) ...[
            if (gi > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(
                    vertical: PSpace.x12),
                color: t.borderSubtle,
              ),
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Text(
                groups[gi].label,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 16,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.16,
                  color: t.fgPrimary,
                ),
              ),
            ),
            for (final item in groups[gi].items)
              _SettingsRow(item: item, tokens: t),
          ],
        ],
      ),
    );
  }
}

/// 플랫 설정 행 — design m-settings-row: 라벨(15/500) + chevron, padding 13px 20px.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item, required this.tokens});
  final _SettingsItem item;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final enabled = item.onTap != null;
    return InkWell(
      onTap: enabled ? () => item.onTap!(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: 15,
                  fontWeight: PFontWeight.medium,
                  letterSpacing: -0.15,
                  color: enabled ? tokens.fgPrimary : tokens.fgDisabled,
                ),
              ),
            ),
            if (enabled)
              Icon(LucideIcons.chevronRight, size: 15, color: tokens.fgTertiary)
            else
              const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }
}
