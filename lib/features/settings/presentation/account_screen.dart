import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/update/app_update.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/format/date.dart';
import 'package:porest_desk_app/core/lock/app_lock.dart';
import 'package:porest_desk_app/core/lock/app_lock_toggle.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
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
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';

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
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).value;
    final subscription = ref.watch(mySubscriptionProvider).asData?.value;
    final hasSecurities = ref.watch(hasSecuritiesProvider);
    final appLockOn = ref.watch(appLockEnabledProvider);
    final hiddenCount =
        ref.watch(settingsProvider).value?.hideCards.length ?? 0;
    final hiddenTotal = kAllHideCards.length;
    final isSubscribed = subscription?.isActive ?? false;
    final nameInitial = user != null && user.userName.isNotEmpty
        ? user.userName[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.accountTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        // 최상위 24 통일(사용자 결정, web --spacing-xl 정합).
        padding: const EdgeInsets.all(PSpace.x24),
        children: [
          // ── 프로필 헤더 — web: 중앙 정렬 avatar 72 + 이름 + 이메일 + 편집/Pro + 가입 시기
          PCard(
            // 자산 요약과 동일한 keep 카드(raised) — surface 배경 위에서 확실히 띄움.
            variant: PCardVariant.raised,
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
                    // 아바타 채움은 다크에서도 primary 고정(bgBrandSolid, 사용자 결정·web 정합).
                    color: t.bgBrandSolid,
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
                  user?.userName ?? l.accountDefaultName,
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
                      label: '✎ ${l.actionEdit}',
                      variant: PButtonVariant.ghost,
                      size: PButtonSize.sm,
                      onPressed: () => showPSnackBar(context, l.accountEditComingSoon,
                          severity: PSnackSeverity.info),
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
                if (user?.joinedAt != null) ...[
                  const SizedBox(height: PSpace.x8),
                  Text(
                    l.accountJoined(yearMonth(user!.joinedAt!)),
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: 12,
                      color: t.fgTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: PSpace.x32),

          // ── 보안 — web: desc 우측 정렬 + chevron/switch
          _SectionLabel(label: l.accountSecurity, tokens: t),
          const SizedBox(height: PSpace.x8),
            Column(
              children: [
                _AccountRow(
                  icon: LucideIcons.key,
                  label: l.navChangePassword,
                  desc: l.accountPasswordDesc,
                  chevron: true,
                  tokens: t,
                  onTap: () => showPasswordChangeDialog(context),
                ),
                const PDivider(),
                _AccountRow(
                  icon: LucideIcons.monitor,
                  label: l.accountTwoFa,
                  desc: _twoFa ? l.accountOn : l.accountOff,
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
                // 앱 잠금 — 로그인 세션과 별개로 앱 자체를 생체인증으로 잠근다.
                // 켤 때만 인증을 거친다(setAppLockWithAuth).
                _AccountRow(
                  icon: LucideIcons.fingerprint,
                  label: l.appLockTitle,
                  desc: appLockOn ? l.accountOn : l.accountOff,
                  tokens: t,
                  trailing: SizedBox(
                    height: 24,
                    child: PSwitch(
                      value: appLockOn,
                      onChanged: (v) => setAppLockWithAuth(context, ref, v),
                    ),
                  ),
                ),
                const PDivider(),
                // 금액 가리기 — 화면·카드 37장을 훑는 목록이라 자기 화면으로 보낸다.
                _AccountRow(
                  icon: hiddenCount == 0 ? LucideIcons.eye : LucideIcons.eyeOff,
                  label: l.hideAmountsTitle,
                  desc: '$hiddenCount / $hiddenTotal',
                  chevron: true,
                  tokens: t,
                  onTap: () => context.push('/settings/hide-amounts'),
                ),
                const PDivider(),
                _AccountRow(
                  icon: LucideIcons.monitor,
                  label: l.accountDevices,
                  desc: l.accountCurrentDevice,
                  chevron: true,
                  tokens: t,
                ),
                const PDivider(),
                _AccountRow(
                  icon: LucideIcons.calendarDays,
                  label: l.accountLoginHistory,
                  desc: l.accountLast30Days,
                  chevron: true,
                  tokens: t,
                ),
              ],
            ),
          const SizedBox(height: PSpace.x32),

          // ── 연결된 계정 — web: 레터 아이콘 + '연결 안 됨' + 연결 버튼
          _SectionLabel(label: l.accountConnected, tokens: t),
          const SizedBox(height: PSpace.x8),
            Column(
              children: [
                for (final social in _socialItems) ...[
                  if (social != _socialItems.first) const PDivider(),
                  _AccountRow(
                    letter: social.letter,
                    label: social.name,
                    desc: l.accountNotConnected,
                    tokens: t,
                    trailing: PButton(
                      label: l.accountConnect,
                      variant: PButtonVariant.outline,
                      size: PButtonSize.sm,
                      onPressed: () =>
                          showPSnackBar(context, l.accountSocialComingSoon(social.name),
                    severity: PSnackSeverity.info),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: PSpace.x32),

          // ── 구독·결제 — Porest Pro 단일 행 → 구독 관리 시트(일반/프로·결제)
          _SectionLabel(label: l.accountBilling, tokens: t),
          const SizedBox(height: PSpace.x8),
            // 구독·결제 — 디자인대로 제목/부제 세로 스택 + 우측 가격/배지 커스텀 행.
            // (generic _AccountRow 가로 desc 는 긴 부제에서 label 이 글자단위로 깨짐)
            InkWell(
              onTap: () => showSubscriptionSheet(context),
              borderRadius: PRadius.brLg,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
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
                                ? '${subscription?.currentPeriodEnd != null && subscription!.currentPeriodEnd!.length >= 10 ? l.accountNextBilling(subscription.currentPeriodEnd!.substring(0, 10)) : ''}${l.accountProActive}'
                                : l.accountProPromo,
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
                            krwSigned(9900, false, unit: true),
                            style: TextStyle(
                              fontFamily: PTypo.sans,
                              fontSize: PFontSize.body,
                              fontWeight: PFontWeight.bold,
                              color: t.fgPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(l.accountPerMonth,
                              style: PTypo.micro.copyWith(color: t.fgTertiary)),
                        ],
                      )
                    else
                      PBadge(label: l.accountProStart,
                          variant: PBadgeVariant.softBrand),
                    const SizedBox(width: PSpace.x8),
                    Icon(LucideIcons.chevronRight,
                        size: 16, color: t.fgTertiary),
                  ],
                ),
              ),
            ),

          // ── 증권 데이터 연동 — 구독(Pro) 시에만 노출(별도 화면 아님, 인라인)
          if (hasSecurities) ...[
            const SizedBox(height: PSpace.x32),
            const TossConnectCard(),
          ],
          const SizedBox(height: PSpace.x32),

          // ── 계정 관리 — web: 로그아웃(일반) / 회원 탈퇴(danger)
          _SectionLabel(label: l.accountManage, tokens: t),
          const SizedBox(height: PSpace.x8),
            Column(
              children: [
                _AccountRow(
                  icon: LucideIcons.logOut,
                  label: l.navLogout,
                  desc: l.accountLogoutDesc,
                  chevron: true,
                  tokens: t,
                  onTap: () => _confirmLogout(context, ref),
                ),
                // web 정합 — 로그아웃 아래 구분선 없음.
                _AccountRow(
                  icon: LucideIcons.trash2,
                  label: l.accountWithdraw,
                  desc: l.accountWithdrawDesc,
                  iconColor: t.statusDanger,
                  labelColor: t.statusDanger,
                  tokens: t,
                  onTap: () => _confirmWithdraw(context),
                ),
              ],
            ),

          const SizedBox(height: PSpace.x32),

          // 앱 버전 — 화면 맨 아래에 조용히 둔다. 스토어를 안 거치니 지금 깔린 게
          // 어느 빌드인지 알 데가 여기밖에 없다.
          const _AppVersionLine(),

          const SizedBox(height: PSpace.x32),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    // Material 기본 AlertDialog 는 앱 테마·타이포를 안 따른다 — 공통 다이얼로그를 쓴다.
    final ok = await showPConfirmDialog(
      context,
      title: l.navLogout,
      message: l.accountLogoutConfirm,
      confirmLabel: l.navLogout,
    );
    if (ok) {
      ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _confirmWithdraw(BuildContext context) async {
    final l = AppLocalizations.of(context);
    // 되돌릴 수 없는 삭제라 destructive. 실제 탈퇴 처리는 아직 없어 확인해도 닫히기만 한다.
    await showPConfirmDialog(
      context,
      title: l.accountWithdrawTitle,
      message: l.accountWithdrawConfirm,
      // 기본값 "확인" 은 결정 행위를 안 밝힌다(spec alert-dialog.md Don't).
      confirmLabel: l.accountWithdrawAction,
      destructive: true,
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
  final Color? iconColor;
  final Color? labelColor;
  final PorestTokens tokens;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final fgIcon = iconColor ?? t.fgSecondary;
    final fgLabel = labelColor ?? t.fgPrimary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        // web row '14px 0' 정합 — 좌우 inset 삭제(사용자 결정).
        padding: const EdgeInsets.symmetric(vertical: 14),
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

/// 앱 버전과 최신 여부 한 줄.
///
/// 버전을 읽기 전에는 아무것도 그리지 않는다 — 빈 자리가 잠깐 보였다 채워지는 게
/// 자리만 잡아 두는 것보다 낫다.
///
/// 최신 여부는 새 버전 확인과 같은 근거(`/download/version.json`)를 쓴다. 그 요청이
/// 실패해도 provider 가 null 을 주므로 "최신"으로 보인다 — 서버를 못 읽었다고 굳이
/// 알릴 일은 아니고, 홈 배너도 같은 조건이라 두 곳이 어긋나지 않는다.
class _AppVersionLine extends ConsumerWidget {
  const _AppVersionLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    final version = ref.watch(appVersionProvider).value;
    if (version == null) return const SizedBox.shrink();

    final statusAsync = ref.watch(updateStatusProvider);
    final status = statusAsync.value;
    final hasUpdate = status?.hasUpdate ?? false;

    // 서버를 못 읽었으면 아무 말도 안 한다 — "최신이에요" 는 실제로 비교해 봤을 때만.
    // 못 읽은 걸 최신으로 적으면 서버가 죽어 있는 동안 새 버전을 영영 모른다.
    final suffix = statusAsync.isLoading || status == null || status.checkFailed
        ? null
        : hasUpdate
            ? l.accountAppVersionUpdate(status.latest!.version)
            : l.accountAppVersionLatest;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: l.accountAppVersion(version)),
          if (suffix != null) ...[
            const TextSpan(text: ' · '),
            TextSpan(
              text: suffix,
              // 새 버전이 있을 때만 눈에 걸리게. 최신이면 나머지와 같은 톤으로 묻는다.
              style: hasUpdate
                  ? TextStyle(color: t.fgBrand, fontWeight: PFontWeight.semi)
                  : null,
            ),
          ],
        ],
      ),
      style: TextStyle(
        fontFamily: PTypo.sans,
        fontSize: PFontSize.caption,
        color: t.fgTertiary,
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
      padding: EdgeInsets.zero, // label 좌 inset 삭제(사용자 결정)
      child: Text(
        label,
        style: TextStyle(
          fontFamily: PTypo.sans,
          fontSize: PFontSize.bodySm, // 웹 섹션 라벨 13 정합
          fontWeight: PFontWeight.bold,
          color: tokens.fgPrimary,
        ),
      ),
    );
  }
}
