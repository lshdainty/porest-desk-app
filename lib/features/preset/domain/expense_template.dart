import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_template.freezed.dart';
part 'expense_template.g.dart';

/// 백엔드 `ExpenseTemplateApiDto.Response` 매핑.
@freezed
abstract class ExpenseTemplate with _$ExpenseTemplate {
  const factory ExpenseTemplate({
    required int rowId,
    int? userRowId,
    required String templateName,
    int? categoryRowId,
    String? categoryName,
    int? assetRowId,
    String? assetName,

    /// 이체일 때 받는 자산. 지출·수입이면 null.
    int? toAssetRowId,
    String? toAssetName,
    int? fee,

    /// 이체 이자 — 받는 자산이 대출일 때만 값이 있다.
    int? interestAmount,

    /// 'EXPENSE' | 'INCOME' | 'TRANSFER'
    required String expenseType,
    int? amount,
    String? description,
    String? merchant,
    String? paymentMethod,
    int? useCount,
    int? sortOrder,
    String? lockAmount, // 'Y' | 'N'
    String? lastUsedAt,
    String? createAt,
    String? modifyAt,
  }) = _ExpenseTemplate;

  factory ExpenseTemplate.fromJson(Map<String, dynamic> json) =>
      _$ExpenseTemplateFromJson(json);
}
