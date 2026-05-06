/// 백엔드 `ExpenseBudgetApiDto.ComplianceMonthResponse` 매핑.
///
/// 한 달 예산 준수율: `compliancePercent` 가 100 미만이면 한도 내, 100 초과면 초과.
class BudgetComplianceMonth {
  const BudgetComplianceMonth({
    required this.year,
    required this.month,
    required this.totalLimit,
    required this.totalSpent,
    required this.compliancePercent,
  });

  final int year;
  final int month;
  final int totalLimit;
  final int totalSpent;
  final double compliancePercent;

  factory BudgetComplianceMonth.fromJson(Map<String, dynamic> json) {
    return BudgetComplianceMonth(
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      totalLimit: (json['totalLimit'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toInt() ?? 0,
      compliancePercent: (json['compliancePercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
