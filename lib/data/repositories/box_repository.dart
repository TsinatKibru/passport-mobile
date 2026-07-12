import 'base_repository.dart';
import '../models/box.dart';

/// Handles all movable box API calls.
class BoxRepository extends BaseRepository {
  /// GET /boxes/qr/:qrCode
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

  /// GET /boxes/available — get boxes with at least N vacant spaces
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
