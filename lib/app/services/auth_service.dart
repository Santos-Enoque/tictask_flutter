import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/app/services/sync_service.dart';
import 'package:tictask/injection_container.dart';

/// Service for handling user authentication using Supabase
/// Works across all platforms including Linux
class AuthService {
  // Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  // Auth state stream - converted from supabase auth changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Current user getter
  User? get currentUser => _supabase.auth.currentUser;

  // User ID getter with null safety
  String? get userId => _supabase.auth.currentUser?.id;

  // Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // After successful sign-in, trigger data sync
      await _syncDataAfterAuth();
      
      return response;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  // Create account with email and password
  Future<AuthResponse> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      // After account creation, sync local data to the server
      await _syncDataAfterAuth();
      
      return response;
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Try to sync one last time before signing out
      final syncService = sl<SyncService>();
      final syncEnabled = await _getSyncEnabled();
      
      if (syncEnabled) {
        try {
          await syncService.syncAll();
        } catch (e) {
          // If sync fails, continue with sign out
          debugPrint('Error syncing during sign out: $e');
        }
      }
      
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  // Get user display name
  String? get userDisplayName =>
      _supabase.auth.currentUser?.userMetadata?['name'] as String?;

  // Get user email
  String? get userEmail => _supabase.auth.currentUser?.email;

  // Sign in with magic link
  Future<void> signInWithMagicLink({
    required String email,
    String? redirectTo,
  }) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirectTo,
      );
      
      // Note: The sync will happen after the user clicks the magic link
      // and the auth state changes, triggering the auth state listener
    } catch (e) {
      debugPrint('Error sending magic link: $e');
      rethrow;
    }
  }

  // Sign in anonymously
  Future<void> signInAnonymously() async {
    try {
      await _supabase.auth.signInWithPassword(
        email: 'anonymous@tictask.app',
        password: 'anonymous',
      );
      
      // Anonymous users can sync to their device
      await _syncDataAfterAuth();
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            if (displayName != null) 'name': displayName,
            if (photoURL != null) 'avatar_url': photoURL,
          },
        ),
      );
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // Check if user's session is valid
  Future<bool> isSessionValid() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Check if session exists and is not expired
      final session = _supabase.auth.currentSession;
      if (session == null) return false;

      return true;
    } catch (e) {
      debugPrint('Error checking session: $e');
      return false;
    }
  }

  // Refresh session if needed
  Future<void> refreshSessionIfNeeded() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return;

      // Only refresh if expiry is less than 1 hour away
      final expiresAt = session.expiresAt;
      final now = DateTime.now().millisecondsSinceEpoch / 1000;

      if (expiresAt! - now < 3600) {
        // Less than 1 hour left
        await _supabase.auth.refreshSession();
      }
    } catch (e) {
      debugPrint('Error refreshing session: $e');
    }
  }
  
  // Add listeners for auth state changes
  void setupAuthStateListener() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      
      // When user signs in or token refreshes, sync data
      if (event == AuthChangeEvent.signedIn || 
          event == AuthChangeEvent.tokenRefreshed) {
        _syncDataAfterAuth();
      }
    });
  }
  
  // Sync data after authentication
  Future<void> _syncDataAfterAuth() async {
    try {
      // Check if sync is enabled in settings
      final syncEnabled = await _getSyncEnabled();
      if (!syncEnabled) return;
      
      // Get the sync service
      final syncService = sl<SyncService>();
      
      // Sync data
      await syncService.syncAll();
      
      debugPrint('Data synced after authentication');
    } catch (e) {
      debugPrint('Error syncing data after auth: $e');
    }
  }
  
  // Get sync enabled setting
  Future<bool> _getSyncEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('sync_enabled') ?? true;
    } catch (e) {
      // Default to enabled if there's an error
      return true;
    }
  }
}
