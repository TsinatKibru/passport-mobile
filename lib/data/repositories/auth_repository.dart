import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'base_repository.dart';

class AuthRepository extends BaseRepository {
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final res = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = res.data['accessToken'] as String;
      await _storage.write(key: 'accessToken', value: token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'accessToken');
    return token != null;
  }
}
