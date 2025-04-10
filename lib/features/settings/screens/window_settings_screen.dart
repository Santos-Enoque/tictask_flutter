import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/app/services/window_service.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/app/theme/text_styles.dart';

class WindowSettingsScreen extends StatefulWidget {
  const WindowSettingsScreen({Key? key}) : super(key: key);

  @override
  State<WindowSettingsScreen> createState() => _WindowSettingsScreenState();
}

class _WindowSettingsScreenState extends State<WindowSettingsScreen> {
  // Window size presets
  final List<Map<String, dynamic>> _windowSizePresets = [
    {'name': 'Small (Phone)', 'size': const Size(360, 720)},
    {'name': 'Medium (Tablet)', 'size': const Size(600, 900)},
    {'name': 'Large (Desktop)', 'size': const Size(800, 1000)},
  ];

  // Current window size
  Size _windowSize = WindowService.defaultWindowSize;

  // Always on top setting
  bool _alwaysOnTop = false;

  // Is desktop platform
  bool get _isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Load saved window settings
  Future<void> _loadSettings() async {
    if (!_isDesktopPlatform) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _windowSize = Size(
        prefs.getDouble('window_width') ?? WindowService.defaultWindowSize.width,
        prefs.getDouble('window_height') ?? WindowService.defaultWindowSize.height,
      );
      _alwaysOnTop = prefs.getBool('window_always_on_top') ?? false;
    });
  }

  // Save window settings
  Future<void> _saveSettings() async {
    if (!_isDesktopPlatform) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('window_width', _windowSize.width);
    await prefs.setDouble('window_height', _windowSize.height);
    await prefs.setBool('window_always_on_top', _alwaysOnTop);
  }

  // Set window size
  Future<void> _applyWindowSize(Size size) async {
    if (!_isDesktopPlatform) return;

    setState(() {
      _windowSize = size;
    });

    await WindowService.setWindowSize(size);
    await _saveSettings();
  }

  // Set always on top
  Future<void> _setAlwaysOnTop(bool value) async {
    if (!_isDesktopPlatform) return;

    setState(() {
      _alwaysOnTop = value;
    });

    await WindowService.setAlwaysOnTop(value);
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopPlatform) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Text(
            'Window settings are only available on desktop platforms.',
            style: AppTextStyles.bodyLarge(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Window Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.md),
        children: [
          // Window size settings
          Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Window Size',
                    style: AppTextStyles.titleMedium(context),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  // Window size presets
                  Wrap(
                    spacing: AppDimensions.sm,
                    children: _windowSizePresets.map((preset) {
                      final Size size = preset['size'] as Size;
                      return ElevatedButton(
                        onPressed: () => _applyWindowSize(size),
                        child: Text('${preset['name']}'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  // Custom size
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _windowSize.width.toStringAsFixed(0),
                          decoration: const InputDecoration(
                            labelText: 'Width',
                            suffixText: 'px',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final double? width = double.tryParse(value);
                            if (width != null) {
                              _windowSize = Size(width, _windowSize.height);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppDimensions.md),
                      Expanded(
                        child: TextFormField(
                          initialValue: _windowSize.height.toStringAsFixed(0),
                          decoration: const InputDecoration(
                            labelText: 'Height',
                            suffixText: 'px',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final double? height = double.tryParse(value);
                            if (height != null) {
                              _windowSize = Size(_windowSize.width, height);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),
                  ElevatedButton(
                    onPressed: () => _applyWindowSize(_windowSize),
                    child: const Text('Apply Custom Size'),
                  ),
                ],
              ),
            ),
          ),
          // Window behavior
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Window Behavior',
                    style: AppTextStyles.titleMedium(context),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  // Always on top
                  SwitchListTile(
                    title: const Text('Always on Top'),
                    subtitle: const Text(
                      'Keep the window above other windows',
                    ),
                    value: _alwaysOnTop,
                    onChanged: _setAlwaysOnTop,
                  ),
                  // Center window
                  ListTile(
                    title: const Text('Center Window'),
                    subtitle: const Text('Center the window on the screen'),
                    trailing: IconButton(
                      icon: const Icon(Icons.center_focus_strong),
                      onPressed: () async {
                        await WindowService.centerWindow();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.md),
          // Reset button
          OutlinedButton(
            onPressed: () async {
              await WindowService.setWindowSize(WindowService.defaultWindowSize);
              await WindowService.setAlwaysOnTop(false);
              await WindowService.centerWindow();
              
              setState(() {
                _windowSize = WindowService.defaultWindowSize;
                _alwaysOnTop = false;
              });
              
              await _saveSettings();
            },
            child: const Text('Reset to Defaults'),
          ),
        ],
      ),
    );
  }
}