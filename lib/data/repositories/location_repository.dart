import 'base_repository.dart';
import '../models/room.dart';

/// Handles location hierarchy API calls (rooms → shelves → rows → slots).
class LocationRepository extends BaseRepository {
  /// GET /location/rooms — list all rooms with shelf count
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

  /// GET /location/shelves?roomId= — list shelves, filtered by room
  Future<List<Shelf>> getShelves(String roomId) async {
    try {
      final res = await dio.get('/location/shelves', queryParameters: {'roomId': roomId});
      final data = res.data;
      final list = data is List ? data : (data['data'] as List? ?? []);
      return list.map((json) => Shelf.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching shelves: $e');
      return [];
    }
  }

  /// GET /location/rows?shelfId= — list rows, filtered by shelf
  Future<List<VaultRow>> getRows(String shelfId) async {
    try {
      final res = await dio.get('/location/rows', queryParameters: {'shelfId': shelfId});
      final data = res.data;
      final list = data is List ? data : (data['data'] as List? ?? []);
      return list.map((json) => VaultRow.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching rows: $e');
      return [];
    }
  }

  /// GET /location/slots?rowId= — list slots with box contents, filtered by row
  Future<List<VaultSlot>> getSlots(String rowId) async {
    try {
      final res = await dio.get('/location/slots', queryParameters: {'rowId': rowId});
      final data = res.data;
      // When rowId is given, the backend returns a plain list (not paginated)
      final list = data is List ? data : (data['data'] as List? ?? []);
      return list.map((json) => VaultSlot.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching slots: $e');
      return [];
    }
  }
}
