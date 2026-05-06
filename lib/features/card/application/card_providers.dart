import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../data/card_repository.dart';
import '../domain/card_catalog.dart';

final cardRepositoryProvider = FutureProvider<CardRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return CardRepository(dio);
});

typedef CardSearchKey = ({String? keyword, String? cardType});

final cardCatalogSearchProvider = FutureProvider.family<
    List<CardCatalogSummary>, CardSearchKey>((ref, key) async {
  final repo = await ref.watch(cardRepositoryProvider.future);
  return repo.search(keyword: key.keyword, cardType: key.cardType);
});

final cardCatalogDetailProvider =
    FutureProvider.family<CardCatalogDetail, int>((ref, id) async {
  final repo = await ref.watch(cardRepositoryProvider.future);
  return repo.detail(id);
});
