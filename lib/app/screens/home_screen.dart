import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:tictask/features/calendar/screens/calendar_screen.dart';
import 'package:tictask/features/settings/screens/settings_screen.dart';
import 'package:tictask/features/tasks/screens/tasks_screen.dart';
import 'package:tictask/features/timer/screens/timer_screen.dart';
// Import stats screen once it's created

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  // Create page controllers if you want to maintain state between tab switches

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Define your screens here
  final List<Widget> _screens = [
    const TimerScreen(showNavBar: false, key: PageStorageKey('timer')),
    const TasksScreen(showNavBar: false, key: PageStorageKey('tasks')),
    const CalendarScreen(showNavBar: false, key: PageStorageKey('calendar')),
    const SettingsScreen(showNavBar: false, key: PageStorageKey('settings')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
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
      ),
    );
  }
}
