import 'base_repository.dart';

/// Handles all movable box API calls.
class BoxRepository extends BaseRepository {
  /// GET /boxes/qr/:qrCode
  Future<Map<String, dynamic>> getByQr(String qrCode) async {
    final res = await dio.get('/boxes/qr/$qrCode');
    return res.data as Map<String, dynamic>;
  }

  /// POST /boxes/:id/move — move box to a new slot
  Future<Map<String, dynamic>> move(String boxId, String newSlotId) async {
    final res = await dio.post('/boxes/$boxId/move', data: {'slotId': newSlotId});
    return res.data as Map<String, dynamic>;
  }

  /// GET /boxes/available — get boxes with at least N vacant spaces
  Future<List<dynamic>> getAvailable(int neededSpaces) async {
    final res = await dio.get('/boxes/available', queryParameters: {'neededSpaces': neededSpaces});
    return res.data as List<dynamic>;
  }
}
