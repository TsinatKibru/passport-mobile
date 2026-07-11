import 'package:dio/dio.dart';
import '../api/api_client.dart';

/// Base class for all repositories.
/// Provides a pre-configured Dio instance and shared error handling.
/// CONVENTIONS.md §1: widgets call repositories, never the ApiClient directly.
abstract class BaseRepository {
  final Dio dio = ApiClient.instance.dio;
}
