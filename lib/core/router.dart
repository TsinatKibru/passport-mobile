import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';
import 'theme/app_theme.dart';
import '../presentation/login_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/home/pages/scan_page.dart';
import '../presentation/home/pages/passport_issue_page.dart';
import '../presentation/home/pages/passport_return_page.dart';
import '../presentation/home/widgets/biometric_guard.dart';

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
          // Show branded splash screen while checking auth
          if (authState.status == AuthStatus.unknown) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final c = context.colors;
            return Scaffold(
              backgroundColor: c.surface,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      isDark
                          ? 'assets/images/dark_mode_brand.png'
                          : 'assets/images/light_mode_brand.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            );
          }
          return const BiometricGuard(child: HomeScreen());
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
          Widget pageWidget;
          if (mode == 'issue') {
            pageWidget = const PassportIssuePage();
          } else if (mode == 'return') {
            pageWidget = const PassportReturnPage();
          } else {
            pageWidget = ScanPage(initialMode: mode);
          }
          return BiometricGuard(child: pageWidget);
        },
      ),
    ],
  );
});
