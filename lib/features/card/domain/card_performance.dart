/// 백엔드 `CardPerformanceApiDto.PerformanceResponse` 매핑.
///
/// 카드 한 장의 월 실적: `requiredAmount` 까지 사용해야 다음 달 혜택 활성.
class CardPerformance {
  const CardPerformance({
    required this.assetRowId,
    required this.yearMonth,
    this.requiredAmount,
    this.requiredText,
    required this.isRequired,
    required this.currentAmount,
    required this.achievementRate,
    required this.isAchieved,
    this.remainingAmount,
  });

  final int assetRowId;
  final String yearMonth; // 'YYYY-MM'
  final int? requiredAmount;
  final String? requiredText;
  final bool isRequired;
  final int currentAmount;
  final double achievementRate; // 0~1.x
  final bool isAchieved;
  final int? remainingAmount;

  factory CardPerformance.fromJson(Map<String, dynamic> j) => CardPerformance(
        assetRowId: (j['assetRowId'] as num).toInt(),
        yearMonth: (j['yearMonth'] as String?) ?? '',
        requiredAmount: (j['requiredAmount'] as num?)?.toInt(),
        requiredText: j['requiredText'] as String?,
        isRequired: (j['isRequired'] as bool?) ?? false,
        currentAmount: (j['currentAmount'] as num?)?.toInt() ?? 0,
        achievementRate: (j['achievementRate'] as num?)?.toDouble() ?? 0.0,
        isAchieved: (j['isAchieved'] as bool?) ?? false,
        remainingAmount: (j['remainingAmount'] as num?)?.toInt(),
      );
}
