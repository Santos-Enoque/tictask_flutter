import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/core/utils/logger.dart';
import 'package:tictask/features/timer/data/models/timer_config_model.dart';
import 'package:tictask/features/timer/data/models/timer_session_model.dart';

abstract class TimerRemoteDataSource {
  Future<List<TimerSessionModel>> getAllSessions();
  Future<TimerSessionModel?> getSessionById(String id);
  Future<void> saveSession(TimerSessionModel session);
  Future<void> deleteSession(String id);
  Future<void> saveTimerConfig(TimerConfigModel config, String userId);
  Future<TimerConfigModel?> getTimerConfig(String userId);
  Future<List<TimerSessionModel>> getSessionsSince(DateTime? lastSyncTime, String userId);
  Future<void> setLastSyncTime(DateTime time, String userId);
  Future<DateTime?> getLastSyncTime(String userId);
  Future<void> deleteSessionsMarkedForDeletion(List<String> ids, String userId);
}

class TimerRemoteDataSourceImpl implements TimerRemoteDataSource {
  final SupabaseClient supabase;
  final String userId;
  static const String _sessionsTableName = 'timer_sessions';
  static const String _configsTableName = 'timer_configs';
  static const String _lastSyncTimeKey = 'timer_sessions_last_sync_time';

  TimerRemoteDataSourceImpl({
    required this.supabase,
    required this.userId,
  });

  @override
  Future<List<TimerSessionModel>> getAllSessions() async {
    final response = await supabase
        .from(_sessionsTableName)
        .select()
        .eq('user_id', userId);

    return (response as List)
        .map((item) => TimerSessionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TimerSessionModel?> getSessionById(String id) async {
    final response = await supabase
        .from(_sessionsTableName)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return TimerSessionModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> saveSession(TimerSessionModel session) async {
    final sessionMap = session.toJson();
    sessionMap['user_id'] = userId;

    await supabase
        .from(_sessionsTableName)
        .upsert(sessionMap);
  }

  @override
  Future<void> deleteSession(String id) async {
    await supabase
        .from(_sessionsTableName)
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  @override
  Future<void> saveTimerConfig(TimerConfigModel config, String userId) async {
    try {
      final configMap = config.toJson();
      configMap['id'] = '${config.id}_$userId'; // Make it unique per user
      configMap['user_id'] = userId;
      configMap['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      await supabase.from(_configsTableName).upsert(configMap);
      AppLogger.i('Timer config synced successfully');
    } catch (e) {
      AppLogger.e('Error saving timer config to remote: $e');
      rethrow;
    }
  }

  @override
  Future<TimerConfigModel?> getTimerConfig(String userId) async {
    try {
      final response = await supabase
          .from(_configsTableName)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response == null) return null;
      
      return TimerConfigModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      AppLogger.e('Error getting timer config from remote: $e');
      return null;
    }
  }

  @override
  Future<List<TimerSessionModel>> getSessionsSince(DateTime? lastSyncTime, String userId) async {
    final timestamp = lastSyncTime?.millisecondsSinceEpoch ?? 0;

    final response = await supabase
        .from(_sessionsTableName)
        .select()
        .eq('user_id', userId)
        .gte('end_time', timestamp);

    return (response as List)
        .map((item) => TimerSessionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DateTime?> getLastSyncTime(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastSyncTimeKey}_$userId';
    final timestamp = prefs.getInt(key);

    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  @override
  Future<void> setLastSyncTime(DateTime time, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastSyncTimeKey}_$userId';
    await prefs.setInt(key, time.millisecondsSinceEpoch);
  }

  @override
  Future<void> deleteSessionsMarkedForDeletion(List<String> ids, String userId) async {
    if (ids.isEmpty) return;
    
    for (final id in ids) {
      await supabase
          .from(_sessionsTableName)
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    }
  }
}