import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/app/services/auth_service.dart';

/// Status of synchronization
enum SyncStatus {
  /// Not connected to the internet
  offline,

  /// Connected but not actively syncing
  idle,

  /// Currently syncing
  syncing,

  /// Last sync completed successfully
  completed,

  /// Last sync failed
  failed
}

/// Central service for managing data synchronization
class SyncService {
  // Dependencies
  final AuthService _authService;
  final SupabaseClient _supabase = Supabase.instance.client;
  final Connectivity _connectivity = Connectivity();

  // Internal state
  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;

  // Stream controller for sync status updates
  final _syncStatusController = StreamController<SyncStatus>.broadcast();

  // Stream for sync status
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  // Constructor
  SyncService(this._authService) {
    _initializeService();
  }

  // Current sync status
  SyncStatus get status => _status;

  // Last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  // Initialize the service
  Future<void> _initializeService() async {
    // Load last sync time from preferences
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimeMillis = prefs.getInt('last_sync_time');
    if (lastSyncTimeMillis != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncTimeMillis);
    }

    // Set up connectivity monitoring
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);

    // Check initial connectivity
    final connectivityResults = await _connectivity.checkConnectivity();
    _handleConnectivityChange(connectivityResults);

    // Set up automatic background sync if user is authenticated
    _setupBackgroundSync();
  }

  // Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.none)) {
      _status = SyncStatus.offline;
      _syncStatusController.add(_status);
      _cancelBackgroundSync();
    } else {
      if (_status == SyncStatus.offline) {
        _status = SyncStatus.idle;
        _syncStatusController.add(_status);
        _setupBackgroundSync();

        // Try to sync immediately when connection is restored
        if (_authService.isAuthenticated) {
          syncAll();
        }
      }
    }
  }

  // Set up background sync timer
  void _setupBackgroundSync() {
    // Only set up if user is authenticated
    if (!_authService.isAuthenticated) return;

    // Cancel existing timer if any
    _cancelBackgroundSync();

    // Create new timer for every 15 minutes
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      syncAll();
    });
  }

  // Cancel background sync timer
  void _cancelBackgroundSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Sync all data
  Future<bool> syncAll() async {
    // Skip if offline or already syncing
    if (_status == SyncStatus.offline || _isSyncing) {
      return false;
    }

    // Skip if not authenticated
    if (!_authService.isAuthenticated) {
      return false;
    }

    _isSyncing = true;
    _status = SyncStatus.syncing;
    _syncStatusController.add(_status);

    try {
      // Refresh auth session if needed
      await _authService.refreshSessionIfNeeded();

      // Sync data from all repositories
      // Using a queue approach to avoid concurrency issues
      await _syncProjects();
      await _syncTasks();
      await _syncTimerSessions();
      await _syncTimerConfigs();

      // Update last sync time
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_sync_time', _lastSyncTime!.millisecondsSinceEpoch);

      _status = SyncStatus.completed;
      _syncStatusController.add(_status);
      _isSyncing = false;
      return true;
    } catch (e) {
      debugPrint('Sync error: $e');
      _status = SyncStatus.failed;
      _syncStatusController.add(_status);
      _isSyncing = false;
      return false;
    }
  }

  // Sync projects
  Future<void> _syncProjects() async {
    // This will be implemented to sync with the project repository
    // For now we'll leave it as a placeholder
  }

  // Sync tasks
  Future<void> _syncTasks() async {
    // This will be implemented to sync with the task repository
    // For now we'll leave it as a placeholder
  }

  // Sync timer sessions
  Future<void> _syncTimerSessions() async {
    // This will be implemented to sync with the timer repository
    // For now we'll leave it as a placeholder
  }

  // Sync timer configs
  Future<void> _syncTimerConfigs() async {
    // This will be implemented to sync with the timer repository
    // For now we'll leave it as a placeholder
  }

  // Dispose the service
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}
