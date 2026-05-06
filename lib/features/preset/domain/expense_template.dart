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
    required int categoryRowId,
    String? categoryName,
    required int assetRowId,
    String? assetName,
    required String expenseType,
    required int amount,
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
