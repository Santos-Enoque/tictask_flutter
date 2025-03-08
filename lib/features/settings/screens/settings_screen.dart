import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  late Future<TimerConfig> _timerConfigFuture;

  @override
  void initState() {
    super.initState();
    _timerConfigFuture = _timerRepository.getTimerConfig();
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
              _buildTimerSettingsSection(context, timerConfig),
              const SizedBox(height: 20),
              _buildSystemSettingsSection(context),
            ],
          );
        },
      ),
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
