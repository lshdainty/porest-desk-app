import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// 백엔드 `AssetType` enum 의 7종 타입 메타데이터.
class AssetTypeMeta {
  const AssetTypeMeta({
    required this.code,
    required this.label,
    required this.icon,
    required this.group,
  });

  final String code;
  final String label;
  final IconData icon;

  /// 자산 화면 그룹핑용 카테고리.
  final String group;

  static const all = <AssetTypeMeta>[
    AssetTypeMeta(code: 'BANK_ACCOUNT', label: '입출금', icon: LucideIcons.landmark, group: '계좌'),
    AssetTypeMeta(code: 'SAVINGS', label: '예적금', icon: LucideIcons.piggyBank, group: '계좌'),
    AssetTypeMeta(code: 'CASH', label: '현금', icon: LucideIcons.banknote, group: '계좌'),
    AssetTypeMeta(code: 'CREDIT_CARD', label: '신용카드', icon: LucideIcons.creditCard, group: '카드'),
    AssetTypeMeta(code: 'CHECK_CARD', label: '체크카드', icon: LucideIcons.creditCard, group: '카드'),
    AssetTypeMeta(code: 'INVESTMENT', label: '투자', icon: LucideIcons.trendingUp, group: '투자'),
    AssetTypeMeta(code: 'LOAN', label: '대출', icon: LucideIcons.minusCircle, group: '부채'),
  ];

  static AssetTypeMeta of(String code) =>
      all.firstWhere((m) => m.code == code, orElse: () => all.first);
}

/// 화면 표시 순서.
const assetGroupOrder = ['계좌', '카드', '투자', '부채'];
