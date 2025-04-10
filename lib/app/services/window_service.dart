import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
/// Service for managing window properties on desktop platforms
class WindowService {
  // Default window size
  static const Size defaultWindowSize = Size(400, 800);
  static const Size defaultMinWindowSize = Size(320, 600);
  static const Size defaultMaxWindowSize = Size(800, 1200);

  /// Initialize window settings
  /// Must be called before runApp()
  static Future<void> initWindow() async {
    // Only apply window settings on desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      // Initialize windowManager
      await windowManager.ensureInitialized();

      // Set window title
      const windowTitle = 'TicTask';

      // Default window options
      WindowOptions windowOptions = WindowOptions(
        size: defaultWindowSize,
        minimumSize: defaultMinWindowSize,
        maximumSize: defaultMaxWindowSize,
        center: true,
        backgroundColor: const Color(0x00000000),
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
        title: windowTitle,
      );

      // Apply window settings
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  /// Set window size
  static Future<void> setWindowSize(Size size) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
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
      await windowManager.setResizable(resizable);
    }
  }

  /// Set window always on top
  static Future<void> setAlwaysOnTop(bool alwaysOnTop) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      await windowManager.setAlwaysOnTop(alwaysOnTop);
    }
  }

  /// Set window center position
  static Future<void> centerWindow() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      await windowManager.center();
    }
  }
}