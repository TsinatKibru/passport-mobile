import 'base_repository.dart';

/// Handles all passport API calls.
/// Business logic (capacity checks, location cascades) lives in the backend —
/// this repository is purely a typed HTTP wrapper.
class PassportRepository extends BaseRepository {
  /// GET /passports/qr/:qrCode
  Future<Map<String, dynamic>> getByQr(String qrCode) async {
    final res = await dio.get('/passports/qr/$qrCode');
    return res.data as Map<String, dynamic>;
  }

  /// POST /passports/:id/assign — assign passport to a box
  Future<Map<String, dynamic>> assignToBox({
    required String passportId,
    required String boxId,
    String? slotQrCode,
    bool overrideLocation = false,
  }) async {
    final res = await dio.post(
      '/passports/$passportId/assign',
      data: {
        'boxId': boxId,
        if (slotQrCode != null) 'slotQrCode': slotQrCode,
        'overrideLocation': overrideLocation,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /passports/:id/return — return passport from owner into a box
  Future<Map<String, dynamic>> returnToBox({
    required String passportId,
    required String boxId,
    String? slotQrCode,
    bool overrideLocation = false,
  }) async {
    final res = await dio.post(
      '/passports/$passportId/return',
      data: {
        'boxId': boxId,
        if (slotQrCode != null) 'slotQrCode': slotQrCode,
        'overrideLocation': overrideLocation,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /passports/batch-assign — batch assign multiple passports to a box
  Future<Map<String, dynamic>> batchAssign({
    required List<String> passportIds,
    required String boxId,
    String? slotQrCode,
    bool overrideLocation = false,
    required String action, // 'PASSPORT_ASSIGNED' | 'PASSPORT_RETURNED'
  }) async {
    final res = await dio.post(
      '/passports/batch-assign',
      data: {
        'passportIds': passportIds,
        'boxId': boxId,
        if (slotQrCode != null) 'slotQrCode': slotQrCode,
        'overrideLocation': overrideLocation,
        'action': action,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  /// POST /passports/:id/issue — issue passport to owner
  Future<Map<String, dynamic>> issue(String passportId) async {
    final res = await dio.post('/passports/$passportId/issue');
    return res.data as Map<String, dynamic>;
  }
}
