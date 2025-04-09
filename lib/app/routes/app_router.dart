import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/screens/home_screen.dart';
import 'package:tictask/app/screens/not_found_screen.dart';
import 'package:tictask/app/services/auth_service.dart';
import 'package:tictask/features/auth/screens/login_screen.dart';
import 'package:tictask/features/timer/screens/timer_screen.dart';
import 'package:get_it/get_it.dart';

/// App router configuration with auth handling
GoRouter getAppRouter() {
  final authService = GetIt.I<AuthService>();

  return GoRouter(
    initialLocation: Routes.home,
    errorBuilder: (context, state) => const NotFoundScreen(),

    // Add redirect logic for authentication
    redirect: (context, state) {
      // Check if the route requires authentication
      final isAuthRoute = state.uri.path.startsWith(Routes.auth);

      // If user is not authenticated and not on an auth route, redirect to login
      if (!authService.isAuthenticated && !isAuthRoute) {
        return Routes.login;
      }

      // If user is authenticated and on an auth route, redirect to home
      if (authService.isAuthenticated && isAuthRoute) {
        return Routes.home;
      }

      // No redirection needed
      return null;
    },

    // Define routes
    routes: [
      // Authentication routes
      GoRoute(
        path: Routes.auth,
        builder: (context, state) => LoginScreen(
          onLoginSuccess: () => context.go(Routes.home),
        ),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => LoginScreen(
              onLoginSuccess: () => context.go(Routes.home),
            ),
          ),
        ],
      ),

      // App routes (existing)
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: Routes.timer,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'task/:taskId',
            builder: (context, state) {
              final taskId = state.pathParameters['taskId'];
              return TimerScreen(
                taskId: taskId,
                autoStart: true,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.tasks,
        builder: (context, state) => const HomeScreen(initialIndex: 1),
      ),
      GoRoute(
        path: Routes.stats,
        builder: (context, state) => const HomeScreen(initialIndex: 2),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const HomeScreen(initialIndex: 4),
      ),
      GoRoute(
        path: Routes.calendar,
        builder: (context, state) => const HomeScreen(initialIndex: 3),
      ),
    ],

    // Optional: Add observers for analytics or debugging
    observers: [
      GoRouterObserver(),
    ],
  );
}

// Optional: Router observer for logging
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    debugPrint('Navigation: ${route.settings.name}');
  }
}
