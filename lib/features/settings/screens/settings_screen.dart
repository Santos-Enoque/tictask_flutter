import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/services/auth_service.dart';
import 'package:tictask/app/services/sync_service.dart';
import 'package:tictask/app/theme/app_theme.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/app/theme/text_styles.dart';
import 'package:tictask/injection_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key, this.showNavBar = true}) : super(key: key);

  final bool showNavBar;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = sl<AuthService>();
  final SyncService _syncService = sl<SyncService>();
  
  bool _syncEnabled = true;
  bool _notificationsEnabled = true;
  bool _soundsEnabled = true;
  bool _vibrationEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _syncEnabled = prefs.getBool('sync_enabled') ?? true;
      _notificationsEnabled = prefs.getBool(AppConstants.notificationsEnabledPrefKey) ?? true;
      _soundsEnabled = prefs.getBool('sounds_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sync_enabled', _syncEnabled);
    await prefs.setBool(AppConstants.notificationsEnabledPrefKey, _notificationsEnabled);
    await prefs.setBool('sounds_enabled', _soundsEnabled);
    await prefs.setBool('vibration_enabled', _vibrationEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // App Info
          _buildSectionHeader('App Information'),
          ListTile(
            title: const Text('App Name'),
            subtitle: Text(AppConstants.appName),
          ),
          ListTile(
            title: const Text('App Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          const Divider(),

          // Appearance Settings
          _buildSectionHeader('Appearance'),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return ListTile(
                title: const Text('Theme'),
                subtitle: Text(_getThemeModeText(state.themeMode)),
                trailing: DropdownButton<ThemeMode>(
                  value: state.themeMode,
                  onChanged: (ThemeMode? newMode) {
                    if (newMode != null) {
                      context.setThemeMode(newMode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                  underline: const SizedBox.shrink(),
                ),
              );
            },
          ),
          const Divider(),

          // Window Settings (Desktop only)
          if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ...[
            _buildSectionHeader('Window'),
            ListTile(
              title: const Text('Window Settings'),
              subtitle: const Text('Configure window size and behavior'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                context.push(Routes.windowSettings);
              },
            ),
            const Divider(),
          ],

          // Notification Settings
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get notified when timers complete'),
            value: _notificationsEnabled,
            onChanged: (bool value) async {
              setState(() {
                _notificationsEnabled = value;
              });
              await _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Sound Effects'),
            subtitle: const Text('Play sound when timer completes'),
            value: _soundsEnabled,
            onChanged: (bool value) async {
              setState(() {
                _soundsEnabled = value;
              });
              await _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate when timer completes'),
            value: _vibrationEnabled,
            onChanged: (bool value) async {
              setState(() {
                _vibrationEnabled = value;
              });
              await _saveSettings();
            },
          ),
          const Divider(),

          // Timer Settings
          _buildSectionHeader('Timer Settings'),
          ListTile(
            title: const Text('Default Timer Duration'),
            subtitle: const Text('Configure default timer durations'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to timer settings
            },
          ),
          const Divider(),

          // Sync Settings
          _buildSectionHeader('Synchronization'),
          SwitchListTile(
            title: const Text('Enable Sync'),
            subtitle: const Text('Sync your data across devices'),
            value: _syncEnabled,
            onChanged: _authService.isAuthenticated
                ? (bool value) async {
                    setState(() {
                      _syncEnabled = value;
                    });
                    await _saveSettings();
                    
                    // Update sync service
                    _syncService.restartBackgroundSync();
                    
                    // Force sync if enabled
                    if (value) {
                      _syncService.syncAll();
                    }
                  }
                : null,
          ),
          if (_authService.isAuthenticated) ...[
            ListTile(
              title: const Text('Sync Now'),
              subtitle: Text('Last sync: ${_getLastSyncTimeText()}'),
              trailing: IconButton(
                icon: const Icon(Icons.sync),
                onPressed: () async {
                  // Show sync in progress
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Syncing data...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  // Perform sync
                  final success = await _syncService.syncAll();
                  
                  // Show result
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sync completed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sync failed. Please try again later.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  
                  // Refresh UI to show updated last sync time
                  setState(() {});
                },
              ),
            ),
          ],
          if (!_authService.isAuthenticated)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppDimensions.md),
              child: Text(
                'Sign in to enable synchronization',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          const Divider(),

          // Account
          _buildSectionHeader('Account'),
          if (_authService.isAuthenticated)
            ListTile(
              title: Text(_authService.userEmail ?? 'User'),
              subtitle: const Text('Signed in'),
              trailing: TextButton(
                onPressed: () async {
                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    await _authService.signOut();
                    setState(() {});
                  }
                },
                child: const Text('Sign Out'),
              ),
            )
          else
            ListTile(
              title: const Text('Sign In'),
              subtitle: const Text('Sync your data across devices'),
              trailing: ElevatedButton(
                onPressed: () {
                  context.go(Routes.login);
                },
                child: const Text('Sign In'),
              ),
            ),
          const Divider(),

          // Data Management
          _buildSectionHeader('Data Management'),
          ListTile(
            title: const Text('Export Data'),
            subtitle: const Text('Export your tasks and timer sessions'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                // Export data
              },
            ),
          ),
          ListTile(
            title: const Text('Import Data'),
            subtitle: const Text('Import tasks and timer sessions'),
            trailing: IconButton(
              icon: const Icon(Icons.upload),
              onPressed: () {
                // Import data
              },
            ),
          ),
          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all local data'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                // Show confirmation dialog
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Data'),
                    content: const Text(
                      'Are you sure you want to delete all local data? This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  // Clear all data
                  // Show loading indicator
                  // Show success message
                }
              },
            ),
          ),
          const Divider(),

          // About
          _buildSectionHeader('About'),
          ListTile(
            title: const Text('Privacy Policy'),
            onTap: () {
              // Open privacy policy
            },
          ),
          ListTile(
            title: const Text('Terms of Service'),
            onTap: () {
              // Open terms of service
            },
          ),
          ListTile(
            title: const Text('Acknowledgements'),
            subtitle: const Text('Third-party libraries and assets'),
            onTap: () {
              // Show acknowledgements
              showLicensePage(
                context: context,
                applicationName: AppConstants.appName,
                applicationVersion: AppConstants.appVersion,
              );
            },
          ),
          const SizedBox(height: AppDimensions.xl),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'Follow system';
      case ThemeMode.light:
        return 'Light mode';
      case ThemeMode.dark:
        return 'Dark mode';
    }
  }
  
  String _getLastSyncTimeText() {
    final lastSyncTime = _syncService.lastSyncTime;
    if (lastSyncTime == null) {
      return 'Never';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      return '${lastSyncTime.day}/${lastSyncTime.month}/${lastSyncTime.year}';
    }
  }
}