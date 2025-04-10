import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleAuthService {
  static const _scopes = [
    'email',
    calendar.CalendarApi.calendarScope,
  ];
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );
  
  GoogleSignInAccount? _currentUser;
  calendar.CalendarApi? _calendarApi;
  
  // Getters
  GoogleSignInAccount? get currentUser => _currentUser;
  calendar.CalendarApi? get calendarApi => _calendarApi;
  bool get isSignedIn => _currentUser != null;
  
  // Initialize and check for existing sign-in
  Future<void> init() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        await _initCalendarApi();
      }
    } catch (e) {
      debugPrint('Error initializing Google Auth: $e');
    }
  }
  
  // Sign in with Google
  Future<bool> signIn() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        return false;
      }
      
      _currentUser = user;
      await _initCalendarApi();
      
      // Store user email for later reference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('google_user_email', user.email);
      
      return true;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
      return false;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _calendarApi = null;
      
      // Clear stored user email
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('google_user_email');
    } catch (e) {
      debugPrint('Error signing out from Google: $e');
    }
  }
  
  // Initialize Calendar API
  Future<void> _initCalendarApi() async {
    if (_currentUser == null) return;
    
    try {
      final authHeaders = await _currentUser!.authHeaders;
      final client = GoogleHttpClient(authHeaders);
      _calendarApi = calendar.CalendarApi(client);
    } catch (e) {
      debugPrint('Error initializing Calendar API: $e');
    }
  }
  
  // Method to refresh authentication if needed
  Future<bool> refreshAuth() async {
    if (_currentUser == null) {
      return await signIn();
    }
    
    try {
      await _initCalendarApi();
      return true;
    } catch (e) {
      debugPrint('Error refreshing auth: $e');
      // Try signing in again if refresh fails
      return await signIn();
    }
  }
}

// Custom HTTP Client that adds auth headers to requests
class GoogleHttpClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleHttpClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}