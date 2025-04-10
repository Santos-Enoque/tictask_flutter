import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing window properties on desktop platforms
class WindowService {
  // Default window size
  static const Size defaultWindowSize = Size(400, 800);
  static const Size defaultMinWindowSize = Size(320, 600);
  static const Size defaultMaxWindowSize = Size(800, 1200);

  // Preset window sizes
  static const Map<String, Size> windowSizePresets = {
    'small': Size(360, 720),   // Phone
    'medium': Size(600, 900),  // Tablet
    'large': Size(800, 1000),  // Desktop
  };

  // Preference keys
  static const String windowWidthKey = 'window_width';
  static const String windowHeightKey = 'window_height';
  static const String windowAlwaysOnTopKey = 'window_always_on_top';
  static const String windowResizableKey = 'window_resizable';
  static const String windowPresetKey = 'window_preset';

  /// Initialize window settings
  /// Must be called before runApp()
  static Future<void> initWindow() async {
    // Only apply window settings on desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // Initialize windowManager
      await windowManager.ensureInitialized();

      // Set window title
      const windowTitle = 'TicTask';

      // Load saved settings
      final prefs = await SharedPreferences.getInstance();
      
      // Get window size
      final double width = prefs.getDouble(windowWidthKey) ?? defaultWindowSize.width;
      final double height = prefs.getDouble(windowHeightKey) ?? defaultWindowSize.height;
      final Size windowSize = Size(width, height);

      // Get other window properties
      final bool alwaysOnTop = prefs.getBool(windowAlwaysOnTopKey) ?? false;
      
      // Default window options - without resizable parameter
      WindowOptions windowOptions = WindowOptions(
        size: windowSize,
        minimumSize: defaultMinWindowSize,
        maximumSize: defaultMaxWindowSize,
        center: true,
        backgroundColor: const Color(0x00000000),
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: windowTitle,
        alwaysOnTop: alwaysOnTop,
      );

      // Apply window settings
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
        
        // Set resizability after the window is shown
        // Get saved setting or default to false
        final bool resizable = prefs.getBool(windowResizableKey) ?? false;
        await windowManager.setResizable(resizable);
      });
    }
  }

  /// Set window size with preset name
  static Future<void> setWindowSizePreset(String presetName) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      final prefs = await SharedPreferences.getInstance();
      
      // Store the preset name for future reference
      await prefs.setString(windowPresetKey, presetName);
      
      // Get the actual size from presets
      if (windowSizePresets.containsKey(presetName)) {
        final size = windowSizePresets[presetName]!;
        await setWindowSize(size);
      }
    }
  }

  /// Set window size
  static Future<void> setWindowSize(Size size) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // Save the size in preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(windowWidthKey, size.width);
      await prefs.setDouble(windowHeightKey, size.height);
      
      // Apply to window
      await windowManager.setSize(size);
    }
  }

  /// Set minimum window size
  static Future<void> setMinimumWindowSize(Size size) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      await windowManager.setMinimumSize(size);
    }
  }

  /// Set maximum window size
  static Future<void> setMaximumWindowSize(Size size) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      await windowManager.setMaximumSize(size);
    }
  }

  /// Enable or disable resizing
  static Future<void> setResizable(bool resizable) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // Save the setting in preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(windowResizableKey, resizable);
      
      // Apply to window
      await windowManager.setResizable(resizable);
    }
  }

  /// Set window always on top
  static Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // Save the setting in preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(windowAlwaysOnTopKey, alwaysOnTop);
      
      // Apply to window
      await windowManager.setAlwaysOnTop(alwaysOnTop);
    }
  }

  /// Set window center position
  static Future<void> centerWindow() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      await windowManager.center();
    }
  }
  
  /// Get current window size preset
  static Future<String?> getCurrentWindowPreset() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(windowPresetKey);
    }
    return null;
  }
  
  /// Reset all window settings to defaults
  static Future<void> resetToDefaults() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear saved settings
      await prefs.remove(windowWidthKey);
      await prefs.remove(windowHeightKey);
      await prefs.remove(windowAlwaysOnTopKey);
      await prefs.remove(windowResizableKey);
      await prefs.remove(windowPresetKey);
      
      // Apply default settings
      await setWindowSize(defaultWindowSize);
      await setAlwaysOnTop(false);
      await setResizable(false);
      await centerWindow();
    }
  }
}