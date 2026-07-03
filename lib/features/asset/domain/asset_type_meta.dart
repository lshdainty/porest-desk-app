import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

/// AssetType 코드 → 로컬라이즈된 표시 라벨.
String assetTypeLabel(AppLocalizations l, String code) => switch (code) {
      'BANK_ACCOUNT' => l.assetTypeBankAccount,
      'SAVINGS' => l.assetTypeSavings,
      'CASH' => l.assetTypeCash,
      'CREDIT_CARD' => l.assetTypeCreditCard,
      'CHECK_CARD' => l.assetTypeCheckCard,
      'INVESTMENT' => l.assetTypeInvestment,
      'LOAN' => l.assetTypeLoan,
      _ => l.assetTypeBankAccount,
    };

/// 백엔드 `AssetType` enum 의 7종 타입 메타데이터.
/// (icon 글리프는 asset icon 제거 마이그에서 폐기 — 자산 표시는 AssetLogo 모노그램 단일화.)
class AssetTypeMeta {
  const AssetTypeMeta({
    required this.code,
    required this.label,
    required this.group,
  });

  final String code;
  final String label;

  /// 자산 화면 그룹핑용 카테고리.
  final String group;

  static const all = <AssetTypeMeta>[
    AssetTypeMeta(code: 'BANK_ACCOUNT', label: '입출금', group: '계좌'),
    AssetTypeMeta(code: 'SAVINGS', label: '예적금', group: '계좌'),
    AssetTypeMeta(code: 'CASH', label: '현금', group: '계좌'),
    AssetTypeMeta(code: 'CREDIT_CARD', label: '신용카드', group: '카드'),
    AssetTypeMeta(code: 'CHECK_CARD', label: '체크카드', group: '카드'),
    AssetTypeMeta(code: 'INVESTMENT', label: '투자', group: '투자'),
    AssetTypeMeta(code: 'LOAN', label: '대출', group: '부채'),
  ];

  static AssetTypeMeta of(String code) =>
      all.firstWhere((m) => m.code == code, orElse: () => all.first);
}

/// 화면 표시 순서.
const assetGroupOrder = ['계좌', '카드', '투자', '부채'];
