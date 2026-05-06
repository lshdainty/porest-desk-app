import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_catalog.freezed.dart';
part 'card_catalog.g.dart';

@freezed
abstract class CardCompany with _$CardCompany {
  const factory CardCompany({
    int? rowId,
    String? name,
    String? nameEng,
    String? logoUrl,
  }) = _CardCompany;
  factory CardCompany.fromJson(Map<String, dynamic> json) =>
      _$CardCompanyFromJson(json);
}

@freezed
abstract class CardAnnualFee with _$CardAnnualFee {
  const factory CardAnnualFee({int? amount, String? label}) = _CardAnnualFee;
  factory CardAnnualFee.fromJson(Map<String, dynamic> json) =>
      _$CardAnnualFeeFromJson(json);
}

@freezed
abstract class CardPerformance with _$CardPerformance {
  const factory CardPerformance({
    int? requiredAmount,
    String? requiredText,
    String? isRequired, // 'Y'|'N'
  }) = _CardPerformance;
  factory CardPerformance.fromJson(Map<String, dynamic> json) =>
      _$CardPerformanceFromJson(json);
}

@freezed
abstract class CardCatalogSummary with _$CardCatalogSummary {
  const factory CardCatalogSummary({
    required int rowId,
    int? externalCardId,
    CardCompany? company,
    required String cardName,
    String? cardType, // CREDIT/CHECK
    String? benefitType,
    String? isDiscontinued,
    String? onlyOnline,
    String? launchDate,
    String? imgUrl,
    String? detailUrl,
    CardAnnualFee? annualFee,
    CardPerformance? performance,
  }) = _CardCatalogSummary;

  factory CardCatalogSummary.fromJson(Map<String, dynamic> json) =>
      _$CardCatalogSummaryFromJson(json);
}

@freezed
abstract class CardBenefit with _$CardBenefit {
  const factory CardBenefit({
    int? rowId,
    String? category,
    String? categoryIcon,
    String? title,
    String? summary,
    String? detail,
    int? sortOrder,
  }) = _CardBenefit;

  factory CardBenefit.fromJson(Map<String, dynamic> json) =>
      _$CardBenefitFromJson(json);
}

@freezed
abstract class CardTagGroup with _$CardTagGroup {
  const factory CardTagGroup({
    String? category,
    @Default(<String>[]) List<String> tags,
  }) = _CardTagGroup;
  factory CardTagGroup.fromJson(Map<String, dynamic> json) =>
      _$CardTagGroupFromJson(json);
}

@freezed
abstract class CardCatalogDetail with _$CardCatalogDetail {
  const factory CardCatalogDetail({
    required CardCatalogSummary summary,
    @Default(<String>[]) List<String> brands,
    @Default(<CardBenefit>[]) List<CardBenefit> benefits,
    @Default(<CardBenefit>[]) List<CardBenefit> cautions,
    @Default(<CardTagGroup>[]) List<CardTagGroup> topBenefits,
    @Default(<CardTagGroup>[]) List<CardTagGroup> searchBenefits,
  }) = _CardCatalogDetail;

  factory CardCatalogDetail.fromJson(Map<String, dynamic> json) =>
      _$CardCatalogDetailFromJson(json);
}
