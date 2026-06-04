import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../expense/presentation/export_dialog.dart';
import 'appearance_section.dart';
import '../../../shared/widgets/p_avatar.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';

class _SettingsItem {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.desc,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String desc;
  final void Function(BuildContext ctx)? onTap;
}

class _SettingsGroup {
  const _SettingsGroup({required this.label, required this.items});
  final String label;
  final List<_SettingsItem> items;
}

List<_SettingsGroup> _buildGroups(BuildContext ctx) => [
  _SettingsGroup(
    label: '데이터 관리',
    items: [
      _SettingsItem(
        icon: LucideIcons.tag,
        label: '카테고리 관리',
        desc: '지출·수입 카테고리 추가·수정·삭제',
        onTap: (c) => c.push('/categories'),
      ),
      _SettingsItem(
        icon: LucideIcons.wallet,
        label: '계좌·카드 관리',
        desc: '계좌·카드 추가·편집',
        onTap: (c) => c.push('/account-card-manage'),
      ),
      _SettingsItem(
        icon: LucideIcons.target,
        label: '예산 설정',
        desc: '월간 예산 및 카테고리별 한도',
        onTap: (c) => c.push('/budget'),
      ),
      _SettingsItem(
        icon: LucideIcons.repeat,
        label: '반복 거래 관리',
        desc: '구독·고정 결제·정기 수입',
        onTap: (c) => c.push('/recurring'),
      ),
      _SettingsItem(
        icon: LucideIcons.bookmark,
        label: '프리셋 관리',
        desc: '자주 쓰는 내역 한 번 탭으로 채우기',
        onTap: (c) => c.push('/presets'),
      ),
    ],
  ),
  _SettingsGroup(
    label: '공유·소통',
    items: [
      _SettingsItem(
        icon: LucideIcons.calendarRange,
        label: '캘린더 관리·공유',
        desc: '내 캘린더 · 멤버 권한 · 초대 코드',
        onTap: (c) => c.push('/settings/calendar-share'),
      ),
      _SettingsItem(
        icon: LucideIcons.tag,
        label: '캘린더 라벨',
        desc: '일정 라벨 추가·편집·삭제',
        onTap: (c) => c.push('/settings/calendar-labels'),
      ),
      _SettingsItem(
        icon: LucideIcons.divide,
        label: '더치페이',
        desc: '정산 · 친구 · 송금 요청',
        onTap: (c) => c.push('/dutch-pay'),
      ),
    ],
  ),
  _SettingsGroup(
    label: '앱 환경',
    items: [
      _SettingsItem(
        icon: LucideIcons.palette,
        label: '표시 설정',
        desc: '테마 · 밀도 · 통화',
        onTap: null, // inline 섹션으로 처리
      ),
      _SettingsItem(
        icon: LucideIcons.bell,
        label: '알림',
        desc: '결제 예정·예산 초과 알림',
        onTap: (c) => c.push('/settings/notifications'),
      ),
    ],
  ),
  _SettingsGroup(
    label: '데이터',
    items: [
      _SettingsItem(
        icon: LucideIcons.download,
        label: '데이터 내보내기',
        desc: 'CSV 로 거래 내역 백업',
        onTap: (c) => showExportDialog(c),
      ),
      _SettingsItem(
        icon: LucideIcons.hardDrive,
        label: '저장공간',
        desc: '준비중',
        onTap: null,
      ),
    ],
  ),
  _SettingsGroup(
    label: '계정',
    items: [
      _SettingsItem(
        icon: LucideIcons.user,
        label: '계정 관리',
        desc: '프로필 · 보안 · 구독',
        onTap: (c) => c.push('/account'),
      ),
    ],
  ),
];

/// 설정 화면 — 프로필 카드 + 5개 그룹 카드 + 표시 설정 inline.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).value;
    final groups = _buildGroups(context);

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: Text(l.navSettings),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x20,
          vertical: PSpace.x24,
        ),
        children: [
          // 프로필 카드
          if (user != null) ...[
            PCard(
              variant: PCardVariant.shadow,
              // shadow 기본 padding(16)과 내부 Padding(x16)이 겹쳐 과대 인셋 — zero (web 정합).
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () => context.push('/account'),
                borderRadius: PRadius.brLg,
                child: Padding(
                  padding: const EdgeInsets.all(PSpace.x16),
                  child: Row(
                    children: [
                      PAvatar(
                        size: PAvatarSize.md,
                        fill: PAvatarFill.primary,
                        fallbackText: user.userName.isNotEmpty
                            ? user.userName[0].toUpperCase()
                            : '?',
                      ),
                      const SizedBox(width: PSpace.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.userName,
                              style: TextStyle(
                                fontFamily: PTypo.sans,
                                fontSize: PFontSize.body,
                                fontWeight: PFontWeight.semi,
                                color: t.fgPrimary,
                              ),
                            ),
                            if (user.userEmail.isNotEmpty)
                              Text(
                                user.userEmail,
                                style: TextStyle(
                                  fontFamily: PTypo.sans,
                                  fontSize: PFontSize.caption,
                                  color: t.fgTertiary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronRight,
                        size: 16,
                        color: t.fgTertiary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: PSpace.x24),
          ],

          // 표시 설정 inline
          _GroupLabel(label: '표시 설정', tokens: t),
          const SizedBox(height: PSpace.x8),
          const AppearanceSection(),
          const SizedBox(height: PSpace.x24),

          // 나머지 그룹 카드 (표시설정 그룹 제외 — inline으로 처리)
          for (int gi = 0; gi < groups.length; gi++) ...[
            if (groups[gi].label == '앱 환경') ...[
              // 앱 환경: 표시 설정 항목 제외하고 알림만 표시
              _GroupLabel(label: groups[gi].label, tokens: t),
              const SizedBox(height: PSpace.x8),
              PCard(
                variant: PCardVariant.shadow,
                // list shell — 카드 자체 padding 제거, row 가 14/16 보유 (web 정합).
                padding: EdgeInsets.zero,
                child: Column(
                  children: () {
                    final items = groups[gi].items
                        .where((i) => i.label != '표시 설정')
                        .toList();
                    return [
                      for (int i = 0; i < items.length; i++) ...[
                        _SettingsRow(item: items[i], tokens: t),
                        if (i < items.length - 1) const PDivider(),
                      ],
                    ];
                  }(),
                ),
              ),
            ] else ...[
              _GroupLabel(label: groups[gi].label, tokens: t),
              const SizedBox(height: PSpace.x8),
              PCard(
                variant: PCardVariant.shadow,
                // list shell — 카드 자체 padding 제거, row 가 14/16 보유 (web 정합).
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (int i = 0; i < groups[gi].items.length; i++) ...[
                      _SettingsRow(item: groups[gi].items[i], tokens: t),
                      if (i < groups[gi].items.length - 1) const PDivider(),
                    ],
                  ],
                ),
              ),
            ],
            if (gi < groups.length - 1) const SizedBox(height: PSpace.x20),
          ],

          const SizedBox(height: PSpace.x32),
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label, required this.tokens});
  final String label;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: PTypo.sans,
          fontSize: PFontSize.caption,
          fontWeight: PFontWeight.bold,
          color: tokens.fgPrimary,
        ),
      ),
    );
  }
}

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
        // web row '14px 16px' 정합.
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x16,
          vertical: 14,
        ),
        child: Row(
          children: [
            // 아이콘 네모 배경 제거 — 아이콘만 (web 동일 처리).
            Icon(
              item.icon,
              size: 16,
              color: enabled ? tokens.fgSecondary : tokens.fgDisabled,
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.body,
                      fontWeight: PFontWeight.semi,
                      color: enabled ? tokens.fgPrimary : tokens.fgDisabled,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.desc,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.caption,
                      color: tokens.fgTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled)
              Icon(LucideIcons.chevronRight, size: 16, color: tokens.fgTertiary)
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}
