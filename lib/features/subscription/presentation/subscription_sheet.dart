import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_segmented.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 구독 관리 바텀시트 — porest-design `SubscriptionDialog` 미러.
///
/// 현재 플랜 배너(Free/Pro) · 증권 스포트라이트 · 월간/연간 세그(가격 cosmetic)
/// · Free/Pro 비교 카드 · 기능 비교표. 결제(PG) 없음 — 'Pro 시작하기'=self-grant,
/// '구독 해지'=cancel. (결제 수단·내역 mock 은 백엔드 PG 부재로 미구현)
void showSubscriptionSheet(BuildContext context) {
  final l = AppLocalizations.of(context);
  showPSheet<void>(
    context,
    title: l.subManageTitle,
    contentBuilder: (ctx, scrollCtrl) =>
        _SubscriptionSheetBody(scrollController: scrollCtrl),
    // footer 는 showPSheet 가 하단 고정 — content(ListView)만 스크롤 (웹 ModalShell 정합).
    footerBuilder: (ctx) => const _SubscriptionFooter(),
    initialChildSize: 0.92,
    maxChildSize: 0.95,
  );
}

class _PlanFeature {
  const _PlanFeature(this.label, this.free, this.pro, {this.star = false});
  final String label;

  /// true=체크, false=대시, String=텍스트(예: '100건')
  final Object free;
  final Object pro;
  final bool star;
}

List<_PlanFeature> _featuresOf(AppLocalizations l) => <_PlanFeature>[
  _PlanFeature(l.subFeatLedger, true, true),
  _PlanFeature(l.subFeatBudget, true, true),
  _PlanFeature(l.subFeatMonthlyTx, l.subFeatTxLimit, l.subFeatUnlimited),
  _PlanFeature(l.subFeatSecurities, false, true, star: true),
  _PlanFeature(l.subFeatImportExport, false, true),
  _PlanFeature(l.subFeatCalendarShare, false, true),
  _PlanFeature(l.subFeatCardRec, false, true),
];

enum _Cycle { monthly, yearly }

const _proMonthly = 9900;
const _proYearly = 99000;
const _savePct = 17; // 1 - 99000/(9900*12) ≈ 0.166

class _SubscriptionSheetBody extends ConsumerStatefulWidget {
  const _SubscriptionSheetBody({required this.scrollController});
  final ScrollController scrollController;

  @override
  ConsumerState<_SubscriptionSheetBody> createState() =>
      _SubscriptionSheetBodyState();
}

class _SubscriptionSheetBodyState
    extends ConsumerState<_SubscriptionSheetBody> {
  _Cycle _cycle = _Cycle.monthly;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final sub = ref.watch(mySubscriptionProvider).asData?.value;
    final isPro = sub?.isActive ?? false;
    final nextBill =
        (sub?.currentPeriodEnd != null && sub!.currentPeriodEnd!.length >= 10)
        ? sub.currentPeriodEnd!.substring(0, 10)
        : l.subNextBillingDate;
    final proPrice = _cycle == _Cycle.monthly ? _proMonthly : _proYearly;
    final proPerMonth = _cycle == _Cycle.monthly
        ? _proMonthly
        : (_proYearly / 12).round();

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        PSpace.x16,
        PSpace.x4,
        PSpace.x16,
        PSpace.x16,
      ),
      children: [
        // 현재 플랜 배너 — PCard.brand (bgBrandSubtle + soft brand border)
        PCard(
          variant: PCardVariant.brand,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: Border.all(color: t.borderBrandSoft),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  // solid 채움 아이콘 칩 — 다크에서도 primary 고정(bgBrandSolid). bgBrand 는
                  // 다크에서 primary-light 로 밝아짐 → 웹(--bg-brand=primary) 정합 위해 solid.
                  color: t.bgBrandSolid,
                  borderRadius: PRadius.brMd,
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.sparkles, size: 20, color: t.fgOnBrand),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPro ? l.subUsingPro : l.subUsingFree,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.bodyMd,
                        fontWeight: PFontWeight.bold,
                        color: t.fgPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPro
                          ? l.subNextBilling(
                              nextBill, krwSigned(_proMonthly, false, unit: true))
                          : l.subFreeLockedDesc,
                      style: PTypo.caption.copyWith(color: t.fgSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 증권 스포트라이트 — PCard.muted + bgSunken override (dark 톤 분리)
        PCard(
          variant: PCardVariant.muted,
          color: t.bgSunken,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.statusDangerSubtle,
                  borderRadius: PRadius.brMd,
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.trendingUp,
                  size: 18,
                  color: t.statusDangerFg,
                ),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.subSpotlightTitle,
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: PFontSize.body,
                        fontWeight: PFontWeight.bold,
                        color: t.fgPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l.subSpotlightDesc,
                      style: PTypo.caption.copyWith(
                        color: t.fgSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 결제 주기 토글
        PSegmented<_Cycle>(
          value: _cycle,
          onChanged: (v) => setState(() => _cycle = v),
          options: [
            PSegmentOption(value: _Cycle.monthly, label: l.subCycleMonthly),
            PSegmentOption(
              value: _Cycle.yearly,
              label: l.subCycleYearlyOff(_savePct),
            ),
          ],
        ),
        const SizedBox(height: PSpace.x16),

        // Free / Pro 비교 카드 — IntrinsicHeight 로 높이 bound(ListView 안에서
        // crossAxisAlignment.stretch 는 무한 높이 크래시) + 두 카드 동일 높이.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _planCard(t, isPro: false, current: !isPro)),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: _planCard(
                  t,
                  isPro: true,
                  current: isPro,
                  priceWon: proPrice,
                  priceUnit: _cycle == _Cycle.monthly
                      ? l.subUnitMonth
                      : l.subUnitYear,
                  note: _cycle == _Cycle.yearly
                      ? l.subYearlyPerMonth(
                          krwSigned(proPerMonth, false, unit: true), _savePct)
                      : l.subMonthlyBilling,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x20),

        // 기능 비교표
        Padding(
          padding: const EdgeInsets.only(bottom: PSpace.x8),
          child: Text(
            l.subFeatureCompare,
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.caption,
              fontWeight: PFontWeight.bold,
              color: t.fgTertiary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        // PCard.bordered (bgSurface + borderSubtle) — 행 모서리 라운딩은 PCard 가
        // clip 을 안 하므로 내부 ClipRRect 로 처리.
        PCard(
          variant: PCardVariant.bordered,
          child: ClipRRect(
            borderRadius: PRadius.brLg,
            child: Column(
              children: [
                _featureHeader(t),
                for (final f in _featuresOf(l)) _featureRow(t, f),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _planCard(
    PorestTokens t, {
    required bool isPro,
    required bool current,
    int priceWon = 0,
    String? priceUnit,
    String? note,
  }) {
    final l = AppLocalizations.of(context);
    return PCard(
      variant: PCardVariant.bordered,
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: isPro ? t.borderBrand : t.borderDefault,
        width: isPro ? 2 : 1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isPro) ...[
                    Icon(LucideIcons.sparkles, size: 13, color: t.fgBrand),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    isPro ? 'Pro' : 'Free',
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.body,
                      fontWeight: PFontWeight.bold,
                      color: isPro ? t.fgBrand : t.fgPrimary,
                    ),
                  ),
                ],
              ),
              if (current)
                PBadge(
                  label: l.subCurrentPlan,
                  variant: isPro
                      ? PBadgeVariant.primary
                      : PBadgeVariant.secondary,
                ),
            ],
          ),
          const SizedBox(height: PSpace.x8),
          // crossAxisAlignment.end(하단 정렬) — IntrinsicHeight 안에서 baseline 은
          // intrinsic 계산과 비호환이라 사용 금지. 가격은 Flexible+ellipsis 로 overflow 방지.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  isPro
                      ? krwSigned(priceWon, false, unit: true)
                      : krwSigned(0, false, unit: true),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: PFontSize.h2,
                    fontWeight: PFontWeight.bold,
                    color: t.fgPrimary,
                    letterSpacing: -0.48,
                  ),
                ),
              ),
              if (isPro) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '/ ${priceUnit ?? l.subUnitMonth}',
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isPro ? (note ?? l.subMonthlyBilling) : l.subFreeCaption,
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
        ],
      ),
    );
  }

  Widget _featureHeader(PorestTokens t) {
    final l = AppLocalizations.of(context);
    return Container(
      color: t.bgSunken,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l.subFeatureColumn,
              style: TextStyle(
                fontFamily: PTypo.sans,
                fontSize: PFontSize.caption,
                fontWeight: PFontWeight.semi,
                color: t.fgTertiary,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              'Free',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: PTypo.sans,
                fontSize: PFontSize.caption,
                fontWeight: PFontWeight.semi,
                color: t.fgTertiary,
              ),
            ),
          ),
          SizedBox(
            width: 52,
            child: Text(
              'Pro',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: PTypo.sans,
                fontSize: PFontSize.caption,
                fontWeight: PFontWeight.bold,
                color: t.fgBrand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(PorestTokens t, _PlanFeature f) {
    return Container(
      decoration: BoxDecoration(
        color: f.star ? t.bgBrandSubtle : t.bgSurface,
        border: Border(top: BorderSide(color: t.borderSubtle)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (f.star) ...[
                  Icon(
                    LucideIcons.trendingUp,
                    size: 13,
                    color: t.statusDangerFg,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    f.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: PFontSize.bodySm,
                      fontWeight: f.star
                          ? PFontWeight.bold
                          : PFontWeight.medium,
                      color: t.fgPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 52,
            child: Center(child: _featureCell(t, f.free, accent: false)),
          ),
          SizedBox(
            width: 52,
            child: Center(child: _featureCell(t, f.pro, accent: f.star)),
          ),
        ],
      ),
    );
  }

  Widget _featureCell(PorestTokens t, Object val, {required bool accent}) {
    if (val == true) {
      return Icon(
        LucideIcons.check,
        size: 15,
        color: accent ? t.fgBrand : t.statusSuccessFg,
      );
    }
    if (val == false) {
      return Icon(LucideIcons.minus, size: 15, color: t.fgDisabled);
    }
    return Text(
      val.toString(),
      style: TextStyle(
        fontFamily: PTypo.sans,
        fontSize: PFontSize.caption,
        fontWeight: PFontWeight.bold,
        color: accent ? t.fgBrand : t.fgSecondary,
      ),
    );
  }
}

/// 구독 시트 하단 고정 footer — [닫기 | 구독 해지 / Pro 시작하기].
/// content(ListView)와 분리해 showPSheet footerBuilder 로 하단 고정(웹 ModalShell 정합).
/// _busy 는 footer 전용 상태(버튼 비활성/로딩), isPro·nextBill 은 provider 에서 직접 read.
class _SubscriptionFooter extends ConsumerStatefulWidget {
  const _SubscriptionFooter();

  @override
  ConsumerState<_SubscriptionFooter> createState() =>
      _SubscriptionFooterState();
}

class _SubscriptionFooterState extends ConsumerState<_SubscriptionFooter> {
  bool _busy = false;

  Future<void> _subscribe() async {
    final l = AppLocalizations.of(context);
    final plans = ref.read(subscriptionPlansProvider).asData?.value ?? const [];
    final planCode = plans.isNotEmpty ? plans.first.planCode : 'SECURITIES';
    setState(() => _busy = true);
    try {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      await repo.subscribe(planCode);
      ref.invalidate(myFeaturesProvider);
      ref.invalidate(mySubscriptionProvider);
      if (mounted) {
        showPSnackBar(
          context,
          l.subStarted,
          severity: PSnackSeverity.success,
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        showPSnackBar(context, l.subFailed, severity: PSnackSeverity.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(String nextBill) async {
    final l = AppLocalizations.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.subCancelConfirmTitle,
      message: l.subCancelConfirmMsg(nextBill),
      confirmLabel: l.subCancel,
      cancelLabel: l.subKeep,
      destructive: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      final repo = await ref.read(subscriptionRepositoryProvider.future);
      await repo.cancelSubscription();
      ref.invalidate(myFeaturesProvider);
      ref.invalidate(mySubscriptionProvider);
      if (mounted) {
        showPSnackBar(context, l.subCanceled, severity: PSnackSeverity.success);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        showPSnackBar(context, l.subCancelFailed, severity: PSnackSeverity.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sub = ref.watch(mySubscriptionProvider).asData?.value;
    final isPro = sub?.isActive ?? false;
    final nextBill =
        (sub?.currentPeriodEnd != null && sub!.currentPeriodEnd!.length >= 10)
        ? sub.currentPeriodEnd!.substring(0, 10)
        : l.subNextBillingDate;
    return Row(
      children: [
        Expanded(
          child: PButton(
            label: l.actionClose,
            variant: PButtonVariant.outline,
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: PSpace.x12),
        Expanded(
          child: isPro
              ? PButton(
                  label: l.subCancel,
                  variant: PButtonVariant.danger,
                  onPressed: _busy ? null : () => _cancel(nextBill),
                )
              : PButton(
                  label: _busy ? l.subProcessing : l.subStartPro,
                  onPressed: _busy ? null : _subscribe,
                ),
        ),
      ],
    );
  }
}
