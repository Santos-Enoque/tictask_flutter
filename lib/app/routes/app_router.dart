import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/screens/not_found_screen.dart';
import 'package:tictask/features/timer/screens/timer_screen.dart';

/// App router configuration
GoRouter getAppRouter() {
  return GoRouter(
    initialLocation: Routes.timer,
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: Routes.home,
        redirect: (_, __) => Routes.timer,
      ),
      GoRoute(
        path: Routes.timer,
        builder: (context, state) => const TimerScreen(),
      ),
      // Task routes will be added later
      // Stats routes will be added later
      // Settings routes will be added later
    ],
  );
}