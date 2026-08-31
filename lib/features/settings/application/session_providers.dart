import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/settings/data/session_repository.dart';
import 'package:porest_desk_app/features/settings/domain/device_session.dart';

final sessionRepositoryProvider = FutureProvider<SessionRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return SessionRepository(dio);
});

final deviceSessionListProvider = FutureProvider<List<DeviceSession>>((
  ref,
) async {
  final repo = await ref.watch(sessionRepositoryProvider.future);
  return repo.list();
});
