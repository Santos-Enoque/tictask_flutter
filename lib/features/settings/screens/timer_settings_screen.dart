import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/features/timer/bloc/timer_bloc.dart';
import 'package:tictask/features/timer/models/timer_config.dart';
import 'package:tictask/features/timer/repositories/timer_repository.dart';
import 'package:tictask/injection_container.dart';

class TimerSettingsScreen extends StatefulWidget {
  const TimerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<TimerSettingsScreen> createState() => _TimerSettingsScreenState();
}

class _TimerSettingsScreenState extends State<TimerSettingsScreen> {
  final TimerRepository _timerRepository = sl<TimerRepository>();

  late int _pomoDuration;
  late int _shortBreakDuration;
  late int _longBreakDuration;
  late int _longBreakInterval;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTimerConfig();
  }

  Future<void> _loadTimerConfig() async {
    final config = await _timerRepository.getTimerConfig();
    setState(() {
      _pomoDuration = config.pomodoroDurationInMinutes;
      _shortBreakDuration = config.shortBreakDurationInMinutes;
      _longBreakDuration = config.longBreakDurationInMinutes;
      _longBreakInterval = config.longBreakInterval;
      _isLoading = false;
    });
  }

  Future<void> _saveTimerConfig() async {
    setState(() {
      _isLoading = true;
    });

    final newConfig = TimerConfig(
      pomoDuration: _pomoDuration * 60,
      shortBreakDuration: _shortBreakDuration * 60,
      longBreakDuration: _longBreakDuration * 60,
      longBreakInterval: _longBreakInterval,
    );

    await _timerRepository.saveTimerConfig(newConfig);

    // Update timer bloc with new configuration
    if (mounted) {
      context.read<TimerBloc>().add(TimerConfigChanged(config: newConfig));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timer settings saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTimerConfig,
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Pomodoro Technique Settings'),
                  const SizedBox(height: AppDimensions.sm),
                  const Text(
                    'Configure the duration of your focus sessions and breaks',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  _buildDurationSetting(
                    title: 'Focus Duration',
                    subtitle: 'Time spent working on tasks',
                    value: _pomoDuration,
                    min: 1,
                    max: 120,
                    onChanged: (value) {
                      setState(() {
                        _pomoDuration = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildDurationSetting(
                    title: 'Short Break Duration',
                    subtitle: 'Brief rest between focus sessions',
                    value: _shortBreakDuration,
                    min: 1,
                    max: 30,
                    onChanged: (value) {
                      setState(() {
                        _shortBreakDuration = value;
                      });
                    },
                  ),
                  const Divider(),
                  _buildDurationSetting(
                    title: 'Long Break Duration',
                    subtitle: 'Extended rest after multiple focus sessions',
                    value: _longBreakDuration,
                    min: 1,
                    max: 60,
                    onChanged: (value) {
                      setState(() {
                        _longBreakDuration = value;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Long Break Interval'),
                    subtitle: const Text(
                        'Number of focus sessions before a long break'),
                    trailing: DropdownButton<int>(
                      value: _longBreakInterval,
                      items: List.generate(10, (index) => index + 1)
                          .map((value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value sessions'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _longBreakInterval = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  const Text(
                    'Changes will apply to the next timer you start.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDurationSetting({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Text('$value minutes'),
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$value minutes',
          onChanged: (newValue) {
            onChanged(newValue.round());
          },
        ),
      ],
    );
  }
}
