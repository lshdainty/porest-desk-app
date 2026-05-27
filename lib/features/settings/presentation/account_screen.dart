import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../shared/widgets/p_avatar.dart';
import '../../../shared/widgets/p_badge.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_divider.dart';
import '../../../shared/widgets/p_snack_bar.dart';
import '../../../shared/widgets/p_switch.dart';
import 'password_change_dialog.dart';

/// 계정 상세 화면 — web AccountSection 미러.
///
/// 기능 연동: 프로필 표시, 비밀번호 변경, 로그아웃.
/// UI only: 2FA, 생체인증, 기기목록, 소셜 연결, 구독/결제, 회원탈퇴.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _twoFa = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: PButton.icon(
          icon: LucideIcons.arrowLeft,
          onPressed: () => context.pop(),
        ),
        title: const Text('계정'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20, vertical: PSpace.x24),
        children: [
          // 프로필 카드
          PCard(
            variant: PCardVariant.shadow,
            child: Padding(
              padding: const EdgeInsets.all(PSpace.x16),
              child: Row(
                children: [
                  PAvatar(
                    size: PAvatarSize.xl,
                    fill: PAvatarFill.primary,
                    fallbackText: user != null && user.userName.isNotEmpty
                        ? user.userName[0].toUpperCase()
                        : '?',
                  ),
                  const SizedBox(width: PSpace.x16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              user?.userName ?? '-',
                              style: TextStyle(
                                fontFamily: PTypo.sans,
                                fontSize: PFontSize.titleMd,
                                fontWeight: PFontWeight.bold,
                                color: t.fgPrimary,
                              ),
                            ),
                            const SizedBox(width: PSpace.xs),
                            PBadge(
                              label: 'Free',
                              variant: PBadgeVariant.secondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.userEmail ?? '-',
                          style: TextStyle(
                            fontFamily: PTypo.sans,
                            fontSize: PFontSize.bodySm,
                            color: t.fgTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PSpace.x24),

          // 보안
          _SectionLabel(label: '보안', tokens: t),
          const SizedBox(height: PSpace.x8),
          PCard(
            variant: PCardVariant.shadow,
            child: Column(
              children: [
                _ActionRow(
                  icon: LucideIcons.key,
                  label: '비밀번호 변경',
                  tokens: t,
                  onTap: () => showPasswordChangeDialog(context),
                ),
                PDivider(indent: 46),
                PSwitchTile(
                  title: '2단계 인증',
                  subtitle: '로그인 시 추가 인증 요구 (준비중)',
                  value: _twoFa,
                  onChanged: (v) => setState(() => _twoFa = v),
                  leading: Icon(LucideIcons.shieldCheck,
                      size: 18, color: t.fgSecondary),
                ),
                PDivider(indent: 46),
                PSwitchTile(
                  title: '생체 인증',
                  subtitle: '준비중',
                  value: false,
                  onChanged: null,
                  leading:
                      Icon(LucideIcons.fingerprint, size: 18, color: t.fgDisabled),
                ),
                PDivider(indent: 46),
                _ActionRow(
                  icon: LucideIcons.monitor,
                  label: '기기 · 로그인 기록',
                  desc: '준비중',
                  tokens: t,
                  onTap: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x24),

          // 연결된 계정
          _SectionLabel(label: '연결된 계정', tokens: t),
          const SizedBox(height: PSpace.x8),
          PCard(
            variant: PCardVariant.shadow,
            child: Column(
              children: [
                for (final social in _socialItems) ...[
                  if (social != _socialItems.first) PDivider(indent: 46),
                  _SocialRow(item: social, tokens: t),
                ],
              ],
            ),
          ),
          const SizedBox(height: PSpace.x24),

          // 구독·결제
          _SectionLabel(label: '구독·결제', tokens: t),
          const SizedBox(height: PSpace.x8),
          PCard(
            variant: PCardVariant.shadow,
            child: Padding(
              padding: const EdgeInsets.all(PSpace.x16),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: t.bgBrandSubtle,
                      borderRadius: PRadius.brSm,
                    ),
                    alignment: Alignment.center,
                    child: Icon(LucideIcons.star, size: 16, color: t.fgBrand),
                  ),
                  const SizedBox(width: PSpace.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Porest Free',
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: PFontSize.body,
                              fontWeight: PFontWeight.semi,
                              color: t.fgPrimary,
                            )),
                        Text('현재 플랜',
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: PFontSize.caption,
                              color: t.fgTertiary,
                            )),
                      ],
                    ),
                  ),
                  PButton(
                    label: '업그레이드',
                    variant: PButtonVariant.outline,
                    size: PButtonSize.sm,
                    onPressed: () => showPSnackBar(context, '구독 기능은 준비중입니다'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PSpace.x24),

          // 계정 관리
          _SectionLabel(label: '계정 관리', tokens: t),
          const SizedBox(height: PSpace.x8),
          PCard(
            variant: PCardVariant.shadow,
            child: Column(
              children: [
                _ActionRow(
                  icon: LucideIcons.logOut,
                  label: '로그아웃',
                  iconColor: t.statusDanger,
                  labelColor: t.statusDanger,
                  tokens: t,
                  onTap: () => _confirmLogout(context, ref),
                ),
                PDivider(indent: 46),
                _ActionRow(
                  icon: LucideIcons.userX,
                  label: '회원탈퇴',
                  iconColor: t.fgTertiary,
                  labelColor: t.fgTertiary,
                  tokens: t,
                  onTap: () => _confirmWithdraw(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: PSpace.x32),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠어요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('로그아웃')),
        ],
      ),
    );
    if (ok == true) {
      ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _confirmWithdraw(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원탈퇴'),
        content: const Text('탈퇴 시 모든 데이터가 영구 삭제됩니다.\n이 기능은 현재 준비중입니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인')),
        ],
      ),
    );
  }
}

const _socialItems = [
  _SocialItem(icon: LucideIcons.chrome, name: 'Google'),
  _SocialItem(icon: LucideIcons.apple, name: 'Apple'),
  _SocialItem(icon: LucideIcons.messageCircle, name: '카카오'),
  _SocialItem(icon: LucideIcons.navigation, name: '네이버'),
];

class _SocialItem {
  const _SocialItem({required this.icon, required this.name});
  final IconData icon;
  final String name;
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.item, required this.tokens});
  final _SocialItem item;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x16, vertical: PSpace.x12),
      child: Row(
        children: [
          Icon(item.icon, size: 18, color: tokens.fgSecondary),
          const SizedBox(width: PSpace.x12),
          Expanded(
            child: Text(item.name,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: PFontSize.body,
                  fontWeight: PFontWeight.semi,
                  color: tokens.fgPrimary,
                )),
          ),
          PButton(
            label: '연결',
            variant: PButtonVariant.outline,
            size: PButtonSize.sm,
            onPressed: () => showPSnackBar(context, '${item.name} 연결은 준비중입니다'),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.tokens,
    this.desc,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? desc;
  final PorestTokens tokens;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x16, vertical: PSpace.x12),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: enabled
                    ? (iconColor ?? tokens.fgSecondary)
                    : tokens.fgDisabled),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.body,
                        fontWeight: PFontWeight.semi,
                        color: enabled
                            ? (labelColor ?? tokens.fgPrimary)
                            : tokens.fgDisabled,
                      )),
                  if (desc != null)
                    Text(desc!,
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: PFontSize.caption,
                          color: tokens.fgTertiary,
                        )),
                ],
              ),
            ),
            if (enabled)
              Icon(LucideIcons.chevronRight, size: 14, color: tokens.fgTertiary),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.tokens});
  final String label;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(label,
          style: TextStyle(
            fontFamily: PTypo.sans,
            fontSize: PFontSize.caption,
            fontWeight: PFontWeight.bold,
            color: tokens.fgPrimary,
          )),
    );
  }
}
