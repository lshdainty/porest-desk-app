/// 백엔드 `CardBenefitCategoryMappingApiDto.MappingResponse` 매핑.
///
/// 카드 혜택 카테고리(예: '카페', '주유') ↔ 가계부 카테고리(`expenseCategoryRowId`) 연결.
/// `isCustom=false` 면 시스템 기본 매핑.
class CardBenefitMapping {
  const CardBenefitMapping({
    required this.rowId,
    required this.benefitCategory,
    this.expenseCategoryRowId,
    this.expenseCategoryName,
    required this.isCustom,
  });

  final int rowId;
  final String benefitCategory;
  final int? expenseCategoryRowId;
  final String? expenseCategoryName;
  final bool isCustom;

  factory CardBenefitMapping.fromJson(Map<String, dynamic> json) {
    return CardBenefitMapping(
      rowId: (json['rowId'] as num).toInt(),
      benefitCategory: (json['benefitCategory'] as String?) ?? '',
      expenseCategoryRowId: (json['expenseCategoryRowId'] as num?)?.toInt(),
      expenseCategoryName: json['expenseCategoryName'] as String?,
      isCustom: (json['isCustom'] as bool?) ?? false,
    );
  }
}
