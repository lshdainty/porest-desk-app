import 'package:flutter/widgets.dart';

/// 거래 유형. front 의 `expense_type` 컬럼 (EXPENSE/INCOME/TRANSFER) 매핑.
enum TxType { expense, income, transfer }

/// 카테고리 (mock 모델 — 백엔드 연결 시 DTO 매핑 레이어 추가 예정).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final Color bg;
}

class Asset {
  const Asset({
    required this.id,
    required this.name,
    required this.type, // 'cash' | 'card' | 'account' | 'investment'
    this.balance,
  });

  final String id;
  final String name;
  final String type;
  final int? balance;
}

class Expense {
  const Expense({
    required this.id,
    required this.date, // 'YYYY-MM-DD'
    required this.amount, // 항상 양수, 부호는 [type] 으로 결정
    required this.type,
    required this.categoryId,
    required this.assetId,
    this.description,
    this.merchant,
  });

  final String id;
  final String date;
  final int amount;
  final TxType type;
  final String categoryId;
  final String assetId;
  final String? description;
  final String? merchant;

  /// 표시용 부호 적용 금액 (지출=음수, 수입/이체=양수).
  int get signedAmount => type == TxType.expense ? -amount : amount;
}
