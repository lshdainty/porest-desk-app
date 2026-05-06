import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/dutch_pay_repository.dart';
import '../domain/dutch_pay.dart';

final dutchPayRepositoryProvider =
    FutureProvider<DutchPayRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return DutchPayRepository(dio);
});

final dutchPayListProvider = FutureProvider<List<DutchPay>>((ref) async {
  final repo = await ref.watch(dutchPayRepositoryProvider.future);
  return repo.list();
});
