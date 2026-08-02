// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'POREST Desk';

  @override
  String get actionSave => '저장';

  @override
  String get actionCancel => '취소';

  @override
  String get actionDelete => '삭제';

  @override
  String get actionEdit => '수정';

  @override
  String get actionCreate => '생성';

  @override
  String get actionConfirm => '확인';

  @override
  String get actionClose => '닫기';

  @override
  String get actionRetry => '다시 시도';

  @override
  String get actionApply => '적용';

  @override
  String get actionReset => '초기화';

  @override
  String get actionSearch => '검색';

  @override
  String get actionLoading => '로딩 중...';

  @override
  String get actionDone => '완료';

  @override
  String get actionBack => '뒤로';

  @override
  String get actionEditLabel => '편집';

  @override
  String get pickDate => '날짜 선택';

  @override
  String get pickTime => '시간 선택';

  @override
  String get searchResultsEmpty => '검색 결과가 없어요';

  @override
  String get unlockTitle => '금액 보기 인증';

  @override
  String get unlockBody => '금액을 다시 보려면 비밀번호로 본인 확인이 필요해요.';

  @override
  String get unlockPasswordLabel => '비밀번호';

  @override
  String get unlockPasswordHint => '비밀번호 입력';

  @override
  String get unlockMismatch => '비밀번호가 일치하지 않습니다.';

  @override
  String get stateNoData => '데이터가 없습니다';

  @override
  String get stateError => '오류가 발생했습니다';

  @override
  String get stateEmpty => '표시할 항목이 없어요';

  @override
  String get languageKorean => '한국어';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSystem => '시스템';

  @override
  String get settingsLanguage => '언어';

  @override
  String get navDashboard => '대시보드';

  @override
  String get navTodo => '할 일';

  @override
  String get navCalendar => '캘린더';

  @override
  String get navMemo => '메모';

  @override
  String get navTimer => '타이머';

  @override
  String get navExpense => '가계부';

  @override
  String get navAsset => '자산';

  @override
  String get navDutchPay => '더치페이';

  @override
  String get navPostit => '포스트잇';

  @override
  String get navGroup => '그룹';

  @override
  String get navSettings => '설정';

  @override
  String get navMore => '전체';

  @override
  String get navMenu => '메뉴';

  @override
  String get navHome => '홈';

  @override
  String get navStats => '통계';

  @override
  String get navSearch => '검색';

  @override
  String get navNotifications => '알림';

  @override
  String get navBudget => '예산';

  @override
  String get navRecurring => '반복 거래';

  @override
  String get navCategories => '카테고리';

  @override
  String get navPresets => '프리셋';

  @override
  String get navCards => '카드 관리';

  @override
  String get navSavingGoals => '저축 목표';

  @override
  String get navExport => '내보내기';

  @override
  String get navLogout => '로그아웃';

  @override
  String get navChangePassword => '비밀번호 변경';

  @override
  String get notiTitle => '알림';

  @override
  String get notiEmpty => '알림이 없습니다';

  @override
  String get notiMarkAllRead => '모두 읽음';

  @override
  String get notiTypeEventReminder => '일정 알림';

  @override
  String get notiTypeBudgetAlert => '예산 알림';

  @override
  String get notiTypeTodoReminder => '할 일 알림';

  @override
  String get notiTypeSystem => '시스템 알림';

  @override
  String get notiConnectionLost => '알림 연결이 끊어졌습니다';

  @override
  String get notiConnectionRestored => '알림 연결이 복구되었습니다';

  @override
  String get notiNew => '새 알림';

  @override
  String get assetTitle => '자산 관리';

  @override
  String get assetSummaryTotalBalance => '총 자산';

  @override
  String get assetEmpty => '등록된 자산이 없습니다';

  @override
  String get assetCreateFirst => '첫 번째 자산을 등록해 보세요';

  @override
  String get assetAdd => '자산 추가';

  @override
  String get assetEdit => '자산 수정';

  @override
  String get assetTransferAdd => '이체 추가';

  @override
  String get assetTransferEmpty => '이체 내역이 없습니다';

  @override
  String get assetFee => '수수료';

  @override
  String get assetTypeBankAccount => '입출금';

  @override
  String get assetTypeSavings => '예적금';

  @override
  String get assetTypeCash => '현금';

  @override
  String get assetTypeCreditCard => '신용카드';

  @override
  String get assetTypeCheckCard => '체크카드';

  @override
  String get assetTypeInvestment => '투자';

  @override
  String get assetTypeLoan => '대출';

  @override
  String get assetGroupAccount => '계좌 · 예금';

  @override
  String get assetGroupCard => '카드';

  @override
  String get assetGroupInvestment => '투자';

  @override
  String get assetGroupDebt => '대출';

  @override
  String get assetCatAccount => '계좌';

  @override
  String get assetSubtypeInstallment => '적금';

  @override
  String get assetSubtypeDeposit => '예금';

  @override
  String get assetLoadError => '자산을 불러오지 못했습니다';

  @override
  String get assetEmptyState => '아직 등록된 자산이 없어요';

  @override
  String get assetEmptyHint => '설정 → 카드·계좌 관리에서 추가할 수 있어요';

  @override
  String get assetSummaryColAccounts => '계좌·예금';

  @override
  String get assetSummaryColCards => '카드값';

  @override
  String get assetTotalNetWorth => '총 순자산';

  @override
  String get assetVsLastMonth => '지난달 대비';

  @override
  String get assetGroupEmpty => '등록된 항목이 없어요';

  @override
  String assetPaymentDayInfo(int day) {
    return '$day일 결제';
  }

  @override
  String get assetExcludedFromTotal => '총액 제외';

  @override
  String get assetManageTitle => '계좌·카드 관리';

  @override
  String assetTabAccountsSavings(int count) {
    return '계좌·예금 $count';
  }

  @override
  String assetTabCards(int count) {
    return '카드 $count';
  }

  @override
  String assetTabInvest(int count) {
    return '투자 $count';
  }

  @override
  String get assetTotalPrefix => '총';

  @override
  String assetAddCategory(String name) {
    return '$name 추가';
  }

  @override
  String assetCategoryEmpty(String name) {
    return '등록된 $name가 없어요';
  }

  @override
  String get assetIncludeInTotal => '전체 자산 합계에 포함';

  @override
  String get assetIncludeInTotalDesc => '순자산·총자산 계산에 반영됩니다';

  @override
  String get assetTrendLoadError => '추이 데이터를 불러오지 못했어요';

  @override
  String get assetTrendEmpty => '추이 데이터가 없어요';

  @override
  String get assetNetWorth => '순자산';

  @override
  String get assetAccountAdd => '계좌 추가';

  @override
  String get assetAccountEdit => '계좌 편집';

  @override
  String get assetAccountAdded => '계좌가 추가되었습니다';

  @override
  String get assetAccountUpdated => '계좌가 수정되었습니다';

  @override
  String get assetAccountDeleted => '계좌가 삭제되었습니다';

  @override
  String get assetAccountDelete => '계좌 삭제';

  @override
  String get assetAccountDeleteConfirm => '이 계좌를 삭제하시겠습니까? 연결된 거래는 유지됩니다.';

  @override
  String get assetActionFailed => '실패';

  @override
  String get assetDeleteFailed => '삭제 실패';

  @override
  String get assetInstitutionBrand => '기관·브랜드';

  @override
  String assetTotalEntries(int count) {
    return '총 $count개';
  }

  @override
  String get assetBankSearchHint => '은행명 또는 증권사 검색';

  @override
  String get assetNickname => '별칭';

  @override
  String get assetNicknamePlaceholder => '예: 신한 주거래';

  @override
  String get assetAccountType => '계좌 종류';

  @override
  String get assetAccountNumber => '계좌번호';

  @override
  String get assetBalanceLabel => '잔액 (원)';

  @override
  String get assetMemoOptional => '메모 (선택)';

  @override
  String get assetMemoPlaceholder => '계좌번호 뒷자리, 결제일, 한도 등 메모하세요';

  @override
  String get assetCreditLimitLabel => '신용한도 (원, 선택)';

  @override
  String get assetCreditLimitPlaceholder => '예: 5,000,000';

  @override
  String get assetCreditLimitHint => '한도를 입력하면 사용률 게이지가 표시됩니다.';

  @override
  String get assetPaymentDayLabel => '결제일 (선택)';

  @override
  String get assetPaymentDaySelect => '결제일 선택';

  @override
  String get assetPaymentDay => '결제일';

  @override
  String get assetPaymentAccountLabel => '결제 출금계좌 (선택)';

  @override
  String get assetNoBankAccounts => '등록된 입출금계좌가 없어요';

  @override
  String get assetPaymentAccountSelect => '결제계좌 선택';

  @override
  String get assetPaymentAccount => '결제 출금계좌';

  @override
  String get assetPaymentAccountHint => '결제일에 이 계좌에서 청구액이 출금됩니다.';

  @override
  String get assetNewAccount => '새 계좌';

  @override
  String get assetPreview => '미리보기';

  @override
  String get assetNoSearchResults => '검색 결과가 없어요';

  @override
  String get assetCardAdd => '카드 추가';

  @override
  String get assetCardAdded => '카드가 추가되었습니다';

  @override
  String get assetCardType => '카드 종류';

  @override
  String get assetCardProduct => '카드 상품';

  @override
  String get assetIncludeDiscontinued => '단종 포함';

  @override
  String assetTotalItems(int count) {
    return '총 $count건';
  }

  @override
  String get assetTotalLoading => '총 …';

  @override
  String get assetCardSearchHint => '카드명 또는 발급사 검색';

  @override
  String get assetNicknameOptional => '별칭 (선택)';

  @override
  String get assetCardNicknamePlaceholder => '예: 신한 Deep Dream';

  @override
  String get assetCurrentUsage => '현재 사용액 (원)';

  @override
  String get assetCurrentUsageHint => '청구될 금액을 입력하세요. 총 부채에 반영됩니다.';

  @override
  String get assetNewCard => '새 카드';

  @override
  String get assetCatalogLoadError => '카탈로그 로드 실패';

  @override
  String get assetAnnualFee => '연회비';

  @override
  String get assetCardShortCredit => '신용';

  @override
  String get assetCardShortCheck => '체크';

  @override
  String get assetDiscontinued => '단종';

  @override
  String get assetInvestAdd => '투자 추가';

  @override
  String get assetInvestEdit => '투자 편집';

  @override
  String get assetInvestAdded => '투자가 추가되었습니다';

  @override
  String get assetInvestUpdated => '투자가 수정되었습니다';

  @override
  String get assetInvestDeleted => '투자가 삭제되었습니다';

  @override
  String get assetInvestDelete => '투자 삭제';

  @override
  String get assetInvestDeleteConfirm => '이 투자 자산을 삭제하시겠습니까? 연결된 거래는 유지됩니다.';

  @override
  String get assetBrokerExchange => '증권사·거래소';

  @override
  String get assetInvestSearchHint => '증권사·가상자산거래소·상품거래소 검색';

  @override
  String get assetProductName => '상품·종목명';

  @override
  String get assetProductPlaceholder => '예: KODEX 200, 해외 ETF 포트폴리오';

  @override
  String get assetValuation => '평가액 (원)';

  @override
  String get assetNewInvestment => '새 투자 상품';

  @override
  String get assetCryptoExchange => '가상자산거래소';

  @override
  String get assetCardDetail => '카드 상세';

  @override
  String get assetInvestDetail => '투자 상세';

  @override
  String get assetAccountDetail => '계좌 상세';

  @override
  String get assetShowAmount => '금액 표시';

  @override
  String get assetHideAmount => '금액 가리기';

  @override
  String get assetPeriod3m => '3개월';

  @override
  String get assetPeriod6m => '6개월';

  @override
  String get assetPeriod1y => '1년';

  @override
  String assetWeeksCount(int weeks) {
    return '$weeks주';
  }

  @override
  String get assetTrendKindUsage => '사용 추이';

  @override
  String get assetTrendKindValuation => '평가액 추이';

  @override
  String get assetTrendKindBalance => '잔액 추이';

  @override
  String assetTrendRecent(String weeks, String kind) {
    return '최근 $weeks $kind';
  }

  @override
  String get assetValueLabelCard => '이번 달 결제 예정';

  @override
  String get assetValuationShort => '평가액';

  @override
  String get assetSeriesUsage => '사용';

  @override
  String assetRecentTxCount(int count) {
    return '최근 거래 ($count)';
  }

  @override
  String get assetViewAll => '전체 보기';

  @override
  String get assetTossLinkStarted => '토스 시세 연동을 시작했어요';

  @override
  String get assetLinkFailed => '연결 실패';

  @override
  String get assetTossUnlinked => '토스 연결을 해제했어요';

  @override
  String get assetUnlinkFailed => '해제 실패';

  @override
  String get assetQtyUpdated => '보유 수량을 수정했어요';

  @override
  String get assetUpdateFailed => '수정 실패';

  @override
  String get assetTossLinked => '토스 연동 중';

  @override
  String get assetHoldings => '보유 종목';

  @override
  String assetHoldingsSummary(int count, String amount) {
    return '$count종목 · $amount원';
  }

  @override
  String assetHoldingRep(String name, int count) {
    return '$name 외 $count종목';
  }

  @override
  String get assetNoHoldings => '보유 종목 없음';

  @override
  String get assetHoldingLinkedBadge => '연동';

  @override
  String assetHoldingLinkedSub(String price) {
    return '현재가 $price × 수량';
  }

  @override
  String get assetHoldingManualSub => '평가액 직접 입력';

  @override
  String assetHoldingLinkedDetail(int qty, String price) {
    return '$qty주 · 현재가 $price 연동';
  }

  @override
  String get assetHoldingManualDetail => '직접 입력';

  @override
  String get assetHoldingsEmptyEdit =>
      '검색으로 보유 종목을 추가하세요. 연동 종목은 현재가 × 수량으로 평가액이 자동 계산돼요.';

  @override
  String get assetHoldingsEmptyDetail => '보유 종목이 없어요. 편집에서 종목을 추가해보세요.';

  @override
  String get assetHoldingSearchHint => '종목명·티커 검색 후 추가 (예: 삼성전자, NVDA)';

  @override
  String assetHoldingAddManual(String name) {
    return '\"$name\" 직접 추가 — 평가액 입력';
  }

  @override
  String get assetSharesUnit => '주';

  @override
  String assetInvestHoldingsSub(int count) {
    return '투자 · 보유 $count종목';
  }

  @override
  String assetTodayChange(String amount) {
    return '오늘 $amount원';
  }

  @override
  String assetSharesCount(int n) {
    return '$n주';
  }

  @override
  String assetTossValuationFormula(int qty) {
    return '평가액 = 토스 현재가 × $qty주 로 실시간 계산됩니다.';
  }

  @override
  String get assetHoldingQty => '보유 수량';

  @override
  String get assetEditQty => '수량 수정';

  @override
  String get assetUnlink => '연결 해제';

  @override
  String get assetTossRealtimeTitle => '토스 시세로 실시간 평가';

  @override
  String get assetTossRealtimeDesc =>
      '보유 종목과 수량을 등록하면 토스 현재가 × 수량으로 평가액이 실시간 반영됩니다.';

  @override
  String get assetTapToChange => '변경하려면 탭';

  @override
  String get assetStockSearchHint => '종목명·코드 검색 (예: 삼성전자, 005930)';

  @override
  String get stockMarketKospi => '코스피';

  @override
  String get stockMarketKosdaq => '코스닥';

  @override
  String get stockMarketKonex => '코넥스';

  @override
  String get stockMarketKrxIdx => 'KRX 지수';

  @override
  String get stockMarketNas => '나스닥';

  @override
  String get stockMarketNys => '뉴욕';

  @override
  String get stockMarketAms => '아멕스';

  @override
  String get stockMarketShs => '상해';

  @override
  String get stockMarketShi => '상해지수';

  @override
  String get stockMarketSzs => '심천';

  @override
  String get stockMarketSzi => '심천지수';

  @override
  String get stockMarketTse => '도쿄';

  @override
  String get stockMarketHks => '홍콩';

  @override
  String get stockMarketHnx => '하노이';

  @override
  String get stockMarketHsx => '호치민';

  @override
  String assetLinkByCode(String code) {
    return '「$code」 코드로 연결';
  }

  @override
  String get assetLink => '연결';

  @override
  String get assetChartNoData => '표시할 데이터가 없어요';

  @override
  String get assetNoLinkedTx => '연결된 거래 내역이 없어요.';

  @override
  String get assetTxFallback => '거래';

  @override
  String get assetCategoryOther => '기타';

  @override
  String assetPayConfirmMessage(String amount) {
    return '결제 예정액 $amount원을 지금 결제 처리할까요?';
  }

  @override
  String assetPayConfirmDateSuffix(String date) {
    return ' 결제일은 $date 입니다.';
  }

  @override
  String get assetPayNow => '지금 결제';

  @override
  String get assetPayAction => '결제하기';

  @override
  String get assetPaymentRecorded => '결제가 기록되었습니다';

  @override
  String get assetPayFailed => '결제 실패';

  @override
  String get assetBillingLoadError => '청구 정보를 불러오지 못했어요';

  @override
  String get assetUpcomingPayment => '결제 예정';

  @override
  String get assetScheduledTag => '예정';

  @override
  String get assetPaidDone => '결제 완료';

  @override
  String assetUsagePeriod(String period) {
    return '카드 이용 기간 $period';
  }

  @override
  String get assetLimitSettings => '한도 · 결제 설정';

  @override
  String get assetLimitUsage => '한도 사용';

  @override
  String assetLimitPctUsed(int pct) {
    return '$pct% 사용';
  }

  @override
  String assetLimitOf(String used, String limit) {
    return '$used / 한도 $limit';
  }

  @override
  String assetLimitRemain(String amount) {
    return '잔여 $amount';
  }

  @override
  String get assetLimitEdit => '한도 · 결제일 변경';

  @override
  String get assetPerfDone => '이번 달 실적 달성';

  @override
  String assetPerfRemain(String amount) {
    return '실적까지 $amount';
  }

  @override
  String get assetUsageHistory => '이용 내역';

  @override
  String get assetSortRecent => '최근순';

  @override
  String get assetSortAmount => '고액순';

  @override
  String get assetSortCategory => '카테고리별';

  @override
  String get assetPeriodPick => '기간 선택';

  @override
  String get assetNoUsage => '이용 내역이 없어요.';

  @override
  String assetBillingPeriod(String start, String end) {
    return '$start~$end 사용분';
  }

  @override
  String assetMonthlyPaymentDay(int day) {
    return '매월 $day일 결제';
  }

  @override
  String get assetBillingHistory => '청구 이력';

  @override
  String get assetStatusPending => '대기';

  @override
  String get assetStatusSkipped => '건너뜀';

  @override
  String get todoTitle => '할 일';

  @override
  String get todoEmpty => '할 일이 없습니다';

  @override
  String get todoCreateFirst => '첫 번째 할 일을 만들어 보세요';

  @override
  String get todoQuickAddHint => '+ 빠른 할 일 추가';

  @override
  String get todoStatusAll => '전체';

  @override
  String get todoStatusCompleted => '완료';

  @override
  String get todoPriorityAll => '전체';

  @override
  String get todoPriorityHigh => '높음';

  @override
  String get todoPriorityMedium => '보통';

  @override
  String get todoPriorityLow => '낮음';

  @override
  String get todoSubtask => '하위 작업';

  @override
  String get todoSubtaskAddHint => '+ 하위 작업 추가';

  @override
  String get todoTagMgmt => '태그 관리';

  @override
  String get memoTitle => '메모';

  @override
  String get memoEmpty => '메모가 없어요';

  @override
  String get memoSearchEmpty => '결과가 없어요';

  @override
  String get memoSearchHint => '메모 검색';

  @override
  String get memoFolderMgmt => '폴더 관리';

  @override
  String get memoFolderRoot => '루트';

  @override
  String get memoFolderEmpty => '등록된 폴더가 없습니다';

  @override
  String get memoPin => '고정';

  @override
  String get memoUnpin => '고정 해제';

  @override
  String get calTitle => '캘린더';

  @override
  String get calToday => '오늘';

  @override
  String get calMonthView => '월';

  @override
  String get calWeekView => '주';

  @override
  String get calDayView => '일';

  @override
  String get calYearView => '연';

  @override
  String get calAgendaView => '안건';

  @override
  String get calNoEvents => '일정이 없습니다';

  @override
  String get calEventAdd => '일정 추가';

  @override
  String get calEventEdit => '일정 수정';

  @override
  String get calEventDelete => '일정 삭제';

  @override
  String get calLabelMgmt => '라벨 관리';

  @override
  String get calMyCalendars => '내 캘린더';

  @override
  String get calAllDay => '종일';

  @override
  String get calRepeat => '반복';

  @override
  String get calRepeatNone => '안 함';

  @override
  String get calRepeatDaily => '매일';

  @override
  String get calRepeatWeekly => '매주';

  @override
  String get calRepeatMonthly => '매월';

  @override
  String get calRepeatYearly => '매년';

  @override
  String get calLocation => '장소';

  @override
  String get calMemo => '메모';

  @override
  String get calStartDate => '시작';

  @override
  String get calEndDate => '종료';

  @override
  String get calFieldTitle => '제목';

  @override
  String get calFieldDescription => '설명';

  @override
  String get calFieldCalendar => '캘린더';

  @override
  String get calFieldLabel => '라벨';

  @override
  String get calFieldColor => '색상';

  @override
  String get calFieldName => '이름';

  @override
  String get calFieldReminder => '알림';

  @override
  String get calFieldStartDate => '시작일';

  @override
  String get calFieldEndDate => '종료일';

  @override
  String get calTitlePlaceholder => '예: 가족 식사';

  @override
  String get calDescriptionPlaceholder => '추가 설명 (선택)';

  @override
  String get calLocationPlaceholder => '장소를 입력하세요';

  @override
  String get calSelectCalendar => '캘린더 선택';

  @override
  String get calNoLabel => '라벨이 없습니다';

  @override
  String get calLabelNamePlaceholder => '예: 중요, 마감일, 회의';

  @override
  String get calCalendarNamePlaceholder => '예: 가족, 업무, 운동 일정';

  @override
  String get calCalendarNameFieldPlaceholder => '캘린더 이름';

  @override
  String get calInviteCodePlaceholder => '예: ABC123';

  @override
  String get calRecurrenceNone => '반복 없음';

  @override
  String calReminderMinutesBefore(int n) {
    return '$n분 전';
  }

  @override
  String get calReminderHourBefore => '1시간 전';

  @override
  String get calReminderDayBefore => '1일 전';

  @override
  String calEventDeleteConfirm(String title) {
    return '\"$title\" 일정을 삭제할까요? 이 작업은 되돌릴 수 없습니다.';
  }

  @override
  String get calEventAdded => '일정이 추가되었습니다';

  @override
  String get calEventUpdated => '일정이 수정되었습니다';

  @override
  String get calLabelsTitle => '캘린더 라벨';

  @override
  String calAllLabelsCount(int count) {
    return '전체 라벨 · $count';
  }

  @override
  String get calLabelsEmpty => '라벨이 없어요';

  @override
  String get calLabelsEmptyHint => '위 \"새 라벨\" 버튼으로 만들어보세요';

  @override
  String get calLabelsIntro => '모든 캘린더에서 공용으로 쓰는 라벨이에요. 일정 등록 시 선택할 수 있어요.';

  @override
  String get calNewLabel => '새 라벨';

  @override
  String get calEditLabel => '라벨 편집';

  @override
  String get calPreview => '미리보기';

  @override
  String get calDeleteLabelTitle => '라벨 삭제';

  @override
  String calDeleteLabelConfirm(String name) {
    return '\"$name\" 라벨을 삭제하시겠어요? 이 라벨이 지정된 일정은 라벨 없음 상태가 됩니다.';
  }

  @override
  String get calDatePicker => '날짜 이동';

  @override
  String calCalendarChipCount(int count) {
    return '$count개';
  }

  @override
  String get calNoCalendars => '캘린더가 없습니다';

  @override
  String get calOtherSources => '기타 소스';

  @override
  String get calHolidays => '공휴일';

  @override
  String get calManageShareSettings => '캘린더 관리 · 공유 설정';

  @override
  String get calNoEventsThisDay => '이날 이벤트가 없습니다';

  @override
  String calEventTotalCount(int count) {
    return '$count건';
  }

  @override
  String get calGoToToday => '오늘로';

  @override
  String get calManageShareTitle => '캘린더 관리·공유';

  @override
  String get calJoinByCode => '초대 코드로 참여';

  @override
  String get calRoleOwner => '소유자';

  @override
  String get calRoleEditor => '편집 가능';

  @override
  String get calRoleViewer => '읽기 전용';

  @override
  String get calShareIntroTitle => '가족·친구와 일정 공유';

  @override
  String get calShareIntroBody => '캘린더를 만들고 멤버를 초대해 함께 일정을 관리할 수 있어요.';

  @override
  String get calNewCalendar => '새 캘린더';

  @override
  String calMyCalendarsCount(int count) {
    return '내 캘린더 · $count';
  }

  @override
  String get calNoOwnedCalendars => '소유한 캘린더가 없어요';

  @override
  String calSharedCalendarsCount(int count) {
    return '공유받은 캘린더 · $count';
  }

  @override
  String get calNoSharedCalendars => '공유받은 캘린더가 없어요';

  @override
  String get calDefault => '기본';

  @override
  String get calOnlyMe => '나만 사용';

  @override
  String calMemberCount(int count) {
    return '멤버 $count명';
  }

  @override
  String get calJoinCardBody => '공유받은 초대 코드를 입력해 캘린더에 참여하세요.';

  @override
  String get calJoin => '참여';

  @override
  String get calCreate => '만들기';

  @override
  String calJoinedCalendar(String name) {
    return '\"$name\" 캘린더에 참여했어요';
  }

  @override
  String get calInviteCode => '초대 코드';

  @override
  String calManageTitle(String name) {
    return '$name · 관리';
  }

  @override
  String get calDeleteCalendar => '캘린더 삭제';

  @override
  String get calCalendarUpdated => '캘린더를 수정했어요';

  @override
  String get calInviteCodeRegenerated => '초대 코드를 새로 만들었어요';

  @override
  String get calInviteCodeCopied => '초대 코드를 복사했어요';

  @override
  String get calRemoveMember => '멤버 내보내기';

  @override
  String calRemoveMemberConfirm(String name) {
    return '$name 님을 캘린더에서 내보내시겠어요?';
  }

  @override
  String get calRemove => '내보내기';

  @override
  String calDeleteCalendarConfirm(String name) {
    return '\"$name\" 캘린더를 삭제하시겠어요? 일정은 기본 캘린더로 이동하고 모든 멤버의 접근 권한이 사라집니다.';
  }

  @override
  String get calCopy => '복사';

  @override
  String get calRegenerate => '재생성';

  @override
  String get calMembers => '멤버';

  @override
  String get calMeSuffix => '(나)';

  @override
  String get calChangeToEditor => '편집 가능으로';

  @override
  String get calChangeToViewer => '읽기 전용으로';

  @override
  String get calAdd => '추가';

  @override
  String get calActionFailed => '실패';

  @override
  String get calSaveFailed => '저장 실패';

  @override
  String get calDeleteFailed => '삭제 실패';

  @override
  String get calJoinFailed => '참여 실패';

  @override
  String get calUpdateFailed => '변경 실패';

  @override
  String get calCalendarLoadError => '캘린더 로드 실패';

  @override
  String get calLabelLoadError => '라벨 로드 실패';

  @override
  String get calMemberLoadError => '멤버 로드 실패';

  @override
  String get dashTitle => '홈';

  @override
  String get dashGreeting => '오늘도 좋은 하루 되세요';

  @override
  String get dashTotalAssets => '총 자산';

  @override
  String get dashChange => '변화';

  @override
  String get dashThisMonthExpense => '이번 달 지출';

  @override
  String get dashThisMonthIncome => '이번 달 수입';

  @override
  String get dashRecent => '최근 거래';

  @override
  String get dashUpcoming => '다가오는 일정';

  @override
  String get dashRecentTodos => '최근 할 일';

  @override
  String dashOverdue(int count) {
    return '연체 $count';
  }

  @override
  String get dashTrendTitle => '최근 6개월';

  @override
  String get dashSeeMore => '자세히';

  @override
  String get dashEmptyTransactions => '최근 거래가 없습니다';

  @override
  String get dashEmptyEvents => '예정된 일정이 없습니다';

  @override
  String get dashEmptyTodos => '처리할 할 일이 없습니다';

  @override
  String get dashAddTx => '거래 추가';

  @override
  String get dashTodayLabel => '오늘';

  @override
  String get dashTomorrowLabel => '내일';

  @override
  String dashDaysLeft(int n) {
    return 'D-$n';
  }

  @override
  String get dashHideAmount => '금액 숨김';

  @override
  String get dashVsLastMonth => '지난달 대비';

  @override
  String get dashLiabilities => '부채';

  @override
  String dashMonthLedger(int month) {
    return '$month월 가계부';
  }

  @override
  String get dashMonthTxError => '이번달 거래를 불러오지 못했습니다';

  @override
  String get dashDailyAvgPrefix => '하루 평균 ';

  @override
  String get dashSpentMasked => ' 썼어요.';

  @override
  String get dashSpentUnit => '원 썼어요.';

  @override
  String get dashVsPrevPrefix => ' 전월 대비 ';

  @override
  String get dashSaving => ' 절약 중이에요.';

  @override
  String get dashSpentMore => ' 더 썼어요.';

  @override
  String get dashSame => ' 동일해요.';

  @override
  String get dashNoCategoryData => '카테고리 데이터가 없어요';

  @override
  String get dashNoBudget => '등록된 예산이 없어요';

  @override
  String get dashTodaySpend => '오늘 쓴 돈';

  @override
  String get dashTxError => '거래를 불러오지 못했습니다';

  @override
  String get dashNoTodaySpend => '오늘은 아직 쓴 돈이 없어요';

  @override
  String get expTitle => '가계부';

  @override
  String get expFilterAll => '전체';

  @override
  String get expFilterIncome => '수입';

  @override
  String get expFilterExpense => '지출';

  @override
  String get expFilterTransfer => '이체';

  @override
  String get expEmpty => '거래가 없습니다';

  @override
  String get expEmptyDescription => '새 거래를 추가해서 가계부를 시작하세요';

  @override
  String get expAdd => '거래 추가';

  @override
  String get expEdit => '거래 수정';

  @override
  String get expDelete => '거래 삭제';

  @override
  String get expAmount => '금액';

  @override
  String get expCategory => '카테고리';

  @override
  String get expAsset => '자산';

  @override
  String get expDate => '날짜';

  @override
  String get expMerchant => '가맹점';

  @override
  String get expPaymentMethod => '결제 수단';

  @override
  String get expDescription => '메모';

  @override
  String get expTypeIncome => '수입';

  @override
  String get expTypeExpense => '지출';

  @override
  String get transferFeePrefix => '수수료';

  @override
  String get transferWithdrawn => '출금 합계';

  @override
  String get transferDeleted => '이체를 삭제했어요';

  @override
  String get transferDeleteConfirm => '이 이체를 삭제할까요? 양쪽 자산의 잔액이 되돌아갑니다';

  @override
  String get expTypeTransfer => '이체';

  @override
  String get expTransferFrom => '보낼 자산';

  @override
  String get expTransferTo => '받을 자산';

  @override
  String get expFee => '수수료';

  @override
  String get expFilter => '필터';

  @override
  String get expFilterMin => '최소';

  @override
  String get expFilterMax => '최대';

  @override
  String get expFilterPeriod => '기간';

  @override
  String get expSplit => '내역 분할';

  @override
  String get expConvertDutch => '더치페이로';

  @override
  String get expConvertRecurring => '반복 설정';

  @override
  String get expExport => '내보내기';

  @override
  String get expExportCsv => 'CSV 내보내기';

  @override
  String get expSummaryTitle => '월간 요약';

  @override
  String get expSummaryIncome => '수입';

  @override
  String get expSummaryExpense => '지출';

  @override
  String get expSummaryBalance => '잔액';

  @override
  String get budgetOverallCapNew => '월 전체 상한 설정';

  @override
  String get budgetCategoryAdd => '카테고리 예산 추가';

  @override
  String get budgetOverallCapEdit => '월 전체 상한 수정';

  @override
  String get budgetCategoryEdit => '카테고리 예산 수정';

  @override
  String get budgetUpdated => '예산이 수정되었습니다';

  @override
  String get budgetAdded => '예산이 추가되었습니다';

  @override
  String get budgetActionFailed => '실패';

  @override
  String get budgetDeleteTitle => '예산 삭제';

  @override
  String get budgetDeleteConfirm => '이 예산을 삭제하시겠습니까?';

  @override
  String get budgetDeleteFailed => '삭제 실패';

  @override
  String get budgetOverallCap => '월 전체 상한';

  @override
  String get budgetCategoryLoadError => '카테고리 로드 실패';

  @override
  String get budgetMonthlyLimit => '월 예산 한도';

  @override
  String get budgetLoadError => '예산을 불러오지 못했습니다';

  @override
  String get budgetSelectMonth => '월 선택';

  @override
  String budgetMonthOverallCap(int month) {
    return '$month월 전체 상한';
  }

  @override
  String get budgetOverallCapDesc => '이번 달 전체 지출의 상한이에요 (카테고리 예산이 없는 지출도 포함).';

  @override
  String get budgetOverallCapEmptyHint =>
      '전체 상한이 아직 설정되지 않았어요. 우측 상단 설정 버튼으로 이번 달 최대 지출 한도를 지정할 수 있어요.';

  @override
  String get budgetCurrentCategorySum => '현재 카테고리 한도 합계';

  @override
  String budgetPercentUsed(String pct) {
    return '$pct% 사용';
  }

  @override
  String budgetRemaining(String amount) {
    return '남은 예산 $amount';
  }

  @override
  String budgetOverBy(String amount) {
    return '한도 $amount 초과';
  }

  @override
  String get budgetOverallCapLabel => '전체 상한';

  @override
  String get budgetCategoryAllocated => '카테고리 할당';

  @override
  String get budgetAllocatable => '할당 가능';

  @override
  String budgetOverAllocatedWarning(String amount) {
    return '카테고리 한도 합이 전체 상한을 $amount 초과했어요. 전체 상한을 올리거나 카테고리 한도를 줄여주세요.';
  }

  @override
  String get budgetSpendingPace => '지출 페이스';

  @override
  String get budgetPaceOnTrack => '정상 속도';

  @override
  String get budgetPaceFast => '빠른 속도';

  @override
  String budgetMonthElapsed(String pct) {
    return '이번 달 $pct% 경과 ↑';
  }

  @override
  String get budgetDailyAvg => '일평균 지출';

  @override
  String get budgetDailyRecommended => '남은 일 권장 지출';

  @override
  String get budgetStatusTitle => '예산 현황';

  @override
  String get budgetOver => '초과';

  @override
  String get budgetHealthy => '여유';

  @override
  String get budgetByCategory => '카테고리별 예산';

  @override
  String budgetCountSet(int count) {
    return '$count개 설정됨';
  }

  @override
  String get budgetNoCategoryBudgets => '카테고리별 예산이 없어요';

  @override
  String get budgetGoToSettings => '예산 설정하러 가기 →';

  @override
  String budgetCategoryFallback(int id) {
    return '카테고리 #$id';
  }

  @override
  String get budgetComplianceTitle => '최근 6개월 예산 이행률';

  @override
  String get budgetComplianceSubtitle => '한도 대비 지출 %';

  @override
  String get budgetNoComplianceData => '아직 이행률 데이터가 없어요';

  @override
  String get budgetVsLimit => '한도 대비';

  @override
  String get budgetLimit => '한도';

  @override
  String get budgetEmptyMonth => '이 달 예산이 없습니다';

  @override
  String get budgetEmptyHint => '전체 상한 또는 카테고리 예산을 설정하세요';

  @override
  String get budgetSetup => '예산 설정';

  @override
  String get budgetCopyLastMonth => '지난달 예산 복사';

  @override
  String budgetCopyConfirmMessage(String from, int count, String to) {
    return '$from 예산 한도($count개)를 $to로 복사해요. 이번 달에 이미 있는 예산은 덮어써집니다.';
  }

  @override
  String get budgetCopyFailed => '복사 실패';

  @override
  String budgetCopiedCount(int count) {
    return '$count개 예산을 복사했습니다';
  }

  @override
  String get budgetCopyLastMonthBtn => '지난달 복사';

  @override
  String budgetMonthTotal(int month) {
    return '$month월 총 예산';
  }

  @override
  String get budgetNotSet => '설정되지 않음';

  @override
  String get budgetUsed => '사용';

  @override
  String get budgetAllocated => '할당됨';

  @override
  String budgetByCategoryCount(int count) {
    return '카테고리별 예산 · $count개';
  }

  @override
  String get budgetAdd => '예산 추가';

  @override
  String get budgetNoCategorySet => '설정된 카테고리 예산이 없어요';

  @override
  String get cardBenefitTypeAll => '혜택 전체';

  @override
  String get cardBenefitTypeDiscount => '할인';

  @override
  String get cardBenefitTypePoint => '적립';

  @override
  String get cardBenefitTypeCashback => '캐시백';

  @override
  String get cardBenefitTypeMileage => '마일리지';

  @override
  String get cardManageTitle => '카드 관리';

  @override
  String get cardBenefitsTitle => '카드 혜택';

  @override
  String get cardSelectTitle => '카드 선택';

  @override
  String get cardBenefitMappingTitle => '카드 혜택 매핑';

  @override
  String get cardBenefitMappingTooltip => '혜택 매핑';

  @override
  String get cardSearchHintName => '카드명 검색';

  @override
  String get cardSearchHintFull => '카드명, 브랜드, 혜택으로 검색';

  @override
  String get cardSearchHintNameCompany => '카드명 / 회사 검색';

  @override
  String get cardLoadError => '카드 로드 실패';

  @override
  String get cardDetailLoadError => '카드 상세 로드 실패';

  @override
  String get cardSearchError => '카드 검색 실패';

  @override
  String get cardAddFailed => '추가 실패';

  @override
  String get cardDeleteFailed => '삭제 실패';

  @override
  String get cardMappingLoadError => '매핑 로드 실패';

  @override
  String get cardLastMonthPerf => '전월 실적';

  @override
  String get cardKeyBenefitTags => '주요 혜택 태그';

  @override
  String cardBenefitDetailCount(int count) {
    return '혜택 상세 · $count건';
  }

  @override
  String get cardExpandAll => '모두 펼치기';

  @override
  String get cardCollapseAll => '모두 접기';

  @override
  String get cardCautions => '유의사항';

  @override
  String get cardBenefits => '혜택';

  @override
  String get cardNone => '없음';

  @override
  String get cardPerfNone => '실적 무관';

  @override
  String cardFeeDomesticOnly(String amount) {
    return '국내전용 $amount';
  }

  @override
  String cardPerfMin(String amount) {
    return '$amount 이상';
  }

  @override
  String cardPerfMonthly(String amount) {
    return '실적 $amount/월';
  }

  @override
  String cardAnnualFeeValue(String fee) {
    return '연회비 $fee';
  }

  @override
  String cardPerfMonthTitle(String month) {
    return '$month 실적';
  }

  @override
  String get cardPerfAchieved => '달성';

  @override
  String cardPerfRemaining(String amount) {
    return '남은 $amount';
  }

  @override
  String get cardMappingNew => '새 매핑';

  @override
  String get cardMappingNewDesc =>
      '카드 혜택 카테고리(예: 카페, 주유)를 가계부 카테고리와 연결하면 거래 입력 시 자동 추천에 활용됩니다.';

  @override
  String get cardMappingBenefitPlaceholder => '혜택 카테고리';

  @override
  String get cardMappingCategoryPlaceholder => '가계부 카테고리';

  @override
  String get cardMappingAdd => '매핑 추가';

  @override
  String get cardMappingRegistered => '등록된 매핑';

  @override
  String get cardMappingEmpty => '등록된 매핑이 없습니다';

  @override
  String get cardMappingDefault => '기본';

  @override
  String get cardIncludeDiscontinued => '단종 카드 포함';

  @override
  String cardTotalCount(int count) {
    return '총 $count건';
  }

  @override
  String get cardEmpty => '카드가 없습니다';

  @override
  String get cardNoResults => '결과가 없어요';

  @override
  String get cardNoResultsHint => '다른 검색어를 시도해보세요';

  @override
  String get cardPickerNoMatch => '일치하는 카드가 없습니다';

  @override
  String get categoryManageTitle => '카테고리 관리';

  @override
  String get categorySearchHint => '카테고리 검색';

  @override
  String get categoryLoadError => '카테고리 로드 실패';

  @override
  String get categoryNoResults => '검색 결과가 없어요';

  @override
  String get categoryEmpty => '카테고리가 없습니다';

  @override
  String get categoryEmptyHint => '상단 \'추가\' 버튼으로 추가하세요';

  @override
  String categoryHasSubcategories(String type) {
    return '$type · 하위 카테고리 있음';
  }

  @override
  String get categoryAdd => '카테고리 추가';

  @override
  String get categoryEdit => '카테고리 편집';

  @override
  String get categoryNameRequired => '이름을 입력해 주세요.';

  @override
  String get categoryNameTooLong => '이름은 12자 이내로 입력해 주세요.';

  @override
  String get categoryNameDuplicate => '같은 위치에 같은 이름의 카테고리가 있습니다.';

  @override
  String get categoryParent => '상위 카테고리';

  @override
  String get categoryBudgetExceedTitle => '예산 초과 확인';

  @override
  String categoryBudgetExceedMessage(String parent, String amount) {
    return '이동하면 \"$parent\" 예산을 $amount 초과합니다. 그래도 이동할까요?';
  }

  @override
  String get categoryMove => '이동';

  @override
  String get categoryUpdated => '카테고리가 수정되었습니다';

  @override
  String get categoryAdded => '카테고리가 추가되었습니다';

  @override
  String get categoryActionFailed => '실패';

  @override
  String get categoryDeleteTitle => '카테고리 삭제';

  @override
  String categoryDeleteHasChildren(String name) {
    return '\"$name\" 카테고리에 하위 카테고리가 있어 삭제할 수 없어요. 먼저 하위 카테고리를 정리해 주세요.';
  }

  @override
  String categoryDeleteWithBudget(String name) {
    return '예산이 설정되어 있는 카테고리입니다. 삭제 시 예산도 함께 삭제됩니다. \"$name\" 카테고리를 삭제하시겠습니까?';
  }

  @override
  String categoryDeleteConfirm(String name) {
    return '\"$name\" 카테고리를 삭제하시겠어요?';
  }

  @override
  String get categoryDeleteFailed => '삭제 실패';

  @override
  String get categoryNew => '새 카테고리';

  @override
  String categoryPreview(String type) {
    return '$type 카테고리 · 미리보기';
  }

  @override
  String get categoryTypeLabel => '구분';

  @override
  String get categoryOptionalSuffix => ' (선택)';

  @override
  String get categoryParentMoveHint =>
      '다른 상위로 이동할 수 있어요. 최상위로 올리려면 연결된 거래를 옮긴 뒤 새로 만들어 주세요.';

  @override
  String get categoryMakeRoot => '— 최상위 카테고리로 두기 —';

  @override
  String get categoryNamePlaceholder => '예: 반려동물, 부수입';

  @override
  String get categoryIconLabel => '아이콘';

  @override
  String get authLoginPrompt => 'SSO 계정으로 로그인하세요';

  @override
  String get authSsoLogin => 'SSO 로그인';

  @override
  String get authLoginTitle => '로그인';

  @override
  String get authLoginFailed => '로그인 실패';

  @override
  String get authLoginError => '로그인 처리 중 오류';

  @override
  String authSecurityNotHttps(String url) {
    return '보안 오류: SSO 서버가 HTTPS 가 아닙니다 ($url).';
  }

  @override
  String get authStateMismatch => '보안 검증에 실패했어요 (state 불일치). 다시 시도해 주세요.';

  @override
  String get authNoAuthCode => '인가코드를 받지 못했어요. 다시 시도해 주세요.';

  @override
  String get authPageLoadError => '로그인 페이지를 불러오지 못했어요.';

  @override
  String get dutchTitle => '더치페이';

  @override
  String get dutchCreate => '정산 만들기';

  @override
  String get dutchLoadFailed => '더치페이 로드 실패';

  @override
  String get dutchTabActive => '진행 중';

  @override
  String get dutchTabPast => '완료';

  @override
  String get dutchTabFriends => '친구';

  @override
  String get dutchEmptyActiveTitle => '진행 중인 정산이 없어요';

  @override
  String get dutchEmptyActiveSub => '+ 버튼으로 새 정산을 만들어보세요.';

  @override
  String get dutchEmptyPastTitle => '완료된 정산이 없어요';

  @override
  String get dutchEmptyPastSub => '정산을 마치면 여기에 모입니다.';

  @override
  String get dutchEmptyFriendsTitle => '함께 정산한 친구가 없어요';

  @override
  String get dutchEmptyFriendsSub => '정산에 참여자를 추가하면 여기에 모입니다.';

  @override
  String get dutchActionFailed => '실패';

  @override
  String get dutchSettleFailed => '정산 실패';

  @override
  String get dutchDeleteFailed => '삭제 실패';

  @override
  String get dutchToReceive => '받을 돈';

  @override
  String get dutchToSend => '보낼 돈';

  @override
  String dutchFromPeople(int count) {
    return '$count명에게서';
  }

  @override
  String dutchToPeople(int count) {
    return '$count명에게';
  }

  @override
  String get dutchPerPersonLabel => '1인당';

  @override
  String dutchNPeople(int count) {
    return '$count명';
  }

  @override
  String dutchSettledTogetherCount(int count) {
    return '$count회 함께 정산';
  }

  @override
  String get dutchSettled => '정산 완료';

  @override
  String get dutchMe => '나';

  @override
  String get dutchPayer => '결제자';

  @override
  String get dutchNameLabel => '정산 이름';

  @override
  String get dutchNamePlaceholder => '예: 팀 저녁 회식';

  @override
  String get dutchPlaceLabel => '장소 (선택)';

  @override
  String get dutchPlacePlaceholder => '장소 또는 상호명';

  @override
  String get dutchTotalLabel => '총 금액';

  @override
  String get dutchDateLabel => '날짜';

  @override
  String get dutchSelectParticipants => '참여자 선택';

  @override
  String dutchNSelected(int count) {
    return '$count명 선택';
  }

  @override
  String get dutchAddNamePlaceholder => '이름 입력 후 추가';

  @override
  String get dutchAdd => '추가';

  @override
  String get dutchNext => '다음';

  @override
  String get dutchPrev => '이전';

  @override
  String get dutchDetailTitle => '정산 상세';

  @override
  String get dutchParticipant => '참여자';

  @override
  String get dutchSettleAction => '정산 완료 처리';

  @override
  String get dutchDeleteTitle => '더치페이 삭제';

  @override
  String dutchDeleteConfirm(String title) {
    return '\"$title\"을(를) 삭제할까요?';
  }

  @override
  String get dutchRequestAll => '일괄 요청';

  @override
  String dutchRequestSent(String name) {
    return '$name님에게 송금 요청을 보냈어요 (추후 카카오톡·문자 연동 예정)';
  }

  @override
  String dutchRequestSentBulk(int count) {
    return '$count명에게 송금 요청을 보냈어요 (추후 카카오톡·문자 연동 예정)';
  }

  @override
  String get dutchAllSettled => '모든 참여자가 이미 정산을 완료했어요';

  @override
  String dutchNeedsPayment(String amount) {
    return '$amount원 송금 필요';
  }

  @override
  String get dutchNoName => '(이름 없음)';

  @override
  String get dutchMarkPaid => '송금 완료 처리';

  @override
  String get dutchRequest => '요청';

  @override
  String get dutchUnsettled => '미정산';

  @override
  String get dutchStartTitle => '더치페이 시작';

  @override
  String get dutchFromTxDesc =>
      '이 거래를 기준으로 더치페이 정산을 만듭니다. 참여자에게 송금 요청을 보내고, 정산 진행 상황을 추적할 수 있어요.';

  @override
  String get dutchSplitMethod => '분배 방식';

  @override
  String get dutchSplitEqualTitle => 'N분의 1';

  @override
  String get dutchSplitEqualSub => '균등 분배';

  @override
  String get dutchSplitRatioTitle => '비율';

  @override
  String get dutchSplitRatioSub => '인원수·기준';

  @override
  String get dutchSplitCustomTitle => '개별 금액';

  @override
  String get dutchSplitCustomSub => '각자 다르게';

  @override
  String get dutchIncludeMyself => '나도 포함해서 분배';

  @override
  String get dutchIncludeMyselfDesc => '내 몫도 계산됩니다';

  @override
  String get dutchIncludeMyselfOffDesc => '내가 전액 결제, 다른 사람 몫만 받아요';

  @override
  String get dutchSourceSub => '참여자에게 송금 요청';

  @override
  String get dutchRequestMsgLabel => '요청 메시지 (선택)';

  @override
  String get dutchRequestMsgPlaceholder => '참여자에게 함께 보낼 한마디를 적어주세요';

  @override
  String dutchShortBy(String amount) {
    return '합계가 총액보다 $amount원 부족합니다.';
  }

  @override
  String dutchOverBy(String amount) {
    return '합계가 총액보다 $amount원 초과합니다.';
  }

  @override
  String get dutchCreated => '정산이 만들어졌어요';

  @override
  String get expLoadError => '거래를 불러오지 못했습니다';

  @override
  String get expEmptyMonth => '이 달에는 거래가 없습니다';

  @override
  String get expEmptyDay => '이 날의 거래가 없어요';

  @override
  String get expTotal => '합계';

  @override
  String get expFiltering => '필터 중';

  @override
  String expFilteringBy(String name) {
    return '$name 필터 중';
  }

  @override
  String get expViewList => '목록';

  @override
  String get expViewCalendar => '달력';

  @override
  String expTxCount(int count) {
    return '$count건';
  }

  @override
  String get expAddShort => '추가';

  @override
  String get expTransferDone => '이체가 완료되었습니다';

  @override
  String get expActionFailed => '실패';

  @override
  String get expUpdated => '거래가 수정되었습니다';

  @override
  String get expAdded => '거래가 추가되었습니다';

  @override
  String get expDeleteConfirm => '이 거래를 삭제하시겠습니까? 연결된 자산 잔액이 함께 조정됩니다.';

  @override
  String get expDeleted => '거래가 삭제되었습니다';

  @override
  String get expDeleteFailed => '삭제 실패';

  @override
  String get expSplitMismatch => '분할 내역과 금액이 달라요';

  @override
  String expSplitDiff(String total, String sum, String diff) {
    return '새 총액 $total원 · 분할 합계 $sum원 · $diff원 차이';
  }

  @override
  String get expSplitReconcile => '분할 내역 맞추기';

  @override
  String get expPresetLoad => '프리셋 불러오기';

  @override
  String get expPresetApplied => '적용됨';

  @override
  String get expPresetSaveCurrent => '현재 입력값 저장';

  @override
  String get expPresetEmpty =>
      '저장된 프리셋이 없어요. 자주 쓰는 내역을 입력 후 “현재 입력값 저장”을 눌러보세요.';

  @override
  String get expPresetFilled => '프리셋 값이 채워졌어요. 금액·내역만 수정해서 저장하세요.';

  @override
  String get expClear => '해제';

  @override
  String get expPresetManageHint => '설정 → 프리셋 관리';

  @override
  String get expSaveFailed => '저장 실패';

  @override
  String get expPresetSaveTitle => '프리셋으로 저장';

  @override
  String get expPresetNamePlaceholder => '예: 점심 도시락';

  @override
  String expPresetLockAmount(String amount) {
    return '금액 잠금 — 적용 시 $amount원 자동 채움';
  }

  @override
  String get expPayCash => '현금';

  @override
  String get expPayCard => '카드';

  @override
  String get expPayTransfer => '계좌이체';

  @override
  String get expPayOther => '기타';

  @override
  String get expPresetLock => '프리셋 잠금';

  @override
  String get expNoCategoryForType => '이 타입에 해당하는 카테고리가 없습니다';

  @override
  String get expSubcategory => '세부 카테고리';

  @override
  String expTopCategorySuffix(String name) {
    return '$name (상위)';
  }

  @override
  String get expIncomeSource => '수입처';

  @override
  String get expPayee => '거래처';

  @override
  String get expIncomeSourcePlaceholder => '예: (주)포레스트';

  @override
  String get expPayeePlaceholder => '예: 스타벅스 강남점';

  @override
  String get expIncomeMethod => '수입 방식';

  @override
  String get expNone => '선택 안 함';

  @override
  String get expDepositAccount => '입금 계좌';

  @override
  String get expAccountCard => '계좌·카드';

  @override
  String get expAssetLoadError => '자산 로드 실패';

  @override
  String get expWithdrawAccount => '출금 계좌';

  @override
  String get expSelect => '선택';

  @override
  String get expTransferSameAsset => '보낼/받을 자산은 달라야 합니다';

  @override
  String get expFeeOptional => '수수료 (선택)';

  @override
  String get expDateTime => '날짜·시간';

  @override
  String get expMemoPlaceholder => '예: 점심, 회식 등';

  @override
  String get expIncomeDetail => '수입 상세';

  @override
  String get expExpenseDetail => '지출 상세';

  @override
  String get expTxFallback => '거래';

  @override
  String get expUncategorized => '미분류';

  @override
  String get expValueNone => '없음';

  @override
  String expItemsCount(int count) {
    return '$count개';
  }

  @override
  String get expNotSelected => '미선택';

  @override
  String expPrevTxAt(String merchant) {
    return '$merchant에서의 이전 거래';
  }

  @override
  String get expThisMonth => '이번 달';

  @override
  String expTimesCount(int count) {
    return '$count회';
  }

  @override
  String get expItem => '항목';

  @override
  String get expFilterApply => '필터 적용';

  @override
  String expNSelected(int count) {
    return '$count개 선택';
  }

  @override
  String get expPeriodWeek => '이번 주';

  @override
  String get expPeriod3Month => '3개월';

  @override
  String get expPeriodCustom => '직접 선택';

  @override
  String get expStartDate => '시작일';

  @override
  String get expEndDate => '종료일';

  @override
  String get expDateRangeError => '시작일이 종료일보다 늦을 수 없습니다.';

  @override
  String get expTxType => '거래 종류';

  @override
  String get expAmountRange => '금액 범위';

  @override
  String get expMinAmount => '최소 금액';

  @override
  String get expMaxAmount => '최대 금액';

  @override
  String get expSplitSave => '분할 저장';

  @override
  String get expSplitRemove => '분할 해제';

  @override
  String get expSplitLoadError => '분할 내역 로드 실패';

  @override
  String get expAddAmount => '추가 금액';

  @override
  String get expSplitSaved => '분할이 저장되었습니다';

  @override
  String get expSplitRemoveConfirm => '이 거래의 분할 내역을 모두 삭제하시겠습니까?';

  @override
  String get expClearFailed => '해제 실패';

  @override
  String get expSplitMatches => '분할 합계가 총액과 일치해요';

  @override
  String get expSplitSum => '분할 합계';

  @override
  String get expTotalAmount => '총액';

  @override
  String get expSplitTotalChanged => '총액이 바뀌어 분할을 맞춰야 해요';

  @override
  String get expSplitMismatchTotal => '분할 합계가 총액과 달라요';

  @override
  String get expSplitCheckItems => '분할 항목을 확인해주세요';

  @override
  String get expShort => '부족';

  @override
  String get expOver => '초과';

  @override
  String get expQuickAdjust => '빠르게 맞추기';

  @override
  String get expProrate => '비례 배분';

  @override
  String get expProrateDesc => '비중대로 자동 조정';

  @override
  String get expApplyToLargest => '큰 항목 반영';

  @override
  String get expApplyToLargestDesc => '가장 큰 항목에 차액';

  @override
  String get expAdjustItem => '조정 항목';

  @override
  String get expAdjustItemDesc => '부족분을 새 항목으로';

  @override
  String get expRecommended => '추천';

  @override
  String get expSplitDesc =>
      '하나의 결제를 카테고리·항목별로 나누어 기록합니다. 예: 마트에서 식품과 생활품을 함께 결제한 경우.';

  @override
  String get expOriginalTx => '원 거래';

  @override
  String get expAddItem => '항목 추가';

  @override
  String get expSplitEven => '균등 분배';

  @override
  String get expSplitRatio => '분할 비율';

  @override
  String get expDeleteItem => '항목 삭제';

  @override
  String get expItemNamePlaceholder => '항목 이름 (선택)';

  @override
  String get exportTitle => '데이터 내보내기';

  @override
  String exportShareText(String start, String end) {
    return '데이터 내보내기 ($start ~ $end)';
  }

  @override
  String get exportSuccess => '내보내기를 완료했어요';

  @override
  String get exportTypeExpense => '거래 내역';

  @override
  String get exportTypeAsset => '자산·계좌';

  @override
  String get exportTypeBudget => '예산 설정';

  @override
  String get exportTypeCategory => '카테고리';

  @override
  String get exportTypeMemo => '메모';

  @override
  String get exportTypeCalendar => '캘린더 일정';

  @override
  String get exportTypeTodo => '할 일';

  @override
  String get exportFormatCsvDesc => '엑셀·구글시트';

  @override
  String get exportFormatExcelDesc => 'Microsoft Excel';

  @override
  String get exportFormatJsonDesc => '개발자·백업';

  @override
  String get exportPeriodThisMonth => '이번 달';

  @override
  String get exportPeriodLastMonth => '지난 달';

  @override
  String get exportPeriodLast3Months => '최근 3개월';

  @override
  String get exportPeriodThisYear => '올해';

  @override
  String get exportPeriodCustom => '사용자 지정';

  @override
  String get exportPeriodTitle => '기간 선택';

  @override
  String get exportDateRangeError => '시작일이 종료일보다 늦을 수 없어요.';

  @override
  String exportTypesTitle(int count) {
    return '데이터 종류 — $count개 선택됨';
  }

  @override
  String get exportTypesDesc => '내보낼 데이터를 골라주세요. 여러 종류는 ZIP으로 묶입니다.';

  @override
  String exportCount(int count) {
    return '$count건';
  }

  @override
  String get exportFormatTitle => '파일 형식';

  @override
  String get exportMaskLabel => '민감 정보 가리기 (잔액·금액·기관)';

  @override
  String get exportPreview => '미리보기';

  @override
  String get exportRun => '내보내기';

  @override
  String get exportEmpty => '이 기간에 내보낼 데이터가 없어요.';

  @override
  String exportPreviewRows(int count) {
    return '상위 $count행 미리보기';
  }

  @override
  String get fileAttachTitle => '첨부 파일';

  @override
  String get fileTooltipGallery => '갤러리';

  @override
  String get fileTooltipCamera => '카메라';

  @override
  String get fileTooltipFile => '파일';

  @override
  String fileUploadComplete(String name) {
    return '$name 업로드 완료';
  }

  @override
  String get fileUploadFailed => '업로드 실패';

  @override
  String get fileDeleteTitle => '파일 삭제';

  @override
  String fileDeleteConfirm(String name) {
    return '$name 삭제할까요?';
  }

  @override
  String get fileDeleteFailed => '삭제 실패';

  @override
  String get fileLoadError => '첨부 로드 실패';

  @override
  String get fileEmpty => '첨부된 파일 없음';

  @override
  String get moreGroupMoney => '돈 관리';

  @override
  String get moreGroupDaily => '일상';

  @override
  String get moreGroupPersonal => '개인화';

  @override
  String get moreGroupSystem => '계정·시스템';

  @override
  String get moreItemStocks => '증권';

  @override
  String get moreItemStats => '통계·분석';

  @override
  String get moreItemAccountCard => '카드·계좌 관리';

  @override
  String get moreItemCardBenefits => '카드 혜택';

  @override
  String get moreItemDisplay => '표시 설정';

  @override
  String get moreItemAccount => '계정';

  @override
  String get moreDescExpense => '지출 · 수입 · 이체';

  @override
  String get moreDescAsset => '계좌 · 카드 · 투자 · 부채';

  @override
  String get moreDescStocks => '시세 · 보유 · 관심 · 호가';

  @override
  String get moreDescBudget => '월간 · 카테고리별';

  @override
  String get moreDescSavingGoal => '목표 · 진행률';

  @override
  String get moreDescStats => '카테고리 · 트렌드 · 비교';

  @override
  String get moreDescRecurring => '구독 · 고정비';

  @override
  String get moreDescAccountCard => '계좌·카드 추가·편집';

  @override
  String get moreDescCalendar => '일정 · 반복 · 알림';

  @override
  String get moreDescTodo => '마감 · 우선순위 · 태그';

  @override
  String get moreDescMemo => '분류 · 고정 · 검색';

  @override
  String get moreDescDutchPay => '정산 · 친구 · 송금 요청';

  @override
  String get moreDescCardBenefits => '신용·체크 카드 검색';

  @override
  String get moreDescCategories => '지출 · 수입';

  @override
  String get moreDescPresets => '자주 쓰는 내역';

  @override
  String get moreDescDisplay => '테마 · 언어 · 통화';

  @override
  String get moreDescSettings => '전체 설정 메뉴';

  @override
  String get moreDescNotifications => '푸시 · 방해 금지';

  @override
  String get moreDescExport => 'CSV · Excel · JSON';

  @override
  String get moreDescAccount => '프로필 · 보안 · 구독';

  @override
  String get moreSearchHint => '메뉴 검색';

  @override
  String get moreSearchEmpty => '검색 결과가 없습니다';

  @override
  String get settingsGroupDataMgmt => '데이터 관리';

  @override
  String get settingsMenuCategory => '카테고리 관리';

  @override
  String get settingsMenuAccountCard => '계좌·카드 관리';

  @override
  String get settingsMenuBudget => '예산 설정';

  @override
  String get settingsMenuRecurring => '반복 거래 관리';

  @override
  String get settingsMenuPreset => '프리셋 관리';

  @override
  String get settingsGroupTagsLabels => '태그 · 라벨';

  @override
  String get settingsGroupShare => '공유·소통';

  @override
  String get settingsMenuCalendarShare => '캘린더 관리·공유';

  @override
  String get settingsMenuCalendarLabel => '캘린더 라벨';

  @override
  String get settingsGroupApp => '앱 환경';

  @override
  String get settingsMenuAppearance => '표시 설정';

  @override
  String get settingsGroupData => '데이터';

  @override
  String get settingsMenuStorage => '저장공간';

  @override
  String get settingsGroupAccount => '계정';

  @override
  String get settingsMenuAccountMgmt => '계정 관리';

  @override
  String get appearanceTitle => '표시 설정';

  @override
  String get appearanceTheme => '테마';

  @override
  String get appearanceThemeLight => '라이트';

  @override
  String get appearanceThemeLightDesc => '밝은 배경';

  @override
  String get appearanceThemeDark => '다크';

  @override
  String get appearanceThemeDarkDesc => '어두운 배경';

  @override
  String get appearanceThemeSystem => '시스템';

  @override
  String get appearanceThemeSystemDesc => '자동 전환';

  @override
  String get appearancePrivacy => '개인정보 보호';

  @override
  String get appearanceHideAmount => '금액 가리기';

  @override
  String get appearanceHideAmountDesc => '모든 화면의 금액을 ••••로 표시합니다';

  @override
  String get appearanceRegion => '표시 기준 지역';

  @override
  String get appearanceRegionPlaceholder => '지역 선택';

  @override
  String get appearanceRegionDesc => '선택한 지역 기준으로 날짜와 시간이 표시돼요';

  @override
  String get appearanceCurrency => '기본 통화';

  @override
  String get appearanceCurrencyKrw => '대한민국 원';

  @override
  String get appearanceCurrencyUsd => '미국 달러';

  @override
  String get appearanceCurrencyEur => '유로';

  @override
  String get appearanceCurrencyJpy => '일본 엔';

  @override
  String get passwordChanged => '비밀번호가 변경되었습니다';

  @override
  String get passwordChangeFailed => '비밀번호 변경에 실패했습니다.';

  @override
  String get passwordCurrent => '현재 비밀번호';

  @override
  String get passwordNew => '새 비밀번호';

  @override
  String get passwordNewPlaceholder => '8자 이상, 특수문자 포함';

  @override
  String get passwordNewConfirm => '새 비밀번호 확인';

  @override
  String get passwordConfirmPlaceholder => '한 번 더 입력';

  @override
  String get passwordMismatch => '새 비밀번호가 일치하지 않습니다';

  @override
  String get passwordMatched => '새 비밀번호가 일치합니다';

  @override
  String get passwordRuleLength => '8자 이상';

  @override
  String get passwordRuleSpecial => '특수문자 1자 이상';

  @override
  String get passwordSameAsCurrent => '현재 비밀번호와 다른 비밀번호를 입력해주세요';

  @override
  String get passwordChangeAction => '변경';

  @override
  String get accountTitle => '계정';

  @override
  String get accountDefaultName => '사용자';

  @override
  String accountJoined(String date) {
    return '가입 $date';
  }

  @override
  String get accountEditComingSoon => '프로필 편집은 준비중입니다';

  @override
  String get accountSecurity => '보안';

  @override
  String get accountPasswordDesc => '최근 변경 없음';

  @override
  String get accountTwoFa => '2단계 인증';

  @override
  String get accountOn => '사용 중';

  @override
  String get accountOff => '사용 안 함';

  @override
  String get accountBiometric => '생체 인증';

  @override
  String get accountComingSoon => '준비중';

  @override
  String get accountDevices => '로그인된 기기';

  @override
  String get accountCurrentDevice => '현재 기기';

  @override
  String get accountLoginHistory => '로그인 기록';

  @override
  String get accountLast30Days => '최근 30일';

  @override
  String get accountConnected => '연결된 계정';

  @override
  String get accountNotConnected => '연결 안 됨';

  @override
  String get accountConnect => '연결';

  @override
  String accountSocialComingSoon(String name) {
    return '$name 연결은 준비중입니다';
  }

  @override
  String get accountBilling => '구독·결제';

  @override
  String accountNextBilling(String date) {
    return '다음 결제 $date · ';
  }

  @override
  String get accountProActive => 'Pro 이용 중';

  @override
  String get accountProPromo => '증권 투자는 Pro 전용 · 지금 시작하기';

  @override
  String get accountPerMonth => '/ 월';

  @override
  String get accountProStart => 'Pro 시작';

  @override
  String get accountManage => '계정 관리';

  @override
  String get accountLogoutDesc => '이 기기에서만';

  @override
  String get accountWithdraw => '회원 탈퇴';

  @override
  String get accountWithdrawDesc => '영구 삭제';

  @override
  String get accountLogoutConfirm => '정말 로그아웃 하시겠어요?';

  @override
  String get accountWithdrawTitle => '정말 탈퇴하시겠습니까?';

  @override
  String get accountWithdrawConfirm =>
      '회원 탈퇴 시 모든 데이터가 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.';

  @override
  String get notiUnreadPrefix => '읽지 않은 알림 ';

  @override
  String get notiUnreadSuffix => '개';

  @override
  String get notiSettings => '알림 설정';

  @override
  String get notiSettingsLoadError => '설정을 불러오지 못했습니다';

  @override
  String get notiKindTitle => '알림 종류';

  @override
  String get notiKindSubtitle => '필요한 알림만 켜두면 더 편해요.';

  @override
  String get notiPayment => '결제 알림';

  @override
  String get notiPaymentDesc => '결제 예정일 D-1, 결제일 당일 알림';

  @override
  String notiBudgetDesc(int threshold) {
    return '카테고리 예산 $threshold%·100% 도달';
  }

  @override
  String get notiAutoRecord => '자동 기록 알림';

  @override
  String get notiAutoRecordDesc => '반복 거래가 자동으로 기록되었을 때';

  @override
  String get notiDutchPay => '더치페이 알림';

  @override
  String get notiDutchPayDesc => '송금 요청 / 정산 완료 알림';

  @override
  String get notiCalendarDesc => '캘린더 이벤트 시작 15분 전';

  @override
  String get notiWeeklyReport => '주간 리포트';

  @override
  String get notiWeeklyReportDesc => '매주 월요일 오전 9시';

  @override
  String get notiMonthlyReport => '월간 리포트';

  @override
  String get notiMonthlyReportDesc => '매월 1일 오전 9시';

  @override
  String get notiPush => '푸시 알림';

  @override
  String get notiPushOn => '모든 알림이 활성화되어 있어요';

  @override
  String get notiPushOff => '알림이 꺼져 있어요';

  @override
  String get notiThresholdTitle => '예산 알림 임계값';

  @override
  String get notiThresholdCurrent => '현재 ';

  @override
  String get notiThresholdDesc1 => '예산 사용률이 이 값을 넘으면 ';

  @override
  String get notiThresholdWarning => '경고';

  @override
  String get notiThresholdDesc2 => ' 상태로 표시되고 알림을 받습니다. 100%는 ';

  @override
  String get notiThresholdOver => '초과';

  @override
  String get notiThresholdDesc3 => '로 별도 알림이 발생합니다.';

  @override
  String get notiQuietTitle => '방해 금지 시간';

  @override
  String get notiQuietSubtitle => '이 시간에는 알림이 소리·진동 없이 표시됩니다.';

  @override
  String get notiQuietToggle => '방해 금지 사용';

  @override
  String get notiQuietToggleDesc => '시간대를 지정해 자동 무음';

  @override
  String get notiQuietStart => '시작';

  @override
  String get notiQuietEnd => '종료';

  @override
  String get notiSoundTitle => '소리·진동';

  @override
  String get notiSound => '알림음';

  @override
  String get notiSoundDesc => '앱 알림 사운드';

  @override
  String get notiSoundChime => '차임';

  @override
  String get notiSoundDefault => '기본';

  @override
  String get notiSoundNone => '무음';

  @override
  String get notiVibration => '진동';

  @override
  String get notiVibrationDesc => '모바일에서 진동 함께 알림';

  @override
  String get notiEmailTitle => '이메일 알림';

  @override
  String get notiEmailSubtitle => '앱을 잘 안 열어도 이메일로 요약을 받아볼 수 있어요.';

  @override
  String get notiEmailToggle => '이메일 받기';

  @override
  String get notiEmailNone => '등록된 이메일이 없습니다';

  @override
  String get notiEmailFreq => '발송 주기';

  @override
  String get notiEmailDaily => '매일';

  @override
  String get notiEmailWeekly => '매주';

  @override
  String get notiEmailMonthly => '매월';

  @override
  String get presetManageTitle => '프리셋 관리';

  @override
  String get presetLoadError => '프리셋 로드 실패';

  @override
  String get presetDeleteTitle => '프리셋 삭제';

  @override
  String presetDeleteConfirm(String name) {
    return '\"$name\" 프리셋을 삭제할까요? 이미 저장된 거래 내역에는 영향이 없습니다.';
  }

  @override
  String get presetDeleted => '프리셋이 삭제되었습니다';

  @override
  String get presetDeleteFailed => '삭제 실패';

  @override
  String get presetIntroTitle => '프리셋이란?';

  @override
  String get presetIntroBody =>
      '자주 쓰는 내역(점심·커피·교통비 등)을 미리 저장해두면, 내역 추가 화면에서 한 번 탭으로 카테고리·결제수단·내역을 모두 채워넣어요. 금액만 바꿔서 단건으로 저장하기 좋습니다.';

  @override
  String get presetStatSaved => '저장된 프리셋';

  @override
  String get presetStatUses => '누적 사용';

  @override
  String presetUsesCount(int count) {
    return '$count회';
  }

  @override
  String get presetStatType => '지출 / 수입';

  @override
  String get presetSortUsed => '사용 많은 순';

  @override
  String get presetSortRecent => '최근 사용';

  @override
  String get presetSortName => '이름순';

  @override
  String get presetAdd => '프리셋 추가';

  @override
  String get presetAmountEmpty => '금액 비움';

  @override
  String get presetNoCategory => '카테고리 없음';

  @override
  String get presetEmptyTitle => '저장된 프리셋이 없어요';

  @override
  String get presetEmptyDesc => '자주 쓰는 내역을 추가해 매번 입력하는 수고를 줄여보세요.';

  @override
  String get presetEditTitle => '프리셋 수정';

  @override
  String get presetSubmitAdd => '추가';

  @override
  String get presetName => '프리셋 이름';

  @override
  String get presetMerchant => '기본 내역';

  @override
  String get presetMerchantPlaceholder => '예: 한솥 도시락';

  @override
  String get presetSelectNone => '선택 안 함';

  @override
  String get presetAssetCard => '계좌·카드';

  @override
  String get presetAssetLoadError => '자산 로드 실패';

  @override
  String get presetLockToggle => '고정 금액 사용';

  @override
  String get presetLockDesc => '꺼두면 불러올 때 금액이 비어있어요. 매번 다른 금액일 때 편해요.';

  @override
  String get presetLockAmountLabel => '고정 금액';

  @override
  String get presetUpdated => '프리셋이 수정되었습니다';

  @override
  String get presetCreated => '프리셋이 추가되었습니다';

  @override
  String get recurringToggleFailed => '변경 실패';

  @override
  String get recurringDeleteTitle => '반복 거래 삭제';

  @override
  String recurringDeleteConfirm(String name) {
    return '\"$name\" 반복 설정을 삭제할까요?\n이미 기록된 거래는 그대로 남습니다.';
  }

  @override
  String get recurringDeleteFailed => '삭제 실패';

  @override
  String get recurringLoadError => '반복 거래를 불러오지 못했습니다';

  @override
  String get recurringAllList => '전체 목록';

  @override
  String get recurringAdd => '추가';

  @override
  String recurringFilterAll(int count) {
    return '전체 $count';
  }

  @override
  String recurringFilterExpense(int count) {
    return '지출 $count';
  }

  @override
  String recurringFilterIncome(int count) {
    return '수입 $count';
  }

  @override
  String recurringFilterPaused(int count) {
    return '일시정지 $count';
  }

  @override
  String get recurringStatActive => '활성 반복';

  @override
  String recurringCount(int count) {
    return '$count개';
  }

  @override
  String get recurringPaused => '일시정지';

  @override
  String get recurringMonthlyExpense => '매월 고정 지출';

  @override
  String get recurringMonthlyIncome => '매월 고정 수입';

  @override
  String get recurringUpcoming => '다가오는 7일';

  @override
  String recurringUpcomingCount(int count) {
    return '$count건 예정';
  }

  @override
  String get recurringToday => '오늘';

  @override
  String get recurringNoAccount => '계좌 없음';

  @override
  String recurringOccurrences(int executed, int max) {
    return '$executed/$max회';
  }

  @override
  String get recurringNext => '다음';

  @override
  String get recurringStart => '시작';

  @override
  String get recurringEmpty => '해당하는 반복 거래가 없어요';

  @override
  String get recurringIndefinite => '무기한';

  @override
  String get recurringNotifyShort => '알림';

  @override
  String get recurringAddTitle => '반복 거래 추가';

  @override
  String get recurringSaveSubmit => '반복 저장';

  @override
  String get recurringUpdated => '반복 설정이 수정되었습니다';

  @override
  String get recurringSaved => '반복 설정이 저장되었습니다';

  @override
  String get recurringSaveFailed => '저장 실패';

  @override
  String get recurringIntro =>
      '이 거래를 정해진 주기로 자동 반복합니다. 구독료·월세·정기 후원 등에 사용해보세요.';

  @override
  String get recurringFrequencyLabel => '반복 주기';

  @override
  String get recurringDayOfWeekLabel => '요일';

  @override
  String get recurringDayOfMonthLabel => '반복 일자';

  @override
  String get recurringDayNote => '해당 일이 없는 달은 말일에 처리됩니다';

  @override
  String get recurringEndLabel => '종료';

  @override
  String get recurringIndefiniteDesc => '중지할 때까지 계속 반복';

  @override
  String get recurringByCount => '횟수 지정';

  @override
  String get recurringTotal => '총';

  @override
  String get recurringTimesUnit => '회';

  @override
  String get recurringByDate => '종료일 지정';

  @override
  String get recurringOptions => '옵션';

  @override
  String get recurringAutoLog => '자동 기록';

  @override
  String get recurringAutoLogDesc => '해당 일자에 거래를 자동으로 추가합니다';

  @override
  String get recurringNotifyDayBefore => '하루 전 알림';

  @override
  String get recurringNotifyDesc => '결제·이체 예정일 전날 알림을 보냅니다';

  @override
  String get recurringNextDates => '다음 예정일';

  @override
  String get recurringSourceSub => '구독료·월세 등 정기 거래에 쓰여요';

  @override
  String recurringStartFrom(String date) {
    return '$date 시작';
  }

  @override
  String get recurringMerchant => '거래처';

  @override
  String get recurringMerchantPlaceholder => '예: 넷플릭스';

  @override
  String get recurringAssetCard => '계좌·카드';

  @override
  String get recurringAssetLoadError => '자산 로드 실패';

  @override
  String get recurringSelectNone => '선택 안 함';

  @override
  String get recurringStartDateLabel => '반복 시작일';

  @override
  String recurringParentCategory(String name) {
    return '$name (상위)';
  }

  @override
  String get savingGoalLoadError => '저축 목표 로드 실패';

  @override
  String get savingGoalOverallProgress => '전체 진행률';

  @override
  String savingGoalListCount(int n) {
    return '목표 목록 · $n개';
  }

  @override
  String get savingGoalAddAction => '목표 추가';

  @override
  String get savingGoalManagePrompt => '설정에서 저축 목표를 추가해보세요';

  @override
  String get savingGoalManageLink => '관리';

  @override
  String get savingGoalNoDeadline => '기한 없음';

  @override
  String get savingGoalCurrentLabel => '현재 모은 금액';

  @override
  String get savingGoalIconLabel => '아이콘';

  @override
  String get savingGoalEmpty => '아직 저축 목표가 없어요. ‘목표 추가’로 시작해보세요.';

  @override
  String get savingGoalActionFailed => '실패';

  @override
  String get savingGoalAchieved => '달성!';

  @override
  String get savingGoalAdd => '저축 목표 추가';

  @override
  String get savingGoalEdit => '저축 목표 수정';

  @override
  String get savingGoalSubmitAdd => '추가';

  @override
  String get savingGoalDeleteTitle => '저축 목표 삭제';

  @override
  String savingGoalDeleteConfirm(String title) {
    return '\"$title\"을(를) 삭제할까요?';
  }

  @override
  String get savingGoalDeleteFailed => '삭제 실패';

  @override
  String get savingGoalNameLabel => '목표 이름';

  @override
  String get savingGoalNameHint => '예: 비상금';

  @override
  String get savingGoalAmountLabel => '목표 금액';

  @override
  String get savingGoalDeadlineLabel => '마감일 (선택)';

  @override
  String get savingGoalDeadlineHint => '미설정';

  @override
  String get savingGoalColorLabel => '색상';

  @override
  String get searchAdvancedFilter => '고급 필터';

  @override
  String get searchHint => '거래 검색...';

  @override
  String get searchStartHint => '시작';

  @override
  String get searchEndHint => '종료';

  @override
  String get searchFailed => '검색 실패';

  @override
  String get searchEmptyHint => '키워드, 가맹점, 메모로 검색하세요';

  @override
  String get searchNoResults => '결과가 없습니다';

  @override
  String get statsTabTrend => '추이';

  @override
  String get statsTabCompare => '비교';

  @override
  String get statsThisQuarter => '이번 분기';

  @override
  String get statsThisYear => '이번 해';

  @override
  String get statsCustomPeriod => '선택 기간';

  @override
  String get statsLastMonth => '지난 달';

  @override
  String get statsLastQuarter => '지난 분기';

  @override
  String get statsLastYear => '지난 해';

  @override
  String get statsPrevPeriod => '이전 기간';

  @override
  String get statsMomMonth => '전월 대비';

  @override
  String get statsMomQuarter => '전분기 대비';

  @override
  String get statsMomYear => '전년 대비';

  @override
  String get statsMomCustom => '이전 기간 대비';

  @override
  String get statsMomPrevMonth => '전월';

  @override
  String get statsMomPrevQuarter => '전분기';

  @override
  String get statsMomPrevYear => '전년';

  @override
  String get statsDailyAvg => '하루 평균';

  @override
  String get statsMonthlyAvg => '월 평균';

  @override
  String get statsPeriodPickerTitle => '기간 선택';

  @override
  String get statsRange7d => '최근 7일';

  @override
  String get statsRange30d => '최근 30일';

  @override
  String get statsRange3m => '최근 3개월';

  @override
  String get statsRange6m => '최근 6개월';

  @override
  String get statsRange1y => '최근 1년';

  @override
  String get statsSegMonth => '월';

  @override
  String get statsSegQuarter => '분기';

  @override
  String get statsSegYear => '년';

  @override
  String get statsSegCustom => '직접';

  @override
  String get statsNoData => '데이터가 없습니다';

  @override
  String get statsNoDataShort => '데이터 없음';

  @override
  String get statsUnassigned => '미지정';

  @override
  String statsCategoryDetail(String name) {
    return '$name 세부';
  }

  @override
  String statsPeriodSpending(String period) {
    return '$period 지출';
  }

  @override
  String get statsSpendingByCategory => '카테고리별 지출';

  @override
  String get statsNoCategoryData => '카테고리 데이터가 없습니다';

  @override
  String get statsTopMerchantsTitle => '많이 쓴 가맹점 TOP 5';

  @override
  String get statsNoMerchantData => '가맹점 데이터가 없습니다';

  @override
  String get statsNoName => '(이름 없음)';

  @override
  String get statsTimeMorning => '아침';

  @override
  String get statsTimeLunch => '점심';

  @override
  String get statsTimeAfternoon => '오후';

  @override
  String get statsTimeEvening => '저녁';

  @override
  String get statsTimeLateNight => '심야';

  @override
  String get statsTimeDawn => '새벽';

  @override
  String get statsPatternTitle => '요일·시간대 지출 패턴';

  @override
  String get statsPatternDesc => '색이 진할수록 지출이 많은 시간대예요 (단위: 원)';

  @override
  String get statsTooFewTx => '이번 달 거래가 아직 적어요';

  @override
  String get statsLegendLow => '적음';

  @override
  String get statsLegendHigh => '많음';

  @override
  String get statsTotalPrefix => '총';

  @override
  String statsDaysTotal(int days) {
    return '$days일 합계';
  }

  @override
  String get statsMomCalculating => '전월 대비 계산 중…';

  @override
  String get statsMomUnavailable => '전월 비교 불가';

  @override
  String get statsTopCategory => '가장 많이 쓴 카테고리';

  @override
  String get statsTopMerchant => '가장 많이 쓴 가맹점';

  @override
  String get statsIncomeExpenseTrend => '수입·지출 추이';

  @override
  String get statsNoTrendData => '추이 데이터가 없습니다';

  @override
  String get statsAvgIncome => '평균 수입';

  @override
  String get statsAvgExpense => '평균 지출';

  @override
  String get statsNetSavings => '순저축';

  @override
  String get statsAvgSavings => '평균 저축';

  @override
  String get statsSavingsRate => '저축률';

  @override
  String statsSavingsInsight(int pct) {
    return '월 평균 수입의 $pct%를 저축하고 있어요';
  }

  @override
  String get statsDailyNetSavings => '일별 순저축';

  @override
  String get statsMonthlyNetSavings => '월별 순저축';

  @override
  String get statsCatTrendTitle => '주요 카테고리 월별 추이';

  @override
  String get statsCatTrendTop3 => '지출 TOP 3';

  @override
  String get statsIncomeMinusExpense => '수입 − 지출';

  @override
  String statsNoDataFor(String period) {
    return '$period 데이터 없음';
  }

  @override
  String statsCategoryByMom(String mom) {
    return '카테고리별 $mom';
  }

  @override
  String get statsCategoryDelta => '카테고리별 증감';

  @override
  String get statsSortByChange => '변화 큰 순';

  @override
  String get statsNoCompareData => '비교할 데이터가 없습니다';

  @override
  String get statsWeekdayTitle => '요일별 지출 비교';

  @override
  String get statsThisMonthShort => '이번 달';

  @override
  String get statsLastMonthShort => '지난 달';

  @override
  String statsWeekdayInsightDown(String day, String amount) {
    return '$day요일 지출이 지난 달보다 $amount 줄었어요.';
  }

  @override
  String statsWeekdayInsightUp(String day, String amount) {
    return '$day요일 지출이 지난 달보다 $amount 늘었어요.';
  }

  @override
  String get statsWeekdayInsightSame => '요일별 지출이 지난 달과 비슷해요.';

  @override
  String statsVsLastPrefix(String prev) {
    return '$prev보다';
  }

  @override
  String get statsVsLastDirLess => '덜';

  @override
  String get statsVsLastDirMore => '더';

  @override
  String statsVsLastSuffix(String prev) {
    return '썼어요';
  }

  @override
  String get statsCompareDailyAvg => '하루 평균';

  @override
  String get statsCompareTxCount => '거래 건수';

  @override
  String get statsComparePerTx => '건당 평균';

  @override
  String statsCountValue(int count) {
    return '$count건';
  }

  @override
  String get stocksChartTokenFailed => '토큰 발급 실패';

  @override
  String get stocksChartHttpsError => '보안 오류: 차트 WebView 가 HTTPS 가 아닙니다';

  @override
  String get stocksChartInitFailed => '차트 초기화 실패';

  @override
  String get stocksChartLoadFailed => '차트를 불러올 수 없어요';

  @override
  String get stocksSearch => '종목 검색';

  @override
  String get stocksSearchPlaceholder => '종목명 · 티커로 검색 (예: 삼성전자, NVDA)';

  @override
  String stocksSearchNoResults(String query) {
    return '\'$query\' 검색 결과가 없어요';
  }

  @override
  String stocksTabHoldings(int count) {
    return '보유 $count';
  }

  @override
  String stocksTabWatch(int count) {
    return '관심 $count';
  }

  @override
  String get stocksTabDiscover => '발견';

  @override
  String get stocksNoHoldings => '보유 중인 종목이 없어요.';

  @override
  String stocksSharesHeld(String qty) {
    return '$qty주 보유';
  }

  @override
  String get stocksNoWatchlist => '관심 종목이 없어요. 검색해서 별표를 눌러보세요.';

  @override
  String get stocksDetailTitle => '종목 상세';

  @override
  String get stocksMarketHoliday => '휴장';

  @override
  String stocksMarketTrading(String time) {
    return '장중 · $time';
  }

  @override
  String stocksMarketOpensAt(String time) {
    return '개장 $time';
  }

  @override
  String get stocksMarketClosed => '장마감';

  @override
  String get stocksMarketKr => '국내';

  @override
  String get stocksMarketUs => '미국';

  @override
  String get stocksConnectPrompt => '증권 계정을 연결해 주세요';

  @override
  String get stocksConnectDescRealtime =>
      '토스증권 키를 연결하면 시세·보유 종목과\n평가손익을 실시간으로 볼 수 있어요.';

  @override
  String get stocksConnectInSettings => '설정에서 연결하기';

  @override
  String get stocksConnectDesc => '토스증권 키를 연결하면 보유 종목과\n평가손익을 실시간으로 볼 수 있어요.';

  @override
  String get stocksConnectAccount => '계정 연결하기';

  @override
  String get stocksMyEval => '내 투자 평가금액';

  @override
  String get stocksConnectShowAssets => '증권 계정을 연결하면 보유자산이 보여요';

  @override
  String get stocksPurchaseAmount => '매입금액';

  @override
  String get stocksHoldingsLabel => '보유 종목';

  @override
  String get stocksExchangeRate => '환율(USD)';

  @override
  String get stocksSell => '매도';

  @override
  String stocksSellOrderStub(String name) {
    return '$name 매도 주문 — Open API 연동 시 동작';
  }

  @override
  String get stocksBuy => '매수';

  @override
  String stocksBuyOrderStub(String name) {
    return '$name 매수 주문 — Open API 연동 시 동작';
  }

  @override
  String get stocksFeeUs => '미국주식 매매수수료 0.1% · 환전 수수료 별도 적용';

  @override
  String get stocksFeeKr =>
      '국내주식 매매수수료 무료 (2026.6까지) · 이후 KRX 0.015% / NXT 0.014%';

  @override
  String get stocksOrderDisclaimer =>
      '토스증권 Open API 연동 시 실시간 호가·체결가가 반영됩니다.\n시세는 투자 참고용이며 실제 주문은 약관 동의 후 가능합니다.';

  @override
  String get stocksEvalAmount => '평가금액';

  @override
  String get stocksEvalPnl => '평가손익';

  @override
  String get stocksQuantityHeld => '보유수량';

  @override
  String get stocksReturnRate => '수익률';

  @override
  String get stocksDayPnl => '일간 손익';

  @override
  String get stocksAvgPrice => '평균단가';

  @override
  String get stocksFeesTax => '수수료·세금';

  @override
  String get stocksSellable => '매도가능';

  @override
  String get stocksMyHoldings => '내 보유';

  @override
  String get stocksMarket => '시장';

  @override
  String get stocksInstrumentType => '종목 유형';

  @override
  String get stocksInstrumentStock => '주식';

  @override
  String get stocksCurrency => '통화';

  @override
  String get stocksMarketCap => '시가총액';

  @override
  String get stocksUpperLimit => '상한가';

  @override
  String get stocksLowerLimit => '하한가';

  @override
  String get stocksListingDate => '상장일';

  @override
  String get stocksSharesOutstanding => '발행주식수';

  @override
  String get stocksTradingStatus => '거래상태';

  @override
  String get stocksBasicInfo => '기본 정보';

  @override
  String get stocksBidVolume => '매수 잔량';

  @override
  String get stocksAskVolume => '매도 잔량';

  @override
  String get stocksGainers => '급상승';

  @override
  String get stocksLosers => '급하락';

  @override
  String get stocksVolume => '거래량';

  @override
  String get stocksOrderbookLoading => '호가를 불러오는 중이에요';

  @override
  String get stocksOrderbookEmpty => '호가 정보가 없어요';

  @override
  String get stocksTradesLoading => '체결 내역을 불러오는 중이에요';

  @override
  String get stocksTradesEmpty => '체결 내역이 없어요';

  @override
  String get stocksOrderbook => '호가';

  @override
  String get stocksTrades => '체결';

  @override
  String get stocksTradeTime => '체결시각';

  @override
  String get stocksTradePrice => '체결가';

  @override
  String get stocksTradeVolume => '체결량';

  @override
  String get stocksDailyPrices => '일별 시세';

  @override
  String get stocksDailyPricesLoading => '일별 시세를 불러오는 중이에요';

  @override
  String get stocksDailyPricesEmpty => '일별 시세가 없어요';

  @override
  String get stocksDate => '일자';

  @override
  String get stocksClosePrice => '종가';

  @override
  String get stocksChangeRate => '등락률';

  @override
  String get stocksSearchHint => '종목명·심볼로 검색하세요 (국내 + 미국·중국·일본·홍콩·베트남)';

  @override
  String get stocksPriceUnavailable => '토스 시세 미지원 종목이에요 (국내·미국만 제공)';

  @override
  String get stocksRankingLoading => '랭킹을 불러오는 중…';

  @override
  String get stocksRankingEmpty => '집계된 랭킹이 없어요';

  @override
  String get stocksWatchDefaultGroupName => '관심';

  @override
  String get stocksWatchGroupAdd => '그룹 추가';

  @override
  String get stocksWatchGroupRename => '그룹 이름 변경';

  @override
  String get stocksWatchGroupDelete => '그룹 삭제';

  @override
  String get stocksWatchGroupNamePlaceholder => '그룹 이름';

  @override
  String get stocksWatchGroupDeleteConfirm => '그룹과 담긴 종목이 함께 삭제됩니다. 계속할까요?';

  @override
  String get stocksWatchGroupSaveFail => '관심목록 그룹 저장에 실패했어요';

  @override
  String get stocksWatchAddFail => '관심 등록에 실패했어요';

  @override
  String get stocksMarketToggleKr => '국내';

  @override
  String get stocksMarketToggleUs => '미국';

  @override
  String get todoAdd => '할 일 추가';

  @override
  String get todoEditTitle => '할 일 수정';

  @override
  String get todoDeleteTitle => '할 일 삭제';

  @override
  String todoDeleteConfirm(String title) {
    return '\"$title\" 을(를) 삭제할까요?';
  }

  @override
  String get todoDetail => '자세히';

  @override
  String get todoCompletionRate => '완료율';

  @override
  String get todoQuickAddPlaceholder => '할 일을 입력하고 Enter';

  @override
  String get todoTitlePlaceholder => '할 일을 적어주세요';

  @override
  String get todoTitleRequired => '제목을 입력해주세요';

  @override
  String get todoDueDate => '마감일';

  @override
  String get todoUnset => '미설정';

  @override
  String get todoTag => '태그';

  @override
  String get todoTagSelect => '태그 선택';

  @override
  String get todoPriorityLabel => '우선순위';

  @override
  String get todoPriorityImportant => '중요';

  @override
  String get todoPriorityRelaxed => '여유';

  @override
  String get todoContentLabel => '상세 내용 (선택)';

  @override
  String get todoContentPlaceholder => '예: # 제목 / **굵게** / - 항목 / - [ ] 체크';

  @override
  String get todoEditMode => '편집';

  @override
  String get todoPreview => '미리보기';

  @override
  String get todoNoContent => '내용 없음';

  @override
  String get todoEmptyToday => '오늘 할 일이 없어요';

  @override
  String get todoEmptyWeek => '이번 주는 한가해요';

  @override
  String get todoEmptyDone => '아직 완료된 일이 없어요';

  @override
  String get todoEmptyAll => '할 일이 없어요';

  @override
  String get todoEmptyDoneHint => '할 일을 완료하면 여기에 모입니다.';

  @override
  String get todoEmptyAddHint => '위 입력칸으로 빠르게 추가해보세요.';

  @override
  String get todoNewProject => '새 프로젝트';

  @override
  String get todoProjectNamePlaceholder => '프로젝트 이름';

  @override
  String get todoDescOptional => '설명 (선택)';

  @override
  String get todoAdding => '추가 중...';

  @override
  String get todoAddProject => '프로젝트 추가';

  @override
  String get todoRegisteredProjects => '등록된 프로젝트';

  @override
  String get todoNoProjects => '등록된 프로젝트가 없습니다';

  @override
  String get todoDeleteProjectTitle => '프로젝트 삭제';

  @override
  String todoDeleteProjectConfirm(String name) {
    return '\"$name\" 프로젝트를 삭제하시겠어요? 연결된 할 일은 프로젝트 미지정으로 변경됩니다.';
  }

  @override
  String get todoNewTag => '새 태그';

  @override
  String get todoTagNamePlaceholder => '태그 이름';

  @override
  String get todoRegisteredTags => '등록된 태그';

  @override
  String get todoNoTags => '등록된 태그가 없습니다';

  @override
  String get todoDeleteTagTitle => '태그 삭제';

  @override
  String todoDeleteTagConfirm(String name) {
    return '\"$name\" 태그를 삭제하시겠어요?';
  }

  @override
  String get todoActionFailed => '실패';

  @override
  String get todoAddFailed => '추가 실패';

  @override
  String get todoDeleteFailed => '삭제 실패';

  @override
  String get todoUpdateFailed => '수정 실패';

  @override
  String get todoStatusChangeFailed => '상태 변경 실패';

  @override
  String get todoMoveFailed => '이동 실패';

  @override
  String get todoLoadError => '할 일 로드 실패';

  @override
  String get todoProjectLoadError => '프로젝트 로드 실패';

  @override
  String get todoTagLoadError => '태그 로드 실패';

  @override
  String get todoSubtaskLoadError => '하위 작업 로드 실패';

  @override
  String get subManageTitle => '구독 관리';

  @override
  String get subUsingPro => 'Porest Pro 이용 중';

  @override
  String get subUsingFree => 'Free 플랜 이용 중';

  @override
  String subNextBilling(String date, String amount) {
    return '다음 결제 $date · $amount';
  }

  @override
  String get subFreeLockedDesc => '증권·가져오기 등 Pro 기능이 잠겨 있어요';

  @override
  String get subSpotlightTitle => '증권 투자는 Pro 전용이에요';

  @override
  String get subSpotlightDesc =>
      '실시간 시세·호가, 국내외 종목 검색, 관심종목, 보유 손익까지 — Pro를 구독하면 증권 탭이 바로 열려요.';

  @override
  String get subCycleMonthly => '월간';

  @override
  String subCycleYearlyOff(int pct) {
    return '연간 $pct%↓';
  }

  @override
  String get subUnitMonth => '월';

  @override
  String get subUnitYear => '년';

  @override
  String subYearlyPerMonth(String amount, int pct) {
    return '월 $amount 꼴 · $pct% 절약';
  }

  @override
  String get subMonthlyBilling => '월 단위 결제';

  @override
  String get subFeatureCompare => '기능 비교';

  @override
  String get subCurrentPlan => '현재 플랜';

  @override
  String get subFreeCaption => '기본 가계부 기능';

  @override
  String get subFeatureColumn => '기능';

  @override
  String get subFeatLedger => '가계부 · 자산 관리';

  @override
  String get subFeatBudget => '예산 · 저축 목표 · 캘린더';

  @override
  String get subFeatMonthlyTx => '월 거래 기록';

  @override
  String get subFeatTxLimit => '100건';

  @override
  String get subFeatUnlimited => '무제한';

  @override
  String get subFeatSecurities => '증권 — 실시간 시세 · 종목 검색 · 관심종목';

  @override
  String get subFeatImportExport => 'CSV · Excel 가져오기 / 내보내기';

  @override
  String get subFeatCalendarShare => '다중 캘린더 공유';

  @override
  String get subFeatCardRec => '카드 혜택 추천';

  @override
  String get subStarted => 'Porest Pro 구독이 시작되었어요';

  @override
  String get subFailed => '구독에 실패했어요';

  @override
  String get subCancelConfirmTitle => '구독을 해지할까요?';

  @override
  String subCancelConfirmMsg(String date) {
    return '해지하면 $date부터 Free 플랜으로 전환되고 증권 탭이 잠겨요. 그 전까지는 Pro 기능을 계속 쓸 수 있어요.';
  }

  @override
  String get subCancel => '구독 해지';

  @override
  String get subKeep => '유지하기';

  @override
  String get subCanceled => '구독을 해지했어요';

  @override
  String get subCancelFailed => '해지에 실패했어요';

  @override
  String get subNextBillingDate => '다음 결제일';

  @override
  String get subProcessing => '처리 중…';

  @override
  String get subStartPro => 'Pro 시작하기';

  @override
  String get subTossSectionTitle => '증권 데이터 연동';

  @override
  String get subTossConnectTitle => '토스증권 연결';

  @override
  String get subTossConnectDesc => '본인 API 키를 등록하면 보유 주식·시세를 자동으로 가져와요';

  @override
  String get subConnected => '연결됨';

  @override
  String subTossLastVerified(String date) {
    return '마지막 검증 · $date';
  }

  @override
  String get subTossCollecting => '보유 주식·시세 자동 수집 중';

  @override
  String get subTossKeyConnected => '토스증권 API 키 연결됨';

  @override
  String get subTossIdPlaceholder => '토스증권 개발자센터 발급 Client ID';

  @override
  String get subConnecting => '연결 중…';

  @override
  String get subConnect => '연결하기';

  @override
  String get subTossConnected => '토스증권 계정을 연결했어요';

  @override
  String get subTossInvalidCred => '인증정보가 올바르지 않아요';

  @override
  String get subTossDisconnected => '토스증권 연결을 해제했어요';

  @override
  String get subDisconnectFailed => '해제에 실패했어요';

  @override
  String get subTossKeyNotice =>
      '키는 서버에 암호화되어 저장되며 본인만 사용합니다. 발급은 토스증권 개발자센터에서.';

  @override
  String get memoNew => '새 메모';

  @override
  String get memoEditTitle => '메모 수정';

  @override
  String get memoAdd => '추가';

  @override
  String get memoLoadError => '메모 로드 실패';

  @override
  String memoTagAll(int count) {
    return '전체 $count';
  }

  @override
  String memoSectionPinned(int count) {
    return '고정 · $count';
  }

  @override
  String memoSectionAll(int count) {
    return '모든 메모 · $count';
  }

  @override
  String memoActionFailed(String message) {
    return '실패: $message';
  }

  @override
  String get memoEmptyDesc => '생각이 떠오를 때, 새 메모를 만들어보세요.';

  @override
  String get memoSearchEmptyDesc => '다른 검색어를 입력해보세요.';

  @override
  String get memoUntitled => '(제목 없음)';

  @override
  String get memoDeleteTitle => '메모 삭제';

  @override
  String get memoDeleteConfirm => '이 메모를 삭제할까요?';

  @override
  String memoDeleteFailed(String message) {
    return '삭제 실패: $message';
  }

  @override
  String get memoFieldTitle => '제목';

  @override
  String get memoTitleRequired => '제목을 입력해주세요';

  @override
  String get memoFieldContent => '내용';

  @override
  String get memoContentPlaceholder => '여기에 메모를 작성해주세요';

  @override
  String get memoFieldTag => '태그';

  @override
  String get memoPinToTop => '상단에 고정';

  @override
  String get memoFieldColor => '색상';

  @override
  String get dateToday => '오늘';

  @override
  String get dateTomorrow => '내일';

  @override
  String get dateYesterday => '어제';

  @override
  String dateInDays(int n) {
    return '$n일 후';
  }

  @override
  String dateDaysAgo(int n) {
    return '$n일 전';
  }

  @override
  String get dateJustNow => '방금';

  @override
  String dateMinutesAgo(int n) {
    return '$n분 전';
  }

  @override
  String dateHoursAgo(int n) {
    return '$n시간 전';
  }

  @override
  String get todoNoDue => '마감일 없음';

  @override
  String todoGroupLabel(String label, int count) {
    return '$label · $count건';
  }

  @override
  String dayN(int d) {
    return '$d일';
  }

  @override
  String weekN(int n) {
    return '$n주';
  }

  @override
  String get countUnit => '건';

  @override
  String get dayUnit => '일';

  @override
  String get constHeroTodayTarget => '오늘의 목표 별자리';

  @override
  String constHeroCollectedBang(String name) {
    return '$name 수집!';
  }

  @override
  String constHeroStarlightCount(int lit, int goal) {
    return '$lit/$goal 별빛';
  }

  @override
  String get constHeroCaptionDone => '도감에 새겨졌어요 · 완료할수록 더 반짝여요';

  @override
  String constHeroCaptionProgress(int count) {
    return '오늘 $count건 완료';
  }

  @override
  String constHeroCaptionMemo(int count) {
    return '메모 별빛 +$count';
  }

  @override
  String constHeroCaptionRemain(int count) {
    return '$count별 남음';
  }

  @override
  String get constHeroCaptionEmpty => '할 일을 완료하면 별이 켜져요';

  @override
  String constHeroStreak(int count) {
    return '연속 관측 $count일';
  }

  @override
  String constHeroGuardInfo(int count) {
    return '보호 $count · 중요 +3 · 보통 +2 · 여유 +1';
  }

  @override
  String get constMySkyTitle => '나의 밤하늘';

  @override
  String constMySkyTotal(int count) {
    return '누적 $count개';
  }

  @override
  String get constMySkySubtitle => '최근 2주 · 흐린 밤도 기록에 남아요';

  @override
  String get constCollectionTitle => '별자리 도감';

  @override
  String constCollectionProgress(int collected, int total) {
    return '$collected/$total 수집';
  }

  @override
  String get constCollectionSubtitle => '별 개수만큼 별빛을 모으면 수집돼요';

  @override
  String get constCollectionTodayBadge => '오늘의 목표';

  @override
  String constCollectionStarCount(int count) {
    return '별 $count개';
  }

  @override
  String constCollectionTimes(int count) {
    return '$count회';
  }

  @override
  String get constCollectionNotCollected => '미수집';

  @override
  String get constDetailTitle => '별자리 도감';

  @override
  String get constDetailNotMet => '아직 만나지 못한 별자리예요';

  @override
  String constDetailCollectedTimes(int count) {
    return '지금까지 $count번 수집했어요';
  }

  @override
  String constDetailHint(int count) {
    return '하루에 별빛 $count개를 모으면 수집돼요 · 매일 새 목표 별자리가 떠요';
  }

  @override
  String get todoDetailTitle => '할 일 상세';

  @override
  String get todoDetailStatus => '상태';

  @override
  String get todoStatusPending => '대기';

  @override
  String get todoDetailCompletedAt => '완료 일시';

  @override
  String get todoDetailContent => '상세 내용';

  @override
  String get memoDetailTitle => '메모 상세';

  @override
  String get memoDetailPinned => '고정됨';

  @override
  String get memoDetailNoContent => '내용 없음';

  @override
  String get calEventDetailTitle => '일정 상세';

  @override
  String get calDetailNone => '없음';

  @override
  String get exportTab => '내보내기';

  @override
  String get importTab => '가져오기';

  @override
  String get importSourceTitle => '어떤 앱에서 가져오나요?';

  @override
  String get importSourceDesc => '기존에 쓰던 가계부를 고르면 열 구조를 자동으로 맞춰드려요';

  @override
  String get importSourcePorest => 'Porest 백업';

  @override
  String get importSourcePorestDesc => '내보내기 파일 다시 가져오기';

  @override
  String get importSourceEasybudget => '편한가계부·머니매니저';

  @override
  String get importSourceEasybudgetDesc => 'Excel 백업';

  @override
  String get importSourceBanksalad => '뱅크샐러드';

  @override
  String get importSourceBanksaladDesc => '가계부 내역';

  @override
  String get importSourceToss => '토스';

  @override
  String get importSourceTossDesc => '거래내역';

  @override
  String get importSourceCustom => '직접 매핑';

  @override
  String get importSourceCustomDesc => 'CSV·Excel 직접 연결';

  @override
  String get importUploadTitle => '파일 업로드';

  @override
  String get importUploadDesc =>
      'CSV 또는 Excel(.xlsx, .xls) 파일을 올려주세요. 최대 10MB.';

  @override
  String get importDropTitle => '파일 선택';

  @override
  String get importDropHint => '.csv · .xlsx · .xls 지원';

  @override
  String get importAnalyzing => '파일 분석 중…';

  @override
  String get importNotice =>
      '가져온 데이터는 기존 거래에 추가되며 덮어쓰지 않아요. 미리보기에서 중복·오류를 확인할 수 있어요.';

  @override
  String get importFileTitle => '가져올 파일';

  @override
  String importRowsDetected(int total, int valid) {
    return '$total개 행 · 유효 $valid건';
  }

  @override
  String get importChange => '변경';

  @override
  String get importMapTitle => '열 매핑';

  @override
  String get importMapDesc => '파일의 열을 가계부 항목에 연결하세요. 자동 감지값을 바꿀 수 있어요.';

  @override
  String get importNotMapped => '가져오지 않음';

  @override
  String get importFieldSubcategory => '소분류';

  @override
  String get importFieldTime => '시간';

  @override
  String get importFieldMerchant => '거래처';

  @override
  String get importFieldPaymentMethod => '결제수단';

  @override
  String importBlockedTitle(String names) {
    return '$names 카테고리에 거래가 직접 등록돼 있어 하위 분류를 만들 수 없어요';
  }

  @override
  String get importBlockedDesc =>
      '해당 대분류를 쓰는 행은 저장에 실패해요. 그 카테고리의 거래를 하위로 옮기거나 파일의 분류를 바꿔주세요';

  @override
  String get categoryMoveTxAction => '옮기기';

  @override
  String get categoryMoveTxTitle => '거래 옮기기';

  @override
  String get categoryMoveTxEntry => '거래 옮기기';

  @override
  String get categoryMoveTxEntryDesc =>
      '거래가 달린 카테고리는 하위 분류를 만들 수 없어요. 거래를 옮기면 만들 수 있어요';

  @override
  String categoryMoveTxDesc(String name) {
    return '$name 에 달린 거래·반복거래·분할을 모두 옮겨요';
  }

  @override
  String get categoryMoveTxModeNew => '새 하위 만들기';

  @override
  String get categoryMoveTxModeExisting => '기존 카테고리로';

  @override
  String get categoryMoveTxChildName => '만들 하위 이름';

  @override
  String get categoryMoveTxChildPlaceholder => '예: 강의';

  @override
  String categoryMoveTxNewHint(String name) {
    return '$name 아래에 만들고 거래를 모두 그리로 옮겨요. 그러면 다른 하위도 만들 수 있어요';
  }

  @override
  String get categoryMoveTxTarget => '옮길 카테고리';

  @override
  String get categoryMoveTxTargetPlaceholder => '카테고리 선택';

  @override
  String get categoryMoveTxHint => '같은 유형의 말단 카테고리만 고를 수 있어요';

  @override
  String get categoryMoveTxNoTarget => '옮길 수 있는 카테고리가 없어요. 먼저 하나 만들어주세요';

  @override
  String categoryMoveTxDone(int count) {
    return '$count건을 옮겼어요';
  }

  @override
  String get importFieldDate => '날짜';

  @override
  String get importFieldType => '수입/지출';

  @override
  String get importFieldAmount => '금액';

  @override
  String get importFieldCategory => '카테고리';

  @override
  String get importFieldAsset => '자산·결제수단';

  @override
  String get importFieldMemo => '메모';

  @override
  String importPreviewDesc(int dup) {
    return '중복 의심 $dup건';
  }

  @override
  String get importIncome => '수입';

  @override
  String get importExpense => '지출';

  @override
  String get importDupBadge => '중복?';

  @override
  String get importOptionsTitle => '가져오기 옵션';

  @override
  String get importOptDupSkip => '중복 거래 건너뛰기';

  @override
  String importOptDupSkipDesc(int dup) {
    return '날짜·금액·내용이 같은 $dup건을 제외해요';
  }

  @override
  String get importOptAutoCat => '새 카테고리 자동 생성';

  @override
  String get importOptAutoCatDesc => '없는 카테고리는 자동으로 만들어요';

  @override
  String get importPrev => '이전';

  @override
  String importDoImport(int count) {
    return '$count건 가져오기';
  }

  @override
  String get importDoneTitle => '가져오기 완료';

  @override
  String importDoneCount(int count) {
    return '$count건을 가져왔어요';
  }

  @override
  String importDoneDetail(int skipped, int failed) {
    return '건너뜀 $skipped · 실패 $failed';
  }

  @override
  String get importAnother => '다른 파일 가져오기';

  @override
  String get importStepUpload => '파일 선택';

  @override
  String get importStepMapping => '열 매핑';

  @override
  String get importStepDone => '완료';

  @override
  String get calDetailDday => 'D-DAY';

  @override
  String calDetailDdayLeft(int n) {
    return 'D-$n';
  }

  @override
  String calDetailDdayPast(int n) {
    return '$n일 지남';
  }

  @override
  String calDetailDurationH(int h) {
    return '$h시간';
  }

  @override
  String calDetailDurationHM(int h, int m) {
    return '$h시간 $m분';
  }

  @override
  String calDetailDurationM(int m) {
    return '$m분';
  }

  @override
  String get calDetailMemo => '메모';

  @override
  String get calDetailRepeat => '반복';

  @override
  String get categoryReorderEdit => '편집';

  @override
  String get categoryReorderHint =>
      '핸들을 잡고 위·아래로 끌어 순서를 바꿔요. 상위 카테고리끼리·하위 카테고리끼리 이동돼요.';

  @override
  String get txmSpendSummary => '소비 요약';

  @override
  String get txmInsightLessPre => '지난달보다 ';

  @override
  String txmInsightLessHl(String amount) {
    return '$amount 덜';
  }

  @override
  String get txmInsightLessPost => ' 쓰는 중';

  @override
  String get txmInsightMorePre => '지난달보다 ';

  @override
  String txmInsightMoreHl(String amount) {
    return '$amount 더';
  }

  @override
  String get txmInsightMorePost => ' 쓰는 중';

  @override
  String get txmInsightSame => '지난달과 비슷하게 쓰고 있어요';

  @override
  String get txmInsightNone => '이 달에는 거래 내역이 없어요';

  @override
  String get txmInsightTopCatPre => '이번 달 ';

  @override
  String get txmInsightTopCatPost => '에 가장 많이 썼어요';

  @override
  String txmPrevMonthBtn(String month) {
    return '$month 이용 내역 보기';
  }

  @override
  String txmEmptyMonth(String month) {
    return '$month 거래가 없어요';
  }

  @override
  String get txmEmptyMonthDesc => '다른 달을 살펴보거나 첫 거래를 추가해보세요.';

  @override
  String get txmToday => '오늘';

  @override
  String get txmYesterday => '어제';

  @override
  String expChipMin(String amount) {
    return '$amount 이상';
  }

  @override
  String expChipMax(String amount) {
    return '$amount 이하';
  }

  @override
  String tdmTodayLeft(int count) {
    return '오늘 할 일 $count개';
  }

  @override
  String get tdmTodayDone => '오늘 할 일 끝!';

  @override
  String get tdmNightSkyBtn => '밤하늘';

  @override
  String tdmStarlightHint(int lit, int goal, int left, String name) {
    return '별빛 $lit/$goal · $left개 더 모으면 $name 수집';
  }

  @override
  String tdmCollectedHint(String name, int streak) {
    return '$name 수집 완료 · 연속 $streak일';
  }

  @override
  String tdmDoneRatio(int done, int total) {
    return '$done/$total 완료';
  }

  @override
  String get tdmFilterTag => '태그';

  @override
  String get tdmHideDone => '완료한 할 일 숨기기';

  @override
  String tdmEmptyMonth(String month) {
    return '$month 할 일이 없어요';
  }

  @override
  String get tdmEmptyMonthDesc => '오른쪽 아래 + 버튼으로 추가해보세요.';

  @override
  String get tdmEmptyFilter => '조건에 맞는 할 일이 없어요';

  @override
  String get tdmEmptyFilterDesc => '필터를 조정하거나 초기화해보세요.';

  @override
  String tdmStarToastGain(int gain, int left) {
    return '별빛 +$gain · 수집까지 $left별';
  }

  @override
  String tdmStarToastCollected(int gain) {
    return '별빛 +$gain · 오늘의 별자리 수집!';
  }

  @override
  String get nightSkyTitle => '밤하늘';

  @override
  String get forestReportTitle => '관측 리포트';

  @override
  String get fcolViewCta => '감상하기';

  @override
  String get fcolPreviewCta => '미리보기';

  @override
  String fcolLockedHint(int count) {
    return '별빛 $count개를 하룻밤에 모으면 만날 수 있어요.';
  }

  @override
  String get frpObsResult => '관측 결과 :';

  @override
  String frpObsToday(String name, int lit, int goal) {
    return '$name $lit/$goal 진행 중';
  }

  @override
  String frpObsCollected(String name) {
    return '$name 수집!';
  }

  @override
  String get frpObsWithered => '흐린 밤 · 구름 보호로 스트릭 유지';

  @override
  String get frpObsRest => '쉬어간 밤';

  @override
  String frpStampDays(int count) {
    return '$count일째';
  }

  @override
  String get frpStampLabel => '연속 관측!';

  @override
  String get frpStarGather => '별빛 모으기';

  @override
  String frpPctBadge(int pct) {
    return '$pct% 달성';
  }

  @override
  String get frpTileStar => '모은 별빛';

  @override
  String frpTileStarVal(int count) {
    return '$count개';
  }

  @override
  String get frpTileDone => '완료한 할 일';

  @override
  String frpTileDoneVal(int count) {
    return '$count건';
  }

  @override
  String get frpAnalysis => '별빛 분석';

  @override
  String frpLegendItem(String label, int count) {
    return '$label 완료: $count';
  }

  @override
  String get frpMissed => '못다 켠 별';

  @override
  String get frpMissedAllDone => '오늘 하늘의 별을 모두 켰어요. 남은 별빛은 내일 밤으로!';

  @override
  String frpMissedCount(int count) {
    return '$count개';
  }

  @override
  String get frpFuture => '아직 오지 않은 밤이에요';

  @override
  String frpAsOf(String ts) {
    return '$ts 기준';
  }

  @override
  String get settingsMenuTodoTag => '할일 태그';

  @override
  String ttagUsage(int count) {
    return '$count건에 사용 중';
  }

  @override
  String calLabelUsage(Object count) {
    return '$count건에 사용 중';
  }

  @override
  String get ttagEditTitle => '태그 수정';

  @override
  String fcolOwnBadge(int count) {
    return '수집 $count회';
  }

  @override
  String get ttagTitle => '할일 태그';

  @override
  String get ttagDesc => '할 일에 붙이는 태그예요. 리스트 필터와 태그별 분포에 사용돼요.';

  @override
  String get ttagAddCta => '태그 추가';

  @override
  String get ttagColorLabel => '색상';

  @override
  String get ttagNameLabel => '이름';

  @override
  String get ttagEmpty => '태그가 없어요';

  @override
  String ttagDeleteDesc(int count) {
    return '이 태그를 쓰는 할 일 $count건은 태그 없음으로 남아요.';
  }

  @override
  String get iconPickerTitle => '아이콘 선택';

  @override
  String get iconPickerSearchHint => '아이콘 검색...';

  @override
  String get iconPickerNone => '없음';

  @override
  String get iconPickerNoResults => '검색 결과가 없습니다';

  @override
  String iconPickerResultCount(int count) {
    return '$count개 결과';
  }

  @override
  String iconPickerTotalHint(int count) {
    return '전체 $count개 · 스크롤해서 더 보기';
  }
}
