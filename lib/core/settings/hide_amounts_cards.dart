/// 금액 숨기기 대상 목록 — 화면(페이지) → 카드 2단계.
///
/// 예전엔 bool 하나로 앱 전체 금액을 한꺼번에 가렸다. 자산은 가리고 싶어도 가계부는
/// 보고 싶은 경우가 있어서 카드 단위로 쪼갰다.
///
/// **웹(`hide-amounts-cards.ts`)과 키 문자열이 같아야 한다** — 다르면 같은 카드를 두
/// 클라이언트가 다르게 부르게 되고, 나중에 서버 동기화를 붙일 때 어긋난다.
library;

/// `kind` 는 화면이 아니라 **거래 종류** 축이다. 나머지가 "어느 화면의 금액인가" 를
/// 가른다면 이쪽은 "어떤 종류의 거래인가" 를 가른다 — 화면을 가로지른다.
/// 설정 화면에서도 화면 탭 줄에 끼우지 않고 맨 위 별도 영역으로 뺀다.
enum HidePage { kind, home, asset, ledger, stats, budget, stocks, dutchpay, etc }

/// 카드 키 → 속한 화면. 선언 순서가 곧 설정 화면의 나열 순서다.
const Map<String, HidePage> kHideCards = {
  // 거래 종류 (화면 아님)
  'kind.expense': HidePage.kind,
  'kind.income': HidePage.kind,
  'kind.transfer': HidePage.kind,
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

/// 화면 카드만 — 종류 축을 뺀 나머지. 설정 화면의 탭·'모두 선택'·개수가 이걸 센다.
List<String> get kScreenHideCards =>
    kHideCards.entries.where((e) => e.value != HidePage.kind).map((e) => e.key).toList();

/// 이 금액이 어떤 거래의 것인가.
///
/// [net] 은 수입−지출을 그대로 화면에 찍는 값(가계부 월 요약 '합계', 홈 잔액,
/// 차트 저축)이다. 카드가 아니라 파생 규칙이라 설정에는 안 뜨고, **수입·지출 중
/// 하나라도 가려지면** 함께 가린다 — `수입 = 합계 + 지출` 은 항등식이라 둘이 보이면
/// 나머지가 뺄셈 한 번에 드러난다.
///
/// 하루평균(`지출/일수`)·전월대비%(`(지난달지출−이번달지출)/지난달지출`)는 수입이
/// 안 들어가는 **지출 파생**이라 net 이 아니라 [expense] 다.
enum MaskKind { expense, income, transfer, net }

/// 그 종류를 가리는 카드들. 하나라도 켜져 있으면 가린다.
List<String> cardsOfKind(MaskKind kind) => switch (kind) {
      MaskKind.expense => const ['kind.expense'],
      MaskKind.income => const ['kind.income'],
      MaskKind.transfer => const ['kind.transfer'],
      MaskKind.net => const ['kind.expense', 'kind.income'],
    };

/// 거래 한 건의 종류 — 부호가 아니라 타입으로 가른다.
/// 환불은 음수 지출이라 부호로 가르면 수입으로 샌다.
MaskKind kindOfExpense(String? expenseType) =>
    expenseType == 'INCOME' ? MaskKind.income : MaskKind.expense;
