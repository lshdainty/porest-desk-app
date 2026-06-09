import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/widgets/p_button.dart';
import '../../../shared/widgets/p_card.dart';
import '../../../shared/widgets/p_skeleton.dart';
import '../application/asset_providers.dart';
import '../domain/asset.dart';
import '../domain/asset_summary.dart';
import 'asset_edit_dialog.dart';
import 'asset_transfer_dialog.dart';
import 'widgets/asset_logo.dart';
import 'widgets/net_worth_chart.dart';

const _accountTypes = {'BANK_ACCOUNT', 'SAVINGS', 'CASH'};
const _cardTypes = {'CREDIT_CARD', 'CHECK_CARD'};
const _investmentTypes = {'INVESTMENT'};
const _loanTypes = {'LOAN'};

class AssetScreen extends ConsumerWidget {
  const AssetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final settings = ref.watch(settingsProvider).value ?? AppSettings.defaults;
    final assetsAsync = ref.watch(assetsProvider);
    final summaryAsync = ref.watch(
      assetSummaryProvider((year: null, month: null)),
    );

    return Scaffold(
      backgroundColor: t.bgCanvas,
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
          await ref.read(assetsProvider.future);
        },
        child: assetsAsync.when(
          loading: () => const _AssetPageSkeleton(),
          error: (e, _) => _ErrorBox(
            message: '자산을 불러오지 못했습니다\n$e',
            onRetry: () => ref.invalidate(assetsProvider),
          ),
          data: (assets) {
            final summary = summaryAsync.hasValue ? summaryAsync.value : null;
            return _AssetBody(
              assets: assets,
              summary: summary,
              masked: settings.hideAmounts,
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
    required this.masked,
    required this.tokens,
  });

  final List<Asset> assets;
  final AssetSummary? summary;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(PSpace.x20),
        children: [
          const SizedBox(height: PSpace.x32),
          PCard(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
            child: Column(
              children: [
                Text(
                  '아직 등록된 자산이 없어요',
                  style: TextStyle(
                    color: tokens.fgTertiary,
                    fontSize: PFontSize.body,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
                const SizedBox(height: PSpace.x8),
                Text(
                  '설정 → 카드·계좌 관리에서 추가할 수 있어요',
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

    final netWorth =
        summary?.netWorth ??
        (accountsTotal + investmentsTotal - cardsTotal - loansTotal);
    final changeAmount = summary?.changeAmount ?? 0;
    final changePercent = summary?.changePercent ?? 0.0;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x20,
        vertical: PSpace.x24,
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
          tokens: tokens,
        ),
        const SizedBox(height: PSpace.x16),
        _TypeGroup(
          title: '계좌 · 예금',
          assets: accounts,
          total: accountsTotal,
          masked: masked,
          tokens: tokens,
          kind: _GroupKind.account,
        ),
        if (investments.isNotEmpty) ...[
          const SizedBox(height: PSpace.x16),
          _TypeGroup(
            title: '투자',
            assets: investments,
            total: investmentsTotal,
            masked: masked,
            tokens: tokens,
            kind: _GroupKind.investment,
          ),
        ],
        const SizedBox(height: PSpace.x16),
        _TypeGroup(
          title: '카드',
          assets: cards,
          total: cardsTotal,
          totalColor: tokens.fgExpense,
          negativeTotal: true,
          masked: masked,
          tokens: tokens,
          kind: _GroupKind.card,
        ),
        if (loans.isNotEmpty) ...[
          const SizedBox(height: PSpace.x16),
          _TypeGroup(
            title: '대출',
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
    required this.tokens,
  });

  final int netWorth;
  final int changeAmount;
  final double changePercent;
  final int accountsTotal;
  final int investmentsTotal;
  final int cardsTotal;
  final bool masked;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    final isUp = changeAmount >= 0;
    final trendColor = isUp ? tokens.fgIncome : tokens.fgExpense;
    final t = tokens;
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '총 순자산',
                style: TextStyle(
                  color: t.fgTertiary,
                  fontSize: PFontSize.caption,
                  fontWeight: PFontWeight.medium,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                masked ? LucideIcons.eyeOff : LucideIcons.eye,
                size: 14,
                color: t.fgTertiary,
              ),
              const Spacer(),
              // 자산 간 이체 — 헤더 아이콘에서 옮겨옴 (web 와 동일 패턴: 본문 안 액션).
              PButton(
                label: '이체',
                icon: LucideIcons.arrowRightLeft,
                variant: PButtonVariant.ghost,
                size: PButtonSize.sm,
                onPressed: () => showAssetTransferDialog(context),
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
                    text: ' 원',
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
                  '(${isUp ? '+' : '−'}${krw(changeAmount.abs())}원)',
                  style: TextStyle(
                    color: t.fgTertiary,
                    fontSize: PFontSize.bodySm,
                    fontWeight: PFontWeight.medium,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                '지난달 대비',
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
                    label: '계좌·예금',
                    amount: accountsTotal,
                    masked: masked,
                    tokens: t,
                  ),
                ),
                Expanded(
                  child: _SummaryCol(
                    label: '투자',
                    amount: investmentsTotal,
                    masked: masked,
                    tokens: t,
                  ),
                ),
                Expanded(
                  child: _SummaryCol(
                    label: '카드값',
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
    // 총액이 0원이면 음수 표기(−)·빨강 없이 중립색으로 표시 (web 정합)
    final isZeroTotal = total == 0;
    final totalText = masked
        ? '••••••'
        : (negativeTotal && !isZeroTotal)
        ? '−${krw(total.abs())}원'
        : '${krw(total)}원';
    final effectiveTotalColor = isZeroTotal ? tokens.fgPrimary : (totalColor ?? tokens.fgPrimary);
    return PCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: tokens.fgPrimary,
                  fontSize: PFontSize.bodyLg,
                  fontWeight: PFontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                totalText,
                style: TextStyle(
                  color: effectiveTotalColor,
                  fontSize: PFontSize.bodySm,
                  fontWeight: PFontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (assets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '등록된 항목이 없어요',
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
                showTopBorder: i > 0,
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
    required this.showTopBorder,
  });
  final Asset asset;
  final bool masked;
  final bool negativeAmount;
  final PorestTokens tokens;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final balance = asset.balance ?? 0;
    // 음수(빚)만 fg-expense 빨강 + 부호(−), 0 은 부호·강조 없이 '0원' (−0원 방지)
    // — 관리 화면(account_card_manage_screen) 과 동일 로직.
    final isNeg = (negativeAmount ? -balance.abs() : balance) < 0;
    // list item — 자체 round/border 없음. 부모 list 가 큰 카드, item 사이 border-top
    // 1px (첫 item 제외) 으로 구분. 클로드 디자인 톤.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAssetDetailDialog(context, asset),
        child: Container(
          decoration: BoxDecoration(
            border: showTopBorder
                ? Border(top: BorderSide(color: t.borderSubtle))
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
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
                          '${asset.paymentDay}일 결제',
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
                        ? '−${krw(balance.abs())}원'
                        : '${krw(balance.abs())}원',
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
                      '총액 제외',
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
              masked ? '••• / •••' : '${krw(used)} / ${krw(limit)}원',
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
      padding: const EdgeInsets.symmetric(
        horizontal: PSpace.x20,
        vertical: PSpace.x24,
      ),
      children: const [
        _AssetSummaryCardSkeleton(),
        SizedBox(height: PSpace.x16),
        _AssetTypeGroupSkeleton(rows: 3),
        SizedBox(height: PSpace.x16),
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
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: 라벨 + eye + Spacer + 이체 button
          Row(
            children: const [
              PSkeleton.line(width: 56, height: 12),
              SizedBox(width: PSpace.x4),
              PSkeleton(width: 14, height: 14, borderRadius: PRadius.brXs),
              Spacer(),
              PSkeleton(width: 56, height: 28, borderRadius: PRadius.brSm),
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
          const SizedBox(height: PSpace.x12),
          // NetWorthChart placeholder
          const PSkeleton(
            width: double.infinity,
            height: 140,
            borderRadius: PRadius.brSm,
          ),
          const SizedBox(height: PSpace.x12),
          // 3-col border-top section
          Container(
            padding: const EdgeInsets.only(top: PSpace.x12),
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
        PSkeleton.line(width: 48, height: 11),
        SizedBox(height: PSpace.x8),
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
    final t = context.tokens;
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header: title + total + add button
          Row(
            children: const [
              PSkeleton.line(width: 80, height: 16),
              Spacer(),
              PSkeleton.line(width: 96, height: 14),
              SizedBox(width: PSpace.x8),
              PSkeleton(width: 48, height: 28, borderRadius: PRadius.brSm),
            ],
          ),
          const SizedBox(height: PSpace.x12),
          // rows — item 사이 border-top
          for (int i = 0; i < rows; i++)
            Container(
              decoration: BoxDecoration(
                border: i > 0
                    ? Border(top: BorderSide(color: t.borderSubtle))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x4,
                vertical: PSpace.x12,
              ),
              child: Row(
                children: [
                  const PSkeleton(
                    width: 40,
                    height: 40,
                    borderRadius: PRadius.brSm,
                  ),
                  const SizedBox(width: PSpace.x12),
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
      ),
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
                label: '다시 시도',
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
