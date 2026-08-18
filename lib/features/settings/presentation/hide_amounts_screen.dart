import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:porest_desk_app/app/theme/motion.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_cards.dart';
import 'package:porest_desk_app/core/settings/hide_amounts_unlock_dialog.dart';
import 'package:porest_desk_app/core/settings/settings_notifier.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_chip.dart';
import 'package:porest_desk_app/shared/widgets/p_modal.dart';
import 'package:porest_desk_app/shared/widgets/p_snack_bar.dart';
import 'package:porest_desk_app/shared/widgets/p_tabs.dart';

/// 금액 가리기 화면 — 계정 > 보안 > 금액 가리기.
///
/// 카드를 하나 만질 때마다 저장·인증하지 않는다. 화면에서 고르는 동안에는 아무 일도
/// 일어나지 않고, [저장] 을 눌러야 한 번에 반영된다. 예전엔 스위치를 누를 때마다
/// 풀기 인증이 떠서 여러 장을 조정하려면 그만큼 인증을 반복해야 했다.
///
/// 인증은 **푸는 카드가 하나라도 있을 때만** 받는다. 가리기만 늘리는 저장은 그대로 통과.
class HideAmountsScreen extends ConsumerStatefulWidget {
  const HideAmountsScreen({super.key});

  @override
  ConsumerState<HideAmountsScreen> createState() => _HideAmountsScreenState();
}

/// 탭 값 — `null` 은 '전체'(모든 카드를 한 판에).
typedef _Tab = HidePage?;

class _HideAmountsScreenState extends ConsumerState<HideAmountsScreen> {
  /// 화면에서 고르는 중인 선택 — 저장 전까지 설정에 반영되지 않는다.
  Set<String>? _draft;
  _Tab _tab;
  bool _saving = false;

  /// 좌우로 넘기면 탭이 따라 움직인다. 탭을 눌러도 같은 컨트롤러로 페이지를 옮긴다.
  final _pages = PageController();

  _HideAmountsScreenState() : _tab = null;

  /// 탭 순서 — 0 은 '전체', 그 뒤로 화면별.
  static const _tabs = <_Tab>[null, ...HidePage.values];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTab(_Tab tab) {
    setState(() => _tab = tab);
    _pages.animateToPage(
      _tabs.indexOf(tab),
      duration: PMotion.base,
      curve: PMotion.standard,
    );
  }

  /// 저장된 값으로 초기화(최초 1회). 설정 로드가 끝난 뒤에 잡아야 빈 집합으로 시작하지 않는다.
  Set<String> _draftOf(Set<String> saved) => _draft ??= {...saved};

  bool _dirty(Set<String> saved) {
    final d = _draft;
    return d != null && !_setEquals(d, saved);
  }

  static bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  List<String> _cardsOf(_Tab tab) =>
      tab == null ? kAllHideCards : cardsOfPage(tab);

  Future<void> _save(Set<String> saved) async {
    final draft = _draft;
    if (draft == null || _saving) return;
    final l = AppLocalizations.of(context);
    // 푸는 게 하나라도 있으면 본인 확인 — 가리기만 늘리는 저장은 그냥 통과한다.
    final revealing = saved.difference(draft).isNotEmpty;
    setState(() => _saving = true);
    try {
      if (revealing) {
        final ok = await confirmHideAmountsUnlock(context, ref);
        if (!ok) return;
      }
      await ref.read(settingsProvider.notifier).setHideCards(draft);
      if (!mounted) return;
      showPSnackBar(context, l.hideAmountsSaved);
      context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 저장하지 않고 나가려 할 때 — 고른 내용이 날아가는 걸 알리고, 확인하면 화면을 닫는다.
  Future<void> _confirmDiscardAndPop() async {
    final l = AppLocalizations.of(context);
    final router = GoRouter.of(context);
    final ok = await showPConfirmDialog(
      context,
      title: l.hideAmountsDiscardTitle,
      message: l.hideAmountsDiscardBody,
      confirmLabel: l.hideAmountsDiscardConfirm,
      destructive: true,
    );
    if (ok && mounted) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final saved =
        ref.watch(settingsProvider).value?.hideCards ?? const <String>{};
    final draft = _draftOf(saved);
    final tabCards = _cardsOf(_tab);
    final allOnThisTab = tabCards.every(draft.contains);
    final dirty = _dirty(saved);

    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !mounted) return;
        _confirmDiscardAndPop();
      },
      child: Scaffold(
        backgroundColor: t.bgSurface,
        appBar: AppBar(
          leadingWidth: PBackButton.leadingWidth,
          titleSpacing: 0,
          leading: PBackButton(onPressed: () => Navigator.maybePop(context)),
          title: Text(l.hideAmountsTitle),
          backgroundColor: t.bgSurface,
          foregroundColor: t.fgPrimary,
          elevation: 0,
          actions: [
            // 37장을 하나씩 누르게 두지 않는다 — 지금 탭 기준으로 한 번에 켜고 끈다.
            PButton(
              label: allOnThisTab ? l.hideAmountsClearAll : l.hideAmountsSelectAll,
              variant: PButtonVariant.ghost,
              size: PButtonSize.sm,
              onPressed: () => setState(() {
                if (allOnThisTab) {
                  draft.removeAll(tabCards);
                } else {
                  draft.addAll(tabCards);
                }
              }),
            ),
            const SizedBox(width: PSpace.x8),
          ],
        ),
        body: Column(
          children: [
            // 탭 — 전체 + 화면별. 개수는 지금 고른 상태를 그대로 비춘다.
            //
            // pill 채움으로 둔다. underline 은 활성 탭 밑줄과 탭바 아래 경계선이
            // 나란히 겹쳐 선이 두 줄로 보였다(통계 화면도 같은 이유로 pill 이다).
            Padding(
              padding: const EdgeInsets.symmetric(vertical: PSpace.x12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: PSpace.x20),
                child: PTabs<_Tab>(
                  value: _tab,
                  variant: PTabsVariant.pills,
                  size: PTabsSize.sm,
                  items: [
                    _tabItem(l, null, draft),
                    for (final page in HidePage.values)
                      _tabItem(l, page, draft),
                  ],
                  onChanged: _goTab,
                ),
              ),
            ),
            // 탭 전환은 어느 쪽으로든 — 탭을 눌러도, 좌우로 넘겨도 같은 자리로 간다.
            // 안내 문구는 탭마다 같으므로 페이지 밖에 고정한다.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  PSpace.x20, PSpace.x4, PSpace.x20, PSpace.x16),
              child: Text(l.hideAmountsSectionDesc,
                  style:
                      PTypo.caption.copyWith(color: t.fgTertiary, height: 1.55)),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _tabs.length,
                onPageChanged: (i) => setState(() => _tab = _tabs[i]),
                itemBuilder: (_, i) => _CardGrid(
                  cards: _cardsOf(_tabs[i]),
                  draft: draft,
                  onToggle: (card) => setState(() {
                    if (!draft.remove(card)) draft.add(card);
                  }),
                ),
              ),
            ),
            // 저장 — 화면 아래 고정. 고르는 동안에는 아무것도 반영되지 않으므로
            // 여기까지 와야 끝난다.
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    PSpace.x20, PSpace.x12, PSpace.x20, PSpace.x12),
                child: PButton(
                  label: l.actionSave,
                  size: PButtonSize.lg,
                  fullWidth: true,
                  loading: _saving,
                  onPressed: dirty && !_saving ? () => _save(saved) : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PTabItem<_Tab> _tabItem(AppLocalizations l, _Tab tab, Set<String> draft) {
    final cards = _cardsOf(tab);
    final on = cards.where(draft.contains).length;
    // 라벨에 개수를 붙인다 — tabs spec 에 badge 가 없어 별도 스타일을 만들지 않는다.
    final name = tab == null ? l.hideAmountsTabAll : _pageLabel(l, tab);
    return PTabItem(value: tab, label: on == 0 ? name : '$name $on');
  }
}

/// 한 탭의 카드 2열 그리드. 페이지마다 따로 스크롤한다.
class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.cards,
    required this.draft,
    required this.onToggle,
  });

  final List<String> cards;
  final Set<String> draft;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // 2열 — 라벨이 길어 3열은 말줄임이 잦다.
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.fromLTRB(
          PSpace.x20, 0, PSpace.x20, PSpace.x24),
      mainAxisSpacing: PSpace.x8,
      crossAxisSpacing: PSpace.x8,
      childAspectRatio: 3.2,
      children: [
        for (final card in cards)
          PChip(
            label: _cardLabel(l, card),
            selected: draft.contains(card),
            shape: PChipShape.rounded,
            fullWidth: true,
            onTap: () => onToggle(card),
          ),
      ],
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
