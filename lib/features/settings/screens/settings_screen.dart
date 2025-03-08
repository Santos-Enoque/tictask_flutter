import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tictask/app/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.showNavBar = true});

  final bool showNavBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildThemeSection(context),
          const Divider(),
          _buildNotificationsSection(context),
        ],
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    final currentThemeMode =
        context.select((ThemeBloc bloc) => bloc.state.themeMode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        RadioListTile<ThemeMode>(
          title: Row(
            children: [
              Icon(
                Icons.brightness_auto,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              const Text('System'),
            ],
          ),
          value: ThemeMode.system,
          groupValue: currentThemeMode,
          onChanged: (value) {
            if (value != null) {
              context.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              const Text('Light'),
            ],
          ),
          value: ThemeMode.light,
          groupValue: currentThemeMode,
          onChanged: (value) {
            if (value != null) {
              context.setThemeMode(value);
            }
          },
        ),
        RadioListTile<ThemeMode>(
          title: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              const Text('Dark'),
            ],
          ),
          value: ThemeMode.dark,
          groupValue: currentThemeMode,
          onChanged: (value) {
            if (value != null) {
              context.setThemeMode(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    // This would ideally be controlled by a settings bloc
    // For now, it's just a placeholder
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Notifications',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        SwitchListTile(
          title: const Text('Enable Notifications'),
          value: true, // This should come from settings repository
          onChanged: (value) {
            // Update settings
          },
        ),
      ],
    );
  }
}
