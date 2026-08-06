import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';

/// 금액 가리기 — 표시 설정 '개인정보 보호' 안의 아코디언 (design `hide-amounts.jsx` 미러).
///
/// 별도 화면이 아니라 그 자리에서 펼쳐진다. 설정을 한 단계 더 들어가지 않아도 되고,
/// 접힌 상태에서도 몇 장을 가렸는지 헤더 카운트로 보인다.
///
/// 가리는 건 자유롭게, **푸는 건 비밀번호**를 받는다. 전체·화면 스위치로 풀면 그 묶음을
/// 한 번의 인증으로 처리한다 — 카드마다 비밀번호를 치게 하면 못 쓴다.
class HideAmountsAccordion extends ConsumerStatefulWidget {
  const HideAmountsAccordion({super.key, this.initiallyOpen = false});

  /// 화면의 눈 버튼으로 들어오면 펼친 채로 연다 — 접힌 아코디언만 보이면 헛걸음이 된다.
  final bool initiallyOpen;

  @override
  ConsumerState<HideAmountsAccordion> createState() =>
      _HideAmountsAccordionState();
}

class _HideAmountsAccordionState extends ConsumerState<HideAmountsAccordion> {
  late bool _open = widget.initiallyOpen;

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
        // ── 아코디언 트리거
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: PSpace.x4, vertical: PSpace.x12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: t.bgMuted, borderRadius: PRadius.brMd),
                  alignment: Alignment.center,
                  child: Icon(
                    hidden.isEmpty ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 17,
                    color: t.fgSecondary,
                  ),
                ),
                const SizedBox(width: PSpace.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.hideAmountsTitle,
                          style: PTypo.body.copyWith(
                              color: t.fgPrimary,
                              fontWeight: PFontWeight.semi)),
                      const SizedBox(height: 2),
                      Text(l.hideAmountsHeaderDesc,
                          style:
                              PTypo.caption.copyWith(color: t.fgTertiary)),
                    ],
                  ),
                ),
                Text(
                  '${hidden.length} / $total',
                  style: PTypo.caption.copyWith(
                    color: hidden.isEmpty ? t.fgTertiary : t.fgBrand,
                    fontWeight: PFontWeight.semi,
                  ),
                ),
                const SizedBox(width: PSpace.x4),
                AnimatedRotation(
                  turns: _open ? -0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(LucideIcons.chevronDown,
                      size: 17, color: t.fgTertiary),
                ),
              ],
            ),
          ),
        ),

        if (_open) ...[
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
                          style:
                              PTypo.caption.copyWith(color: t.fgTertiary)),
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
