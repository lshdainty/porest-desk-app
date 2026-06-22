import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_segmented.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';

/// 구독 관리 바텀시트 — porest-design `SubscriptionDialog` 미러.
///
/// 현재 플랜 배너(Free/Pro) · 증권 스포트라이트 · 월간/연간 세그(가격 cosmetic)
/// · Free/Pro 비교 카드 · 기능 비교표. 결제(PG) 없음 — 'Pro 시작하기'=self-grant,
/// '구독 해지'=cancel. (결제 수단·내역 mock 은 백엔드 PG 부재로 미구현)
void showSubscriptionSheet(BuildContext context) {
  showPSheet<void>(
    context,
    title: '구독 관리',
    contentBuilder: (ctx, scrollCtrl) =>
        _SubscriptionSheetBody(scrollController: scrollCtrl),
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

const _features = <_PlanFeature>[
  _PlanFeature('가계부 · 자산 관리', true, true),
  _PlanFeature('예산 · 저축 목표 · 캘린더', true, true),
  _PlanFeature('월 거래 기록', '100건', '무제한'),
  _PlanFeature('증권 — 실시간 시세 · 종목 검색 · 관심종목', false, true, star: true),
  _PlanFeature('CSV · Excel 가져오기 / 내보내기', false, true),
  _PlanFeature('다중 캘린더 공유', false, true),
  _PlanFeature('카드 혜택 추천', false, true),
];

enum _Cycle { monthly, yearly }

const _proMonthly = 9900;
const _proYearly = 99000;
const _savePct = 17; // 1 - 99000/(9900*12) ≈ 0.166

String _won(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

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
  bool _busy = false;

  Future<void> _subscribe() async {
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
          'Porest Pro 구독이 시작되었어요',
          severity: PSnackSeverity.success,
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        showPSnackBar(context, '구독에 실패했어요', severity: PSnackSeverity.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(String nextBill) async {
    final ok = await showPConfirmDialog(
      context,
      title: '구독을 해지할까요?',
      message:
          '해지하면 $nextBill부터 Free 플랜으로 전환되고 증권 탭이 잠겨요. 그 전까지는 Pro 기능을 계속 쓸 수 있어요.',
      confirmLabel: '구독 해지',
      cancelLabel: '유지하기',
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
        showPSnackBar(context, '구독을 해지했어요', severity: PSnackSeverity.success);
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        showPSnackBar(context, '해지에 실패했어요', severity: PSnackSeverity.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final sub = ref.watch(mySubscriptionProvider).asData?.value;
    final isPro = sub?.isActive ?? false;
    final nextBill =
        (sub?.currentPeriodEnd != null && sub!.currentPeriodEnd!.length >= 10)
        ? sub.currentPeriodEnd!.substring(0, 10)
        : '다음 결제일';
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
        // 현재 플랜 배너
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: t.bgBrandSubtle,
            borderRadius: PRadius.brLg,
            border: Border.all(color: t.bgBrand.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.bgBrand,
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
                      isPro ? 'Porest Pro 이용 중' : 'Free 플랜 이용 중',
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: 15,
                        fontWeight: PFontWeight.bold,
                        color: t.fgPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPro
                          ? '다음 결제 $nextBill · ${_won(_proMonthly)}원'
                          : '증권·가져오기 등 Pro 기능이 잠겨 있어요',
                      style: PTypo.caption.copyWith(color: t.fgSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x16),

        // 증권 스포트라이트
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: t.bgSunken,
            borderRadius: PRadius.brLg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.statusDanger.withValues(alpha: 0.14),
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
                      '증권 투자는 Pro 전용이에요',
                      style: TextStyle(
                        fontFamily: PTypo.sans,
                        fontSize: 13.5,
                        fontWeight: PFontWeight.bold,
                        color: t.fgPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '실시간 시세·호가, 국내외 종목 검색, 관심종목, 보유 손익까지 — Pro를 구독하면 증권 탭이 바로 열려요.',
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
          options: const [
            PSegmentOption(value: _Cycle.monthly, label: '월간'),
            PSegmentOption(value: _Cycle.yearly, label: '연간 17%↓'),
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
                  priceUnit: _cycle == _Cycle.monthly ? '월' : '년',
                  note: _cycle == _Cycle.yearly
                      ? '월 ${_won(proPerMonth)}원 꼴 · $_savePct% 절약'
                      : '월 단위 결제',
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
            '기능 비교',
            style: TextStyle(
              fontFamily: PTypo.sans,
              fontSize: PFontSize.caption,
              fontWeight: PFontWeight.bold,
              color: t.fgTertiary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: PRadius.brLg,
            border: Border.all(color: t.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              _featureHeader(t),
              for (final f in _features) _featureRow(t, f),
            ],
          ),
        ),
        const SizedBox(height: PSpace.x20),

        // 액션
        Row(
          children: [
            Expanded(
              child: PButton(
                label: '닫기',
                variant: PButtonVariant.outline,
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: PSpace.x12),
            Expanded(
              child: isPro
                  ? PButton(
                      label: '구독 해지',
                      variant: PButtonVariant.danger,
                      onPressed: _busy ? null : () => _cancel(nextBill),
                    )
                  : PButton(
                      label: _busy ? '처리 중…' : 'Pro 시작하기',
                      onPressed: _busy ? null : _subscribe,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _planCard(
    PorestTokens t, {
    required bool isPro,
    required bool current,
    int priceWon = 0,
    String priceUnit = '월',
    String? note,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.bgSurface,
        borderRadius: PRadius.brLg,
        border: Border.all(
          color: isPro ? t.bgBrand : t.borderDefault,
          width: isPro ? 2 : 1,
        ),
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
                      fontSize: 14,
                      fontWeight: PFontWeight.bold,
                      color: isPro ? t.fgBrand : t.fgPrimary,
                    ),
                  ),
                ],
              ),
              if (current)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPro ? t.bgBrandSubtle : t.bgSunken,
                    borderRadius: PRadius.brSm,
                  ),
                  child: Text(
                    '현재 플랜',
                    style: TextStyle(
                      fontFamily: PTypo.sans,
                      fontSize: 10.5,
                      fontWeight: PFontWeight.bold,
                      color: isPro ? t.fgBrandStrong : t.fgSecondary,
                    ),
                  ),
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
                  isPro ? '${_won(priceWon)}원' : '0원',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: PTypo.sans,
                    fontSize: 24,
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
                    '/ $priceUnit',
                    style: PTypo.caption.copyWith(color: t.fgTertiary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isPro ? (note ?? '월 단위 결제') : '기본 가계부 기능',
            style: PTypo.micro.copyWith(color: t.fgTertiary),
          ),
        ],
      ),
    );
  }

  Widget _featureHeader(PorestTokens t) {
    return Container(
      color: t.bgSunken,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '기능',
              style: TextStyle(
                fontFamily: PTypo.sans,
                fontSize: 11.5,
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
                fontSize: 11.5,
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
                fontSize: 11.5,
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
                      fontSize: 12.5,
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
        fontSize: 11.5,
        fontWeight: PFontWeight.bold,
        color: accent ? t.fgBrand : t.fgSecondary,
      ),
    );
  }
}
