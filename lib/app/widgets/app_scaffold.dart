import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/theme/dimensions.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showBottomNav;

  const AppScaffold({
    Key? key,
    required this.child,
    this.title,
    this.actions,
    this.showBottomNav = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
            )
          : null,
      body: SafeArea(
        child: child,
      ),
      bottomNavigationBar: showBottomNav
          ? NavigationBar(
              onDestinationSelected: (index) {
                // Navigate based on index
                switch (index) {
                  case 0:
                    context.go(Routes.timer);
                    break;
                  case 1:
                    context.go(Routes.tasks);
                    break;
                  case 2:
                    context.go(Routes.stats);
                    break;
                  case 3:
                    context.go(Routes.settings);
                    break;
                }
              },
              selectedIndex: _calculateSelectedIndex(context),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.timer_outlined),
                  selectedIcon: Icon(Icons.timer),
                  label: 'Timer',
                ),
                NavigationDestination(
                  icon: Icon(Icons.check_box_outlined),
                  selectedIcon: Icon(Icons.check_box),
                  label: 'Tasks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: 'Stats',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            )
          : null,
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    
    if (location.startsWith(Routes.timer)) {
      return 0;
    }
    if (location.startsWith(Routes.tasks)) {
      return 1;
    }
    if (location.startsWith(Routes.stats)) {
      return 2;
    }
    if (location.startsWith(Routes.settings)) {
      return 3;
    }

    return 0;
  }
}