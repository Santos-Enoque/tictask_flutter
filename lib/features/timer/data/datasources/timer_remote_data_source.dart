import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/features/timer/data/models/timer_config_model.dart';
import 'package:tictask/features/timer/data/models/timer_session_model.dart';

abstract class TimerRemoteDataSource {
  /// Get all timer sessions for a user
  Future<List<TimerSessionModel>> getAllSessions();
  
  /// Get a specific timer session
  Future<TimerSessionModel?> getSessionById(String id);
  
  /// Save a timer session
  Future<void> saveSession(TimerSessionModel session);
  
  /// Delete a timer session
  Future<void> deleteSession(String id);
  
  /// Push changes in bulk
  Future<int> pushChanges(
    Set<String> pendingSyncIds,
    Set<String> deletedIds,
    Map<String, TimerSessionModel> localSessions
  );
  
  /// Pull changes since last sync
  Future<List<TimerSessionModel>> pullChanges(DateTime? lastSyncTime);
  
  /// Save timer configuration
  Future<void> saveTimerConfig(TimerConfigModel config);
  
  /// Get timer configuration
  Future<TimerConfigModel?> getTimerConfig();
  
  /// Get last sync time
  Future<DateTime?> getLastSyncTime();
  
  /// Set last sync time
  Future<void> setLastSyncTime(DateTime time);
}

class TimerRemoteDataSourceImpl implements TimerRemoteDataSource {
  TimerRemoteDataSourceImpl({
    required this.supabase,
    required this.userId,
  });
  
  final SupabaseClient supabase;
  final String userId;
  
  static const String _tableName = 'timer_sessions';
  static const String _configTableName = 'timer_configs';
  static const String _lastSyncTimeKey = 'timer_sessions_last_sync_time';
  
  @override
  Future<List<TimerSessionModel>> getAllSessions() async {
    final response = await supabase
      .from(_tableName)
      .select()
      .eq('user_id', userId);
      
    return (response as List)
      .map((item) => TimerSessionModel.fromJson(item as Map<String, dynamic>))
      .toList();
  }
  
  @override
  Future<TimerSessionModel?> getSessionById(String id) async {
    final response = await supabase
      .from(_tableName)
      .select()
      .eq('id', id)
      .eq('user_id', userId)
      .maybeSingle();
      
    if (response == null) return null;
    return TimerSessionModel.fromJson(response as Map<String, dynamic>);
  }
  
  @override
  Future<void> saveSession(TimerSessionModel session) async {
    final sessionMap = session.toJson(userId: userId);
    
    await supabase
      .from(_tableName)
      .upsert(sessionMap);
  }
  
  @override
  Future<void> deleteSession(String id) async {
    await supabase
      .from(_tableName)
      .delete()
      .eq('id', id)
      .eq('user_id', userId);
  }
  
  @override
  Future<int> pushChanges(
    Set<String> pendingSyncIds,
    Set<String> deletedIds,
    Map<String, TimerSessionModel> localSessions
  ) async {
    var syncCount = 0;
    
    // Process updates
    if (pendingSyncIds.isNotEmpty) {
      for (final id in pendingSyncIds) {
        final session = localSessions[id];
        if (session != null) {
          // Skip if this session is also marked for deletion
          if (deletedIds.contains(id)) {
            continue;
          }
          
          // Push to Supabase
          final sessionMap = session.toJson(userId: userId);
          await supabase.from(_tableName).upsert(sessionMap);
          
          syncCount++;
        }
      }
    }
    
    // Process deletions
    if (deletedIds.isNotEmpty) {
      for (final id in deletedIds) {
        await supabase
          .from(_tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
          
        syncCount++;
      }
    }
    
    return syncCount;
  }
  
  @override
  Future<List<TimerSessionModel>> pullChanges(DateTime? lastSyncTime) async {
    final timestamp = lastSyncTime?.millisecondsSinceEpoch ?? 0;
    
    final response = await supabase
      .from(_tableName)
      .select()
      .eq('user_id', userId)
      .gte('end_time', timestamp);
      
    return (response as List)
      .map((item) => TimerSessionModel.fromJson(item as Map<String, dynamic>))
      .toList();
  }
  
  @override
  Future<void> saveTimerConfig(TimerConfigModel config) async {
    final configMap = config.toJson();
    configMap['user_id'] = userId;
    configMap['id'] = '${config.id}_$userId'; // Make it unique per user
    
    await supabase
      .from(_configTableName)
      .upsert(configMap);
  }
  
  @override
  Future<TimerConfigModel?> getTimerConfig() async {
    final response = await supabase
      .from(_configTableName)
      .select()
      .eq('user_id', userId)
      .maybeSingle();
      
    if (response == null) return null;
    return TimerConfigModel.fromJson(response as Map<String, dynamic>);
  }
  
  @override
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastSyncTimeKey}_$userId';
    final timestamp = prefs.getInt(key);
    
    return timestamp != null
      ? DateTime.fromMillisecondsSinceEpoch(timestamp)
      : null;
  }
  
  @override
  Future<void> setLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastSyncTimeKey}_$userId';
    await prefs.setInt(key, time.millisecondsSinceEpoch);
  }
}