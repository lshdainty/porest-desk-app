import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/notification/data/notification_repository.dart';
import 'package:porest_desk_app/features/notification/domain/notification.dart';

final notificationRepositoryProvider = FutureProvider<NotificationRepository>((
  ref,
) async {
  final dio = await ref.watch(dioProvider.future);
  return NotificationRepository(dio);
});

final notificationListProvider = FutureProvider<List<AppNotification>>((
  ref,
) async {
  final repo = await ref.watch(notificationRepositoryProvider.future);
  return repo.list();
});

final unreadCountProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(notificationRepositoryProvider.future);
  return repo.unreadCount();
});
