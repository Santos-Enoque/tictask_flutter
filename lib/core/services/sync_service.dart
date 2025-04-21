// lib/core/services/sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:tictask/core/services/auth_service.dart';
import 'package:tictask/features/timer/domain/repositories/i_syncable_timer_repository.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:tictask/features/projects/domain/repositories/i_syncable_project_repository.dart';
import 'package:tictask/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Connectivity _connectivity = Connectivity();

  // Repositories to sync
  late final ITaskRepository _taskRepository;
  late final ISyncableProjectRepository _projectRepository;
  late final ISyncableTimerRepository _timerRepository;

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
    final result = results.first;
    if (result == ConnectivityResult.none) {
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
  void _setupBackgroundSync() async {
    // Only set up if user is authenticated
    if (!_authService.isAuthenticated) return;

    // Only set up if sync is enabled in settings
    final prefs = await SharedPreferences.getInstance();
    final syncEnabled = prefs.getBool('sync_enabled') ?? true;
    if (!syncEnabled) return;

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

  // Set repositories
  void setRepositories({
    required ITaskRepository taskRepository,
    required ISyncableProjectRepository projectRepository,
    required ISyncableTimerRepository timerRepository,
  }) {
    _taskRepository = taskRepository;
    _projectRepository = projectRepository;
    _timerRepository = timerRepository;
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

    // Check if sync is enabled in settings
    final prefs = await SharedPreferences.getInstance();
    final syncEnabled = prefs.getBool('sync_enabled') ?? true;
    if (!syncEnabled) {
      return false;
    }

    _isSyncing = true;
    _status = SyncStatus.syncing;
    _syncStatusController.add(_status);

    try {
      // Refresh auth session if needed
      await _authService.refreshSessionIfNeeded();

      // First pull updates from server to get the latest data
      await _pullChanges();

      // Then push local changes to server
      await _pushChanges();

      // Update last sync time
      _lastSyncTime = DateTime.now();
      await prefs.setInt(
          'last_sync_time', _lastSyncTime!.millisecondsSinceEpoch);

      _status = SyncStatus.completed;
      _syncStatusController.add(_status);
      _isSyncing = false;
      return true;
    } catch (e) {
      AppLogger.e('Sync error: $e');
      _status = SyncStatus.failed;
      _syncStatusController.add(_status);
      _isSyncing = false;
      return false;
    }
  }

  // Pull changes from server
  Future<void> _pullChanges() async {
    try {
      // Pull in a specific order to handle dependencies
      // Projects first, then tasks, then timer sessions
      await _projectRepository.pullChanges();
      await _taskRepository.pullChanges();
      await _timerRepository.pullChanges();
    } catch (e) {
      AppLogger.e('Error pulling changes: $e');
      throw Exception('Failed to pull changes: $e');
    }
  }

  // Push changes to server
  Future<void> _pushChanges() async {
    try {
      // First try to sync the Inbox project specifically
      try {
        await _projectRepository.syncInboxProject();
      } catch (e) {
        AppLogger.w('Warning: Failed to sync Inbox project: $e');
        // Continue with other syncs even if Inbox sync fails
      }

      // Then push changes for other repositories
      await _projectRepository.pushChanges();
      await _taskRepository.pushChanges();
      await _timerRepository.pushChanges();

      // Also sync timer configuration
      await _timerRepository.syncTimerConfig();
    } catch (e) {
      AppLogger.e('Error pushing changes: $e');
      throw Exception('Failed to push changes: $e');
    }
  }

  // Restart background sync (called when settings change)
  void restartBackgroundSync() {
    _cancelBackgroundSync();
    _setupBackgroundSync();
  }

  // Dispose the service
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}
