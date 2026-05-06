import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/recurring_repository.dart';
import '../domain/recurring_transaction.dart';

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
