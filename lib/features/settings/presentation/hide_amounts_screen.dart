import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_section_label.dart';
import 'package:porest_desk_app/shared/widgets/p_switch.dart';

/// 금액 가리기 — 화면(페이지) → 카드 단위로 고르는 설정. 웹 `HideAmountsSection.tsx` 미러.
///
/// 예전엔 스위치 하나가 앱 전체 금액을 덮었다. 자산은 가리고 싶어도 가계부는 봐야 하는
/// 경우가 있어서 카드마다 따로 켜고 끈다.
///
/// 가리는 건 자유롭게, **푸는 건 비밀번호**를 받는다. 페이지·전체 스위치로 풀면 그 묶음을
/// 한 번의 인증으로 처리한다 — 카드마다 비밀번호를 치게 하면 못 쓴다.
class HideAmountsScreen extends ConsumerWidget {
  const HideAmountsScreen({super.key, this.focusPage});

  /// 화면의 눈 버튼으로 들어오면 그 묶음을 짚어 준다 — 34장 앞에서 자기 카드를 다시 찾지 않게.
  final String? focusPage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider).value;
    final hidden = settings?.hideCards ?? const <String>{};

    Future<void> apply(Iterable<String> cards, bool hide) =>
        setHideCardsWithUnlock(context, ref, cards: cards, hide: hide);

    return Scaffold(
      backgroundColor: t.bgSurface,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        leading: PBackButton(onPressed: () => context.pop()),
        title: Text(l.hideAmountsTitle),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: PSpace.x20, vertical: PSpace.x24),
        children: [
          Text(l.hideAmountsSectionDesc,
              style: PTypo.caption.copyWith(color: t.fgTertiary)),
          const SizedBox(height: PSpace.x20),
          _ToggleRow(
            icon: hidden.isEmpty ? LucideIcons.eye : LucideIcons.eyeOff,
            title: l.hideAmountsLockAll,
            desc: l.hideAmountsLockAllDesc(kAllHideCards.length, hidden.length),
            value: hidden.length == kAllHideCards.length,
            onChanged: (v) => apply(kAllHideCards, v),
          ),
          for (final page in HidePage.values) ...[
            const SizedBox(height: PSpace.x24),
            _PageBlock(
              page: page,
              hidden: hidden,
              focused: focusPage == page.name,
              onApply: apply,
            ),
          ],
        ],
      ),
    );
  }
}

class _PageBlock extends StatelessWidget {
  const _PageBlock({
    required this.page,
    required this.hidden,
    required this.focused,
    required this.onApply,
  });

  final HidePage page;
  final Set<String> hidden;
  final bool focused;
  final Future<void> Function(Iterable<String>, bool) onApply;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final cards = cardsOfPage(page);
    final on = cards.where(hidden.contains).length;

    return Container(
      decoration: focused
          // 눈 버튼으로 들어온 묶음만 테두리로 짚어 준다.
          ? BoxDecoration(
              border: Border.all(color: t.borderBrand),
              borderRadius: PRadius.brLg,
            )
          : null,
      padding: focused ? const EdgeInsets.all(PSpace.x12) : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PSectionLabel(_pageLabel(l, page),
              variant: PSectionLabelVariant.section),
          _ToggleRow(
            title: _pageLabel(l, page),
            desc: '$on / ${cards.length}',
            value: on == cards.length,
            onChanged: (v) => onApply(cards, v),
          ),
          Padding(
            padding: const EdgeInsets.only(left: PSpace.x12),
            child: Column(
              children: [
                for (final card in cards)
                  _ToggleRow(
                    compact: true,
                    title: _cardLabel(l, card),
                    value: hidden.contains(card),
                    onChanged: (v) => onApply([card], v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.desc,
    this.icon,
    this.compact = false,
  });

  final String title;
  final String? desc;
  final IconData? icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: 10, vertical: compact ? PSpace.x4 : PSpace.x8),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: t.bgMuted, borderRadius: PRadius.brMd),
              alignment: Alignment.center,
              child: Icon(icon, size: 17, color: t.fgSecondary),
            ),
            const SizedBox(width: PSpace.x12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: (compact ? PTypo.body : PTypo.bodySm).copyWith(
                    color: compact ? t.fgSecondary : t.fgPrimary,
                    fontWeight:
                        compact ? PFontWeight.medium : PFontWeight.semi,
                  ),
                ),
                if (desc != null) ...[
                  const SizedBox(height: 2),
                  Text(desc!,
                      style: PTypo.caption.copyWith(color: t.fgTertiary)),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 24,
            child: PSwitch(value: value, onChanged: onChanged),
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
