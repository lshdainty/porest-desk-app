import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/notification.dart';
import 'notification_providers.dart';

/// 알림 스트림 서비스 — front `useNotificationSSE` 의 모바일 폴백.
///
/// 백엔드 SSE 가 도입되기 전까지 polling 으로 새 알림을 감지한다.
/// FCM 도입 시 [start] 가 firebase_messaging.onMessage 를 구독하도록 교체.
class NotificationStreamService {
  NotificationStreamService(this.ref);
  final Ref ref;

  Timer? _timer;
  String? _lastSeenId; // 본 적 있는 가장 최근 알림 rowId.
  final _newController = StreamController<AppNotification>.broadcast();

  /// 새 알림 도착 시 emit.
  Stream<AppNotification> get newNotifications => _newController.stream;

  /// poll 시작. [interval] 마다 list 를 fetch 하고 처음 발견된 항목을 emit.
  void start({Duration interval = const Duration(seconds: 30)}) {
    stop();
    _tick();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    try {
      final repo = await ref.read(notificationRepositoryProvider.future);
      final list = await repo.list(limit: 20);
      if (list.isEmpty) return;
      // 최신 정렬: rowId 큰 순.
      list.sort((a, b) => b.rowId.compareTo(a.rowId));
      final newest = list.first;
      if (_lastSeenId == null) {
        _lastSeenId = newest.rowId.toString();
        return; // 첫 tick 은 baseline 만.
      }
      final lastSeen = int.tryParse(_lastSeenId!) ?? 0;
      // _lastSeenId 보다 큰 모든 새 알림을 emit (오래된 순).
      final fresh = list
          .where((n) => n.rowId > lastSeen)
          .toList()
        ..sort((a, b) => a.rowId.compareTo(b.rowId));
      for (final n in fresh) {
        _newController.add(n);
      }
      // unreadCount 캐시도 invalidate (헤더 배지 갱신).
      if (fresh.isNotEmpty) {
        ref.invalidate(unreadCountProvider);
        ref.invalidate(notificationListProvider);
        _lastSeenId = newest.rowId.toString();
      }
    } catch (_) {
      // 네트워크 에러는 조용히 넘김 (polling 이라 다음 tick).
    }
  }

  void dispose() {
    stop();
    _newController.close();
  }
}

/// 단일 인스턴스 — 앱 lifecycle 에서 [start]/[stop] 호출.
final notificationStreamServiceProvider =
    Provider<NotificationStreamService>((ref) {
  final svc = NotificationStreamService(ref);
  ref.onDispose(svc.dispose);
  return svc;
});

/// 새 알림 stream — UI 에서 listen 해 toast 등 표시.
final newNotificationStreamProvider =
    StreamProvider<AppNotification>((ref) {
  final svc = ref.watch(notificationStreamServiceProvider);
  return svc.newNotifications;
});
