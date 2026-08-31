import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/saving_goal/data/saving_goal_repository.dart';
import 'package:porest_desk_app/features/saving_goal/domain/saving_goal.dart';

final savingGoalRepositoryProvider = FutureProvider<SavingGoalRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return SavingGoalRepository(dio);
});

final savingGoalListProvider = FutureProvider<List<SavingGoal>>((ref) async {
  final repo = await ref.watch(savingGoalRepositoryProvider.future);
  return repo.list();
});

final savingGoalByIdProvider = FutureProvider.family<SavingGoal, int>((
  ref,
  id,
) async {
  final repo = await ref.watch(savingGoalRepositoryProvider.future);
  return repo.getById(id);
});
