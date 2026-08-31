/// 백엔드 일별 요약 응답 매핑 (plain class — freezed 회피).
library;

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
