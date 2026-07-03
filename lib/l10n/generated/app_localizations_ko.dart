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
  String get navSavingGoals => '저금 목표';

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
  String get todoStatusPending => '대기';

  @override
  String get todoStatusInProgress => '진행중';

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
  String get todoProjectMgmt => '프로젝트 관리';

  @override
  String get todoTagMgmt => '태그 관리';

  @override
  String get todoViewKanban => '칸반 보기';

  @override
  String get todoViewList => '리스트 보기';

  @override
  String get memoTitle => '메모';

  @override
  String get memoEmpty => '메모가 없습니다';

  @override
  String get memoSearchEmpty => '검색 결과가 없습니다';

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
  String get calHolidayMgmt => '공휴일 관리';

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
  String get calHolidayNamePlaceholder => '휴일 이름';

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
  String get calAddCustomHoliday => '사용자 휴일 추가';

  @override
  String get calRepeatYearlyLabel => '매년 반복';

  @override
  String get calAdd => '추가';

  @override
  String calYearHolidays(int year) {
    return '$year년 휴일';
  }

  @override
  String get calNoHolidays => '등록된 휴일이 없습니다';

  @override
  String get calDeleteHolidayTitle => '휴일 삭제';

  @override
  String calDeleteHolidayConfirm(String name) {
    return '$name 삭제할까요?';
  }

  @override
  String get calHolidayTypeCustom => '사용자';

  @override
  String get calHolidayTypeSubstitute => '대체';

  @override
  String get calHolidayTypePublic => '공휴일';

  @override
  String get calActionFailed => '실패';

  @override
  String get calSaveFailed => '저장 실패';

  @override
  String get calDeleteFailed => '삭제 실패';

  @override
  String get calAddFailed => '추가 실패';

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
  String get calHolidayLoadError => '휴일 로드 실패';

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
  String get categoryNameDuplicate => '같은 이름의 카테고리가 있습니다.';

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
}
