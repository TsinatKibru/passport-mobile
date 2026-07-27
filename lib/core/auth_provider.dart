import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user.dart';
import 'providers/dashboard_provider.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isLoading;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Start checking status immediately
    _initializeAuth();
    return AuthState(status: AuthStatus.unknown);
  }

  Future<void> _initializeAuth() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final loggedIn = await repo.isLoggedIn();
      if (loggedIn) {
        // Verify token validity with server on startup
        final freshUser = await repo.getCurrentUser();
        if (freshUser != null) {
          state = AuthState(
            status: AuthStatus.authenticated,
            user: freshUser,
            isLoading: false,
          );
        } else {
          // If profile fetch failed, check if token was deleted by the 401 interceptor
          final stillHasToken = await repo.isLoggedIn();
          if (!stillHasToken) {
            state = AuthState(status: AuthStatus.unauthenticated, isLoading: false);
          } else {
            // Server was offline or unreachable: fall back to cached user profile
            final user = await repo.getCachedUser();
            state = AuthState(
              status: AuthStatus.authenticated,
              user: user,
              isLoading: false,
            );
          }
        }
      } else {
        state = AuthState(status: AuthStatus.unauthenticated, isLoading: false);
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, isLoading: false);
    }
  }

  Future<void> checkStatus() async {
    await _initializeAuth();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.login(email, password);
      if (user != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
        );
        _invalidateDashboardProviders();
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.unauthenticated,
          errorMessage: 'Invalid credentials or connection error',
          isLoading: false,
        );
        return false;
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map ? data['message'] : null;
      String errorMsg = 'Connection error';
      if (msg is List) {
        errorMsg = msg.join('\n');
      } else if (msg != null) {
        errorMsg = msg.toString();
      } else if (e.response?.statusCode == 401) {
        errorMsg = 'Invalid credentials';
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: errorMsg,
        isLoading: false,
      );
      return false;
    } catch (_) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Connection error',
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
    _invalidateDashboardProviders();
  }

  void _invalidateDashboardProviders() {
    ref.invalidate(dashboardStatsProvider);
    ref.invalidate(activityLogsProvider);
    ref.invalidate(activityTrendProvider);
    ref.invalidate(roomOccupancyProvider);
    ref.invalidate(myActivityProvider);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

