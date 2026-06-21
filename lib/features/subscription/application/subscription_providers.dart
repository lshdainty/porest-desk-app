/// 구독·기능권한 Riverpod providers. 증권 메뉴 게이트 + 설정.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';

final subscriptionRepositoryProvider = FutureProvider<SubscriptionRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return SubscriptionRepository(dio);
});

/// 내 기능권한 + 토스 연결상태. 메뉴 게이트 단일 소스. 실패 시 empty(권한 없음).
final myFeaturesProvider = FutureProvider<MyFeatures>((ref) async {
  try {
    final repo = await ref.watch(subscriptionRepositoryProvider.future);
    return await repo.getMyFeatures();
  } catch (_) {
    return MyFeatures.empty;
  }
});

/// 증권 기능권한 보유 여부(동기 — 로딩/에러 시 false).
final hasSecuritiesProvider = Provider<bool>((ref) {
  return ref.watch(myFeaturesProvider).asData?.value.hasSecurities ?? false;
});

final subscriptionPlansProvider = FutureProvider<List<SubscriptionPlanInfo>>((ref) async {
  final repo = await ref.watch(subscriptionRepositoryProvider.future);
  return repo.getPlans();
});

final mySubscriptionProvider = FutureProvider<SubscriptionInfo?>((ref) async {
  final repo = await ref.watch(subscriptionRepositoryProvider.future);
  return repo.getMySubscription();
});

final tossCredentialStatusProvider = FutureProvider<TossCredentialStatus>((ref) async {
  final repo = await ref.watch(subscriptionRepositoryProvider.future);
  return repo.getTossCredentialStatus();
});
