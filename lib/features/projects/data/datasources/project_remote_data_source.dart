
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tictask/features/projects/data/models/project_model.dart';

abstract class ProjectRemoteDataSource {
  Future<List<ProjectModel>> getAllProjects();
  Future<ProjectModel?> getProjectById(String id);
  Future<void> saveProject(ProjectModel project);
  Future<void> deleteProject(String id);
  Future<int> pushChanges(Set<String> pendingSyncIds, Set<String> deletedIds, Map<String, ProjectModel> localProjects);
  Future<List<ProjectModel>> pullChanges(DateTime? lastSyncTime);
  Future<void> saveInboxProject(ProjectModel inboxProject);
  Future<void> setLastSyncTime(DateTime time);
  Future<DateTime?> getLastSyncTime();
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  ProjectRemoteDataSourceImpl({
    required this.supabase,
    required this.userId,
  });
  
  final SupabaseClient supabase;
  final String userId;
  
  static const String _tableName = 'projects';
  static const String _lastSyncTimeKey = 'projects_last_sync_time';
  
  @override
  Future<List<ProjectModel>> getAllProjects() async {
    final response = await supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId);
        
    return (response as List)
        .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
  
  @override
  Future<ProjectModel?> getProjectById(String id) async {
    final response = await supabase
        .from(_tableName)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
        
    if (response == null) return null;
    return ProjectModel.fromJson(response as Map<String, dynamic>);
  }
  
  @override
  Future<void> saveProject(ProjectModel project) async {
    final projectMap = project.toJson(userId: userId);
    
    await supabase
        .from(_tableName)
        .upsert(projectMap);
  }
  
  @override
  Future<void> deleteProject(String id) async {
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
    Map<String, ProjectModel> localProjects
  ) async {
    var syncCount = 0;
    
    // Process updates
    if (pendingSyncIds.isNotEmpty) {
      for (final id in pendingSyncIds) {
        final project = localProjects[id];
        if (project != null) {
          // Skip if this project is also marked for deletion
          if (deletedIds.contains(id)) {
            continue;
          }
          
          // Push to Supabase
          final projectMap = project.toJson(userId: userId);
          await supabase.from(_tableName).upsert(projectMap);
          
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
  Future<List<ProjectModel>> pullChanges(DateTime? lastSyncTime) async {
    final timestamp = lastSyncTime?.millisecondsSinceEpoch ?? 0;
    
    final response = await supabase
        .from(_tableName)
        .select()
        .eq('user_id', userId)
        .gte('updated_at', timestamp);
        
    return (response as List)
        .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
  
  @override
  Future<void> saveInboxProject(ProjectModel inboxProject) async {
    final projectMap = inboxProject.toJson(userId: userId);
    
    await supabase
        .from(_tableName)
        .upsert(projectMap)
        .eq('id', 'inbox');
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
