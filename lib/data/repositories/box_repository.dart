import 'base_repository.dart';
import '../models/box.dart';
import '../models/paginated_response.dart';

/// Handles all movable box API calls.
class BoxRepository extends BaseRepository {
  /// GET /boxes?status=...&search=...&page=...&limit=...
  /// Requires ADMIN role. Used by BoxesPage for the full inventory list.
  Future<List<Box>> getAll({
    String? status,
    String? search,
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final res = await dio.get('/boxes', queryParameters: {
        if (status != null && status != 'ALL') 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        'page': page,
        'limit': limit,
      });
      final data = res.data['data'] ?? res.data;
      return (data as List).map((json) => Box.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching all boxes: $e');
      return [];
    }
  }


  Future<Box?> getByQr(String qrCode) async {
    try {
      final res = await dio.get('/boxes/qr/$qrCode');
      return Box.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching box by QR: $e');
      return null;
    }
  }

  /// POST /boxes/:id/move — move box to a new slot
  Future<bool> move(String boxId, String newSlotId) async {
    try {
      await dio.post('/boxes/$boxId/move', data: {'slotId': newSlotId});
      return true;
    } catch (e) {
      print('Error moving box: $e');
      return false;
    }
  }

  /// GET /boxes/available — get boxes with at least N vacant spaces (with pagination)
  Future<PaginatedResponse<Box>> getAvailablePaginated(
    int neededSpaces, {
    int page = 1, 
    int limit = 20,
    String? search,
    String? roomId,
  }) async {
    try {
      final res = await dio.get(
        '/boxes/available',
        queryParameters: {
          'neededSpaces': neededSpaces,
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
        },
      );
      return PaginatedResponse.fromJson(res.data, (json) => Box.fromJson(json));
    } catch (e) {
      print('Error fetching available boxes: $e');
      return PaginatedResponse(
        data: [],
        total: 0,
        page: page,
        limit: limit,
        totalPages: 0,
        hasMore: false,
      );
    }
  }

  /// GET /boxes/available — get boxes with at least N vacant spaces (legacy method)
  Future<List<Box>> getAvailable(int neededSpaces, {int page = 1, int limit = 20}) async {
    try {
      final res = await dio.get(
        '/boxes/available',
        queryParameters: {
          'neededSpaces': neededSpaces,
          'page': page,
          'limit': limit,
        },
      );
      final data = res.data;
      final boxList = data['data'] ?? data;
      return (boxList as List).map((json) => Box.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching available boxes: $e');
      return [];
    }
  }
}
