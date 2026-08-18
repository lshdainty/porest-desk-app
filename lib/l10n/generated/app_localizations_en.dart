// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'POREST Desk';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionLoading => 'Loading...';

  @override
  String get actionDone => 'Done';

  @override
  String get actionBack => 'Back';

  @override
  String get actionEditLabel => 'Edit';

  @override
  String get pickDate => 'Select date';

  @override
  String get pickTime => 'Select time';

  @override
  String get searchResultsEmpty => 'No results';

  @override
  String get unlockTitle => 'Verify to view amounts';

  @override
  String get unlockBody => 'Enter your password to view amounts again.';

  @override
  String get unlockBiometricReason => 'Verify it\'s you to view amounts again.';

  @override
  String get unlockPasswordLabel => 'Password';

  @override
  String get unlockPasswordHint => 'Enter password';

  @override
  String get unlockMismatch => 'Password doesn\'t match.';

  @override
  String get appLockTitle => 'App Lock';

  @override
  String get appLockRowDesc =>
      'Verify with Face ID or fingerprint when opening the app.';

  @override
  String get appLockLockedDesc => 'Verify it\'s you to unlock.';

  @override
  String get appLockUnlockAction => 'Unlock';

  @override
  String get appLockPromptReason => 'Verify it\'s you to open the app.';

  @override
  String get appLockUnavailable =>
      'Biometrics or screen lock isn\'t available on this device.';

  @override
  String get stateNoData => 'No data';

  @override
  String get stateError => 'Something went wrong';

  @override
  String get stateEmpty => 'Nothing to show';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTodo => 'Todo';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navMemo => 'Memo';

  @override
  String get navTimer => 'Timer';

  @override
  String get navExpense => 'Expense';

  @override
  String get navAsset => 'Assets';

  @override
  String get navDutchPay => 'Dutch Pay';

  @override
  String get navPostit => 'Post-it';

  @override
  String get navGroup => 'Groups';

  @override
  String get navSettings => 'Settings';

  @override
  String get navMore => 'More';

  @override
  String get navMenu => 'Menu';

  @override
  String get navHome => 'Home';

  @override
  String get navStats => 'Stats';

  @override
  String get navSearch => 'Search';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get navBudget => 'Budget';

  @override
  String get navRecurring => 'Recurring';

  @override
  String get navCategories => 'Categories';

  @override
  String get navPresets => 'Presets';

  @override
  String get navCards => 'Cards';

  @override
  String get navSavingGoals => 'Saving Goals';

  @override
  String get navExport => 'Export';

  @override
  String get navLogout => 'Log out';

  @override
  String get navChangePassword => 'Change Password';

  @override
  String get notiTitle => 'Notifications';

  @override
  String get notiEmpty => 'No notifications';

  @override
  String get notiMarkAllRead => 'Mark all read';

  @override
  String get notiTypeEventReminder => 'Event Reminder';

  @override
  String get notiTypeBudgetAlert => 'Budget Alert';

  @override
  String get notiTypeTodoReminder => 'Todo Reminder';

  @override
  String get notiTypeSystem => 'System';

  @override
  String get notiConnectionLost => 'Notification connection lost';

  @override
  String get notiConnectionRestored => 'Notification connection restored';

  @override
  String get notiNew => 'New notification';

  @override
  String get assetTitle => 'Assets';

  @override
  String get assetSummaryTotalBalance => 'Total Balance';

  @override
  String get assetEmpty => 'No assets registered';

  @override
  String get assetCreateFirst => 'Register your first asset';

  @override
  String get assetAdd => 'Add Asset';

  @override
  String get assetEdit => 'Edit Asset';

  @override
  String get assetTransferAdd => 'Add Transfer';

  @override
  String get assetTransferEmpty => 'No transfers yet';

  @override
  String get assetFee => 'Fee';

  @override
  String get assetTypeBankAccount => 'Bank Account';

  @override
  String get assetTypeSavings => 'Savings';

  @override
  String get assetTypeCash => 'Cash';

  @override
  String get assetTypeCreditCard => 'Credit Card';

  @override
  String get assetTypeCheckCard => 'Check Card';

  @override
  String get assetTypeInvestment => 'Investment';

  @override
  String get assetTypeLoan => 'Loan';

  @override
  String get assetGroupAccount => 'Accounts';

  @override
  String get assetGroupCard => 'Cards';

  @override
  String get assetGroupInvestment => 'Investments';

  @override
  String get assetGroupDebt => 'Loans';

  @override
  String get assetCatAccount => 'Account';

  @override
  String get assetSubtypeInstallment => 'Installment';

  @override
  String get assetSubtypeDeposit => 'Deposit';

  @override
  String get assetLoadError => 'Couldn\'t load assets';

  @override
  String get assetEmptyState => 'No assets yet';

  @override
  String get assetEmptyHint =>
      'You can add one from Settings → Manage cards & accounts';

  @override
  String get assetSummaryColAccounts => 'Accounts';

  @override
  String get assetSummaryColCards => 'Card debt';

  @override
  String get assetTotalNetWorth => 'Total net worth';

  @override
  String get assetVsLastMonth => 'vs last month';

  @override
  String get assetGroupEmpty => 'No items yet';

  @override
  String assetPaymentDayInfo(int day) {
    return 'Pays on day $day';
  }

  @override
  String get assetExcludedFromTotal => 'Excluded from total';

  @override
  String get assetManageTitle => 'Manage accounts & cards';

  @override
  String assetTabAccountsSavings(int count) {
    return 'Accounts $count';
  }

  @override
  String assetTabCards(int count) {
    return 'Cards $count';
  }

  @override
  String assetTabInvest(int count) {
    return 'Investments $count';
  }

  @override
  String get assetTotalPrefix => 'Total';

  @override
  String assetAddCategory(String name) {
    return 'Add $name';
  }

  @override
  String assetCategoryEmpty(String name) {
    return 'No $name registered yet';
  }

  @override
  String get assetIncludeInTotal => 'Include in total assets';

  @override
  String get assetIncludeInTotalDesc =>
      'Counts toward net worth and total assets';

  @override
  String get assetTrendLoadError => 'Couldn\'t load trend data';

  @override
  String get assetTrendEmpty => 'No trend data';

  @override
  String get assetNetWorth => 'Net worth';

  @override
  String get assetAccountAdd => 'Add account';

  @override
  String get assetAccountEdit => 'Edit account';

  @override
  String get assetAccountAdded => 'Account added';

  @override
  String get assetAccountUpdated => 'Account updated';

  @override
  String get assetAccountDeleted => 'Account deleted';

  @override
  String get assetAccountDelete => 'Delete account';

  @override
  String get assetAccountDeleteConfirm =>
      'Delete this account? Linked transactions are kept.';

  @override
  String get assetActionFailed => 'Failed';

  @override
  String get assetDeleteFailed => 'Delete failed';

  @override
  String get assetInstitutionBrand => 'Institution / brand';

  @override
  String assetTotalEntries(int count) {
    return 'Total $count';
  }

  @override
  String get assetBankSearchHint => 'Search bank or brokerage';

  @override
  String get assetNickname => 'Nickname';

  @override
  String get assetNicknamePlaceholder => 'e.g. Shinhan main';

  @override
  String get assetAccountType => 'Account type';

  @override
  String get assetAccountNumber => 'Account number';

  @override
  String get assetBalanceLabel => 'Balance (KRW)';

  @override
  String get assetCurrency => 'Currency';

  @override
  String get assetExchangeRate => 'Exchange rate';

  @override
  String assetExchangeRateHint(String code) {
    return 'KRW per 1 $code';
  }

  @override
  String get assetExchangeRateDesc =>
      'Net worth converts balance × rate. Left empty it is added without conversion.';

  @override
  String get assetMemoOptional => 'Memo (optional)';

  @override
  String get assetMemoPlaceholder =>
      'Note last digits, payment day, limit, etc.';

  @override
  String get assetCreditLimitLabel => 'Credit limit (KRW, optional)';

  @override
  String get assetCreditLimitPlaceholder => 'e.g. 5,000,000';

  @override
  String get assetCreditLimitHint => 'Enter a limit to show the usage gauge.';

  @override
  String get assetPaymentDayLabel => 'Payment day (optional)';

  @override
  String get assetPaymentDaySelect => 'Select payment day';

  @override
  String get assetPaymentDay => 'Payment day';

  @override
  String get assetLinkedAccount => 'Linked account';

  @override
  String get assetLinkedAccountLabel => 'Linked account';

  @override
  String get assetLinkedAccountSelect => 'Select linked account';

  @override
  String get assetLinkedAccountHint =>
      'Spending on this card is deducted from this account right away.';

  @override
  String get assetPaymentAccountLabel => 'Payment account (optional)';

  @override
  String get assetNoBankAccounts => 'No checking accounts yet';

  @override
  String get assetPaymentAccountSelect => 'Select payment account';

  @override
  String get assetPaymentAccount => 'Payment account';

  @override
  String get assetPaymentAccountHint =>
      'The billed amount is withdrawn from this account on the payment day.';

  @override
  String get assetNewAccount => 'New account';

  @override
  String get assetPreview => 'Preview';

  @override
  String get assetNoSearchResults => 'No search results';

  @override
  String get assetCardAdd => 'Add card';

  @override
  String get assetCardAdded => 'Card added';

  @override
  String get assetCardEdit => 'Edit card';

  @override
  String get assetCardUpdated => 'Card updated';

  @override
  String get assetCardDelete => 'Delete card';

  @override
  String get assetCardDeleteConfirm =>
      'Delete this card? Linked transactions are kept.';

  @override
  String get assetCardDeleted => 'Card deleted';

  @override
  String get assetCardType => 'Card type';

  @override
  String get assetCardProduct => 'Card product';

  @override
  String get assetIncludeDiscontinued => 'Include discontinued';

  @override
  String assetTotalItems(int count) {
    return 'Total $count';
  }

  @override
  String get assetTotalLoading => 'Total …';

  @override
  String get assetCardSearchHint => 'Search card or issuer';

  @override
  String get assetNicknameOptional => 'Nickname (optional)';

  @override
  String get assetCardNicknamePlaceholder => 'e.g. Shinhan Deep Dream';

  @override
  String get assetCurrentUsage => 'Current usage (KRW)';

  @override
  String get assetCurrentUsageHint =>
      'Enter the amount to be billed. It counts toward total debt.';

  @override
  String get assetNewCard => 'New card';

  @override
  String get assetCatalogLoadError => 'Failed to load catalog';

  @override
  String get assetAnnualFee => 'Annual fee';

  @override
  String get assetCardShortCredit => 'Credit';

  @override
  String get assetCardShortCheck => 'Check';

  @override
  String get assetDiscontinued => 'Discontinued';

  @override
  String get assetInvestAdd => 'Add investment';

  @override
  String get assetInvestEdit => 'Edit investment';

  @override
  String get assetInvestAdded => 'Investment added';

  @override
  String get assetInvestUpdated => 'Investment updated';

  @override
  String get assetInvestDeleted => 'Investment deleted';

  @override
  String get assetInvestDelete => 'Delete investment';

  @override
  String get assetInvestDeleteConfirm =>
      'Delete this investment? Linked transactions are kept.';

  @override
  String get assetBrokerExchange => 'Brokerage / exchange';

  @override
  String get assetInvestSearchHint =>
      'Search brokerages, crypto & commodity exchanges';

  @override
  String get assetProductName => 'Alias';

  @override
  String get assetProductPlaceholder => 'e.g. Pension savings, Gold holdings';

  @override
  String get assetValuation => 'Valuation (KRW)';

  @override
  String get assetNewInvestment => 'New investment';

  @override
  String get assetCryptoExchange => 'Crypto exchange';

  @override
  String get assetCategoryCommercialBank => 'Commercial bank';

  @override
  String get assetCategoryInternetBank => 'Internet bank';

  @override
  String get assetCategoryLocalBank => 'Local bank';

  @override
  String get assetCategorySpecialBank => 'Special bank';

  @override
  String get assetCategorySavingsInstitution => 'Savings institution';

  @override
  String get assetCategoryForeignBank => 'Foreign bank';

  @override
  String get assetCategoryOther => 'Other';

  @override
  String get assetCategoryBrokerage => 'Brokerage';

  @override
  String get assetCategoryCommodityExchange => 'Commodity exchange';

  @override
  String get assetCategoryCryptoExchange => 'Crypto exchange';

  @override
  String get assetCardDetail => 'Card details';

  @override
  String get assetInvestDetail => 'Investment details';

  @override
  String get assetAccountDetail => 'Account details';

  @override
  String get assetShowAmount => 'Show amount';

  @override
  String get assetHideAmount => 'Hide amount';

  @override
  String get assetPeriod3m => '3 months';

  @override
  String get assetPeriod6m => '6 months';

  @override
  String get assetPeriod1y => '1 year';

  @override
  String assetWeeksCount(int weeks) {
    return '$weeks weeks';
  }

  @override
  String get assetTrendKindUsage => 'usage trend';

  @override
  String get assetTrendKindValuation => 'valuation trend';

  @override
  String get assetTrendKindBalance => 'balance trend';

  @override
  String assetTrendRecent(String weeks, String kind) {
    return 'Last $weeks $kind';
  }

  @override
  String get assetValueLabelCard => 'Due this month';

  @override
  String get assetValueLabelCheckCard => 'Spent this month';

  @override
  String get assetCheckCardMonthLabel => 'Used this month';

  @override
  String assetMonthTxCount(int count) {
    return 'This month ($count)';
  }

  @override
  String get assetValuationShort => 'Valuation';

  @override
  String get assetSeriesUsage => 'Usage';

  @override
  String assetRecentTxCount(int count) {
    return 'Recent transactions ($count)';
  }

  @override
  String get assetViewAll => 'View all';

  @override
  String get assetTossLinkStarted => 'Started Toss price sync';

  @override
  String get assetLinkFailed => 'Link failed';

  @override
  String get assetTossUnlinked => 'Unlinked from Toss';

  @override
  String get assetUnlinkFailed => 'Unlink failed';

  @override
  String get assetQtyUpdated => 'Updated quantity';

  @override
  String get assetUpdateFailed => 'Update failed';

  @override
  String get assetTossLinked => 'Toss linked';

  @override
  String get assetHoldings => 'Holdings';

  @override
  String get tradeTitle => 'Buy / Sell';

  @override
  String get tradeBuy => 'Buy';

  @override
  String get tradeSell => 'Sell';

  @override
  String get tradeBought => 'Buy recorded';

  @override
  String get tradeSold => 'Sell recorded';

  @override
  String get tradeHolding => 'Holding';

  @override
  String get tradeHoldingType => 'Holding type';

  @override
  String get tradeNoHolding => 'No holdings yet';

  @override
  String get tradeAddNewHolding => 'Buy a new holding';

  @override
  String get tradePickExisting => 'Pick from holdings';

  @override
  String get tradeNewHoldingPlaceholder => 'Enter a holding name';

  @override
  String get tradeQuantity => 'Quantity';

  @override
  String get tradeAmount => 'Trade amount (KRW)';

  @override
  String get tradeAmountHelp => 'Excluding fees. Enter fees separately below.';

  @override
  String get tradeFee => 'Fees & tax (KRW)';

  @override
  String get tradeMemo => 'Memo';

  @override
  String get tradeMemoPlaceholder => 'Optional';

  @override
  String get tradeSettlement => 'Settlement account';

  @override
  String get tradeSettlementCash => 'Brokerage cash';

  @override
  String get tradeSettlementCashHelp =>
      'Paid from the brokerage cash balance. It may go negative.';

  @override
  String get tradeSettlementAccountHelp =>
      'A transfer covers any shortfall from this account.';

  @override
  String get tradeSettlementDelta => 'Settlement account change';

  @override
  String get tradeCashAfter => 'Cash after trade';

  @override
  String get tradeRealizedPreview => 'Realized P/L';

  @override
  String tradeFundingNotice(String amount) {
    return '$amount moves from the settlement account to cover the shortfall';
  }

  @override
  String get tradeInsufficientCash =>
      'Cash will go negative. It is recorded as is.';

  @override
  String get tradeInsufficientQty => 'Cannot sell more than you hold.';

  @override
  String get tradeHistory => 'Trade history';

  @override
  String get tradeDeleted => 'Trade cancelled';

  @override
  String get tradeDeleteTitle => 'Cancel trade';

  @override
  String get tradeDeleteConfirm =>
      'Cancel this trade? Cash and quantity return to their pre-trade state.';

  @override
  String get holdingTypeStock => 'Stock';

  @override
  String get holdingTypeGold => 'Gold';

  @override
  String get holdingTypeCrypto => 'Crypto';

  @override
  String get holdingAvgPrice => 'Avg price';

  @override
  String holdingAvgPriceInline(String avg) {
    return 'avg $avg';
  }

  @override
  String get holdingTotalCost => 'Cost basis';

  @override
  String tradeHeldSummary(String qty, String avg) {
    return 'Holding $qty · avg $avg';
  }

  @override
  String get assetCashBalance => 'Cash';

  @override
  String get assetCashBalanceHint =>
      'Cash waiting to be invested. Proceeds from selling holdings land here.';

  @override
  String get assetHoldingBalance => 'Holdings';

  @override
  String assetHoldingsSummary(int count, String amount) {
    return '$count holdings · ₩$amount';
  }

  @override
  String assetHoldingRep(String name, int count) {
    return '$name +$count more';
  }

  @override
  String get assetNoHoldings => 'No holdings';

  @override
  String get assetHoldingLinkedBadge => 'Linked';

  @override
  String assetHoldingLinkedSub(String price) {
    return 'Price $price × qty';
  }

  @override
  String get assetHoldingManualSub => 'Manual value';

  @override
  String assetHoldingLinkedDetail(String qty, String price) {
    return '$qty shares · linked at $price';
  }

  @override
  String get assetHoldingManualDetail => 'Manual entry';

  @override
  String get assetHoldingsEmptyEdit =>
      'Search to add holdings. Linked holdings are valued automatically at price × quantity.';

  @override
  String get assetHoldingsEmptyManual =>
      'Add your holdings with the button above. No live price — enter the value yourself.';

  @override
  String get assetHoldingsEmptyDetail => 'No holdings yet. Add them from Edit.';

  @override
  String get assetHoldingSearchHint =>
      'Search name/ticker to add (e.g. Samsung, NVDA)';

  @override
  String assetHoldingAddManual(String name) {
    return 'Add \"$name\" manually — enter value';
  }

  @override
  String get assetSharesUnit => 'sh';

  @override
  String get assetHoldingTypeStock => 'Stocks';

  @override
  String get assetHoldingTypeGold => 'Gold';

  @override
  String get assetHoldingTypeCrypto => 'Crypto';

  @override
  String get assetHoldingAddGold => 'Add gold';

  @override
  String get assetHoldingAddCrypto => 'Add crypto';

  @override
  String get assetHoldingUnitGram => 'g';

  @override
  String get assetHoldingUnitCount => 'units';

  @override
  String get assetHoldingNamePlaceholder => 'Item name';

  @override
  String assetHoldingQtyUnit(String qty, String unit) {
    return '$qty $unit';
  }

  @override
  String assetInvestHoldingsSub(int count) {
    return 'Investment · $count holdings';
  }

  @override
  String assetTodayChange(String amount) {
    return 'Today $amount';
  }

  @override
  String assetSharesCount(String n) {
    return '$n shares';
  }

  @override
  String assetTossValuationFormula(int qty) {
    return 'Valuation updates in real time as Toss price × $qty shares.';
  }

  @override
  String get assetHoldingQty => 'Holdings';

  @override
  String get assetEditQty => 'Edit quantity';

  @override
  String get assetUnlink => 'Unlink';

  @override
  String get assetTossRealtimeTitle => 'Real-time valuation via Toss';

  @override
  String get assetTossRealtimeDesc =>
      'Register a ticker and quantity to reflect valuation live as Toss price × quantity.';

  @override
  String get assetTapToChange => 'Tap to change';

  @override
  String get assetStockSearchHint =>
      'Search ticker or code (e.g. Samsung Elec, 005930)';

  @override
  String get stockSecurityTypeIndex => 'Index';

  @override
  String get stockSecurityTypeWarrant => 'Warrant';

  @override
  String get stockMarketKospi => 'KOSPI';

  @override
  String get stockMarketKosdaq => 'KOSDAQ';

  @override
  String get stockMarketKonex => 'KONEX';

  @override
  String get stockMarketKrxIdx => 'KRX Index';

  @override
  String get stockMarketNas => 'NASDAQ';

  @override
  String get stockMarketNys => 'NYSE';

  @override
  String get stockMarketAms => 'AMEX';

  @override
  String get stockMarketShs => 'Shanghai';

  @override
  String get stockMarketShi => 'SSE Index';

  @override
  String get stockMarketSzs => 'Shenzhen';

  @override
  String get stockMarketSzi => 'SZSE Index';

  @override
  String get stockMarketTse => 'Tokyo';

  @override
  String get stockMarketHks => 'Hong Kong';

  @override
  String get stockMarketHnx => 'Hanoi';

  @override
  String get stockMarketHsx => 'Ho Chi Minh';

  @override
  String assetLinkByCode(String code) {
    return 'Link by code \"$code\"';
  }

  @override
  String get assetLink => 'Link';

  @override
  String get assetChartNoData => 'No data to show';

  @override
  String get assetNoLinkedTx => 'No linked transactions.';

  @override
  String get assetTxFallback => 'Transaction';

  @override
  String assetPayConfirmMessage(String amount) {
    return 'Pay the upcoming amount of $amount KRW now?';
  }

  @override
  String assetPayConfirmDateSuffix(String date) {
    return ' The payment date is $date.';
  }

  @override
  String get assetCancelPayment => 'Cancel payment';

  @override
  String assetCancelPaymentConfirm(String amount, String date) {
    return 'Reverts the $amount KRW paid on $date. The account balance and card billing return to the state before payment.';
  }

  @override
  String get assetPaymentCancelled => 'Payment cancelled';

  @override
  String get assetPayNow => 'Pay now';

  @override
  String get assetPayAction => 'Pay';

  @override
  String get assetPayAmount => 'Payment amount';

  @override
  String assetPayRemainder(String amount) {
    return '$amount remaining will be paid on the payment date';
  }

  @override
  String get assetPaymentRecorded => 'Payment recorded';

  @override
  String get assetPayFailed => 'Payment failed';

  @override
  String get assetBillingLoadError => 'Couldn\'t load billing info';

  @override
  String get assetUpcomingPayment => 'Upcoming payment';

  @override
  String get assetScheduledTag => 'Upcoming';

  @override
  String get assetPaidDone => 'Paid';

  @override
  String assetUsagePeriod(String period) {
    return 'Card usage period $period';
  }

  @override
  String get assetLimitSettings => 'Limit · payment';

  @override
  String get assetLimitUsage => 'Limit usage';

  @override
  String assetLimitPctUsed(int pct) {
    return '$pct% used';
  }

  @override
  String assetLimitOf(String used, String limit) {
    return '$used / Limit $limit';
  }

  @override
  String assetLimitRemain(String amount) {
    return 'Remaining $amount';
  }

  @override
  String get assetLimitEdit => 'Edit limit · payment day';

  @override
  String get assetPerfDone => 'Monthly target met';

  @override
  String assetPerfRemain(String amount) {
    return '$amount to target';
  }

  @override
  String get assetUsageHistory => 'Usage history';

  @override
  String get assetSortRecent => 'Recent';

  @override
  String get assetSortAmount => 'Amount';

  @override
  String get assetSortCategory => 'Category';

  @override
  String get assetPeriodPick => 'Select period';

  @override
  String get assetNoUsage => 'No usage history yet.';

  @override
  String assetBillingPeriod(String start, String end) {
    return 'Usage $start–$end';
  }

  @override
  String assetMonthlyPaymentDay(int day) {
    return 'Paid on day $day each month';
  }

  @override
  String get assetBillingHistory => 'Billing history';

  @override
  String get assetStatusPending => 'Pending';

  @override
  String get assetStatusSkipped => 'Skipped';

  @override
  String get todoTitle => 'Todos';

  @override
  String get todoEmpty => 'No todos';

  @override
  String get todoCreateFirst => 'Create your first todo';

  @override
  String get todoQuickAddHint => '+ Quick add';

  @override
  String get todoStatusAll => 'All';

  @override
  String get todoStatusCompleted => 'Completed';

  @override
  String get todoPriorityAll => 'All';

  @override
  String get todoPriorityHigh => 'High';

  @override
  String get todoPriorityMedium => 'Medium';

  @override
  String get todoPriorityLow => 'Low';

  @override
  String get todoSubtask => 'Subtasks';

  @override
  String get todoSubtaskAddHint => '+ Add subtask';

  @override
  String get todoTagMgmt => 'Tags';

  @override
  String get memoTitle => 'Memos';

  @override
  String get memoEmpty => 'No memos';

  @override
  String get memoSearchEmpty => 'No matching memos';

  @override
  String get memoSearchHint => 'Search memos';

  @override
  String get memoFolderMgmt => 'Folders';

  @override
  String get memoFolderRoot => 'Root';

  @override
  String get memoFolderEmpty => 'No folders';

  @override
  String get memoPin => 'Pin';

  @override
  String get memoUnpin => 'Unpin';

  @override
  String get calTitle => 'Calendar';

  @override
  String get calToday => 'Today';

  @override
  String get calMonthView => 'Month';

  @override
  String get calWeekView => 'Week';

  @override
  String get calDayView => 'Day';

  @override
  String get calYearView => 'Year';

  @override
  String get calAgendaView => 'Agenda';

  @override
  String get calNoEvents => 'No events';

  @override
  String get calEventAdd => 'Add event';

  @override
  String get calEventEdit => 'Edit event';

  @override
  String get calEventDelete => 'Delete event';

  @override
  String get calLabelMgmt => 'Labels';

  @override
  String get calMyCalendars => 'My calendars';

  @override
  String get calAllDay => 'All day';

  @override
  String get calRepeat => 'Repeat';

  @override
  String get calRepeatNone => 'None';

  @override
  String get calRepeatDaily => 'Daily';

  @override
  String get calRepeatWeekly => 'Weekly';

  @override
  String get calRepeatMonthly => 'Monthly';

  @override
  String get calRepeatYearly => 'Yearly';

  @override
  String get calLocation => 'Location';

  @override
  String get calMemo => 'Notes';

  @override
  String get calStartDate => 'Start';

  @override
  String get calEndDate => 'End';

  @override
  String get calFieldTitle => 'Title';

  @override
  String get calFieldDescription => 'Description';

  @override
  String get calFieldCalendar => 'Calendar';

  @override
  String get calFieldLabel => 'Label';

  @override
  String get calFieldColor => 'Color';

  @override
  String get calFieldName => 'Name';

  @override
  String get calFieldReminder => 'Reminders';

  @override
  String get calFieldStartDate => 'Start date';

  @override
  String get calFieldEndDate => 'End date';

  @override
  String get calTitlePlaceholder => 'e.g. Family dinner';

  @override
  String get calDescriptionPlaceholder => 'Additional notes (optional)';

  @override
  String get calLocationPlaceholder => 'Enter a location';

  @override
  String get calSelectCalendar => 'Select calendar';

  @override
  String get calNoLabel => 'No label';

  @override
  String get calLabelNamePlaceholder => 'e.g. Important, Deadline, Meeting';

  @override
  String get calCalendarNamePlaceholder => 'e.g. Family, Work, Workouts';

  @override
  String get calCalendarNameFieldPlaceholder => 'Calendar name';

  @override
  String get calInviteCodePlaceholder => 'e.g. ABC123';

  @override
  String get calRecurrenceNone => 'No repeat';

  @override
  String calReminderMinutesBefore(int n) {
    return '$n min before';
  }

  @override
  String get calReminderHourBefore => '1 hour before';

  @override
  String get calReminderDayBefore => '1 day before';

  @override
  String calEventDeleteConfirm(String title) {
    return 'Delete \"$title\"? This can\'t be undone.';
  }

  @override
  String get calEventAdded => 'Event added';

  @override
  String get calEventUpdated => 'Event updated';

  @override
  String get calLabelsTitle => 'Calendar labels';

  @override
  String calAllLabelsCount(int count) {
    return 'All labels · $count';
  }

  @override
  String get calLabelsEmpty => 'No labels yet';

  @override
  String get calLabelsEmptyHint =>
      'Create one with the \"New label\" button above';

  @override
  String get calLabelsIntro =>
      'These labels are shared across all your calendars. You can pick one when creating an event.';

  @override
  String get calNewLabel => 'New label';

  @override
  String get calEditLabel => 'Edit label';

  @override
  String get calPreview => 'Preview';

  @override
  String get calDeleteLabelTitle => 'Delete label';

  @override
  String calDeleteLabelConfirm(String name) {
    return 'Delete the \"$name\" label? Events using it will become unlabeled.';
  }

  @override
  String get calDatePicker => 'Go to date';

  @override
  String calCalendarChipCount(int count) {
    return '$count';
  }

  @override
  String get calNoCalendars => 'No calendars';

  @override
  String get calOtherSources => 'Other sources';

  @override
  String get calHolidays => 'Holidays';

  @override
  String get calManageShareSettings => 'Manage & share calendars';

  @override
  String get calNoEventsThisDay => 'No events on this day';

  @override
  String calEventTotalCount(int count) {
    return '$count';
  }

  @override
  String get calGoToToday => 'Today';

  @override
  String get calManageShareTitle => 'Manage & share';

  @override
  String get calJoinByCode => 'Join with invite code';

  @override
  String get calRoleOwner => 'Owner';

  @override
  String get calRoleEditor => 'Can edit';

  @override
  String get calRoleViewer => 'View only';

  @override
  String get calShareIntroTitle => 'Share with family & friends';

  @override
  String get calShareIntroBody =>
      'Create a calendar and invite members to manage events together.';

  @override
  String get calNewCalendar => 'New calendar';

  @override
  String calMyCalendarsCount(int count) {
    return 'My calendars · $count';
  }

  @override
  String get calNoOwnedCalendars => 'You don\'t own any calendars yet';

  @override
  String calSharedCalendarsCount(int count) {
    return 'Shared calendars · $count';
  }

  @override
  String get calNoSharedCalendars => 'No shared calendars';

  @override
  String get calDefault => 'Default';

  @override
  String get calOnlyMe => 'Only me';

  @override
  String calMemberCount(int count) {
    return '$count members';
  }

  @override
  String get calJoinCardBody =>
      'Enter an invite code you received to join a calendar.';

  @override
  String get calJoin => 'Join';

  @override
  String get calCreate => 'Create';

  @override
  String calJoinedCalendar(String name) {
    return 'Joined \"$name\"';
  }

  @override
  String get calInviteCode => 'Invite code';

  @override
  String calManageTitle(String name) {
    return '$name · Manage';
  }

  @override
  String get calDeleteCalendar => 'Delete calendar';

  @override
  String get calCalendarUpdated => 'Calendar updated';

  @override
  String get calInviteCodeRegenerated => 'Generated a new invite code';

  @override
  String get calInviteCodeCopied => 'Invite code copied';

  @override
  String get calRemoveMember => 'Remove member';

  @override
  String calRemoveMemberConfirm(String name) {
    return 'Remove $name from this calendar?';
  }

  @override
  String get calRemove => 'Remove';

  @override
  String calDeleteCalendarConfirm(String name) {
    return 'Delete the \"$name\" calendar? Its events move to your default calendar and all members lose access.';
  }

  @override
  String get calCopy => 'Copy';

  @override
  String get calRegenerate => 'Regenerate';

  @override
  String get calMembers => 'Members';

  @override
  String get calMeSuffix => '(me)';

  @override
  String get calChangeToEditor => 'Change to editor';

  @override
  String get calChangeToViewer => 'Change to viewer';

  @override
  String get calAdd => 'Add';

  @override
  String get calActionFailed => 'Failed';

  @override
  String get calSaveFailed => 'Save failed';

  @override
  String get calDeleteFailed => 'Delete failed';

  @override
  String get calJoinFailed => 'Failed to join';

  @override
  String get calUpdateFailed => 'Update failed';

  @override
  String get calCalendarLoadError => 'Failed to load calendars';

  @override
  String get calLabelLoadError => 'Failed to load labels';

  @override
  String get calMemberLoadError => 'Failed to load members';

  @override
  String get dashTitle => 'Home';

  @override
  String get dashGreeting => 'Have a great day';

  @override
  String get dashTotalAssets => 'Total assets';

  @override
  String get dashChange => 'Change';

  @override
  String get dashThisMonthExpense => 'This month\'s expense';

  @override
  String get dashThisMonthIncome => 'This month\'s income';

  @override
  String get dashRecent => 'Recent transactions';

  @override
  String get dashUpcoming => 'Upcoming events';

  @override
  String get dashRecentTodos => 'Recent todos';

  @override
  String dashOverdue(int count) {
    return 'Overdue $count';
  }

  @override
  String get dashTrendTitle => 'Last 6 months';

  @override
  String get dashSeeMore => 'See more';

  @override
  String get dashEmptyTransactions => 'No recent transactions';

  @override
  String get dashEmptyEvents => 'No upcoming events';

  @override
  String get dashEmptyTodos => 'No pending todos';

  @override
  String get dashAddTx => 'Add transaction';

  @override
  String get dashTodayLabel => 'Today';

  @override
  String get dashTomorrowLabel => 'Tomorrow';

  @override
  String dashDaysLeft(int n) {
    return '${n}d';
  }

  @override
  String get dashHideAmount => 'Hide amounts';

  @override
  String get dashVsLastMonth => 'vs last month';

  @override
  String get dashLiabilities => 'Liabilities';

  @override
  String dashMonthLedger(int month) {
    return '$month ledger';
  }

  @override
  String get dashMonthTxError => 'Couldn\'t load this month\'s transactions';

  @override
  String get dashDailyAvgPrefix => 'Daily average ';

  @override
  String get dashSpentMasked => ' spent.';

  @override
  String get dashSpentUnit => ' spent.';

  @override
  String get dashVsPrevPrefix => ', vs last month ';

  @override
  String get dashSaving => ' saved.';

  @override
  String get dashSpentMore => ' more.';

  @override
  String get dashSame => ' the same.';

  @override
  String get dashNoCategoryData => 'No category data';

  @override
  String get dashNoBudget => 'No budgets set';

  @override
  String get dashTodaySpend => 'Spent today';

  @override
  String get dashTxError => 'Couldn\'t load transactions';

  @override
  String get dashNoTodaySpend => 'Nothing spent today yet';

  @override
  String get expTitle => 'Expenses';

  @override
  String get expFilterAll => 'All';

  @override
  String get expFilterIncome => 'Income';

  @override
  String get expFilterExpense => 'Expense';

  @override
  String get expFilterTransfer => 'Transfer';

  @override
  String get expEmpty => 'No transactions';

  @override
  String get expEmptyDescription => 'Add your first transaction to get started';

  @override
  String get expAdd => 'Add transaction';

  @override
  String get expEdit => 'Edit transaction';

  @override
  String get expDelete => 'Delete transaction';

  @override
  String get expAmount => 'Amount';

  @override
  String get expCategory => 'Category';

  @override
  String get expAsset => 'Asset';

  @override
  String get expDate => 'Date';

  @override
  String get expMerchant => 'Merchant';

  @override
  String get expPaymentMethod => 'Payment';

  @override
  String get expForeignPayment => 'Foreign payment';

  @override
  String get expCurrency => 'Currency';

  @override
  String get expOriginalAmount => 'Local amount';

  @override
  String get expExchangeRate => 'Rate';

  @override
  String expFxHint(String original, String krw) {
    return '$original → $krw';
  }

  @override
  String get expInstallment => 'Installment';

  @override
  String get expRefund => 'Refund';

  @override
  String get expRefundRecord => 'Record refund';

  @override
  String get expLumpSum => 'Lump sum';

  @override
  String expInstallmentMonths(int months) {
    return '$months months';
  }

  @override
  String expInstallmentHint(String perMonth, int months) {
    return 'About $perMonth per month for $months months';
  }

  @override
  String get expDescription => 'Note';

  @override
  String get expTypeIncome => 'Income';

  @override
  String get expTypeExpense => 'Expense';

  @override
  String get transferFeePrefix => 'Fee';

  @override
  String get transferPrincipal => 'Principal';

  @override
  String get transferWithdrawn => 'Total withdrawn';

  @override
  String get transferDeleted => 'Transfer deleted';

  @override
  String get transferDeleteConfirm =>
      'Delete this transfer? Both assets\' balances will be restored.';

  @override
  String get transferAutoTradeSettlement =>
      'Created automatically to cover a shortfall when buying. It disappears when the purchase is cancelled.';

  @override
  String get transferAutoCardPayment =>
      'Created by a card auto-payment. It is tied to the billing cycle and cannot be edited separately.';

  @override
  String get transferAutoCardRefund =>
      'Created to return a card overpayment to the payment account. Adjust the card balance directly and it reconciles automatically the next day.';

  @override
  String get transferAutoDefault =>
      'Created automatically. It disappears when the original is deleted.';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateAvailableDesc => 'Tap to download and install';

  @override
  String get updateAvailableDescIos => 'Tap to get it from AltStore';

  @override
  String updateSheetTitle(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateSheetSubtitle =>
      'A new version is ready. You can get it right below.';

  @override
  String get updateSheetChanges => 'What\'s new';

  @override
  String get updateSheetNoNotes =>
      'No change notes were prepared for this version.';

  @override
  String get updateSheetLater => 'Later';

  @override
  String get updateSheetNow => 'Update';

  @override
  String get updateSheetRetry => 'Try again';

  @override
  String get updateSheetDownloading => 'Downloading';

  @override
  String get updateSheetOpening => 'Opening the installer';

  @override
  String get updateSheetFailed =>
      'Could not download in the app. Opening your browser instead.';

  @override
  String get updateTitle => 'Update';

  @override
  String updateGateTitle(String version) {
    return 'Version $version is here';
  }

  @override
  String get updateGateInstall => 'Install';

  @override
  String get updateGateForcedCancelBody =>
      'This update includes changes you must install.';

  @override
  String get updateCheckFailedTitle => 'Couldn\'t check for updates';

  @override
  String get updateUpToDate => 'You\'re up to date';

  @override
  String updateCurrentBuild(String build) {
    return 'Current build $build';
  }

  @override
  String get updateCheckFailed => 'Couldn\'t check for a new version';

  @override
  String get updateRequiredDesc =>
      'This update is required. You can\'t use the app until you install it.';

  @override
  String get expScheduled => 'Scheduled';

  @override
  String expDeleteRefundWarn(int count, String amount) {
    return '$count linked refund(s) ($amount KRW) will also be deleted';
  }

  @override
  String expRefundLinked(int count, String amount) {
    return '$count refund(s) · $amount KRW linked to this transaction';
  }

  @override
  String get expTypeTransfer => 'Transfer';

  @override
  String get expTransferFrom => 'From';

  @override
  String get expTransferTo => 'To';

  @override
  String get expFee => 'Fee';

  @override
  String get expFilter => 'Filter';

  @override
  String get expFilterMin => 'Min';

  @override
  String get expFilterMax => 'Max';

  @override
  String get expFilterPeriod => 'Period';

  @override
  String get expSplit => 'Split';

  @override
  String get expConvertDutch => 'To Dutch Pay';

  @override
  String get expConvertRecurring => 'To Recurring';

  @override
  String get expExport => 'Export';

  @override
  String get expExportCsv => 'Export CSV';

  @override
  String get expSummaryTitle => 'Monthly summary';

  @override
  String get expSummaryIncome => 'Income';

  @override
  String get expSummaryExpense => 'Expense';

  @override
  String get expSummaryBalance => 'Balance';

  @override
  String get budgetOverallCapNew => 'Set overall monthly cap';

  @override
  String get budgetCategoryAdd => 'Add category budget';

  @override
  String get budgetOverallCapEdit => 'Edit overall monthly cap';

  @override
  String get budgetCategoryEdit => 'Edit category budget';

  @override
  String get budgetUpdated => 'Budget updated';

  @override
  String get budgetAdded => 'Budget added';

  @override
  String get budgetActionFailed => 'Failed';

  @override
  String get budgetDeleteTitle => 'Delete budget';

  @override
  String get budgetDeleteConfirm => 'Delete this budget?';

  @override
  String get budgetDeleteFailed => 'Delete failed';

  @override
  String get budgetOverallCap => 'Overall monthly cap';

  @override
  String get budgetCategoryLoadError => 'Failed to load categories';

  @override
  String get budgetMonthlyLimit => 'Monthly budget limit';

  @override
  String get budgetLoadError => 'Couldn\'t load budget';

  @override
  String get budgetSelectMonth => 'Select month';

  @override
  String budgetMonthOverallCap(int month) {
    return 'Overall cap · $month';
  }

  @override
  String get budgetOverallCapDesc =>
      'The cap for this month\'s total spending (including spending without a category budget).';

  @override
  String get budgetOverallCapEmptyHint =>
      'No overall cap set yet. Use the settings button at the top right to set this month\'s maximum spending limit.';

  @override
  String get budgetCurrentCategorySum => 'Current category limit total';

  @override
  String budgetPercentUsed(String pct) {
    return '$pct% used';
  }

  @override
  String budgetRemaining(String amount) {
    return 'Remaining $amount';
  }

  @override
  String budgetOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get budgetOverallCapLabel => 'Overall cap';

  @override
  String get budgetCategoryAllocated => 'Category allocated';

  @override
  String get budgetAllocatable => 'Allocatable';

  @override
  String budgetOverAllocatedWarning(String amount) {
    return 'Category limits exceed the overall cap by $amount. Raise the overall cap or lower category limits.';
  }

  @override
  String get budgetSpendingPace => 'Spending pace';

  @override
  String get budgetPaceOnTrack => 'On pace';

  @override
  String get budgetPaceFast => 'Too fast';

  @override
  String budgetMonthElapsed(String pct) {
    return '$pct% of month elapsed ↑';
  }

  @override
  String get budgetDailyAvg => 'Daily average';

  @override
  String get budgetDailyRecommended => 'Recommended per remaining day';

  @override
  String get budgetStatusTitle => 'Budget status';

  @override
  String get budgetOver => 'Over';

  @override
  String get budgetHealthy => 'On track';

  @override
  String get budgetByCategory => 'Budget by category';

  @override
  String budgetCountSet(int count) {
    return '$count set';
  }

  @override
  String get budgetNoCategoryBudgets => 'No category budgets';

  @override
  String get budgetGoToSettings => 'Go to budget settings →';

  @override
  String budgetCategoryFallback(int id) {
    return 'Category #$id';
  }

  @override
  String get budgetComplianceTitle => 'Last 6 months compliance';

  @override
  String get budgetComplianceSubtitle => 'Spending vs limit %';

  @override
  String get budgetNoComplianceData => 'No compliance data yet';

  @override
  String get budgetVsLimit => 'vs limit';

  @override
  String get budgetLimit => 'Limit';

  @override
  String get budgetEmptyMonth => 'No budget for this month';

  @override
  String get budgetEmptyHint => 'Set an overall cap or category budgets';

  @override
  String get budgetSetup => 'Set budget';

  @override
  String get budgetCopyLastMonth => 'Copy last month\'s budget';

  @override
  String budgetCopyConfirmMessage(String from, int count, String to) {
    return '$from budget limits ($count) will be copied to $to. Budgets that already exist this month will be overwritten.';
  }

  @override
  String get budgetCopyFailed => 'Copy failed';

  @override
  String budgetCopiedCount(int count) {
    return 'Copied $count budgets';
  }

  @override
  String get budgetCopyLastMonthBtn => 'Copy last month';

  @override
  String budgetMonthTotal(int month) {
    return 'Total budget · $month';
  }

  @override
  String get budgetNotSet => 'Not set';

  @override
  String get budgetUsed => 'Used';

  @override
  String get budgetAllocated => 'Allocated';

  @override
  String budgetByCategoryCount(int count) {
    return 'Budget by category · $count';
  }

  @override
  String get budgetAdd => 'Add budget';

  @override
  String get budgetNoCategorySet => 'No category budgets set';

  @override
  String get cardBenefitTypeAll => 'All benefits';

  @override
  String get cardBenefitTypeDiscount => 'Discount';

  @override
  String get cardBenefitTypePoint => 'Points';

  @override
  String get cardBenefitTypeCashback => 'Cashback';

  @override
  String get cardBenefitTypeMileage => 'Mileage';

  @override
  String get cardManageTitle => 'Manage cards';

  @override
  String get cardBenefitsTitle => 'Card benefits';

  @override
  String get cardSelectTitle => 'Select card';

  @override
  String get cardBenefitMappingTitle => 'Card benefit mapping';

  @override
  String get cardBenefitMappingTooltip => 'Benefit mapping';

  @override
  String get cardSearchHintName => 'Search by card name';

  @override
  String get cardSearchHintFull => 'Search by name, brand, or benefit';

  @override
  String get cardSearchHintNameCompany => 'Search card / issuer';

  @override
  String get cardLoadError => 'Failed to load cards';

  @override
  String get cardDetailLoadError => 'Failed to load card details';

  @override
  String get cardSearchError => 'Card search failed';

  @override
  String get cardAddFailed => 'Failed to add';

  @override
  String get cardDeleteFailed => 'Failed to delete';

  @override
  String get cardMappingLoadError => 'Failed to load mappings';

  @override
  String get cardLastMonthPerf => 'Last month spend';

  @override
  String get cardKeyBenefitTags => 'Key benefit tags';

  @override
  String cardBenefitDetailCount(int count) {
    return 'Benefit details · $count';
  }

  @override
  String get cardExpandAll => 'Expand all';

  @override
  String get cardCollapseAll => 'Collapse all';

  @override
  String get cardCautions => 'Notes';

  @override
  String get cardCautionDetailsFallback => 'Details';

  @override
  String get cardBenefits => 'Benefits';

  @override
  String get cardNone => 'None';

  @override
  String get cardFeeUnknown => 'Unknown';

  @override
  String get cardFeeFree => 'Free';

  @override
  String get cardPerfNone => 'No spend requirement';

  @override
  String cardFeeDomesticOnly(String amount) {
    return 'Domestic only $amount';
  }

  @override
  String cardPerfMin(String amount) {
    return '$amount or more';
  }

  @override
  String cardPerfMonthly(String amount) {
    return 'Spend $amount/mo';
  }

  @override
  String cardAnnualFeeValue(String fee) {
    return 'Annual fee $fee';
  }

  @override
  String cardPerfMonthTitle(String month) {
    return '$month spend';
  }

  @override
  String get cardPerfAchieved => 'Achieved';

  @override
  String cardPerfRemaining(String amount) {
    return '$amount left';
  }

  @override
  String get cardMappingNew => 'New mapping';

  @override
  String get cardMappingNewDesc =>
      'Link a card benefit category (e.g., Cafe, Fuel) to a ledger category to power auto-suggestions when entering transactions.';

  @override
  String get cardMappingBenefitPlaceholder => 'Benefit category';

  @override
  String get cardMappingCategoryPlaceholder => 'Ledger category';

  @override
  String get cardMappingAdd => 'Add mapping';

  @override
  String get cardMappingRegistered => 'Registered mappings';

  @override
  String get cardMappingEmpty => 'No mappings registered';

  @override
  String get cardMappingDefault => 'Default';

  @override
  String get cardIncludeDiscontinued => 'Include discontinued cards';

  @override
  String cardTotalCount(int count) {
    return '$count total';
  }

  @override
  String get cardEmpty => 'No cards';

  @override
  String get cardNoResults => 'No results';

  @override
  String get cardNoResultsHint => 'Try a different search term';

  @override
  String get cardPickerNoMatch => 'No matching cards';

  @override
  String get categoryManageTitle => 'Manage categories';

  @override
  String get categorySearchHint => 'Search categories';

  @override
  String get categoryLoadError => 'Failed to load categories';

  @override
  String get categoryNoResults => 'No search results';

  @override
  String get categoryEmpty => 'No categories';

  @override
  String get categoryEmptyHint => 'Add one with the \'Add\' button above';

  @override
  String categoryHasSubcategories(String type) {
    return '$type · Has subcategories';
  }

  @override
  String get categoryAdd => 'Add category';

  @override
  String get categoryEdit => 'Edit category';

  @override
  String get categoryNameRequired => 'Please enter a name.';

  @override
  String get categoryNameTooLong => 'Name must be 12 characters or fewer.';

  @override
  String get categoryNameDuplicate =>
      'A category with this name already exists in this location.';

  @override
  String get categoryParent => 'Parent category';

  @override
  String get categoryBudgetExceedTitle => 'Budget exceeded';

  @override
  String categoryBudgetExceedMessage(String parent, String amount) {
    return 'Moving will exceed the \"$parent\" budget by $amount. Move anyway?';
  }

  @override
  String get categoryMove => 'Move';

  @override
  String get categoryUpdated => 'Category updated';

  @override
  String get categoryAdded => 'Category added';

  @override
  String get categoryActionFailed => 'Failed';

  @override
  String get categoryDeleteTitle => 'Delete category';

  @override
  String categoryDeleteHasChildren(String name) {
    return 'The \"$name\" category has subcategories and can\'t be deleted. Please clear its subcategories first.';
  }

  @override
  String categoryDeleteWithBudget(String name) {
    return 'This category has a budget. Deleting it will also delete the budget. Delete the \"$name\" category?';
  }

  @override
  String categoryDeleteConfirm(String name) {
    return 'Delete the \"$name\" category?';
  }

  @override
  String get categoryDeleteFailed => 'Delete failed';

  @override
  String get categoryNew => 'New category';

  @override
  String categoryPreview(String type) {
    return '$type category · Preview';
  }

  @override
  String get categoryTypeLabel => 'Type';

  @override
  String get categoryOptionalSuffix => ' (optional)';

  @override
  String get categoryParentMoveHint =>
      'You can move it under a different parent. To promote it to top level, move its linked transactions and recreate it.';

  @override
  String get categoryMakeRoot => '— Keep as top-level category —';

  @override
  String get categoryNamePlaceholder => 'e.g., Pets, Side income';

  @override
  String get categoryIconLabel => 'Icon';

  @override
  String get authLoginPrompt => 'Sign in with your SSO account';

  @override
  String get authSsoLogin => 'SSO login';

  @override
  String get authLoginTitle => 'Login';

  @override
  String get authLoginFailed => 'Login failed';

  @override
  String get authLoginError => 'Error during login';

  @override
  String authSecurityNotHttps(String url) {
    return 'Security error: the SSO server is not HTTPS ($url).';
  }

  @override
  String get authStateMismatch =>
      'Security check failed (state mismatch). Please try again.';

  @override
  String get authNoAuthCode =>
      'Couldn\'t get the authorization code. Please try again.';

  @override
  String get authPageLoadError => 'Couldn\'t load the login page.';

  @override
  String get dutchTitle => 'Dutch Pay';

  @override
  String get dutchCreate => 'Create settlement';

  @override
  String get dutchLoadFailed => 'Failed to load Dutch Pay';

  @override
  String get dutchTabActive => 'Active';

  @override
  String get dutchTabPast => 'Done';

  @override
  String get dutchTabFriends => 'Friends';

  @override
  String get dutchEmptyActiveTitle => 'No active settlements';

  @override
  String get dutchEmptyActiveSub => 'Tap + to create a new settlement.';

  @override
  String get dutchEmptyPastTitle => 'No completed settlements';

  @override
  String get dutchEmptyPastSub => 'Completed settlements appear here.';

  @override
  String get dutchEmptyFriendsTitle => 'No friends yet';

  @override
  String get dutchEmptyFriendsSub =>
      'Add participants to a settlement to see them here.';

  @override
  String get dutchActionFailed => 'Failed';

  @override
  String get dutchSettleFailed => 'Settlement failed';

  @override
  String get dutchDeleteFailed => 'Delete failed';

  @override
  String get dutchToReceive => 'To receive';

  @override
  String get dutchToSend => 'To send';

  @override
  String dutchFromPeople(int count) {
    return 'from $count people';
  }

  @override
  String dutchToPeople(int count) {
    return 'to $count people';
  }

  @override
  String get dutchPerPersonLabel => 'Per person';

  @override
  String dutchNPeople(int count) {
    return '$count people';
  }

  @override
  String dutchSettledTogetherCount(int count) {
    return 'Settled together $count times';
  }

  @override
  String get dutchSettled => 'Settled';

  @override
  String get dutchMe => 'Me';

  @override
  String get dutchPayer => 'Payer';

  @override
  String get dutchSetPayer => 'Set as payer';

  @override
  String get dutchNameLabel => 'Settlement name';

  @override
  String get dutchNamePlaceholder => 'e.g. Team dinner';

  @override
  String get dutchPlaceLabel => 'Place (optional)';

  @override
  String get dutchPlacePlaceholder => 'Place or merchant';

  @override
  String get dutchTotalLabel => 'Total amount';

  @override
  String get dutchDateLabel => 'Date';

  @override
  String get dutchSelectParticipants => 'Select participants';

  @override
  String dutchNSelected(int count) {
    return '$count selected';
  }

  @override
  String get dutchAddNamePlaceholder => 'Enter a name to add';

  @override
  String get dutchAdd => 'Add';

  @override
  String get dutchNext => 'Next';

  @override
  String get dutchPrev => 'Back';

  @override
  String get dutchDetailTitle => 'Settlement details';

  @override
  String get dutchParticipant => 'Participant';

  @override
  String get dutchSettleAction => 'Mark as settled';

  @override
  String get dutchDeleteTitle => 'Delete Dutch Pay';

  @override
  String dutchDeleteConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get dutchRequestAll => 'Request all';

  @override
  String dutchRequestSent(String name) {
    return 'Payment request sent to $name (KakaoTalk/SMS coming soon)';
  }

  @override
  String dutchRequestSentBulk(int count) {
    return 'Payment request sent to $count people (KakaoTalk/SMS coming soon)';
  }

  @override
  String get dutchAllSettled => 'All participants have already settled';

  @override
  String dutchNeedsPayment(String amount) {
    return 'Send $amount원';
  }

  @override
  String get dutchNoName => '(No name)';

  @override
  String get dutchMarkPaid => 'Mark as paid';

  @override
  String get dutchRequest => 'Request';

  @override
  String get dutchUnsettled => 'Unsettled';

  @override
  String get dutchStartTitle => 'Start Dutch Pay';

  @override
  String get dutchFromTxDesc =>
      'Create a Dutch Pay settlement from this transaction. Send payment requests to participants and track settlement progress.';

  @override
  String get dutchSplitMethod => 'Split method';

  @override
  String get dutchSplitEqualTitle => '1/N';

  @override
  String get dutchSplitEqualSub => 'Equal split';

  @override
  String get dutchSplitRatioTitle => 'Ratio';

  @override
  String get dutchSplitRatioSub => 'By weight';

  @override
  String get dutchSplitCustomTitle => 'Custom amount';

  @override
  String get dutchSplitCustomSub => 'Each differently';

  @override
  String get dutchIncludeMyself => 'Include myself in the split';

  @override
  String get dutchIncludeMyselfDesc => 'Your share is calculated too';

  @override
  String get dutchIncludeMyselfOffDesc =>
      'You paid in full, collect only others\' shares';

  @override
  String get dutchSourceSub => 'Request payments from participants';

  @override
  String get dutchRequestMsgLabel => 'Request message (optional)';

  @override
  String get dutchRequestMsgPlaceholder => 'Add a note to send to participants';

  @override
  String dutchShortBy(String amount) {
    return 'The total is $amount원 short.';
  }

  @override
  String dutchOverBy(String amount) {
    return 'The total exceeds by $amount원.';
  }

  @override
  String get dutchCreated => 'Settlement created';

  @override
  String get expLoadError => 'Failed to load transactions';

  @override
  String get expEmptyMonth => 'No transactions this month';

  @override
  String get expEmptyDay => 'No transactions on this day';

  @override
  String get expTotal => 'Total';

  @override
  String get expFiltering => 'Filtering';

  @override
  String expFilteringBy(String name) {
    return 'Filtering: $name';
  }

  @override
  String get expViewList => 'List';

  @override
  String get expViewCalendar => 'Calendar';

  @override
  String expTxCount(int count) {
    return '$count items';
  }

  @override
  String get expAddShort => 'Add';

  @override
  String get expTransferDone => 'Transfer completed';

  @override
  String get expActionFailed => 'Failed';

  @override
  String get expUpdated => 'Transaction updated';

  @override
  String get expAdded => 'Transaction added';

  @override
  String get expDeleteConfirm =>
      'Delete this transaction? Linked asset balances will be adjusted.';

  @override
  String get expDeleted => 'Transaction deleted';

  @override
  String get expDeleteFailed => 'Delete failed';

  @override
  String get expSplitMismatch => 'Split doesn\'t match the amount';

  @override
  String expSplitDiff(String total, String sum, String diff) {
    return 'New total $total원 · Split sum $sum원 · $diff원 diff';
  }

  @override
  String get expSplitReconcile => 'Reconcile split';

  @override
  String get expPresetLoad => 'Load preset';

  @override
  String get expPresetApplied => 'Applied';

  @override
  String get expPresetSaveCurrent => 'Save current input';

  @override
  String get expPresetEmpty =>
      'No saved presets yet. Enter a transaction you use often, then tap “Save current input”.';

  @override
  String get expPresetFilled =>
      'Preset values filled in. Adjust the amount and note, then save.';

  @override
  String get expClear => 'Clear';

  @override
  String get expPresetManageHint => 'Settings → Manage presets';

  @override
  String get expSaveFailed => 'Save failed';

  @override
  String get expPresetSaveTitle => 'Save as preset';

  @override
  String get expPresetNamePlaceholder => 'e.g. Lunch box';

  @override
  String expPresetLockAmount(String amount) {
    return 'Lock amount — auto-fills $amount원 when applied';
  }

  @override
  String get expPayCash => 'Cash';

  @override
  String get expPayCard => 'Card';

  @override
  String get expPayTransfer => 'Bank transfer';

  @override
  String get expPayOther => 'Other';

  @override
  String get expAutoLock => 'Auto';

  @override
  String get expAutoSourceTradeRealized =>
      'Realized P/L from a sale. The amount is calculated from the trade.';

  @override
  String get expAutoSourceTransferInterest =>
      'Interest on a transfer. The amount is calculated from the transfer.';

  @override
  String get expAutoSourceDefault =>
      'Created automatically. It disappears when the original is deleted.';

  @override
  String get expPresetLock => 'Preset lock';

  @override
  String get expNoCategoryForType => 'No categories for this type';

  @override
  String get expSubcategory => 'Subcategory';

  @override
  String expTopCategorySuffix(String name) {
    return '$name (parent)';
  }

  @override
  String get expIncomeSource => 'Income source';

  @override
  String get expPayee => 'Merchant';

  @override
  String get expIncomeSourcePlaceholder => 'e.g. Forest Inc.';

  @override
  String get expPayeePlaceholder => 'e.g. Starbucks Gangnam';

  @override
  String get expIncomeMethod => 'Income method';

  @override
  String get expNone => 'None';

  @override
  String get expDepositAccount => 'Deposit account';

  @override
  String get expAccountCard => 'Account/Card';

  @override
  String get expAssetLoadError => 'Failed to load assets';

  @override
  String get expWithdrawAccount => 'From account';

  @override
  String get expSelect => 'Select';

  @override
  String get expTransferSameAsset => 'From and to assets must differ';

  @override
  String get expFeeOptional => 'Fee (optional)';

  @override
  String get expInterest => 'Interest';

  @override
  String get expInterestHint =>
      'The interest portion — debt decreases only by the rest';

  @override
  String expInterestSplit(String principal, String interest) {
    return 'Principal $principal · Interest $interest';
  }

  @override
  String get expDateTime => 'Date & time';

  @override
  String get expMemoPlaceholder => 'e.g. Lunch, dinner';

  @override
  String get expIncomeDetail => 'Income details';

  @override
  String get expExpenseDetail => 'Expense details';

  @override
  String get expTxFallback => 'Transaction';

  @override
  String get expUncategorized => 'Uncategorized';

  @override
  String get expValueNone => 'None';

  @override
  String expItemsCount(int count) {
    return '$count items';
  }

  @override
  String get expNotSelected => 'Not selected';

  @override
  String expPrevTxAt(String merchant) {
    return 'Previous at $merchant';
  }

  @override
  String get expThisMonth => 'This month';

  @override
  String expTimesCount(int count) {
    return '$count×';
  }

  @override
  String get expItem => 'Item';

  @override
  String get expFilterApply => 'Apply filter';

  @override
  String expNSelected(int count) {
    return '$count selected';
  }

  @override
  String get expPeriodWeek => 'This week';

  @override
  String get expPeriod3Month => '3 months';

  @override
  String get expPeriodCustom => 'Custom';

  @override
  String get expStartDate => 'Start date';

  @override
  String get expEndDate => 'End date';

  @override
  String get expDateRangeError => 'Start date can\'t be after end date.';

  @override
  String get expTxType => 'Transaction type';

  @override
  String get expAmountRange => 'Amount range';

  @override
  String get expMinAmount => 'Min amount';

  @override
  String get expMaxAmount => 'Max amount';

  @override
  String get expSplitSave => 'Save split';

  @override
  String get expSplitRemove => 'Remove split';

  @override
  String get expSplitLoadError => 'Failed to load split';

  @override
  String get expAddAmount => 'Extra amount';

  @override
  String get expSplitSaved => 'Split saved';

  @override
  String get expSplitRemoveConfirm =>
      'Remove all split items for this transaction?';

  @override
  String get expClearFailed => 'Failed to clear';

  @override
  String get expSplitMatches => 'Split sum matches the total';

  @override
  String get expSplitSum => 'Split sum';

  @override
  String get expTotalAmount => 'Total';

  @override
  String get expSplitTotalChanged => 'The total changed — reconcile the split';

  @override
  String get expSplitMismatchTotal => 'Split sum doesn\'t match the total';

  @override
  String get expSplitCheckItems => 'Check the split items';

  @override
  String get expShort => 'Short';

  @override
  String get expOver => 'Over';

  @override
  String get expQuickAdjust => 'Quick adjust';

  @override
  String get expProrate => 'Prorate';

  @override
  String get expProrateDesc => 'Auto-adjust by weight';

  @override
  String get expApplyToLargest => 'Apply to largest';

  @override
  String get expApplyToLargestDesc => 'Difference to the largest item';

  @override
  String get expAdjustItem => 'Adjustment item';

  @override
  String get expAdjustItemDesc => 'Shortfall as a new item';

  @override
  String get expRecommended => 'Recommended';

  @override
  String get expSplitDesc =>
      'Record one payment split by category and item. e.g. Groceries and household items bought together at a mart.';

  @override
  String get expOriginalTx => 'Original transaction';

  @override
  String get expAddItem => 'Add item';

  @override
  String get expSplitEven => 'Split evenly';

  @override
  String get expSplitRatio => 'Split ratio';

  @override
  String get expDeleteItem => 'Delete item';

  @override
  String get expItemNamePlaceholder => 'Item name (optional)';

  @override
  String get exportTitle => 'Export data';

  @override
  String exportShareText(String start, String end) {
    return 'Data export ($start ~ $end)';
  }

  @override
  String get exportSuccess => 'Export complete';

  @override
  String get exportTypeExpense => 'Transactions';

  @override
  String get exportTypeAsset => 'Assets & accounts';

  @override
  String get exportTypeBudget => 'Budget settings';

  @override
  String get exportTypeCategory => 'Categories';

  @override
  String get exportTypeMemo => 'Memos';

  @override
  String get exportTypeCalendar => 'Calendar events';

  @override
  String get exportTypeTodo => 'To-dos';

  @override
  String get exportFormatCsvDesc => 'Excel & Google Sheets';

  @override
  String get exportFormatExcelDesc => 'Microsoft Excel';

  @override
  String get exportFormatJsonDesc => 'Developers & backup';

  @override
  String get exportPeriodThisMonth => 'This month';

  @override
  String get exportPeriodLastMonth => 'Last month';

  @override
  String get exportPeriodLast3Months => 'Last 3 months';

  @override
  String get exportPeriodThisYear => 'This year';

  @override
  String get exportPeriodCustom => 'Custom';

  @override
  String get exportPeriodTitle => 'Select period';

  @override
  String get exportDateRangeError =>
      'Start date can\'t be later than the end date.';

  @override
  String exportTypesTitle(int count) {
    return 'Data types — $count selected';
  }

  @override
  String get exportTypesDesc =>
      'Choose the data to export. Multiple types are bundled into a ZIP.';

  @override
  String exportCount(int count) {
    return '$count';
  }

  @override
  String get exportFormatTitle => 'File format';

  @override
  String get exportMaskLabel =>
      'Hide sensitive info (balance, amount, institution)';

  @override
  String get exportPreview => 'Preview';

  @override
  String get exportRun => 'Export';

  @override
  String get exportEmpty => 'No data to export for this period.';

  @override
  String exportPreviewRows(int count) {
    return 'Top $count rows';
  }

  @override
  String get fileAttachTitle => 'Attachments';

  @override
  String get fileTooltipGallery => 'Gallery';

  @override
  String get fileTooltipCamera => 'Camera';

  @override
  String get fileTooltipFile => 'File';

  @override
  String fileUploadComplete(String name) {
    return '$name uploaded';
  }

  @override
  String get fileUploadFailed => 'Upload failed';

  @override
  String get fileDeleteTitle => 'Delete file';

  @override
  String fileDeleteConfirm(String name) {
    return 'Delete $name?';
  }

  @override
  String get fileDeleteFailed => 'Delete failed';

  @override
  String get fileLoadError => 'Failed to load attachments';

  @override
  String get fileEmpty => 'No attachments';

  @override
  String get moreGroupMoney => 'Money';

  @override
  String get moreGroupDaily => 'Daily';

  @override
  String get moreGroupPersonal => 'Personalization';

  @override
  String get moreGroupSystem => 'Account & System';

  @override
  String get moreItemStocks => 'Securities';

  @override
  String get moreItemStats => 'Stats & Analysis';

  @override
  String get moreItemAccountCard => 'Account & Card';

  @override
  String get moreItemCardBenefits => 'Card Benefits';

  @override
  String get moreItemDisplay => 'Display';

  @override
  String get moreItemAccount => 'Account';

  @override
  String get moreDescExpense => 'Expense · Income · Transfer';

  @override
  String get moreDescAsset => 'Accounts · Cards · Investments · Debt';

  @override
  String get moreDescStocks => 'Quotes · Holdings · Watchlist · Orders';

  @override
  String get moreDescBudget => 'Monthly · By category';

  @override
  String get moreDescSavingGoal => 'Goals · Progress';

  @override
  String get moreDescStats => 'Category · Trends · Comparison';

  @override
  String get moreDescRecurring => 'Subscriptions · Fixed costs';

  @override
  String get moreDescAccountCard => 'Add · Edit accounts & cards';

  @override
  String get moreDescCalendar => 'Events · Recurring · Reminders';

  @override
  String get moreDescTodo => 'Due · Priority · Tags';

  @override
  String get moreDescMemo => 'Category · Pin · Search';

  @override
  String get moreDescDutchPay => 'Settle · Friends · Payment requests';

  @override
  String get moreDescCardBenefits => 'Search credit & check cards';

  @override
  String get moreDescCategories => 'Expense · Income';

  @override
  String get moreDescPresets => 'Frequently used entries';

  @override
  String get moreDescDisplay => 'Theme · Language · Currency';

  @override
  String get moreDescSettings => 'All settings menu';

  @override
  String get moreDescNotifications => 'Push · Do not disturb';

  @override
  String get moreDescExport => 'CSV · Excel · JSON';

  @override
  String get moreDescAccount => 'Profile · Security · Subscription';

  @override
  String get moreSearchHint => 'Search menu';

  @override
  String get moreSearchEmpty => 'No results found';

  @override
  String get settingsGroupDataMgmt => 'Data Management';

  @override
  String get settingsMenuCategory => 'Category Management';

  @override
  String get settingsMenuAccountCard => 'Account & Card Management';

  @override
  String get settingsMenuBudget => 'Budget Settings';

  @override
  String get settingsMenuRecurring => 'Recurring Management';

  @override
  String get settingsMenuPreset => 'Preset Management';

  @override
  String get settingsGroupTagsLabels => 'Tags · Labels';

  @override
  String get settingsGroupShare => 'Sharing & Communication';

  @override
  String get settingsMenuCalendarShare => 'Calendar Management & Sharing';

  @override
  String get settingsMenuCalendarLabel => 'Calendar Labels';

  @override
  String get settingsGroupApp => 'App Environment';

  @override
  String get settingsMenuAppearance => 'Display Settings';

  @override
  String get settingsGroupData => 'Data';

  @override
  String get settingsMenuStorage => 'Storage';

  @override
  String get settingsGroupAccount => 'Account';

  @override
  String get settingsMenuAccountMgmt => 'Account Management';

  @override
  String get settingsMenuPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsPrivacyOpenFailed => 'Could not open the privacy policy';

  @override
  String get appearanceTitle => 'Display Settings';

  @override
  String get appearanceTheme => 'Theme';

  @override
  String get appearanceThemeLight => 'Light';

  @override
  String get appearanceThemeLightDesc => 'Light background';

  @override
  String get appearanceThemeDark => 'Dark';

  @override
  String get appearanceThemeDarkDesc => 'Dark background';

  @override
  String get appearanceThemeSystem => 'System';

  @override
  String get appearanceThemeSystemDesc => 'Auto switch';

  @override
  String hideAmountsLockAllDesc(int total, int count) {
    return 'Hiding $count of $total cards';
  }

  @override
  String get hideAmountsTitle => 'Hide Amounts';

  @override
  String get hideAmountsSectionDesc =>
      'Pick the cards to hide. You\'ll verify once when you save.';

  @override
  String get hideAmountsLockAll => 'Lock everything';

  @override
  String get hideAmountsTabAll => 'All';

  @override
  String get hideAmountsSelectAll => 'Select all';

  @override
  String get hideAmountsClearAll => 'Clear all';

  @override
  String hideAmountsSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get hideAmountsDiscardTitle => 'Leave without saving?';

  @override
  String get hideAmountsDiscardBody => 'Your selection will be discarded.';

  @override
  String get hideAmountsDiscardConfirm => 'Leave';

  @override
  String get hideAmountsSaved => 'Saved';

  @override
  String get hideAmountsPageHome => 'Home';

  @override
  String get hideAmountsPageAsset => 'Assets';

  @override
  String get hideAmountsPageLedger => 'Ledger';

  @override
  String get hideAmountsPageStats => 'Stats';

  @override
  String get hideAmountsPageBudget => 'Budget';

  @override
  String get hideAmountsPageStocks => 'Stocks';

  @override
  String get hideAmountsPageDutchpay => 'Dutch Pay';

  @override
  String get hideAmountsPageEtc => 'Other';

  @override
  String get hideCardHomeNetWorth => 'Net worth';

  @override
  String get hideCardHomeMonthExpense => 'This month income & spending';

  @override
  String get hideCardHomeCategoryDonut => 'Category donut';

  @override
  String get hideCardHomeBudget => 'Budget progress';

  @override
  String get hideCardHomeTodaySpend => 'Today\'s spending';

  @override
  String get hideCardHomeUpcoming => 'Upcoming payments';

  @override
  String get hideCardAssetNetWorth => 'Net worth & trend';

  @override
  String get hideCardAssetComposition => 'Asset composition';

  @override
  String get hideCardAssetAccounts => 'Accounts & deposits';

  @override
  String get hideCardAssetInvestments => 'Investments';

  @override
  String get hideCardAssetCards => 'Cards';

  @override
  String get hideCardAssetLoans => 'Loans';

  @override
  String get hideCardAssetSavingGoals => 'Saving goals';

  @override
  String get hideCardAssetUpcoming => 'Upcoming payments';

  @override
  String get hideCardAssetDetail => 'Asset detail';

  @override
  String get hideCardAssetManage => 'Manage accounts & cards';

  @override
  String get hideCardLedgerMonthSummary => 'Monthly total';

  @override
  String get hideCardLedgerCalendar => 'Calendar amounts';

  @override
  String get hideCardLedgerTxList => 'Transaction list';

  @override
  String get hideCardLedgerTxDetail => 'Transaction detail';

  @override
  String get hideCardStatsCategory => 'Category tab';

  @override
  String get hideCardStatsTrend => 'Trend tab';

  @override
  String get hideCardStatsCompare => 'Compare tab';

  @override
  String get hideCardBudgetHeader => 'Budget summary';

  @override
  String get hideCardBudgetPace => 'Spending pace';

  @override
  String get hideCardBudgetStatus => 'Status';

  @override
  String get hideCardBudgetCategories => 'Budget by category';

  @override
  String get hideCardBudgetCompliance => 'Compliance';

  @override
  String get hideCardBudgetManage => 'Manage budgets';

  @override
  String get hideCardStocksSummary => 'Valuation summary';

  @override
  String get hideCardStocksHoldings => 'Holdings';

  @override
  String get hideCardStocksDetail => 'Stock detail';

  @override
  String get hideCardDutchpaySummary => 'Dutch pay summary';

  @override
  String get hideCardDutchpaySessions => 'Settlements';

  @override
  String get hideCardEtcSearch => 'Search results';

  @override
  String get hideCardEtcRecurring => 'Recurring';

  @override
  String get hideCardEtcPreset => 'Presets';

  @override
  String get appearanceHideAmount => 'Hide amounts';

  @override
  String get appearanceHideAmountDesc => 'Display all amounts as ••••';

  @override
  String get appearanceRegion => 'Display region';

  @override
  String get appearanceRegionPlaceholder => 'Select a region';

  @override
  String get appearanceRegionDesc =>
      'Dates and times are shown in the selected region';

  @override
  String get appearanceCurrency => 'Default currency';

  @override
  String get appearanceCurrencyKrw => 'South Korean Won';

  @override
  String get appearanceCurrencyUsd => 'US Dollar';

  @override
  String get appearanceCurrencyEur => 'Euro';

  @override
  String get appearanceCurrencyJpy => 'Japanese Yen';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get passwordChangeFailed => 'Failed to change password.';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordNew => 'New password';

  @override
  String get passwordNewPlaceholder =>
      '8+ characters, incl. a special character';

  @override
  String get passwordNewConfirm => 'Confirm new password';

  @override
  String get passwordConfirmPlaceholder => 'Enter once more';

  @override
  String get passwordMismatch => 'New passwords do not match';

  @override
  String get passwordMatched => 'New passwords match';

  @override
  String get passwordRuleLength => 'At least 8 characters';

  @override
  String get passwordRuleSpecial => 'At least 1 special character';

  @override
  String get passwordSameAsCurrent =>
      'New password must be different from the current one';

  @override
  String get passwordChangeAction => 'Change';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountDefaultName => 'User';

  @override
  String accountJoined(String date) {
    return 'Joined $date';
  }

  @override
  String get accountEditComingSoon => 'Profile editing is coming soon';

  @override
  String get accountSecurity => 'Security';

  @override
  String get accountPasswordDesc => 'No recent changes';

  @override
  String get accountTwoFa => 'Two-factor authentication';

  @override
  String get accountOn => 'On';

  @override
  String get accountOff => 'Off';

  @override
  String get accountDevices => 'Logged-in devices';

  @override
  String get accountCurrentDevice => 'Current device';

  @override
  String get accountLoginHistory => 'Login history';

  @override
  String get accountLast30Days => 'Last 30 days';

  @override
  String get accountConnected => 'Connected accounts';

  @override
  String get accountNotConnected => 'Not connected';

  @override
  String get accountConnect => 'Connect';

  @override
  String accountSocialComingSoon(String name) {
    return '$name connection is coming soon';
  }

  @override
  String get accountBilling => 'Subscription & Billing';

  @override
  String accountNextBilling(String date) {
    return 'Next billing $date · ';
  }

  @override
  String get accountProActive => 'Pro active';

  @override
  String get accountProPromo => 'Securities investing is Pro-only · Start now';

  @override
  String get accountPerMonth => '/ mo';

  @override
  String get accountProStart => 'Start Pro';

  @override
  String get accountManage => 'Account Management';

  @override
  String get accountLogoutDesc => 'This device only';

  @override
  String get accountWithdraw => 'Delete account';

  @override
  String get accountWithdrawDesc => 'Permanent deletion';

  @override
  String accountAppVersion(String version) {
    return 'App version $version';
  }

  @override
  String get accountAppVersionLatest => 'Up to date';

  @override
  String accountAppVersionUpdate(String version) {
    return 'New version $version';
  }

  @override
  String get accountLogoutConfirm => 'Are you sure you want to log out?';

  @override
  String get accountWithdrawTitle =>
      'Are you sure you want to delete your account?';

  @override
  String get accountWithdrawConfirm =>
      'Deleting your account permanently erases all data.\nThis cannot be undone.';

  @override
  String get notiUnreadPrefix => '';

  @override
  String get notiUnreadSuffix => ' unread';

  @override
  String get notiSettings => 'Notification settings';

  @override
  String get notiSettingsLoadError => 'Failed to load settings';

  @override
  String get notiKindTitle => 'Notification types';

  @override
  String get notiKindSubtitle => 'Keep only the alerts you need.';

  @override
  String get notiPayment => 'Payment alerts';

  @override
  String get notiPaymentDesc => 'D-1 before due date, and on the payment day';

  @override
  String notiBudgetDesc(int threshold) {
    return 'Category budget reaches $threshold%·100%';
  }

  @override
  String get notiAutoRecord => 'Auto-record alerts';

  @override
  String get notiAutoRecordDesc =>
      'When a recurring transaction is auto-recorded';

  @override
  String get notiDutchPay => 'Dutch pay alerts';

  @override
  String get notiDutchPayDesc => 'Payment requests / settlement complete';

  @override
  String get notiCalendarDesc => '15 minutes before a calendar event';

  @override
  String get notiWeeklyReport => 'Weekly report';

  @override
  String get notiWeeklyReportDesc => 'Every Monday at 9 AM';

  @override
  String get notiMonthlyReport => 'Monthly report';

  @override
  String get notiMonthlyReportDesc => 'On the 1st of each month at 9 AM';

  @override
  String get notiPush => 'Push notifications';

  @override
  String get notiPushOn => 'All notifications are enabled';

  @override
  String get notiPushOff => 'Notifications are off';

  @override
  String get notiThresholdTitle => 'Budget alert threshold';

  @override
  String get notiThresholdCurrent => 'Current ';

  @override
  String get notiThresholdDesc1 => 'When usage exceeds this, a ';

  @override
  String get notiThresholdWarning => 'Warning';

  @override
  String get notiThresholdDesc2 =>
      ' state is shown and you get an alert. At 100%, an ';

  @override
  String get notiThresholdOver => 'Over';

  @override
  String get notiThresholdDesc3 => ' alert is sent separately.';

  @override
  String get notiQuietTitle => 'Do not disturb hours';

  @override
  String get notiQuietSubtitle =>
      'During these hours, alerts show without sound or vibration.';

  @override
  String get notiQuietToggle => 'Use do not disturb';

  @override
  String get notiQuietToggleDesc => 'Auto-mute during a set time range';

  @override
  String get notiQuietStart => 'Start';

  @override
  String get notiQuietEnd => 'End';

  @override
  String get notiSoundTitle => 'Sound & vibration';

  @override
  String get notiSound => 'Notification sound';

  @override
  String get notiSoundDesc => 'In-app notification sound';

  @override
  String get notiSoundChime => 'Chime';

  @override
  String get notiSoundDefault => 'Default';

  @override
  String get notiSoundNone => 'Silent';

  @override
  String get notiVibration => 'Vibration';

  @override
  String get notiVibrationDesc => 'Vibrate with notifications on mobile';

  @override
  String get notiEmailTitle => 'Email notifications';

  @override
  String get notiEmailSubtitle =>
      'Get summaries by email even if you rarely open the app.';

  @override
  String get notiEmailToggle => 'Receive emails';

  @override
  String get notiEmailNone => 'No email registered';

  @override
  String get notiEmailFreq => 'Frequency';

  @override
  String get notiEmailDaily => 'Daily';

  @override
  String get notiEmailWeekly => 'Weekly';

  @override
  String get notiEmailMonthly => 'Monthly';

  @override
  String get presetManageTitle => 'Manage presets';

  @override
  String get presetLoadError => 'Failed to load presets';

  @override
  String get presetDeleteTitle => 'Delete preset';

  @override
  String presetDeleteConfirm(String name) {
    return 'Delete preset \"$name\"? Already saved transactions are unaffected.';
  }

  @override
  String get presetDeleted => 'Preset deleted';

  @override
  String get presetDeleteFailed => 'Delete failed';

  @override
  String get presetIntroTitle => 'What is a preset?';

  @override
  String get presetIntroBody =>
      'Save frequently used entries (lunch, coffee, transit, etc.) so you can fill in category, payment method, and details with one tap on the add screen. Handy for saving single entries by just changing the amount.';

  @override
  String get presetStatSaved => 'Saved presets';

  @override
  String get presetStatUses => 'Total uses';

  @override
  String presetUsesCount(int count) {
    return '$count×';
  }

  @override
  String get presetStatType => 'Expense / Income';

  @override
  String get presetSortUsed => 'Most used';

  @override
  String get presetSortRecent => 'Recently used';

  @override
  String get presetSortName => 'By name';

  @override
  String get presetAdd => 'Add preset';

  @override
  String get presetAmountEmpty => 'No amount';

  @override
  String get presetNoCategory => 'No category';

  @override
  String get presetEmptyTitle => 'No saved presets';

  @override
  String get presetEmptyDesc =>
      'Add frequently used entries to save yourself repetitive input.';

  @override
  String get presetEditTitle => 'Edit preset';

  @override
  String get presetSubmitAdd => 'Add';

  @override
  String get presetName => 'Preset name';

  @override
  String get presetMerchant => 'Default details';

  @override
  String get presetMerchantPlaceholder => 'e.g. Hansot lunchbox';

  @override
  String get presetSelectNone => 'None';

  @override
  String get presetAssetCard => 'Account / Card';

  @override
  String get presetAssetLoadError => 'Failed to load assets';

  @override
  String get presetLockToggle => 'Use fixed amount';

  @override
  String get presetLockDesc =>
      'When off, the amount is empty on load. Handy when the amount varies each time.';

  @override
  String get presetLockAmountLabel => 'Fixed amount';

  @override
  String get presetUpdated => 'Preset updated';

  @override
  String get presetCreated => 'Preset added';

  @override
  String get recurringToggleFailed => 'Change failed';

  @override
  String get recurringDeleteTitle => 'Delete recurring transaction';

  @override
  String recurringDeleteConfirm(String name) {
    return 'Delete the recurring setting for \"$name\"?\nAlready recorded transactions remain.';
  }

  @override
  String get recurringDeleteFailed => 'Delete failed';

  @override
  String get recurringLoadError => 'Failed to load recurring transactions';

  @override
  String get recurringAllList => 'All';

  @override
  String get recurringAdd => 'Add';

  @override
  String recurringFilterAll(int count) {
    return 'All $count';
  }

  @override
  String recurringFilterExpense(int count) {
    return 'Expense $count';
  }

  @override
  String recurringFilterIncome(int count) {
    return 'Income $count';
  }

  @override
  String recurringFilterPaused(int count) {
    return 'Paused $count';
  }

  @override
  String get recurringStatActive => 'Active';

  @override
  String recurringCount(int count) {
    return '$count';
  }

  @override
  String get recurringPaused => 'Paused';

  @override
  String get recurringMonthlyExpense => 'Monthly fixed expense';

  @override
  String get recurringMonthlyIncome => 'Monthly fixed income';

  @override
  String get recurringUpcoming => 'Next 7 days';

  @override
  String recurringUpcomingCount(int count) {
    return '$count upcoming';
  }

  @override
  String get recurringToday => 'Today';

  @override
  String get recurringNoAccount => 'No account';

  @override
  String recurringOccurrences(int executed, int max) {
    return '$executed/$max';
  }

  @override
  String get recurringNext => 'Next';

  @override
  String get recurringStart => 'Start';

  @override
  String get recurringEmpty => 'No matching recurring transactions';

  @override
  String get recurringIndefinite => 'Indefinite';

  @override
  String get recurringNotifyShort => 'Alert';

  @override
  String get recurringAddTitle => 'Add recurring transaction';

  @override
  String get recurringSaveSubmit => 'Save recurring';

  @override
  String get recurringUpdated => 'Recurring setting updated';

  @override
  String get recurringSaved => 'Recurring setting saved';

  @override
  String get recurringSaveFailed => 'Save failed';

  @override
  String get recurringIntro =>
      'Automatically repeat this transaction on a set cycle. Great for subscriptions, rent, regular donations, etc.';

  @override
  String get recurringFrequencyLabel => 'Frequency';

  @override
  String get recurringDayOfWeekLabel => 'Day of week';

  @override
  String get recurringDayOfMonthLabel => 'Day of month';

  @override
  String get recurringDayNote =>
      'Months without this day are handled on the last day';

  @override
  String get recurringEndLabel => 'End';

  @override
  String get recurringIndefiniteDesc => 'Repeat until stopped';

  @override
  String get recurringByCount => 'By count';

  @override
  String get recurringTotal => 'Total';

  @override
  String get recurringTimesUnit => 'times';

  @override
  String get recurringByDate => 'By end date';

  @override
  String get recurringOptions => 'Options';

  @override
  String get recurringAutoLog => 'Auto-record';

  @override
  String get recurringAutoLogDesc =>
      'Automatically add the transaction on the date';

  @override
  String get recurringNotifyDayBefore => 'Day-before alert';

  @override
  String get recurringNotifyDesc =>
      'Send an alert the day before the payment/transfer';

  @override
  String get recurringNextDates => 'Next dates';

  @override
  String get recurringSourceSub =>
      'For subscriptions·rent and other regular payments';

  @override
  String recurringStartFrom(String date) {
    return 'Starts $date';
  }

  @override
  String get recurringMerchant => 'Merchant';

  @override
  String get recurringMerchantPlaceholder => 'e.g. Netflix';

  @override
  String get recurringAssetCard => 'Account / Card';

  @override
  String get recurringAssetLoadError => 'Failed to load assets';

  @override
  String get recurringSelectNone => 'None';

  @override
  String get recurringStartDateLabel => 'Start date';

  @override
  String recurringParentCategory(String name) {
    return '$name (parent)';
  }

  @override
  String get savingGoalLoadError => 'Failed to load saving goals';

  @override
  String get savingGoalOverallProgress => 'Overall progress';

  @override
  String savingGoalListCount(int n) {
    return 'Goals · $n';
  }

  @override
  String get savingGoalAddAction => 'Add goal';

  @override
  String get savingGoalManagePrompt => 'Add saving goals in Settings';

  @override
  String get savingGoalManageLink => 'Manage';

  @override
  String get savingGoalNoDeadline => 'No deadline';

  @override
  String get savingGoalCurrentLabel => 'Amount saved';

  @override
  String get savingGoalIconLabel => 'Icon';

  @override
  String get savingGoalEmpty => 'No saving goals yet. Start with ‘Add goal’.';

  @override
  String get savingGoalActionFailed => 'Failed';

  @override
  String get savingGoalAchieved => 'Achieved!';

  @override
  String get savingGoalAdd => 'Add saving goal';

  @override
  String get savingGoalEdit => 'Edit saving goal';

  @override
  String get savingGoalSubmitAdd => 'Add';

  @override
  String get savingGoalDeleteTitle => 'Delete saving goal';

  @override
  String savingGoalDeleteConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get savingGoalDeleteFailed => 'Delete failed';

  @override
  String get savingGoalNameLabel => 'Goal name';

  @override
  String get savingGoalNameHint => 'e.g. Emergency fund';

  @override
  String get savingGoalAmountLabel => 'Target amount';

  @override
  String get savingGoalDeadlineLabel => 'Deadline (optional)';

  @override
  String get savingGoalDeadlineHint => 'Not set';

  @override
  String get savingGoalColorLabel => 'Color';

  @override
  String get searchAdvancedFilter => 'Advanced filter';

  @override
  String get searchHint => 'Search transactions...';

  @override
  String get searchStartHint => 'Start';

  @override
  String get searchEndHint => 'End';

  @override
  String get searchFailed => 'Search failed';

  @override
  String get searchEmptyHint => 'Search by keyword, merchant, or note';

  @override
  String get searchNoResults => 'No results';

  @override
  String get statsTabTrend => 'Trend';

  @override
  String get statsTabCompare => 'Compare';

  @override
  String get statsThisQuarter => 'This quarter';

  @override
  String get statsThisYear => 'This year';

  @override
  String get statsCustomPeriod => 'Selected period';

  @override
  String get statsLastMonth => 'Last month';

  @override
  String get statsLastQuarter => 'Last quarter';

  @override
  String get statsLastYear => 'Last year';

  @override
  String get statsPrevPeriod => 'Previous period';

  @override
  String get statsMomMonth => 'vs last month';

  @override
  String get statsMomQuarter => 'vs last quarter';

  @override
  String get statsMomYear => 'vs last year';

  @override
  String get statsMomCustom => 'vs previous period';

  @override
  String get statsMomPrevMonth => 'Last month';

  @override
  String get statsMomPrevQuarter => 'Last quarter';

  @override
  String get statsMomPrevYear => 'Last year';

  @override
  String get statsDailyAvg => 'Daily average';

  @override
  String get statsMonthlyAvg => 'Monthly average';

  @override
  String get statsPeriodPickerTitle => 'Select period';

  @override
  String get statsRange7d => 'Last 7 days';

  @override
  String get statsRange30d => 'Last 30 days';

  @override
  String get statsRange3m => 'Last 3 months';

  @override
  String get statsRange6m => 'Last 6 months';

  @override
  String get statsRange1y => 'Last 1 year';

  @override
  String get statsSegMonth => 'Month';

  @override
  String get statsSegQuarter => 'Quarter';

  @override
  String get statsSegYear => 'Year';

  @override
  String get statsSegCustom => 'Custom';

  @override
  String get statsNoData => 'No data';

  @override
  String get statsNoDataShort => 'No data';

  @override
  String get statsUnassigned => 'Unassigned';

  @override
  String statsCategoryDetail(String name) {
    return '$name detail';
  }

  @override
  String statsPeriodSpending(String period) {
    return '$period spending';
  }

  @override
  String get statsSpendingByCategory => 'Spending by category';

  @override
  String get statsNoCategoryData => 'No category data';

  @override
  String get statsTopMerchantsTitle => 'Top 5 merchants';

  @override
  String get statsNoMerchantData => 'No merchant data';

  @override
  String get statsNoName => '(No name)';

  @override
  String get statsTimeMorning => 'Morning';

  @override
  String get statsTimeLunch => 'Lunch';

  @override
  String get statsTimeAfternoon => 'Afternoon';

  @override
  String get statsTimeEvening => 'Evening';

  @override
  String get statsTimeLateNight => 'Late night';

  @override
  String get statsTimeDawn => 'Dawn';

  @override
  String get statsPatternTitle => 'Spending pattern by day & time';

  @override
  String get statsPatternDesc =>
      'Darker cells mean more spending in that time slot (unit: KRW)';

  @override
  String get statsTooFewTx => 'Too few transactions this month';

  @override
  String get statsLegendLow => 'Low';

  @override
  String get statsLegendHigh => 'High';

  @override
  String get statsTotalPrefix => 'Total';

  @override
  String statsDaysTotal(int days) {
    return '$days-day total';
  }

  @override
  String get statsMomCalculating => 'Calculating vs last month…';

  @override
  String get statsMomUnavailable => 'Comparison unavailable';

  @override
  String get statsTopCategory => 'Top spending category';

  @override
  String get statsTopMerchant => 'Top merchant';

  @override
  String get statsIncomeExpenseTrend => 'Income & expense trend';

  @override
  String get statsNoTrendData => 'No trend data';

  @override
  String get statsAvgIncome => 'Avg income';

  @override
  String get statsAvgExpense => 'Avg expense';

  @override
  String get statsNetSavings => 'Net savings';

  @override
  String get statsAvgSavings => 'Avg savings';

  @override
  String get statsSavingsRate => 'Savings rate';

  @override
  String statsSavingsInsight(int pct) {
    return 'You\'re saving $pct% of your average income';
  }

  @override
  String get statsDailyNetSavings => 'Daily net savings';

  @override
  String get statsMonthlyNetSavings => 'Monthly net savings';

  @override
  String get statsCatTrendTitle => 'Top categories over time';

  @override
  String get statsCatTrendTop3 => 'Top 3 spending';

  @override
  String get statsIncomeMinusExpense => 'Income − Expense';

  @override
  String statsNoDataFor(String period) {
    return 'No data for $period';
  }

  @override
  String statsCategoryByMom(String mom) {
    return 'By category, $mom';
  }

  @override
  String get statsCategoryDelta => 'Change by category';

  @override
  String get statsSortByChange => 'Biggest changes';

  @override
  String get statsNoCompareData => 'No data to compare';

  @override
  String get statsWeekdayTitle => 'Spending by weekday';

  @override
  String get statsThisMonthShort => 'This month';

  @override
  String get statsLastMonthShort => 'Last month';

  @override
  String statsWeekdayInsightDown(String day, String amount) {
    return '$day spending dropped by $amount vs last month.';
  }

  @override
  String statsWeekdayInsightUp(String day, String amount) {
    return '$day spending rose by $amount vs last month.';
  }

  @override
  String get statsWeekdayInsightSame =>
      'Weekday spending is similar to last month.';

  @override
  String statsVsLastPrefix(String prev) {
    return 'You spent';
  }

  @override
  String get statsVsLastDirLess => 'less';

  @override
  String get statsVsLastDirMore => 'more';

  @override
  String statsVsLastSuffix(String prev) {
    return 'than $prev';
  }

  @override
  String get statsCompareDailyAvg => 'Daily average';

  @override
  String get statsCompareTxCount => 'Transactions';

  @override
  String get statsComparePerTx => 'Per transaction';

  @override
  String statsCountValue(int count) {
    return '$count';
  }

  @override
  String get stocksChartTokenFailed => 'Failed to issue token';

  @override
  String get stocksChartHttpsError =>
      'Security error: chart WebView is not HTTPS';

  @override
  String get stocksChartInitFailed => 'Chart initialization failed';

  @override
  String get stocksChartLoadFailed => 'Couldn\'t load chart';

  @override
  String get stocksSearch => 'Search stocks';

  @override
  String get stocksSearchPlaceholder =>
      'Search by name or ticker (e.g. Samsung Electronics, NVDA)';

  @override
  String stocksSearchNoResults(String query) {
    return 'No results for \'$query\'';
  }

  @override
  String stocksTabHoldings(int count) {
    return 'Holdings $count';
  }

  @override
  String stocksTabWatch(int count) {
    return 'Watchlist $count';
  }

  @override
  String get stocksTabDiscover => 'Discover';

  @override
  String get stocksNoHoldings => 'You have no holdings.';

  @override
  String stocksSharesHeld(String qty) {
    return 'Holding $qty shares';
  }

  @override
  String get stocksRange1d => '1D';

  @override
  String get stocksRange1w => '1W';

  @override
  String get stocksRange1m => '1M';

  @override
  String get stocksRange3m => '3M';

  @override
  String get stocksRange1y => '1Y';

  @override
  String stocksUnitCount(int count) {
    return '$count';
  }

  @override
  String stocksSharesUnit(String qty) {
    return '$qty shares';
  }

  @override
  String get stocksTradingSuspended => 'Suspended';

  @override
  String get stocksTradingNormal => 'Normal';

  @override
  String get stocksWarningLiquidationTrading => 'Liquidation trading';

  @override
  String get stocksWarningOverheated => 'Overheated';

  @override
  String get stocksWarningShortTermOverheat => 'Short-term overheat';

  @override
  String get stocksWarningExcessiveRise => 'Excessive rise';

  @override
  String get stocksWarningInvestmentWarning => 'Investment warning';

  @override
  String get stocksWarningInvestmentRisk => 'Investment risk';

  @override
  String get stocksWarningInvestmentCaution => 'Investment caution';

  @override
  String get stocksWarningVi => 'Volatility interruption';

  @override
  String get stocksWarningViStatic => 'Static VI';

  @override
  String get stocksWarningViDynamic => 'Dynamic VI';

  @override
  String get stocksWarningStockWarrants => 'Stock warrants';

  @override
  String get stocksWarningAdministrative => 'Administrative issue';

  @override
  String get stocksWarningAdjustmentOfShares => 'Share adjustment';

  @override
  String get stocksNoWatchlist => 'No watchlist. Search and tap the star.';

  @override
  String get stocksDetailTitle => 'Stock details';

  @override
  String get stocksMarketHoliday => 'Holiday';

  @override
  String stocksMarketTrading(String time) {
    return 'Open · $time';
  }

  @override
  String stocksMarketOpensAt(String time) {
    return 'Opens $time';
  }

  @override
  String get stocksMarketClosed => 'Closed';

  @override
  String get stocksMarketKr => 'Domestic';

  @override
  String get stocksMarketUs => 'US';

  @override
  String get stocksConnectPrompt => 'Please connect a securities account';

  @override
  String get stocksConnectDescRealtime =>
      'Connect your Toss Securities key to see quotes, holdings, and P&L in real time.';

  @override
  String get stocksConnectInSettings => 'Connect in settings';

  @override
  String get stocksConnectDesc =>
      'Connect your Toss Securities key to see holdings and P&L.';

  @override
  String get stocksConnectAccount => 'Connect account';

  @override
  String get stocksMyEval => 'My portfolio value';

  @override
  String get stocksConnectShowAssets =>
      'Connect a securities account to see your assets';

  @override
  String get stocksPurchaseAmount => 'Cost basis';

  @override
  String get stocksHoldingsLabel => 'Holdings';

  @override
  String get stocksExchangeRate => 'Exchange rate (USD)';

  @override
  String get stocksSell => 'Sell';

  @override
  String stocksSellOrderStub(String name) {
    return '$name sell order — works when Open API is connected';
  }

  @override
  String get stocksBuy => 'Buy';

  @override
  String stocksBuyOrderStub(String name) {
    return '$name buy order — works when Open API is connected';
  }

  @override
  String get stocksFeeUs =>
      'US stock trading fee 0.1% · FX fee applies separately';

  @override
  String get stocksFeeKr =>
      'Domestic stock trading free (until Jun 2026) · then KRX 0.015% / NXT 0.014%';

  @override
  String get stocksOrderDisclaimer =>
      'Real-time quotes and prices apply once Toss Securities Open API is connected.\nQuotes are for reference only; actual orders require agreeing to the terms.';

  @override
  String get stocksEvalAmount => 'Market value';

  @override
  String get stocksEvalPnl => 'Unrealized P&L';

  @override
  String get stocksQuantityHeld => 'Quantity held';

  @override
  String get stocksReturnRate => 'Return';

  @override
  String get stocksDayPnl => 'Daily P&L';

  @override
  String get stocksAvgPrice => 'Average price';

  @override
  String get stocksFeesTax => 'Fees & taxes';

  @override
  String get stocksSellable => 'Sellable';

  @override
  String get stocksMyHoldings => 'My holdings';

  @override
  String get stocksMarket => 'Market';

  @override
  String get stocksInstrumentType => 'Instrument type';

  @override
  String get stocksInstrumentStock => 'Stock';

  @override
  String get stocksCurrency => 'Currency';

  @override
  String get stocksMarketCap => 'Market cap';

  @override
  String get stocksUpperLimit => 'Upper limit';

  @override
  String get stocksLowerLimit => 'Lower limit';

  @override
  String get stocksListingDate => 'Listing date';

  @override
  String get stocksSharesOutstanding => 'Shares outstanding';

  @override
  String get stocksTradingStatus => 'Trading status';

  @override
  String get stocksBasicInfo => 'Basic info';

  @override
  String get stocksBidVolume => 'Bid volume';

  @override
  String get stocksAskVolume => 'Ask volume';

  @override
  String get stocksGainers => 'Top gainers';

  @override
  String get stocksLosers => 'Top losers';

  @override
  String get stocksVolume => 'Volume';

  @override
  String get stocksOrderbookLoading => 'Loading order book…';

  @override
  String get stocksOrderbookEmpty => 'No order book data';

  @override
  String get stocksTradesLoading => 'Loading trades…';

  @override
  String get stocksTradesEmpty => 'No trades';

  @override
  String get stocksOrderbook => 'Order book';

  @override
  String get stocksTrades => 'Trades';

  @override
  String get stocksTradeTime => 'Time';

  @override
  String get stocksTradePrice => 'Price';

  @override
  String get stocksTradeVolume => 'Volume';

  @override
  String get stocksDailyPrices => 'Daily prices';

  @override
  String get stocksDailyPricesLoading => 'Loading daily prices…';

  @override
  String get stocksDailyPricesEmpty => 'No daily prices';

  @override
  String get stocksDate => 'Date';

  @override
  String get stocksClosePrice => 'Close';

  @override
  String get stocksChangeRate => 'Change';

  @override
  String get stocksSearchHint =>
      'Search by name or symbol (KR + US·CN·JP·HK·VN)';

  @override
  String get stocksPriceUnavailable =>
      'Price unavailable via Toss (KR·US only)';

  @override
  String get stocksRankingLoading => 'Loading rankings…';

  @override
  String get stocksRankingEmpty => 'No rankings available';

  @override
  String get stocksWatchDefaultGroupName => 'Watchlist';

  @override
  String get stocksWatchGroupAdd => 'Add group';

  @override
  String get stocksWatchGroupRename => 'Rename group';

  @override
  String get stocksWatchGroupDelete => 'Delete group';

  @override
  String get stocksWatchGroupNamePlaceholder => 'Group name';

  @override
  String get stocksWatchGroupDeleteConfirm =>
      'The group and its stocks will be removed. Continue?';

  @override
  String get stocksWatchGroupSaveFail => 'Failed to save watchlist group';

  @override
  String get stocksWatchAddFail => 'Failed to add to watchlist';

  @override
  String get stocksMarketToggleKr => 'KR';

  @override
  String get stocksMarketToggleUs => 'US';

  @override
  String get todoAdd => 'Add todo';

  @override
  String get todoEditTitle => 'Edit todo';

  @override
  String get todoDeleteTitle => 'Delete todo';

  @override
  String todoDeleteConfirm(String title) {
    return 'Delete \"$title\"?';
  }

  @override
  String get todoDetail => 'Details';

  @override
  String get todoCompletionRate => 'Completion rate';

  @override
  String get todoQuickAddPlaceholder => 'Type a todo and press Enter';

  @override
  String get todoTitlePlaceholder => 'Write a todo';

  @override
  String get todoTitleRequired => 'Please enter a title';

  @override
  String get todoDueDate => 'Due date';

  @override
  String get todoUnset => 'Not set';

  @override
  String get todoTag => 'Tag';

  @override
  String get todoTagSelect => 'Select tag';

  @override
  String get todoPriorityLabel => 'Priority';

  @override
  String get todoPriorityImportant => 'High';

  @override
  String get todoPriorityRelaxed => 'Low';

  @override
  String get todoContentLabel => 'Details (optional)';

  @override
  String get todoContentPlaceholder =>
      'e.g. # Heading / **bold** / - item / - [ ] check';

  @override
  String get todoEditMode => 'Edit';

  @override
  String get todoPreview => 'Preview';

  @override
  String get todoNoContent => 'No content';

  @override
  String get todoEmptyToday => 'Nothing due today';

  @override
  String get todoEmptyWeek => 'A light week ahead';

  @override
  String get todoEmptyDone => 'Nothing completed yet';

  @override
  String get todoEmptyAll => 'No todos';

  @override
  String get todoEmptyDoneHint => 'Completed todos appear here.';

  @override
  String get todoEmptyAddHint => 'Add one quickly using the field above.';

  @override
  String get todoNewProject => 'New project';

  @override
  String get todoProjectNamePlaceholder => 'Project name';

  @override
  String get todoDescOptional => 'Description (optional)';

  @override
  String get todoAdding => 'Adding…';

  @override
  String get todoAddProject => 'Add project';

  @override
  String get todoRegisteredProjects => 'Projects';

  @override
  String get todoNoProjects => 'No projects';

  @override
  String get todoDeleteProjectTitle => 'Delete project';

  @override
  String todoDeleteProjectConfirm(String name) {
    return 'Delete project \"$name\"? Linked todos will be set to no project.';
  }

  @override
  String get todoNewTag => 'New tag';

  @override
  String get todoTagNamePlaceholder => 'Tag name';

  @override
  String get todoRegisteredTags => 'Tags';

  @override
  String get todoNoTags => 'No tags';

  @override
  String get todoDeleteTagTitle => 'Delete tag';

  @override
  String todoDeleteTagConfirm(String name) {
    return 'Delete tag \"$name\"?';
  }

  @override
  String get todoActionFailed => 'Failed';

  @override
  String get todoAddFailed => 'Add failed';

  @override
  String get todoDeleteFailed => 'Delete failed';

  @override
  String get todoUpdateFailed => 'Update failed';

  @override
  String get todoStatusChangeFailed => 'Status change failed';

  @override
  String get todoMoveFailed => 'Move failed';

  @override
  String get todoLoadError => 'Failed to load todos';

  @override
  String get todoProjectLoadError => 'Failed to load projects';

  @override
  String get todoTagLoadError => 'Failed to load tags';

  @override
  String get todoSubtaskLoadError => 'Failed to load subtasks';

  @override
  String get subManageTitle => 'Manage subscription';

  @override
  String get subUsingPro => 'On Porest Pro';

  @override
  String get subUsingFree => 'On the Free plan';

  @override
  String subNextBilling(String date, String amount) {
    return 'Next billing $date · $amount';
  }

  @override
  String get subFreeLockedDesc =>
      'Pro features like securities and import are locked';

  @override
  String get subSpotlightTitle => 'Securities investing is Pro-only';

  @override
  String get subSpotlightDesc =>
      'Real-time quotes and order book, domestic and overseas ticker search, watchlists, and holding P&L — subscribe to Pro and the Securities tab opens right away.';

  @override
  String get subCycleMonthly => 'Monthly';

  @override
  String subCycleYearlyOff(int pct) {
    return 'Yearly $pct% off';
  }

  @override
  String get subUnitMonth => 'mo';

  @override
  String get subUnitYear => 'yr';

  @override
  String subYearlyPerMonth(String amount, int pct) {
    return '≈ $amount/mo · Save $pct%';
  }

  @override
  String get subMonthlyBilling => 'Billed monthly';

  @override
  String get subFeatureCompare => 'Feature comparison';

  @override
  String get subCurrentPlan => 'Current plan';

  @override
  String get subFreeCaption => 'Basic ledger features';

  @override
  String get subFeatureColumn => 'Feature';

  @override
  String get subFeatLedger => 'Ledger · asset management';

  @override
  String get subFeatBudget => 'Budget · savings goals · calendar';

  @override
  String get subFeatMonthlyTx => 'Monthly transaction records';

  @override
  String get subFeatTxLimit => '100';

  @override
  String get subFeatUnlimited => 'Unlimited';

  @override
  String get subFeatSecurities =>
      'Securities — real-time quotes · ticker search · watchlist';

  @override
  String get subFeatImportExport => 'CSV · Excel import / export';

  @override
  String get subFeatCalendarShare => 'Shared multi-calendar';

  @override
  String get subFeatCardRec => 'Card benefit recommendations';

  @override
  String get subStarted => 'Your Porest Pro subscription is active';

  @override
  String get subFailed => 'Couldn\'t start the subscription';

  @override
  String get subCancelConfirmTitle => 'Cancel your subscription?';

  @override
  String subCancelConfirmMsg(String date) {
    return 'If you cancel, you will switch to the Free plan from $date and the Securities tab will lock. You can keep using Pro features until then.';
  }

  @override
  String get subCancel => 'Cancel subscription';

  @override
  String get subKeep => 'Keep';

  @override
  String get subCanceled => 'Subscription canceled';

  @override
  String get subCancelFailed => 'Couldn\'t cancel';

  @override
  String get subNextBillingDate => 'Next billing date';

  @override
  String get subProcessing => 'Processing…';

  @override
  String get subStartPro => 'Start Pro';

  @override
  String get subTossSectionTitle => 'Securities data link';

  @override
  String get subTossConnectTitle => 'Connect Toss Securities';

  @override
  String get subTossConnectDesc =>
      'Register your API key to auto-import your holdings and prices';

  @override
  String get subConnected => 'Connected';

  @override
  String subTossLastVerified(String date) {
    return 'Last verified · $date';
  }

  @override
  String get subTossCollecting => 'Auto-collecting holdings and prices';

  @override
  String get subTossKeyConnected => 'Toss Securities API key connected';

  @override
  String get subTossIdPlaceholder =>
      'Client ID issued by Toss Securities Developer Center';

  @override
  String get subConnecting => 'Connecting…';

  @override
  String get subConnect => 'Connect';

  @override
  String get subTossConnected => 'Connected your Toss Securities account';

  @override
  String get subTossInvalidCred => 'Those credentials aren\'t valid';

  @override
  String get subTossDisconnected => 'Disconnected from Toss Securities';

  @override
  String get subDisconnectFailed => 'Couldn\'t disconnect';

  @override
  String get subTossKeyNotice =>
      'Your key is stored encrypted on the server and used only by you. Issue one at the Toss Securities Developer Center.';

  @override
  String get memoNew => 'New memo';

  @override
  String get memoEditTitle => 'Edit memo';

  @override
  String get memoAdd => 'Add';

  @override
  String get memoLoadError => 'Failed to load memos';

  @override
  String memoTagAll(int count) {
    return 'All $count';
  }

  @override
  String memoSectionPinned(int count) {
    return 'Pinned · $count';
  }

  @override
  String memoSectionAll(int count) {
    return 'All memos · $count';
  }

  @override
  String memoActionFailed(String message) {
    return 'Failed: $message';
  }

  @override
  String get memoEmptyDesc =>
      'When something comes to mind, create a new memo.';

  @override
  String get memoSearchEmptyDesc => 'Try a different search term.';

  @override
  String get memoUntitled => '(Untitled)';

  @override
  String get memoDeleteTitle => 'Delete memo';

  @override
  String get memoDeleteConfirm => 'Delete this memo?';

  @override
  String memoDeleteFailed(String message) {
    return 'Delete failed: $message';
  }

  @override
  String get memoFieldTitle => 'Title';

  @override
  String get memoTitleRequired => 'Please enter a title';

  @override
  String get memoFieldContent => 'Content';

  @override
  String get memoContentPlaceholder => 'Write your memo here';

  @override
  String get memoFieldTag => 'Tag';

  @override
  String get memoPinToTop => 'Pin to top';

  @override
  String get memoFieldColor => 'Color';

  @override
  String get dateToday => 'Today';

  @override
  String get dateTomorrow => 'Tomorrow';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateInDays(int n) {
    return 'in $n days';
  }

  @override
  String dateDaysAgo(int n) {
    return '$n days ago';
  }

  @override
  String get dateJustNow => 'Just now';

  @override
  String dateMinutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String dateHoursAgo(int n) {
    return '$n hr ago';
  }

  @override
  String get todoNoDue => 'No due date';

  @override
  String todoGroupLabel(String label, int count) {
    return '$label · $count';
  }

  @override
  String dayN(int d) {
    return 'Day $d';
  }

  @override
  String weekN(int n) {
    return 'W$n';
  }

  @override
  String get countUnit => '';

  @override
  String get dayUnit => 'day';

  @override
  String get constHeroTodayTarget => 'Today\'s constellation';

  @override
  String constHeroCollectedBang(String name) {
    return '$name collected!';
  }

  @override
  String constHeroStarlightCount(int lit, int goal) {
    return '$lit/$goal starlight';
  }

  @override
  String get constHeroCaptionDone =>
      'Etched in your collection · shines brighter as you complete more';

  @override
  String constHeroCaptionProgress(int count) {
    return '$count done today';
  }

  @override
  String constHeroCaptionMemo(int count) {
    return 'Memo starlight +$count';
  }

  @override
  String constHeroCaptionRemain(int count) {
    return '$count stars to go';
  }

  @override
  String get constHeroCaptionEmpty => 'Complete todos to light up the stars';

  @override
  String constHeroStreak(int count) {
    return '$count-day streak';
  }

  @override
  String constHeroGuardInfo(int count) {
    return 'Guard $count · High +3 · Medium +2 · Low +1';
  }

  @override
  String get constMySkyTitle => 'My Night Sky';

  @override
  String constMySkyTotal(int count) {
    return '$count collected';
  }

  @override
  String get constMySkySubtitle => 'Last 2 weeks · cloudy nights count too';

  @override
  String get constCollectionTitle => 'Constellation Collection';

  @override
  String constCollectionProgress(int collected, int total) {
    return '$collected/$total collected';
  }

  @override
  String get constCollectionSubtitle =>
      'Gather starlight equal to the stars to collect';

  @override
  String get constCollectionTodayBadge => 'Today\'s goal';

  @override
  String constCollectionStarCount(int count) {
    return '$count stars';
  }

  @override
  String constCollectionTimes(int count) {
    return '$count×';
  }

  @override
  String get constCollectionNotCollected => 'Not yet';

  @override
  String get constDetailTitle => 'Constellation Collection';

  @override
  String get constDetailNotMet => 'A constellation you haven\'t met yet';

  @override
  String constDetailCollectedTimes(int count) {
    return 'Collected $count times so far';
  }

  @override
  String constDetailHint(int count) {
    return 'Gather $count starlight in a day to collect · a new target rises daily';
  }

  @override
  String get todoDetailTitle => 'To-do details';

  @override
  String get todoDetailStatus => 'Status';

  @override
  String get todoStatusPending => 'Pending';

  @override
  String get todoDetailCompletedAt => 'Completed at';

  @override
  String get todoDetailContent => 'Details';

  @override
  String get memoDetailTitle => 'Memo details';

  @override
  String get memoDetailPinned => 'Pinned';

  @override
  String get memoDetailNoContent => 'No content';

  @override
  String get calEventDetailTitle => 'Event details';

  @override
  String get calDetailNone => 'None';

  @override
  String get exportTab => 'Export';

  @override
  String get importTab => 'Import';

  @override
  String get importSourceTitle => 'Which app are you importing from?';

  @override
  String get importSourceDesc =>
      'Pick your previous app and we\'ll auto-map the columns';

  @override
  String get importSourcePorest => 'Porest backup';

  @override
  String get importSourcePorestDesc => 'Re-import an export file';

  @override
  String get importSourceEasybudget => 'EasyBudget · Money Manager';

  @override
  String get importSourceEasybudgetDesc => 'Excel backup';

  @override
  String get importSourceBanksalad => 'Banksalad';

  @override
  String get importSourceBanksaladDesc => 'Ledger export';

  @override
  String get importSourceToss => 'Toss';

  @override
  String get importSourceTossDesc => 'Transactions';

  @override
  String get importSourceCustom => 'Custom';

  @override
  String get importSourceCustomDesc => 'Map CSV/Excel yourself';

  @override
  String get importUploadTitle => 'Upload file';

  @override
  String get importUploadDesc =>
      'Upload a CSV or Excel (.xlsx, .xls) file. Up to 10MB.';

  @override
  String get importDropTitle => 'Choose a file';

  @override
  String get importDropHint => '.csv · .xlsx · .xls supported';

  @override
  String get importAnalyzing => 'Analyzing…';

  @override
  String get importNotice =>
      'Imported data is added to existing transactions without overwriting. Check duplicates and errors in the preview.';

  @override
  String get importFileTitle => 'File to import';

  @override
  String importRowsDetected(int total, int valid) {
    return '$total rows · $valid valid';
  }

  @override
  String get importChange => 'Change';

  @override
  String get importMapTitle => 'Column mapping';

  @override
  String get importMapDesc =>
      'Connect file columns to ledger fields. Adjust the auto-detected values.';

  @override
  String get importNotMapped => 'Don\'t import';

  @override
  String get importFieldSubcategory => 'Subcategory';

  @override
  String get importFieldTime => 'Time';

  @override
  String get importFieldMerchant => 'Merchant';

  @override
  String get importFieldPaymentMethod => 'Payment method';

  @override
  String importBlockedTitle(String names) {
    return 'Cannot create subcategories under $names — it already has transactions';
  }

  @override
  String get importBlockedDesc =>
      'Rows using it will fail. Move its transactions into a subcategory or change the category in the file';

  @override
  String get categoryMoveTxAction => 'Move';

  @override
  String get categoryMoveTxTitle => 'Move transactions';

  @override
  String get categoryMoveTxEntry => 'Move transactions';

  @override
  String get categoryMoveTxEntryDesc =>
      'A category with transactions cannot have subcategories. Move them to enable it';

  @override
  String categoryMoveTxDesc(String name) {
    return 'Moves all transactions, recurring and splits from $name';
  }

  @override
  String get categoryMoveTxModeNew => 'Create subcategory';

  @override
  String get categoryMoveTxModeExisting => 'Move to existing';

  @override
  String get categoryMoveTxChildName => 'New subcategory name';

  @override
  String get categoryMoveTxChildPlaceholder => 'e.g. Lectures';

  @override
  String categoryMoveTxNewHint(String name) {
    return 'Creates it under $name and moves all transactions there, so you can add more subcategories';
  }

  @override
  String get categoryMoveTxTarget => 'Target category';

  @override
  String get categoryMoveTxTargetPlaceholder => 'Select a category';

  @override
  String get categoryMoveTxHint =>
      'Only leaf categories of the same type can be selected';

  @override
  String get categoryMoveTxNoTarget => 'No target available — create one first';

  @override
  String categoryMoveTxDone(int count) {
    return 'Moved $count items';
  }

  @override
  String get importFieldDate => 'Date';

  @override
  String get importFieldType => 'Income/Expense';

  @override
  String get importFieldAmount => 'Amount';

  @override
  String get importFieldCategory => 'Category';

  @override
  String get importFieldAsset => 'Asset/Method';

  @override
  String get importFieldMemo => 'Memo';

  @override
  String importPreviewDesc(int dup) {
    return '$dup possible duplicates';
  }

  @override
  String get importIncome => 'Income';

  @override
  String get importExpense => 'Expense';

  @override
  String get importDupBadge => 'Dup?';

  @override
  String get importOptionsTitle => 'Import options';

  @override
  String get importOptDupSkip => 'Skip duplicate transactions';

  @override
  String importOptDupSkipDesc(int dup) {
    return 'Excludes $dup rows with same date, amount and content';
  }

  @override
  String get importOptAutoCat => 'Auto-create new categories';

  @override
  String get importOptAutoCatDesc =>
      'Missing categories are created automatically';

  @override
  String get importPrev => 'Back';

  @override
  String importDoImport(int count) {
    return 'Import $count';
  }

  @override
  String get importDoneTitle => 'Import complete';

  @override
  String importDoneCount(int count) {
    return 'Imported $count';
  }

  @override
  String importDoneDetail(int skipped, int failed) {
    return '$skipped skipped · $failed failed';
  }

  @override
  String get importAnother => 'Import another file';

  @override
  String get importStepUpload => 'Choose file';

  @override
  String get importStepMapping => 'Map columns';

  @override
  String get importStepDone => 'Done';

  @override
  String get calDetailDday => 'D-DAY';

  @override
  String calDetailDdayLeft(int n) {
    return 'D-$n';
  }

  @override
  String calDetailDdayPast(int n) {
    return '${n}d ago';
  }

  @override
  String calDetailDurationH(int h) {
    return '${h}h';
  }

  @override
  String calDetailDurationHM(int h, int m) {
    return '${h}h ${m}m';
  }

  @override
  String calDetailDurationM(int m) {
    return '${m}m';
  }

  @override
  String get calDetailMemo => 'Memo';

  @override
  String get calDetailRepeat => 'Repeat';

  @override
  String get categoryReorderEdit => 'Edit';

  @override
  String get categoryReorderHint =>
      'Drag the handle to reorder. Parents move among parents; subcategories move within their parent.';

  @override
  String get txmSpendSummary => 'Spending summary';

  @override
  String get txmInsightLessPre => 'Spending ';

  @override
  String txmInsightLessHl(String amount) {
    return '$amount less';
  }

  @override
  String get txmInsightLessPost => ' than last month';

  @override
  String get txmInsightMorePre => 'Spending ';

  @override
  String txmInsightMoreHl(String amount) {
    return '$amount more';
  }

  @override
  String get txmInsightMorePost => ' than last month';

  @override
  String get txmInsightSame => 'Spending about the same as last month';

  @override
  String get txmInsightNone => 'No transactions this month';

  @override
  String get txmInsightTopCatPre => 'Spent the most on ';

  @override
  String get txmInsightTopCatPost => ' this month';

  @override
  String txmPrevMonthBtn(String month) {
    return 'View $month history';
  }

  @override
  String txmEmptyMonth(String month) {
    return 'No transactions in $month';
  }

  @override
  String get txmEmptyMonthDesc =>
      'Browse another month or add your first transaction.';

  @override
  String get txmToday => 'Today';

  @override
  String get txmYesterday => 'Yesterday';

  @override
  String expChipMin(String amount) {
    return 'Min $amount';
  }

  @override
  String expChipMax(String amount) {
    return 'Max $amount';
  }

  @override
  String tdmTodayLeft(int count) {
    return '$count to-dos today';
  }

  @override
  String get tdmTodayDone => 'All done for today!';

  @override
  String get tdmNightSkyBtn => 'Night sky';

  @override
  String tdmStarlightHint(int lit, int goal, int left, String name) {
    return 'Starlight $lit/$goal · $left more to collect $name';
  }

  @override
  String tdmCollectedHint(String name, int streak) {
    return '$name collected · $streak-day streak';
  }

  @override
  String tdmDoneRatio(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get tdmFilterTag => 'Tags';

  @override
  String get tdmHideDone => 'Hide completed';

  @override
  String tdmEmptyMonth(String month) {
    return 'No to-dos in $month';
  }

  @override
  String get tdmEmptyMonthDesc => 'Add one with the + button below.';

  @override
  String get tdmEmptyFilter => 'No to-dos match the filters';

  @override
  String get tdmEmptyFilterDesc => 'Adjust or reset the filters.';

  @override
  String tdmStarToastGain(int gain, int left) {
    return 'Starlight +$gain · $left to collect';
  }

  @override
  String tdmStarToastCollected(int gain) {
    return 'Starlight +$gain · today\'s constellation collected!';
  }

  @override
  String get nightSkyTitle => 'Night sky';

  @override
  String get forestReportTitle => 'Observation report';

  @override
  String get fcolViewCta => 'View';

  @override
  String get fcolPreviewCta => 'Preview';

  @override
  String fcolLockedHint(int count) {
    return 'Gather $count starlight in one night to meet it.';
  }

  @override
  String get frpObsResult => 'Observation:';

  @override
  String frpObsToday(String name, int lit, int goal) {
    return '$name $lit/$goal in progress';
  }

  @override
  String frpObsCollected(String name) {
    return '$name collected!';
  }

  @override
  String get frpObsWithered => 'Cloudy night · streak kept by cloud guard';

  @override
  String get frpObsRest => 'A restful night';

  @override
  String frpStampDays(int count) {
    return 'Day $count';
  }

  @override
  String get frpStampLabel => 'streak!';

  @override
  String get frpStarGather => 'Starlight gathering';

  @override
  String frpPctBadge(int pct) {
    return '$pct% achieved';
  }

  @override
  String get frpTileStar => 'Starlight gathered';

  @override
  String frpTileStarVal(int count) {
    return '$count';
  }

  @override
  String get frpTileDone => 'To-dos completed';

  @override
  String frpTileDoneVal(int count) {
    return '$count';
  }

  @override
  String get frpAnalysis => 'Starlight analysis';

  @override
  String frpLegendItem(String label, int count) {
    return '$label done: $count';
  }

  @override
  String get frpMissed => 'Stars left unlit';

  @override
  String get frpMissedAllDone =>
      'You lit every star tonight. The rest waits for tomorrow!';

  @override
  String frpMissedCount(int count) {
    return '$count';
  }

  @override
  String get frpFuture => 'That night hasn\'t come yet';

  @override
  String frpAsOf(String ts) {
    return 'as of $ts';
  }

  @override
  String get settingsMenuTodoTag => 'To-do tags';

  @override
  String ttagUsage(int count) {
    return 'Used by $count to-dos';
  }

  @override
  String calLabelUsage(Object count) {
    return 'Used by $count events';
  }

  @override
  String get ttagEditTitle => 'Edit tag';

  @override
  String fcolOwnBadge(int count) {
    return 'Collected ×$count';
  }

  @override
  String get ttagTitle => 'Todo tags';

  @override
  String get ttagDesc =>
      'Tags you attach to to-dos. Used for list filters and tag breakdowns.';

  @override
  String get ttagAddCta => 'Add tag';

  @override
  String get ttagColorLabel => 'Color';

  @override
  String get ttagNameLabel => 'Name';

  @override
  String get ttagEmpty => 'No tags yet';

  @override
  String ttagDeleteDesc(int count) {
    return '$count to-dos using this tag will become untagged.';
  }

  @override
  String get iconPickerTitle => 'Select icon';

  @override
  String get iconPickerSearchHint => 'Search icons...';

  @override
  String get iconPickerNone => 'None';

  @override
  String get iconPickerNoResults => 'No results found';

  @override
  String iconPickerResultCount(int count) {
    return '$count results';
  }

  @override
  String iconPickerTotalHint(int count) {
    return '$count total · scroll for more';
  }

  @override
  String get smsPasteTitle => 'Record from payment text';

  @override
  String get smsPasteDesc =>
      'Paste a card payment text and we will read the amount, merchant and time to fill in the expense form. You can review it before saving.';

  @override
  String get smsPasteFieldLabel => 'Payment text';

  @override
  String get smsPastePlaceholder =>
      '[Web발신]\nKB국민카드1234승인\n5,500원 일시불\n08/13 13:22\n스타벅스강남';

  @override
  String get smsPasteAction => 'Read text';

  @override
  String get smsPasteFromClipboard => 'Paste from clipboard';

  @override
  String get smsClipboardEmpty => 'No text in the clipboard';

  @override
  String get smsNotRecognized =>
      'This doesn\'t look like a payment text. Please check that the whole message was pasted.';

  @override
  String get smsCancelNotice =>
      'This is a cancellation text. Automatic recording is not supported — find the original expense and record it as a refund.';

  @override
  String get smsLowConfidence =>
      'Some fields could not be read. Please review and fill them in.';

  @override
  String get smsRememberCard =>
      'Remember this card and link it automatically next time';

  @override
  String get moreItemSmsPaste => 'Record from payment text';

  @override
  String get moreDescSmsPaste => 'Paste a card payment text to add an expense';

  @override
  String get smsClipboardBannerTitle => 'You have a copied payment text';

  @override
  String get smsClipboardBannerDesc => 'Paste it to record as an expense.';

  @override
  String get smsClipboardBannerAction => 'Record';

  @override
  String get smsInboxTitle => 'Payment inbox';

  @override
  String get smsInboxClear => 'Clear';

  @override
  String get smsInboxEmpty => 'No payment notifications yet';

  @override
  String get smsInboxEmptyDesc =>
      'Detected card payments collect here. Tap one to record it as an expense.';

  @override
  String get smsInboxRemove => 'Remove';

  @override
  String get smsInboxRemoveConfirm =>
      'Remove this message from the list? It will not be recorded.';

  @override
  String get smsPermissionOffTitle =>
      'We can\'t notify you about detected payments';

  @override
  String get smsPermissionOffDesc =>
      'Turn on the notification permission and we will tell you as soon as a payment is detected. Detection keeps working either way and results collect in the inbox.';

  @override
  String get smsPermissionEnable => 'Turn on';

  @override
  String get moreItemSmsInbox => 'Payment inbox';

  @override
  String get moreDescSmsInbox => 'Record detected card payments as expenses';

  @override
  String get smsNotiAccessOffTitle => 'Payment detection is off';

  @override
  String get smsNotiAccessOffDesc =>
      'Turn on notification access to read payment notifications from card and bank apps as well as payment texts. Only payment notifications are read — everything else is discarded immediately.';

  @override
  String get updateAutoBlockerTitle =>
      'Turn off Samsung Auto Blocker to install';

  @override
  String get updateAutoBlockerDesc =>
      'Galaxy devices block installing apps from outside the store by default. It is not that this app is unsafe — the feature blocks the install path itself, so the download will not install while it is on.';

  @override
  String get updateAutoBlockerPath =>
      'Turn it off in Settings > Security and privacy > Auto Blocker. You can turn it back on after installing.';

  @override
  String get updateAutoBlockerAfterDirect =>
      'Turn off Auto Blocker, come back, and tap download. You can turn it back on after installing.';

  @override
  String get updateAutoBlockerAfterSecurity =>
      'Find Auto Blocker in the list and turn it off. You can turn it back on after installing.';

  @override
  String get updateAutoBlockerOpen => 'Open settings';
}
