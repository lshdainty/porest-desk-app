import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:groo_damda_app/features/asset/domain/asset.dart';
import 'package:groo_damda_app/features/asset/domain/asset_type_meta.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 추가 · 수정 폼의 종류 아홉(I-17 6) — 1단계 Select Box 의 상자 하나가 이것 하나다. 웹 `lib/asset-kind.ts` 와 같은 아홉이다.
///
/// 저장 종류는 서버 `AssetType` 이다. 예금 · 적금은 둘 다 SAVINGS 이고 마이너스 통장은 BANK_ACCOUNT + 음수 잔액이다(QA #17).
enum AssetKind {
  checking,
  deposit,
  installment,
  overdraft,
  cash,
  loan,
  credit,
  check,
  investment,
}

/// 폼이 갈리는 묶음 — 칸 목록이 묶음마다 다르다.
enum AssetKindGroup { account, card, investment }

extension AssetKindX on AssetKind {
  AssetKindGroup get group => switch (this) {
    AssetKind.credit || AssetKind.check => AssetKindGroup.card,
    AssetKind.investment => AssetKindGroup.investment,
    _ => AssetKindGroup.account,
  };

  /// 백엔드 assetType 매핑.
  String get assetType => switch (this) {
    AssetKind.checking => 'BANK_ACCOUNT',
    AssetKind.deposit || AssetKind.installment => 'SAVINGS',
    AssetKind.cash => 'CASH',
    // 새 AssetType 을 만들지 않는다(QA #17) — 마이너스 통장은 음수 잔액으로 구분한다.
    AssetKind.overdraft => 'BANK_ACCOUNT',
    AssetKind.loan => 'LOAN',
    AssetKind.credit => 'CREDIT_CARD',
    AssetKind.check => 'CHECK_CARD',
    AssetKind.investment => 'INVESTMENT',
  };

  /// 카탈로그 검색의 카드 종류 코드(`CREDIT` · `CHECK`) — 카드가 아니면 null.
  String? get cardApiCode => switch (this) {
    AssetKind.credit => 'CREDIT',
    AssetKind.check => 'CHECK',
    _ => null,
  };

  /// 잔액이 빚인 종류 — 저장 부호가 `−` 다.
  bool get isDebt => this == AssetKind.overdraft || this == AssetKind.loan;

  String label(AppLocalizations l) => switch (this) {
    AssetKind.checking => l.assetTypeBankAccount,
    AssetKind.deposit => l.assetSubtypeDeposit,
    AssetKind.installment => l.assetSubtypeInstallment,
    AssetKind.overdraft => l.assetSubtypeOverdraft,
    AssetKind.cash => l.assetTypeCash,
    AssetKind.loan => l.assetTypeLoan,
    AssetKind.credit => l.assetTypeCreditCard,
    AssetKind.check => l.assetTypeCheckCard,
    AssetKind.investment => l.assetTypeInvestment,
  };

  /// 1단계 상자 앞 아이콘(22) — 두 카드가 같은 아이콘인 것은 그림 그대로다(제목이 가른다).
  IconData get icon => switch (this) {
    AssetKind.checking => LucideIcons.landmark,
    AssetKind.deposit => LucideIcons.piggyBank,
    AssetKind.installment => LucideIcons.calendarDays,
    AssetKind.overdraft => LucideIcons.percent,
    AssetKind.cash => LucideIcons.banknote,
    AssetKind.loan => LucideIcons.coins,
    AssetKind.credit || AssetKind.check => LucideIcons.creditCard,
    AssetKind.investment => LucideIcons.trendingUp,
  };

  /// 수정에서 바꿀 수 있는 종류 — 같은 묶음의 종류만. 투자는 하나뿐이다.
  List<AssetKind> get siblings => [
    for (final k in AssetKind.values)
      if (k.group == group) k,
  ];

  /// 자산이 열리는 종류. 마이너스 통장은 유형만으로 못 가른다 — 입출금인데 잔액이 음수면 그렇다(열 때마다 '입출금' 이 골라지면
  /// 저장하는 순간 사용 중인 금액이 잔액으로 뒤집힌다). 예금 · 적금은 둘 다 SAVINGS 라 늘 "적금" 으로 연다(지금 그대로 — I-17 T).
  static AssetKind of(Asset a) => switch (a.assetType) {
    'SAVINGS' => AssetKind.installment,
    'CASH' => AssetKind.cash,
    'LOAN' => AssetKind.loan,
    'CREDIT_CARD' => AssetKind.credit,
    'CHECK_CARD' => AssetKind.check,
    'INVESTMENT' => AssetKind.investment,
    _ => isOverdraftAsset(a) ? AssetKind.overdraft : AssetKind.checking,
  };
}

/// 1단계 묶음 — 계좌 · 카드 · 투자(차례 그대로).
const assetKindGroups = <(AssetKindGroup, List<AssetKind>)>[
  (
    AssetKindGroup.account,
    [
      AssetKind.checking,
      AssetKind.deposit,
      AssetKind.installment,
      AssetKind.overdraft,
      AssetKind.cash,
      AssetKind.loan,
    ],
  ),
  (AssetKindGroup.card, [AssetKind.credit, AssetKind.check]),
  (AssetKindGroup.investment, [AssetKind.investment]),
];
