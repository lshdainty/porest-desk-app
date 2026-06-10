import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/preset/data/preset_repository.dart';
import 'package:porest_desk_app/features/preset/domain/expense_template.dart';

final presetRepositoryProvider =
    FutureProvider<PresetRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return PresetRepository(dio);
});

final presetListProvider =
    FutureProvider<List<ExpenseTemplate>>((ref) async {
  final repo = await ref.watch(presetRepositoryProvider.future);
  return repo.list();
});
