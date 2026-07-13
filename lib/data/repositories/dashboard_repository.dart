import 'base_repository.dart';
import '../models/dashboard_stats.dart';

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
}

