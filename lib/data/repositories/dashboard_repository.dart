import 'base_repository.dart';
import '../models/dashboard_stats.dart';
import '../models/analytics.dart';

class DashboardRepository extends BaseRepository {
  Future<DashboardStats?> getStats() async {
    try {
      final res = await dio.get('/dashboard/stats');
      return DashboardStats.fromJson(res.data);
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return null;
    }
  }

  /// GET /location/logs?page=1&limit=5
  /// Returns the 5 most recent movement events for the activity feed.
  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 5}) async {
    try {
      final res = await dio.get('/location/logs', queryParameters: {
        'page': 1,
        'limit': limit,
      });
      final data = res.data['data'] ?? res.data;
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      print('Error fetching activity logs: $e');
      return [];
    }
  }

  /// GET /dashboard/activity-trend?days=N
  /// Daily movement counts (by action) for the last [days] days.
  Future<List<ActivityTrendPoint>> getActivityTrend({int days = 7}) async {
    try {
      final res = await dio.get('/dashboard/activity-trend',
          queryParameters: {'days': days});
      final data = res.data is List ? res.data : (res.data['data'] ?? []);
      return (data as List)
          .map((json) => ActivityTrendPoint.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching activity trend: $e');
      return [];
    }
  }

  /// GET /dashboard/room-occupancy
  /// Per-room capacity/occupancy breakdown.
  Future<List<RoomOccupancy>> getRoomOccupancy() async {
    try {
      final res = await dio.get('/dashboard/room-occupancy');
      final data = res.data is List ? res.data : (res.data['data'] ?? []);
      return (data as List)
          .map((json) => RoomOccupancy.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching room occupancy: $e');
      return [];
    }
  }
}

