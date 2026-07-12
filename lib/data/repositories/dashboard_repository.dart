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
}
