/// 금액 숨기기 대상 목록 — 화면(페이지) → 카드 2단계.
///
/// 예전엔 bool 하나로 앱 전체 금액을 한꺼번에 가렸다. 자산은 가리고 싶어도 가계부는
/// 보고 싶은 경우가 있어서 카드 단위로 쪼갰다.
///
/// **웹(`hide-amounts-cards.ts`)과 키 문자열이 같아야 한다** — 다르면 같은 카드를 두
/// 클라이언트가 다르게 부르게 되고, 나중에 서버 동기화를 붙일 때 어긋난다.
library;

enum HidePage { home, asset, ledger, stats, budget, stocks, dutchpay, etc }

/// 카드 키 → 속한 화면. 선언 순서가 곧 설정 화면의 나열 순서다.
const Map<String, HidePage> kHideCards = {
  // 홈
  'home.netWorth': HidePage.home,
  'home.monthExpense': HidePage.home,
  'home.categoryDonut': HidePage.home,
  'home.budget': HidePage.home,
  'home.todaySpend': HidePage.home,
  'home.upcoming': HidePage.home,
  // 자산
  'asset.netWorth': HidePage.asset,
  'asset.composition': HidePage.asset,
  'asset.accounts': HidePage.asset,
  'asset.investments': HidePage.asset,
  'asset.cards': HidePage.asset,
  'asset.loans': HidePage.asset,
  'asset.savingGoals': HidePage.asset,
  'asset.upcoming': HidePage.asset,
  'asset.detail': HidePage.asset,
  'asset.manage': HidePage.asset,
  // 가계부
  'ledger.monthSummary': HidePage.ledger,
  'ledger.calendar': HidePage.ledger,
  'ledger.txList': HidePage.ledger,
  'ledger.txDetail': HidePage.ledger,
  // 통계
  'stats.category': HidePage.stats,
  'stats.trend': HidePage.stats,
  'stats.compare': HidePage.stats,
  // 예산
  'budget.header': HidePage.budget,
  'budget.pace': HidePage.budget,
  'budget.status': HidePage.budget,
  'budget.categories': HidePage.budget,
  'budget.compliance': HidePage.budget,
  'budget.manage': HidePage.budget,
  // 증권
  'stocks.summary': HidePage.stocks,
  'stocks.holdings': HidePage.stocks,
  'stocks.detail': HidePage.stocks,
  // 더치페이
  'dutchpay.summary': HidePage.dutchpay,
  'dutchpay.sessions': HidePage.dutchpay,
  // 기타
  'etc.search': HidePage.etc,
  'etc.recurring': HidePage.etc,
  'etc.preset': HidePage.etc,
};

List<String> get kAllHideCards => kHideCards.keys.toList(growable: false);

List<String> cardsOfPage(HidePage page) =>
    kHideCards.entries.where((e) => e.value == page).map((e) => e.key).toList();
