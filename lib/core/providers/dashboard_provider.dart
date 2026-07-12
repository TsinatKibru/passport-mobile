import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/dashboard_stats.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardStatsProvider = FutureProvider<DashboardStats?>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return await repo.getStats();
});
