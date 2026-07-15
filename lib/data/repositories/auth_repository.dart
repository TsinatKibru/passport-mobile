import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'base_repository.dart';
import '../models/user.dart';

class AuthRepository extends BaseRepository {
  final _storage = const FlutterSecureStorage();

  Future<User?> login(String email, String password) async {
    try {
      final res = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final token = res.data['accessToken'] as String;
      await _storage.write(key: 'accessToken', value: token);
      
      // Fetch user profile
      final user = await getCurrentUser();
      if (user != null) {
        await _storage.write(key: 'user', value: jsonEncode(user.toJson()));
      }
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final res = await dio.get('/auth/me');
      return User.fromJson(res.data);
    } catch (e) {
      return null;
    }
  }

  Future<User?> getCachedUser() async {
    final userJson = await _storage.read(key: 'user');
    if (userJson == null) return null;
    try {
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'user');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'accessToken');
    return token != null;
  }

  /// PUT /auth/change-password — returns null on success, else an error message.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await dio.put('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['message'] : null;
      if (msg is List) return msg.join('\n');
      return msg?.toString() ?? 'Could not change password';
    } catch (_) {
      return 'Could not change password';
    }
  }
}
