import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/presentation/subscription_sheet.dart';
import 'package:porest_desk_app/features/subscription/presentation/toss_connect_card.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_divider.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';
import 'package:porest_desk_app/features/settings/presentation/password_change_dialog.dart';

/// 계정 상세 화면 — web AccountSection 1:1 미러.
///
/// 프로필(중앙 정렬 헤더) + 보안 + 연결된 계정 + 구독·결제 + 계정 관리.
/// 기능 연동: 프로필 표시, 비밀번호 변경, 로그아웃.
/// UI only: 2FA, 생체인증, 기기/기록, 소셜 연결, 구독/결제, 회원탈퇴.
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
    final subscription = ref.watch(mySubscriptionProvider).asData?.value;
    final hasSecurities = ref.watch(hasSecuritiesProvider);
    final isSubscribed = subscription?.isActive ?? false;
    final nameInitial = user != null && user.userName.isNotEmpty
        ? user.userName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: const Text('계정'),
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
          // ── 프로필 헤더 — web: 중앙 정렬 avatar 72 + 이름 + 이메일 + 편집/Pro + 가입 시기
          PCard(
            variant: PCardVariant.shadow,
            padding: const EdgeInsets.symmetric(
              vertical: 28,
              horizontal: PSpace.x24,
            ),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: t.bgBrand,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    nameInitial,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: 24,
                      fontWeight: PFontWeight.bold,
                      color: t.fgOnBrand,
                    ),
                  ),
                ),
                const SizedBox(height: PSpace.x12),
                Text(
                  user?.userName ?? '사용자',
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 17,
                    fontWeight: PFontWeight.bold,
                    color: t.fgPrimary,
                    letterSpacing: -0.34,
                  ),
                ),
                const SizedBox(height: PSpace.x8),
                Text(
                  user?.userEmail ?? '',
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 13,
                    color: t.fgTertiary,
                  ),
                ),
                const SizedBox(height: PSpace.x12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PButton(
                      label: '✎ 편집',
                      variant: PButtonVariant.ghost,
                      size: PButtonSize.sm,
                      onPressed: () => showPSnackBar(context, '프로필 편집은 준비중입니다'),
                    ),
                    const SizedBox(width: PSpace.x8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: t.bgBrandSubtle,
                        borderRadius: PRadius.brSm,
                      ),
                      child: Text(
                        isSubscribed ? 'Pro' : 'Free',
                        style: TextStyle(
                          fontFamily: PTypo.sans,
                          fontSize: 11,
                          fontWeight: PFontWeight.bold,
                          color: t.fgBrandStrong,
                          letterSpacing: 0.22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PSpace.x8),
                Text(
                  '가입 2024년 11월',
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 12,
                    color: t.fgTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x20),

          // ── 보안 — web: desc 우측 정렬 + chevron/switch
          _SectionLabel(label: '보안', tokens: t),
          const SizedBox(height: PSpace.x8),
          PCard(
            variant: PCardVariant.shadow,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _AccountRow(
                  icon: LucideIcons.key,
                  label: '비밀번호 변경',
                  desc: '최근 변경 없음',
                  chevron: true,
                  tokens: t,
                  onTap: () => showPasswordChangeDialog(context),
                ),
                // web 정합 — 비밀번호 변경 아래 구분선 없음.
                _AccountRow(
                  icon: LucideIcons.monitor,
                  label: '2단계 인증',
                  desc: _twoFa ? '사용 중' : '사용 안 함',
                  tokens: t,
                  // PSwitch 의 44px 탭 타깃이 행을 키우지 않게 트랙 높이(24)로 제한
                  // — 다른 행과 동일 높이 (web 정합).
                  trailing: SizedBox(
                    height: 24,
                    child: PSwitch(
                      value: _twoFa,
                      onChanged: (v) => setState(() => _twoFa = v),
                    ),
                  ),
                ),
                const PDivider(),
                _AccountRow(
                  icon: LucideIcons.fingerprint,
                  label: '생체 인증',
                  desc: '준비중',
                  dimmed: true,
                  tokens: t,
                ),
                const PDivider(),
                _AccountRow(
                  icon: LucideIcons.monitor,
                  label: '로그인된 기기',
                  desc: '현재 기기',
                  chevron: true,
                  tokens: t,
                ),
                const PDivider(),
                _AccountRow(
                  icon: LucideIcons.calendarDays,
                  label: '로그인 기록',
                  desc: '최근 30일',
                  chevron: true,
                  tokens: t,
                ),
              ],
            ),
          ),
          const SizedBox(height: PSpace.x20),

          // ── 연결된 계정 — web: 레터 아이콘 + '연결 안 됨' + 연결 버튼
          _SectionLabel(label: '연결된 계정', tokens: t),
          const SizedBox(height: PSpace.x8),
          PCard(
            variant: PCardVariant.shadow,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final social in _socialItems) ...[
                  if (social != _socialItems.first) const PDivider(),
                  _AccountRow(
                    letter: social.letter,
                    label: social.name,
                    desc: '연결 안 됨',
                    tokens: t,
                    trailing: PButton(
                      label: '연결',
                      variant: PButtonVariant.outline,
                      size: PButtonSize.sm,
                      onPressed: () =>
                          showPSnackBar(context, '${social.name} 연결은 준비중입니다'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: PSpace.x20),

          // ── 구독·결제 — Porest Pro 단일 행 → 구독 관리 시트(일반/프로·결제)
          _SectionLabel(label: '구독·결제', tokens: t),
          const SizedBox(height: PSpace.x8),
          PCard(
            variant: PCardVariant.shadow,
            padding: EdgeInsets.zero,
            // 구독·결제 — 디자인대로 제목/부제 세로 스택 + 우측 가격/배지 커스텀 행.
            // (generic _AccountRow 가로 desc 는 긴 부제에서 label 이 글자단위로 깨짐)
            child: InkWell(
              onTap: () => showSubscriptionSheet(context),
              borderRadius: PRadius.brLg,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: PSpace.x16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: t.bgBrandSubtle,
                        borderRadius: PRadius.brMd,
                      ),
                      alignment: Alignment.center,
                      child: Icon(LucideIcons.sparkles,
                          size: 18, color: t.fgBrand),
                    ),
                    const SizedBox(width: PSpace.x12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Porest Pro',
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: PFontSize.body,
                              fontWeight: PFontWeight.bold,
                              color: t.fgPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSubscribed
                                ? '${subscription?.currentPeriodEnd != null && subscription!.currentPeriodEnd!.length >= 10 ? '다음 결제 ${subscription.currentPeriodEnd!.substring(0, 10)} · ' : ''}Pro 이용 중'
                                : '증권 투자는 Pro 전용 · 지금 시작하기',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PTypo.caption.copyWith(color: t.fgTertiary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: PSpace.x8),
                    if (isSubscribed)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '9,900원',
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: PFontSize.body,
                              fontWeight: PFontWeight.bold,
                              color: t.fgPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('/ 월',
                              style: PTypo.micro.copyWith(color: t.fgTertiary)),
                        ],
                      )
                    else
                      const PBadge(label: 'Pro 시작',
                          variant: PBadgeVariant.softBrand),
                    const SizedBox(width: PSpace.x8),
                    Icon(LucideIcons.chevronRight,
                        size: 16, color: t.fgTertiary),
                  ],
                ),
              ),
            ),
          ),

          // ── 증권 데이터 연동 — 구독(Pro) 시에만 노출(별도 화면 아님, 인라인)
          if (hasSecurities) ...[
            const SizedBox(height: PSpace.x20),
            const TossConnectCard(),
          ],
          const SizedBox(height: PSpace.x20),

          // ── 계정 관리 — web: 로그아웃(일반) / 회원 탈퇴(danger)
          _SectionLabel(label: '계정 관리', tokens: t),
          const SizedBox(height: PSpace.x8),
          PCard(
            variant: PCardVariant.shadow,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _AccountRow(
                  icon: LucideIcons.logOut,
                  label: '로그아웃',
                  desc: '이 기기에서만',
                  chevron: true,
                  tokens: t,
                  onTap: () => _confirmLogout(context, ref),
                ),
                // web 정합 — 로그아웃 아래 구분선 없음.
                _AccountRow(
                  icon: LucideIcons.trash2,
                  label: '회원 탈퇴',
                  desc: '영구 삭제',
                  iconColor: t.statusDanger,
                  labelColor: t.statusDanger,
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
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('로그아웃'),
          ),
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
        title: const Text('정말 탈퇴하시겠습니까?'),
        content: const Text('회원 탈퇴 시 모든 데이터가 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

const _socialItems = [
  _SocialItem(letter: 'G', name: 'Google'),
  _SocialItem(letter: 'A', name: 'Apple ID'),
  _SocialItem(letter: 'K', name: '카카오'),
  _SocialItem(letter: 'N', name: '네이버'),
];

class _SocialItem {
  const _SocialItem({required this.letter, required this.name});
  final String letter;
  final String name;
}

/// web AccountRow 미러 — [icon|letter] + 라벨(flex) + desc(우측 정렬) + trailing.
class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.label,
    required this.tokens,
    this.icon,
    this.letter,
    this.desc,
    this.trailing,
    this.chevron = false,
    this.dimmed = false,
    this.iconColor,
    this.labelColor,
    this.onTap,
  });

  final IconData? icon;
  final String? letter;
  final String label;
  final String? desc;
  final Widget? trailing;
  final bool chevron;
  final bool dimmed;
  final Color? iconColor;
  final Color? labelColor;
  final PorestTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final fgIcon = dimmed ? t.fgDisabled : (iconColor ?? t.fgSecondary);
    final fgLabel = dimmed ? t.fgDisabled : (labelColor ?? t.fgPrimary);
    return InkWell(
      onTap: onTap,
      child: Padding(
        // web row '14px 16px' 정합.
        padding: const EdgeInsets.symmetric(
          horizontal: PSpace.x16,
          vertical: 14,
        ),
        child: Row(
          children: [
            // web: 24px 아이콘 슬롯 (레터 아이콘은 15/700 텍스트)
            SizedBox(
              width: 24,
              child: letter != null
                  ? Text(
                      letter!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: 15,
                        fontWeight: PFontWeight.bold,
                        color: fgIcon,
                      ),
                    )
                  : Icon(icon, size: 18, color: fgIcon),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: PFontSize.body,
                  fontWeight: PFontWeight.semi,
                  color: fgLabel,
                ),
              ),
            ),
            if (desc != null) ...[
              // 우측 상태/설명 — 짧은 desc(연결 안 됨/최근 변경 없음 등) 전용.
              // label(Expanded)이 남은 폭을 차지해 desc·trailing 을 우측으로 민다.
              // (긴 desc 는 구독 행처럼 호출부에서 커스텀 스택으로 처리)
              Text(
                desc!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: PTypo.sans,
                  fontSize: PFontSize.caption,
                  color: t.fgTertiary,
                ),
              ),
              if (trailing != null || chevron) const SizedBox(width: PSpace.x8),
            ],
            ?trailing,
            if (chevron)
              Icon(LucideIcons.chevronRight, size: 16, color: t.fgTertiary),
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
