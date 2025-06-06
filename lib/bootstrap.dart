import 'dart:async';
import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/app/constants/app_constants.dart';
import 'package:tictask/core/services/init_supabase.dart';
import 'package:tictask/core/services/notification_service.dart';
import 'package:tictask/core/services/window_service.dart';
import 'package:tictask/core/utils/logger.dart';
import 'package:tictask/injection_container.dart' as di;

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();
  
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }
  
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };
  Bloc.observer = const AppBlocObserver();
  
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences first (needed for window settings and sync settings)
  await SharedPreferences.getInstance();
  
  // Initialize window settings for desktop platforms
  await WindowService.initWindow();
  
  // Initialize Supabase before Hive
  await initSupabase();
  
  // Initialize Hive
  await _initializeHive();
  
  // Initialize notification service
  await NotificationService().initialize();
  
  // Initialize dependency injection - this must be after Hive and Supabase
  await di.init();
  
 
  
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.e('Flutter error', details.exception, details.stack);
  };
  
  // Add cross-flavor configuration here
  runApp(await builder());
}

/// Initialize Hive for local storage
Future<void> _initializeHive() async {
  try {
    // Initialize Hive for Flutter (this works for all platforms including web)
    await Hive.initFlutter();
    
    // TEMPORARY FIX: Clear all boxes to resolve the type mismatch issue
    // Delete this after the first successful run
    // await Hive.deleteBoxFromDisk(AppConstants.settingsBox);
    // await Hive.deleteBoxFromDisk('tasks');
    // await Hive.deleteBoxFromDisk('timer_settings');
    // await Hive.deleteBoxFromDisk('user_settings');
    
    // Note: The actual adapter registrations will be done in the repository
    // to avoid circular dependencies
    AppLogger.i('Hive initialized successfully');
  } catch (e, stack) {
    AppLogger.e('Failed to initialize Hive', e, stack);
    rethrow;
  }
}