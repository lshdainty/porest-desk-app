import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../app/theme/colors.dart';
import '../../../app/theme/radius.dart';
import '../../../app/theme/spacing.dart';
import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/format/krw.dart';
import '../../../core/settings/hide_amounts_unlock_dialog.dart';
import '../../../core/settings/settings_notifier.dart';
import '../../../shared/widgets/p_card.dart';
import '../../notification/application/notification_providers.dart';
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
    final summaryAsync =
        ref.watch(assetSummaryProvider((year: null, month: null)));

    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text('자산',
            style: TextStyle(
              color: t.fgPrimary,
              fontSize: PFontSize.h2,
              fontWeight: PFontWeight.bold,
              letterSpacing: -0.44,
            )),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          // web MobileHeader 와 동일: 다크모드 / 눈 / 알림(빨강 점) / 검색
          _IcoBtn(
            isDark: Theme.of(context).brightness == Brightness.dark,
            onTap: () {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              ref
                  .read(settingsProvider.notifier)
                  .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
            tokens: t,
          ),
          IconButton(
            tooltip: settings.hideAmounts ? '금액 표시' : '금액 숨김',
            icon: Icon(
              settings.hideAmounts ? LucideIcons.eyeOff : LucideIcons.eye,
              size: 20,
              color: t.fgPrimary,
            ),
            onPressed: () => toggleHideAmountsWithUnlock(context, ref),
          ),
          _NotificationBell(tokens: t),
          IconButton(
            tooltip: '검색',
            icon: Icon(LucideIcons.search, size: 20, color: t.fgPrimary),
            onPressed: () => context.push('/search'),
          ),
          const SizedBox(width: 4),
        ],
      ),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorBox(
            message: '자산을 불러오지 못했습니다\n$e',
            onRetry: () => ref.invalidate(assetsProvider),
          ),
          data: (assets) {
            final summary =
                summaryAsync.hasValue ? summaryAsync.value : null;
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
                Text('아직 등록된 자산이 없어요',
                    style: TextStyle(
                        color: tokens.fgTertiary,
                        fontSize: PFontSize.body,
                        fontWeight: PFontWeight.medium)),
                const SizedBox(height: PSpace.x12),
                FilledButton.icon(
                  onPressed: () => showAssetAddDialog(context),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text('첫 자산 추가하기'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final accounts = assets.where((a) => _accountTypes.contains(a.assetType)).toList();
    final cards = assets.where((a) => _cardTypes.contains(a.assetType)).toList();
    final investments =
        assets.where((a) => _investmentTypes.contains(a.assetType)).toList();
    final loans = assets.where((a) => _loanTypes.contains(a.assetType)).toList();

    int sumIncluded(List<Asset> arr) => arr
        .where((a) => a.isIncludedInTotal == 'Y')
        .fold<int>(0, (s, a) => s + (a.balance ?? 0));

    final accountsTotal = sumIncluded(accounts);
    final cardsTotal = sumIncluded(cards).abs();
    final investmentsTotal = sumIncluded(investments);
    final loansTotal = sumIncluded(loans).abs();

    final netWorth = summary?.netWorth ??
        (accountsTotal + investmentsTotal - cardsTotal - loansTotal);
    final changeAmount = summary?.changeAmount ?? 0;
    final changePercent = summary?.changePercent ?? 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          PSpace.x20, PSpace.x4, PSpace.x20, PSpace.x80),
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
          totalColor: PorestPalette.berry700,
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
            totalColor: PorestPalette.berry700,
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
    final trendColor =
        isUp ? PorestPalette.cobalt700 : PorestPalette.berry500;
    final t = tokens;
    return PCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('총 순자산',
                  style: TextStyle(
                      color: t.fgTertiary,
                      fontSize: PFontSize.caption,
                      fontWeight: PFontWeight.medium)),
              const SizedBox(width: 6),
              Icon(masked ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 14, color: t.fgTertiary),
              const Spacer(),
              // 자산 간 이체 — 헤더 아이콘에서 옮겨옴 (web 와 동일 패턴: 본문 안 액션).
              TextButton.icon(
                onPressed: () => showAssetTransferDialog(context),
                style: TextButton.styleFrom(
                  foregroundColor: t.fgSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(LucideIcons.arrowRightLeft,
                    size: 14, color: t.fgSecondary),
                label: Text('이체',
                    style: TextStyle(
                      color: t.fgSecondary,
                      fontSize: PFontSize.caption,
                      fontWeight: PFontWeight.semi,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Big amount
          RichText(
            text: TextSpan(
              text: masked ? '•••' : krw(netWorth),
              style: TextStyle(
                color: t.fgPrimary,
                fontSize: PFontSize.h1,
                fontWeight: PFontWeight.heavy,
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
                  color: trendColor),
              const SizedBox(width: 2),
              Text(
                '${isUp ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                style: TextStyle(
                    color: trendColor,
                    fontSize: PFontSize.bodySm,
                    fontWeight: PFontWeight.semi,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              if (!masked && changeAmount != 0) ...[
                const SizedBox(width: 4),
                Text(
                  '(${isUp ? '+' : '−'}${krw(changeAmount.abs())}원)',
                  style: TextStyle(
                      color: t.fgTertiary,
                      fontSize: PFontSize.bodySm,
                      fontWeight: PFontWeight.medium),
                ),
              ],
              const SizedBox(width: 10),
              Text('지난달 대비',
                  style: TextStyle(color: t.fgTertiary, fontSize: PFontSize.bodySm)),
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
                        tokens: t)),
                Expanded(
                    child: _SummaryCol(
                        label: '투자',
                        amount: investmentsTotal,
                        masked: masked,
                        tokens: t)),
                Expanded(
                    child: _SummaryCol(
                        label: '카드값',
                        amount: cardsTotal,
                        valueColor: PorestPalette.berry700,
                        negative: true,
                        masked: masked,
                        tokens: t)),
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
        Text(label,
            style: TextStyle(
                color: tokens.fgTertiary,
                fontSize: PFontSize.micro,
                fontWeight: PFontWeight.medium)),
        const SizedBox(height: 2),
        Text(
          masked
              ? '•••'
              : negative
                  ? '−${krw(amount.abs())}'
                  : krw(amount),
          style: TextStyle(
            color: valueColor ?? tokens.fgPrimary,
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

  void _onAdd(BuildContext context) {
    switch (kind) {
      case _GroupKind.account:
        showAssetAddDialog(context);
        break;
      case _GroupKind.investment:
        showInvestmentAddDialog(context);
        break;
      case _GroupKind.card:
        showCardAddDialog(context);
        break;
      case _GroupKind.loan:
        showAssetAddDialog(context, presetType: 'LOAN');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title,
                  style: TextStyle(
                      color: tokens.fgPrimary,
                      fontSize: PFontSize.bodyLg,
                      fontWeight: PFontWeight.bold)),
              const Spacer(),
              Text(
                masked
                    ? '•••'
                    : negativeTotal
                        ? '−${krw(total.abs())}원'
                        : '${krw(total)}원',
                style: TextStyle(
                  color: totalColor ?? tokens.fgPrimary,
                  fontSize: PFontSize.bodySm,
                  fontWeight: PFontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                borderRadius: PRadius.brMd,
                onTap: () => _onAdd(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.plus, size: 13, color: tokens.fgSecondary),
                      const SizedBox(width: 2),
                      Text('추가',
                          style: TextStyle(
                              color: tokens.fgSecondary,
                              fontSize: PFontSize.bodySm,
                              fontWeight: PFontWeight.semi)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (assets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('등록된 항목이 없어요',
                    style: TextStyle(color: tokens.fgTertiary, fontSize: PFontSize.bodySm)),
              ),
            )
          else
            for (int i = 0; i < assets.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _AssetCard(
                asset: assets[i],
                masked: masked,
                negativeAmount: negativeTotal,
                tokens: tokens,
              ),
            ],
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
    final balance = asset.balance ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: PRadius.brLg,
        onTap: () => showAssetDetailDialog(context, asset),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: t.bgSurface,
            borderRadius: PRadius.brLg,
            border: Border.all(color: t.borderSubtle),
          ),
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
                        if (asset.institution != null && asset.institution!.isNotEmpty) ...[
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
                              fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                masked
                    ? '•••'
                    : negativeAmount
                        ? '−${krw(balance.abs())}원'
                        : '${krw(balance)}원',
                style: TextStyle(
                  color: t.fgPrimary,
                  fontSize: PFontSize.bodyLg,
                  fontWeight: PFontWeight.bold,
                  letterSpacing: -0.32,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IcoBtn extends StatelessWidget {
  const _IcoBtn({
    required this.isDark,
    required this.onTap,
    required this.tokens,
  });
  final bool isDark;
  final VoidCallback onTap;
  final PorestTokens tokens;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: '테마 전환',
      icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon,
          size: 20, color: tokens.fgPrimary),
      onPressed: onTap,
    );
  }
}

/// 헤더 종 아이콘 + unread 배지 — front `NotificationBell` 미러.
/// 모바일 공통 헤더(MobileHeader)의 동일 패턴을 자산 화면 AppBar 에 인라인.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell({required this.tokens});
  final PorestTokens tokens;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).value ?? 0;
    return Tooltip(
      message: '알림',
      child: InkWell(
        onTap: () => context.push('/notifications'),
        borderRadius: PRadius.brFull,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(LucideIcons.bell, size: 20, color: tokens.fgPrimary),
              if (unread > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    constraints:
                        const BoxConstraints(minWidth: 10, minHeight: 10),
                    decoration: BoxDecoration(
                      color: tokens.statusDanger,
                      borderRadius: PRadius.brFull,
                      border: Border.all(color: tokens.bgSurface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
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
              Text(message, style: TextStyle(color: t.statusDangerFg, fontSize: PFontSize.bodySm)),
              const SizedBox(height: PSpace.x8),
              OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        ),
      ],
    );
  }
}
