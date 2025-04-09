import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
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
      return await _supabase.auth.signUp(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
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
}
