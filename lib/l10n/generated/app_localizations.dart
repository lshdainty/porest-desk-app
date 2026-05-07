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
