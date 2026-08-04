import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// 앱 이름
  ///
  /// In ko, this message translates to:
  /// **'POREST Desk'**
  String get appTitle;

  /// No description provided for @actionSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get actionEdit;

  /// No description provided for @actionCreate.
  ///
  /// In ko, this message translates to:
  /// **'생성'**
  String get actionCreate;

  /// No description provided for @actionConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get actionConfirm;

  /// No description provided for @actionClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get actionRetry;

  /// No description provided for @actionApply.
  ///
  /// In ko, this message translates to:
  /// **'적용'**
  String get actionApply;

  /// No description provided for @actionReset.
  ///
  /// In ko, this message translates to:
  /// **'초기화'**
  String get actionReset;

  /// No description provided for @actionSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get actionSearch;

  /// No description provided for @actionLoading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get actionLoading;

  /// No description provided for @actionDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get actionDone;

  /// No description provided for @actionBack.
  ///
  /// In ko, this message translates to:
  /// **'뒤로'**
  String get actionBack;

  /// No description provided for @actionEditLabel.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get actionEditLabel;

  /// No description provided for @pickDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜 선택'**
  String get pickDate;

  /// No description provided for @pickTime.
  ///
  /// In ko, this message translates to:
  /// **'시간 선택'**
  String get pickTime;

  /// No description provided for @searchResultsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요'**
  String get searchResultsEmpty;

  /// No description provided for @unlockTitle.
  ///
  /// In ko, this message translates to:
  /// **'금액 보기 인증'**
  String get unlockTitle;

  /// No description provided for @unlockBody.
  ///
  /// In ko, this message translates to:
  /// **'금액을 다시 보려면 비밀번호로 본인 확인이 필요해요.'**
  String get unlockBody;

  /// No description provided for @unlockPasswordLabel.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get unlockPasswordLabel;

  /// No description provided for @unlockPasswordHint.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 입력'**
  String get unlockPasswordHint;

  /// No description provided for @unlockMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 일치하지 않습니다.'**
  String get unlockMismatch;

  /// No description provided for @stateNoData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get stateNoData;

  /// No description provided for @stateError.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했습니다'**
  String get stateError;

  /// No description provided for @stateEmpty.
  ///
  /// In ko, this message translates to:
  /// **'표시할 항목이 없어요'**
  String get stateEmpty;

  /// No description provided for @languageKorean.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKorean;

  /// No description provided for @languageEnglish.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get languageSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @navDashboard.
  ///
  /// In ko, this message translates to:
  /// **'대시보드'**
  String get navDashboard;

  /// No description provided for @navTodo.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get navTodo;

  /// No description provided for @navCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get navCalendar;

  /// No description provided for @navMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get navMemo;

  /// No description provided for @navTimer.
  ///
  /// In ko, this message translates to:
  /// **'타이머'**
  String get navTimer;

  /// No description provided for @navExpense.
  ///
  /// In ko, this message translates to:
  /// **'가계부'**
  String get navExpense;

  /// No description provided for @navAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get navAsset;

  /// No description provided for @navDutchPay.
  ///
  /// In ko, this message translates to:
  /// **'더치페이'**
  String get navDutchPay;

  /// No description provided for @navPostit.
  ///
  /// In ko, this message translates to:
  /// **'포스트잇'**
  String get navPostit;

  /// No description provided for @navGroup.
  ///
  /// In ko, this message translates to:
  /// **'그룹'**
  String get navGroup;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @navMore.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get navMore;

  /// No description provided for @navMenu.
  ///
  /// In ko, this message translates to:
  /// **'메뉴'**
  String get navMenu;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navStats.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get navStats;

  /// No description provided for @navSearch.
  ///
  /// In ko, this message translates to:
  /// **'검색'**
  String get navSearch;

  /// No description provided for @navNotifications.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get navNotifications;

  /// No description provided for @navBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산'**
  String get navBudget;

  /// No description provided for @navRecurring.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래'**
  String get navRecurring;

  /// No description provided for @navCategories.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get navCategories;

  /// No description provided for @navPresets.
  ///
  /// In ko, this message translates to:
  /// **'프리셋'**
  String get navPresets;

  /// No description provided for @navCards.
  ///
  /// In ko, this message translates to:
  /// **'카드 관리'**
  String get navCards;

  /// No description provided for @navSavingGoals.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표'**
  String get navSavingGoals;

  /// No description provided for @navExport.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get navExport;

  /// No description provided for @navLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get navLogout;

  /// No description provided for @navChangePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get navChangePassword;

  /// No description provided for @notiTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notiTitle;

  /// No description provided for @notiEmpty.
  ///
  /// In ko, this message translates to:
  /// **'알림이 없습니다'**
  String get notiEmpty;

  /// No description provided for @notiMarkAllRead.
  ///
  /// In ko, this message translates to:
  /// **'모두 읽음'**
  String get notiMarkAllRead;

  /// No description provided for @notiTypeEventReminder.
  ///
  /// In ko, this message translates to:
  /// **'일정 알림'**
  String get notiTypeEventReminder;

  /// No description provided for @notiTypeBudgetAlert.
  ///
  /// In ko, this message translates to:
  /// **'예산 알림'**
  String get notiTypeBudgetAlert;

  /// No description provided for @notiTypeTodoReminder.
  ///
  /// In ko, this message translates to:
  /// **'할 일 알림'**
  String get notiTypeTodoReminder;

  /// No description provided for @notiTypeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템 알림'**
  String get notiTypeSystem;

  /// No description provided for @notiConnectionLost.
  ///
  /// In ko, this message translates to:
  /// **'알림 연결이 끊어졌습니다'**
  String get notiConnectionLost;

  /// No description provided for @notiConnectionRestored.
  ///
  /// In ko, this message translates to:
  /// **'알림 연결이 복구되었습니다'**
  String get notiConnectionRestored;

  /// No description provided for @notiNew.
  ///
  /// In ko, this message translates to:
  /// **'새 알림'**
  String get notiNew;

  /// No description provided for @assetTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산 관리'**
  String get assetTitle;

  /// No description provided for @assetSummaryTotalBalance.
  ///
  /// In ko, this message translates to:
  /// **'총 자산'**
  String get assetSummaryTotalBalance;

  /// No description provided for @assetEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 자산이 없습니다'**
  String get assetEmpty;

  /// No description provided for @assetCreateFirst.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 자산을 등록해 보세요'**
  String get assetCreateFirst;

  /// No description provided for @assetAdd.
  ///
  /// In ko, this message translates to:
  /// **'자산 추가'**
  String get assetAdd;

  /// No description provided for @assetEdit.
  ///
  /// In ko, this message translates to:
  /// **'자산 수정'**
  String get assetEdit;

  /// No description provided for @assetTransferAdd.
  ///
  /// In ko, this message translates to:
  /// **'이체 추가'**
  String get assetTransferAdd;

  /// No description provided for @assetTransferEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이체 내역이 없습니다'**
  String get assetTransferEmpty;

  /// No description provided for @assetFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get assetFee;

  /// No description provided for @assetTypeBankAccount.
  ///
  /// In ko, this message translates to:
  /// **'입출금'**
  String get assetTypeBankAccount;

  /// No description provided for @assetTypeSavings.
  ///
  /// In ko, this message translates to:
  /// **'예적금'**
  String get assetTypeSavings;

  /// No description provided for @assetTypeCash.
  ///
  /// In ko, this message translates to:
  /// **'현금'**
  String get assetTypeCash;

  /// No description provided for @assetTypeCreditCard.
  ///
  /// In ko, this message translates to:
  /// **'신용카드'**
  String get assetTypeCreditCard;

  /// No description provided for @assetTypeCheckCard.
  ///
  /// In ko, this message translates to:
  /// **'체크카드'**
  String get assetTypeCheckCard;

  /// No description provided for @assetTypeInvestment.
  ///
  /// In ko, this message translates to:
  /// **'투자'**
  String get assetTypeInvestment;

  /// No description provided for @assetTypeLoan.
  ///
  /// In ko, this message translates to:
  /// **'대출'**
  String get assetTypeLoan;

  /// No description provided for @assetGroupAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌 · 예금'**
  String get assetGroupAccount;

  /// No description provided for @assetGroupCard.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get assetGroupCard;

  /// No description provided for @assetGroupInvestment.
  ///
  /// In ko, this message translates to:
  /// **'투자'**
  String get assetGroupInvestment;

  /// No description provided for @assetGroupDebt.
  ///
  /// In ko, this message translates to:
  /// **'대출'**
  String get assetGroupDebt;

  /// No description provided for @assetCatAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌'**
  String get assetCatAccount;

  /// No description provided for @assetSubtypeInstallment.
  ///
  /// In ko, this message translates to:
  /// **'적금'**
  String get assetSubtypeInstallment;

  /// No description provided for @assetSubtypeDeposit.
  ///
  /// In ko, this message translates to:
  /// **'예금'**
  String get assetSubtypeDeposit;

  /// No description provided for @assetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'자산을 불러오지 못했습니다'**
  String get assetLoadError;

  /// No description provided for @assetEmptyState.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록된 자산이 없어요'**
  String get assetEmptyState;

  /// No description provided for @assetEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 카드·계좌 관리에서 추가할 수 있어요'**
  String get assetEmptyHint;

  /// No description provided for @assetSummaryColAccounts.
  ///
  /// In ko, this message translates to:
  /// **'계좌·예금'**
  String get assetSummaryColAccounts;

  /// No description provided for @assetSummaryColCards.
  ///
  /// In ko, this message translates to:
  /// **'카드값'**
  String get assetSummaryColCards;

  /// No description provided for @assetTotalNetWorth.
  ///
  /// In ko, this message translates to:
  /// **'총 순자산'**
  String get assetTotalNetWorth;

  /// No description provided for @assetVsLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달 대비'**
  String get assetVsLastMonth;

  /// No description provided for @assetGroupEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 항목이 없어요'**
  String get assetGroupEmpty;

  /// No description provided for @assetPaymentDayInfo.
  ///
  /// In ko, this message translates to:
  /// **'{day}일 결제'**
  String assetPaymentDayInfo(int day);

  /// No description provided for @assetExcludedFromTotal.
  ///
  /// In ko, this message translates to:
  /// **'총액 제외'**
  String get assetExcludedFromTotal;

  /// No description provided for @assetManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드 관리'**
  String get assetManageTitle;

  /// No description provided for @assetTabAccountsSavings.
  ///
  /// In ko, this message translates to:
  /// **'계좌·예금 {count}'**
  String assetTabAccountsSavings(int count);

  /// No description provided for @assetTabCards.
  ///
  /// In ko, this message translates to:
  /// **'카드 {count}'**
  String assetTabCards(int count);

  /// No description provided for @assetTabInvest.
  ///
  /// In ko, this message translates to:
  /// **'투자 {count}'**
  String assetTabInvest(int count);

  /// No description provided for @assetTotalPrefix.
  ///
  /// In ko, this message translates to:
  /// **'총'**
  String get assetTotalPrefix;

  /// No description provided for @assetAddCategory.
  ///
  /// In ko, this message translates to:
  /// **'{name} 추가'**
  String assetAddCategory(String name);

  /// No description provided for @assetCategoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 {name}가 없어요'**
  String assetCategoryEmpty(String name);

  /// No description provided for @assetIncludeInTotal.
  ///
  /// In ko, this message translates to:
  /// **'전체 자산 합계에 포함'**
  String get assetIncludeInTotal;

  /// No description provided for @assetIncludeInTotalDesc.
  ///
  /// In ko, this message translates to:
  /// **'순자산·총자산 계산에 반영됩니다'**
  String get assetIncludeInTotalDesc;

  /// No description provided for @assetTrendLoadError.
  ///
  /// In ko, this message translates to:
  /// **'추이 데이터를 불러오지 못했어요'**
  String get assetTrendLoadError;

  /// No description provided for @assetTrendEmpty.
  ///
  /// In ko, this message translates to:
  /// **'추이 데이터가 없어요'**
  String get assetTrendEmpty;

  /// No description provided for @assetNetWorth.
  ///
  /// In ko, this message translates to:
  /// **'순자산'**
  String get assetNetWorth;

  /// No description provided for @assetAccountAdd.
  ///
  /// In ko, this message translates to:
  /// **'계좌 추가'**
  String get assetAccountAdd;

  /// No description provided for @assetAccountEdit.
  ///
  /// In ko, this message translates to:
  /// **'계좌 편집'**
  String get assetAccountEdit;

  /// No description provided for @assetAccountAdded.
  ///
  /// In ko, this message translates to:
  /// **'계좌가 추가되었습니다'**
  String get assetAccountAdded;

  /// No description provided for @assetAccountUpdated.
  ///
  /// In ko, this message translates to:
  /// **'계좌가 수정되었습니다'**
  String get assetAccountUpdated;

  /// No description provided for @assetAccountDeleted.
  ///
  /// In ko, this message translates to:
  /// **'계좌가 삭제되었습니다'**
  String get assetAccountDeleted;

  /// No description provided for @assetAccountDelete.
  ///
  /// In ko, this message translates to:
  /// **'계좌 삭제'**
  String get assetAccountDelete;

  /// No description provided for @assetAccountDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 계좌를 삭제하시겠습니까? 연결된 거래는 유지됩니다.'**
  String get assetAccountDeleteConfirm;

  /// No description provided for @assetActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get assetActionFailed;

  /// No description provided for @assetDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get assetDeleteFailed;

  /// No description provided for @assetInstitutionBrand.
  ///
  /// In ko, this message translates to:
  /// **'기관·브랜드'**
  String get assetInstitutionBrand;

  /// No description provided for @assetTotalEntries.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}개'**
  String assetTotalEntries(int count);

  /// No description provided for @assetBankSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'은행명 또는 증권사 검색'**
  String get assetBankSearchHint;

  /// No description provided for @assetNickname.
  ///
  /// In ko, this message translates to:
  /// **'별칭'**
  String get assetNickname;

  /// No description provided for @assetNicknamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 신한 주거래'**
  String get assetNicknamePlaceholder;

  /// No description provided for @assetAccountType.
  ///
  /// In ko, this message translates to:
  /// **'계좌 종류'**
  String get assetAccountType;

  /// No description provided for @assetAccountNumber.
  ///
  /// In ko, this message translates to:
  /// **'계좌번호'**
  String get assetAccountNumber;

  /// No description provided for @assetBalanceLabel.
  ///
  /// In ko, this message translates to:
  /// **'잔액 (원)'**
  String get assetBalanceLabel;

  /// No description provided for @assetCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get assetCurrency;

  /// No description provided for @assetExchangeRate.
  ///
  /// In ko, this message translates to:
  /// **'환율'**
  String get assetExchangeRate;

  /// No description provided for @assetExchangeRateHint.
  ///
  /// In ko, this message translates to:
  /// **'{code} 1당 원화'**
  String assetExchangeRateHint(String code);

  /// No description provided for @assetExchangeRateDesc.
  ///
  /// In ko, this message translates to:
  /// **'순자산은 잔액 × 환율로 환산합니다. 비워 두면 환산 없이 그대로 더해집니다.'**
  String get assetExchangeRateDesc;

  /// No description provided for @assetMemoOptional.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get assetMemoOptional;

  /// No description provided for @assetMemoPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'계좌번호 뒷자리, 결제일, 한도 등 메모하세요'**
  String get assetMemoPlaceholder;

  /// No description provided for @assetCreditLimitLabel.
  ///
  /// In ko, this message translates to:
  /// **'신용한도 (원, 선택)'**
  String get assetCreditLimitLabel;

  /// No description provided for @assetCreditLimitPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 5,000,000'**
  String get assetCreditLimitPlaceholder;

  /// No description provided for @assetCreditLimitHint.
  ///
  /// In ko, this message translates to:
  /// **'한도를 입력하면 사용률 게이지가 표시됩니다.'**
  String get assetCreditLimitHint;

  /// No description provided for @assetPaymentDayLabel.
  ///
  /// In ko, this message translates to:
  /// **'결제일 (선택)'**
  String get assetPaymentDayLabel;

  /// No description provided for @assetPaymentDaySelect.
  ///
  /// In ko, this message translates to:
  /// **'결제일 선택'**
  String get assetPaymentDaySelect;

  /// No description provided for @assetPaymentDay.
  ///
  /// In ko, this message translates to:
  /// **'결제일'**
  String get assetPaymentDay;

  /// No description provided for @assetLinkedAccount.
  ///
  /// In ko, this message translates to:
  /// **'연결 계좌'**
  String get assetLinkedAccount;

  /// No description provided for @assetLinkedAccountLabel.
  ///
  /// In ko, this message translates to:
  /// **'연결 계좌'**
  String get assetLinkedAccountLabel;

  /// No description provided for @assetLinkedAccountSelect.
  ///
  /// In ko, this message translates to:
  /// **'연결 계좌 선택'**
  String get assetLinkedAccountSelect;

  /// No description provided for @assetLinkedAccountHint.
  ///
  /// In ko, this message translates to:
  /// **'이 카드로 결제하면 이 계좌에서 바로 빠져나가요.'**
  String get assetLinkedAccountHint;

  /// No description provided for @assetPaymentAccountLabel.
  ///
  /// In ko, this message translates to:
  /// **'결제 출금계좌 (선택)'**
  String get assetPaymentAccountLabel;

  /// No description provided for @assetNoBankAccounts.
  ///
  /// In ko, this message translates to:
  /// **'등록된 입출금계좌가 없어요'**
  String get assetNoBankAccounts;

  /// No description provided for @assetPaymentAccountSelect.
  ///
  /// In ko, this message translates to:
  /// **'결제계좌 선택'**
  String get assetPaymentAccountSelect;

  /// No description provided for @assetPaymentAccount.
  ///
  /// In ko, this message translates to:
  /// **'결제 출금계좌'**
  String get assetPaymentAccount;

  /// No description provided for @assetPaymentAccountHint.
  ///
  /// In ko, this message translates to:
  /// **'결제일에 이 계좌에서 청구액이 출금됩니다.'**
  String get assetPaymentAccountHint;

  /// No description provided for @assetNewAccount.
  ///
  /// In ko, this message translates to:
  /// **'새 계좌'**
  String get assetNewAccount;

  /// No description provided for @assetPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get assetPreview;

  /// No description provided for @assetNoSearchResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요'**
  String get assetNoSearchResults;

  /// No description provided for @assetCardAdd.
  ///
  /// In ko, this message translates to:
  /// **'카드 추가'**
  String get assetCardAdd;

  /// No description provided for @assetCardAdded.
  ///
  /// In ko, this message translates to:
  /// **'카드가 추가되었습니다'**
  String get assetCardAdded;

  /// No description provided for @assetCardEdit.
  ///
  /// In ko, this message translates to:
  /// **'카드 편집'**
  String get assetCardEdit;

  /// No description provided for @assetCardUpdated.
  ///
  /// In ko, this message translates to:
  /// **'카드가 수정되었습니다'**
  String get assetCardUpdated;

  /// No description provided for @assetCardDelete.
  ///
  /// In ko, this message translates to:
  /// **'카드 삭제'**
  String get assetCardDelete;

  /// No description provided for @assetCardDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 카드를 삭제하시겠습니까? 연결된 거래는 유지됩니다.'**
  String get assetCardDeleteConfirm;

  /// No description provided for @assetCardDeleted.
  ///
  /// In ko, this message translates to:
  /// **'카드가 삭제되었습니다'**
  String get assetCardDeleted;

  /// No description provided for @assetCardType.
  ///
  /// In ko, this message translates to:
  /// **'카드 종류'**
  String get assetCardType;

  /// No description provided for @assetCardProduct.
  ///
  /// In ko, this message translates to:
  /// **'카드 상품'**
  String get assetCardProduct;

  /// No description provided for @assetIncludeDiscontinued.
  ///
  /// In ko, this message translates to:
  /// **'단종 포함'**
  String get assetIncludeDiscontinued;

  /// No description provided for @assetTotalItems.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}건'**
  String assetTotalItems(int count);

  /// No description provided for @assetTotalLoading.
  ///
  /// In ko, this message translates to:
  /// **'총 …'**
  String get assetTotalLoading;

  /// No description provided for @assetCardSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'카드명 또는 발급사 검색'**
  String get assetCardSearchHint;

  /// No description provided for @assetNicknameOptional.
  ///
  /// In ko, this message translates to:
  /// **'별칭 (선택)'**
  String get assetNicknameOptional;

  /// No description provided for @assetCardNicknamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 신한 Deep Dream'**
  String get assetCardNicknamePlaceholder;

  /// No description provided for @assetCurrentUsage.
  ///
  /// In ko, this message translates to:
  /// **'현재 사용액 (원)'**
  String get assetCurrentUsage;

  /// No description provided for @assetCurrentUsageHint.
  ///
  /// In ko, this message translates to:
  /// **'청구될 금액을 입력하세요. 총 부채에 반영됩니다.'**
  String get assetCurrentUsageHint;

  /// No description provided for @assetNewCard.
  ///
  /// In ko, this message translates to:
  /// **'새 카드'**
  String get assetNewCard;

  /// No description provided for @assetCatalogLoadError.
  ///
  /// In ko, this message translates to:
  /// **'카탈로그 로드 실패'**
  String get assetCatalogLoadError;

  /// No description provided for @assetAnnualFee.
  ///
  /// In ko, this message translates to:
  /// **'연회비'**
  String get assetAnnualFee;

  /// No description provided for @assetCardShortCredit.
  ///
  /// In ko, this message translates to:
  /// **'신용'**
  String get assetCardShortCredit;

  /// No description provided for @assetCardShortCheck.
  ///
  /// In ko, this message translates to:
  /// **'체크'**
  String get assetCardShortCheck;

  /// No description provided for @assetDiscontinued.
  ///
  /// In ko, this message translates to:
  /// **'단종'**
  String get assetDiscontinued;

  /// No description provided for @assetInvestAdd.
  ///
  /// In ko, this message translates to:
  /// **'투자 추가'**
  String get assetInvestAdd;

  /// No description provided for @assetInvestEdit.
  ///
  /// In ko, this message translates to:
  /// **'투자 편집'**
  String get assetInvestEdit;

  /// No description provided for @assetInvestAdded.
  ///
  /// In ko, this message translates to:
  /// **'투자가 추가되었습니다'**
  String get assetInvestAdded;

  /// No description provided for @assetInvestUpdated.
  ///
  /// In ko, this message translates to:
  /// **'투자가 수정되었습니다'**
  String get assetInvestUpdated;

  /// No description provided for @assetInvestDeleted.
  ///
  /// In ko, this message translates to:
  /// **'투자가 삭제되었습니다'**
  String get assetInvestDeleted;

  /// No description provided for @assetInvestDelete.
  ///
  /// In ko, this message translates to:
  /// **'투자 삭제'**
  String get assetInvestDelete;

  /// No description provided for @assetInvestDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 투자 자산을 삭제하시겠습니까? 연결된 거래는 유지됩니다.'**
  String get assetInvestDeleteConfirm;

  /// No description provided for @assetBrokerExchange.
  ///
  /// In ko, this message translates to:
  /// **'증권사·거래소'**
  String get assetBrokerExchange;

  /// No description provided for @assetInvestSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'증권사·가상자산거래소·상품거래소 검색'**
  String get assetInvestSearchHint;

  /// No description provided for @assetProductName.
  ///
  /// In ko, this message translates to:
  /// **'별칭'**
  String get assetProductName;

  /// No description provided for @assetProductPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 연금저축, 금 보유분'**
  String get assetProductPlaceholder;

  /// No description provided for @assetValuation.
  ///
  /// In ko, this message translates to:
  /// **'평가액 (원)'**
  String get assetValuation;

  /// No description provided for @assetNewInvestment.
  ///
  /// In ko, this message translates to:
  /// **'새 투자 상품'**
  String get assetNewInvestment;

  /// No description provided for @assetCryptoExchange.
  ///
  /// In ko, this message translates to:
  /// **'가상자산거래소'**
  String get assetCryptoExchange;

  /// No description provided for @assetCategoryCommercialBank.
  ///
  /// In ko, this message translates to:
  /// **'시중은행'**
  String get assetCategoryCommercialBank;

  /// No description provided for @assetCategoryInternetBank.
  ///
  /// In ko, this message translates to:
  /// **'인터넷은행'**
  String get assetCategoryInternetBank;

  /// No description provided for @assetCategoryLocalBank.
  ///
  /// In ko, this message translates to:
  /// **'지방은행'**
  String get assetCategoryLocalBank;

  /// No description provided for @assetCategorySpecialBank.
  ///
  /// In ko, this message translates to:
  /// **'특수은행'**
  String get assetCategorySpecialBank;

  /// No description provided for @assetCategorySavingsInstitution.
  ///
  /// In ko, this message translates to:
  /// **'저축기관'**
  String get assetCategorySavingsInstitution;

  /// No description provided for @assetCategoryForeignBank.
  ///
  /// In ko, this message translates to:
  /// **'외국계'**
  String get assetCategoryForeignBank;

  /// No description provided for @assetCategoryOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get assetCategoryOther;

  /// No description provided for @assetCategoryBrokerage.
  ///
  /// In ko, this message translates to:
  /// **'증권사'**
  String get assetCategoryBrokerage;

  /// No description provided for @assetCategoryCommodityExchange.
  ///
  /// In ko, this message translates to:
  /// **'상품거래소'**
  String get assetCategoryCommodityExchange;

  /// No description provided for @assetCategoryCryptoExchange.
  ///
  /// In ko, this message translates to:
  /// **'가상자산거래소'**
  String get assetCategoryCryptoExchange;

  /// No description provided for @assetCardDetail.
  ///
  /// In ko, this message translates to:
  /// **'카드 상세'**
  String get assetCardDetail;

  /// No description provided for @assetInvestDetail.
  ///
  /// In ko, this message translates to:
  /// **'투자 상세'**
  String get assetInvestDetail;

  /// No description provided for @assetAccountDetail.
  ///
  /// In ko, this message translates to:
  /// **'계좌 상세'**
  String get assetAccountDetail;

  /// No description provided for @assetShowAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 표시'**
  String get assetShowAmount;

  /// No description provided for @assetHideAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 가리기'**
  String get assetHideAmount;

  /// No description provided for @assetPeriod3m.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get assetPeriod3m;

  /// No description provided for @assetPeriod6m.
  ///
  /// In ko, this message translates to:
  /// **'6개월'**
  String get assetPeriod6m;

  /// No description provided for @assetPeriod1y.
  ///
  /// In ko, this message translates to:
  /// **'1년'**
  String get assetPeriod1y;

  /// No description provided for @assetWeeksCount.
  ///
  /// In ko, this message translates to:
  /// **'{weeks}주'**
  String assetWeeksCount(int weeks);

  /// No description provided for @assetTrendKindUsage.
  ///
  /// In ko, this message translates to:
  /// **'사용 추이'**
  String get assetTrendKindUsage;

  /// No description provided for @assetTrendKindValuation.
  ///
  /// In ko, this message translates to:
  /// **'평가액 추이'**
  String get assetTrendKindValuation;

  /// No description provided for @assetTrendKindBalance.
  ///
  /// In ko, this message translates to:
  /// **'잔액 추이'**
  String get assetTrendKindBalance;

  /// No description provided for @assetTrendRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 {weeks} {kind}'**
  String assetTrendRecent(String weeks, String kind);

  /// No description provided for @assetValueLabelCard.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 결제 예정'**
  String get assetValueLabelCard;

  /// No description provided for @assetValuationShort.
  ///
  /// In ko, this message translates to:
  /// **'평가액'**
  String get assetValuationShort;

  /// No description provided for @assetSeriesUsage.
  ///
  /// In ko, this message translates to:
  /// **'사용'**
  String get assetSeriesUsage;

  /// No description provided for @assetRecentTxCount.
  ///
  /// In ko, this message translates to:
  /// **'최근 거래 ({count})'**
  String assetRecentTxCount(int count);

  /// No description provided for @assetViewAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 보기'**
  String get assetViewAll;

  /// No description provided for @assetTossLinkStarted.
  ///
  /// In ko, this message translates to:
  /// **'토스 시세 연동을 시작했어요'**
  String get assetTossLinkStarted;

  /// No description provided for @assetLinkFailed.
  ///
  /// In ko, this message translates to:
  /// **'연결 실패'**
  String get assetLinkFailed;

  /// No description provided for @assetTossUnlinked.
  ///
  /// In ko, this message translates to:
  /// **'토스 연결을 해제했어요'**
  String get assetTossUnlinked;

  /// No description provided for @assetUnlinkFailed.
  ///
  /// In ko, this message translates to:
  /// **'해제 실패'**
  String get assetUnlinkFailed;

  /// No description provided for @assetQtyUpdated.
  ///
  /// In ko, this message translates to:
  /// **'보유 수량을 수정했어요'**
  String get assetQtyUpdated;

  /// No description provided for @assetUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'수정 실패'**
  String get assetUpdateFailed;

  /// No description provided for @assetTossLinked.
  ///
  /// In ko, this message translates to:
  /// **'토스 연동 중'**
  String get assetTossLinked;

  /// No description provided for @assetHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목'**
  String get assetHoldings;

  /// No description provided for @tradeTitle.
  ///
  /// In ko, this message translates to:
  /// **'매수·매도'**
  String get tradeTitle;

  /// No description provided for @tradeBuy.
  ///
  /// In ko, this message translates to:
  /// **'매수'**
  String get tradeBuy;

  /// No description provided for @tradeSell.
  ///
  /// In ko, this message translates to:
  /// **'매도'**
  String get tradeSell;

  /// No description provided for @tradeBought.
  ///
  /// In ko, this message translates to:
  /// **'매수를 기록했어요'**
  String get tradeBought;

  /// No description provided for @tradeSold.
  ///
  /// In ko, this message translates to:
  /// **'매도를 기록했어요'**
  String get tradeSold;

  /// No description provided for @tradeHolding.
  ///
  /// In ko, this message translates to:
  /// **'종목'**
  String get tradeHolding;

  /// No description provided for @tradeHoldingType.
  ///
  /// In ko, this message translates to:
  /// **'종목 유형'**
  String get tradeHoldingType;

  /// No description provided for @tradeNoHolding.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목이 없어요'**
  String get tradeNoHolding;

  /// No description provided for @tradeAddNewHolding.
  ///
  /// In ko, this message translates to:
  /// **'새 종목 사기'**
  String get tradeAddNewHolding;

  /// No description provided for @tradePickExisting.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목에서 고르기'**
  String get tradePickExisting;

  /// No description provided for @tradeNewHoldingPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'종목명을 적어주세요'**
  String get tradeNewHoldingPlaceholder;

  /// No description provided for @tradeQuantity.
  ///
  /// In ko, this message translates to:
  /// **'수량'**
  String get tradeQuantity;

  /// No description provided for @tradeAmount.
  ///
  /// In ko, this message translates to:
  /// **'거래대금 (원)'**
  String get tradeAmount;

  /// No description provided for @tradeAmountHelp.
  ///
  /// In ko, this message translates to:
  /// **'수수료를 뺀 금액이에요. 수수료는 아래에 따로 적어주세요.'**
  String get tradeAmountHelp;

  /// No description provided for @tradeFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료·세금 (원)'**
  String get tradeFee;

  /// No description provided for @tradeMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get tradeMemo;

  /// No description provided for @tradeMemoPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'선택 입력'**
  String get tradeMemoPlaceholder;

  /// No description provided for @tradeSettlement.
  ///
  /// In ko, this message translates to:
  /// **'결제 계좌'**
  String get tradeSettlement;

  /// No description provided for @tradeSettlementCash.
  ///
  /// In ko, this message translates to:
  /// **'증권계좌 예수금'**
  String get tradeSettlementCash;

  /// No description provided for @tradeSettlementCashHelp.
  ///
  /// In ko, this message translates to:
  /// **'증권계좌에 넣어둔 예수금에서 오가요.'**
  String get tradeSettlementCashHelp;

  /// No description provided for @tradeSettlementAccountHelp.
  ///
  /// In ko, this message translates to:
  /// **'이 계좌에서 바로 오가요. 증권계좌 예수금은 건드리지 않아요.'**
  String get tradeSettlementAccountHelp;

  /// No description provided for @tradeSettlementDelta.
  ///
  /// In ko, this message translates to:
  /// **'결제 계좌 변동'**
  String get tradeSettlementDelta;

  /// No description provided for @tradeCashAfter.
  ///
  /// In ko, this message translates to:
  /// **'거래 후 예수금'**
  String get tradeCashAfter;

  /// No description provided for @tradeRealizedPreview.
  ///
  /// In ko, this message translates to:
  /// **'실현손익'**
  String get tradeRealizedPreview;

  /// No description provided for @tradeInsufficientCash.
  ///
  /// In ko, this message translates to:
  /// **'예수금이 부족해요. 먼저 입금하거나 금액을 확인해주세요.'**
  String get tradeInsufficientCash;

  /// No description provided for @tradeInsufficientQty.
  ///
  /// In ko, this message translates to:
  /// **'보유 수량보다 많이 팔 수 없어요.'**
  String get tradeInsufficientQty;

  /// No description provided for @tradeHistory.
  ///
  /// In ko, this message translates to:
  /// **'거래 내역'**
  String get tradeHistory;

  /// No description provided for @tradeDeleted.
  ///
  /// In ko, this message translates to:
  /// **'거래를 취소했어요'**
  String get tradeDeleted;

  /// No description provided for @tradeDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 취소하시겠어요? 예수금과 보유 수량이 거래 전으로 돌아가요.'**
  String get tradeDeleteConfirm;

  /// No description provided for @holdingTypeStock.
  ///
  /// In ko, this message translates to:
  /// **'주식'**
  String get holdingTypeStock;

  /// No description provided for @holdingTypeGold.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get holdingTypeGold;

  /// No description provided for @holdingTypeCrypto.
  ///
  /// In ko, this message translates to:
  /// **'코인'**
  String get holdingTypeCrypto;

  /// No description provided for @holdingAvgPrice.
  ///
  /// In ko, this message translates to:
  /// **'평단가'**
  String get holdingAvgPrice;

  /// No description provided for @holdingTotalCost.
  ///
  /// In ko, this message translates to:
  /// **'매수원가'**
  String get holdingTotalCost;

  /// No description provided for @tradeHeldSummary.
  ///
  /// In ko, this message translates to:
  /// **'보유 {qty} · 평단가 {avg}'**
  String tradeHeldSummary(String qty, String avg);

  /// No description provided for @assetCashBalance.
  ///
  /// In ko, this message translates to:
  /// **'예수금'**
  String get assetCashBalance;

  /// No description provided for @assetCashBalanceHint.
  ///
  /// In ko, this message translates to:
  /// **'매수 대기 자금이에요. 보유 종목을 팔면 이 금액으로 남아요.'**
  String get assetCashBalanceHint;

  /// No description provided for @assetHoldingBalance.
  ///
  /// In ko, this message translates to:
  /// **'평가금액'**
  String get assetHoldingBalance;

  /// No description provided for @assetHoldingsSummary.
  ///
  /// In ko, this message translates to:
  /// **'{count}종목 · {amount}원'**
  String assetHoldingsSummary(int count, String amount);

  /// No description provided for @assetHoldingRep.
  ///
  /// In ko, this message translates to:
  /// **'{name} 외 {count}종목'**
  String assetHoldingRep(String name, int count);

  /// No description provided for @assetNoHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목 없음'**
  String get assetNoHoldings;

  /// No description provided for @assetHoldingLinkedBadge.
  ///
  /// In ko, this message translates to:
  /// **'연동'**
  String get assetHoldingLinkedBadge;

  /// No description provided for @assetHoldingLinkedSub.
  ///
  /// In ko, this message translates to:
  /// **'현재가 {price} × 수량'**
  String assetHoldingLinkedSub(String price);

  /// No description provided for @assetHoldingManualSub.
  ///
  /// In ko, this message translates to:
  /// **'평가액 직접 입력'**
  String get assetHoldingManualSub;

  /// No description provided for @assetHoldingLinkedDetail.
  ///
  /// In ko, this message translates to:
  /// **'{qty}주 · 현재가 {price} 연동'**
  String assetHoldingLinkedDetail(String qty, String price);

  /// No description provided for @assetHoldingManualDetail.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get assetHoldingManualDetail;

  /// No description provided for @assetHoldingsEmptyEdit.
  ///
  /// In ko, this message translates to:
  /// **'검색으로 보유 종목을 추가하세요. 연동 종목은 현재가 × 수량으로 평가액이 자동 계산돼요.'**
  String get assetHoldingsEmptyEdit;

  /// No description provided for @assetHoldingsEmptyManual.
  ///
  /// In ko, this message translates to:
  /// **'위 버튼으로 보유분을 추가하세요. 시세 연동이 없어 평가액은 직접 입력합니다.'**
  String get assetHoldingsEmptyManual;

  /// No description provided for @assetHoldingsEmptyDetail.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목이 없어요. 편집에서 종목을 추가해보세요.'**
  String get assetHoldingsEmptyDetail;

  /// No description provided for @assetHoldingSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'종목명·티커 검색 후 추가 (예: 삼성전자, NVDA)'**
  String get assetHoldingSearchHint;

  /// No description provided for @assetHoldingAddManual.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 직접 추가 — 평가액 입력'**
  String assetHoldingAddManual(String name);

  /// No description provided for @assetSharesUnit.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get assetSharesUnit;

  /// No description provided for @assetHoldingTypeStock.
  ///
  /// In ko, this message translates to:
  /// **'주식'**
  String get assetHoldingTypeStock;

  /// No description provided for @assetHoldingTypeGold.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get assetHoldingTypeGold;

  /// No description provided for @assetHoldingTypeCrypto.
  ///
  /// In ko, this message translates to:
  /// **'코인'**
  String get assetHoldingTypeCrypto;

  /// No description provided for @assetHoldingAddGold.
  ///
  /// In ko, this message translates to:
  /// **'금 추가'**
  String get assetHoldingAddGold;

  /// No description provided for @assetHoldingAddCrypto.
  ///
  /// In ko, this message translates to:
  /// **'코인 추가'**
  String get assetHoldingAddCrypto;

  /// No description provided for @assetHoldingUnitGram.
  ///
  /// In ko, this message translates to:
  /// **'g'**
  String get assetHoldingUnitGram;

  /// No description provided for @assetHoldingUnitCount.
  ///
  /// In ko, this message translates to:
  /// **'개'**
  String get assetHoldingUnitCount;

  /// No description provided for @assetHoldingNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름'**
  String get assetHoldingNamePlaceholder;

  /// No description provided for @assetHoldingQtyUnit.
  ///
  /// In ko, this message translates to:
  /// **'{qty}{unit}'**
  String assetHoldingQtyUnit(String qty, String unit);

  /// No description provided for @assetInvestHoldingsSub.
  ///
  /// In ko, this message translates to:
  /// **'투자 · 보유 {count}종목'**
  String assetInvestHoldingsSub(int count);

  /// No description provided for @assetTodayChange.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {amount}원'**
  String assetTodayChange(String amount);

  /// No description provided for @assetSharesCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}주'**
  String assetSharesCount(String n);

  /// No description provided for @assetTossValuationFormula.
  ///
  /// In ko, this message translates to:
  /// **'평가액 = 토스 현재가 × {qty}주 로 실시간 계산됩니다.'**
  String assetTossValuationFormula(int qty);

  /// No description provided for @assetHoldingQty.
  ///
  /// In ko, this message translates to:
  /// **'보유 수량'**
  String get assetHoldingQty;

  /// No description provided for @assetEditQty.
  ///
  /// In ko, this message translates to:
  /// **'수량 수정'**
  String get assetEditQty;

  /// No description provided for @assetUnlink.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제'**
  String get assetUnlink;

  /// No description provided for @assetTossRealtimeTitle.
  ///
  /// In ko, this message translates to:
  /// **'토스 시세로 실시간 평가'**
  String get assetTossRealtimeTitle;

  /// No description provided for @assetTossRealtimeDesc.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목과 수량을 등록하면 토스 현재가 × 수량으로 평가액이 실시간 반영됩니다.'**
  String get assetTossRealtimeDesc;

  /// No description provided for @assetTapToChange.
  ///
  /// In ko, this message translates to:
  /// **'변경하려면 탭'**
  String get assetTapToChange;

  /// No description provided for @assetStockSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'종목명·코드 검색 (예: 삼성전자, 005930)'**
  String get assetStockSearchHint;

  /// No description provided for @stockSecurityTypeIndex.
  ///
  /// In ko, this message translates to:
  /// **'지수'**
  String get stockSecurityTypeIndex;

  /// No description provided for @stockSecurityTypeWarrant.
  ///
  /// In ko, this message translates to:
  /// **'워런트'**
  String get stockSecurityTypeWarrant;

  /// No description provided for @stockMarketKospi.
  ///
  /// In ko, this message translates to:
  /// **'코스피'**
  String get stockMarketKospi;

  /// No description provided for @stockMarketKosdaq.
  ///
  /// In ko, this message translates to:
  /// **'코스닥'**
  String get stockMarketKosdaq;

  /// No description provided for @stockMarketKonex.
  ///
  /// In ko, this message translates to:
  /// **'코넥스'**
  String get stockMarketKonex;

  /// No description provided for @stockMarketKrxIdx.
  ///
  /// In ko, this message translates to:
  /// **'KRX 지수'**
  String get stockMarketKrxIdx;

  /// No description provided for @stockMarketNas.
  ///
  /// In ko, this message translates to:
  /// **'나스닥'**
  String get stockMarketNas;

  /// No description provided for @stockMarketNys.
  ///
  /// In ko, this message translates to:
  /// **'뉴욕'**
  String get stockMarketNys;

  /// No description provided for @stockMarketAms.
  ///
  /// In ko, this message translates to:
  /// **'아멕스'**
  String get stockMarketAms;

  /// No description provided for @stockMarketShs.
  ///
  /// In ko, this message translates to:
  /// **'상해'**
  String get stockMarketShs;

  /// No description provided for @stockMarketShi.
  ///
  /// In ko, this message translates to:
  /// **'상해지수'**
  String get stockMarketShi;

  /// No description provided for @stockMarketSzs.
  ///
  /// In ko, this message translates to:
  /// **'심천'**
  String get stockMarketSzs;

  /// No description provided for @stockMarketSzi.
  ///
  /// In ko, this message translates to:
  /// **'심천지수'**
  String get stockMarketSzi;

  /// No description provided for @stockMarketTse.
  ///
  /// In ko, this message translates to:
  /// **'도쿄'**
  String get stockMarketTse;

  /// No description provided for @stockMarketHks.
  ///
  /// In ko, this message translates to:
  /// **'홍콩'**
  String get stockMarketHks;

  /// No description provided for @stockMarketHnx.
  ///
  /// In ko, this message translates to:
  /// **'하노이'**
  String get stockMarketHnx;

  /// No description provided for @stockMarketHsx.
  ///
  /// In ko, this message translates to:
  /// **'호치민'**
  String get stockMarketHsx;

  /// No description provided for @assetLinkByCode.
  ///
  /// In ko, this message translates to:
  /// **'「{code}」 코드로 연결'**
  String assetLinkByCode(String code);

  /// No description provided for @assetLink.
  ///
  /// In ko, this message translates to:
  /// **'연결'**
  String get assetLink;

  /// No description provided for @assetChartNoData.
  ///
  /// In ko, this message translates to:
  /// **'표시할 데이터가 없어요'**
  String get assetChartNoData;

  /// No description provided for @assetNoLinkedTx.
  ///
  /// In ko, this message translates to:
  /// **'연결된 거래 내역이 없어요.'**
  String get assetNoLinkedTx;

  /// No description provided for @assetTxFallback.
  ///
  /// In ko, this message translates to:
  /// **'거래'**
  String get assetTxFallback;

  /// No description provided for @assetPayConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'결제 예정액 {amount}원을 지금 결제 처리할까요?'**
  String assetPayConfirmMessage(String amount);

  /// No description provided for @assetPayConfirmDateSuffix.
  ///
  /// In ko, this message translates to:
  /// **' 결제일은 {date} 입니다.'**
  String assetPayConfirmDateSuffix(String date);

  /// No description provided for @assetPayNow.
  ///
  /// In ko, this message translates to:
  /// **'지금 결제'**
  String get assetPayNow;

  /// No description provided for @assetPayAction.
  ///
  /// In ko, this message translates to:
  /// **'결제하기'**
  String get assetPayAction;

  /// No description provided for @assetPayAmount.
  ///
  /// In ko, this message translates to:
  /// **'결제 금액'**
  String get assetPayAmount;

  /// No description provided for @assetPayRemainder.
  ///
  /// In ko, this message translates to:
  /// **'남은 {amount}은 결제일에 빠져요'**
  String assetPayRemainder(String amount);

  /// No description provided for @assetPaymentRecorded.
  ///
  /// In ko, this message translates to:
  /// **'결제가 기록되었습니다'**
  String get assetPaymentRecorded;

  /// No description provided for @assetPayFailed.
  ///
  /// In ko, this message translates to:
  /// **'결제 실패'**
  String get assetPayFailed;

  /// No description provided for @assetBillingLoadError.
  ///
  /// In ko, this message translates to:
  /// **'청구 정보를 불러오지 못했어요'**
  String get assetBillingLoadError;

  /// No description provided for @assetUpcomingPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 예정'**
  String get assetUpcomingPayment;

  /// No description provided for @assetScheduledTag.
  ///
  /// In ko, this message translates to:
  /// **'예정'**
  String get assetScheduledTag;

  /// No description provided for @assetPaidDone.
  ///
  /// In ko, this message translates to:
  /// **'결제 완료'**
  String get assetPaidDone;

  /// No description provided for @assetUsagePeriod.
  ///
  /// In ko, this message translates to:
  /// **'카드 이용 기간 {period}'**
  String assetUsagePeriod(String period);

  /// No description provided for @assetLimitSettings.
  ///
  /// In ko, this message translates to:
  /// **'한도 · 결제 설정'**
  String get assetLimitSettings;

  /// No description provided for @assetLimitUsage.
  ///
  /// In ko, this message translates to:
  /// **'한도 사용'**
  String get assetLimitUsage;

  /// No description provided for @assetLimitPctUsed.
  ///
  /// In ko, this message translates to:
  /// **'{pct}% 사용'**
  String assetLimitPctUsed(int pct);

  /// No description provided for @assetLimitOf.
  ///
  /// In ko, this message translates to:
  /// **'{used} / 한도 {limit}'**
  String assetLimitOf(String used, String limit);

  /// No description provided for @assetLimitRemain.
  ///
  /// In ko, this message translates to:
  /// **'잔여 {amount}'**
  String assetLimitRemain(String amount);

  /// No description provided for @assetLimitEdit.
  ///
  /// In ko, this message translates to:
  /// **'한도 · 결제일 변경'**
  String get assetLimitEdit;

  /// No description provided for @assetPerfDone.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 실적 달성'**
  String get assetPerfDone;

  /// No description provided for @assetPerfRemain.
  ///
  /// In ko, this message translates to:
  /// **'실적까지 {amount}'**
  String assetPerfRemain(String amount);

  /// No description provided for @assetUsageHistory.
  ///
  /// In ko, this message translates to:
  /// **'이용 내역'**
  String get assetUsageHistory;

  /// No description provided for @assetSortRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근순'**
  String get assetSortRecent;

  /// No description provided for @assetSortAmount.
  ///
  /// In ko, this message translates to:
  /// **'고액순'**
  String get assetSortAmount;

  /// No description provided for @assetSortCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별'**
  String get assetSortCategory;

  /// No description provided for @assetPeriodPick.
  ///
  /// In ko, this message translates to:
  /// **'기간 선택'**
  String get assetPeriodPick;

  /// No description provided for @assetNoUsage.
  ///
  /// In ko, this message translates to:
  /// **'이용 내역이 없어요.'**
  String get assetNoUsage;

  /// No description provided for @assetBillingPeriod.
  ///
  /// In ko, this message translates to:
  /// **'{start}~{end} 사용분'**
  String assetBillingPeriod(String start, String end);

  /// No description provided for @assetMonthlyPaymentDay.
  ///
  /// In ko, this message translates to:
  /// **'매월 {day}일 결제'**
  String assetMonthlyPaymentDay(int day);

  /// No description provided for @assetBillingHistory.
  ///
  /// In ko, this message translates to:
  /// **'청구 이력'**
  String get assetBillingHistory;

  /// No description provided for @assetStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get assetStatusPending;

  /// No description provided for @assetStatusSkipped.
  ///
  /// In ko, this message translates to:
  /// **'건너뜀'**
  String get assetStatusSkipped;

  /// No description provided for @todoTitle.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get todoTitle;

  /// No description provided for @todoEmpty.
  ///
  /// In ko, this message translates to:
  /// **'할 일이 없습니다'**
  String get todoEmpty;

  /// No description provided for @todoCreateFirst.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 할 일을 만들어 보세요'**
  String get todoCreateFirst;

  /// No description provided for @todoQuickAddHint.
  ///
  /// In ko, this message translates to:
  /// **'+ 빠른 할 일 추가'**
  String get todoQuickAddHint;

  /// No description provided for @todoStatusAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get todoStatusAll;

  /// No description provided for @todoStatusCompleted.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get todoStatusCompleted;

  /// No description provided for @todoPriorityAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get todoPriorityAll;

  /// No description provided for @todoPriorityHigh.
  ///
  /// In ko, this message translates to:
  /// **'높음'**
  String get todoPriorityHigh;

  /// No description provided for @todoPriorityMedium.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get todoPriorityMedium;

  /// No description provided for @todoPriorityLow.
  ///
  /// In ko, this message translates to:
  /// **'낮음'**
  String get todoPriorityLow;

  /// No description provided for @todoSubtask.
  ///
  /// In ko, this message translates to:
  /// **'하위 작업'**
  String get todoSubtask;

  /// No description provided for @todoSubtaskAddHint.
  ///
  /// In ko, this message translates to:
  /// **'+ 하위 작업 추가'**
  String get todoSubtaskAddHint;

  /// No description provided for @todoTagMgmt.
  ///
  /// In ko, this message translates to:
  /// **'태그 관리'**
  String get todoTagMgmt;

  /// No description provided for @memoTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memoTitle;

  /// No description provided for @memoEmpty.
  ///
  /// In ko, this message translates to:
  /// **'메모가 없어요'**
  String get memoEmpty;

  /// No description provided for @memoSearchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'결과가 없어요'**
  String get memoSearchEmpty;

  /// No description provided for @memoSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'메모 검색'**
  String get memoSearchHint;

  /// No description provided for @memoFolderMgmt.
  ///
  /// In ko, this message translates to:
  /// **'폴더 관리'**
  String get memoFolderMgmt;

  /// No description provided for @memoFolderRoot.
  ///
  /// In ko, this message translates to:
  /// **'루트'**
  String get memoFolderRoot;

  /// No description provided for @memoFolderEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 폴더가 없습니다'**
  String get memoFolderEmpty;

  /// No description provided for @memoPin.
  ///
  /// In ko, this message translates to:
  /// **'고정'**
  String get memoPin;

  /// No description provided for @memoUnpin.
  ///
  /// In ko, this message translates to:
  /// **'고정 해제'**
  String get memoUnpin;

  /// No description provided for @calTitle.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get calTitle;

  /// No description provided for @calToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get calToday;

  /// No description provided for @calMonthView.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get calMonthView;

  /// No description provided for @calWeekView.
  ///
  /// In ko, this message translates to:
  /// **'주'**
  String get calWeekView;

  /// No description provided for @calDayView.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get calDayView;

  /// No description provided for @calYearView.
  ///
  /// In ko, this message translates to:
  /// **'연'**
  String get calYearView;

  /// No description provided for @calAgendaView.
  ///
  /// In ko, this message translates to:
  /// **'안건'**
  String get calAgendaView;

  /// No description provided for @calNoEvents.
  ///
  /// In ko, this message translates to:
  /// **'일정이 없습니다'**
  String get calNoEvents;

  /// No description provided for @calEventAdd.
  ///
  /// In ko, this message translates to:
  /// **'일정 추가'**
  String get calEventAdd;

  /// No description provided for @calEventEdit.
  ///
  /// In ko, this message translates to:
  /// **'일정 수정'**
  String get calEventEdit;

  /// No description provided for @calEventDelete.
  ///
  /// In ko, this message translates to:
  /// **'일정 삭제'**
  String get calEventDelete;

  /// No description provided for @calLabelMgmt.
  ///
  /// In ko, this message translates to:
  /// **'라벨 관리'**
  String get calLabelMgmt;

  /// No description provided for @calMyCalendars.
  ///
  /// In ko, this message translates to:
  /// **'내 캘린더'**
  String get calMyCalendars;

  /// No description provided for @calAllDay.
  ///
  /// In ko, this message translates to:
  /// **'종일'**
  String get calAllDay;

  /// No description provided for @calRepeat.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get calRepeat;

  /// No description provided for @calRepeatNone.
  ///
  /// In ko, this message translates to:
  /// **'안 함'**
  String get calRepeatNone;

  /// No description provided for @calRepeatDaily.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get calRepeatDaily;

  /// No description provided for @calRepeatWeekly.
  ///
  /// In ko, this message translates to:
  /// **'매주'**
  String get calRepeatWeekly;

  /// No description provided for @calRepeatMonthly.
  ///
  /// In ko, this message translates to:
  /// **'매월'**
  String get calRepeatMonthly;

  /// No description provided for @calRepeatYearly.
  ///
  /// In ko, this message translates to:
  /// **'매년'**
  String get calRepeatYearly;

  /// No description provided for @calLocation.
  ///
  /// In ko, this message translates to:
  /// **'장소'**
  String get calLocation;

  /// No description provided for @calMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get calMemo;

  /// No description provided for @calStartDate.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get calStartDate;

  /// No description provided for @calEndDate.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get calEndDate;

  /// No description provided for @calFieldTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get calFieldTitle;

  /// No description provided for @calFieldDescription.
  ///
  /// In ko, this message translates to:
  /// **'설명'**
  String get calFieldDescription;

  /// No description provided for @calFieldCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get calFieldCalendar;

  /// No description provided for @calFieldLabel.
  ///
  /// In ko, this message translates to:
  /// **'라벨'**
  String get calFieldLabel;

  /// No description provided for @calFieldColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get calFieldColor;

  /// No description provided for @calFieldName.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get calFieldName;

  /// No description provided for @calFieldReminder.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get calFieldReminder;

  /// No description provided for @calFieldStartDate.
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get calFieldStartDate;

  /// No description provided for @calFieldEndDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일'**
  String get calFieldEndDate;

  /// No description provided for @calTitlePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 가족 식사'**
  String get calTitlePlaceholder;

  /// No description provided for @calDescriptionPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'추가 설명 (선택)'**
  String get calDescriptionPlaceholder;

  /// No description provided for @calLocationPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'장소를 입력하세요'**
  String get calLocationPlaceholder;

  /// No description provided for @calSelectCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 선택'**
  String get calSelectCalendar;

  /// No description provided for @calNoLabel.
  ///
  /// In ko, this message translates to:
  /// **'라벨이 없습니다'**
  String get calNoLabel;

  /// No description provided for @calLabelNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 중요, 마감일, 회의'**
  String get calLabelNamePlaceholder;

  /// No description provided for @calCalendarNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 가족, 업무, 운동 일정'**
  String get calCalendarNamePlaceholder;

  /// No description provided for @calCalendarNameFieldPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 이름'**
  String get calCalendarNameFieldPlaceholder;

  /// No description provided for @calInviteCodePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: ABC123'**
  String get calInviteCodePlaceholder;

  /// No description provided for @calRecurrenceNone.
  ///
  /// In ko, this message translates to:
  /// **'반복 없음'**
  String get calRecurrenceNone;

  /// No description provided for @calReminderMinutesBefore.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String calReminderMinutesBefore(int n);

  /// No description provided for @calReminderHourBefore.
  ///
  /// In ko, this message translates to:
  /// **'1시간 전'**
  String get calReminderHourBefore;

  /// No description provided for @calReminderDayBefore.
  ///
  /// In ko, this message translates to:
  /// **'1일 전'**
  String get calReminderDayBefore;

  /// No description provided for @calEventDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 일정을 삭제할까요? 이 작업은 되돌릴 수 없습니다.'**
  String calEventDeleteConfirm(String title);

  /// No description provided for @calEventAdded.
  ///
  /// In ko, this message translates to:
  /// **'일정이 추가되었습니다'**
  String get calEventAdded;

  /// No description provided for @calEventUpdated.
  ///
  /// In ko, this message translates to:
  /// **'일정이 수정되었습니다'**
  String get calEventUpdated;

  /// No description provided for @calLabelsTitle.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 라벨'**
  String get calLabelsTitle;

  /// No description provided for @calAllLabelsCount.
  ///
  /// In ko, this message translates to:
  /// **'전체 라벨 · {count}'**
  String calAllLabelsCount(int count);

  /// No description provided for @calLabelsEmpty.
  ///
  /// In ko, this message translates to:
  /// **'라벨이 없어요'**
  String get calLabelsEmpty;

  /// No description provided for @calLabelsEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'위 \"새 라벨\" 버튼으로 만들어보세요'**
  String get calLabelsEmptyHint;

  /// No description provided for @calLabelsIntro.
  ///
  /// In ko, this message translates to:
  /// **'모든 캘린더에서 공용으로 쓰는 라벨이에요. 일정 등록 시 선택할 수 있어요.'**
  String get calLabelsIntro;

  /// No description provided for @calNewLabel.
  ///
  /// In ko, this message translates to:
  /// **'새 라벨'**
  String get calNewLabel;

  /// No description provided for @calEditLabel.
  ///
  /// In ko, this message translates to:
  /// **'라벨 편집'**
  String get calEditLabel;

  /// No description provided for @calPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get calPreview;

  /// No description provided for @calDeleteLabelTitle.
  ///
  /// In ko, this message translates to:
  /// **'라벨 삭제'**
  String get calDeleteLabelTitle;

  /// No description provided for @calDeleteLabelConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 라벨을 삭제하시겠어요? 이 라벨이 지정된 일정은 라벨 없음 상태가 됩니다.'**
  String calDeleteLabelConfirm(String name);

  /// No description provided for @calDatePicker.
  ///
  /// In ko, this message translates to:
  /// **'날짜 이동'**
  String get calDatePicker;

  /// No description provided for @calCalendarChipCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String calCalendarChipCount(int count);

  /// No description provided for @calNoCalendars.
  ///
  /// In ko, this message translates to:
  /// **'캘린더가 없습니다'**
  String get calNoCalendars;

  /// No description provided for @calOtherSources.
  ///
  /// In ko, this message translates to:
  /// **'기타 소스'**
  String get calOtherSources;

  /// No description provided for @calHolidays.
  ///
  /// In ko, this message translates to:
  /// **'공휴일'**
  String get calHolidays;

  /// No description provided for @calManageShareSettings.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 관리 · 공유 설정'**
  String get calManageShareSettings;

  /// No description provided for @calNoEventsThisDay.
  ///
  /// In ko, this message translates to:
  /// **'이날 이벤트가 없습니다'**
  String get calNoEventsThisDay;

  /// No description provided for @calEventTotalCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String calEventTotalCount(int count);

  /// No description provided for @calGoToToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘로'**
  String get calGoToToday;

  /// No description provided for @calManageShareTitle.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 관리·공유'**
  String get calManageShareTitle;

  /// No description provided for @calJoinByCode.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드로 참여'**
  String get calJoinByCode;

  /// No description provided for @calRoleOwner.
  ///
  /// In ko, this message translates to:
  /// **'소유자'**
  String get calRoleOwner;

  /// No description provided for @calRoleEditor.
  ///
  /// In ko, this message translates to:
  /// **'편집 가능'**
  String get calRoleEditor;

  /// No description provided for @calRoleViewer.
  ///
  /// In ko, this message translates to:
  /// **'읽기 전용'**
  String get calRoleViewer;

  /// No description provided for @calShareIntroTitle.
  ///
  /// In ko, this message translates to:
  /// **'가족·친구와 일정 공유'**
  String get calShareIntroTitle;

  /// No description provided for @calShareIntroBody.
  ///
  /// In ko, this message translates to:
  /// **'캘린더를 만들고 멤버를 초대해 함께 일정을 관리할 수 있어요.'**
  String get calShareIntroBody;

  /// No description provided for @calNewCalendar.
  ///
  /// In ko, this message translates to:
  /// **'새 캘린더'**
  String get calNewCalendar;

  /// No description provided for @calMyCalendarsCount.
  ///
  /// In ko, this message translates to:
  /// **'내 캘린더 · {count}'**
  String calMyCalendarsCount(int count);

  /// No description provided for @calNoOwnedCalendars.
  ///
  /// In ko, this message translates to:
  /// **'소유한 캘린더가 없어요'**
  String get calNoOwnedCalendars;

  /// No description provided for @calSharedCalendarsCount.
  ///
  /// In ko, this message translates to:
  /// **'공유받은 캘린더 · {count}'**
  String calSharedCalendarsCount(int count);

  /// No description provided for @calNoSharedCalendars.
  ///
  /// In ko, this message translates to:
  /// **'공유받은 캘린더가 없어요'**
  String get calNoSharedCalendars;

  /// No description provided for @calDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get calDefault;

  /// No description provided for @calOnlyMe.
  ///
  /// In ko, this message translates to:
  /// **'나만 사용'**
  String get calOnlyMe;

  /// No description provided for @calMemberCount.
  ///
  /// In ko, this message translates to:
  /// **'멤버 {count}명'**
  String calMemberCount(int count);

  /// No description provided for @calJoinCardBody.
  ///
  /// In ko, this message translates to:
  /// **'공유받은 초대 코드를 입력해 캘린더에 참여하세요.'**
  String get calJoinCardBody;

  /// No description provided for @calJoin.
  ///
  /// In ko, this message translates to:
  /// **'참여'**
  String get calJoin;

  /// No description provided for @calCreate.
  ///
  /// In ko, this message translates to:
  /// **'만들기'**
  String get calCreate;

  /// No description provided for @calJoinedCalendar.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 캘린더에 참여했어요'**
  String calJoinedCalendar(String name);

  /// No description provided for @calInviteCode.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드'**
  String get calInviteCode;

  /// No description provided for @calManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'{name} · 관리'**
  String calManageTitle(String name);

  /// No description provided for @calDeleteCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 삭제'**
  String get calDeleteCalendar;

  /// No description provided for @calCalendarUpdated.
  ///
  /// In ko, this message translates to:
  /// **'캘린더를 수정했어요'**
  String get calCalendarUpdated;

  /// No description provided for @calInviteCodeRegenerated.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 새로 만들었어요'**
  String get calInviteCodeRegenerated;

  /// No description provided for @calInviteCodeCopied.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 복사했어요'**
  String get calInviteCodeCopied;

  /// No description provided for @calRemoveMember.
  ///
  /// In ko, this message translates to:
  /// **'멤버 내보내기'**
  String get calRemoveMember;

  /// No description provided for @calRemoveMemberConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name} 님을 캘린더에서 내보내시겠어요?'**
  String calRemoveMemberConfirm(String name);

  /// No description provided for @calRemove.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get calRemove;

  /// No description provided for @calDeleteCalendarConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 캘린더를 삭제하시겠어요? 일정은 기본 캘린더로 이동하고 모든 멤버의 접근 권한이 사라집니다.'**
  String calDeleteCalendarConfirm(String name);

  /// No description provided for @calCopy.
  ///
  /// In ko, this message translates to:
  /// **'복사'**
  String get calCopy;

  /// No description provided for @calRegenerate.
  ///
  /// In ko, this message translates to:
  /// **'재생성'**
  String get calRegenerate;

  /// No description provided for @calMembers.
  ///
  /// In ko, this message translates to:
  /// **'멤버'**
  String get calMembers;

  /// No description provided for @calMeSuffix.
  ///
  /// In ko, this message translates to:
  /// **'(나)'**
  String get calMeSuffix;

  /// No description provided for @calChangeToEditor.
  ///
  /// In ko, this message translates to:
  /// **'편집 가능으로'**
  String get calChangeToEditor;

  /// No description provided for @calChangeToViewer.
  ///
  /// In ko, this message translates to:
  /// **'읽기 전용으로'**
  String get calChangeToViewer;

  /// No description provided for @calAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get calAdd;

  /// No description provided for @calActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get calActionFailed;

  /// No description provided for @calSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패'**
  String get calSaveFailed;

  /// No description provided for @calDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get calDeleteFailed;

  /// No description provided for @calJoinFailed.
  ///
  /// In ko, this message translates to:
  /// **'참여 실패'**
  String get calJoinFailed;

  /// No description provided for @calUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'변경 실패'**
  String get calUpdateFailed;

  /// No description provided for @calCalendarLoadError.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 로드 실패'**
  String get calCalendarLoadError;

  /// No description provided for @calLabelLoadError.
  ///
  /// In ko, this message translates to:
  /// **'라벨 로드 실패'**
  String get calLabelLoadError;

  /// No description provided for @calMemberLoadError.
  ///
  /// In ko, this message translates to:
  /// **'멤버 로드 실패'**
  String get calMemberLoadError;

  /// No description provided for @dashTitle.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get dashTitle;

  /// No description provided for @dashGreeting.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 좋은 하루 되세요'**
  String get dashGreeting;

  /// No description provided for @dashTotalAssets.
  ///
  /// In ko, this message translates to:
  /// **'총 자산'**
  String get dashTotalAssets;

  /// No description provided for @dashChange.
  ///
  /// In ko, this message translates to:
  /// **'변화'**
  String get dashChange;

  /// No description provided for @dashThisMonthExpense.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 지출'**
  String get dashThisMonthExpense;

  /// No description provided for @dashThisMonthIncome.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 수입'**
  String get dashThisMonthIncome;

  /// No description provided for @dashRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 거래'**
  String get dashRecent;

  /// No description provided for @dashUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 일정'**
  String get dashUpcoming;

  /// No description provided for @dashRecentTodos.
  ///
  /// In ko, this message translates to:
  /// **'최근 할 일'**
  String get dashRecentTodos;

  /// No description provided for @dashOverdue.
  ///
  /// In ko, this message translates to:
  /// **'연체 {count}'**
  String dashOverdue(int count);

  /// No description provided for @dashTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 6개월'**
  String get dashTrendTitle;

  /// No description provided for @dashSeeMore.
  ///
  /// In ko, this message translates to:
  /// **'자세히'**
  String get dashSeeMore;

  /// No description provided for @dashEmptyTransactions.
  ///
  /// In ko, this message translates to:
  /// **'최근 거래가 없습니다'**
  String get dashEmptyTransactions;

  /// No description provided for @dashEmptyEvents.
  ///
  /// In ko, this message translates to:
  /// **'예정된 일정이 없습니다'**
  String get dashEmptyEvents;

  /// No description provided for @dashEmptyTodos.
  ///
  /// In ko, this message translates to:
  /// **'처리할 할 일이 없습니다'**
  String get dashEmptyTodos;

  /// No description provided for @dashAddTx.
  ///
  /// In ko, this message translates to:
  /// **'거래 추가'**
  String get dashAddTx;

  /// No description provided for @dashTodayLabel.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get dashTodayLabel;

  /// No description provided for @dashTomorrowLabel.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get dashTomorrowLabel;

  /// No description provided for @dashDaysLeft.
  ///
  /// In ko, this message translates to:
  /// **'D-{n}'**
  String dashDaysLeft(int n);

  /// No description provided for @dashHideAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 숨김'**
  String get dashHideAmount;

  /// No description provided for @dashVsLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달 대비'**
  String get dashVsLastMonth;

  /// No description provided for @dashLiabilities.
  ///
  /// In ko, this message translates to:
  /// **'부채'**
  String get dashLiabilities;

  /// No description provided for @dashMonthLedger.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 가계부'**
  String dashMonthLedger(int month);

  /// No description provided for @dashMonthTxError.
  ///
  /// In ko, this message translates to:
  /// **'이번달 거래를 불러오지 못했습니다'**
  String get dashMonthTxError;

  /// No description provided for @dashDailyAvgPrefix.
  ///
  /// In ko, this message translates to:
  /// **'하루 평균 '**
  String get dashDailyAvgPrefix;

  /// No description provided for @dashSpentMasked.
  ///
  /// In ko, this message translates to:
  /// **' 썼어요.'**
  String get dashSpentMasked;

  /// No description provided for @dashSpentUnit.
  ///
  /// In ko, this message translates to:
  /// **'원 썼어요.'**
  String get dashSpentUnit;

  /// No description provided for @dashVsPrevPrefix.
  ///
  /// In ko, this message translates to:
  /// **' 전월 대비 '**
  String get dashVsPrevPrefix;

  /// No description provided for @dashSaving.
  ///
  /// In ko, this message translates to:
  /// **' 절약 중이에요.'**
  String get dashSaving;

  /// No description provided for @dashSpentMore.
  ///
  /// In ko, this message translates to:
  /// **' 더 썼어요.'**
  String get dashSpentMore;

  /// No description provided for @dashSame.
  ///
  /// In ko, this message translates to:
  /// **' 동일해요.'**
  String get dashSame;

  /// No description provided for @dashNoCategoryData.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 데이터가 없어요'**
  String get dashNoCategoryData;

  /// No description provided for @dashNoBudget.
  ///
  /// In ko, this message translates to:
  /// **'등록된 예산이 없어요'**
  String get dashNoBudget;

  /// No description provided for @dashTodaySpend.
  ///
  /// In ko, this message translates to:
  /// **'오늘 쓴 돈'**
  String get dashTodaySpend;

  /// No description provided for @dashTxError.
  ///
  /// In ko, this message translates to:
  /// **'거래를 불러오지 못했습니다'**
  String get dashTxError;

  /// No description provided for @dashNoTodaySpend.
  ///
  /// In ko, this message translates to:
  /// **'오늘은 아직 쓴 돈이 없어요'**
  String get dashNoTodaySpend;

  /// No description provided for @expTitle.
  ///
  /// In ko, this message translates to:
  /// **'가계부'**
  String get expTitle;

  /// No description provided for @expFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get expFilterAll;

  /// No description provided for @expFilterIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get expFilterIncome;

  /// No description provided for @expFilterExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get expFilterExpense;

  /// No description provided for @expFilterTransfer.
  ///
  /// In ko, this message translates to:
  /// **'이체'**
  String get expFilterTransfer;

  /// No description provided for @expEmpty.
  ///
  /// In ko, this message translates to:
  /// **'거래가 없습니다'**
  String get expEmpty;

  /// No description provided for @expEmptyDescription.
  ///
  /// In ko, this message translates to:
  /// **'새 거래를 추가해서 가계부를 시작하세요'**
  String get expEmptyDescription;

  /// No description provided for @expAdd.
  ///
  /// In ko, this message translates to:
  /// **'거래 추가'**
  String get expAdd;

  /// No description provided for @expEdit.
  ///
  /// In ko, this message translates to:
  /// **'거래 수정'**
  String get expEdit;

  /// No description provided for @expDelete.
  ///
  /// In ko, this message translates to:
  /// **'거래 삭제'**
  String get expDelete;

  /// No description provided for @expAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get expAmount;

  /// No description provided for @expCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get expCategory;

  /// No description provided for @expAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get expAsset;

  /// No description provided for @expDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get expDate;

  /// No description provided for @expMerchant.
  ///
  /// In ko, this message translates to:
  /// **'가맹점'**
  String get expMerchant;

  /// No description provided for @expPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제 수단'**
  String get expPaymentMethod;

  /// No description provided for @expForeignPayment.
  ///
  /// In ko, this message translates to:
  /// **'해외 결제'**
  String get expForeignPayment;

  /// No description provided for @expCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get expCurrency;

  /// No description provided for @expOriginalAmount.
  ///
  /// In ko, this message translates to:
  /// **'현지 금액'**
  String get expOriginalAmount;

  /// No description provided for @expExchangeRate.
  ///
  /// In ko, this message translates to:
  /// **'환율'**
  String get expExchangeRate;

  /// No description provided for @expFxHint.
  ///
  /// In ko, this message translates to:
  /// **'{original} → {krw}'**
  String expFxHint(String original, String krw);

  /// No description provided for @expInstallment.
  ///
  /// In ko, this message translates to:
  /// **'할부'**
  String get expInstallment;

  /// No description provided for @expRefund.
  ///
  /// In ko, this message translates to:
  /// **'환불'**
  String get expRefund;

  /// No description provided for @expRefundRecord.
  ///
  /// In ko, this message translates to:
  /// **'환불 기록'**
  String get expRefundRecord;

  /// No description provided for @expLumpSum.
  ///
  /// In ko, this message translates to:
  /// **'일시불'**
  String get expLumpSum;

  /// No description provided for @expInstallmentMonths.
  ///
  /// In ko, this message translates to:
  /// **'{months}개월'**
  String expInstallmentMonths(int months);

  /// No description provided for @expInstallmentHint.
  ///
  /// In ko, this message translates to:
  /// **'매달 약 {perMonth}원씩 {months}회 청구돼요'**
  String expInstallmentHint(String perMonth, int months);

  /// No description provided for @expDescription.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get expDescription;

  /// No description provided for @expTypeIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get expTypeIncome;

  /// No description provided for @expTypeExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get expTypeExpense;

  /// No description provided for @transferFeePrefix.
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get transferFeePrefix;

  /// No description provided for @transferWithdrawn.
  ///
  /// In ko, this message translates to:
  /// **'출금 합계'**
  String get transferWithdrawn;

  /// No description provided for @transferDeleted.
  ///
  /// In ko, this message translates to:
  /// **'이체를 삭제했어요'**
  String get transferDeleted;

  /// No description provided for @transferDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 이체를 삭제할까요? 양쪽 자산의 잔액이 되돌아갑니다'**
  String get transferDeleteConfirm;

  /// No description provided for @expTypeTransfer.
  ///
  /// In ko, this message translates to:
  /// **'이체'**
  String get expTypeTransfer;

  /// No description provided for @expTransferFrom.
  ///
  /// In ko, this message translates to:
  /// **'보낼 자산'**
  String get expTransferFrom;

  /// No description provided for @expTransferTo.
  ///
  /// In ko, this message translates to:
  /// **'받을 자산'**
  String get expTransferTo;

  /// No description provided for @expFee.
  ///
  /// In ko, this message translates to:
  /// **'수수료'**
  String get expFee;

  /// No description provided for @expFilter.
  ///
  /// In ko, this message translates to:
  /// **'필터'**
  String get expFilter;

  /// No description provided for @expFilterMin.
  ///
  /// In ko, this message translates to:
  /// **'최소'**
  String get expFilterMin;

  /// No description provided for @expFilterMax.
  ///
  /// In ko, this message translates to:
  /// **'최대'**
  String get expFilterMax;

  /// No description provided for @expFilterPeriod.
  ///
  /// In ko, this message translates to:
  /// **'기간'**
  String get expFilterPeriod;

  /// No description provided for @expSplit.
  ///
  /// In ko, this message translates to:
  /// **'내역 분할'**
  String get expSplit;

  /// No description provided for @expConvertDutch.
  ///
  /// In ko, this message translates to:
  /// **'더치페이로'**
  String get expConvertDutch;

  /// No description provided for @expConvertRecurring.
  ///
  /// In ko, this message translates to:
  /// **'반복 설정'**
  String get expConvertRecurring;

  /// No description provided for @expExport.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get expExport;

  /// No description provided for @expExportCsv.
  ///
  /// In ko, this message translates to:
  /// **'CSV 내보내기'**
  String get expExportCsv;

  /// No description provided for @expSummaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'월간 요약'**
  String get expSummaryTitle;

  /// No description provided for @expSummaryIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get expSummaryIncome;

  /// No description provided for @expSummaryExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get expSummaryExpense;

  /// No description provided for @expSummaryBalance.
  ///
  /// In ko, this message translates to:
  /// **'잔액'**
  String get expSummaryBalance;

  /// No description provided for @budgetOverallCapNew.
  ///
  /// In ko, this message translates to:
  /// **'월 전체 상한 설정'**
  String get budgetOverallCapNew;

  /// No description provided for @budgetCategoryAdd.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 예산 추가'**
  String get budgetCategoryAdd;

  /// No description provided for @budgetOverallCapEdit.
  ///
  /// In ko, this message translates to:
  /// **'월 전체 상한 수정'**
  String get budgetOverallCapEdit;

  /// No description provided for @budgetCategoryEdit.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 예산 수정'**
  String get budgetCategoryEdit;

  /// No description provided for @budgetUpdated.
  ///
  /// In ko, this message translates to:
  /// **'예산이 수정되었습니다'**
  String get budgetUpdated;

  /// No description provided for @budgetAdded.
  ///
  /// In ko, this message translates to:
  /// **'예산이 추가되었습니다'**
  String get budgetAdded;

  /// No description provided for @budgetActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get budgetActionFailed;

  /// No description provided for @budgetDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'예산 삭제'**
  String get budgetDeleteTitle;

  /// No description provided for @budgetDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 예산을 삭제하시겠습니까?'**
  String get budgetDeleteConfirm;

  /// No description provided for @budgetDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get budgetDeleteFailed;

  /// No description provided for @budgetOverallCap.
  ///
  /// In ko, this message translates to:
  /// **'월 전체 상한'**
  String get budgetOverallCap;

  /// No description provided for @budgetCategoryLoadError.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 로드 실패'**
  String get budgetCategoryLoadError;

  /// No description provided for @budgetMonthlyLimit.
  ///
  /// In ko, this message translates to:
  /// **'월 예산 한도'**
  String get budgetMonthlyLimit;

  /// No description provided for @budgetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'예산을 불러오지 못했습니다'**
  String get budgetLoadError;

  /// No description provided for @budgetSelectMonth.
  ///
  /// In ko, this message translates to:
  /// **'월 선택'**
  String get budgetSelectMonth;

  /// No description provided for @budgetMonthOverallCap.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 전체 상한'**
  String budgetMonthOverallCap(int month);

  /// No description provided for @budgetOverallCapDesc.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 전체 지출의 상한이에요 (카테고리 예산이 없는 지출도 포함).'**
  String get budgetOverallCapDesc;

  /// No description provided for @budgetOverallCapEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'전체 상한이 아직 설정되지 않았어요. 우측 상단 설정 버튼으로 이번 달 최대 지출 한도를 지정할 수 있어요.'**
  String get budgetOverallCapEmptyHint;

  /// No description provided for @budgetCurrentCategorySum.
  ///
  /// In ko, this message translates to:
  /// **'현재 카테고리 한도 합계'**
  String get budgetCurrentCategorySum;

  /// No description provided for @budgetPercentUsed.
  ///
  /// In ko, this message translates to:
  /// **'{pct}% 사용'**
  String budgetPercentUsed(String pct);

  /// No description provided for @budgetRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 예산 {amount}'**
  String budgetRemaining(String amount);

  /// No description provided for @budgetOverBy.
  ///
  /// In ko, this message translates to:
  /// **'한도 {amount} 초과'**
  String budgetOverBy(String amount);

  /// No description provided for @budgetOverallCapLabel.
  ///
  /// In ko, this message translates to:
  /// **'전체 상한'**
  String get budgetOverallCapLabel;

  /// No description provided for @budgetCategoryAllocated.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 할당'**
  String get budgetCategoryAllocated;

  /// No description provided for @budgetAllocatable.
  ///
  /// In ko, this message translates to:
  /// **'할당 가능'**
  String get budgetAllocatable;

  /// No description provided for @budgetOverAllocatedWarning.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 한도 합이 전체 상한을 {amount} 초과했어요. 전체 상한을 올리거나 카테고리 한도를 줄여주세요.'**
  String budgetOverAllocatedWarning(String amount);

  /// No description provided for @budgetSpendingPace.
  ///
  /// In ko, this message translates to:
  /// **'지출 페이스'**
  String get budgetSpendingPace;

  /// No description provided for @budgetPaceOnTrack.
  ///
  /// In ko, this message translates to:
  /// **'정상 속도'**
  String get budgetPaceOnTrack;

  /// No description provided for @budgetPaceFast.
  ///
  /// In ko, this message translates to:
  /// **'빠른 속도'**
  String get budgetPaceFast;

  /// No description provided for @budgetMonthElapsed.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 {pct}% 경과 ↑'**
  String budgetMonthElapsed(String pct);

  /// No description provided for @budgetDailyAvg.
  ///
  /// In ko, this message translates to:
  /// **'일평균 지출'**
  String get budgetDailyAvg;

  /// No description provided for @budgetDailyRecommended.
  ///
  /// In ko, this message translates to:
  /// **'남은 일 권장 지출'**
  String get budgetDailyRecommended;

  /// No description provided for @budgetStatusTitle.
  ///
  /// In ko, this message translates to:
  /// **'예산 현황'**
  String get budgetStatusTitle;

  /// No description provided for @budgetOver.
  ///
  /// In ko, this message translates to:
  /// **'초과'**
  String get budgetOver;

  /// No description provided for @budgetHealthy.
  ///
  /// In ko, this message translates to:
  /// **'여유'**
  String get budgetHealthy;

  /// No description provided for @budgetByCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 예산'**
  String get budgetByCategory;

  /// No description provided for @budgetCountSet.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 설정됨'**
  String budgetCountSet(int count);

  /// No description provided for @budgetNoCategoryBudgets.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 예산이 없어요'**
  String get budgetNoCategoryBudgets;

  /// No description provided for @budgetGoToSettings.
  ///
  /// In ko, this message translates to:
  /// **'예산 설정하러 가기 →'**
  String get budgetGoToSettings;

  /// No description provided for @budgetCategoryFallback.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 #{id}'**
  String budgetCategoryFallback(int id);

  /// No description provided for @budgetComplianceTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 6개월 예산 이행률'**
  String get budgetComplianceTitle;

  /// No description provided for @budgetComplianceSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'한도 대비 지출 %'**
  String get budgetComplianceSubtitle;

  /// No description provided for @budgetNoComplianceData.
  ///
  /// In ko, this message translates to:
  /// **'아직 이행률 데이터가 없어요'**
  String get budgetNoComplianceData;

  /// No description provided for @budgetVsLimit.
  ///
  /// In ko, this message translates to:
  /// **'한도 대비'**
  String get budgetVsLimit;

  /// No description provided for @budgetLimit.
  ///
  /// In ko, this message translates to:
  /// **'한도'**
  String get budgetLimit;

  /// No description provided for @budgetEmptyMonth.
  ///
  /// In ko, this message translates to:
  /// **'이 달 예산이 없습니다'**
  String get budgetEmptyMonth;

  /// No description provided for @budgetEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'전체 상한 또는 카테고리 예산을 설정하세요'**
  String get budgetEmptyHint;

  /// No description provided for @budgetSetup.
  ///
  /// In ko, this message translates to:
  /// **'예산 설정'**
  String get budgetSetup;

  /// No description provided for @budgetCopyLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달 예산 복사'**
  String get budgetCopyLastMonth;

  /// No description provided for @budgetCopyConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'{from} 예산 한도({count}개)를 {to}로 복사해요. 이번 달에 이미 있는 예산은 덮어써집니다.'**
  String budgetCopyConfirmMessage(String from, int count, String to);

  /// No description provided for @budgetCopyFailed.
  ///
  /// In ko, this message translates to:
  /// **'복사 실패'**
  String get budgetCopyFailed;

  /// No description provided for @budgetCopiedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 예산을 복사했습니다'**
  String budgetCopiedCount(int count);

  /// No description provided for @budgetCopyLastMonthBtn.
  ///
  /// In ko, this message translates to:
  /// **'지난달 복사'**
  String get budgetCopyLastMonthBtn;

  /// No description provided for @budgetMonthTotal.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 총 예산'**
  String budgetMonthTotal(int month);

  /// No description provided for @budgetNotSet.
  ///
  /// In ko, this message translates to:
  /// **'설정되지 않음'**
  String get budgetNotSet;

  /// No description provided for @budgetUsed.
  ///
  /// In ko, this message translates to:
  /// **'사용'**
  String get budgetUsed;

  /// No description provided for @budgetAllocated.
  ///
  /// In ko, this message translates to:
  /// **'할당됨'**
  String get budgetAllocated;

  /// No description provided for @budgetByCategoryCount.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 예산 · {count}개'**
  String budgetByCategoryCount(int count);

  /// No description provided for @budgetAdd.
  ///
  /// In ko, this message translates to:
  /// **'예산 추가'**
  String get budgetAdd;

  /// No description provided for @budgetNoCategorySet.
  ///
  /// In ko, this message translates to:
  /// **'설정된 카테고리 예산이 없어요'**
  String get budgetNoCategorySet;

  /// No description provided for @cardBenefitTypeAll.
  ///
  /// In ko, this message translates to:
  /// **'혜택 전체'**
  String get cardBenefitTypeAll;

  /// No description provided for @cardBenefitTypeDiscount.
  ///
  /// In ko, this message translates to:
  /// **'할인'**
  String get cardBenefitTypeDiscount;

  /// No description provided for @cardBenefitTypePoint.
  ///
  /// In ko, this message translates to:
  /// **'적립'**
  String get cardBenefitTypePoint;

  /// No description provided for @cardBenefitTypeCashback.
  ///
  /// In ko, this message translates to:
  /// **'캐시백'**
  String get cardBenefitTypeCashback;

  /// No description provided for @cardBenefitTypeMileage.
  ///
  /// In ko, this message translates to:
  /// **'마일리지'**
  String get cardBenefitTypeMileage;

  /// No description provided for @cardManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 관리'**
  String get cardManageTitle;

  /// No description provided for @cardBenefitsTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 혜택'**
  String get cardBenefitsTitle;

  /// No description provided for @cardSelectTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 선택'**
  String get cardSelectTitle;

  /// No description provided for @cardBenefitMappingTitle.
  ///
  /// In ko, this message translates to:
  /// **'카드 혜택 매핑'**
  String get cardBenefitMappingTitle;

  /// No description provided for @cardBenefitMappingTooltip.
  ///
  /// In ko, this message translates to:
  /// **'혜택 매핑'**
  String get cardBenefitMappingTooltip;

  /// No description provided for @cardSearchHintName.
  ///
  /// In ko, this message translates to:
  /// **'카드명 검색'**
  String get cardSearchHintName;

  /// No description provided for @cardSearchHintFull.
  ///
  /// In ko, this message translates to:
  /// **'카드명, 브랜드, 혜택으로 검색'**
  String get cardSearchHintFull;

  /// No description provided for @cardSearchHintNameCompany.
  ///
  /// In ko, this message translates to:
  /// **'카드명 / 회사 검색'**
  String get cardSearchHintNameCompany;

  /// No description provided for @cardLoadError.
  ///
  /// In ko, this message translates to:
  /// **'카드 로드 실패'**
  String get cardLoadError;

  /// No description provided for @cardDetailLoadError.
  ///
  /// In ko, this message translates to:
  /// **'카드 상세 로드 실패'**
  String get cardDetailLoadError;

  /// No description provided for @cardSearchError.
  ///
  /// In ko, this message translates to:
  /// **'카드 검색 실패'**
  String get cardSearchError;

  /// No description provided for @cardAddFailed.
  ///
  /// In ko, this message translates to:
  /// **'추가 실패'**
  String get cardAddFailed;

  /// No description provided for @cardDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get cardDeleteFailed;

  /// No description provided for @cardMappingLoadError.
  ///
  /// In ko, this message translates to:
  /// **'매핑 로드 실패'**
  String get cardMappingLoadError;

  /// No description provided for @cardLastMonthPerf.
  ///
  /// In ko, this message translates to:
  /// **'전월 실적'**
  String get cardLastMonthPerf;

  /// No description provided for @cardKeyBenefitTags.
  ///
  /// In ko, this message translates to:
  /// **'주요 혜택 태그'**
  String get cardKeyBenefitTags;

  /// No description provided for @cardBenefitDetailCount.
  ///
  /// In ko, this message translates to:
  /// **'혜택 상세 · {count}건'**
  String cardBenefitDetailCount(int count);

  /// No description provided for @cardExpandAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 펼치기'**
  String get cardExpandAll;

  /// No description provided for @cardCollapseAll.
  ///
  /// In ko, this message translates to:
  /// **'모두 접기'**
  String get cardCollapseAll;

  /// No description provided for @cardCautions.
  ///
  /// In ko, this message translates to:
  /// **'유의사항'**
  String get cardCautions;

  /// No description provided for @cardCautionDetailsFallback.
  ///
  /// In ko, this message translates to:
  /// **'세부 사항'**
  String get cardCautionDetailsFallback;

  /// No description provided for @cardBenefits.
  ///
  /// In ko, this message translates to:
  /// **'혜택'**
  String get cardBenefits;

  /// No description provided for @cardNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get cardNone;

  /// No description provided for @cardFeeUnknown.
  ///
  /// In ko, this message translates to:
  /// **'정보 없음'**
  String get cardFeeUnknown;

  /// No description provided for @cardFeeFree.
  ///
  /// In ko, this message translates to:
  /// **'무료'**
  String get cardFeeFree;

  /// No description provided for @cardPerfNone.
  ///
  /// In ko, this message translates to:
  /// **'실적 무관'**
  String get cardPerfNone;

  /// No description provided for @cardFeeDomesticOnly.
  ///
  /// In ko, this message translates to:
  /// **'국내전용 {amount}'**
  String cardFeeDomesticOnly(String amount);

  /// No description provided for @cardPerfMin.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 이상'**
  String cardPerfMin(String amount);

  /// No description provided for @cardPerfMonthly.
  ///
  /// In ko, this message translates to:
  /// **'실적 {amount}/월'**
  String cardPerfMonthly(String amount);

  /// No description provided for @cardAnnualFeeValue.
  ///
  /// In ko, this message translates to:
  /// **'연회비 {fee}'**
  String cardAnnualFeeValue(String fee);

  /// No description provided for @cardPerfMonthTitle.
  ///
  /// In ko, this message translates to:
  /// **'{month} 실적'**
  String cardPerfMonthTitle(String month);

  /// No description provided for @cardPerfAchieved.
  ///
  /// In ko, this message translates to:
  /// **'달성'**
  String get cardPerfAchieved;

  /// No description provided for @cardPerfRemaining.
  ///
  /// In ko, this message translates to:
  /// **'남은 {amount}'**
  String cardPerfRemaining(String amount);

  /// No description provided for @cardMappingNew.
  ///
  /// In ko, this message translates to:
  /// **'새 매핑'**
  String get cardMappingNew;

  /// No description provided for @cardMappingNewDesc.
  ///
  /// In ko, this message translates to:
  /// **'카드 혜택 카테고리(예: 카페, 주유)를 가계부 카테고리와 연결하면 거래 입력 시 자동 추천에 활용됩니다.'**
  String get cardMappingNewDesc;

  /// No description provided for @cardMappingBenefitPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'혜택 카테고리'**
  String get cardMappingBenefitPlaceholder;

  /// No description provided for @cardMappingCategoryPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'가계부 카테고리'**
  String get cardMappingCategoryPlaceholder;

  /// No description provided for @cardMappingAdd.
  ///
  /// In ko, this message translates to:
  /// **'매핑 추가'**
  String get cardMappingAdd;

  /// No description provided for @cardMappingRegistered.
  ///
  /// In ko, this message translates to:
  /// **'등록된 매핑'**
  String get cardMappingRegistered;

  /// No description provided for @cardMappingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'등록된 매핑이 없습니다'**
  String get cardMappingEmpty;

  /// No description provided for @cardMappingDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get cardMappingDefault;

  /// No description provided for @cardIncludeDiscontinued.
  ///
  /// In ko, this message translates to:
  /// **'단종 카드 포함'**
  String get cardIncludeDiscontinued;

  /// No description provided for @cardTotalCount.
  ///
  /// In ko, this message translates to:
  /// **'총 {count}건'**
  String cardTotalCount(int count);

  /// No description provided for @cardEmpty.
  ///
  /// In ko, this message translates to:
  /// **'카드가 없습니다'**
  String get cardEmpty;

  /// No description provided for @cardNoResults.
  ///
  /// In ko, this message translates to:
  /// **'결과가 없어요'**
  String get cardNoResults;

  /// No description provided for @cardNoResultsHint.
  ///
  /// In ko, this message translates to:
  /// **'다른 검색어를 시도해보세요'**
  String get cardNoResultsHint;

  /// No description provided for @cardPickerNoMatch.
  ///
  /// In ko, this message translates to:
  /// **'일치하는 카드가 없습니다'**
  String get cardPickerNoMatch;

  /// No description provided for @categoryManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 관리'**
  String get categoryManageTitle;

  /// No description provided for @categorySearchHint.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 검색'**
  String get categorySearchHint;

  /// No description provided for @categoryLoadError.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 로드 실패'**
  String get categoryLoadError;

  /// No description provided for @categoryNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없어요'**
  String get categoryNoResults;

  /// No description provided for @categoryEmpty.
  ///
  /// In ko, this message translates to:
  /// **'카테고리가 없습니다'**
  String get categoryEmpty;

  /// No description provided for @categoryEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'상단 \'추가\' 버튼으로 추가하세요'**
  String get categoryEmptyHint;

  /// No description provided for @categoryHasSubcategories.
  ///
  /// In ko, this message translates to:
  /// **'{type} · 하위 카테고리 있음'**
  String categoryHasSubcategories(String type);

  /// No description provided for @categoryAdd.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 추가'**
  String get categoryAdd;

  /// No description provided for @categoryEdit.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 편집'**
  String get categoryEdit;

  /// No description provided for @categoryNameRequired.
  ///
  /// In ko, this message translates to:
  /// **'이름을 입력해 주세요.'**
  String get categoryNameRequired;

  /// No description provided for @categoryNameTooLong.
  ///
  /// In ko, this message translates to:
  /// **'이름은 12자 이내로 입력해 주세요.'**
  String get categoryNameTooLong;

  /// No description provided for @categoryNameDuplicate.
  ///
  /// In ko, this message translates to:
  /// **'같은 위치에 같은 이름의 카테고리가 있습니다.'**
  String get categoryNameDuplicate;

  /// No description provided for @categoryParent.
  ///
  /// In ko, this message translates to:
  /// **'상위 카테고리'**
  String get categoryParent;

  /// No description provided for @categoryBudgetExceedTitle.
  ///
  /// In ko, this message translates to:
  /// **'예산 초과 확인'**
  String get categoryBudgetExceedTitle;

  /// No description provided for @categoryBudgetExceedMessage.
  ///
  /// In ko, this message translates to:
  /// **'이동하면 \"{parent}\" 예산을 {amount} 초과합니다. 그래도 이동할까요?'**
  String categoryBudgetExceedMessage(String parent, String amount);

  /// No description provided for @categoryMove.
  ///
  /// In ko, this message translates to:
  /// **'이동'**
  String get categoryMove;

  /// No description provided for @categoryUpdated.
  ///
  /// In ko, this message translates to:
  /// **'카테고리가 수정되었습니다'**
  String get categoryUpdated;

  /// No description provided for @categoryAdded.
  ///
  /// In ko, this message translates to:
  /// **'카테고리가 추가되었습니다'**
  String get categoryAdded;

  /// No description provided for @categoryActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get categoryActionFailed;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 삭제'**
  String get categoryDeleteTitle;

  /// No description provided for @categoryDeleteHasChildren.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 카테고리에 하위 카테고리가 있어 삭제할 수 없어요. 먼저 하위 카테고리를 정리해 주세요.'**
  String categoryDeleteHasChildren(String name);

  /// No description provided for @categoryDeleteWithBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산이 설정되어 있는 카테고리입니다. 삭제 시 예산도 함께 삭제됩니다. \"{name}\" 카테고리를 삭제하시겠습니까?'**
  String categoryDeleteWithBudget(String name);

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 카테고리를 삭제하시겠어요?'**
  String categoryDeleteConfirm(String name);

  /// No description provided for @categoryDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get categoryDeleteFailed;

  /// No description provided for @categoryNew.
  ///
  /// In ko, this message translates to:
  /// **'새 카테고리'**
  String get categoryNew;

  /// No description provided for @categoryPreview.
  ///
  /// In ko, this message translates to:
  /// **'{type} 카테고리 · 미리보기'**
  String categoryPreview(String type);

  /// No description provided for @categoryTypeLabel.
  ///
  /// In ko, this message translates to:
  /// **'구분'**
  String get categoryTypeLabel;

  /// No description provided for @categoryOptionalSuffix.
  ///
  /// In ko, this message translates to:
  /// **' (선택)'**
  String get categoryOptionalSuffix;

  /// No description provided for @categoryParentMoveHint.
  ///
  /// In ko, this message translates to:
  /// **'다른 상위로 이동할 수 있어요. 최상위로 올리려면 연결된 거래를 옮긴 뒤 새로 만들어 주세요.'**
  String get categoryParentMoveHint;

  /// No description provided for @categoryMakeRoot.
  ///
  /// In ko, this message translates to:
  /// **'— 최상위 카테고리로 두기 —'**
  String get categoryMakeRoot;

  /// No description provided for @categoryNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 반려동물, 부수입'**
  String get categoryNamePlaceholder;

  /// No description provided for @categoryIconLabel.
  ///
  /// In ko, this message translates to:
  /// **'아이콘'**
  String get categoryIconLabel;

  /// No description provided for @authLoginPrompt.
  ///
  /// In ko, this message translates to:
  /// **'SSO 계정으로 로그인하세요'**
  String get authLoginPrompt;

  /// No description provided for @authSsoLogin.
  ///
  /// In ko, this message translates to:
  /// **'SSO 로그인'**
  String get authSsoLogin;

  /// No description provided for @authLoginTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authLoginTitle;

  /// No description provided for @authLoginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인 실패'**
  String get authLoginFailed;

  /// No description provided for @authLoginError.
  ///
  /// In ko, this message translates to:
  /// **'로그인 처리 중 오류'**
  String get authLoginError;

  /// No description provided for @authSecurityNotHttps.
  ///
  /// In ko, this message translates to:
  /// **'보안 오류: SSO 서버가 HTTPS 가 아닙니다 ({url}).'**
  String authSecurityNotHttps(String url);

  /// No description provided for @authStateMismatch.
  ///
  /// In ko, this message translates to:
  /// **'보안 검증에 실패했어요 (state 불일치). 다시 시도해 주세요.'**
  String get authStateMismatch;

  /// No description provided for @authNoAuthCode.
  ///
  /// In ko, this message translates to:
  /// **'인가코드를 받지 못했어요. 다시 시도해 주세요.'**
  String get authNoAuthCode;

  /// No description provided for @authPageLoadError.
  ///
  /// In ko, this message translates to:
  /// **'로그인 페이지를 불러오지 못했어요.'**
  String get authPageLoadError;

  /// No description provided for @dutchTitle.
  ///
  /// In ko, this message translates to:
  /// **'더치페이'**
  String get dutchTitle;

  /// No description provided for @dutchCreate.
  ///
  /// In ko, this message translates to:
  /// **'정산 만들기'**
  String get dutchCreate;

  /// No description provided for @dutchLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'더치페이 로드 실패'**
  String get dutchLoadFailed;

  /// No description provided for @dutchTabActive.
  ///
  /// In ko, this message translates to:
  /// **'진행 중'**
  String get dutchTabActive;

  /// No description provided for @dutchTabPast.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get dutchTabPast;

  /// No description provided for @dutchTabFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get dutchTabFriends;

  /// No description provided for @dutchEmptyActiveTitle.
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 정산이 없어요'**
  String get dutchEmptyActiveTitle;

  /// No description provided for @dutchEmptyActiveSub.
  ///
  /// In ko, this message translates to:
  /// **'+ 버튼으로 새 정산을 만들어보세요.'**
  String get dutchEmptyActiveSub;

  /// No description provided for @dutchEmptyPastTitle.
  ///
  /// In ko, this message translates to:
  /// **'완료된 정산이 없어요'**
  String get dutchEmptyPastTitle;

  /// No description provided for @dutchEmptyPastSub.
  ///
  /// In ko, this message translates to:
  /// **'정산을 마치면 여기에 모입니다.'**
  String get dutchEmptyPastSub;

  /// No description provided for @dutchEmptyFriendsTitle.
  ///
  /// In ko, this message translates to:
  /// **'함께 정산한 친구가 없어요'**
  String get dutchEmptyFriendsTitle;

  /// No description provided for @dutchEmptyFriendsSub.
  ///
  /// In ko, this message translates to:
  /// **'정산에 참여자를 추가하면 여기에 모입니다.'**
  String get dutchEmptyFriendsSub;

  /// No description provided for @dutchActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get dutchActionFailed;

  /// No description provided for @dutchSettleFailed.
  ///
  /// In ko, this message translates to:
  /// **'정산 실패'**
  String get dutchSettleFailed;

  /// No description provided for @dutchDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get dutchDeleteFailed;

  /// No description provided for @dutchToReceive.
  ///
  /// In ko, this message translates to:
  /// **'받을 돈'**
  String get dutchToReceive;

  /// No description provided for @dutchToSend.
  ///
  /// In ko, this message translates to:
  /// **'보낼 돈'**
  String get dutchToSend;

  /// No description provided for @dutchFromPeople.
  ///
  /// In ko, this message translates to:
  /// **'{count}명에게서'**
  String dutchFromPeople(int count);

  /// No description provided for @dutchToPeople.
  ///
  /// In ko, this message translates to:
  /// **'{count}명에게'**
  String dutchToPeople(int count);

  /// No description provided for @dutchPerPersonLabel.
  ///
  /// In ko, this message translates to:
  /// **'1인당'**
  String get dutchPerPersonLabel;

  /// No description provided for @dutchNPeople.
  ///
  /// In ko, this message translates to:
  /// **'{count}명'**
  String dutchNPeople(int count);

  /// No description provided for @dutchSettledTogetherCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}회 함께 정산'**
  String dutchSettledTogetherCount(int count);

  /// No description provided for @dutchSettled.
  ///
  /// In ko, this message translates to:
  /// **'정산 완료'**
  String get dutchSettled;

  /// No description provided for @dutchMe.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get dutchMe;

  /// No description provided for @dutchPayer.
  ///
  /// In ko, this message translates to:
  /// **'결제자'**
  String get dutchPayer;

  /// No description provided for @dutchNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'정산 이름'**
  String get dutchNameLabel;

  /// No description provided for @dutchNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 팀 저녁 회식'**
  String get dutchNamePlaceholder;

  /// No description provided for @dutchPlaceLabel.
  ///
  /// In ko, this message translates to:
  /// **'장소 (선택)'**
  String get dutchPlaceLabel;

  /// No description provided for @dutchPlacePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'장소 또는 상호명'**
  String get dutchPlacePlaceholder;

  /// No description provided for @dutchTotalLabel.
  ///
  /// In ko, this message translates to:
  /// **'총 금액'**
  String get dutchTotalLabel;

  /// No description provided for @dutchDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get dutchDateLabel;

  /// No description provided for @dutchSelectParticipants.
  ///
  /// In ko, this message translates to:
  /// **'참여자 선택'**
  String get dutchSelectParticipants;

  /// No description provided for @dutchNSelected.
  ///
  /// In ko, this message translates to:
  /// **'{count}명 선택'**
  String dutchNSelected(int count);

  /// No description provided for @dutchAddNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'이름 입력 후 추가'**
  String get dutchAddNamePlaceholder;

  /// No description provided for @dutchAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get dutchAdd;

  /// No description provided for @dutchNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get dutchNext;

  /// No description provided for @dutchPrev.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get dutchPrev;

  /// No description provided for @dutchDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'정산 상세'**
  String get dutchDetailTitle;

  /// No description provided for @dutchParticipant.
  ///
  /// In ko, this message translates to:
  /// **'참여자'**
  String get dutchParticipant;

  /// No description provided for @dutchSettleAction.
  ///
  /// In ko, this message translates to:
  /// **'정산 완료 처리'**
  String get dutchSettleAction;

  /// No description provided for @dutchDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'더치페이 삭제'**
  String get dutchDeleteTitle;

  /// No description provided for @dutchDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\"을(를) 삭제할까요?'**
  String dutchDeleteConfirm(String title);

  /// No description provided for @dutchRequestAll.
  ///
  /// In ko, this message translates to:
  /// **'일괄 요청'**
  String get dutchRequestAll;

  /// No description provided for @dutchRequestSent.
  ///
  /// In ko, this message translates to:
  /// **'{name}님에게 송금 요청을 보냈어요 (추후 카카오톡·문자 연동 예정)'**
  String dutchRequestSent(String name);

  /// No description provided for @dutchRequestSentBulk.
  ///
  /// In ko, this message translates to:
  /// **'{count}명에게 송금 요청을 보냈어요 (추후 카카오톡·문자 연동 예정)'**
  String dutchRequestSentBulk(int count);

  /// No description provided for @dutchAllSettled.
  ///
  /// In ko, this message translates to:
  /// **'모든 참여자가 이미 정산을 완료했어요'**
  String get dutchAllSettled;

  /// No description provided for @dutchNeedsPayment.
  ///
  /// In ko, this message translates to:
  /// **'{amount}원 송금 필요'**
  String dutchNeedsPayment(String amount);

  /// No description provided for @dutchNoName.
  ///
  /// In ko, this message translates to:
  /// **'(이름 없음)'**
  String get dutchNoName;

  /// No description provided for @dutchMarkPaid.
  ///
  /// In ko, this message translates to:
  /// **'송금 완료 처리'**
  String get dutchMarkPaid;

  /// No description provided for @dutchRequest.
  ///
  /// In ko, this message translates to:
  /// **'요청'**
  String get dutchRequest;

  /// No description provided for @dutchUnsettled.
  ///
  /// In ko, this message translates to:
  /// **'미정산'**
  String get dutchUnsettled;

  /// No description provided for @dutchStartTitle.
  ///
  /// In ko, this message translates to:
  /// **'더치페이 시작'**
  String get dutchStartTitle;

  /// No description provided for @dutchFromTxDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 기준으로 더치페이 정산을 만듭니다. 참여자에게 송금 요청을 보내고, 정산 진행 상황을 추적할 수 있어요.'**
  String get dutchFromTxDesc;

  /// No description provided for @dutchSplitMethod.
  ///
  /// In ko, this message translates to:
  /// **'분배 방식'**
  String get dutchSplitMethod;

  /// No description provided for @dutchSplitEqualTitle.
  ///
  /// In ko, this message translates to:
  /// **'N분의 1'**
  String get dutchSplitEqualTitle;

  /// No description provided for @dutchSplitEqualSub.
  ///
  /// In ko, this message translates to:
  /// **'균등 분배'**
  String get dutchSplitEqualSub;

  /// No description provided for @dutchSplitRatioTitle.
  ///
  /// In ko, this message translates to:
  /// **'비율'**
  String get dutchSplitRatioTitle;

  /// No description provided for @dutchSplitRatioSub.
  ///
  /// In ko, this message translates to:
  /// **'인원수·기준'**
  String get dutchSplitRatioSub;

  /// No description provided for @dutchSplitCustomTitle.
  ///
  /// In ko, this message translates to:
  /// **'개별 금액'**
  String get dutchSplitCustomTitle;

  /// No description provided for @dutchSplitCustomSub.
  ///
  /// In ko, this message translates to:
  /// **'각자 다르게'**
  String get dutchSplitCustomSub;

  /// No description provided for @dutchIncludeMyself.
  ///
  /// In ko, this message translates to:
  /// **'나도 포함해서 분배'**
  String get dutchIncludeMyself;

  /// No description provided for @dutchIncludeMyselfDesc.
  ///
  /// In ko, this message translates to:
  /// **'내 몫도 계산됩니다'**
  String get dutchIncludeMyselfDesc;

  /// No description provided for @dutchIncludeMyselfOffDesc.
  ///
  /// In ko, this message translates to:
  /// **'내가 전액 결제, 다른 사람 몫만 받아요'**
  String get dutchIncludeMyselfOffDesc;

  /// No description provided for @dutchSourceSub.
  ///
  /// In ko, this message translates to:
  /// **'참여자에게 송금 요청'**
  String get dutchSourceSub;

  /// No description provided for @dutchRequestMsgLabel.
  ///
  /// In ko, this message translates to:
  /// **'요청 메시지 (선택)'**
  String get dutchRequestMsgLabel;

  /// No description provided for @dutchRequestMsgPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'참여자에게 함께 보낼 한마디를 적어주세요'**
  String get dutchRequestMsgPlaceholder;

  /// No description provided for @dutchShortBy.
  ///
  /// In ko, this message translates to:
  /// **'합계가 총액보다 {amount}원 부족합니다.'**
  String dutchShortBy(String amount);

  /// No description provided for @dutchOverBy.
  ///
  /// In ko, this message translates to:
  /// **'합계가 총액보다 {amount}원 초과합니다.'**
  String dutchOverBy(String amount);

  /// No description provided for @dutchCreated.
  ///
  /// In ko, this message translates to:
  /// **'정산이 만들어졌어요'**
  String get dutchCreated;

  /// No description provided for @expLoadError.
  ///
  /// In ko, this message translates to:
  /// **'거래를 불러오지 못했습니다'**
  String get expLoadError;

  /// No description provided for @expEmptyMonth.
  ///
  /// In ko, this message translates to:
  /// **'이 달에는 거래가 없습니다'**
  String get expEmptyMonth;

  /// No description provided for @expEmptyDay.
  ///
  /// In ko, this message translates to:
  /// **'이 날의 거래가 없어요'**
  String get expEmptyDay;

  /// No description provided for @expTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계'**
  String get expTotal;

  /// No description provided for @expFiltering.
  ///
  /// In ko, this message translates to:
  /// **'필터 중'**
  String get expFiltering;

  /// No description provided for @expFilteringBy.
  ///
  /// In ko, this message translates to:
  /// **'{name} 필터 중'**
  String expFilteringBy(String name);

  /// No description provided for @expViewList.
  ///
  /// In ko, this message translates to:
  /// **'목록'**
  String get expViewList;

  /// No description provided for @expViewCalendar.
  ///
  /// In ko, this message translates to:
  /// **'달력'**
  String get expViewCalendar;

  /// No description provided for @expTxCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String expTxCount(int count);

  /// No description provided for @expAddShort.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get expAddShort;

  /// No description provided for @expTransferDone.
  ///
  /// In ko, this message translates to:
  /// **'이체가 완료되었습니다'**
  String get expTransferDone;

  /// No description provided for @expActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get expActionFailed;

  /// No description provided for @expUpdated.
  ///
  /// In ko, this message translates to:
  /// **'거래가 수정되었습니다'**
  String get expUpdated;

  /// No description provided for @expAdded.
  ///
  /// In ko, this message translates to:
  /// **'거래가 추가되었습니다'**
  String get expAdded;

  /// No description provided for @expDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 삭제하시겠습니까? 연결된 자산 잔액이 함께 조정됩니다.'**
  String get expDeleteConfirm;

  /// No description provided for @expDeleted.
  ///
  /// In ko, this message translates to:
  /// **'거래가 삭제되었습니다'**
  String get expDeleted;

  /// No description provided for @expDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get expDeleteFailed;

  /// No description provided for @expSplitMismatch.
  ///
  /// In ko, this message translates to:
  /// **'분할 내역과 금액이 달라요'**
  String get expSplitMismatch;

  /// No description provided for @expSplitDiff.
  ///
  /// In ko, this message translates to:
  /// **'새 총액 {total}원 · 분할 합계 {sum}원 · {diff}원 차이'**
  String expSplitDiff(String total, String sum, String diff);

  /// No description provided for @expSplitReconcile.
  ///
  /// In ko, this message translates to:
  /// **'분할 내역 맞추기'**
  String get expSplitReconcile;

  /// No description provided for @expPresetLoad.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 불러오기'**
  String get expPresetLoad;

  /// No description provided for @expPresetApplied.
  ///
  /// In ko, this message translates to:
  /// **'적용됨'**
  String get expPresetApplied;

  /// No description provided for @expPresetSaveCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 입력값 저장'**
  String get expPresetSaveCurrent;

  /// No description provided for @expPresetEmpty.
  ///
  /// In ko, this message translates to:
  /// **'저장된 프리셋이 없어요. 자주 쓰는 내역을 입력 후 “현재 입력값 저장”을 눌러보세요.'**
  String get expPresetEmpty;

  /// No description provided for @expPresetFilled.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 값이 채워졌어요. 금액·내역만 수정해서 저장하세요.'**
  String get expPresetFilled;

  /// No description provided for @expClear.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get expClear;

  /// No description provided for @expPresetManageHint.
  ///
  /// In ko, this message translates to:
  /// **'설정 → 프리셋 관리'**
  String get expPresetManageHint;

  /// No description provided for @expSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패'**
  String get expSaveFailed;

  /// No description provided for @expPresetSaveTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋으로 저장'**
  String get expPresetSaveTitle;

  /// No description provided for @expPresetNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 점심 도시락'**
  String get expPresetNamePlaceholder;

  /// No description provided for @expPresetLockAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 잠금 — 적용 시 {amount}원 자동 채움'**
  String expPresetLockAmount(String amount);

  /// No description provided for @expPayCash.
  ///
  /// In ko, this message translates to:
  /// **'현금'**
  String get expPayCash;

  /// No description provided for @expPayCard.
  ///
  /// In ko, this message translates to:
  /// **'카드'**
  String get expPayCard;

  /// No description provided for @expPayTransfer.
  ///
  /// In ko, this message translates to:
  /// **'계좌이체'**
  String get expPayTransfer;

  /// No description provided for @expPayOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get expPayOther;

  /// No description provided for @expPresetLock.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 잠금'**
  String get expPresetLock;

  /// No description provided for @expNoCategoryForType.
  ///
  /// In ko, this message translates to:
  /// **'이 타입에 해당하는 카테고리가 없습니다'**
  String get expNoCategoryForType;

  /// No description provided for @expSubcategory.
  ///
  /// In ko, this message translates to:
  /// **'세부 카테고리'**
  String get expSubcategory;

  /// No description provided for @expTopCategorySuffix.
  ///
  /// In ko, this message translates to:
  /// **'{name} (상위)'**
  String expTopCategorySuffix(String name);

  /// No description provided for @expIncomeSource.
  ///
  /// In ko, this message translates to:
  /// **'수입처'**
  String get expIncomeSource;

  /// No description provided for @expPayee.
  ///
  /// In ko, this message translates to:
  /// **'거래처'**
  String get expPayee;

  /// No description provided for @expIncomeSourcePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: (주)포레스트'**
  String get expIncomeSourcePlaceholder;

  /// No description provided for @expPayeePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 스타벅스 강남점'**
  String get expPayeePlaceholder;

  /// No description provided for @expIncomeMethod.
  ///
  /// In ko, this message translates to:
  /// **'수입 방식'**
  String get expIncomeMethod;

  /// No description provided for @expNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get expNone;

  /// No description provided for @expDepositAccount.
  ///
  /// In ko, this message translates to:
  /// **'입금 계좌'**
  String get expDepositAccount;

  /// No description provided for @expAccountCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드'**
  String get expAccountCard;

  /// No description provided for @expAssetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'자산 로드 실패'**
  String get expAssetLoadError;

  /// No description provided for @expWithdrawAccount.
  ///
  /// In ko, this message translates to:
  /// **'출금 계좌'**
  String get expWithdrawAccount;

  /// No description provided for @expSelect.
  ///
  /// In ko, this message translates to:
  /// **'선택'**
  String get expSelect;

  /// No description provided for @expTransferSameAsset.
  ///
  /// In ko, this message translates to:
  /// **'보낼/받을 자산은 달라야 합니다'**
  String get expTransferSameAsset;

  /// No description provided for @expFeeOptional.
  ///
  /// In ko, this message translates to:
  /// **'수수료 (선택)'**
  String get expFeeOptional;

  /// No description provided for @expInterest.
  ///
  /// In ko, this message translates to:
  /// **'이자'**
  String get expInterest;

  /// No description provided for @expInterestHint.
  ///
  /// In ko, this message translates to:
  /// **'상환액 중 이자 몫 — 부채는 이자를 뺀 만큼만 줄어들어요'**
  String get expInterestHint;

  /// No description provided for @expInterestSplit.
  ///
  /// In ko, this message translates to:
  /// **'원금 {principal}원 · 이자 {interest}원'**
  String expInterestSplit(String principal, String interest);

  /// No description provided for @expDateTime.
  ///
  /// In ko, this message translates to:
  /// **'날짜·시간'**
  String get expDateTime;

  /// No description provided for @expMemoPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 점심, 회식 등'**
  String get expMemoPlaceholder;

  /// No description provided for @expIncomeDetail.
  ///
  /// In ko, this message translates to:
  /// **'수입 상세'**
  String get expIncomeDetail;

  /// No description provided for @expExpenseDetail.
  ///
  /// In ko, this message translates to:
  /// **'지출 상세'**
  String get expExpenseDetail;

  /// No description provided for @expTxFallback.
  ///
  /// In ko, this message translates to:
  /// **'거래'**
  String get expTxFallback;

  /// No description provided for @expUncategorized.
  ///
  /// In ko, this message translates to:
  /// **'미분류'**
  String get expUncategorized;

  /// No description provided for @expValueNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get expValueNone;

  /// No description provided for @expItemsCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String expItemsCount(int count);

  /// No description provided for @expNotSelected.
  ///
  /// In ko, this message translates to:
  /// **'미선택'**
  String get expNotSelected;

  /// No description provided for @expPrevTxAt.
  ///
  /// In ko, this message translates to:
  /// **'{merchant}에서의 이전 거래'**
  String expPrevTxAt(String merchant);

  /// No description provided for @expThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get expThisMonth;

  /// No description provided for @expTimesCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String expTimesCount(int count);

  /// No description provided for @expItem.
  ///
  /// In ko, this message translates to:
  /// **'항목'**
  String get expItem;

  /// No description provided for @expFilterApply.
  ///
  /// In ko, this message translates to:
  /// **'필터 적용'**
  String get expFilterApply;

  /// No description provided for @expNSelected.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 선택'**
  String expNSelected(int count);

  /// No description provided for @expPeriodWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주'**
  String get expPeriodWeek;

  /// No description provided for @expPeriod3Month.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get expPeriod3Month;

  /// No description provided for @expPeriodCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 선택'**
  String get expPeriodCustom;

  /// No description provided for @expStartDate.
  ///
  /// In ko, this message translates to:
  /// **'시작일'**
  String get expStartDate;

  /// No description provided for @expEndDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일'**
  String get expEndDate;

  /// No description provided for @expDateRangeError.
  ///
  /// In ko, this message translates to:
  /// **'시작일이 종료일보다 늦을 수 없습니다.'**
  String get expDateRangeError;

  /// No description provided for @expTxType.
  ///
  /// In ko, this message translates to:
  /// **'거래 종류'**
  String get expTxType;

  /// No description provided for @expAmountRange.
  ///
  /// In ko, this message translates to:
  /// **'금액 범위'**
  String get expAmountRange;

  /// No description provided for @expMinAmount.
  ///
  /// In ko, this message translates to:
  /// **'최소 금액'**
  String get expMinAmount;

  /// No description provided for @expMaxAmount.
  ///
  /// In ko, this message translates to:
  /// **'최대 금액'**
  String get expMaxAmount;

  /// No description provided for @expSplitSave.
  ///
  /// In ko, this message translates to:
  /// **'분할 저장'**
  String get expSplitSave;

  /// No description provided for @expSplitRemove.
  ///
  /// In ko, this message translates to:
  /// **'분할 해제'**
  String get expSplitRemove;

  /// No description provided for @expSplitLoadError.
  ///
  /// In ko, this message translates to:
  /// **'분할 내역 로드 실패'**
  String get expSplitLoadError;

  /// No description provided for @expAddAmount.
  ///
  /// In ko, this message translates to:
  /// **'추가 금액'**
  String get expAddAmount;

  /// No description provided for @expSplitSaved.
  ///
  /// In ko, this message translates to:
  /// **'분할이 저장되었습니다'**
  String get expSplitSaved;

  /// No description provided for @expSplitRemoveConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 거래의 분할 내역을 모두 삭제하시겠습니까?'**
  String get expSplitRemoveConfirm;

  /// No description provided for @expClearFailed.
  ///
  /// In ko, this message translates to:
  /// **'해제 실패'**
  String get expClearFailed;

  /// No description provided for @expSplitMatches.
  ///
  /// In ko, this message translates to:
  /// **'분할 합계가 총액과 일치해요'**
  String get expSplitMatches;

  /// No description provided for @expSplitSum.
  ///
  /// In ko, this message translates to:
  /// **'분할 합계'**
  String get expSplitSum;

  /// No description provided for @expTotalAmount.
  ///
  /// In ko, this message translates to:
  /// **'총액'**
  String get expTotalAmount;

  /// No description provided for @expSplitTotalChanged.
  ///
  /// In ko, this message translates to:
  /// **'총액이 바뀌어 분할을 맞춰야 해요'**
  String get expSplitTotalChanged;

  /// No description provided for @expSplitMismatchTotal.
  ///
  /// In ko, this message translates to:
  /// **'분할 합계가 총액과 달라요'**
  String get expSplitMismatchTotal;

  /// No description provided for @expSplitCheckItems.
  ///
  /// In ko, this message translates to:
  /// **'분할 항목을 확인해주세요'**
  String get expSplitCheckItems;

  /// No description provided for @expShort.
  ///
  /// In ko, this message translates to:
  /// **'부족'**
  String get expShort;

  /// No description provided for @expOver.
  ///
  /// In ko, this message translates to:
  /// **'초과'**
  String get expOver;

  /// No description provided for @expQuickAdjust.
  ///
  /// In ko, this message translates to:
  /// **'빠르게 맞추기'**
  String get expQuickAdjust;

  /// No description provided for @expProrate.
  ///
  /// In ko, this message translates to:
  /// **'비례 배분'**
  String get expProrate;

  /// No description provided for @expProrateDesc.
  ///
  /// In ko, this message translates to:
  /// **'비중대로 자동 조정'**
  String get expProrateDesc;

  /// No description provided for @expApplyToLargest.
  ///
  /// In ko, this message translates to:
  /// **'큰 항목 반영'**
  String get expApplyToLargest;

  /// No description provided for @expApplyToLargestDesc.
  ///
  /// In ko, this message translates to:
  /// **'가장 큰 항목에 차액'**
  String get expApplyToLargestDesc;

  /// No description provided for @expAdjustItem.
  ///
  /// In ko, this message translates to:
  /// **'조정 항목'**
  String get expAdjustItem;

  /// No description provided for @expAdjustItemDesc.
  ///
  /// In ko, this message translates to:
  /// **'부족분을 새 항목으로'**
  String get expAdjustItemDesc;

  /// No description provided for @expRecommended.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get expRecommended;

  /// No description provided for @expSplitDesc.
  ///
  /// In ko, this message translates to:
  /// **'하나의 결제를 카테고리·항목별로 나누어 기록합니다. 예: 마트에서 식품과 생활품을 함께 결제한 경우.'**
  String get expSplitDesc;

  /// No description provided for @expOriginalTx.
  ///
  /// In ko, this message translates to:
  /// **'원 거래'**
  String get expOriginalTx;

  /// No description provided for @expAddItem.
  ///
  /// In ko, this message translates to:
  /// **'항목 추가'**
  String get expAddItem;

  /// No description provided for @expSplitEven.
  ///
  /// In ko, this message translates to:
  /// **'균등 분배'**
  String get expSplitEven;

  /// No description provided for @expSplitRatio.
  ///
  /// In ko, this message translates to:
  /// **'분할 비율'**
  String get expSplitRatio;

  /// No description provided for @expDeleteItem.
  ///
  /// In ko, this message translates to:
  /// **'항목 삭제'**
  String get expDeleteItem;

  /// No description provided for @expItemNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름 (선택)'**
  String get expItemNamePlaceholder;

  /// No description provided for @exportTitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터 내보내기'**
  String get exportTitle;

  /// No description provided for @exportShareText.
  ///
  /// In ko, this message translates to:
  /// **'데이터 내보내기 ({start} ~ {end})'**
  String exportShareText(String start, String end);

  /// No description provided for @exportSuccess.
  ///
  /// In ko, this message translates to:
  /// **'내보내기를 완료했어요'**
  String get exportSuccess;

  /// No description provided for @exportTypeExpense.
  ///
  /// In ko, this message translates to:
  /// **'거래 내역'**
  String get exportTypeExpense;

  /// No description provided for @exportTypeAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산·계좌'**
  String get exportTypeAsset;

  /// No description provided for @exportTypeBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산 설정'**
  String get exportTypeBudget;

  /// No description provided for @exportTypeCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get exportTypeCategory;

  /// No description provided for @exportTypeMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get exportTypeMemo;

  /// No description provided for @exportTypeCalendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 일정'**
  String get exportTypeCalendar;

  /// No description provided for @exportTypeTodo.
  ///
  /// In ko, this message translates to:
  /// **'할 일'**
  String get exportTypeTodo;

  /// No description provided for @exportFormatCsvDesc.
  ///
  /// In ko, this message translates to:
  /// **'엑셀·구글시트'**
  String get exportFormatCsvDesc;

  /// No description provided for @exportFormatExcelDesc.
  ///
  /// In ko, this message translates to:
  /// **'Microsoft Excel'**
  String get exportFormatExcelDesc;

  /// No description provided for @exportFormatJsonDesc.
  ///
  /// In ko, this message translates to:
  /// **'개발자·백업'**
  String get exportFormatJsonDesc;

  /// No description provided for @exportPeriodThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get exportPeriodThisMonth;

  /// No description provided for @exportPeriodLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난 달'**
  String get exportPeriodLastMonth;

  /// No description provided for @exportPeriodLast3Months.
  ///
  /// In ko, this message translates to:
  /// **'최근 3개월'**
  String get exportPeriodLast3Months;

  /// No description provided for @exportPeriodThisYear.
  ///
  /// In ko, this message translates to:
  /// **'올해'**
  String get exportPeriodThisYear;

  /// No description provided for @exportPeriodCustom.
  ///
  /// In ko, this message translates to:
  /// **'사용자 지정'**
  String get exportPeriodCustom;

  /// No description provided for @exportPeriodTitle.
  ///
  /// In ko, this message translates to:
  /// **'기간 선택'**
  String get exportPeriodTitle;

  /// No description provided for @exportDateRangeError.
  ///
  /// In ko, this message translates to:
  /// **'시작일이 종료일보다 늦을 수 없어요.'**
  String get exportDateRangeError;

  /// No description provided for @exportTypesTitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터 종류 — {count}개 선택됨'**
  String exportTypesTitle(int count);

  /// No description provided for @exportTypesDesc.
  ///
  /// In ko, this message translates to:
  /// **'내보낼 데이터를 골라주세요. 여러 종류는 ZIP으로 묶입니다.'**
  String get exportTypesDesc;

  /// No description provided for @exportCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String exportCount(int count);

  /// No description provided for @exportFormatTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 형식'**
  String get exportFormatTitle;

  /// No description provided for @exportMaskLabel.
  ///
  /// In ko, this message translates to:
  /// **'민감 정보 가리기 (잔액·금액·기관)'**
  String get exportMaskLabel;

  /// No description provided for @exportPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get exportPreview;

  /// No description provided for @exportRun.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get exportRun;

  /// No description provided for @exportEmpty.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에 내보낼 데이터가 없어요.'**
  String get exportEmpty;

  /// No description provided for @exportPreviewRows.
  ///
  /// In ko, this message translates to:
  /// **'상위 {count}행 미리보기'**
  String exportPreviewRows(int count);

  /// No description provided for @fileAttachTitle.
  ///
  /// In ko, this message translates to:
  /// **'첨부 파일'**
  String get fileAttachTitle;

  /// No description provided for @fileTooltipGallery.
  ///
  /// In ko, this message translates to:
  /// **'갤러리'**
  String get fileTooltipGallery;

  /// No description provided for @fileTooltipCamera.
  ///
  /// In ko, this message translates to:
  /// **'카메라'**
  String get fileTooltipCamera;

  /// No description provided for @fileTooltipFile.
  ///
  /// In ko, this message translates to:
  /// **'파일'**
  String get fileTooltipFile;

  /// No description provided for @fileUploadComplete.
  ///
  /// In ko, this message translates to:
  /// **'{name} 업로드 완료'**
  String fileUploadComplete(String name);

  /// No description provided for @fileUploadFailed.
  ///
  /// In ko, this message translates to:
  /// **'업로드 실패'**
  String get fileUploadFailed;

  /// No description provided for @fileDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 삭제'**
  String get fileDeleteTitle;

  /// No description provided for @fileDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name} 삭제할까요?'**
  String fileDeleteConfirm(String name);

  /// No description provided for @fileDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get fileDeleteFailed;

  /// No description provided for @fileLoadError.
  ///
  /// In ko, this message translates to:
  /// **'첨부 로드 실패'**
  String get fileLoadError;

  /// No description provided for @fileEmpty.
  ///
  /// In ko, this message translates to:
  /// **'첨부된 파일 없음'**
  String get fileEmpty;

  /// No description provided for @moreGroupMoney.
  ///
  /// In ko, this message translates to:
  /// **'돈 관리'**
  String get moreGroupMoney;

  /// No description provided for @moreGroupDaily.
  ///
  /// In ko, this message translates to:
  /// **'일상'**
  String get moreGroupDaily;

  /// No description provided for @moreGroupPersonal.
  ///
  /// In ko, this message translates to:
  /// **'개인화'**
  String get moreGroupPersonal;

  /// No description provided for @moreGroupSystem.
  ///
  /// In ko, this message translates to:
  /// **'계정·시스템'**
  String get moreGroupSystem;

  /// No description provided for @moreItemStocks.
  ///
  /// In ko, this message translates to:
  /// **'증권'**
  String get moreItemStocks;

  /// No description provided for @moreItemStats.
  ///
  /// In ko, this message translates to:
  /// **'통계·분석'**
  String get moreItemStats;

  /// No description provided for @moreItemAccountCard.
  ///
  /// In ko, this message translates to:
  /// **'카드·계좌 관리'**
  String get moreItemAccountCard;

  /// No description provided for @moreItemCardBenefits.
  ///
  /// In ko, this message translates to:
  /// **'카드 혜택'**
  String get moreItemCardBenefits;

  /// No description provided for @moreItemDisplay.
  ///
  /// In ko, this message translates to:
  /// **'표시 설정'**
  String get moreItemDisplay;

  /// No description provided for @moreItemAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get moreItemAccount;

  /// No description provided for @moreDescExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출 · 수입 · 이체'**
  String get moreDescExpense;

  /// No description provided for @moreDescAsset.
  ///
  /// In ko, this message translates to:
  /// **'계좌 · 카드 · 투자 · 부채'**
  String get moreDescAsset;

  /// No description provided for @moreDescStocks.
  ///
  /// In ko, this message translates to:
  /// **'시세 · 보유 · 관심 · 호가'**
  String get moreDescStocks;

  /// No description provided for @moreDescBudget.
  ///
  /// In ko, this message translates to:
  /// **'월간 · 카테고리별'**
  String get moreDescBudget;

  /// No description provided for @moreDescSavingGoal.
  ///
  /// In ko, this message translates to:
  /// **'목표 · 진행률'**
  String get moreDescSavingGoal;

  /// No description provided for @moreDescStats.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 · 트렌드 · 비교'**
  String get moreDescStats;

  /// No description provided for @moreDescRecurring.
  ///
  /// In ko, this message translates to:
  /// **'구독 · 고정비'**
  String get moreDescRecurring;

  /// No description provided for @moreDescAccountCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드 추가·편집'**
  String get moreDescAccountCard;

  /// No description provided for @moreDescCalendar.
  ///
  /// In ko, this message translates to:
  /// **'일정 · 반복 · 알림'**
  String get moreDescCalendar;

  /// No description provided for @moreDescTodo.
  ///
  /// In ko, this message translates to:
  /// **'마감 · 우선순위 · 태그'**
  String get moreDescTodo;

  /// No description provided for @moreDescMemo.
  ///
  /// In ko, this message translates to:
  /// **'분류 · 고정 · 검색'**
  String get moreDescMemo;

  /// No description provided for @moreDescDutchPay.
  ///
  /// In ko, this message translates to:
  /// **'정산 · 친구 · 송금 요청'**
  String get moreDescDutchPay;

  /// No description provided for @moreDescCardBenefits.
  ///
  /// In ko, this message translates to:
  /// **'신용·체크 카드 검색'**
  String get moreDescCardBenefits;

  /// No description provided for @moreDescCategories.
  ///
  /// In ko, this message translates to:
  /// **'지출 · 수입'**
  String get moreDescCategories;

  /// No description provided for @moreDescPresets.
  ///
  /// In ko, this message translates to:
  /// **'자주 쓰는 내역'**
  String get moreDescPresets;

  /// No description provided for @moreDescDisplay.
  ///
  /// In ko, this message translates to:
  /// **'테마 · 언어 · 통화'**
  String get moreDescDisplay;

  /// No description provided for @moreDescSettings.
  ///
  /// In ko, this message translates to:
  /// **'전체 설정 메뉴'**
  String get moreDescSettings;

  /// No description provided for @moreDescNotifications.
  ///
  /// In ko, this message translates to:
  /// **'푸시 · 방해 금지'**
  String get moreDescNotifications;

  /// No description provided for @moreDescExport.
  ///
  /// In ko, this message translates to:
  /// **'CSV · Excel · JSON'**
  String get moreDescExport;

  /// No description provided for @moreDescAccount.
  ///
  /// In ko, this message translates to:
  /// **'프로필 · 보안 · 구독'**
  String get moreDescAccount;

  /// No description provided for @moreSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'메뉴 검색'**
  String get moreSearchHint;

  /// No description provided for @moreSearchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get moreSearchEmpty;

  /// No description provided for @settingsGroupDataMgmt.
  ///
  /// In ko, this message translates to:
  /// **'데이터 관리'**
  String get settingsGroupDataMgmt;

  /// No description provided for @settingsMenuCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 관리'**
  String get settingsMenuCategory;

  /// No description provided for @settingsMenuAccountCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드 관리'**
  String get settingsMenuAccountCard;

  /// No description provided for @settingsMenuBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산 설정'**
  String get settingsMenuBudget;

  /// No description provided for @settingsMenuRecurring.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 관리'**
  String get settingsMenuRecurring;

  /// No description provided for @settingsMenuPreset.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 관리'**
  String get settingsMenuPreset;

  /// No description provided for @settingsGroupTagsLabels.
  ///
  /// In ko, this message translates to:
  /// **'태그 · 라벨'**
  String get settingsGroupTagsLabels;

  /// No description provided for @settingsGroupShare.
  ///
  /// In ko, this message translates to:
  /// **'공유·소통'**
  String get settingsGroupShare;

  /// No description provided for @settingsMenuCalendarShare.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 관리·공유'**
  String get settingsMenuCalendarShare;

  /// No description provided for @settingsMenuCalendarLabel.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 라벨'**
  String get settingsMenuCalendarLabel;

  /// No description provided for @settingsGroupApp.
  ///
  /// In ko, this message translates to:
  /// **'앱 환경'**
  String get settingsGroupApp;

  /// No description provided for @settingsMenuAppearance.
  ///
  /// In ko, this message translates to:
  /// **'표시 설정'**
  String get settingsMenuAppearance;

  /// No description provided for @settingsGroupData.
  ///
  /// In ko, this message translates to:
  /// **'데이터'**
  String get settingsGroupData;

  /// No description provided for @settingsMenuStorage.
  ///
  /// In ko, this message translates to:
  /// **'저장공간'**
  String get settingsMenuStorage;

  /// No description provided for @settingsGroupAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get settingsGroupAccount;

  /// No description provided for @settingsMenuAccountMgmt.
  ///
  /// In ko, this message translates to:
  /// **'계정 관리'**
  String get settingsMenuAccountMgmt;

  /// No description provided for @appearanceTitle.
  ///
  /// In ko, this message translates to:
  /// **'표시 설정'**
  String get appearanceTitle;

  /// No description provided for @appearanceTheme.
  ///
  /// In ko, this message translates to:
  /// **'테마'**
  String get appearanceTheme;

  /// No description provided for @appearanceThemeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get appearanceThemeLight;

  /// No description provided for @appearanceThemeLightDesc.
  ///
  /// In ko, this message translates to:
  /// **'밝은 배경'**
  String get appearanceThemeLightDesc;

  /// No description provided for @appearanceThemeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get appearanceThemeDark;

  /// No description provided for @appearanceThemeDarkDesc.
  ///
  /// In ko, this message translates to:
  /// **'어두운 배경'**
  String get appearanceThemeDarkDesc;

  /// No description provided for @appearanceThemeSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get appearanceThemeSystem;

  /// No description provided for @appearanceThemeSystemDesc.
  ///
  /// In ko, this message translates to:
  /// **'자동 전환'**
  String get appearanceThemeSystemDesc;

  /// No description provided for @appearancePrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 보호'**
  String get appearancePrivacy;

  /// No description provided for @appearanceHideAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액 가리기'**
  String get appearanceHideAmount;

  /// No description provided for @appearanceHideAmountDesc.
  ///
  /// In ko, this message translates to:
  /// **'모든 화면의 금액을 ••••로 표시합니다'**
  String get appearanceHideAmountDesc;

  /// No description provided for @appearanceRegion.
  ///
  /// In ko, this message translates to:
  /// **'표시 기준 지역'**
  String get appearanceRegion;

  /// No description provided for @appearanceRegionPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'지역 선택'**
  String get appearanceRegionPlaceholder;

  /// No description provided for @appearanceRegionDesc.
  ///
  /// In ko, this message translates to:
  /// **'선택한 지역 기준으로 날짜와 시간이 표시돼요'**
  String get appearanceRegionDesc;

  /// No description provided for @appearanceCurrency.
  ///
  /// In ko, this message translates to:
  /// **'기본 통화'**
  String get appearanceCurrency;

  /// No description provided for @appearanceCurrencyKrw.
  ///
  /// In ko, this message translates to:
  /// **'대한민국 원'**
  String get appearanceCurrencyKrw;

  /// No description provided for @appearanceCurrencyUsd.
  ///
  /// In ko, this message translates to:
  /// **'미국 달러'**
  String get appearanceCurrencyUsd;

  /// No description provided for @appearanceCurrencyEur.
  ///
  /// In ko, this message translates to:
  /// **'유로'**
  String get appearanceCurrencyEur;

  /// No description provided for @appearanceCurrencyJpy.
  ///
  /// In ko, this message translates to:
  /// **'일본 엔'**
  String get appearanceCurrencyJpy;

  /// No description provided for @passwordChanged.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 변경되었습니다'**
  String get passwordChanged;

  /// No description provided for @passwordChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경에 실패했습니다.'**
  String get passwordChangeFailed;

  /// No description provided for @passwordCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호'**
  String get passwordCurrent;

  /// No description provided for @passwordNew.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get passwordNew;

  /// No description provided for @passwordNewPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'8자 이상, 특수문자 포함'**
  String get passwordNewPlaceholder;

  /// No description provided for @passwordNewConfirm.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 확인'**
  String get passwordNewConfirm;

  /// No description provided for @passwordConfirmPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'한 번 더 입력'**
  String get passwordConfirmPlaceholder;

  /// No description provided for @passwordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호가 일치하지 않습니다'**
  String get passwordMismatch;

  /// No description provided for @passwordMatched.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호가 일치합니다'**
  String get passwordMatched;

  /// No description provided for @passwordRuleLength.
  ///
  /// In ko, this message translates to:
  /// **'8자 이상'**
  String get passwordRuleLength;

  /// No description provided for @passwordRuleSpecial.
  ///
  /// In ko, this message translates to:
  /// **'특수문자 1자 이상'**
  String get passwordRuleSpecial;

  /// No description provided for @passwordSameAsCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호와 다른 비밀번호를 입력해주세요'**
  String get passwordSameAsCurrent;

  /// No description provided for @passwordChangeAction.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get passwordChangeAction;

  /// No description provided for @accountTitle.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get accountTitle;

  /// No description provided for @accountDefaultName.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get accountDefaultName;

  /// No description provided for @accountJoined.
  ///
  /// In ko, this message translates to:
  /// **'가입 {date}'**
  String accountJoined(String date);

  /// No description provided for @accountEditComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'프로필 편집은 준비중입니다'**
  String get accountEditComingSoon;

  /// No description provided for @accountSecurity.
  ///
  /// In ko, this message translates to:
  /// **'보안'**
  String get accountSecurity;

  /// No description provided for @accountPasswordDesc.
  ///
  /// In ko, this message translates to:
  /// **'최근 변경 없음'**
  String get accountPasswordDesc;

  /// No description provided for @accountTwoFa.
  ///
  /// In ko, this message translates to:
  /// **'2단계 인증'**
  String get accountTwoFa;

  /// No description provided for @accountOn.
  ///
  /// In ko, this message translates to:
  /// **'사용 중'**
  String get accountOn;

  /// No description provided for @accountOff.
  ///
  /// In ko, this message translates to:
  /// **'사용 안 함'**
  String get accountOff;

  /// No description provided for @accountBiometric.
  ///
  /// In ko, this message translates to:
  /// **'생체 인증'**
  String get accountBiometric;

  /// No description provided for @accountComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비중'**
  String get accountComingSoon;

  /// No description provided for @accountDevices.
  ///
  /// In ko, this message translates to:
  /// **'로그인된 기기'**
  String get accountDevices;

  /// No description provided for @accountCurrentDevice.
  ///
  /// In ko, this message translates to:
  /// **'현재 기기'**
  String get accountCurrentDevice;

  /// No description provided for @accountLoginHistory.
  ///
  /// In ko, this message translates to:
  /// **'로그인 기록'**
  String get accountLoginHistory;

  /// No description provided for @accountLast30Days.
  ///
  /// In ko, this message translates to:
  /// **'최근 30일'**
  String get accountLast30Days;

  /// No description provided for @accountConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결된 계정'**
  String get accountConnected;

  /// No description provided for @accountNotConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결 안 됨'**
  String get accountNotConnected;

  /// No description provided for @accountConnect.
  ///
  /// In ko, this message translates to:
  /// **'연결'**
  String get accountConnect;

  /// No description provided for @accountSocialComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'{name} 연결은 준비중입니다'**
  String accountSocialComingSoon(String name);

  /// No description provided for @accountBilling.
  ///
  /// In ko, this message translates to:
  /// **'구독·결제'**
  String get accountBilling;

  /// No description provided for @accountNextBilling.
  ///
  /// In ko, this message translates to:
  /// **'다음 결제 {date} · '**
  String accountNextBilling(String date);

  /// No description provided for @accountProActive.
  ///
  /// In ko, this message translates to:
  /// **'Pro 이용 중'**
  String get accountProActive;

  /// No description provided for @accountProPromo.
  ///
  /// In ko, this message translates to:
  /// **'증권 투자는 Pro 전용 · 지금 시작하기'**
  String get accountProPromo;

  /// No description provided for @accountPerMonth.
  ///
  /// In ko, this message translates to:
  /// **'/ 월'**
  String get accountPerMonth;

  /// No description provided for @accountProStart.
  ///
  /// In ko, this message translates to:
  /// **'Pro 시작'**
  String get accountProStart;

  /// No description provided for @accountManage.
  ///
  /// In ko, this message translates to:
  /// **'계정 관리'**
  String get accountManage;

  /// No description provided for @accountLogoutDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서만'**
  String get accountLogoutDesc;

  /// No description provided for @accountWithdraw.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get accountWithdraw;

  /// No description provided for @accountWithdrawDesc.
  ///
  /// In ko, this message translates to:
  /// **'영구 삭제'**
  String get accountWithdrawDesc;

  /// No description provided for @accountLogoutConfirm.
  ///
  /// In ko, this message translates to:
  /// **'정말 로그아웃 하시겠어요?'**
  String get accountLogoutConfirm;

  /// No description provided for @accountWithdrawTitle.
  ///
  /// In ko, this message translates to:
  /// **'정말 탈퇴하시겠습니까?'**
  String get accountWithdrawTitle;

  /// No description provided for @accountWithdrawConfirm.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴 시 모든 데이터가 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'**
  String get accountWithdrawConfirm;

  /// No description provided for @notiUnreadPrefix.
  ///
  /// In ko, this message translates to:
  /// **'읽지 않은 알림 '**
  String get notiUnreadPrefix;

  /// No description provided for @notiUnreadSuffix.
  ///
  /// In ko, this message translates to:
  /// **'개'**
  String get notiUnreadSuffix;

  /// No description provided for @notiSettings.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notiSettings;

  /// No description provided for @notiSettingsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'설정을 불러오지 못했습니다'**
  String get notiSettingsLoadError;

  /// No description provided for @notiKindTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 종류'**
  String get notiKindTitle;

  /// No description provided for @notiKindSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'필요한 알림만 켜두면 더 편해요.'**
  String get notiKindSubtitle;

  /// No description provided for @notiPayment.
  ///
  /// In ko, this message translates to:
  /// **'결제 알림'**
  String get notiPayment;

  /// No description provided for @notiPaymentDesc.
  ///
  /// In ko, this message translates to:
  /// **'결제 예정일 D-1, 결제일 당일 알림'**
  String get notiPaymentDesc;

  /// No description provided for @notiBudgetDesc.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 예산 {threshold}%·100% 도달'**
  String notiBudgetDesc(int threshold);

  /// No description provided for @notiAutoRecord.
  ///
  /// In ko, this message translates to:
  /// **'자동 기록 알림'**
  String get notiAutoRecord;

  /// No description provided for @notiAutoRecordDesc.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래가 자동으로 기록되었을 때'**
  String get notiAutoRecordDesc;

  /// No description provided for @notiDutchPay.
  ///
  /// In ko, this message translates to:
  /// **'더치페이 알림'**
  String get notiDutchPay;

  /// No description provided for @notiDutchPayDesc.
  ///
  /// In ko, this message translates to:
  /// **'송금 요청 / 정산 완료 알림'**
  String get notiDutchPayDesc;

  /// No description provided for @notiCalendarDesc.
  ///
  /// In ko, this message translates to:
  /// **'캘린더 이벤트 시작 15분 전'**
  String get notiCalendarDesc;

  /// No description provided for @notiWeeklyReport.
  ///
  /// In ko, this message translates to:
  /// **'주간 리포트'**
  String get notiWeeklyReport;

  /// No description provided for @notiWeeklyReportDesc.
  ///
  /// In ko, this message translates to:
  /// **'매주 월요일 오전 9시'**
  String get notiWeeklyReportDesc;

  /// No description provided for @notiMonthlyReport.
  ///
  /// In ko, this message translates to:
  /// **'월간 리포트'**
  String get notiMonthlyReport;

  /// No description provided for @notiMonthlyReportDesc.
  ///
  /// In ko, this message translates to:
  /// **'매월 1일 오전 9시'**
  String get notiMonthlyReportDesc;

  /// No description provided for @notiPush.
  ///
  /// In ko, this message translates to:
  /// **'푸시 알림'**
  String get notiPush;

  /// No description provided for @notiPushOn.
  ///
  /// In ko, this message translates to:
  /// **'모든 알림이 활성화되어 있어요'**
  String get notiPushOn;

  /// No description provided for @notiPushOff.
  ///
  /// In ko, this message translates to:
  /// **'알림이 꺼져 있어요'**
  String get notiPushOff;

  /// No description provided for @notiThresholdTitle.
  ///
  /// In ko, this message translates to:
  /// **'예산 알림 임계값'**
  String get notiThresholdTitle;

  /// No description provided for @notiThresholdCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 '**
  String get notiThresholdCurrent;

  /// No description provided for @notiThresholdDesc1.
  ///
  /// In ko, this message translates to:
  /// **'예산 사용률이 이 값을 넘으면 '**
  String get notiThresholdDesc1;

  /// No description provided for @notiThresholdWarning.
  ///
  /// In ko, this message translates to:
  /// **'경고'**
  String get notiThresholdWarning;

  /// No description provided for @notiThresholdDesc2.
  ///
  /// In ko, this message translates to:
  /// **' 상태로 표시되고 알림을 받습니다. 100%는 '**
  String get notiThresholdDesc2;

  /// No description provided for @notiThresholdOver.
  ///
  /// In ko, this message translates to:
  /// **'초과'**
  String get notiThresholdOver;

  /// No description provided for @notiThresholdDesc3.
  ///
  /// In ko, this message translates to:
  /// **'로 별도 알림이 발생합니다.'**
  String get notiThresholdDesc3;

  /// No description provided for @notiQuietTitle.
  ///
  /// In ko, this message translates to:
  /// **'방해 금지 시간'**
  String get notiQuietTitle;

  /// No description provided for @notiQuietSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이 시간에는 알림이 소리·진동 없이 표시됩니다.'**
  String get notiQuietSubtitle;

  /// No description provided for @notiQuietToggle.
  ///
  /// In ko, this message translates to:
  /// **'방해 금지 사용'**
  String get notiQuietToggle;

  /// No description provided for @notiQuietToggleDesc.
  ///
  /// In ko, this message translates to:
  /// **'시간대를 지정해 자동 무음'**
  String get notiQuietToggleDesc;

  /// No description provided for @notiQuietStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get notiQuietStart;

  /// No description provided for @notiQuietEnd.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get notiQuietEnd;

  /// No description provided for @notiSoundTitle.
  ///
  /// In ko, this message translates to:
  /// **'소리·진동'**
  String get notiSoundTitle;

  /// No description provided for @notiSound.
  ///
  /// In ko, this message translates to:
  /// **'알림음'**
  String get notiSound;

  /// No description provided for @notiSoundDesc.
  ///
  /// In ko, this message translates to:
  /// **'앱 알림 사운드'**
  String get notiSoundDesc;

  /// No description provided for @notiSoundChime.
  ///
  /// In ko, this message translates to:
  /// **'차임'**
  String get notiSoundChime;

  /// No description provided for @notiSoundDefault.
  ///
  /// In ko, this message translates to:
  /// **'기본'**
  String get notiSoundDefault;

  /// No description provided for @notiSoundNone.
  ///
  /// In ko, this message translates to:
  /// **'무음'**
  String get notiSoundNone;

  /// No description provided for @notiVibration.
  ///
  /// In ko, this message translates to:
  /// **'진동'**
  String get notiVibration;

  /// No description provided for @notiVibrationDesc.
  ///
  /// In ko, this message translates to:
  /// **'모바일에서 진동 함께 알림'**
  String get notiVibrationDesc;

  /// No description provided for @notiEmailTitle.
  ///
  /// In ko, this message translates to:
  /// **'이메일 알림'**
  String get notiEmailTitle;

  /// No description provided for @notiEmailSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앱을 잘 안 열어도 이메일로 요약을 받아볼 수 있어요.'**
  String get notiEmailSubtitle;

  /// No description provided for @notiEmailToggle.
  ///
  /// In ko, this message translates to:
  /// **'이메일 받기'**
  String get notiEmailToggle;

  /// No description provided for @notiEmailNone.
  ///
  /// In ko, this message translates to:
  /// **'등록된 이메일이 없습니다'**
  String get notiEmailNone;

  /// No description provided for @notiEmailFreq.
  ///
  /// In ko, this message translates to:
  /// **'발송 주기'**
  String get notiEmailFreq;

  /// No description provided for @notiEmailDaily.
  ///
  /// In ko, this message translates to:
  /// **'매일'**
  String get notiEmailDaily;

  /// No description provided for @notiEmailWeekly.
  ///
  /// In ko, this message translates to:
  /// **'매주'**
  String get notiEmailWeekly;

  /// No description provided for @notiEmailMonthly.
  ///
  /// In ko, this message translates to:
  /// **'매월'**
  String get notiEmailMonthly;

  /// No description provided for @presetManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 관리'**
  String get presetManageTitle;

  /// No description provided for @presetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 로드 실패'**
  String get presetLoadError;

  /// No description provided for @presetDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 삭제'**
  String get presetDeleteTitle;

  /// No description provided for @presetDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 프리셋을 삭제할까요? 이미 저장된 거래 내역에는 영향이 없습니다.'**
  String presetDeleteConfirm(String name);

  /// No description provided for @presetDeleted.
  ///
  /// In ko, this message translates to:
  /// **'프리셋이 삭제되었습니다'**
  String get presetDeleted;

  /// No description provided for @presetDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get presetDeleteFailed;

  /// No description provided for @presetIntroTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋이란?'**
  String get presetIntroTitle;

  /// No description provided for @presetIntroBody.
  ///
  /// In ko, this message translates to:
  /// **'자주 쓰는 내역(점심·커피·교통비 등)을 미리 저장해두면, 내역 추가 화면에서 한 번 탭으로 카테고리·결제수단·내역을 모두 채워넣어요. 금액만 바꿔서 단건으로 저장하기 좋습니다.'**
  String get presetIntroBody;

  /// No description provided for @presetStatSaved.
  ///
  /// In ko, this message translates to:
  /// **'저장된 프리셋'**
  String get presetStatSaved;

  /// No description provided for @presetStatUses.
  ///
  /// In ko, this message translates to:
  /// **'누적 사용'**
  String get presetStatUses;

  /// No description provided for @presetUsesCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String presetUsesCount(int count);

  /// No description provided for @presetStatType.
  ///
  /// In ko, this message translates to:
  /// **'지출 / 수입'**
  String get presetStatType;

  /// No description provided for @presetSortUsed.
  ///
  /// In ko, this message translates to:
  /// **'사용 많은 순'**
  String get presetSortUsed;

  /// No description provided for @presetSortRecent.
  ///
  /// In ko, this message translates to:
  /// **'최근 사용'**
  String get presetSortRecent;

  /// No description provided for @presetSortName.
  ///
  /// In ko, this message translates to:
  /// **'이름순'**
  String get presetSortName;

  /// No description provided for @presetAdd.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 추가'**
  String get presetAdd;

  /// No description provided for @presetAmountEmpty.
  ///
  /// In ko, this message translates to:
  /// **'금액 비움'**
  String get presetAmountEmpty;

  /// No description provided for @presetNoCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 없음'**
  String get presetNoCategory;

  /// No description provided for @presetEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'저장된 프리셋이 없어요'**
  String get presetEmptyTitle;

  /// No description provided for @presetEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'자주 쓰는 내역을 추가해 매번 입력하는 수고를 줄여보세요.'**
  String get presetEmptyDesc;

  /// No description provided for @presetEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 수정'**
  String get presetEditTitle;

  /// No description provided for @presetSubmitAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get presetSubmitAdd;

  /// No description provided for @presetName.
  ///
  /// In ko, this message translates to:
  /// **'프리셋 이름'**
  String get presetName;

  /// No description provided for @presetMerchant.
  ///
  /// In ko, this message translates to:
  /// **'기본 내역'**
  String get presetMerchant;

  /// No description provided for @presetMerchantPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 한솥 도시락'**
  String get presetMerchantPlaceholder;

  /// No description provided for @presetSelectNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get presetSelectNone;

  /// No description provided for @presetAssetCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드'**
  String get presetAssetCard;

  /// No description provided for @presetAssetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'자산 로드 실패'**
  String get presetAssetLoadError;

  /// No description provided for @presetLockToggle.
  ///
  /// In ko, this message translates to:
  /// **'고정 금액 사용'**
  String get presetLockToggle;

  /// No description provided for @presetLockDesc.
  ///
  /// In ko, this message translates to:
  /// **'꺼두면 불러올 때 금액이 비어있어요. 매번 다른 금액일 때 편해요.'**
  String get presetLockDesc;

  /// No description provided for @presetLockAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'고정 금액'**
  String get presetLockAmountLabel;

  /// No description provided for @presetUpdated.
  ///
  /// In ko, this message translates to:
  /// **'프리셋이 수정되었습니다'**
  String get presetUpdated;

  /// No description provided for @presetCreated.
  ///
  /// In ko, this message translates to:
  /// **'프리셋이 추가되었습니다'**
  String get presetCreated;

  /// No description provided for @recurringToggleFailed.
  ///
  /// In ko, this message translates to:
  /// **'변경 실패'**
  String get recurringToggleFailed;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 삭제'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 반복 설정을 삭제할까요?\n이미 기록된 거래는 그대로 남습니다.'**
  String recurringDeleteConfirm(String name);

  /// No description provided for @recurringDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get recurringDeleteFailed;

  /// No description provided for @recurringLoadError.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래를 불러오지 못했습니다'**
  String get recurringLoadError;

  /// No description provided for @recurringAllList.
  ///
  /// In ko, this message translates to:
  /// **'전체 목록'**
  String get recurringAllList;

  /// No description provided for @recurringAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get recurringAdd;

  /// No description provided for @recurringFilterAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 {count}'**
  String recurringFilterAll(int count);

  /// No description provided for @recurringFilterExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출 {count}'**
  String recurringFilterExpense(int count);

  /// No description provided for @recurringFilterIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입 {count}'**
  String recurringFilterIncome(int count);

  /// No description provided for @recurringFilterPaused.
  ///
  /// In ko, this message translates to:
  /// **'일시정지 {count}'**
  String recurringFilterPaused(int count);

  /// No description provided for @recurringStatActive.
  ///
  /// In ko, this message translates to:
  /// **'활성 반복'**
  String get recurringStatActive;

  /// No description provided for @recurringCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String recurringCount(int count);

  /// No description provided for @recurringPaused.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get recurringPaused;

  /// No description provided for @recurringMonthlyExpense.
  ///
  /// In ko, this message translates to:
  /// **'매월 고정 지출'**
  String get recurringMonthlyExpense;

  /// No description provided for @recurringMonthlyIncome.
  ///
  /// In ko, this message translates to:
  /// **'매월 고정 수입'**
  String get recurringMonthlyIncome;

  /// No description provided for @recurringUpcoming.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 7일'**
  String get recurringUpcoming;

  /// No description provided for @recurringUpcomingCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 예정'**
  String recurringUpcomingCount(int count);

  /// No description provided for @recurringToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get recurringToday;

  /// No description provided for @recurringNoAccount.
  ///
  /// In ko, this message translates to:
  /// **'계좌 없음'**
  String get recurringNoAccount;

  /// No description provided for @recurringOccurrences.
  ///
  /// In ko, this message translates to:
  /// **'{executed}/{max}회'**
  String recurringOccurrences(int executed, int max);

  /// No description provided for @recurringNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get recurringNext;

  /// No description provided for @recurringStart.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get recurringStart;

  /// No description provided for @recurringEmpty.
  ///
  /// In ko, this message translates to:
  /// **'해당하는 반복 거래가 없어요'**
  String get recurringEmpty;

  /// No description provided for @recurringIndefinite.
  ///
  /// In ko, this message translates to:
  /// **'무기한'**
  String get recurringIndefinite;

  /// No description provided for @recurringNotifyShort.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get recurringNotifyShort;

  /// No description provided for @recurringAddTitle.
  ///
  /// In ko, this message translates to:
  /// **'반복 거래 추가'**
  String get recurringAddTitle;

  /// No description provided for @recurringSaveSubmit.
  ///
  /// In ko, this message translates to:
  /// **'반복 저장'**
  String get recurringSaveSubmit;

  /// No description provided for @recurringUpdated.
  ///
  /// In ko, this message translates to:
  /// **'반복 설정이 수정되었습니다'**
  String get recurringUpdated;

  /// No description provided for @recurringSaved.
  ///
  /// In ko, this message translates to:
  /// **'반복 설정이 저장되었습니다'**
  String get recurringSaved;

  /// No description provided for @recurringSaveFailed.
  ///
  /// In ko, this message translates to:
  /// **'저장 실패'**
  String get recurringSaveFailed;

  /// No description provided for @recurringIntro.
  ///
  /// In ko, this message translates to:
  /// **'이 거래를 정해진 주기로 자동 반복합니다. 구독료·월세·정기 후원 등에 사용해보세요.'**
  String get recurringIntro;

  /// No description provided for @recurringFrequencyLabel.
  ///
  /// In ko, this message translates to:
  /// **'반복 주기'**
  String get recurringFrequencyLabel;

  /// No description provided for @recurringDayOfWeekLabel.
  ///
  /// In ko, this message translates to:
  /// **'요일'**
  String get recurringDayOfWeekLabel;

  /// No description provided for @recurringDayOfMonthLabel.
  ///
  /// In ko, this message translates to:
  /// **'반복 일자'**
  String get recurringDayOfMonthLabel;

  /// No description provided for @recurringDayNote.
  ///
  /// In ko, this message translates to:
  /// **'해당 일이 없는 달은 말일에 처리됩니다'**
  String get recurringDayNote;

  /// No description provided for @recurringEndLabel.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get recurringEndLabel;

  /// No description provided for @recurringIndefiniteDesc.
  ///
  /// In ko, this message translates to:
  /// **'중지할 때까지 계속 반복'**
  String get recurringIndefiniteDesc;

  /// No description provided for @recurringByCount.
  ///
  /// In ko, this message translates to:
  /// **'횟수 지정'**
  String get recurringByCount;

  /// No description provided for @recurringTotal.
  ///
  /// In ko, this message translates to:
  /// **'총'**
  String get recurringTotal;

  /// No description provided for @recurringTimesUnit.
  ///
  /// In ko, this message translates to:
  /// **'회'**
  String get recurringTimesUnit;

  /// No description provided for @recurringByDate.
  ///
  /// In ko, this message translates to:
  /// **'종료일 지정'**
  String get recurringByDate;

  /// No description provided for @recurringOptions.
  ///
  /// In ko, this message translates to:
  /// **'옵션'**
  String get recurringOptions;

  /// No description provided for @recurringAutoLog.
  ///
  /// In ko, this message translates to:
  /// **'자동 기록'**
  String get recurringAutoLog;

  /// No description provided for @recurringAutoLogDesc.
  ///
  /// In ko, this message translates to:
  /// **'해당 일자에 거래를 자동으로 추가합니다'**
  String get recurringAutoLogDesc;

  /// No description provided for @recurringNotifyDayBefore.
  ///
  /// In ko, this message translates to:
  /// **'하루 전 알림'**
  String get recurringNotifyDayBefore;

  /// No description provided for @recurringNotifyDesc.
  ///
  /// In ko, this message translates to:
  /// **'결제·이체 예정일 전날 알림을 보냅니다'**
  String get recurringNotifyDesc;

  /// No description provided for @recurringNextDates.
  ///
  /// In ko, this message translates to:
  /// **'다음 예정일'**
  String get recurringNextDates;

  /// No description provided for @recurringSourceSub.
  ///
  /// In ko, this message translates to:
  /// **'구독료·월세 등 정기 거래에 쓰여요'**
  String get recurringSourceSub;

  /// No description provided for @recurringStartFrom.
  ///
  /// In ko, this message translates to:
  /// **'{date} 시작'**
  String recurringStartFrom(String date);

  /// No description provided for @recurringMerchant.
  ///
  /// In ko, this message translates to:
  /// **'거래처'**
  String get recurringMerchant;

  /// No description provided for @recurringMerchantPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 넷플릭스'**
  String get recurringMerchantPlaceholder;

  /// No description provided for @recurringAssetCard.
  ///
  /// In ko, this message translates to:
  /// **'계좌·카드'**
  String get recurringAssetCard;

  /// No description provided for @recurringAssetLoadError.
  ///
  /// In ko, this message translates to:
  /// **'자산 로드 실패'**
  String get recurringAssetLoadError;

  /// No description provided for @recurringSelectNone.
  ///
  /// In ko, this message translates to:
  /// **'선택 안 함'**
  String get recurringSelectNone;

  /// No description provided for @recurringStartDateLabel.
  ///
  /// In ko, this message translates to:
  /// **'반복 시작일'**
  String get recurringStartDateLabel;

  /// No description provided for @recurringParentCategory.
  ///
  /// In ko, this message translates to:
  /// **'{name} (상위)'**
  String recurringParentCategory(String name);

  /// No description provided for @savingGoalLoadError.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표 로드 실패'**
  String get savingGoalLoadError;

  /// No description provided for @savingGoalOverallProgress.
  ///
  /// In ko, this message translates to:
  /// **'전체 진행률'**
  String get savingGoalOverallProgress;

  /// No description provided for @savingGoalListCount.
  ///
  /// In ko, this message translates to:
  /// **'목표 목록 · {n}개'**
  String savingGoalListCount(int n);

  /// No description provided for @savingGoalAddAction.
  ///
  /// In ko, this message translates to:
  /// **'목표 추가'**
  String get savingGoalAddAction;

  /// No description provided for @savingGoalManagePrompt.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 저축 목표를 추가해보세요'**
  String get savingGoalManagePrompt;

  /// No description provided for @savingGoalManageLink.
  ///
  /// In ko, this message translates to:
  /// **'관리'**
  String get savingGoalManageLink;

  /// No description provided for @savingGoalNoDeadline.
  ///
  /// In ko, this message translates to:
  /// **'기한 없음'**
  String get savingGoalNoDeadline;

  /// No description provided for @savingGoalCurrentLabel.
  ///
  /// In ko, this message translates to:
  /// **'현재 모은 금액'**
  String get savingGoalCurrentLabel;

  /// No description provided for @savingGoalIconLabel.
  ///
  /// In ko, this message translates to:
  /// **'아이콘'**
  String get savingGoalIconLabel;

  /// No description provided for @savingGoalEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 저축 목표가 없어요. ‘목표 추가’로 시작해보세요.'**
  String get savingGoalEmpty;

  /// No description provided for @savingGoalActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get savingGoalActionFailed;

  /// No description provided for @savingGoalAchieved.
  ///
  /// In ko, this message translates to:
  /// **'달성!'**
  String get savingGoalAchieved;

  /// No description provided for @savingGoalAdd.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표 추가'**
  String get savingGoalAdd;

  /// No description provided for @savingGoalEdit.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표 수정'**
  String get savingGoalEdit;

  /// No description provided for @savingGoalSubmitAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get savingGoalSubmitAdd;

  /// No description provided for @savingGoalDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'저축 목표 삭제'**
  String get savingGoalDeleteTitle;

  /// No description provided for @savingGoalDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\"을(를) 삭제할까요?'**
  String savingGoalDeleteConfirm(String title);

  /// No description provided for @savingGoalDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get savingGoalDeleteFailed;

  /// No description provided for @savingGoalNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'목표 이름'**
  String get savingGoalNameLabel;

  /// No description provided for @savingGoalNameHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 비상금'**
  String get savingGoalNameHint;

  /// No description provided for @savingGoalAmountLabel.
  ///
  /// In ko, this message translates to:
  /// **'목표 금액'**
  String get savingGoalAmountLabel;

  /// No description provided for @savingGoalDeadlineLabel.
  ///
  /// In ko, this message translates to:
  /// **'마감일 (선택)'**
  String get savingGoalDeadlineLabel;

  /// No description provided for @savingGoalDeadlineHint.
  ///
  /// In ko, this message translates to:
  /// **'미설정'**
  String get savingGoalDeadlineHint;

  /// No description provided for @savingGoalColorLabel.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get savingGoalColorLabel;

  /// No description provided for @searchAdvancedFilter.
  ///
  /// In ko, this message translates to:
  /// **'고급 필터'**
  String get searchAdvancedFilter;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'거래 검색...'**
  String get searchHint;

  /// No description provided for @searchStartHint.
  ///
  /// In ko, this message translates to:
  /// **'시작'**
  String get searchStartHint;

  /// No description provided for @searchEndHint.
  ///
  /// In ko, this message translates to:
  /// **'종료'**
  String get searchEndHint;

  /// No description provided for @searchFailed.
  ///
  /// In ko, this message translates to:
  /// **'검색 실패'**
  String get searchFailed;

  /// No description provided for @searchEmptyHint.
  ///
  /// In ko, this message translates to:
  /// **'키워드, 가맹점, 메모로 검색하세요'**
  String get searchEmptyHint;

  /// No description provided for @searchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'결과가 없습니다'**
  String get searchNoResults;

  /// No description provided for @statsTabTrend.
  ///
  /// In ko, this message translates to:
  /// **'추이'**
  String get statsTabTrend;

  /// No description provided for @statsTabCompare.
  ///
  /// In ko, this message translates to:
  /// **'비교'**
  String get statsTabCompare;

  /// No description provided for @statsThisQuarter.
  ///
  /// In ko, this message translates to:
  /// **'이번 분기'**
  String get statsThisQuarter;

  /// No description provided for @statsThisYear.
  ///
  /// In ko, this message translates to:
  /// **'이번 해'**
  String get statsThisYear;

  /// No description provided for @statsCustomPeriod.
  ///
  /// In ko, this message translates to:
  /// **'선택 기간'**
  String get statsCustomPeriod;

  /// No description provided for @statsLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난 달'**
  String get statsLastMonth;

  /// No description provided for @statsLastQuarter.
  ///
  /// In ko, this message translates to:
  /// **'지난 분기'**
  String get statsLastQuarter;

  /// No description provided for @statsLastYear.
  ///
  /// In ko, this message translates to:
  /// **'지난 해'**
  String get statsLastYear;

  /// No description provided for @statsPrevPeriod.
  ///
  /// In ko, this message translates to:
  /// **'이전 기간'**
  String get statsPrevPeriod;

  /// No description provided for @statsMomMonth.
  ///
  /// In ko, this message translates to:
  /// **'전월 대비'**
  String get statsMomMonth;

  /// No description provided for @statsMomQuarter.
  ///
  /// In ko, this message translates to:
  /// **'전분기 대비'**
  String get statsMomQuarter;

  /// No description provided for @statsMomYear.
  ///
  /// In ko, this message translates to:
  /// **'전년 대비'**
  String get statsMomYear;

  /// No description provided for @statsMomCustom.
  ///
  /// In ko, this message translates to:
  /// **'이전 기간 대비'**
  String get statsMomCustom;

  /// No description provided for @statsMomPrevMonth.
  ///
  /// In ko, this message translates to:
  /// **'전월'**
  String get statsMomPrevMonth;

  /// No description provided for @statsMomPrevQuarter.
  ///
  /// In ko, this message translates to:
  /// **'전분기'**
  String get statsMomPrevQuarter;

  /// No description provided for @statsMomPrevYear.
  ///
  /// In ko, this message translates to:
  /// **'전년'**
  String get statsMomPrevYear;

  /// No description provided for @statsDailyAvg.
  ///
  /// In ko, this message translates to:
  /// **'하루 평균'**
  String get statsDailyAvg;

  /// No description provided for @statsMonthlyAvg.
  ///
  /// In ko, this message translates to:
  /// **'월 평균'**
  String get statsMonthlyAvg;

  /// No description provided for @statsPeriodPickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'기간 선택'**
  String get statsPeriodPickerTitle;

  /// No description provided for @statsRange7d.
  ///
  /// In ko, this message translates to:
  /// **'최근 7일'**
  String get statsRange7d;

  /// No description provided for @statsRange30d.
  ///
  /// In ko, this message translates to:
  /// **'최근 30일'**
  String get statsRange30d;

  /// No description provided for @statsRange3m.
  ///
  /// In ko, this message translates to:
  /// **'최근 3개월'**
  String get statsRange3m;

  /// No description provided for @statsRange6m.
  ///
  /// In ko, this message translates to:
  /// **'최근 6개월'**
  String get statsRange6m;

  /// No description provided for @statsRange1y.
  ///
  /// In ko, this message translates to:
  /// **'최근 1년'**
  String get statsRange1y;

  /// No description provided for @statsSegMonth.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get statsSegMonth;

  /// No description provided for @statsSegQuarter.
  ///
  /// In ko, this message translates to:
  /// **'분기'**
  String get statsSegQuarter;

  /// No description provided for @statsSegYear.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get statsSegYear;

  /// No description provided for @statsSegCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접'**
  String get statsSegCustom;

  /// No description provided for @statsNoData.
  ///
  /// In ko, this message translates to:
  /// **'데이터가 없습니다'**
  String get statsNoData;

  /// No description provided for @statsNoDataShort.
  ///
  /// In ko, this message translates to:
  /// **'데이터 없음'**
  String get statsNoDataShort;

  /// No description provided for @statsUnassigned.
  ///
  /// In ko, this message translates to:
  /// **'미지정'**
  String get statsUnassigned;

  /// No description provided for @statsCategoryDetail.
  ///
  /// In ko, this message translates to:
  /// **'{name} 세부'**
  String statsCategoryDetail(String name);

  /// No description provided for @statsPeriodSpending.
  ///
  /// In ko, this message translates to:
  /// **'{period} 지출'**
  String statsPeriodSpending(String period);

  /// No description provided for @statsSpendingByCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 지출'**
  String get statsSpendingByCategory;

  /// No description provided for @statsNoCategoryData.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 데이터가 없습니다'**
  String get statsNoCategoryData;

  /// No description provided for @statsTopMerchantsTitle.
  ///
  /// In ko, this message translates to:
  /// **'많이 쓴 가맹점 TOP 5'**
  String get statsTopMerchantsTitle;

  /// No description provided for @statsNoMerchantData.
  ///
  /// In ko, this message translates to:
  /// **'가맹점 데이터가 없습니다'**
  String get statsNoMerchantData;

  /// No description provided for @statsNoName.
  ///
  /// In ko, this message translates to:
  /// **'(이름 없음)'**
  String get statsNoName;

  /// No description provided for @statsTimeMorning.
  ///
  /// In ko, this message translates to:
  /// **'아침'**
  String get statsTimeMorning;

  /// No description provided for @statsTimeLunch.
  ///
  /// In ko, this message translates to:
  /// **'점심'**
  String get statsTimeLunch;

  /// No description provided for @statsTimeAfternoon.
  ///
  /// In ko, this message translates to:
  /// **'오후'**
  String get statsTimeAfternoon;

  /// No description provided for @statsTimeEvening.
  ///
  /// In ko, this message translates to:
  /// **'저녁'**
  String get statsTimeEvening;

  /// No description provided for @statsTimeLateNight.
  ///
  /// In ko, this message translates to:
  /// **'심야'**
  String get statsTimeLateNight;

  /// No description provided for @statsTimeDawn.
  ///
  /// In ko, this message translates to:
  /// **'새벽'**
  String get statsTimeDawn;

  /// No description provided for @statsPatternTitle.
  ///
  /// In ko, this message translates to:
  /// **'요일·시간대 지출 패턴'**
  String get statsPatternTitle;

  /// No description provided for @statsPatternDesc.
  ///
  /// In ko, this message translates to:
  /// **'색이 진할수록 지출이 많은 시간대예요 (단위: 원)'**
  String get statsPatternDesc;

  /// No description provided for @statsTooFewTx.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 거래가 아직 적어요'**
  String get statsTooFewTx;

  /// No description provided for @statsLegendLow.
  ///
  /// In ko, this message translates to:
  /// **'적음'**
  String get statsLegendLow;

  /// No description provided for @statsLegendHigh.
  ///
  /// In ko, this message translates to:
  /// **'많음'**
  String get statsLegendHigh;

  /// No description provided for @statsTotalPrefix.
  ///
  /// In ko, this message translates to:
  /// **'총'**
  String get statsTotalPrefix;

  /// No description provided for @statsDaysTotal.
  ///
  /// In ko, this message translates to:
  /// **'{days}일 합계'**
  String statsDaysTotal(int days);

  /// No description provided for @statsMomCalculating.
  ///
  /// In ko, this message translates to:
  /// **'전월 대비 계산 중…'**
  String get statsMomCalculating;

  /// No description provided for @statsMomUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'전월 비교 불가'**
  String get statsMomUnavailable;

  /// No description provided for @statsTopCategory.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 쓴 카테고리'**
  String get statsTopCategory;

  /// No description provided for @statsTopMerchant.
  ///
  /// In ko, this message translates to:
  /// **'가장 많이 쓴 가맹점'**
  String get statsTopMerchant;

  /// No description provided for @statsIncomeExpenseTrend.
  ///
  /// In ko, this message translates to:
  /// **'수입·지출 추이'**
  String get statsIncomeExpenseTrend;

  /// No description provided for @statsNoTrendData.
  ///
  /// In ko, this message translates to:
  /// **'추이 데이터가 없습니다'**
  String get statsNoTrendData;

  /// No description provided for @statsAvgIncome.
  ///
  /// In ko, this message translates to:
  /// **'평균 수입'**
  String get statsAvgIncome;

  /// No description provided for @statsAvgExpense.
  ///
  /// In ko, this message translates to:
  /// **'평균 지출'**
  String get statsAvgExpense;

  /// No description provided for @statsNetSavings.
  ///
  /// In ko, this message translates to:
  /// **'순저축'**
  String get statsNetSavings;

  /// No description provided for @statsAvgSavings.
  ///
  /// In ko, this message translates to:
  /// **'평균 저축'**
  String get statsAvgSavings;

  /// No description provided for @statsSavingsRate.
  ///
  /// In ko, this message translates to:
  /// **'저축률'**
  String get statsSavingsRate;

  /// No description provided for @statsSavingsInsight.
  ///
  /// In ko, this message translates to:
  /// **'월 평균 수입의 {pct}%를 저축하고 있어요'**
  String statsSavingsInsight(int pct);

  /// No description provided for @statsDailyNetSavings.
  ///
  /// In ko, this message translates to:
  /// **'일별 순저축'**
  String get statsDailyNetSavings;

  /// No description provided for @statsMonthlyNetSavings.
  ///
  /// In ko, this message translates to:
  /// **'월별 순저축'**
  String get statsMonthlyNetSavings;

  /// No description provided for @statsCatTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'주요 카테고리 월별 추이'**
  String get statsCatTrendTitle;

  /// No description provided for @statsCatTrendTop3.
  ///
  /// In ko, this message translates to:
  /// **'지출 TOP 3'**
  String get statsCatTrendTop3;

  /// No description provided for @statsIncomeMinusExpense.
  ///
  /// In ko, this message translates to:
  /// **'수입 − 지출'**
  String get statsIncomeMinusExpense;

  /// No description provided for @statsNoDataFor.
  ///
  /// In ko, this message translates to:
  /// **'{period} 데이터 없음'**
  String statsNoDataFor(String period);

  /// No description provided for @statsCategoryByMom.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 {mom}'**
  String statsCategoryByMom(String mom);

  /// No description provided for @statsCategoryDelta.
  ///
  /// In ko, this message translates to:
  /// **'카테고리별 증감'**
  String get statsCategoryDelta;

  /// No description provided for @statsSortByChange.
  ///
  /// In ko, this message translates to:
  /// **'변화 큰 순'**
  String get statsSortByChange;

  /// No description provided for @statsNoCompareData.
  ///
  /// In ko, this message translates to:
  /// **'비교할 데이터가 없습니다'**
  String get statsNoCompareData;

  /// No description provided for @statsWeekdayTitle.
  ///
  /// In ko, this message translates to:
  /// **'요일별 지출 비교'**
  String get statsWeekdayTitle;

  /// No description provided for @statsThisMonthShort.
  ///
  /// In ko, this message translates to:
  /// **'이번 달'**
  String get statsThisMonthShort;

  /// No description provided for @statsLastMonthShort.
  ///
  /// In ko, this message translates to:
  /// **'지난 달'**
  String get statsLastMonthShort;

  /// No description provided for @statsWeekdayInsightDown.
  ///
  /// In ko, this message translates to:
  /// **'{day}요일 지출이 지난 달보다 {amount} 줄었어요.'**
  String statsWeekdayInsightDown(String day, String amount);

  /// No description provided for @statsWeekdayInsightUp.
  ///
  /// In ko, this message translates to:
  /// **'{day}요일 지출이 지난 달보다 {amount} 늘었어요.'**
  String statsWeekdayInsightUp(String day, String amount);

  /// No description provided for @statsWeekdayInsightSame.
  ///
  /// In ko, this message translates to:
  /// **'요일별 지출이 지난 달과 비슷해요.'**
  String get statsWeekdayInsightSame;

  /// No description provided for @statsVsLastPrefix.
  ///
  /// In ko, this message translates to:
  /// **'{prev}보다'**
  String statsVsLastPrefix(String prev);

  /// No description provided for @statsVsLastDirLess.
  ///
  /// In ko, this message translates to:
  /// **'덜'**
  String get statsVsLastDirLess;

  /// No description provided for @statsVsLastDirMore.
  ///
  /// In ko, this message translates to:
  /// **'더'**
  String get statsVsLastDirMore;

  /// No description provided for @statsVsLastSuffix.
  ///
  /// In ko, this message translates to:
  /// **'썼어요'**
  String statsVsLastSuffix(String prev);

  /// No description provided for @statsCompareDailyAvg.
  ///
  /// In ko, this message translates to:
  /// **'하루 평균'**
  String get statsCompareDailyAvg;

  /// No description provided for @statsCompareTxCount.
  ///
  /// In ko, this message translates to:
  /// **'거래 건수'**
  String get statsCompareTxCount;

  /// No description provided for @statsComparePerTx.
  ///
  /// In ko, this message translates to:
  /// **'건당 평균'**
  String get statsComparePerTx;

  /// No description provided for @statsCountValue.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String statsCountValue(int count);

  /// No description provided for @stocksChartTokenFailed.
  ///
  /// In ko, this message translates to:
  /// **'토큰 발급 실패'**
  String get stocksChartTokenFailed;

  /// No description provided for @stocksChartHttpsError.
  ///
  /// In ko, this message translates to:
  /// **'보안 오류: 차트 WebView 가 HTTPS 가 아닙니다'**
  String get stocksChartHttpsError;

  /// No description provided for @stocksChartInitFailed.
  ///
  /// In ko, this message translates to:
  /// **'차트 초기화 실패'**
  String get stocksChartInitFailed;

  /// No description provided for @stocksChartLoadFailed.
  ///
  /// In ko, this message translates to:
  /// **'차트를 불러올 수 없어요'**
  String get stocksChartLoadFailed;

  /// No description provided for @stocksSearch.
  ///
  /// In ko, this message translates to:
  /// **'종목 검색'**
  String get stocksSearch;

  /// No description provided for @stocksSearchPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'종목명 · 티커로 검색 (예: 삼성전자, NVDA)'**
  String get stocksSearchPlaceholder;

  /// No description provided for @stocksSearchNoResults.
  ///
  /// In ko, this message translates to:
  /// **'\'{query}\' 검색 결과가 없어요'**
  String stocksSearchNoResults(String query);

  /// No description provided for @stocksTabHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유 {count}'**
  String stocksTabHoldings(int count);

  /// No description provided for @stocksTabWatch.
  ///
  /// In ko, this message translates to:
  /// **'관심 {count}'**
  String stocksTabWatch(int count);

  /// No description provided for @stocksTabDiscover.
  ///
  /// In ko, this message translates to:
  /// **'발견'**
  String get stocksTabDiscover;

  /// No description provided for @stocksNoHoldings.
  ///
  /// In ko, this message translates to:
  /// **'보유 중인 종목이 없어요.'**
  String get stocksNoHoldings;

  /// No description provided for @stocksSharesHeld.
  ///
  /// In ko, this message translates to:
  /// **'{qty}주 보유'**
  String stocksSharesHeld(String qty);

  /// No description provided for @stocksRange1d.
  ///
  /// In ko, this message translates to:
  /// **'1D'**
  String get stocksRange1d;

  /// No description provided for @stocksRange1w.
  ///
  /// In ko, this message translates to:
  /// **'1주'**
  String get stocksRange1w;

  /// No description provided for @stocksRange1m.
  ///
  /// In ko, this message translates to:
  /// **'1개월'**
  String get stocksRange1m;

  /// No description provided for @stocksRange3m.
  ///
  /// In ko, this message translates to:
  /// **'3개월'**
  String get stocksRange3m;

  /// No description provided for @stocksRange1y.
  ///
  /// In ko, this message translates to:
  /// **'1년'**
  String get stocksRange1y;

  /// No description provided for @stocksUnitCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String stocksUnitCount(int count);

  /// No description provided for @stocksSharesUnit.
  ///
  /// In ko, this message translates to:
  /// **'{qty}주'**
  String stocksSharesUnit(String qty);

  /// No description provided for @stocksTradingSuspended.
  ///
  /// In ko, this message translates to:
  /// **'거래정지'**
  String get stocksTradingSuspended;

  /// No description provided for @stocksTradingNormal.
  ///
  /// In ko, this message translates to:
  /// **'정상'**
  String get stocksTradingNormal;

  /// No description provided for @stocksWarningLiquidationTrading.
  ///
  /// In ko, this message translates to:
  /// **'정리매매'**
  String get stocksWarningLiquidationTrading;

  /// No description provided for @stocksWarningOverheated.
  ///
  /// In ko, this message translates to:
  /// **'단기과열'**
  String get stocksWarningOverheated;

  /// No description provided for @stocksWarningShortTermOverheat.
  ///
  /// In ko, this message translates to:
  /// **'단기과열'**
  String get stocksWarningShortTermOverheat;

  /// No description provided for @stocksWarningExcessiveRise.
  ///
  /// In ko, this message translates to:
  /// **'이상급등'**
  String get stocksWarningExcessiveRise;

  /// No description provided for @stocksWarningInvestmentWarning.
  ///
  /// In ko, this message translates to:
  /// **'투자경고'**
  String get stocksWarningInvestmentWarning;

  /// No description provided for @stocksWarningInvestmentRisk.
  ///
  /// In ko, this message translates to:
  /// **'투자위험'**
  String get stocksWarningInvestmentRisk;

  /// No description provided for @stocksWarningInvestmentCaution.
  ///
  /// In ko, this message translates to:
  /// **'투자주의'**
  String get stocksWarningInvestmentCaution;

  /// No description provided for @stocksWarningVi.
  ///
  /// In ko, this message translates to:
  /// **'VI 발동'**
  String get stocksWarningVi;

  /// No description provided for @stocksWarningViStatic.
  ///
  /// In ko, this message translates to:
  /// **'정적 VI'**
  String get stocksWarningViStatic;

  /// No description provided for @stocksWarningViDynamic.
  ///
  /// In ko, this message translates to:
  /// **'동적 VI'**
  String get stocksWarningViDynamic;

  /// No description provided for @stocksWarningStockWarrants.
  ///
  /// In ko, this message translates to:
  /// **'신주인수권'**
  String get stocksWarningStockWarrants;

  /// No description provided for @stocksWarningAdministrative.
  ///
  /// In ko, this message translates to:
  /// **'관리종목'**
  String get stocksWarningAdministrative;

  /// No description provided for @stocksWarningAdjustmentOfShares.
  ///
  /// In ko, this message translates to:
  /// **'주식병합·분할'**
  String get stocksWarningAdjustmentOfShares;

  /// No description provided for @stocksNoWatchlist.
  ///
  /// In ko, this message translates to:
  /// **'관심 종목이 없어요. 검색해서 별표를 눌러보세요.'**
  String get stocksNoWatchlist;

  /// No description provided for @stocksDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'종목 상세'**
  String get stocksDetailTitle;

  /// No description provided for @stocksMarketHoliday.
  ///
  /// In ko, this message translates to:
  /// **'휴장'**
  String get stocksMarketHoliday;

  /// No description provided for @stocksMarketTrading.
  ///
  /// In ko, this message translates to:
  /// **'장중 · {time}'**
  String stocksMarketTrading(String time);

  /// No description provided for @stocksMarketOpensAt.
  ///
  /// In ko, this message translates to:
  /// **'개장 {time}'**
  String stocksMarketOpensAt(String time);

  /// No description provided for @stocksMarketClosed.
  ///
  /// In ko, this message translates to:
  /// **'장마감'**
  String get stocksMarketClosed;

  /// No description provided for @stocksMarketKr.
  ///
  /// In ko, this message translates to:
  /// **'국내'**
  String get stocksMarketKr;

  /// No description provided for @stocksMarketUs.
  ///
  /// In ko, this message translates to:
  /// **'미국'**
  String get stocksMarketUs;

  /// No description provided for @stocksConnectPrompt.
  ///
  /// In ko, this message translates to:
  /// **'증권 계정을 연결해 주세요'**
  String get stocksConnectPrompt;

  /// No description provided for @stocksConnectDescRealtime.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 키를 연결하면 시세·보유 종목과\n평가손익을 실시간으로 볼 수 있어요.'**
  String get stocksConnectDescRealtime;

  /// No description provided for @stocksConnectInSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정에서 연결하기'**
  String get stocksConnectInSettings;

  /// No description provided for @stocksConnectDesc.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 키를 연결하면 보유 종목과\n평가손익을 실시간으로 볼 수 있어요.'**
  String get stocksConnectDesc;

  /// No description provided for @stocksConnectAccount.
  ///
  /// In ko, this message translates to:
  /// **'계정 연결하기'**
  String get stocksConnectAccount;

  /// No description provided for @stocksMyEval.
  ///
  /// In ko, this message translates to:
  /// **'내 투자 평가금액'**
  String get stocksMyEval;

  /// No description provided for @stocksConnectShowAssets.
  ///
  /// In ko, this message translates to:
  /// **'증권 계정을 연결하면 보유자산이 보여요'**
  String get stocksConnectShowAssets;

  /// No description provided for @stocksPurchaseAmount.
  ///
  /// In ko, this message translates to:
  /// **'매입금액'**
  String get stocksPurchaseAmount;

  /// No description provided for @stocksHoldingsLabel.
  ///
  /// In ko, this message translates to:
  /// **'보유 종목'**
  String get stocksHoldingsLabel;

  /// No description provided for @stocksExchangeRate.
  ///
  /// In ko, this message translates to:
  /// **'환율(USD)'**
  String get stocksExchangeRate;

  /// No description provided for @stocksSell.
  ///
  /// In ko, this message translates to:
  /// **'매도'**
  String get stocksSell;

  /// No description provided for @stocksSellOrderStub.
  ///
  /// In ko, this message translates to:
  /// **'{name} 매도 주문 — Open API 연동 시 동작'**
  String stocksSellOrderStub(String name);

  /// No description provided for @stocksBuy.
  ///
  /// In ko, this message translates to:
  /// **'매수'**
  String get stocksBuy;

  /// No description provided for @stocksBuyOrderStub.
  ///
  /// In ko, this message translates to:
  /// **'{name} 매수 주문 — Open API 연동 시 동작'**
  String stocksBuyOrderStub(String name);

  /// No description provided for @stocksFeeUs.
  ///
  /// In ko, this message translates to:
  /// **'미국주식 매매수수료 0.1% · 환전 수수료 별도 적용'**
  String get stocksFeeUs;

  /// No description provided for @stocksFeeKr.
  ///
  /// In ko, this message translates to:
  /// **'국내주식 매매수수료 무료 (2026.6까지) · 이후 KRX 0.015% / NXT 0.014%'**
  String get stocksFeeKr;

  /// No description provided for @stocksOrderDisclaimer.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 Open API 연동 시 실시간 호가·체결가가 반영됩니다.\n시세는 투자 참고용이며 실제 주문은 약관 동의 후 가능합니다.'**
  String get stocksOrderDisclaimer;

  /// No description provided for @stocksEvalAmount.
  ///
  /// In ko, this message translates to:
  /// **'평가금액'**
  String get stocksEvalAmount;

  /// No description provided for @stocksEvalPnl.
  ///
  /// In ko, this message translates to:
  /// **'평가손익'**
  String get stocksEvalPnl;

  /// No description provided for @stocksQuantityHeld.
  ///
  /// In ko, this message translates to:
  /// **'보유수량'**
  String get stocksQuantityHeld;

  /// No description provided for @stocksReturnRate.
  ///
  /// In ko, this message translates to:
  /// **'수익률'**
  String get stocksReturnRate;

  /// No description provided for @stocksDayPnl.
  ///
  /// In ko, this message translates to:
  /// **'일간 손익'**
  String get stocksDayPnl;

  /// No description provided for @stocksAvgPrice.
  ///
  /// In ko, this message translates to:
  /// **'평균단가'**
  String get stocksAvgPrice;

  /// No description provided for @stocksFeesTax.
  ///
  /// In ko, this message translates to:
  /// **'수수료·세금'**
  String get stocksFeesTax;

  /// No description provided for @stocksSellable.
  ///
  /// In ko, this message translates to:
  /// **'매도가능'**
  String get stocksSellable;

  /// No description provided for @stocksMyHoldings.
  ///
  /// In ko, this message translates to:
  /// **'내 보유'**
  String get stocksMyHoldings;

  /// No description provided for @stocksMarket.
  ///
  /// In ko, this message translates to:
  /// **'시장'**
  String get stocksMarket;

  /// No description provided for @stocksInstrumentType.
  ///
  /// In ko, this message translates to:
  /// **'종목 유형'**
  String get stocksInstrumentType;

  /// No description provided for @stocksInstrumentStock.
  ///
  /// In ko, this message translates to:
  /// **'주식'**
  String get stocksInstrumentStock;

  /// No description provided for @stocksCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get stocksCurrency;

  /// No description provided for @stocksMarketCap.
  ///
  /// In ko, this message translates to:
  /// **'시가총액'**
  String get stocksMarketCap;

  /// No description provided for @stocksUpperLimit.
  ///
  /// In ko, this message translates to:
  /// **'상한가'**
  String get stocksUpperLimit;

  /// No description provided for @stocksLowerLimit.
  ///
  /// In ko, this message translates to:
  /// **'하한가'**
  String get stocksLowerLimit;

  /// No description provided for @stocksListingDate.
  ///
  /// In ko, this message translates to:
  /// **'상장일'**
  String get stocksListingDate;

  /// No description provided for @stocksSharesOutstanding.
  ///
  /// In ko, this message translates to:
  /// **'발행주식수'**
  String get stocksSharesOutstanding;

  /// No description provided for @stocksTradingStatus.
  ///
  /// In ko, this message translates to:
  /// **'거래상태'**
  String get stocksTradingStatus;

  /// No description provided for @stocksBasicInfo.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get stocksBasicInfo;

  /// No description provided for @stocksBidVolume.
  ///
  /// In ko, this message translates to:
  /// **'매수 잔량'**
  String get stocksBidVolume;

  /// No description provided for @stocksAskVolume.
  ///
  /// In ko, this message translates to:
  /// **'매도 잔량'**
  String get stocksAskVolume;

  /// No description provided for @stocksGainers.
  ///
  /// In ko, this message translates to:
  /// **'급상승'**
  String get stocksGainers;

  /// No description provided for @stocksLosers.
  ///
  /// In ko, this message translates to:
  /// **'급하락'**
  String get stocksLosers;

  /// No description provided for @stocksVolume.
  ///
  /// In ko, this message translates to:
  /// **'거래량'**
  String get stocksVolume;

  /// No description provided for @stocksOrderbookLoading.
  ///
  /// In ko, this message translates to:
  /// **'호가를 불러오는 중이에요'**
  String get stocksOrderbookLoading;

  /// No description provided for @stocksOrderbookEmpty.
  ///
  /// In ko, this message translates to:
  /// **'호가 정보가 없어요'**
  String get stocksOrderbookEmpty;

  /// No description provided for @stocksTradesLoading.
  ///
  /// In ko, this message translates to:
  /// **'체결 내역을 불러오는 중이에요'**
  String get stocksTradesLoading;

  /// No description provided for @stocksTradesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'체결 내역이 없어요'**
  String get stocksTradesEmpty;

  /// No description provided for @stocksOrderbook.
  ///
  /// In ko, this message translates to:
  /// **'호가'**
  String get stocksOrderbook;

  /// No description provided for @stocksTrades.
  ///
  /// In ko, this message translates to:
  /// **'체결'**
  String get stocksTrades;

  /// No description provided for @stocksTradeTime.
  ///
  /// In ko, this message translates to:
  /// **'체결시각'**
  String get stocksTradeTime;

  /// No description provided for @stocksTradePrice.
  ///
  /// In ko, this message translates to:
  /// **'체결가'**
  String get stocksTradePrice;

  /// No description provided for @stocksTradeVolume.
  ///
  /// In ko, this message translates to:
  /// **'체결량'**
  String get stocksTradeVolume;

  /// No description provided for @stocksDailyPrices.
  ///
  /// In ko, this message translates to:
  /// **'일별 시세'**
  String get stocksDailyPrices;

  /// No description provided for @stocksDailyPricesLoading.
  ///
  /// In ko, this message translates to:
  /// **'일별 시세를 불러오는 중이에요'**
  String get stocksDailyPricesLoading;

  /// No description provided for @stocksDailyPricesEmpty.
  ///
  /// In ko, this message translates to:
  /// **'일별 시세가 없어요'**
  String get stocksDailyPricesEmpty;

  /// No description provided for @stocksDate.
  ///
  /// In ko, this message translates to:
  /// **'일자'**
  String get stocksDate;

  /// No description provided for @stocksClosePrice.
  ///
  /// In ko, this message translates to:
  /// **'종가'**
  String get stocksClosePrice;

  /// No description provided for @stocksChangeRate.
  ///
  /// In ko, this message translates to:
  /// **'등락률'**
  String get stocksChangeRate;

  /// No description provided for @stocksSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'종목명·심볼로 검색하세요 (국내 + 미국·중국·일본·홍콩·베트남)'**
  String get stocksSearchHint;

  /// No description provided for @stocksPriceUnavailable.
  ///
  /// In ko, this message translates to:
  /// **'토스 시세 미지원 종목이에요 (국내·미국만 제공)'**
  String get stocksPriceUnavailable;

  /// No description provided for @stocksRankingLoading.
  ///
  /// In ko, this message translates to:
  /// **'랭킹을 불러오는 중…'**
  String get stocksRankingLoading;

  /// No description provided for @stocksRankingEmpty.
  ///
  /// In ko, this message translates to:
  /// **'집계된 랭킹이 없어요'**
  String get stocksRankingEmpty;

  /// No description provided for @stocksWatchDefaultGroupName.
  ///
  /// In ko, this message translates to:
  /// **'관심'**
  String get stocksWatchDefaultGroupName;

  /// No description provided for @stocksWatchGroupAdd.
  ///
  /// In ko, this message translates to:
  /// **'그룹 추가'**
  String get stocksWatchGroupAdd;

  /// No description provided for @stocksWatchGroupRename.
  ///
  /// In ko, this message translates to:
  /// **'그룹 이름 변경'**
  String get stocksWatchGroupRename;

  /// No description provided for @stocksWatchGroupDelete.
  ///
  /// In ko, this message translates to:
  /// **'그룹 삭제'**
  String get stocksWatchGroupDelete;

  /// No description provided for @stocksWatchGroupNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'그룹 이름'**
  String get stocksWatchGroupNamePlaceholder;

  /// No description provided for @stocksWatchGroupDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'그룹과 담긴 종목이 함께 삭제됩니다. 계속할까요?'**
  String get stocksWatchGroupDeleteConfirm;

  /// No description provided for @stocksWatchGroupSaveFail.
  ///
  /// In ko, this message translates to:
  /// **'관심목록 그룹 저장에 실패했어요'**
  String get stocksWatchGroupSaveFail;

  /// No description provided for @stocksWatchAddFail.
  ///
  /// In ko, this message translates to:
  /// **'관심 등록에 실패했어요'**
  String get stocksWatchAddFail;

  /// No description provided for @stocksMarketToggleKr.
  ///
  /// In ko, this message translates to:
  /// **'국내'**
  String get stocksMarketToggleKr;

  /// No description provided for @stocksMarketToggleUs.
  ///
  /// In ko, this message translates to:
  /// **'미국'**
  String get stocksMarketToggleUs;

  /// No description provided for @todoAdd.
  ///
  /// In ko, this message translates to:
  /// **'할 일 추가'**
  String get todoAdd;

  /// No description provided for @todoEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'할 일 수정'**
  String get todoEditTitle;

  /// No description provided for @todoDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'할 일 삭제'**
  String get todoDeleteTitle;

  /// No description provided for @todoDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{title}\" 을(를) 삭제할까요?'**
  String todoDeleteConfirm(String title);

  /// No description provided for @todoDetail.
  ///
  /// In ko, this message translates to:
  /// **'자세히'**
  String get todoDetail;

  /// No description provided for @todoCompletionRate.
  ///
  /// In ko, this message translates to:
  /// **'완료율'**
  String get todoCompletionRate;

  /// No description provided for @todoQuickAddPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 입력하고 Enter'**
  String get todoQuickAddPlaceholder;

  /// No description provided for @todoTitlePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 적어주세요'**
  String get todoTitlePlaceholder;

  /// No description provided for @todoTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요'**
  String get todoTitleRequired;

  /// No description provided for @todoDueDate.
  ///
  /// In ko, this message translates to:
  /// **'마감일'**
  String get todoDueDate;

  /// No description provided for @todoUnset.
  ///
  /// In ko, this message translates to:
  /// **'미설정'**
  String get todoUnset;

  /// No description provided for @todoTag.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get todoTag;

  /// No description provided for @todoTagSelect.
  ///
  /// In ko, this message translates to:
  /// **'태그 선택'**
  String get todoTagSelect;

  /// No description provided for @todoPriorityLabel.
  ///
  /// In ko, this message translates to:
  /// **'우선순위'**
  String get todoPriorityLabel;

  /// No description provided for @todoPriorityImportant.
  ///
  /// In ko, this message translates to:
  /// **'중요'**
  String get todoPriorityImportant;

  /// No description provided for @todoPriorityRelaxed.
  ///
  /// In ko, this message translates to:
  /// **'여유'**
  String get todoPriorityRelaxed;

  /// No description provided for @todoContentLabel.
  ///
  /// In ko, this message translates to:
  /// **'상세 내용 (선택)'**
  String get todoContentLabel;

  /// No description provided for @todoContentPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: # 제목 / **굵게** / - 항목 / - [ ] 체크'**
  String get todoContentPlaceholder;

  /// No description provided for @todoEditMode.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get todoEditMode;

  /// No description provided for @todoPreview.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get todoPreview;

  /// No description provided for @todoNoContent.
  ///
  /// In ko, this message translates to:
  /// **'내용 없음'**
  String get todoNoContent;

  /// No description provided for @todoEmptyToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘 할 일이 없어요'**
  String get todoEmptyToday;

  /// No description provided for @todoEmptyWeek.
  ///
  /// In ko, this message translates to:
  /// **'이번 주는 한가해요'**
  String get todoEmptyWeek;

  /// No description provided for @todoEmptyDone.
  ///
  /// In ko, this message translates to:
  /// **'아직 완료된 일이 없어요'**
  String get todoEmptyDone;

  /// No description provided for @todoEmptyAll.
  ///
  /// In ko, this message translates to:
  /// **'할 일이 없어요'**
  String get todoEmptyAll;

  /// No description provided for @todoEmptyDoneHint.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 완료하면 여기에 모입니다.'**
  String get todoEmptyDoneHint;

  /// No description provided for @todoEmptyAddHint.
  ///
  /// In ko, this message translates to:
  /// **'위 입력칸으로 빠르게 추가해보세요.'**
  String get todoEmptyAddHint;

  /// No description provided for @todoNewProject.
  ///
  /// In ko, this message translates to:
  /// **'새 프로젝트'**
  String get todoNewProject;

  /// No description provided for @todoProjectNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 이름'**
  String get todoProjectNamePlaceholder;

  /// No description provided for @todoDescOptional.
  ///
  /// In ko, this message translates to:
  /// **'설명 (선택)'**
  String get todoDescOptional;

  /// No description provided for @todoAdding.
  ///
  /// In ko, this message translates to:
  /// **'추가 중...'**
  String get todoAdding;

  /// No description provided for @todoAddProject.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 추가'**
  String get todoAddProject;

  /// No description provided for @todoRegisteredProjects.
  ///
  /// In ko, this message translates to:
  /// **'등록된 프로젝트'**
  String get todoRegisteredProjects;

  /// No description provided for @todoNoProjects.
  ///
  /// In ko, this message translates to:
  /// **'등록된 프로젝트가 없습니다'**
  String get todoNoProjects;

  /// No description provided for @todoDeleteProjectTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 삭제'**
  String get todoDeleteProjectTitle;

  /// No description provided for @todoDeleteProjectConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 프로젝트를 삭제하시겠어요? 연결된 할 일은 프로젝트 미지정으로 변경됩니다.'**
  String todoDeleteProjectConfirm(String name);

  /// No description provided for @todoNewTag.
  ///
  /// In ko, this message translates to:
  /// **'새 태그'**
  String get todoNewTag;

  /// No description provided for @todoTagNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'태그 이름'**
  String get todoTagNamePlaceholder;

  /// No description provided for @todoRegisteredTags.
  ///
  /// In ko, this message translates to:
  /// **'등록된 태그'**
  String get todoRegisteredTags;

  /// No description provided for @todoNoTags.
  ///
  /// In ko, this message translates to:
  /// **'등록된 태그가 없습니다'**
  String get todoNoTags;

  /// No description provided for @todoDeleteTagTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 삭제'**
  String get todoDeleteTagTitle;

  /// No description provided for @todoDeleteTagConfirm.
  ///
  /// In ko, this message translates to:
  /// **'\"{name}\" 태그를 삭제하시겠어요?'**
  String todoDeleteTagConfirm(String name);

  /// No description provided for @todoActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패'**
  String get todoActionFailed;

  /// No description provided for @todoAddFailed.
  ///
  /// In ko, this message translates to:
  /// **'추가 실패'**
  String get todoAddFailed;

  /// No description provided for @todoDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패'**
  String get todoDeleteFailed;

  /// No description provided for @todoUpdateFailed.
  ///
  /// In ko, this message translates to:
  /// **'수정 실패'**
  String get todoUpdateFailed;

  /// No description provided for @todoStatusChangeFailed.
  ///
  /// In ko, this message translates to:
  /// **'상태 변경 실패'**
  String get todoStatusChangeFailed;

  /// No description provided for @todoMoveFailed.
  ///
  /// In ko, this message translates to:
  /// **'이동 실패'**
  String get todoMoveFailed;

  /// No description provided for @todoLoadError.
  ///
  /// In ko, this message translates to:
  /// **'할 일 로드 실패'**
  String get todoLoadError;

  /// No description provided for @todoProjectLoadError.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 로드 실패'**
  String get todoProjectLoadError;

  /// No description provided for @todoTagLoadError.
  ///
  /// In ko, this message translates to:
  /// **'태그 로드 실패'**
  String get todoTagLoadError;

  /// No description provided for @todoSubtaskLoadError.
  ///
  /// In ko, this message translates to:
  /// **'하위 작업 로드 실패'**
  String get todoSubtaskLoadError;

  /// No description provided for @subManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독 관리'**
  String get subManageTitle;

  /// No description provided for @subUsingPro.
  ///
  /// In ko, this message translates to:
  /// **'Porest Pro 이용 중'**
  String get subUsingPro;

  /// No description provided for @subUsingFree.
  ///
  /// In ko, this message translates to:
  /// **'Free 플랜 이용 중'**
  String get subUsingFree;

  /// No description provided for @subNextBilling.
  ///
  /// In ko, this message translates to:
  /// **'다음 결제 {date} · {amount}'**
  String subNextBilling(String date, String amount);

  /// No description provided for @subFreeLockedDesc.
  ///
  /// In ko, this message translates to:
  /// **'증권·가져오기 등 Pro 기능이 잠겨 있어요'**
  String get subFreeLockedDesc;

  /// No description provided for @subSpotlightTitle.
  ///
  /// In ko, this message translates to:
  /// **'증권 투자는 Pro 전용이에요'**
  String get subSpotlightTitle;

  /// No description provided for @subSpotlightDesc.
  ///
  /// In ko, this message translates to:
  /// **'실시간 시세·호가, 국내외 종목 검색, 관심종목, 보유 손익까지 — Pro를 구독하면 증권 탭이 바로 열려요.'**
  String get subSpotlightDesc;

  /// No description provided for @subCycleMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월간'**
  String get subCycleMonthly;

  /// No description provided for @subCycleYearlyOff.
  ///
  /// In ko, this message translates to:
  /// **'연간 {pct}%↓'**
  String subCycleYearlyOff(int pct);

  /// No description provided for @subUnitMonth.
  ///
  /// In ko, this message translates to:
  /// **'월'**
  String get subUnitMonth;

  /// No description provided for @subUnitYear.
  ///
  /// In ko, this message translates to:
  /// **'년'**
  String get subUnitYear;

  /// No description provided for @subYearlyPerMonth.
  ///
  /// In ko, this message translates to:
  /// **'월 {amount} 꼴 · {pct}% 절약'**
  String subYearlyPerMonth(String amount, int pct);

  /// No description provided for @subMonthlyBilling.
  ///
  /// In ko, this message translates to:
  /// **'월 단위 결제'**
  String get subMonthlyBilling;

  /// No description provided for @subFeatureCompare.
  ///
  /// In ko, this message translates to:
  /// **'기능 비교'**
  String get subFeatureCompare;

  /// No description provided for @subCurrentPlan.
  ///
  /// In ko, this message translates to:
  /// **'현재 플랜'**
  String get subCurrentPlan;

  /// No description provided for @subFreeCaption.
  ///
  /// In ko, this message translates to:
  /// **'기본 가계부 기능'**
  String get subFreeCaption;

  /// No description provided for @subFeatureColumn.
  ///
  /// In ko, this message translates to:
  /// **'기능'**
  String get subFeatureColumn;

  /// No description provided for @subFeatLedger.
  ///
  /// In ko, this message translates to:
  /// **'가계부 · 자산 관리'**
  String get subFeatLedger;

  /// No description provided for @subFeatBudget.
  ///
  /// In ko, this message translates to:
  /// **'예산 · 저축 목표 · 캘린더'**
  String get subFeatBudget;

  /// No description provided for @subFeatMonthlyTx.
  ///
  /// In ko, this message translates to:
  /// **'월 거래 기록'**
  String get subFeatMonthlyTx;

  /// No description provided for @subFeatTxLimit.
  ///
  /// In ko, this message translates to:
  /// **'100건'**
  String get subFeatTxLimit;

  /// No description provided for @subFeatUnlimited.
  ///
  /// In ko, this message translates to:
  /// **'무제한'**
  String get subFeatUnlimited;

  /// No description provided for @subFeatSecurities.
  ///
  /// In ko, this message translates to:
  /// **'증권 — 실시간 시세 · 종목 검색 · 관심종목'**
  String get subFeatSecurities;

  /// No description provided for @subFeatImportExport.
  ///
  /// In ko, this message translates to:
  /// **'CSV · Excel 가져오기 / 내보내기'**
  String get subFeatImportExport;

  /// No description provided for @subFeatCalendarShare.
  ///
  /// In ko, this message translates to:
  /// **'다중 캘린더 공유'**
  String get subFeatCalendarShare;

  /// No description provided for @subFeatCardRec.
  ///
  /// In ko, this message translates to:
  /// **'카드 혜택 추천'**
  String get subFeatCardRec;

  /// No description provided for @subStarted.
  ///
  /// In ko, this message translates to:
  /// **'Porest Pro 구독이 시작되었어요'**
  String get subStarted;

  /// No description provided for @subFailed.
  ///
  /// In ko, this message translates to:
  /// **'구독에 실패했어요'**
  String get subFailed;

  /// No description provided for @subCancelConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독을 해지할까요?'**
  String get subCancelConfirmTitle;

  /// No description provided for @subCancelConfirmMsg.
  ///
  /// In ko, this message translates to:
  /// **'해지하면 {date}부터 Free 플랜으로 전환되고 증권 탭이 잠겨요. 그 전까지는 Pro 기능을 계속 쓸 수 있어요.'**
  String subCancelConfirmMsg(String date);

  /// No description provided for @subCancel.
  ///
  /// In ko, this message translates to:
  /// **'구독 해지'**
  String get subCancel;

  /// No description provided for @subKeep.
  ///
  /// In ko, this message translates to:
  /// **'유지하기'**
  String get subKeep;

  /// No description provided for @subCanceled.
  ///
  /// In ko, this message translates to:
  /// **'구독을 해지했어요'**
  String get subCanceled;

  /// No description provided for @subCancelFailed.
  ///
  /// In ko, this message translates to:
  /// **'해지에 실패했어요'**
  String get subCancelFailed;

  /// No description provided for @subNextBillingDate.
  ///
  /// In ko, this message translates to:
  /// **'다음 결제일'**
  String get subNextBillingDate;

  /// No description provided for @subProcessing.
  ///
  /// In ko, this message translates to:
  /// **'처리 중…'**
  String get subProcessing;

  /// No description provided for @subStartPro.
  ///
  /// In ko, this message translates to:
  /// **'Pro 시작하기'**
  String get subStartPro;

  /// No description provided for @subTossSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'증권 데이터 연동'**
  String get subTossSectionTitle;

  /// No description provided for @subTossConnectTitle.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 연결'**
  String get subTossConnectTitle;

  /// No description provided for @subTossConnectDesc.
  ///
  /// In ko, this message translates to:
  /// **'본인 API 키를 등록하면 보유 주식·시세를 자동으로 가져와요'**
  String get subTossConnectDesc;

  /// No description provided for @subConnected.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get subConnected;

  /// No description provided for @subTossLastVerified.
  ///
  /// In ko, this message translates to:
  /// **'마지막 검증 · {date}'**
  String subTossLastVerified(String date);

  /// No description provided for @subTossCollecting.
  ///
  /// In ko, this message translates to:
  /// **'보유 주식·시세 자동 수집 중'**
  String get subTossCollecting;

  /// No description provided for @subTossKeyConnected.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 API 키 연결됨'**
  String get subTossKeyConnected;

  /// No description provided for @subTossIdPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 개발자센터 발급 Client ID'**
  String get subTossIdPlaceholder;

  /// No description provided for @subConnecting.
  ///
  /// In ko, this message translates to:
  /// **'연결 중…'**
  String get subConnecting;

  /// No description provided for @subConnect.
  ///
  /// In ko, this message translates to:
  /// **'연결하기'**
  String get subConnect;

  /// No description provided for @subTossConnected.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 계정을 연결했어요'**
  String get subTossConnected;

  /// No description provided for @subTossInvalidCred.
  ///
  /// In ko, this message translates to:
  /// **'인증정보가 올바르지 않아요'**
  String get subTossInvalidCred;

  /// No description provided for @subTossDisconnected.
  ///
  /// In ko, this message translates to:
  /// **'토스증권 연결을 해제했어요'**
  String get subTossDisconnected;

  /// No description provided for @subDisconnectFailed.
  ///
  /// In ko, this message translates to:
  /// **'해제에 실패했어요'**
  String get subDisconnectFailed;

  /// No description provided for @subTossKeyNotice.
  ///
  /// In ko, this message translates to:
  /// **'키는 서버에 암호화되어 저장되며 본인만 사용합니다. 발급은 토스증권 개발자센터에서.'**
  String get subTossKeyNotice;

  /// No description provided for @memoNew.
  ///
  /// In ko, this message translates to:
  /// **'새 메모'**
  String get memoNew;

  /// No description provided for @memoEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 수정'**
  String get memoEditTitle;

  /// No description provided for @memoAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get memoAdd;

  /// No description provided for @memoLoadError.
  ///
  /// In ko, this message translates to:
  /// **'메모 로드 실패'**
  String get memoLoadError;

  /// No description provided for @memoTagAll.
  ///
  /// In ko, this message translates to:
  /// **'전체 {count}'**
  String memoTagAll(int count);

  /// No description provided for @memoSectionPinned.
  ///
  /// In ko, this message translates to:
  /// **'고정 · {count}'**
  String memoSectionPinned(int count);

  /// No description provided for @memoSectionAll.
  ///
  /// In ko, this message translates to:
  /// **'모든 메모 · {count}'**
  String memoSectionAll(int count);

  /// No description provided for @memoActionFailed.
  ///
  /// In ko, this message translates to:
  /// **'실패: {message}'**
  String memoActionFailed(String message);

  /// No description provided for @memoEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'생각이 떠오를 때, 새 메모를 만들어보세요.'**
  String get memoEmptyDesc;

  /// No description provided for @memoSearchEmptyDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 검색어를 입력해보세요.'**
  String get memoSearchEmptyDesc;

  /// No description provided for @memoUntitled.
  ///
  /// In ko, this message translates to:
  /// **'(제목 없음)'**
  String get memoUntitled;

  /// No description provided for @memoDeleteTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 삭제'**
  String get memoDeleteTitle;

  /// No description provided for @memoDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 메모를 삭제할까요?'**
  String get memoDeleteConfirm;

  /// No description provided for @memoDeleteFailed.
  ///
  /// In ko, this message translates to:
  /// **'삭제 실패: {message}'**
  String memoDeleteFailed(String message);

  /// No description provided for @memoFieldTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get memoFieldTitle;

  /// No description provided for @memoTitleRequired.
  ///
  /// In ko, this message translates to:
  /// **'제목을 입력해주세요'**
  String get memoTitleRequired;

  /// No description provided for @memoFieldContent.
  ///
  /// In ko, this message translates to:
  /// **'내용'**
  String get memoFieldContent;

  /// No description provided for @memoContentPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'여기에 메모를 작성해주세요'**
  String get memoContentPlaceholder;

  /// No description provided for @memoFieldTag.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get memoFieldTag;

  /// No description provided for @memoPinToTop.
  ///
  /// In ko, this message translates to:
  /// **'상단에 고정'**
  String get memoPinToTop;

  /// No description provided for @memoFieldColor.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get memoFieldColor;

  /// No description provided for @dateToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get dateToday;

  /// No description provided for @dateTomorrow.
  ///
  /// In ko, this message translates to:
  /// **'내일'**
  String get dateTomorrow;

  /// No description provided for @dateYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get dateYesterday;

  /// No description provided for @dateInDays.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 후'**
  String dateInDays(int n);

  /// No description provided for @dateDaysAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 전'**
  String dateDaysAgo(int n);

  /// No description provided for @dateJustNow.
  ///
  /// In ko, this message translates to:
  /// **'방금'**
  String get dateJustNow;

  /// No description provided for @dateMinutesAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}분 전'**
  String dateMinutesAgo(int n);

  /// No description provided for @dateHoursAgo.
  ///
  /// In ko, this message translates to:
  /// **'{n}시간 전'**
  String dateHoursAgo(int n);

  /// No description provided for @todoNoDue.
  ///
  /// In ko, this message translates to:
  /// **'마감일 없음'**
  String get todoNoDue;

  /// No description provided for @todoGroupLabel.
  ///
  /// In ko, this message translates to:
  /// **'{label} · {count}건'**
  String todoGroupLabel(String label, int count);

  /// No description provided for @dayN.
  ///
  /// In ko, this message translates to:
  /// **'{d}일'**
  String dayN(int d);

  /// No description provided for @weekN.
  ///
  /// In ko, this message translates to:
  /// **'{n}주'**
  String weekN(int n);

  /// No description provided for @countUnit.
  ///
  /// In ko, this message translates to:
  /// **'건'**
  String get countUnit;

  /// No description provided for @dayUnit.
  ///
  /// In ko, this message translates to:
  /// **'일'**
  String get dayUnit;

  /// No description provided for @constHeroTodayTarget.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 목표 별자리'**
  String get constHeroTodayTarget;

  /// No description provided for @constHeroCollectedBang.
  ///
  /// In ko, this message translates to:
  /// **'{name} 수집!'**
  String constHeroCollectedBang(String name);

  /// No description provided for @constHeroStarlightCount.
  ///
  /// In ko, this message translates to:
  /// **'{lit}/{goal} 별빛'**
  String constHeroStarlightCount(int lit, int goal);

  /// No description provided for @constHeroCaptionDone.
  ///
  /// In ko, this message translates to:
  /// **'도감에 새겨졌어요 · 완료할수록 더 반짝여요'**
  String get constHeroCaptionDone;

  /// No description provided for @constHeroCaptionProgress.
  ///
  /// In ko, this message translates to:
  /// **'오늘 {count}건 완료'**
  String constHeroCaptionProgress(int count);

  /// No description provided for @constHeroCaptionMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모 별빛 +{count}'**
  String constHeroCaptionMemo(int count);

  /// No description provided for @constHeroCaptionRemain.
  ///
  /// In ko, this message translates to:
  /// **'{count}별 남음'**
  String constHeroCaptionRemain(int count);

  /// No description provided for @constHeroCaptionEmpty.
  ///
  /// In ko, this message translates to:
  /// **'할 일을 완료하면 별이 켜져요'**
  String get constHeroCaptionEmpty;

  /// No description provided for @constHeroStreak.
  ///
  /// In ko, this message translates to:
  /// **'연속 관측 {count}일'**
  String constHeroStreak(int count);

  /// No description provided for @constHeroGuardInfo.
  ///
  /// In ko, this message translates to:
  /// **'보호 {count} · 중요 +3 · 보통 +2 · 여유 +1'**
  String constHeroGuardInfo(int count);

  /// No description provided for @constMySkyTitle.
  ///
  /// In ko, this message translates to:
  /// **'나의 밤하늘'**
  String get constMySkyTitle;

  /// No description provided for @constMySkyTotal.
  ///
  /// In ko, this message translates to:
  /// **'누적 {count}개'**
  String constMySkyTotal(int count);

  /// No description provided for @constMySkySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 2주 · 흐린 밤도 기록에 남아요'**
  String get constMySkySubtitle;

  /// No description provided for @constCollectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'별자리 도감'**
  String get constCollectionTitle;

  /// No description provided for @constCollectionProgress.
  ///
  /// In ko, this message translates to:
  /// **'{collected}/{total} 수집'**
  String constCollectionProgress(int collected, int total);

  /// No description provided for @constCollectionSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'별 개수만큼 별빛을 모으면 수집돼요'**
  String get constCollectionSubtitle;

  /// No description provided for @constCollectionTodayBadge.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 목표'**
  String get constCollectionTodayBadge;

  /// No description provided for @constCollectionStarCount.
  ///
  /// In ko, this message translates to:
  /// **'별 {count}개'**
  String constCollectionStarCount(int count);

  /// No description provided for @constCollectionTimes.
  ///
  /// In ko, this message translates to:
  /// **'{count}회'**
  String constCollectionTimes(int count);

  /// No description provided for @constCollectionNotCollected.
  ///
  /// In ko, this message translates to:
  /// **'미수집'**
  String get constCollectionNotCollected;

  /// No description provided for @constDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'별자리 도감'**
  String get constDetailTitle;

  /// No description provided for @constDetailNotMet.
  ///
  /// In ko, this message translates to:
  /// **'아직 만나지 못한 별자리예요'**
  String get constDetailNotMet;

  /// No description provided for @constDetailCollectedTimes.
  ///
  /// In ko, this message translates to:
  /// **'지금까지 {count}번 수집했어요'**
  String constDetailCollectedTimes(int count);

  /// No description provided for @constDetailHint.
  ///
  /// In ko, this message translates to:
  /// **'하루에 별빛 {count}개를 모으면 수집돼요 · 매일 새 목표 별자리가 떠요'**
  String constDetailHint(int count);

  /// No description provided for @todoDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'할 일 상세'**
  String get todoDetailTitle;

  /// No description provided for @todoDetailStatus.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get todoDetailStatus;

  /// No description provided for @todoStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get todoStatusPending;

  /// No description provided for @todoDetailCompletedAt.
  ///
  /// In ko, this message translates to:
  /// **'완료 일시'**
  String get todoDetailCompletedAt;

  /// No description provided for @todoDetailContent.
  ///
  /// In ko, this message translates to:
  /// **'상세 내용'**
  String get todoDetailContent;

  /// No description provided for @memoDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 상세'**
  String get memoDetailTitle;

  /// No description provided for @memoDetailPinned.
  ///
  /// In ko, this message translates to:
  /// **'고정됨'**
  String get memoDetailPinned;

  /// No description provided for @memoDetailNoContent.
  ///
  /// In ko, this message translates to:
  /// **'내용 없음'**
  String get memoDetailNoContent;

  /// No description provided for @calEventDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'일정 상세'**
  String get calEventDetailTitle;

  /// No description provided for @calDetailNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get calDetailNone;

  /// No description provided for @exportTab.
  ///
  /// In ko, this message translates to:
  /// **'내보내기'**
  String get exportTab;

  /// No description provided for @importTab.
  ///
  /// In ko, this message translates to:
  /// **'가져오기'**
  String get importTab;

  /// No description provided for @importSourceTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 앱에서 가져오나요?'**
  String get importSourceTitle;

  /// No description provided for @importSourceDesc.
  ///
  /// In ko, this message translates to:
  /// **'기존에 쓰던 가계부를 고르면 열 구조를 자동으로 맞춰드려요'**
  String get importSourceDesc;

  /// No description provided for @importSourcePorest.
  ///
  /// In ko, this message translates to:
  /// **'Porest 백업'**
  String get importSourcePorest;

  /// No description provided for @importSourcePorestDesc.
  ///
  /// In ko, this message translates to:
  /// **'내보내기 파일 다시 가져오기'**
  String get importSourcePorestDesc;

  /// No description provided for @importSourceEasybudget.
  ///
  /// In ko, this message translates to:
  /// **'편한가계부·머니매니저'**
  String get importSourceEasybudget;

  /// No description provided for @importSourceEasybudgetDesc.
  ///
  /// In ko, this message translates to:
  /// **'Excel 백업'**
  String get importSourceEasybudgetDesc;

  /// No description provided for @importSourceBanksalad.
  ///
  /// In ko, this message translates to:
  /// **'뱅크샐러드'**
  String get importSourceBanksalad;

  /// No description provided for @importSourceBanksaladDesc.
  ///
  /// In ko, this message translates to:
  /// **'가계부 내역'**
  String get importSourceBanksaladDesc;

  /// No description provided for @importSourceToss.
  ///
  /// In ko, this message translates to:
  /// **'토스'**
  String get importSourceToss;

  /// No description provided for @importSourceTossDesc.
  ///
  /// In ko, this message translates to:
  /// **'거래내역'**
  String get importSourceTossDesc;

  /// No description provided for @importSourceCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 매핑'**
  String get importSourceCustom;

  /// No description provided for @importSourceCustomDesc.
  ///
  /// In ko, this message translates to:
  /// **'CSV·Excel 직접 연결'**
  String get importSourceCustomDesc;

  /// No description provided for @importUploadTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 업로드'**
  String get importUploadTitle;

  /// No description provided for @importUploadDesc.
  ///
  /// In ko, this message translates to:
  /// **'CSV 또는 Excel(.xlsx, .xls) 파일을 올려주세요. 최대 10MB.'**
  String get importUploadDesc;

  /// No description provided for @importDropTitle.
  ///
  /// In ko, this message translates to:
  /// **'파일 선택'**
  String get importDropTitle;

  /// No description provided for @importDropHint.
  ///
  /// In ko, this message translates to:
  /// **'.csv · .xlsx · .xls 지원'**
  String get importDropHint;

  /// No description provided for @importAnalyzing.
  ///
  /// In ko, this message translates to:
  /// **'파일 분석 중…'**
  String get importAnalyzing;

  /// No description provided for @importNotice.
  ///
  /// In ko, this message translates to:
  /// **'가져온 데이터는 기존 거래에 추가되며 덮어쓰지 않아요. 미리보기에서 중복·오류를 확인할 수 있어요.'**
  String get importNotice;

  /// No description provided for @importFileTitle.
  ///
  /// In ko, this message translates to:
  /// **'가져올 파일'**
  String get importFileTitle;

  /// No description provided for @importRowsDetected.
  ///
  /// In ko, this message translates to:
  /// **'{total}개 행 · 유효 {valid}건'**
  String importRowsDetected(int total, int valid);

  /// No description provided for @importChange.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get importChange;

  /// No description provided for @importMapTitle.
  ///
  /// In ko, this message translates to:
  /// **'열 매핑'**
  String get importMapTitle;

  /// No description provided for @importMapDesc.
  ///
  /// In ko, this message translates to:
  /// **'파일의 열을 가계부 항목에 연결하세요. 자동 감지값을 바꿀 수 있어요.'**
  String get importMapDesc;

  /// No description provided for @importNotMapped.
  ///
  /// In ko, this message translates to:
  /// **'가져오지 않음'**
  String get importNotMapped;

  /// No description provided for @importFieldSubcategory.
  ///
  /// In ko, this message translates to:
  /// **'소분류'**
  String get importFieldSubcategory;

  /// No description provided for @importFieldTime.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get importFieldTime;

  /// No description provided for @importFieldMerchant.
  ///
  /// In ko, this message translates to:
  /// **'거래처'**
  String get importFieldMerchant;

  /// No description provided for @importFieldPaymentMethod.
  ///
  /// In ko, this message translates to:
  /// **'결제수단'**
  String get importFieldPaymentMethod;

  /// No description provided for @importBlockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'{names} 카테고리에 거래가 직접 등록돼 있어 하위 분류를 만들 수 없어요'**
  String importBlockedTitle(String names);

  /// No description provided for @importBlockedDesc.
  ///
  /// In ko, this message translates to:
  /// **'해당 대분류를 쓰는 행은 저장에 실패해요. 그 카테고리의 거래를 하위로 옮기거나 파일의 분류를 바꿔주세요'**
  String get importBlockedDesc;

  /// No description provided for @categoryMoveTxAction.
  ///
  /// In ko, this message translates to:
  /// **'옮기기'**
  String get categoryMoveTxAction;

  /// No description provided for @categoryMoveTxTitle.
  ///
  /// In ko, this message translates to:
  /// **'거래 옮기기'**
  String get categoryMoveTxTitle;

  /// No description provided for @categoryMoveTxEntry.
  ///
  /// In ko, this message translates to:
  /// **'거래 옮기기'**
  String get categoryMoveTxEntry;

  /// No description provided for @categoryMoveTxEntryDesc.
  ///
  /// In ko, this message translates to:
  /// **'거래가 달린 카테고리는 하위 분류를 만들 수 없어요. 거래를 옮기면 만들 수 있어요'**
  String get categoryMoveTxEntryDesc;

  /// No description provided for @categoryMoveTxDesc.
  ///
  /// In ko, this message translates to:
  /// **'{name} 에 달린 거래·반복거래·분할을 모두 옮겨요'**
  String categoryMoveTxDesc(String name);

  /// No description provided for @categoryMoveTxModeNew.
  ///
  /// In ko, this message translates to:
  /// **'새 하위 만들기'**
  String get categoryMoveTxModeNew;

  /// No description provided for @categoryMoveTxModeExisting.
  ///
  /// In ko, this message translates to:
  /// **'기존 카테고리로'**
  String get categoryMoveTxModeExisting;

  /// No description provided for @categoryMoveTxChildName.
  ///
  /// In ko, this message translates to:
  /// **'만들 하위 이름'**
  String get categoryMoveTxChildName;

  /// No description provided for @categoryMoveTxChildPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: 강의'**
  String get categoryMoveTxChildPlaceholder;

  /// No description provided for @categoryMoveTxNewHint.
  ///
  /// In ko, this message translates to:
  /// **'{name} 아래에 만들고 거래를 모두 그리로 옮겨요. 그러면 다른 하위도 만들 수 있어요'**
  String categoryMoveTxNewHint(String name);

  /// No description provided for @categoryMoveTxTarget.
  ///
  /// In ko, this message translates to:
  /// **'옮길 카테고리'**
  String get categoryMoveTxTarget;

  /// No description provided for @categoryMoveTxTargetPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'카테고리 선택'**
  String get categoryMoveTxTargetPlaceholder;

  /// No description provided for @categoryMoveTxHint.
  ///
  /// In ko, this message translates to:
  /// **'같은 유형의 말단 카테고리만 고를 수 있어요'**
  String get categoryMoveTxHint;

  /// No description provided for @categoryMoveTxNoTarget.
  ///
  /// In ko, this message translates to:
  /// **'옮길 수 있는 카테고리가 없어요. 먼저 하나 만들어주세요'**
  String get categoryMoveTxNoTarget;

  /// No description provided for @categoryMoveTxDone.
  ///
  /// In ko, this message translates to:
  /// **'{count}건을 옮겼어요'**
  String categoryMoveTxDone(int count);

  /// No description provided for @importFieldDate.
  ///
  /// In ko, this message translates to:
  /// **'날짜'**
  String get importFieldDate;

  /// No description provided for @importFieldType.
  ///
  /// In ko, this message translates to:
  /// **'수입/지출'**
  String get importFieldType;

  /// No description provided for @importFieldAmount.
  ///
  /// In ko, this message translates to:
  /// **'금액'**
  String get importFieldAmount;

  /// No description provided for @importFieldCategory.
  ///
  /// In ko, this message translates to:
  /// **'카테고리'**
  String get importFieldCategory;

  /// No description provided for @importFieldAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산·결제수단'**
  String get importFieldAsset;

  /// No description provided for @importFieldMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get importFieldMemo;

  /// No description provided for @importPreviewDesc.
  ///
  /// In ko, this message translates to:
  /// **'중복 의심 {dup}건'**
  String importPreviewDesc(int dup);

  /// No description provided for @importIncome.
  ///
  /// In ko, this message translates to:
  /// **'수입'**
  String get importIncome;

  /// No description provided for @importExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get importExpense;

  /// No description provided for @importDupBadge.
  ///
  /// In ko, this message translates to:
  /// **'중복?'**
  String get importDupBadge;

  /// No description provided for @importOptionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'가져오기 옵션'**
  String get importOptionsTitle;

  /// No description provided for @importOptDupSkip.
  ///
  /// In ko, this message translates to:
  /// **'중복 거래 건너뛰기'**
  String get importOptDupSkip;

  /// No description provided for @importOptDupSkipDesc.
  ///
  /// In ko, this message translates to:
  /// **'날짜·금액·내용이 같은 {dup}건을 제외해요'**
  String importOptDupSkipDesc(int dup);

  /// No description provided for @importOptAutoCat.
  ///
  /// In ko, this message translates to:
  /// **'새 카테고리 자동 생성'**
  String get importOptAutoCat;

  /// No description provided for @importOptAutoCatDesc.
  ///
  /// In ko, this message translates to:
  /// **'없는 카테고리는 자동으로 만들어요'**
  String get importOptAutoCatDesc;

  /// No description provided for @importPrev.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get importPrev;

  /// No description provided for @importDoImport.
  ///
  /// In ko, this message translates to:
  /// **'{count}건 가져오기'**
  String importDoImport(int count);

  /// No description provided for @importDoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'가져오기 완료'**
  String get importDoneTitle;

  /// No description provided for @importDoneCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}건을 가져왔어요'**
  String importDoneCount(int count);

  /// No description provided for @importDoneDetail.
  ///
  /// In ko, this message translates to:
  /// **'건너뜀 {skipped} · 실패 {failed}'**
  String importDoneDetail(int skipped, int failed);

  /// No description provided for @importAnother.
  ///
  /// In ko, this message translates to:
  /// **'다른 파일 가져오기'**
  String get importAnother;

  /// No description provided for @importStepUpload.
  ///
  /// In ko, this message translates to:
  /// **'파일 선택'**
  String get importStepUpload;

  /// No description provided for @importStepMapping.
  ///
  /// In ko, this message translates to:
  /// **'열 매핑'**
  String get importStepMapping;

  /// No description provided for @importStepDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get importStepDone;

  /// No description provided for @calDetailDday.
  ///
  /// In ko, this message translates to:
  /// **'D-DAY'**
  String get calDetailDday;

  /// No description provided for @calDetailDdayLeft.
  ///
  /// In ko, this message translates to:
  /// **'D-{n}'**
  String calDetailDdayLeft(int n);

  /// No description provided for @calDetailDdayPast.
  ///
  /// In ko, this message translates to:
  /// **'{n}일 지남'**
  String calDetailDdayPast(int n);

  /// No description provided for @calDetailDurationH.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간'**
  String calDetailDurationH(int h);

  /// No description provided for @calDetailDurationHM.
  ///
  /// In ko, this message translates to:
  /// **'{h}시간 {m}분'**
  String calDetailDurationHM(int h, int m);

  /// No description provided for @calDetailDurationM.
  ///
  /// In ko, this message translates to:
  /// **'{m}분'**
  String calDetailDurationM(int m);

  /// No description provided for @calDetailMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get calDetailMemo;

  /// No description provided for @calDetailRepeat.
  ///
  /// In ko, this message translates to:
  /// **'반복'**
  String get calDetailRepeat;

  /// No description provided for @categoryReorderEdit.
  ///
  /// In ko, this message translates to:
  /// **'편집'**
  String get categoryReorderEdit;

  /// No description provided for @categoryReorderHint.
  ///
  /// In ko, this message translates to:
  /// **'핸들을 잡고 위·아래로 끌어 순서를 바꿔요. 상위 카테고리끼리·하위 카테고리끼리 이동돼요.'**
  String get categoryReorderHint;

  /// No description provided for @txmSpendSummary.
  ///
  /// In ko, this message translates to:
  /// **'소비 요약'**
  String get txmSpendSummary;

  /// No description provided for @txmInsightLessPre.
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 '**
  String get txmInsightLessPre;

  /// No description provided for @txmInsightLessHl.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 덜'**
  String txmInsightLessHl(String amount);

  /// No description provided for @txmInsightLessPost.
  ///
  /// In ko, this message translates to:
  /// **' 쓰는 중'**
  String get txmInsightLessPost;

  /// No description provided for @txmInsightMorePre.
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 '**
  String get txmInsightMorePre;

  /// No description provided for @txmInsightMoreHl.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 더'**
  String txmInsightMoreHl(String amount);

  /// No description provided for @txmInsightMorePost.
  ///
  /// In ko, this message translates to:
  /// **' 쓰는 중'**
  String get txmInsightMorePost;

  /// No description provided for @txmInsightSame.
  ///
  /// In ko, this message translates to:
  /// **'지난달과 비슷하게 쓰고 있어요'**
  String get txmInsightSame;

  /// No description provided for @txmInsightNone.
  ///
  /// In ko, this message translates to:
  /// **'이 달에는 거래 내역이 없어요'**
  String get txmInsightNone;

  /// No description provided for @txmInsightTopCatPre.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 '**
  String get txmInsightTopCatPre;

  /// No description provided for @txmInsightTopCatPost.
  ///
  /// In ko, this message translates to:
  /// **'에 가장 많이 썼어요'**
  String get txmInsightTopCatPost;

  /// No description provided for @txmPrevMonthBtn.
  ///
  /// In ko, this message translates to:
  /// **'{month} 이용 내역 보기'**
  String txmPrevMonthBtn(String month);

  /// No description provided for @txmEmptyMonth.
  ///
  /// In ko, this message translates to:
  /// **'{month} 거래가 없어요'**
  String txmEmptyMonth(String month);

  /// No description provided for @txmEmptyMonthDesc.
  ///
  /// In ko, this message translates to:
  /// **'다른 달을 살펴보거나 첫 거래를 추가해보세요.'**
  String get txmEmptyMonthDesc;

  /// No description provided for @txmToday.
  ///
  /// In ko, this message translates to:
  /// **'오늘'**
  String get txmToday;

  /// No description provided for @txmYesterday.
  ///
  /// In ko, this message translates to:
  /// **'어제'**
  String get txmYesterday;

  /// No description provided for @expChipMin.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 이상'**
  String expChipMin(String amount);

  /// No description provided for @expChipMax.
  ///
  /// In ko, this message translates to:
  /// **'{amount} 이하'**
  String expChipMax(String amount);

  /// No description provided for @tdmTodayLeft.
  ///
  /// In ko, this message translates to:
  /// **'오늘 할 일 {count}개'**
  String tdmTodayLeft(int count);

  /// No description provided for @tdmTodayDone.
  ///
  /// In ko, this message translates to:
  /// **'오늘 할 일 끝!'**
  String get tdmTodayDone;

  /// No description provided for @tdmNightSkyBtn.
  ///
  /// In ko, this message translates to:
  /// **'밤하늘'**
  String get tdmNightSkyBtn;

  /// No description provided for @tdmStarlightHint.
  ///
  /// In ko, this message translates to:
  /// **'별빛 {lit}/{goal} · {left}개 더 모으면 {name} 수집'**
  String tdmStarlightHint(int lit, int goal, int left, String name);

  /// No description provided for @tdmCollectedHint.
  ///
  /// In ko, this message translates to:
  /// **'{name} 수집 완료 · 연속 {streak}일'**
  String tdmCollectedHint(String name, int streak);

  /// No description provided for @tdmDoneRatio.
  ///
  /// In ko, this message translates to:
  /// **'{done}/{total} 완료'**
  String tdmDoneRatio(int done, int total);

  /// No description provided for @tdmFilterTag.
  ///
  /// In ko, this message translates to:
  /// **'태그'**
  String get tdmFilterTag;

  /// No description provided for @tdmHideDone.
  ///
  /// In ko, this message translates to:
  /// **'완료한 할 일 숨기기'**
  String get tdmHideDone;

  /// No description provided for @tdmEmptyMonth.
  ///
  /// In ko, this message translates to:
  /// **'{month} 할 일이 없어요'**
  String tdmEmptyMonth(String month);

  /// No description provided for @tdmEmptyMonthDesc.
  ///
  /// In ko, this message translates to:
  /// **'오른쪽 아래 + 버튼으로 추가해보세요.'**
  String get tdmEmptyMonthDesc;

  /// No description provided for @tdmEmptyFilter.
  ///
  /// In ko, this message translates to:
  /// **'조건에 맞는 할 일이 없어요'**
  String get tdmEmptyFilter;

  /// No description provided for @tdmEmptyFilterDesc.
  ///
  /// In ko, this message translates to:
  /// **'필터를 조정하거나 초기화해보세요.'**
  String get tdmEmptyFilterDesc;

  /// No description provided for @tdmStarToastGain.
  ///
  /// In ko, this message translates to:
  /// **'별빛 +{gain} · 수집까지 {left}별'**
  String tdmStarToastGain(int gain, int left);

  /// No description provided for @tdmStarToastCollected.
  ///
  /// In ko, this message translates to:
  /// **'별빛 +{gain} · 오늘의 별자리 수집!'**
  String tdmStarToastCollected(int gain);

  /// No description provided for @nightSkyTitle.
  ///
  /// In ko, this message translates to:
  /// **'밤하늘'**
  String get nightSkyTitle;

  /// No description provided for @forestReportTitle.
  ///
  /// In ko, this message translates to:
  /// **'관측 리포트'**
  String get forestReportTitle;

  /// No description provided for @fcolViewCta.
  ///
  /// In ko, this message translates to:
  /// **'감상하기'**
  String get fcolViewCta;

  /// No description provided for @fcolPreviewCta.
  ///
  /// In ko, this message translates to:
  /// **'미리보기'**
  String get fcolPreviewCta;

  /// No description provided for @fcolLockedHint.
  ///
  /// In ko, this message translates to:
  /// **'별빛 {count}개를 하룻밤에 모으면 만날 수 있어요.'**
  String fcolLockedHint(int count);

  /// No description provided for @frpObsResult.
  ///
  /// In ko, this message translates to:
  /// **'관측 결과 :'**
  String get frpObsResult;

  /// No description provided for @frpObsToday.
  ///
  /// In ko, this message translates to:
  /// **'{name} {lit}/{goal} 진행 중'**
  String frpObsToday(String name, int lit, int goal);

  /// No description provided for @frpObsCollected.
  ///
  /// In ko, this message translates to:
  /// **'{name} 수집!'**
  String frpObsCollected(String name);

  /// No description provided for @frpObsWithered.
  ///
  /// In ko, this message translates to:
  /// **'흐린 밤 · 구름 보호로 스트릭 유지'**
  String get frpObsWithered;

  /// No description provided for @frpObsRest.
  ///
  /// In ko, this message translates to:
  /// **'쉬어간 밤'**
  String get frpObsRest;

  /// No description provided for @frpStampDays.
  ///
  /// In ko, this message translates to:
  /// **'{count}일째'**
  String frpStampDays(int count);

  /// No description provided for @frpStampLabel.
  ///
  /// In ko, this message translates to:
  /// **'연속 관측!'**
  String get frpStampLabel;

  /// No description provided for @frpStarGather.
  ///
  /// In ko, this message translates to:
  /// **'별빛 모으기'**
  String get frpStarGather;

  /// No description provided for @frpPctBadge.
  ///
  /// In ko, this message translates to:
  /// **'{pct}% 달성'**
  String frpPctBadge(int pct);

  /// No description provided for @frpTileStar.
  ///
  /// In ko, this message translates to:
  /// **'모은 별빛'**
  String get frpTileStar;

  /// No description provided for @frpTileStarVal.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String frpTileStarVal(int count);

  /// No description provided for @frpTileDone.
  ///
  /// In ko, this message translates to:
  /// **'완료한 할 일'**
  String get frpTileDone;

  /// No description provided for @frpTileDoneVal.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String frpTileDoneVal(int count);

  /// No description provided for @frpAnalysis.
  ///
  /// In ko, this message translates to:
  /// **'별빛 분석'**
  String get frpAnalysis;

  /// No description provided for @frpLegendItem.
  ///
  /// In ko, this message translates to:
  /// **'{label} 완료: {count}'**
  String frpLegendItem(String label, int count);

  /// No description provided for @frpMissed.
  ///
  /// In ko, this message translates to:
  /// **'못다 켠 별'**
  String get frpMissed;

  /// No description provided for @frpMissedAllDone.
  ///
  /// In ko, this message translates to:
  /// **'오늘 하늘의 별을 모두 켰어요. 남은 별빛은 내일 밤으로!'**
  String get frpMissedAllDone;

  /// No description provided for @frpMissedCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개'**
  String frpMissedCount(int count);

  /// No description provided for @frpFuture.
  ///
  /// In ko, this message translates to:
  /// **'아직 오지 않은 밤이에요'**
  String get frpFuture;

  /// No description provided for @frpAsOf.
  ///
  /// In ko, this message translates to:
  /// **'{ts} 기준'**
  String frpAsOf(String ts);

  /// No description provided for @settingsMenuTodoTag.
  ///
  /// In ko, this message translates to:
  /// **'할일 태그'**
  String get settingsMenuTodoTag;

  /// No description provided for @ttagUsage.
  ///
  /// In ko, this message translates to:
  /// **'{count}건에 사용 중'**
  String ttagUsage(int count);

  /// No description provided for @calLabelUsage.
  ///
  /// In ko, this message translates to:
  /// **'{count}건에 사용 중'**
  String calLabelUsage(Object count);

  /// No description provided for @ttagEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'태그 수정'**
  String get ttagEditTitle;

  /// No description provided for @fcolOwnBadge.
  ///
  /// In ko, this message translates to:
  /// **'수집 {count}회'**
  String fcolOwnBadge(int count);

  /// No description provided for @ttagTitle.
  ///
  /// In ko, this message translates to:
  /// **'할일 태그'**
  String get ttagTitle;

  /// No description provided for @ttagDesc.
  ///
  /// In ko, this message translates to:
  /// **'할 일에 붙이는 태그예요. 리스트 필터와 태그별 분포에 사용돼요.'**
  String get ttagDesc;

  /// No description provided for @ttagAddCta.
  ///
  /// In ko, this message translates to:
  /// **'태그 추가'**
  String get ttagAddCta;

  /// No description provided for @ttagColorLabel.
  ///
  /// In ko, this message translates to:
  /// **'색상'**
  String get ttagColorLabel;

  /// No description provided for @ttagNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get ttagNameLabel;

  /// No description provided for @ttagEmpty.
  ///
  /// In ko, this message translates to:
  /// **'태그가 없어요'**
  String get ttagEmpty;

  /// No description provided for @ttagDeleteDesc.
  ///
  /// In ko, this message translates to:
  /// **'이 태그를 쓰는 할 일 {count}건은 태그 없음으로 남아요.'**
  String ttagDeleteDesc(int count);

  /// No description provided for @iconPickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'아이콘 선택'**
  String get iconPickerTitle;

  /// No description provided for @iconPickerSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'아이콘 검색...'**
  String get iconPickerSearchHint;

  /// No description provided for @iconPickerNone.
  ///
  /// In ko, this message translates to:
  /// **'없음'**
  String get iconPickerNone;

  /// No description provided for @iconPickerNoResults.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
  String get iconPickerNoResults;

  /// No description provided for @iconPickerResultCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}개 결과'**
  String iconPickerResultCount(int count);

  /// No description provided for @iconPickerTotalHint.
  ///
  /// In ko, this message translates to:
  /// **'전체 {count}개 · 스크롤해서 더 보기'**
  String iconPickerTotalHint(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
