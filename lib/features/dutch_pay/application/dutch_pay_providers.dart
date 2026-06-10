import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/dutch_pay/data/dutch_pay_repository.dart';
import 'package:porest_desk_app/features/dutch_pay/domain/dutch_pay.dart';

final dutchPayRepositoryProvider =
    FutureProvider<DutchPayRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return DutchPayRepository(dio);
});

final dutchPayListProvider = FutureProvider<List<DutchPay>>((ref) async {
  final repo = await ref.watch(dutchPayRepositoryProvider.future);
  return repo.list();
});
