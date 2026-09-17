import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/settings/data/withdrawal_repository.dart';

final withdrawalRepositoryProvider = FutureProvider<WithdrawalRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return WithdrawalRepository(dio);
});
