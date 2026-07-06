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
  /// **'저금 목표'**
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
  /// **'상품·종목명'**
  String get assetProductName;

  /// No description provided for @assetProductPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'예: KODEX 200, 해외 ETF 포트폴리오'**
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

  /// No description provided for @assetSharesCount.
  ///
  /// In ko, this message translates to:
  /// **'{n}주'**
  String assetSharesCount(int n);

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

  /// No description provided for @assetCategoryOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get assetCategoryOther;

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

  /// No description provided for @todoStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'대기'**
  String get todoStatusPending;

  /// No description provided for @todoStatusInProgress.
  ///
  /// In ko, this message translates to:
  /// **'진행중'**
  String get todoStatusInProgress;

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

  /// No description provided for @todoProjectMgmt.
  ///
  /// In ko, this message translates to:
  /// **'프로젝트 관리'**
  String get todoProjectMgmt;

  /// No description provided for @todoTagMgmt.
  ///
  /// In ko, this message translates to:
  /// **'태그 관리'**
  String get todoTagMgmt;

  /// No description provided for @todoViewKanban.
  ///
  /// In ko, this message translates to:
  /// **'칸반 보기'**
  String get todoViewKanban;

  /// No description provided for @todoViewList.
  ///
  /// In ko, this message translates to:
  /// **'리스트 보기'**
  String get todoViewList;

  /// No description provided for @memoTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memoTitle;

  /// No description provided for @memoEmpty.
  ///
  /// In ko, this message translates to:
  /// **'메모가 없습니다'**
  String get memoEmpty;

  /// No description provided for @memoSearchEmpty.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다'**
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

  /// No description provided for @calHolidayMgmt.
  ///
  /// In ko, this message translates to:
  /// **'공휴일 관리'**
  String get calHolidayMgmt;

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

  /// No description provided for @calHolidayNamePlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'휴일 이름'**
  String get calHolidayNamePlaceholder;

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

  /// No description provided for @calAddCustomHoliday.
  ///
  /// In ko, this message translates to:
  /// **'사용자 휴일 추가'**
  String get calAddCustomHoliday;

  /// No description provided for @calRepeatYearlyLabel.
  ///
  /// In ko, this message translates to:
  /// **'매년 반복'**
  String get calRepeatYearlyLabel;

  /// No description provided for @calAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get calAdd;

  /// No description provided for @calYearHolidays.
  ///
  /// In ko, this message translates to:
  /// **'{year}년 휴일'**
  String calYearHolidays(int year);

  /// No description provided for @calNoHolidays.
  ///
  /// In ko, this message translates to:
  /// **'등록된 휴일이 없습니다'**
  String get calNoHolidays;

  /// No description provided for @calDeleteHolidayTitle.
  ///
  /// In ko, this message translates to:
  /// **'휴일 삭제'**
  String get calDeleteHolidayTitle;

  /// No description provided for @calDeleteHolidayConfirm.
  ///
  /// In ko, this message translates to:
  /// **'{name} 삭제할까요?'**
  String calDeleteHolidayConfirm(String name);

  /// No description provided for @calHolidayTypeCustom.
  ///
  /// In ko, this message translates to:
  /// **'사용자'**
  String get calHolidayTypeCustom;

  /// No description provided for @calHolidayTypeSubstitute.
  ///
  /// In ko, this message translates to:
  /// **'대체'**
  String get calHolidayTypeSubstitute;

  /// No description provided for @calHolidayTypePublic.
  ///
  /// In ko, this message translates to:
  /// **'공휴일'**
  String get calHolidayTypePublic;

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

  /// No description provided for @calAddFailed.
  ///
  /// In ko, this message translates to:
  /// **'추가 실패'**
  String get calAddFailed;

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

  /// No description provided for @calHolidayLoadError.
  ///
  /// In ko, this message translates to:
  /// **'휴일 로드 실패'**
  String get calHolidayLoadError;

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
  /// **'같은 이름의 카테고리가 있습니다.'**
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
