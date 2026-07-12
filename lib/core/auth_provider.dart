import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/models/user.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
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
        final user = await repo.getCachedUser();
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> checkStatus() async {
    await _initializeAuth();
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(errorMessage: null);
    final repo = ref.read(authRepositoryProvider);
    final user = await repo.login(email, password);
    if (user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
      return true;
    } else {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Invalid credentials or connection error',
      );
      return false;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
