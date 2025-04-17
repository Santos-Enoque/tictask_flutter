import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/core/services/window_service.dart';
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
    {'name': 'Small (Phone)', 'value': 'small', 'size': WindowService.windowSizePresets['small']!},
    {'name': 'Medium (Tablet)', 'value': 'medium', 'size': WindowService.windowSizePresets['medium']!},
    {'name': 'Large (Desktop)', 'value': 'large', 'size': WindowService.windowSizePresets['large']!},
  ];

  // Current window size
  Size _windowSize = WindowService.defaultWindowSize;
  
  // Selected preset
  String? _selectedPreset;

  // Window settings
  bool _alwaysOnTop = false;
  bool _resizable = false;

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
      _resizable = prefs.getBool('window_resizable') ?? false;
      _selectedPreset = prefs.getString('window_preset');
    });
  }

  // Apply preset window size
  Future<void> _applyWindowSizePreset(String presetName) async {
    if (!_isDesktopPlatform) return;

    // Only enable resizable when in settings
    await WindowService.setResizable(true);
    
    // Apply the preset size
    await WindowService.setWindowSizePreset(presetName);
    
    // Reload settings
    await _loadSettings();
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Window size set to ${_getPresetName(presetName)}')),
      );
    }
  }

  // Apply custom window size
  Future<void> _applyCustomSize() async {
    if (!_isDesktopPlatform) return;

    // Only enable resizable when in settings
    await WindowService.setResizable(true);
    
    // Apply custom size
    await WindowService.setWindowSize(_windowSize);
    
    // Clear preset selection
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('window_preset');
    
    setState(() {
      _selectedPreset = null;
    });

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom window size applied')),
      );
    }
  }

  // Set always on top
  Future<void> _setAlwaysOnTop(bool value) async {
    if (!_isDesktopPlatform) return;

    setState(() {
      _alwaysOnTop = value;
    });

    await WindowService.setAlwaysOnTop(value);
  }

  // Set window resizable
  Future<void> _setResizable(bool value) async {
    if (!_isDesktopPlatform) return;

    setState(() {
      _resizable = value;
    });

    await WindowService.setResizable(value);
  }

  // Helper to get preset name from value
  String _getPresetName(String presetValue) {
    final preset = _windowSizePresets.firstWhere(
      (preset) => preset['value'] == presetValue,
      orElse: () => {'name': 'Unknown'},
    );
    return preset['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktopPlatform) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Window Settings'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.lg),
            child: Text(
              'Window settings are only available on desktop platforms.',
              textAlign: TextAlign.center,
            ),
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
          // Explanation text
          Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Window Options',
                    style: AppTextStyles.titleMedium(context),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  const Text(
                    'The window is non-resizable by default for a consistent experience, '
                    'but you can enable resizing here if needed. Window size settings will '
                    'be remembered across app restarts.',
                  ),
                ],
              ),
            ),
          ),

          // Window size presets
          Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Window Size Presets',
                    style: AppTextStyles.titleMedium(context),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  // Window size presets
                  Wrap(
                    spacing: AppDimensions.sm,
                    runSpacing: AppDimensions.sm,
                    children: _windowSizePresets.map((preset) {
                      final String presetValue = preset['value'] as String;
                      final bool isSelected = _selectedPreset == presetValue;
                      
                      return ElevatedButton(
                        onPressed: () => _applyWindowSizePreset(presetValue),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : null,
                          foregroundColor: isSelected
                              ? Theme.of(context).colorScheme.onPrimary
                              : null,
                        ),
                        child: Text('${preset['name']}'),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  Text(
                    'Current Preset: ${_selectedPreset != null ? _getPresetName(_selectedPreset!) : 'Custom Size'}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Custom size
          Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Custom Window Size',
                    style: AppTextStyles.titleMedium(context),
                  ),
                  const SizedBox(height: AppDimensions.md),
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
                              setState(() {
                                _windowSize = Size(width, _windowSize.height);
                              });
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
                              setState(() {
                                _windowSize = Size(_windowSize.width, height);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.md),
                  ElevatedButton(
                    onPressed: _applyCustomSize,
                    child: const Text('Apply Custom Size'),
                  ),
                ],
              ),
            ),
          ),

          // Window behavior
          Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.md),
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
                  
                  // Resizable option
                  SwitchListTile(
                    title: const Text('Enable Resizing'),
                    subtitle: const Text(
                      'Allow manual window resizing (applies after leaving settings)',
                    ),
                    value: _resizable,
                    onChanged: _setResizable,
                  ),
                  
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Window centered')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Reset button
          OutlinedButton(
            onPressed: () async {
              // Show confirmation dialog
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Window Settings'),
                  content: const Text(
                    'This will reset all window settings to default values. Continue?'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await WindowService.resetToDefaults();
                await _loadSettings();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Window settings reset to defaults')),
                  );
                }
              }
            },
            child: const Text('Reset to Defaults'),
          ),
        ],
      ),
    );
  }
}