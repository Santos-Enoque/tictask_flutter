import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/app/routes/routes.dart';
import 'package:tictask/app/theme/colors.dart';
import 'package:tictask/core/services/auth_service.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/core/services/sync_service.dart';
import 'package:tictask/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:tictask/injection_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key, this.showNavBar = true}) : super(key: key);

  final bool showNavBar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsBloc>()..add(const LoadSettings()),
      child: _SettingsScreenContent(showNavBar: showNavBar),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
  const _SettingsScreenContent({required this.showNavBar});

  final bool showNavBar;

  @override
  Widget build(BuildContext context) {
    final authService = sl<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocConsumer<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state is SettingsLoaded) {
            return _buildSettingsList(context, state, authService);
          }
          
          return const Center(child: Text('Failed to load settings'));
        },
      ),
    );
  }

  Widget _buildSettingsList(
    BuildContext context, 
    SettingsLoaded state, 
    AuthService authService
  ) {
    return ListView(
      children: [
        // App Info
        _buildSectionHeader(context, 'App Information'),
        const ListTile(
          title: Text('App Name'),
          subtitle: Text(AppConstants.appName),
        ),
        const ListTile(
          title: Text('App Version'),
          subtitle: Text(AppConstants.appVersion),
        ),
        const Divider(),

        // Appearance Settings
        _buildSectionHeader(context, 'Appearance'),
        ListTile(
          title: const Text('Theme'),
          subtitle: Text(_getThemeModeText(state.themeMode)),
          trailing: DropdownButton<ThemeMode>(
            value: state.themeMode,
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                context.read<SettingsBloc>().add(UpdateThemeMode(newMode));
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
        ),
        const Divider(),

        // Window Settings (Desktop only)
        if (!kIsWeb &&
            (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) ...[
          _buildSectionHeader(context, 'Window'),
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
        _buildSectionHeader(context, 'Notifications'),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          subtitle: const Text('Get notified when timers complete'),
          value: state.settings.notificationsEnabled,
          onChanged: (bool value) {
            context.read<SettingsBloc>().add(UpdateNotificationsEnabled(value));
          },
        ),
        SwitchListTile(
          title: const Text('Sound Effects'),
          subtitle: const Text('Play sound when timer completes'),
          value: state.settings.soundsEnabled,
          onChanged: (bool value) {
            context.read<SettingsBloc>().add(UpdateSoundsEnabled(value));
          },
        ),
        SwitchListTile(
          title: const Text('Vibration'),
          subtitle: const Text('Vibrate when timer completes'),
          value: state.settings.vibrationEnabled,
          onChanged: (bool value) {
            context.read<SettingsBloc>().add(UpdateVibrationEnabled(value));
          },
        ),
        const Divider(),

        // Calendar Integration
        _buildSectionHeader(context, 'Calendar Integration'),
        ListTile(
          title: const Text('Google Calendar'),
          subtitle: const Text('Configure calendar integration and sync'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push(Routes.calendarSettings);
          },
        ),
        const Divider(),

        // Timer Settings
        _buildSectionHeader(context, 'Timer Settings'),
        ListTile(
          title: const Text('Default Timer Duration'),
          subtitle: const Text('Configure default timer durations'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push(Routes.timerSettings);
          },
        ),
        const Divider(),

        // Sync Settings
        _buildSectionHeader(context, 'Synchronization'),
        SwitchListTile(
          title: const Text('Enable Sync'),
          subtitle: const Text('Sync your data across devices'),
          value: state.settings.syncEnabled,
          onChanged: authService.isAuthenticated
              ? (bool value) {
                  context.read<SettingsBloc>().add(UpdateSyncEnabled(value));
                }
              : null,
        ),
        if (authService.isAuthenticated) ...[
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
                final syncService = sl<SyncService>();
                final success = await syncService.syncAll();

                // Show result
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sync completed successfully'),
                      backgroundColor: AppColors.lightSecondary,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sync failed. Please try again later.'),
                      backgroundColor: AppColors.lightError,
                    ),
                  );
                }
              },
            ),
          ),
        ],
        if (!authService.isAuthenticated)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimensions.md),
            child: Text(
              'Sign in to enable synchronization',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.lightDisabled,
              ),
            ),
          ),
        const Divider(),

        // Account
        _buildSectionHeader(context, 'Account'),
        if (authService.isAuthenticated)
          ListTile(
            title: Text(authService.userEmail ?? 'User'),
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
                  await authService.signOut();
                  // Reload settings after sign out
                  if (context.mounted) {
                    context.read<SettingsBloc>().add(const LoadSettings());
                  }
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
        _buildSectionHeader(context, 'Data Management'),
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
                        foregroundColor: AppColors.lightError,
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
        _buildSectionHeader(context, 'About'),
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
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
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
    final syncService = sl<SyncService>();
    final lastSyncTime = syncService.lastSyncTime;
    
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
