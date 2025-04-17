import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tictask/features/calendar/screens/calendar_screen.dart';
import 'package:tictask/features/settings/screens/settings_screen.dart';
import 'package:tictask/features/stats/screens/stats_screen.dart';
import 'package:tictask/features/tasks/presentation/screens/tasks_screen.dart';
import 'package:tictask/features/timer/screens/timer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;
  TimerDisplayMode _timerDisplayMode = TimerDisplayMode.normal;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Define your screens here
  late final List<Widget> _screens = [
    TimerScreen(
      showNavBar: false,
      key: const PageStorageKey('timer'),
      onDisplayModeChanged: (mode) {
        setState(() {
          _timerDisplayMode = mode;
        });
      },
    ),
    const TasksScreen(showNavBar: false, key: PageStorageKey('tasks')),
    const StatsScreen(showNavBar: false, key: PageStorageKey('stats')),
    const CalendarScreen(showNavBar: false, key: PageStorageKey('calendar')),
    const SettingsScreen(showNavBar: false, key: PageStorageKey('settings')),
  ];
  // checkif its large screen
  bool _isLargeScreen() {
    return MediaQuery.of(context).size.width > 600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
      // Only show bottom navigation bar on small screens and when timer is in normal mode
      bottomNavigationBar:
          ( _timerDisplayMode == TimerDisplayMode.normal)
              ? NavigationBar(
                  onDestinationSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  selectedIndex: _selectedIndex,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(LucideIcons.timer),
                      selectedIcon: Icon(Icons.timer),
                      label: '',
                    ),
                    NavigationDestination(
                      icon: Icon(LucideIcons.checkCircle),
                      selectedIcon: Icon(LucideIcons.checkCircle),
                      label: '',
                    ),
                    NavigationDestination(
                      icon: Icon(LucideIcons.barChart2),
                      selectedIcon: Icon(LucideIcons.barChart),
                      label: '',
                    ),
                    NavigationDestination(
                      icon: Icon(LucideIcons.calendar),
                      selectedIcon: Icon(LucideIcons.calendar),
                      label: '',
                    ),
                    NavigationDestination(
                      icon: Icon(LucideIcons.settings),
                      selectedIcon: Icon(LucideIcons.settings),
                      label: '',
                    ),
                  ],
                )
              : null,
    );
  }
}
