import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/recurring/data/recurring_repository.dart';
import 'package:porest_desk_app/features/recurring/domain/recurring_transaction.dart';

final recurringRepositoryProvider =
    FutureProvider<RecurringRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return RecurringRepository(dio);
});

final recurringListProvider =
    FutureProvider<List<RecurringTransaction>>((ref) async {
  final repo = await ref.watch(recurringRepositoryProvider.future);
  return repo.list();
});
