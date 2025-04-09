import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/services/auth_service.dart';
import 'package:tictask/app/services/sync_service.dart';
import 'package:tictask/app/theme/app_theme.dart';
import 'package:tictask/features/timer/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/models/timer_config.dart';
import 'package:tictask/features/timer/repositories/timer_repository.dart';
import 'package:tictask/injection_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.showNavBar = true});

  final bool showNavBar;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TimerRepository _timerRepository = sl<TimerRepository>();
  final AuthService _authService = sl<AuthService>();
  final SyncService _syncService = sl<SyncService>();
  
  late Future<TimerConfig> _timerConfigFuture;
  bool _isSyncing = false;
  String? _syncStatusMessage;
  bool _syncEnabled = true;

  @override
  void initState() {
    super.initState();
    _timerConfigFuture = _timerRepository.getTimerConfig();
    _loadSyncSettings();
    
    // Listen to sync status changes
    _syncService.syncStatusStream.listen((status) {
      if (mounted) {
        setState(() {
          _isSyncing = status == SyncStatus.syncing;
          switch (status) {
            case SyncStatus.completed:
              _syncStatusMessage = 'Last sync: just now';
              break;
            case SyncStatus.failed:
              _syncStatusMessage = 'Sync failed. Try again.';
              break;
            case SyncStatus.offline:
              _syncStatusMessage = 'You are offline';
              break;
            default:
              _syncStatusMessage = _syncService.lastSyncTime != null
                  ? 'Last sync: ${_formatLastSyncTime(_syncService.lastSyncTime!)}'
                  : 'Not synced yet';
          }
        });
      }
    });
  }
  
  Future<void> _loadSyncSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncEnabled = prefs.getBool('sync_enabled') ?? true;
      _isSyncing = _syncService.status == SyncStatus.syncing;
      
      // Set initial sync status message
      if (_syncService.lastSyncTime != null) {
        _syncStatusMessage = 'Last sync: ${_formatLastSyncTime(_syncService.lastSyncTime!)}';
      } else {
        _syncStatusMessage = 'Not synced yet';
      }
    });
  }
  
  String _formatLastSyncTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      return '${DateFormat('MMM d, yyyy').format(time)}';
    }
  }
  
  Future<void> _syncNow() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
      _syncStatusMessage = 'Syncing...';
    });
    
    try {
      final success = await _syncService.syncAll();
      
      setState(() {
        _isSyncing = false;
        if (success) {
          _syncStatusMessage = 'Last sync: just now';
        } else {
          _syncStatusMessage = 'Sync failed. Try again.';
        }
      });
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _syncStatusMessage = 'Sync failed. Try again.';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync error: $e')),
      );
    }
  }
  
  Future<void> _toggleSyncEnabled(bool value) async {
    setState(() {
      _syncEnabled = value;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_enabled', value);
    
    if (value) {
      // If turning on sync, run a sync immediately
      _syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: FutureBuilder<TimerConfig>(
        future: _timerConfigFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final timerConfig = snapshot.data ?? TimerConfig.defaultConfig;

          return ListView(
            children: [
              // Sync settings (new section)
              if (_authService.isAuthenticated) ... [
                _buildSyncSettingsSection(context),
                const SizedBox(height: 20),
              ],
              
              _buildTimerSettingsSection(context, timerConfig),
              const SizedBox(height: 20),
              _buildSystemSettingsSection(context),
              
              if (_authService.isAuthenticated) ... [
                const SizedBox(height: 20),
                _buildAccountSection(context),
              ],
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSyncSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Sync',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Enable sync toggle
              SwitchListTile(
                title: const Text('Enable Sync'),
                subtitle: const Text('Sync your data across all devices'),
                value: _syncEnabled,
                onChanged: _toggleSyncEnabled,
              ),
              
              const Divider(height: 1, indent: 16),
              
              // Sync now button
              ListTile(
                title: const Text('Sync Now'),
                subtitle: Text(_syncStatusMessage ?? 'Not synced yet'),
                trailing: _isSyncing 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
                onTap: _syncNow,
                enabled: _syncEnabled && !_isSyncing && _authService.isAuthenticated,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSettingsSection(BuildContext context, TimerConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Timer Settings',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildTimerDurationTile(
                context,
                title: 'Focus Time Duration',
                value: config.pomodoroDurationInMinutes,
                unit: 'min',
                onChanged: (value) => _updateTimerConfig(
                  config.copyWith(pomoDuration: value * 60),
                ),
                min: 1,
                max: 60,
              ),
              const Divider(height: 1, indent: 16),
              _buildTimerDurationTile(
                context,
                title: 'Short Break Duration',
                value: config.shortBreakDurationInMinutes,
                unit: 'min',
                onChanged: (value) => _updateTimerConfig(
                  config.copyWith(shortBreakDuration: value * 60),
                ),
                min: 1,
                max: 30,
              ),
              const Divider(height: 1, indent: 16),
              _buildTimerDurationTile(
                context,
                title: 'Long Break Duration',
                value: config.longBreakDurationInMinutes,
                unit: 'min',
                onChanged: (value) => _updateTimerConfig(
                  config.copyWith(longBreakDuration: value * 60),
                ),
                min: 5,
                max: 60,
              ),
              const Divider(height: 1, indent: 16),
              _buildTimerDurationTile(
                context,
                title: 'Pomodoros Before Long Break',
                value: config.longBreakInterval,
                unit: '',
                onChanged: (value) => _updateTimerConfig(
                  config.copyWith(longBreakInterval: value),
                ),
                min: 1,
                max: 10,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDurationTile(
    BuildContext context, {
    required String title,
    required int value,
    required String unit,
    required void Function(int) onChanged,
    required int min,
    required int max,
  }) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            unit.isEmpty ? '$value' : '$value $unit',
            style: TextStyle(
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).hintColor,
          ),
        ],
      ),
      onTap: () => _showDurationPicker(
        context,
        title: title,
        initialValue: value,
        onChanged: onChanged,
        min: min,
        max: max,
        unit: unit,
      ),
    );
  }

  Future<void> _showDurationPicker(
    BuildContext context, {
    required String title,
    required int initialValue,
    required void Function(int) onChanged,
    required int min,
    required int max,
    required String unit,
  }) async {
    var selectedValue = initialValue;

    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onChanged(selectedValue);
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  selectedValue = min + index;
                },
                scrollController: FixedExtentScrollController(
                  initialItem: initialValue - min,
                ),
                children: List.generate(
                  max - min + 1,
                  (index) => Center(
                    child: Text(
                      unit.isEmpty ? '${min + index}' : '${min + index} $unit',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTimerConfig(TimerConfig config) async {
    await _timerRepository.saveTimerConfig(config);

    context.read<TimerBloc>().add(TimerConfigChanged(config: config));

    setState(() {
      _timerConfigFuture = Future.value(config);
    });
  }

  Widget _buildSystemSettingsSection(BuildContext context) {
    final currentThemeMode =
        context.select((ThemeBloc bloc) => bloc.state.themeMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'System Settings',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Appearance section
              ListTile(
                title: const Text('Appearance'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getThemeModeText(currentThemeMode),
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).hintColor,
                    ),
                  ],
                ),
                onTap: () => _showThemeModePicker(context, currentThemeMode),
              ),
              const Divider(height: 1, indent: 16),
              // Notifications section
              SwitchListTile(
                title: const Text('Enable Notifications'),
                value: true, // This should come from settings repository
                onChanged: (value) {
                  // Update settings
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            'Account',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              ListTile(
                title: Text(_authService.userEmail ?? 'Anonymous User'),
                subtitle: Text(_authService.isAuthenticated 
                    ? 'Signed in' 
                    : 'Not signed in'),
                leading: const Icon(Icons.account_circle),
              ),
              const Divider(height: 1, indent: 16),
              // Sign out button
              ListTile(
                title: const Text('Sign Out'),
                leading: const Icon(Icons.logout),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () => _showSignOutConfirmation(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Future<void> _showSignOutConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      await _authService.signOut();
      if (mounted) {
        // Navigate to login
        context.go(Routes.login);
      }
    }
  }

  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System';
    }
  }

  Future<void> _showThemeModePicker(
    BuildContext context,
    ThemeMode currentThemeMode,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildThemeModeOption(
              context,
              title: 'System',
              icon: Icons.brightness_auto,
              themeMode: ThemeMode.system,
              currentThemeMode: currentThemeMode,
            ),
            _buildThemeModeOption(
              context,
              title: 'Light',
              icon: Icons.light_mode,
              themeMode: ThemeMode.light,
              currentThemeMode: currentThemeMode,
            ),
            _buildThemeModeOption(
              context,
              title: 'Dark',
              icon: Icons.dark_mode,
              themeMode: ThemeMode.dark,
              currentThemeMode: currentThemeMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode themeMode,
    required ThemeMode currentThemeMode,
  }) {
    final isSelected = themeMode == currentThemeMode;

    return ListTile(
      leading: Icon(
        icon,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () {
        context.setThemeMode(themeMode);
        Navigator.pop(context);
      },
    );
  }
}
