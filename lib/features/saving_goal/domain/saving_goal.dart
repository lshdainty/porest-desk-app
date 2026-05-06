import 'package:freezed_annotation/freezed_annotation.dart';

part 'saving_goal.freezed.dart';
part 'saving_goal.g.dart';

@freezed
abstract class SavingGoal with _$SavingGoal {
  const factory SavingGoal({
    required int rowId,
    int? userRowId,
    required String title,
    String? description,
    required int targetAmount,
    @Default(0) int currentAmount,
    String? currency,
    String? deadlineDate,
    String? icon,
    String? color,
    int? linkedAssetRowId,
    int? sortOrder,
    String? isAchieved, // 'Y'|'N'
    String? achievedAt,
  }) = _SavingGoal;

  factory SavingGoal.fromJson(Map<String, dynamic> json) =>
      _$SavingGoalFromJson(json);
}

extension SavingGoalX on SavingGoal {
  bool get achieved => (isAchieved ?? 'N') == 'Y';
  double get progress =>
      targetAmount == 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);
}
