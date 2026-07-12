import 'base_repository.dart';
import '../models/passport.dart';

/// Handles all passport API calls.
/// Business logic (capacity checks, location cascades) lives in the backend —
/// this repository is purely a typed HTTP wrapper.
class PassportRepository extends BaseRepository {
  /// GET /passports/qr/:qrCode
  Future<Passport?> getByQr(String qrCode) async {
    try {
      final res = await dio.get('/passports/qr/$qrCode');
      return Passport.fromJson(res.data as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching passport by QR: $e');
      return null;
    }
  }

  /// POST /passports/:id/assign — assign passport to a box
  Future<bool> assignToBox({
    required String passportId,
    required String boxId,
    String? slotQrCode,
    bool overrideLocation = false,
  }) async {
    try {
      await dio.post(
        '/passports/$passportId/assign',
        data: {
          'boxId': boxId,
          if (slotQrCode != null) 'slotQrCode': slotQrCode,
          'overrideLocation': overrideLocation,
        },
      );
      return true;
    } catch (e) {
      print('Error assigning passport: $e');
      return false;
    }
  }

  /// POST /passports/:id/return — return passport from owner into a box
  Future<bool> returnToBox({
    required String passportId,
    required String boxId,
    String? slotQrCode,
    bool overrideLocation = false,
  }) async {
    try {
      await dio.post(
        '/passports/$passportId/return',
        data: {
          'boxId': boxId,
          if (slotQrCode != null) 'slotQrCode': slotQrCode,
          'overrideLocation': overrideLocation,
        },
      );
      return true;
    } catch (e) {
      print('Error returning passport: $e');
      return false;
    }
  }

  /// POST /passports/batch-assign — batch assign multiple passports to a box
  Future<bool> batchAssign({
    required List<String> passportIds,
    required String boxId,
    String? slotQrCode,
    bool overrideLocation = false,
    required String action, // 'PASSPORT_ASSIGNED' | 'PASSPORT_RETURNED'
  }) async {
    try {
      await dio.post(
        '/passports/batch-assign',
        data: {
          'passportIds': passportIds,
          'boxId': boxId,
          if (slotQrCode != null) 'slotQrCode': slotQrCode,
          'overrideLocation': overrideLocation,
          'action': action,
        },
      );
      return true;
    } catch (e) {
      print('Error batch assigning passports: $e');
      return false;
    }
  }

  /// POST /passports/:id/issue — issue passport to owner
  Future<bool> issue(String passportId) async {
    try {
      await dio.post('/passports/$passportId/issue');
      return true;
    } catch (e) {
      print('Error issuing passport: $e');
      return false;
    }
  }
}
