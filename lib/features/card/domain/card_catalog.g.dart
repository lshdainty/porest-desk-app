// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CardCompany _$CardCompanyFromJson(Map<String, dynamic> json) => _CardCompany(
  rowId: (json['rowId'] as num?)?.toInt(),
  name: json['name'] as String?,
  nameEng: json['nameEng'] as String?,
  logoUrl: json['logoUrl'] as String?,
);

Map<String, dynamic> _$CardCompanyToJson(_CardCompany instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'name': instance.name,
      'nameEng': instance.nameEng,
      'logoUrl': instance.logoUrl,
    };

_CardAnnualFee _$CardAnnualFeeFromJson(Map<String, dynamic> json) =>
    _CardAnnualFee(
      amount: (json['amount'] as num?)?.toInt(),
      label: json['label'] as String?,
    );

Map<String, dynamic> _$CardAnnualFeeToJson(_CardAnnualFee instance) =>
    <String, dynamic>{'amount': instance.amount, 'label': instance.label};

_CardPerformance _$CardPerformanceFromJson(Map<String, dynamic> json) =>
    _CardPerformance(
      requiredAmount: (json['requiredAmount'] as num?)?.toInt(),
      requiredText: json['requiredText'] as String?,
      isRequired: json['isRequired'] as String?,
    );

Map<String, dynamic> _$CardPerformanceToJson(_CardPerformance instance) =>
    <String, dynamic>{
      'requiredAmount': instance.requiredAmount,
      'requiredText': instance.requiredText,
      'isRequired': instance.isRequired,
    };

_CardCatalogSummary _$CardCatalogSummaryFromJson(Map<String, dynamic> json) =>
    _CardCatalogSummary(
      rowId: (json['rowId'] as num).toInt(),
      externalCardId: (json['externalCardId'] as num?)?.toInt(),
      company: json['company'] == null
          ? null
          : CardCompany.fromJson(json['company'] as Map<String, dynamic>),
      cardName: json['cardName'] as String,
      cardType: json['cardType'] as String?,
      benefitType: json['benefitType'] as String?,
      isDiscontinued: json['isDiscontinued'] as String?,
      onlyOnline: json['onlyOnline'] as String?,
      launchDate: json['launchDate'] as String?,
      imgUrl: json['imgUrl'] as String?,
      detailUrl: json['detailUrl'] as String?,
      annualFee: json['annualFee'] == null
          ? null
          : CardAnnualFee.fromJson(json['annualFee'] as Map<String, dynamic>),
      performance: json['performance'] == null
          ? null
          : CardPerformance.fromJson(
              json['performance'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CardCatalogSummaryToJson(_CardCatalogSummary instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'externalCardId': instance.externalCardId,
      'company': instance.company,
      'cardName': instance.cardName,
      'cardType': instance.cardType,
      'benefitType': instance.benefitType,
      'isDiscontinued': instance.isDiscontinued,
      'onlyOnline': instance.onlyOnline,
      'launchDate': instance.launchDate,
      'imgUrl': instance.imgUrl,
      'detailUrl': instance.detailUrl,
      'annualFee': instance.annualFee,
      'performance': instance.performance,
    };

_CardBenefit _$CardBenefitFromJson(Map<String, dynamic> json) => _CardBenefit(
  rowId: (json['rowId'] as num?)?.toInt(),
  category: json['category'] as String?,
  categoryIcon: json['categoryIcon'] as String?,
  title: json['title'] as String?,
  summary: json['summary'] as String?,
  detail: json['detail'] as String?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$CardBenefitToJson(_CardBenefit instance) =>
    <String, dynamic>{
      'rowId': instance.rowId,
      'category': instance.category,
      'categoryIcon': instance.categoryIcon,
      'title': instance.title,
      'summary': instance.summary,
      'detail': instance.detail,
      'sortOrder': instance.sortOrder,
    };

_CardTagGroup _$CardTagGroupFromJson(Map<String, dynamic> json) =>
    _CardTagGroup(
      category: json['category'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
    );

Map<String, dynamic> _$CardTagGroupToJson(_CardTagGroup instance) =>
    <String, dynamic>{'category': instance.category, 'tags': instance.tags};

_CardCatalogDetail _$CardCatalogDetailFromJson(
  Map<String, dynamic> json,
) => _CardCatalogDetail(
  summary: CardCatalogSummary.fromJson(json['summary'] as Map<String, dynamic>),
  brands:
      (json['brands'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  benefits:
      (json['benefits'] as List<dynamic>?)
          ?.map((e) => CardBenefit.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CardBenefit>[],
  cautions:
      (json['cautions'] as List<dynamic>?)
          ?.map((e) => CardBenefit.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CardBenefit>[],
  topBenefits:
      (json['topBenefits'] as List<dynamic>?)
          ?.map((e) => CardTagGroup.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CardTagGroup>[],
  searchBenefits:
      (json['searchBenefits'] as List<dynamic>?)
          ?.map((e) => CardTagGroup.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <CardTagGroup>[],
);

Map<String, dynamic> _$CardCatalogDetailToJson(_CardCatalogDetail instance) =>
    <String, dynamic>{
      'summary': instance.summary,
      'brands': instance.brands,
      'benefits': instance.benefits,
      'cautions': instance.cautions,
      'topBenefits': instance.topBenefits,
      'searchBenefits': instance.searchBenefits,
    };
