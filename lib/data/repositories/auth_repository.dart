import 'dart:convert';
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
}
