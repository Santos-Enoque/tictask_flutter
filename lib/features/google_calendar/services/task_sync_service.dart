import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';

import 'google_auth_service.dart';
import 'google_calendar_service.dart';

class TaskSyncService {
  final GoogleAuthService _authService;
  final GoogleCalendarService _calendarService;
  final TaskRepository _taskRepository;
  
  // Map to store task ID to Google Calendar event ID
  Map<String, String> _taskEventMap = {};
  
  // Status for sync
  bool _isSyncing = false;
  
  // Constructor
  TaskSyncService(
    this._authService,
    this._calendarService,
    this._taskRepository,
  );
  
  // Initialize and load task-event mappings
  Future<void> init() async {
    await _loadTaskEventMappings();
  }
  
  // Load mappings from SharedPreferences
  Future<void> _loadTaskEventMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappings = prefs.getStringList('task_event_mappings') ?? [];
      
      _taskEventMap = {};
      for (final mapping in mappings) {
        final parts = mapping.split(':');
        if (parts.length == 2) {
          _taskEventMap[parts[0]] = parts[1];
        }
      }
      
      debugPrint('Loaded task-event mappings: $_taskEventMap');
    } catch (e) {
      debugPrint('Error loading task-event mappings: $e');
    }
  }
  
  // Save mappings to SharedPreferences
  Future<void> _saveTaskEventMappings() async {
    try {
      final mappings = _taskEventMap.entries
          .map((e) => '${e.key}:${e.value}')
          .toList();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('task_event_mappings', mappings);
    } catch (e) {
      debugPrint('Error saving task-event mappings: $e');
    }
  }
  
  // Check if sync is enabled
  Future<bool> isSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('calendar_sync_enabled') ?? true;
  }
  
  // Set sync enabled status
  Future<void> setSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_sync_enabled', enabled);
  }
  
  // Check if two-way sync is enabled
  Future<bool> isTwoWaySyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('calendar_two_way_sync_enabled') ?? false;
  }
  
  // Set two-way sync enabled status
  Future<void> setTwoWaySyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('calendar_two_way_sync_enabled', enabled);
  }
  
  // Sync a single task with Google Calendar
  Future<bool> syncTask(Task task) async {
    if (!await isSyncEnabled() || !_authService.isSignedIn) {
      return false;
    }
    
    // Check if the task's project is linked to a calendar
    final calendarId = _calendarService.getCalendarIdForProject(task.projectId);
    if (calendarId == null) {
      debugPrint('Project ${task.projectId} not linked to any calendar');
      return false;
    }
    
    try {
      // Check if the task is already mapped to an event
      final eventId = _taskEventMap[task.id];
      
      if (eventId != null) {
        // Update existing event
        final updated = await _calendarService.updateEventFromTask(task, eventId);
        return updated;
      } else {
        // Create new event
        final newEventId = await _calendarService.createEventFromTask(task);
        if (newEventId != null) {
          _taskEventMap[task.id] = newEventId;
          await _saveTaskEventMappings();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error syncing task: $e');
      return false;
    }
  }
  
  // Delete an event when a task is deleted
  Future<bool> deleteTaskEvent(String taskId) async {
    if (!await isSyncEnabled() || !_authService.isSignedIn) {
      return false;
    }
    
    try {
      final eventId = _taskEventMap[taskId];
      if (eventId == null) {
        return false;
      }
      
      // Get task to find its project
      final task = await _taskRepository.getTaskById(taskId);
      if (task == null) {
        _taskEventMap.remove(taskId);
        await _saveTaskEventMappings();
        return false;
      }
      
      // Delete the event
      final deleted = await _calendarService.deleteEvent(task.projectId, eventId);
      
      if (deleted) {
        _taskEventMap.remove(taskId);
        await _saveTaskEventMappings();
      }
      
      return deleted;
    } catch (e) {
      debugPrint('Error deleting task event: $e');
      return false;
    }
  }
  
  // Sync all tasks for a specific date range
  Future<int> syncTasksInRange(DateTime startDate, DateTime endDate) async {
    if (!await isSyncEnabled() || !_authService.isSignedIn || _isSyncing) {
      return 0;
    }
    
    _isSyncing = true;
    int syncCount = 0;
    
    try {
      // Get tasks within the date range
      final tasks = await _taskRepository.getTasksInDateRange(startDate, endDate);
      
      // Sync each task
      for (final task in tasks) {
        final success = await syncTask(task);
        if (success) {
          syncCount++;
        }
      }
      
      return syncCount;
    } catch (e) {
      debugPrint('Error syncing tasks in range: $e');
      return syncCount;
    } finally {
      _isSyncing = false;
    }
  }
  
  // Sync all tasks
  Future<int> syncAllTasks() async {
    if (!await isSyncEnabled() || !_authService.isSignedIn || _isSyncing) {
      return 0;
    }
    
    _isSyncing = true;
    int syncCount = 0;
    
    try {
      // Get all tasks
      final tasks = await _taskRepository.getAllTasks();
      
      // Sync each task
      for (final task in tasks) {
        final success = await syncTask(task);
        if (success) {
          syncCount++;
        }
      }
      
      return syncCount;
    } catch (e) {
      debugPrint('Error syncing all tasks: $e');
      return syncCount;
    } finally {
      _isSyncing = false;
    }
  }
  
  // Import events from Google Calendar as tasks (two-way sync)
  Future<int> importEventsFromCalendar({
    DateTime? from,
    DateTime? to,
  }) async {
    if (!await isTwoWaySyncEnabled() || !_authService.isSignedIn || _isSyncing) {
      return 0;
    }
    
    _isSyncing = true;
    int importCount = 0;
    
    try {
      // Get linked projects
      final linkedProjects = _calendarService.getLinkedProjects();
      
      // For each linked project
      for (final entry in linkedProjects.entries) {
        final projectId = entry.key;
        final calendarId = entry.value;
        
        // Get events from this calendar
        final events = await _getCalendarEvents(calendarId, from, to);
        
        // Import each event that doesn't have our custom property
        for (final event in events) {
          // Skip events created by our app (they have the tictask_id property)
          if (event.extendedProperties?.private?.containsKey('tictask_id') ?? false) {
            continue;
          }
          
          // Import this event
          final taskId = await _importEventAsTask(event, projectId);
          if (taskId != null) {
            importCount++;
          }
        }
      }
      
      return importCount;
    } catch (e) {
      debugPrint('Error importing events from calendar: $e');
      return importCount;
    } finally {
      _isSyncing = false;
    }
  }
  
  // Helper method to get calendar events
  Future<List<calendar.Event>> _getCalendarEvents(
    String calendarId,
    DateTime? from,
    DateTime? to,
  ) async {
    try {
      final calendarApi = _authService.calendarApi;
      if (calendarApi == null) {
        return [];
      }
      
      // Set time range for query
      final timeMin = from ?? DateTime.now().subtract(const Duration(days: 30));
      final timeMax = to ?? DateTime.now().add(const Duration(days: 30));
      
      // Query events
      final events = await calendarApi.events.list(
        calendarId,
        timeMin: timeMin.toUtc(),
        timeMax: timeMax.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );
      
      return events.items ?? [];
    } catch (e) {
      debugPrint('Error getting calendar events: $e');
      return [];
    }
  }
  
  // Import a Google Calendar event as a task
  Future<String?> _importEventAsTask(calendar.Event event, String projectId) async {
    if (event.id == null || event.summary == null || 
        event.start?.dateTime == null || event.end?.dateTime == null) {
      return null;
    }
    
    try {
      // Convert event to task
      final task = Task.create(
        title: event.summary!,
        description: event.description,
        startDate: event.start!.dateTime!.millisecondsSinceEpoch,
        endDate: event.end!.dateTime!.millisecondsSinceEpoch,
        ongoing: (event.recurrence?.isNotEmpty ?? false),
        hasReminder: (event.reminders?.overrides?.isNotEmpty ?? false),
        reminderTime: _calculateReminderTime(
          event.start!.dateTime!,
          event.reminders?.overrides,
        ),
        projectId: projectId,
      );
      
      // Save the task
      await _taskRepository.saveTask(task);
      
      // Map task to event
      _taskEventMap[task.id] = event.id!;
      await _saveTaskEventMappings();
      
      return task.id;
    } catch (e) {
      debugPrint('Error importing event as task: $e');
      return null;
    }
  }
  
  // Calculate reminder time from event reminders
  int? _calculateReminderTime(
    DateTime startTime, 
    List<calendar.EventReminder>? reminders,
  ) {
    if (reminders == null || reminders.isEmpty) {
      return null;
    }
    
    // Get the first reminder
    final reminder = reminders.first;
    final minutes = reminder.minutes ?? 0;
    
    // Calculate reminder time
    final reminderTime = startTime.subtract(Duration(minutes: minutes));
    return reminderTime.millisecondsSinceEpoch;
  }
  
  // Check if a task has an associated event
  bool isTaskSynced(String taskId) {
    return _taskEventMap.containsKey(taskId);
  }
  
  // Get the associated event ID for a task
  String? getEventIdForTask(String taskId) {
    return _taskEventMap[taskId];
  }
}