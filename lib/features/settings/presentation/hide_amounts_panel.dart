import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';

/// 금액 가리기 본문 — 계정 > 보안 > 금액 가리기 화면의 내용 (design `hide-amounts.jsx` 미러).
///
/// 예전엔 표시 설정 안의 아코디언이었는데, 카드가 37장이라 접힌 채로는 무엇이 가려졌는지
/// 알 수 없고 펼치면 표시 설정을 통째로 밀어냈다. 지금은 보안 화면의 한 행으로 들어가
/// [HideAmountsScreen] 에서 전체를 펼쳐 본다.
///
/// 가리는 건 자유롭게, **푸는 건 비밀번호**를 받는다. 전체·화면 스위치로 풀면 그 묶음을
/// 한 번의 인증으로 처리한다 — 카드마다 비밀번호를 치게 하면 못 쓴다.
class HideAmountsPanel extends ConsumerStatefulWidget {
  const HideAmountsPanel({super.key});

  @override
  ConsumerState<HideAmountsPanel> createState() => _HideAmountsPanelState();
}

class _HideAmountsPanelState extends ConsumerState<HideAmountsPanel> {
  Future<void> _apply(Iterable<String> cards, bool hide) =>
      setHideCardsWithUnlock(context, ref, cards: cards, hide: hide);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final hidden = ref.watch(settingsProvider).value?.hideCards ?? const <String>{};
    final total = kAllHideCards.length;
    final allOn = hidden.length == total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: PSpace.x4),
          child: Text(l.hideAmountsSectionDesc,
              style: PTypo.caption.copyWith(color: t.fgTertiary, height: 1.55)),
        ),
        // ── 전체 잠그기 마스터
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: PSpace.x4, vertical: PSpace.x12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: allOn ? t.bgBrandSubtle : t.bgMuted,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.lock,
                    size: 16, color: allOn ? t.fgBrand : t.fgSecondary),
              ),
              const SizedBox(width: PSpace.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.hideAmountsLockAll,
                        style: PTypo.body.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(l.hideAmountsLockAllDesc(total, hidden.length),
                        style: PTypo.caption.copyWith(color: t.fgTertiary)),
                  ],
                ),
              ),
              SizedBox(
                height: 24,
                child: PSwitch(
                  value: allOn,
                  onChanged: (v) => _apply(kAllHideCards, v),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: t.borderSubtle),

        // ── 화면별 (전체 잠금이면 만질 필요가 없다 — 물러나 있게)
        IgnorePointer(
          ignoring: allOn,
          child: Opacity(
            opacity: allOn ? 0.55 : 1,
            child: Column(
              children: [
                for (final page in HidePage.values)
                  _PageBlock(
                    page: page,
                    hidden: hidden,
                    onApply: _apply,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PageBlock extends StatelessWidget {
  const _PageBlock({
    required this.page,
    required this.hidden,
    required this.onApply,
  });

  final HidePage page;
  final Set<String> hidden;
  final Future<void> Function(Iterable<String>, bool) onApply;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final cards = cardsOfPage(page);
    final on = cards.where(hidden.contains).length;

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: PSpace.x4, bottom: PSpace.x12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_pageLabel(l, page),
                          style: PTypo.bodyLg.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('$on / ${cards.length}',
                          style:
                              PTypo.caption.copyWith(color: t.fgTertiary)),
                    ],
                  ),
                ),
                SizedBox(
                  height: 24,
                  child: PSwitch(
                    value: on == cards.length,
                    onChanged: (v) => onApply(cards, v),
                  ),
                ),
              ],
            ),
          ),
          for (final card in cards)
            Container(
              padding: const EdgeInsets.only(
                  left: 10, top: PSpace.x12, bottom: PSpace.x12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.borderSubtle)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_cardLabel(l, card),
                        style: PTypo.body.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.medium)),
                  ),
                  SizedBox(
                    height: 24,
                    child: PSwitch(
                      value: hidden.contains(card),
                      onChanged: (v) => onApply([card], v),
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

String _pageLabel(AppLocalizations l, HidePage page) => switch (page) {
      HidePage.home => l.hideAmountsPageHome,
      HidePage.asset => l.hideAmountsPageAsset,
      HidePage.ledger => l.hideAmountsPageLedger,
      HidePage.stats => l.hideAmountsPageStats,
      HidePage.budget => l.hideAmountsPageBudget,
      HidePage.stocks => l.hideAmountsPageStocks,
      HidePage.dutchpay => l.hideAmountsPageDutchpay,
      HidePage.etc => l.hideAmountsPageEtc,
    };

String _cardLabel(AppLocalizations l, String card) => switch (card) {
      'home.netWorth' => l.hideCardHomeNetWorth,
      'home.monthExpense' => l.hideCardHomeMonthExpense,
      'home.categoryDonut' => l.hideCardHomeCategoryDonut,
      'home.budget' => l.hideCardHomeBudget,
      'home.todaySpend' => l.hideCardHomeTodaySpend,
      'home.upcoming' => l.hideCardHomeUpcoming,
      'asset.netWorth' => l.hideCardAssetNetWorth,
      'asset.composition' => l.hideCardAssetComposition,
      'asset.accounts' => l.hideCardAssetAccounts,
      'asset.investments' => l.hideCardAssetInvestments,
      'asset.cards' => l.hideCardAssetCards,
      'asset.loans' => l.hideCardAssetLoans,
      'asset.savingGoals' => l.hideCardAssetSavingGoals,
      'asset.upcoming' => l.hideCardAssetUpcoming,
      'asset.detail' => l.hideCardAssetDetail,
      'asset.manage' => l.hideCardAssetManage,
      'ledger.monthSummary' => l.hideCardLedgerMonthSummary,
      'ledger.calendar' => l.hideCardLedgerCalendar,
      'ledger.txList' => l.hideCardLedgerTxList,
      'ledger.txDetail' => l.hideCardLedgerTxDetail,
      'stats.category' => l.hideCardStatsCategory,
      'stats.trend' => l.hideCardStatsTrend,
      'stats.compare' => l.hideCardStatsCompare,
      'budget.header' => l.hideCardBudgetHeader,
      'budget.pace' => l.hideCardBudgetPace,
      'budget.status' => l.hideCardBudgetStatus,
      'budget.categories' => l.hideCardBudgetCategories,
      'budget.compliance' => l.hideCardBudgetCompliance,
      'budget.manage' => l.hideCardBudgetManage,
      'stocks.summary' => l.hideCardStocksSummary,
      'stocks.holdings' => l.hideCardStocksHoldings,
      'stocks.detail' => l.hideCardStocksDetail,
      'dutchpay.summary' => l.hideCardDutchpaySummary,
      'dutchpay.sessions' => l.hideCardDutchpaySessions,
      'etc.search' => l.hideCardEtcSearch,
      'etc.recurring' => l.hideCardEtcRecurring,
      'etc.preset' => l.hideCardEtcPreset,
      _ => card,
    };
