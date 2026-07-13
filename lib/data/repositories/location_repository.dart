import 'base_repository.dart';
import '../models/room.dart';

/// Handles location hierarchy API calls (rooms, shelves, etc.).
class LocationRepository extends BaseRepository {
  /// GET /location/rooms — list all rooms
  Future<List<Room>> getRooms() async {
    try {
      final res = await dio.get('/location/rooms');
      final data = res.data;
      final list = data is List ? data : (data['data'] as List? ?? []);
      return list.map((json) => Room.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching rooms: $e');
      return [];
    }
  }
}
