/// 백엔드 일/주/연 요약 응답 매핑 (plain class — freezed 회피).

class DailySummary {
  const DailySummary({
    required this.date,
    required this.totalIncome,
    required this.totalExpense,
  });
  final String date; // YYYY-MM-DD
  final int totalIncome;
  final int totalExpense;
  factory DailySummary.fromJson(Map<String, dynamic> j) => DailySummary(
        date: (j['date'] as String?) ?? '',
        totalIncome: (j['totalIncome'] as num?)?.toInt() ?? 0,
        totalExpense: (j['totalExpense'] as num?)?.toInt() ?? 0,
      );
}

class WeeklySummary {
  const WeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.totalIncome,
    required this.totalExpense,
  });
  final String weekStart;
  final String weekEnd;
  final int totalIncome;
  final int totalExpense;
  factory WeeklySummary.fromJson(Map<String, dynamic> j) => WeeklySummary(
        weekStart: (j['weekStart'] as String?) ?? '',
        weekEnd: (j['weekEnd'] as String?) ?? '',
        totalIncome: (j['totalIncome'] as num?)?.toInt() ?? 0,
        totalExpense: (j['totalExpense'] as num?)?.toInt() ?? 0,
      );
}

class MonthlyAmount {
  const MonthlyAmount({
    required this.month,
    required this.totalIncome,
    required this.totalExpense,
    this.categoryBreakdown = const [],
  });
  final int month;
  final int totalIncome;
  final int totalExpense;
  final List<CategoryBreakdown> categoryBreakdown;
  factory MonthlyAmount.fromJson(Map<String, dynamic> j) {
    final raw = (j['categoryBreakdown'] as List?) ?? const [];
    return MonthlyAmount(
      month: (j['month'] as num?)?.toInt() ?? 0,
      totalIncome: (j['totalIncome'] as num?)?.toInt() ?? 0,
      totalExpense: (j['totalExpense'] as num?)?.toInt() ?? 0,
      categoryBreakdown: raw
          .map((e) => CategoryBreakdown.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class YearlySummary {
  const YearlySummary({
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    this.monthlyAmounts = const [],
  });
  final int year;
  final int totalIncome;
  final int totalExpense;
  final List<MonthlyAmount> monthlyAmounts;
  factory YearlySummary.fromJson(Map<String, dynamic> j) {
    final raw = (j['monthlyAmounts'] as List?) ?? const [];
    return YearlySummary(
      year: (j['year'] as num?)?.toInt() ?? 0,
      totalIncome: (j['totalIncome'] as num?)?.toInt() ?? 0,
      totalExpense: (j['totalExpense'] as num?)?.toInt() ?? 0,
      monthlyAmounts: raw
          .map((e) => MonthlyAmount.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// MonthlySummary 의 categoryBreakdown 항목 — 부모/자식 카테고리 합계.
/// `parentCategoryRowId` null 이면 최상위 카테고리.
class CategoryBreakdown {
  const CategoryBreakdown({
    this.categoryRowId,
    this.categoryName,
    this.parentCategoryRowId,
    this.parentCategoryName,
    required this.expenseType,
    required this.totalAmount,
  });
  final int? categoryRowId;
  final String? categoryName;
  final int? parentCategoryRowId;
  final String? parentCategoryName;
  final String expenseType; // EXPENSE/INCOME
  final int totalAmount;
  factory CategoryBreakdown.fromJson(Map<String, dynamic> j) =>
      CategoryBreakdown(
        categoryRowId: (j['categoryRowId'] as num?)?.toInt(),
        categoryName: j['categoryName'] as String?,
        parentCategoryRowId: (j['parentCategoryRowId'] as num?)?.toInt(),
        parentCategoryName: j['parentCategoryName'] as String?,
        expenseType: (j['expenseType'] as String?) ?? 'EXPENSE',
        totalAmount: (j['totalAmount'] as num?)?.toInt() ?? 0,
      );
}
