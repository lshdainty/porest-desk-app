import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/dashboard/data/dashboard_repository.dart';
import 'package:porest_desk_app/features/dashboard/domain/dashboard_summary.dart';

final dashboardRepositoryProvider =
    FutureProvider<DashboardRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return DashboardRepository(dio);
});

/// Home 화면 통합 요약 (#230).
final dashboardSummaryProvider =
    FutureProvider<DashboardSummary>((ref) async {
  final repo = await ref.watch(dashboardRepositoryProvider.future);
  return repo.summary();
});

/// Dashboard 위젯 레이아웃 JSON (#231).
final dashboardLayoutProvider = FutureProvider<String?>((ref) async {
  final repo = await ref.watch(dashboardRepositoryProvider.future);
  return repo.getLayout();
});
