import 'dart:async';

import 'package:flutter/material.dart';
import 'package:porest_desk_app/core/format/currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/format/chart_palette.dart';
import 'package:porest_desk_app/core/format/krw.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/shared/icons/lucide_icon_map.dart';
import 'package:porest_desk_app/shared/widgets/p_badge.dart';
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
import 'package:porest_desk_app/features/saving_goal/application/saving_goal_providers.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';
import 'package:porest_desk_app/shared/widgets/p_tab_bar.dart';

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
      if (mounted) ref.invalidate(investmentValuationMapProvider);
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
    final assetsAsync = ref.watch(assetsProvider);
    final summaryAsync = ref.watch(
      assetSummaryProvider((year: null, month: null)),
    );
    // 투자 자산 라이브 평가(평가액·등락) 맵 — holdings/레거시 연동 공용. 게이트 OFF·미평가 시 빈 맵.
    final invMap = ref.watch(investmentValuationMapProvider).asData?.value ??
        const <int, InvestmentValuation>{};
    final valMap = {for (final e in invMap.entries) e.key: e.value.value};

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
          ref.invalidate(investmentValuationMapProvider);
          ref.invalidate(savingGoalListProvider);
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
            // 라이브 평가는 '보유분'만이라 예수금을 더해야 계좌 총액이 된다.
            // 안 더하면 증권계좌에 넣어 둔 매수 대기 자금이 목록에서 통째로 빠진다.
            int liveTotal(Asset a) => (a.cashBalance ?? 0) + valMap[a.rowId]!;
            final liveAssets = valMap.isEmpty
                ? assets
                : assets
                    .map(
                      (a) => valMap.containsKey(a.rowId)
                          ? a.copyWith(
                              balance: liveTotal(a),
                              holdingBalance: valMap[a.rowId])
                          : a,
                    )
                    .toList();
            final summaryDelta = valMap.isEmpty
                ? 0
                : assets.fold<int>(
                    0,
                    (s, a) => (a.isIncludedInTotal == 'Y' &&
                            valMap.containsKey(a.rowId))
                        ? s + (liveTotal(a) - (a.balance ?? 0))
                        : s,
                  );
            return _AssetBody(
              assets: liveAssets,
              summary: summary,
              summaryDelta: summaryDelta,
              valuations: invMap,
              goals: ref.watch(savingGoalListProvider),
              masked: ref.watch(hideCardProvider('asset.netWorth')),
              onToggleMask: () => context.push('/settings/appearance?hide=1'),
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
    required this.valuations,
    required this.goals,
    required this.masked,
    required this.onToggleMask,
    required this.tokens,
  });

  final List<Asset> assets;
  final AssetSummary? summary;
  // 토스 라이브 평가액 보정분(라이브−DB). summary(DB 기준) 순자산/변화에 더한다.
  final int summaryDelta;
  // 투자 자산 라이브 평가 맵 — 행 등락 표시용.
  final Map<int, InvestmentValuation> valuations;
  // 저축 목표 — 조회 전용 섹션 (관리는 설정 > 저축 목표).
  final AsyncValue<List<SavingGoal>> goals;
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

    // 외화는 환산해서 더한다 — raw 로 더하면 USD 1,000 이 1,000원이 돼 서버 요약과 어긋난다.
    int sumIncluded(List<Asset> arr) => arr
        .where((a) => a.isIncludedInTotal == 'Y')
        .fold<int>(
            0,
            (s, a) => s +
                balanceInKrw(a.balance ?? 0, a.currency, a.exchangeRate));

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
      padding: EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        // 플로팅 탭바 보상
        pTabBarBottomInset(context),
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
            valuations: valuations,
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
        const SizedBox(height: PSpace.x32),
        _SavingGoalsSection(goals: goals, masked: masked, tokens: tokens),
      ],
    );
  }
}

/// 저축 목표 — 조회 전용 flat 섹션 (design AssetsScreen GoalsCard / 웹 SavingGoalsCard 미러).
/// 추가·수정·삭제는 '관리 >' 링크로 설정 > 저축 목표에서.
class _SavingGoalsSection extends StatelessWidget {
  const _SavingGoalsSection({
    required this.goals,
    required this.masked,
    required this.tokens,
  });

  final AsyncValue<List<SavingGoal>> goals;
  final bool masked;
  final PorestTokens tokens;

  String? _deadlineLabel(SavingGoal g) {
    final raw = g.deadlineDate;
    if (raw == null || raw.isEmpty) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    return '${d.year}.${d.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = goals.asData?.value ?? const <SavingGoal>[];
    final loading = goals.isLoading && items.isEmpty;
    return PFlatSection(
      title: l.navSavingGoals,
      trailing: PFlatSectionLink(
        label: l.savingGoalManageLink,
        onTap: () => context.push('/saving-goals'),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      child: loading
          ? Column(
              children: [
                for (int i = 0; i < 2; i++) ...[
                  if (i > 0) const SizedBox(height: PSpace.x16),
                  Row(
                    children: [
                      PSkeleton(
                          width: 32, height: 32, borderRadius: PRadius.tile(32)),
                      const SizedBox(width: PSpace.x8),
                      const Expanded(child: PSkeleton.line(width: 120)),
                      const PSkeleton.line(width: 48, height: 12),
                    ],
                  ),
                ],
              ],
            )
          : items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: PSpace.x20),
                  child: Center(
                    child: Text(
                      l.savingGoalManagePrompt,
                      style: PTypo.bodySm.copyWith(color: tokens.fgTertiary),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: PSpace.x16),
                      _SavingGoalRow(
                        goal: items[i],
                        masked: masked,
                        tokens: tokens,
                        deadlineLabel: _deadlineLabel(items[i]),
                      ),
                    ],
                  ],
                ),
    );
  }
}

/// 저축 목표 행 — 아이콘 타일 + 이름·기한 + %/금액 + 진행바 (웹 SavingGoalItem 미러).
class _SavingGoalRow extends StatelessWidget {
  const _SavingGoalRow({
    required this.goal,
    required this.masked,
    required this.tokens,
    required this.deadlineLabel,
  });

  final SavingGoal goal;
  final bool masked;
  final PorestTokens tokens;
  final String? deadlineLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final color =
        resolveChartColor(context, goal.color, fallback: tokens.fgBrand);
    final bg = softBg(context, color);
    final pct = (goal.progress * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration:
                  BoxDecoration(color: bg, borderRadius: PRadius.tile(32)),
              alignment: Alignment.center,
              child: Icon(
                  lucideByName(goal.icon, fallback: LucideIcons.piggyBank),
                  size: 15,
                  color: color),
            ),
            const SizedBox(width: PSpace.x8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(goal.title,
                            overflow: TextOverflow.ellipsis,
                            style: PTypo.body.copyWith(
                                color: tokens.fgPrimary,
                                fontWeight: PFontWeight.semi)),
                      ),
                      if (goal.achieved) ...[
                        const SizedBox(width: 6),
                        PBadge(
                            label: l.savingGoalAchieved,
                            variant: PBadgeVariant.softSuccess),
                      ],
                    ],
                  ),
                  Text(deadlineLabel ?? l.savingGoalNoDeadline,
                      style:
                          PTypo.caption.copyWith(color: tokens.fgTertiary)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$pct%',
                    style: PTypo.bodySm.copyWith(
                        color: tokens.fgPrimary,
                        fontWeight: PFontWeight.bold)),
                Text(
                    '${krwMasked(goal.currentAmount, masked, mask: '••••')} / ${krwMasked(goal.targetAmount, masked, mask: '••••')}',
                    style: PTypo.micro.copyWith(color: tokens.fgTertiary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: PSpace.x8),
        ClipRRect(
          borderRadius: PRadius.brXs,
          child: LinearProgressIndicator(
            value: goal.progress,
            minHeight: 6,
            backgroundColor: tokens.bgTrack,
            color: color,
          ),
        ),
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
    this.valuations = const {},
  });
  final String title;
  final List<Asset> assets;
  final int total;
  final bool masked;
  final PorestTokens tokens;
  final _GroupKind kind;
  final Color? totalColor;
  final bool negativeTotal;
  // 투자 그룹 전용 — 행 등락(오늘 변화) 표시.
  final Map<int, InvestmentValuation> valuations;

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
                valuation: valuations[assets[i].rowId],
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
    this.valuation,
  });
  final Asset asset;
  final bool masked;
  final bool negativeAmount;
  final PorestTokens tokens;
  // 투자 자산 라이브 평가(등락 표시용) — 투자 외엔 null.
  final InvestmentValuation? valuation;

  @override
  Widget build(BuildContext context) {
    final t = tokens;
    final l = AppLocalizations.of(context);
    // 외화는 환산액이 주 표기 — 원 통화 잔고는 밑에 함께 보여 준다.
    final balance =
        balanceInKrw(asset.balance ?? 0, asset.currency, asset.exchangeRate);
    // 음수(빚)만 fg-expense 빨강 + 부호(−), 0 은 부호·강조 없이 '0원' (−0원 방지)
    // — 관리 화면(account_card_manage_screen) 과 동일 로직.
    // 저장된 부호를 그대로 믿는다 — 예전엔 카드 그룹에서 부호를 강제로 뒤집었는데,
    // 그러면 데이터가 양수로 어긋나도 행은 멀쩡해 보이고 합계만 틀린 값이 나온다.
    // 지금은 저장할 때 음수로 정규화하므로 표시에서 손볼 게 없다.
    final isNeg = balance < 0;

    // 신용카드 사용률 — 한도가 있어야 뜻이 있다.
    final showGauge =
        asset.assetType == 'CREDIT_CARD' && (asset.creditLimit ?? 0) > 0;
    final gaugeRatio = showGauge ? balance.abs() / asset.creditLimit! : 0.0;
    final gaugeColor = gaugeRatio >= 0.9
        ? t.statusDanger
        : gaugeRatio >= 0.7
            ? t.statusWarning
            : t.fgBrand;

    // design acc-card 플랫 행 — 구분선 없이 padding(12/10)+radius 10, 탭 hover 톤.
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAssetDetailDialog(context, asset),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 2, 12), // web 12px 2px 12px 8px 정합
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Row(
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
                    if (asset.assetType == 'INVESTMENT' &&
                        asset.holdings.isNotEmpty)
                      // design 투자 행 서브 — 대표 종목 "외 N종목" (memo 는 상세에서).
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          _holdingsRep(l, asset.holdings),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.fgTertiary,
                            fontSize: PFontSize.caption,
                          ),
                        ),
                      )
                    // 카드는 메모를 행에 안 띄운다. 아래로 결제일·게이지가 이어지는데
                    // 메모가 한 줄 끼면 그만큼 밀려, 카드마다 게이지 높이가 달라진다.
                    // 투자 행이 이미 쓰는 원칙과 같다 — 메모는 상세에서 본다.
                    else if (!_cardTypes.contains(asset.assetType) &&
                        asset.memo != null &&
                        asset.memo!.isNotEmpty)
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
                    // 신용카드는 이 줄을 늘 차지한다. 결제일이 없다고 줄을 빼면
                    // 그 카드만 게이지가 위로 붙어 목록이 어긋난다.
                    if (asset.assetType == 'CREDIT_CARD')
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          asset.paymentDay != null
                              ? l.assetPaymentDayInfo(asset.paymentDay!)
                              : '',
                          style: TextStyle(
                            color: t.fgTertiary,
                            fontSize: PFontSize.caption,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
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
                    // 행 금액 중립색 — 부호(−)만 유지(사용자 결정)
                    style: TextStyle(
                      color: t.fgPrimary,
                      fontSize: PFontSize.bodyLg,
                      fontWeight: PFontWeight.bold,
                      letterSpacing: -0.32,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  // 외화 행 — 환산액 밑에 원 통화 잔고를 함께.
                  if (!masked && isForeignCurrency(asset.currency)) ...[
                    const SizedBox(height: 2),
                    Text(
                      formatOriginalAmount(
                        (asset.balance ?? 0).toDouble(),
                        asset.currency!,
                        Localizations.localeOf(context).toString(),
                      ),
                      style: TextStyle(
                        color: t.fgTertiary,
                        fontSize: PFontSize.micro,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  // 투자 행 등락 — design: +N% (+M원), 상승=빨강/하락=파랑(국내 통념).
                  if (!masked &&
                      valuation != null &&
                      valuation!.changeAmt != null) ...[
                    const SizedBox(height: 2),
                    Builder(builder: (context) {
                      final chg = valuation!.changeAmt!;
                      final base = valuation!.value - chg;
                      final pct = base == 0 ? 0.0 : chg / base * 100;
                      final up = chg >= 0;
                      final color = up ? t.statusDangerFg : t.fgBrand;
                      final pctText =
                          '${up ? '+' : ''}${pct.toStringAsFixed(1)}%';
                      final amtText = krwSigned(chg.abs(), false,
                          sign: up ? '+' : '−', unit: true);
                      return Text(
                        '$pctText ($amtText)',
                        style: TextStyle(
                          color: color,
                          fontSize: PFontSize.micro,
                          fontWeight: PFontWeight.semi,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      );
                    }),
                  ],
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
                  // 카드 사용액·사용률 — 게이지 바는 아래 행 전체 폭으로 따로 그린다.
                  // 왼쪽 텍스트 열에 두면 카드 이름 길이에 밀려 폭이 모자라 넘친다.
                  if (showGauge) ...[
                    const SizedBox(height: 2),
                    Text(
                      masked
                          ? '••• / •••'
                          : '${krw(balance.abs())} / ${krwSigned(asset.creditLimit!, false, unit: true)}',
                      style: TextStyle(
                        color: t.fgTertiary,
                        fontSize: PFontSize.micro,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          // 게이지는 행 맨 아래, 아이콘부터 오른쪽 끝까지 한 줄로. 예산 카테고리 행과
          // 같은 배치라 카드 이름이나 금액 길이와 무관하게 시작·끝이 늘 같다.
          if (showGauge) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: PRadius.brFull,
                    child: LinearProgressIndicator(
                      value: gaugeRatio.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: t.bgTrack,
                      color: gaugeColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(gaugeRatio * 100).round()}%',
                  style: TextStyle(
                    color: gaugeColor,
                    fontSize: PFontSize.micro,
                    fontWeight: PFontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

/// 투자 보유 요약 서브라인 — "대표종목 외 N종목" / 단일 이름 / 빈 목록 문구.
String _holdingsRep(AppLocalizations l, List<AssetHolding> holdings) {
  if (holdings.isEmpty) return l.assetNoHoldings;
  String nameOf(AssetHolding h) =>
      (h.holdingName?.isNotEmpty ?? false) ? h.holdingName! : (h.tossSymbol ?? '');
  final first = nameOf(holdings.first);
  if (holdings.length == 1) return first;
  return l.assetHoldingRep(first, holdings.length - 1);
}

/// Asset 페이지 구조 맞춤 skeleton — Web AssetPageSkeleton 정합.
/// SummaryCard (Hero netWorth + chart + 3-col total) + TypeGroup x2.
class _AssetPageSkeleton extends StatelessWidget {
  const _AssetPageSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        PSpace.x24,
        PSpace.x16,
        PSpace.x24,
        pTabBarBottomInset(context),
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
