import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_card.dart';
import 'package:porest_desk_app/shared/widgets/p_flat_section.dart';
import 'package:porest_desk_app/shared/widgets/p_skeleton.dart';
import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/asset/presentation/asset_edit_dialog.dart';
import 'package:porest_desk_app/features/asset/presentation/widgets/asset_logo.dart';
import 'package:porest_desk_app/features/asset/presentation/widgets/net_worth_chart.dart';

const _accountTypes = {'BANK_ACCOUNT', 'SAVINGS', 'CASH'};
const _cardTypes = {'CREDIT_CARD', 'CHECK_CARD'};
const _investmentTypes = {'INVESTMENT'};
const _loanTypes = {'LOAN'};

class AssetScreen extends ConsumerStatefulWidget {
  const AssetScreen({super.key});

  @override
  ConsumerState<AssetScreen> createState() => _AssetScreenState();
}

class _AssetScreenState extends ConsumerState<AssetScreen> {
  Timer? _valuationTimer;

  @override
  void initState() {
    super.initState();
    // 토스 연결 평가액 라이브 갱신 — 시세(현재가)를 10초마다 재조회.
    // 게이트 OFF(비프로/미연결)·연결 자산 없음이면 빈 맵이라 NOP.
    _valuationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) ref.invalidate(tossValuationMapProvider);
    });
  }

  @override
  void dispose() {
    _valuationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final assetsAsync = ref.watch(assetsProvider);
    final summaryAsync = ref.watch(
      assetSummaryProvider((year: null, month: null)),
    );
    // 토스 연결 투자 자산의 라이브 평가액(KRW) 맵 — assetRowId → 평가액 (게이트 OFF면 빈 맵).
    final valMap =
        ref.watch(tossValuationMapProvider).asData?.value ?? const <int, int>{};

    return Scaffold(
      backgroundColor: t.bgSurface,
      // appBar 제거 — shell MobileScaffold 의 MobileHeader 가 title='자산' +
      // actions(theme/eye/bell/search) 일관 표시.
      // bottomNavigationBar 는 shell MobileScaffold 가 path-aware MoneyTabBar 표시.
      // FAB 미사용 — 각 그룹(계좌·예금/투자/카드/대출) 헤더의 '+ 추가'
      // 버튼이 종류별 적절한 다이얼로그를 띄움.
      body: RefreshIndicator(
        color: t.bgBrand,
        onRefresh: () async {
          ref.invalidate(assetsProvider);
          ref.invalidate(assetSummaryProvider);
          ref.invalidate(netWorthTrendProvider);
          ref.invalidate(tossValuationMapProvider);
          await ref.read(assetsProvider.future);
        },
        child: assetsAsync.when(
          loading: () => const _AssetPageSkeleton(),
          error: (e, _) => _ErrorBox(
            message: '${l.assetLoadError}\n$e',
            onRetry: () => ref.invalidate(assetsProvider),
          ),
          data: (assets) {
            final summary = summaryAsync.hasValue ? summaryAsync.value : null;
            // 연결 자산 balance 를 라이브 평가액(시세×수량)으로 치환 + 순자산 보정용 delta(라이브−DB).
            final liveAssets = valMap.isEmpty
                ? assets
                : assets
                    .map(
                      (a) => valMap.containsKey(a.rowId)
                          ? a.copyWith(balance: valMap[a.rowId])
                          : a,
                    )
                    .toList();
            final summaryDelta = valMap.isEmpty
                ? 0
                : assets.fold<int>(
                    0,
                    (s, a) => (a.isIncludedInTotal == 'Y' &&
                            valMap.containsKey(a.rowId))
                        ? s + (valMap[a.rowId]! - (a.balance ?? 0))
                        : s,
                  );
            return _AssetBody(
              assets: liveAssets,
              summary: summary,
              summaryDelta: summaryDelta,
              masked: settings.hideAmounts,
              onToggleMask: () => toggleHideAmountsWithUnlock(context, ref),
              tokens: t,
            );
          },
        ),
      ),
    );
  }
}

class _AssetBody extends StatelessWidget {
  const _AssetBody({
    required this.assets,
    required this.summary,
    required this.summaryDelta,
    required this.masked,
    required this.onToggleMask,
    required this.tokens,
  });

  final List<Asset> assets;
  final AssetSummary? summary;
  // 토스 라이브 평가액 보정분(라이브−DB). summary(DB 기준) 순자산/변화에 더한다.
  final int summaryDelta;
  final bool masked;
  final VoidCallback onToggleMask;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (assets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: PSpace.x24, vertical: PSpace.x20),
        children: [
          const SizedBox(height: PSpace.x32),
          // 카드 다이어트 — 빈 상태도 카드 없이 플랫.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            child: Column(
              children: [
                Text(
                  l.assetEmptyState,
                  style: TextStyle(
                    color: tokens.fgTertiary,
                    fontSize: PFontSize.body,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
                const SizedBox(height: PSpace.x8),
                Text(
                  l.assetEmptyHint,
                  style: TextStyle(
                    color: tokens.fgTertiary,
                    fontSize: PFontSize.caption,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final accounts = assets
        .where((a) => _accountTypes.contains(a.assetType))
        .toList();
    final cards = assets
        .where((a) => _cardTypes.contains(a.assetType))
        .toList();
    final investments = assets
        .where((a) => _investmentTypes.contains(a.assetType))
        .toList();
    final loans = assets
        .where((a) => _loanTypes.contains(a.assetType))
        .toList();

    int sumIncluded(List<Asset> arr) => arr
        .where((a) => a.isIncludedInTotal == 'Y')
        .fold<int>(0, (s, a) => s + (a.balance ?? 0));

    final accountsTotal = sumIncluded(accounts);
    final cardsTotal = sumIncluded(cards).abs();
    final investmentsTotal = sumIncluded(investments);
    final loansTotal = sumIncluded(loans).abs();

    // summary(DB 기준)에 토스 라이브 평가액 보정. summary 없으면 liveAssets 합계가 이미 라이브.
    final netWorth = summary != null
        ? summary!.netWorth + summaryDelta
        : (accountsTotal + investmentsTotal - cardsTotal - loansTotal);
    final changeAmount = (summary?.changeAmount ?? 0) + summaryDelta;
    final lastMonth = summary?.lastMonthNetWorth ?? 0;
    final changePercent = lastMonth != 0
        ? (changeAmount / lastMonth.abs() * 1000).round() / 10
        : (summary?.changePercent ?? 0.0);

    // 카드 다이어트 — design AssetsScreen mobile: padding 16/20/24 + 섹션 gap 36.
    // 총순자산 요약만 keep(raised) 카드, 그룹들은 flat-group(라벨+총액+행).
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        PSpace.x24,
      ),
      children: [
        _SummaryCard(
          netWorth: netWorth,
          changeAmount: changeAmount,
          changePercent: changePercent,
          accountsTotal: accountsTotal,
          investmentsTotal: investmentsTotal,
          cardsTotal: cardsTotal,
          masked: masked,
          onToggleMask: onToggleMask,
          tokens: tokens,
        ),
        const SizedBox(height: PSpace.x32),
        _TypeGroup(
          title: l.assetGroupAccount,
          assets: accounts,
          total: accountsTotal,
          masked: masked,
          tokens: tokens,
          kind: _GroupKind.account,
        ),
        if (investments.isNotEmpty) ...[
          const SizedBox(height: PSpace.x32),
          _TypeGroup(
            title: l.assetGroupInvestment,
            assets: investments,
            total: investmentsTotal,
            masked: masked,
            tokens: tokens,
            kind: _GroupKind.investment,
          ),
        ],
        const SizedBox(height: PSpace.x32),
        _TypeGroup(
          title: l.assetGroupCard,
          assets: cards,
          total: cardsTotal,
          totalColor: tokens.fgExpense,
          negativeTotal: true,
          masked: masked,
          tokens: tokens,
          kind: _GroupKind.card,
        ),
        if (loans.isNotEmpty) ...[
          const SizedBox(height: PSpace.x32),
          _TypeGroup(
            title: l.assetGroupDebt,
            assets: loans,
            total: loansTotal,
            totalColor: tokens.fgExpense,
            negativeTotal: true,
            masked: masked,
            tokens: tokens,
            kind: _GroupKind.loan,
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.netWorth,
    required this.changeAmount,
    required this.changePercent,
    required this.accountsTotal,
    required this.investmentsTotal,
    required this.cardsTotal,
    required this.masked,
    required this.onToggleMask,
    required this.tokens,
  });

  final int netWorth;
  final int changeAmount;
  final double changePercent;
  final int accountsTotal;
  final int investmentsTotal;
  final int cardsTotal;
  final bool masked;

  /// 눈 아이콘 탭 — 금액 가리기 토글 (헤더 눈 버튼 제거 후 유일한 자산 진입점).
  final VoidCallback onToggleMask;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isUp = changeAmount >= 0;
    final trendColor = isUp ? tokens.fgIncome : tokens.fgExpense;
    final t = tokens;
    final l = AppLocalizations.of(context);
    // 총순자산 요약 — design `p-card--keep` (raised + shadow-lg, padding mobile 18).
    return PCard(
      variant: PCardVariant.raised,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.assetTotalNetWorth,
                style: TextStyle(
                  color: t.fgTertiary,
                  fontSize: PFontSize.caption,
                  fontWeight: PFontWeight.medium,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onToggleMask,
                borderRadius: PRadius.brFull,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    masked ? LucideIcons.eyeOff : LucideIcons.eye,
                    size: 14,
                    color: t.fgTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Big amount
          RichText(
            text: TextSpan(
              text: masked ? '••••••' : krw(netWorth),
              style: TextStyle(
                color: t.fgPrimary,
                fontSize: PFontSize.h1,
                fontWeight: PFontWeight.bold,
                letterSpacing: -0.84, // -0.03em × 28
                height: PLineHeight.tight,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              children: [
                if (!masked)
                  TextSpan(
                    text: ' ${wonUnit()}',
                    style: TextStyle(
                      color: t.fgPrimary,
                      fontSize: PFontSize.bodyLg,
                      fontWeight: PFontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isUp ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                size: 14,
                color: trendColor,
              ),
              const SizedBox(width: 2),
              Text(
                '${isUp ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: trendColor,
                  fontSize: PFontSize.bodySm,
                  fontWeight: PFontWeight.semi,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (!masked && changeAmount != 0) ...[
                const SizedBox(width: 4),
                Text(
                  '(${krwSigned(changeAmount.abs(), false, sign: isUp ? '+' : '−', unit: true)})',
                  style: TextStyle(
                    color: t.fgTertiary,
                    fontSize: PFontSize.bodySm,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                l.assetVsLastMonth,
                style: TextStyle(
                  color: t.fgTertiary,
                  fontSize: PFontSize.bodySm,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const NetWorthChart(height: 140),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCol(
                    label: l.assetSummaryColAccounts,
                    amount: accountsTotal,
                    masked: masked,
                    tokens: t,
                  ),
                ),
                Expanded(
                  child: _SummaryCol(
                    label: l.assetGroupInvestment,
                    amount: investmentsTotal,
                    masked: masked,
                    tokens: t,
                  ),
                ),
                Expanded(
                  child: _SummaryCol(
                    label: l.assetSummaryColCards,
                    amount: cardsTotal,
                    valueColor: t.fgExpense,
                    negative: true,
                    masked: masked,
                    tokens: t,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCol extends StatelessWidget {
  const _SummaryCol({
    required this.label,
    required this.amount,
    required this.masked,
    required this.tokens,
    this.valueColor,
    this.negative = false,
  });
  final String label;
  final int amount;
  final bool masked;
  final PorestTokens tokens;
  final Color? valueColor;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: tokens.fgTertiary,
            fontSize: PFontSize.micro,
            fontWeight: PFontWeight.medium,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          masked
              ? '••••••'
              : (negative && amount != 0)
              ? '−${krw(amount.abs())}'
              : krw(amount),
          style: TextStyle(
            // 0원이면 음수 색(빨강) 대신 중립색
            color: amount == 0 ? tokens.fgPrimary : (valueColor ?? tokens.fgPrimary),
            fontSize: PFontSize.body,
            fontWeight: PFontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

enum _GroupKind { account, investment, card, loan }

class _TypeGroup extends StatelessWidget {
  const _TypeGroup({
    required this.title,
    required this.assets,
    required this.total,
    required this.masked,
    required this.tokens,
    required this.kind,
    this.totalColor,
    this.negativeTotal = false,
  });
  final String title;
  final List<Asset> assets;
  final int total;
  final bool masked;
  final PorestTokens tokens;
  final _GroupKind kind;
  final Color? totalColor;
  final bool negativeTotal;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 총액이 0원이면 음수 표기(−)·빨강 없이 중립색으로 표시 (web 정합)
    final isZeroTotal = total == 0;
    final totalText = masked
        ? '••••••'
        : (negativeTotal && !isZeroTotal)
        ? krwSigned(total.abs(), false, sign: '−', unit: true)
        : krwSigned(total, false, unit: true);
    final effectiveTotalColor = isZeroTotal ? tokens.fgPrimary : (totalColor ?? tokens.fgPrimary);
    // 카드 다이어트 — design flat-group: 라벨(15/bold)+총액(13/bold 우측), 카드 없음.
    return PFlatSection(
      title: title,
      trailing: Text(
        totalText,
        style: TextStyle(
          color: effectiveTotalColor,
          fontSize: PFontSize.bodySm,
          fontWeight: PFontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (assets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  l.assetGroupEmpty,
                  style: TextStyle(
                    color: tokens.fgTertiary,
                    fontSize: PFontSize.bodySm,
                  ),
                ),
              ),
            )
          else
            for (int i = 0; i < assets.length; i++)
              _AssetCard(
                asset: assets[i],
                masked: masked,
                negativeAmount: negativeTotal,
                tokens: tokens,
              ),
        ],
      ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({
    required this.asset,
    required this.masked,
    required this.negativeAmount,
    required this.tokens,
  });
  final Asset asset;
  final bool masked;
  final bool negativeAmount;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    final balance = asset.balance ?? 0;
    // 음수(빚)만 fg-expense 빨강 + 부호(−), 0 은 부호·강조 없이 '0원' (−0원 방지)
    // — 관리 화면(account_card_manage_screen) 과 동일 로직.
    final isNeg = (negativeAmount ? -balance.abs() : balance) < 0;
    // design acc-card 플랫 행 — 구분선 없이 padding(12/10)+radius 10, 탭 hover 톤.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAssetDetailDialog(context, asset),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 2, 12), // web 12px 2px 12px 8px 정합
          child: Row(
            children: [
              AssetLogo(asset: asset),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            asset.assetName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: t.fgPrimary,
                              fontSize: PFontSize.body,
                              fontWeight: PFontWeight.semi,
                            ),
                          ),
                        ),
                        if (asset.institution != null &&
                            asset.institution!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              asset.institution!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: t.fgTertiary,
                                fontSize: PFontSize.caption,
                                fontWeight: PFontWeight.medium,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (asset.memo != null && asset.memo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          asset.memo!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.fgTertiary,
                            fontSize: PFontSize.caption,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    if (asset.assetType == 'CREDIT_CARD' &&
                        asset.paymentDay != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          l.assetPaymentDayInfo(asset.paymentDay!),
                          style: TextStyle(
                            color: t.fgTertiary,
                            fontSize: PFontSize.caption,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    if (asset.assetType == 'CREDIT_CARD' &&
                        (asset.creditLimit ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _CardUsageGauge(
                          used: balance.abs(),
                          limit: asset.creditLimit!,
                          masked: masked,
                          tokens: t,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    masked
                        ? '••••••'
                        : isNeg
                        ? krwSigned(balance.abs(), false, sign: '−', unit: true)
                        : krwSigned(balance.abs(), false, unit: true),
                    style: TextStyle(
                      color: isNeg ? t.fgExpense : t.fgPrimary,
                      fontSize: PFontSize.bodyLg,
                      fontWeight: PFontWeight.bold,
                      letterSpacing: -0.32,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  // 총액에서 제외된 자산이면 금액 아래 '총액 제외' 표기 (관리 화면 정합)
                  if (asset.isIncludedInTotal == 'N') ...[
                    const SizedBox(height: 2),
                    Text(
                      l.assetExcludedFromTotal,
                      style: TextStyle(
                        color: t.fgTertiary,
                        fontSize: PFontSize.micro,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 신용카드 사용률 게이지 — abs(balance)/creditLimit.
/// 70%↑ warning, 90%↑ danger 색. card_performance_bar 와 동일한
/// LinearProgressIndicator(ClipRRect) 패턴 재활용.
class _CardUsageGauge extends StatelessWidget {
  const _CardUsageGauge({
    required this.used,
    required this.limit,
    required this.masked,
    required this.tokens,
  });
  final int used;
  final int limit;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final ratio = limit > 0 ? used / limit : 0.0;
    final pct = (ratio * 100).round();
    final barColor = ratio >= 0.9
        ? t.statusDanger
        : ratio >= 0.7
        ? t.statusWarning
        : t.fgBrand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: PRadius.brXs,
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: t.bgTrack,
            color: barColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              masked
                  ? '••• / •••'
                  : '${krw(used)} / ${krwSigned(limit, false, unit: true)}',
              style: TextStyle(
                color: t.fgTertiary,
                fontSize: PFontSize.micro,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: TextStyle(
                color: barColor,
                fontSize: PFontSize.micro,
                fontWeight: PFontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Asset 페이지 구조 맞춤 skeleton — Web AssetPageSkeleton 정합.
/// SummaryCard (Hero netWorth + chart + 3-col total) + TypeGroup x2.
class _AssetPageSkeleton extends StatelessWidget {
  const _AssetPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        PSpace.x24,
      ),
      children: const [
        _AssetSummaryCardSkeleton(),
        SizedBox(height: PSpace.x32),
        _AssetTypeGroupSkeleton(rows: 3),
        SizedBox(height: PSpace.x32),
        _AssetTypeGroupSkeleton(rows: 2),
      ],
    );
  }
}

class _AssetSummaryCardSkeleton extends StatelessWidget {
  const _AssetSummaryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // keep(raised) 요약 카드 스켈레톤 — 실제 _SummaryCard 와 동일 껍데기.
    return PCard(
      variant: PCardVariant.raised,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: 라벨 + eye(6 gap)
          Row(
            children: const [
              PSkeleton.line(width: 56, height: 12),
              SizedBox(width: 6),
              PSkeleton(width: 14, height: 14, borderRadius: PRadius.brXs),
            ],
          ),
          const SizedBox(height: 6),
          // 큰 amount
          const PSkeleton.line(width: 200, height: 32),
          const SizedBox(height: 6),
          // trend row
          Row(
            children: const [
              PSkeleton(width: 14, height: 14, borderRadius: PRadius.brXs),
              SizedBox(width: PSpace.x4),
              PSkeleton.line(width: 56, height: 14),
              SizedBox(width: PSpace.x8),
              PSkeleton.line(width: 100, height: 14),
            ],
          ),
          const SizedBox(height: 14),
          // NetWorthChart placeholder — 실제 차트 자체 로딩 스켈레톤(brLg) 정합.
          const PSkeleton(
            width: double.infinity,
            height: 140,
            borderRadius: PRadius.brLg,
          ),
          const SizedBox(height: 14),
          // 3-col border-top section
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: t.borderSubtle)),
            ),
            child: Row(
              children: const [
                Expanded(child: _AssetSummaryColPlaceholder()),
                Expanded(child: _AssetSummaryColPlaceholder()),
                Expanded(child: _AssetSummaryColPlaceholder()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssetSummaryColPlaceholder extends StatelessWidget {
  const _AssetSummaryColPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // 실제 _SummaryCol: label(micro) + 2px gap + amount(body)
        PSkeleton.line(width: 48, height: 11),
        SizedBox(height: 2),
        PSkeleton.line(width: 72, height: 14),
      ],
    );
  }
}

class _AssetTypeGroupSkeleton extends StatelessWidget {
  const _AssetTypeGroupSkeleton({required this.rows});
  final int rows;

  @override
  Widget build(BuildContext context) {
    // 카드 다이어트 — 플랫 그룹 스켈레톤 (라벨+총액 헤드 + acc-card 행 리듬).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // header: title(15/bold) + Spacer + total(bodySm) — 실제 _TypeGroup 정합.
          Padding(
            padding: const EdgeInsets.only(bottom: PSpace.x8),
            child: Row(
              children: const [
                PSkeleton.line(width: 80, height: 16),
                Spacer(),
                PSkeleton.line(width: 96, height: 14),
              ],
            ),
          ),
          // rows — 실제 _AssetCard 정합: logo(40, brLg) + 14 gap + 2 line +
          // amount(bodyLg). 플랫 행 리듬 padding (10 / v12), 구분선 없음.
          for (int i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                8, PSpace.x12, 2, PSpace.x12, // web 12px 2px 12px 8px 정합
              ),
              child: Row(
                children: [
                  const PSkeleton(
                    width: 40,
                    height: 40,
                    borderRadius: PRadius.brLg,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        PSkeleton.line(width: 120, height: 14),
                        SizedBox(height: PSpace.x4),
                        PSkeleton.line(width: 72, height: 11),
                      ],
                    ),
                  ),
                  const SizedBox(width: PSpace.x8),
                  const PSkeleton.line(width: 96, height: 16),
                ],
              ),
            ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(PSpace.x16),
      children: [
        Container(
          padding: const EdgeInsets.all(PSpace.x16),
          decoration: BoxDecoration(
            color: t.statusDangerSubtle,
            borderRadius: PRadius.brLg,
          ),
          child: Column(
            children: [
              Text(
                message,
                style: TextStyle(
                  color: t.statusDangerFg,
                  fontSize: PFontSize.bodySm,
                ),
              ),
              const SizedBox(height: PSpace.x8),
              PButton(
                label: l.actionRetry,
                variant: PButtonVariant.outline,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
