import 'package:flutter/material.dart';
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
    const TimerScreen(showNavBar: false),
    const TasksScreen(showNavBar: false),
    const Placeholder(), // Replace with StatsScreen once created
    const SettingsScreen(showNavBar: false),
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
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
