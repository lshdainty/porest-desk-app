import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/notification/data/user_preferences_repository.dart';

final userPreferencesRepositoryProvider =
    FutureProvider<UserPreferencesRepository>((ref) async {
      final dio = await ref.watch(dioProvider.future);
      return UserPreferencesRepository(dio);
    });

/// 사용자 환경설정 상태 — 낙관적 업데이트(optimistic) Notifier.
///
/// [build] 에서 GET 으로 초기 로드. [patch] 는 호출 즉시 로컬 상태를 갱신해
/// UI 가 바로 반응하고, 그 뒤 PATCH(변경 필드만) 를 보낸다. 실패 시 직전 값으로
/// 조용히 롤백(서버 응답값으로 정정).
/// autoDispose — 화면을 떠나면 상태 폐기, 재진입 시 GET 재조회.
/// (웹 등 다른 클라이언트에서 변경한 값이 다음 진입 때 반영되도록)
final userPreferencesProvider =
    AsyncNotifierProvider.autoDispose<UserPreferencesNotifier, UserPreferences>(
      UserPreferencesNotifier.new,
    );

class UserPreferencesNotifier extends AsyncNotifier<UserPreferences> {
  @override
  Future<UserPreferences> build() async {
    final repo = await ref.watch(userPreferencesRepositoryProvider.future);
    return repo.get();
  }

  /// 부분 갱신 — 낙관적. [optimistic] 으로 즉시 로컬 반영 후 PATCH.
  /// 실패 시 이전 값으로 롤백.
  Future<void> patch(
    Map<String, dynamic> fields, {
    required UserPreferences Function(UserPreferences prev) optimistic,
  }) async {
    final prev = state.value;
    if (prev == null) return;

    // 낙관적 즉시 반영.
    state = AsyncData(optimistic(prev));
    try {
      final repo = await ref.read(userPreferencesRepositoryProvider.future);
      final updated = await repo.update(fields);
      state = AsyncData(updated);
    } catch (_) {
      // 조용히 롤백.
      state = AsyncData(prev);
    }
  }
}
