import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/models/dashboard_stats.dart';
import '../../data/models/analytics.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final dashboardStatsProvider = FutureProvider<DashboardStats?>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return await repo.getStats();
});

final activityLogsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return await repo.getRecentActivity(limit: 5);
});

final activityTrendProvider =
    FutureProvider<List<ActivityTrendPoint>>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return await repo.getActivityTrend(days: 7);
});

final roomOccupancyProvider = FutureProvider<List<RoomOccupancy>>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return await repo.getRoomOccupancy();
});

final myActivityProvider = FutureProvider<MyActivity>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return await repo.getMyActivity();
});

