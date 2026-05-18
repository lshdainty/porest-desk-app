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
import 'password_change_dialog.dart';
import '../../../shared/widgets/p_avatar.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';

/// 설정 화면 — front `SettingsPage` 9개 섹션 미러.
///
/// 모바일에서는 메뉴 리스트로 보여주고 일부 섹션은 별도 라우트로 push,
/// 표시 설정·계정·알림·데이터 등은 inline 또는 dialog 로 처리.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).value;

    final sections = <_SettingsSection>[
      _SettingsSection(
        icon: LucideIcons.tag,
        label: '카테고리 관리',
        desc: '지출·수입 카테고리 추가·수정·삭제',
        onTap: (ctx) => ctx.push('/categories'),
      ),
      _SettingsSection(
        icon: LucideIcons.wallet,
        label: '계좌·카드 관리',
        desc: '연결된 계좌와 카드 관리',
        onTap: (ctx) => ctx.push('/assets'),
      ),
      _SettingsSection(
        icon: LucideIcons.target,
        label: '예산 설정',
        desc: '월간 예산 및 카테고리별 한도',
        onTap: (ctx) => ctx.push('/budget'),
      ),
      _SettingsSection(
        icon: LucideIcons.repeat,
        label: '반복 거래 관리',
        desc: '구독·고정 결제·정기 수입 일괄 관리',
        onTap: (ctx) => ctx.push('/recurring'),
      ),
      _SettingsSection(
        icon: LucideIcons.bookmark,
        label: '프리셋 관리',
        desc: '자주 쓰는 내역을 한 번 탭으로 채우기',
        onTap: (ctx) => ctx.push('/presets'),
      ),
      _SettingsSection(
        icon: LucideIcons.bell,
        label: '알림',
        desc: '결제 예정·예산 초과 알림',
        onTap: (ctx) => ctx.push('/notifications'),
      ),
      _SettingsSection(
        icon: LucideIcons.download,
        label: '데이터 내보내기',
        desc: 'CSV 로 거래 내역 백업',
        onTap: (ctx) => showExportDialog(ctx),
      ),
    ];

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(l.navSettings),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(PSpace.x20),
        children: [
          // 표시 설정 (inline)
          _SectionHeader(title: '표시 설정', subtitle: '테마·밀도·통화', tokens: t),
          const SizedBox(height: PSpace.x12),
          const AppearanceSection(),
          const SizedBox(height: PSpace.x24),

          // 메뉴 그룹
          _SectionHeader(title: '관리', subtitle: '관련 기능 바로가기', tokens: t),
          const SizedBox(height: PSpace.x12),
          PCard(
            variant: PCardVariant.bordered,
            child: Column(
              children: [
                for (int i = 0; i < sections.length; i++) ...[
                  _SectionRow(section: sections[i], tokens: t),
                  if (i < sections.length - 1)
                    PDivider(indent: 56),
                ],
              ],
            ),
          ),
          const SizedBox(height: PSpace.x24),

          // 계정 섹션
          _SectionHeader(title: '계정', subtitle: '프로필·로그아웃', tokens: t),
          const SizedBox(height: PSpace.x12),
          PCard(
            variant: PCardVariant.bordered,
            child: Column(
              children: [
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PSpace.x16, vertical: PSpace.x12),
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
                              Text(user.userName,
                                  style: PTypo.body.copyWith(
                                      color: t.fgPrimary,
                                      fontWeight: PFontWeight.semi)),
                              if (user.userEmail.isNotEmpty)
                                Text(user.userEmail,
                                    style: PTypo.caption
                                        .copyWith(color: t.fgTertiary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (user != null)
                  PDivider(indent: 56),
                InkWell(
                  onTap: () => showPasswordChangeDialog(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PSpace.x16, vertical: PSpace.x12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.key,
                            size: 20, color: t.fgSecondary),
                        const SizedBox(width: PSpace.x12),
                        Expanded(
                          child: Text(l.navChangePassword,
                              style: PTypo.body.copyWith(
                                  color: t.fgPrimary,
                                  fontWeight: PFontWeight.semi)),
                        ),
                        Icon(LucideIcons.chevronRight,
                            size: 16, color: t.fgTertiary),
                      ],
                    ),
                  ),
                ),
                PDivider(indent: 56),
                InkWell(
                  onTap: () => ref.read(authProvider.notifier).logout(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: PSpace.x16, vertical: PSpace.x12),
                    child: Row(
                      children: [
                        Icon(LucideIcons.logOut,
                            size: 20, color: t.statusDanger),
                        const SizedBox(width: PSpace.x12),
                        Text(l.navLogout,
                            style: PTypo.body.copyWith(
                                color: t.statusDanger,
                                fontWeight: PFontWeight.semi)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x32),
        ],
      ),
    );
  }
}

class _SettingsSection {
  const _SettingsSection({
    required this.icon,
    required this.label,
    required this.desc,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String desc;
  final void Function(BuildContext) onTap;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.subtitle, required this.tokens});
  final String title;
  final String subtitle;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: PTypo.h3.copyWith(color: tokens.fgPrimary)),
        const SizedBox(height: 2),
        Text(subtitle, style: PTypo.bodySm.copyWith(color: tokens.fgTertiary)),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.section, required this.tokens});
  final _SettingsSection section;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => section.onTap(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: tokens.bgMuted,
                borderRadius: PRadius.brSm,
              ),
              alignment: Alignment.center,
              child: Icon(section.icon, size: 16, color: tokens.fgSecondary),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(section.label,
                      style: PTypo.body.copyWith(
                          color: tokens.fgPrimary,
                          fontWeight: PFontWeight.semi)),
                  const SizedBox(height: 1),
                  Text(section.desc,
                      style: PTypo.caption.copyWith(color: tokens.fgTertiary)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight,
                size: 16, color: tokens.fgTertiary),
          ],
        ),
      ),
    );
  }
}
