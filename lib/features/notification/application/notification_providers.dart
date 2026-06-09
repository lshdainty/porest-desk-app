import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/notification_repository.dart';
import '../domain/notification.dart';

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
