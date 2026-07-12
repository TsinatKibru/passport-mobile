import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import '../presentation/login_screen.dart';
import '../presentation/home_screen.dart';
import '../presentation/scan_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final status = authState.status;
      final goingToLogin = state.matchedLocation == '/login';

      // While checking auth status, stay on current route
      if (status == AuthStatus.unknown) {
        return null; // Don't redirect while loading
      }

      if (status == AuthStatus.unauthenticated) {
        return goingToLogin ? null : '/login';
      }

      if (status == AuthStatus.authenticated && goingToLogin) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final authState = ref.watch(authProvider);
          // Show loading screen while checking auth
          if (authState.status == AuthStatus.unknown) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] ?? 'assign';
          return ScanScreen(mode: mode);
        },
      ),
    ],
  );
});
