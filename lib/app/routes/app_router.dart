import 'package:go_router/go_router.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/screens/home_screen.dart';
import 'package:tictask/app/screens/not_found_screen.dart';
import 'package:tictask/features/timer/screens/timer_screen.dart';

/// App router configuration
GoRouter getAppRouter() {
  return GoRouter(
    initialLocation: Routes.home,
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      // Tab routes that redirect to home with the right tab
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
  );
}
