import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/app/constants/app_constants.dart';
// This function initializes Supabase once at app startup
Future<void> initSupabase() async {
  try {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
      debug: kDebugMode,
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }
}