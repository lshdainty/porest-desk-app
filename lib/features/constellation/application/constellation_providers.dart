import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/constellation/data/constellation_repository.dart';
import 'package:porest_desk_app/features/constellation/domain/constellation.dart';

final constellationRepositoryProvider = FutureProvider<ConstellationRepository>(
  (ref) async {
    final dio = await ref.watch(dioProvider.future);
    return ConstellationRepository(dio);
  },
);

/// 오늘의 목표 별자리 + 별빛 현황 (히어로).
final constellationTodayProvider = FutureProvider<ConstellationToday>((
  ref,
) async {
  final repo = await ref.watch(constellationRepositoryProvider.future);
  return repo.today();
});

/// 나의 밤하늘 — 최근 14일.
final constellationSkyProvider = FutureProvider<List<SkyDay>>((ref) async {
  final repo = await ref.watch(constellationRepositoryProvider.future);
  return repo.sky();
});

/// 별자리 도감.
final constellationCollectionProvider =
    FutureProvider<ConstellationCollectionData>((ref) async {
      final repo = await ref.watch(constellationRepositoryProvider.future);
      return repo.collection();
    });

/// 별빛 상태 일괄 갱신 — 할일 완료 토글/메모 작성·삭제 후 호출 (WidgetRef).
void invalidateConstellation(WidgetRef ref) {
  ref.invalidate(constellationTodayProvider);
  ref.invalidate(constellationSkyProvider);
  ref.invalidate(constellationCollectionProvider);
}
