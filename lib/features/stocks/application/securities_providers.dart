/// 증권사 무관 시세 providers. 자산 화면이 쓴다 — 증권사를 몰라도 된다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/stocks/data/securities_repository.dart';

final securitiesRepositoryProvider = FutureProvider<SecuritiesRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return SecuritiesRepository(dio);
});
