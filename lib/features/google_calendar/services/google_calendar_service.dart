import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:tictask/features/projects/models/project.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_auth_service.dart';

class GoogleCalendarService {
  final GoogleAuthService _authService;

  // Map to store project ID to calendar ID mapping
  Map<String, String> _projectCalendarMap = {};

  // Constructor
  GoogleCalendarService(this._authService);

  // Initialize and load saved calendar mappings
  Future<void> init() async {
    await _loadCalendarMappings();
  }

  // Load calendar mappings from SharedPreferences
  Future<void> _loadCalendarMappings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mappings = prefs.getStringList('project_calendar_mappings') ?? [];

      _projectCalendarMap = {};
      for (final mapping in mappings) {
        final parts = mapping.split(':');
        if (parts.length == 2) {
          _projectCalendarMap[parts[0]] = parts[1];
        }
      }

      debugPrint('Loaded calendar mappings: $_projectCalendarMap');
    } catch (e) {
      debugPrint('Error loading calendar mappings: $e');
    }
  }

  // Save calendar mappings to SharedPreferences
  Future<void> _saveCalendarMappings() async {
    try {
      final mappings = _projectCalendarMap.entries
          .map((e) => '${e.key}:${e.value}')
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('project_calendar_mappings', mappings);
    } catch (e) {
      debugPrint('Error saving calendar mappings: $e');
    }
  }

  // Get all available calendars from Google Calendar
  Future<List<calendar.CalendarListEntry>> getAvailableCalendars() async {
    if (!_authService.isSignedIn) {
      throw Exception('User not signed in to Google');
    }

    try {
      final calendarApi = _authService.calendarApi;
      if (calendarApi == null) {
        throw Exception('Calendar API not initialized');
      }

      final calendarList = await calendarApi.calendarList.list();
      return calendarList.items ?? [];
    } catch (e) {
      debugPrint('Error getting available calendars: $e');
      rethrow;
    }
  }

  // Create a new calendar for a project
  Future<String> createCalendarForProject(Project project) async {
    if (!_authService.isSignedIn) {
      throw Exception('User not signed in to Google');
    }

    try {
      final calendarApi = _authService.calendarApi;
      if (calendarApi == null) {
        throw Exception('Calendar API not initialized');
      }

      // Create a new calendar
      final newCalendar = calendar.Calendar()
        ..summary = project.name
        ..description = project.description ?? 'TicTask Project'
        ..timeZone = 'UTC'; // Use device timezone ideally

      final createdCalendar = await calendarApi.calendars.insert(newCalendar);

      if (createdCalendar.id != null) {
        // Store the mapping
        _projectCalendarMap[project.id] = createdCalendar.id!;
        await _saveCalendarMappings();

        return createdCalendar.id!;
      } else {
        throw Exception('Failed to create calendar');
      }
    } catch (e) {
      debugPrint('Error creating calendar for project: $e');
      rethrow;
    }
  }

  // Link an existing Google Calendar to a project
  Future<void> linkCalendarToProject(
      String projectId, String calendarId) async {
    _projectCalendarMap[projectId] = calendarId;
    await _saveCalendarMappings();
  }

  // Unlink a project from Google Calendar
  Future<void> unlinkCalendarFromProject(String projectId) async {
    _projectCalendarMap.remove(projectId);
    await _saveCalendarMappings();
  }

  // Get calendar ID for a project
  String? getCalendarIdForProject(String projectId) {
    return _projectCalendarMap[projectId];
  }

  // Check if a project is linked to a calendar
  bool isProjectLinked(String projectId) {
    return _projectCalendarMap.containsKey(projectId);
  }

  // Create a Google Calendar event from a task
  Future<String?> createEventFromTask(Task task) async {
    if (!_authService.isSignedIn) {
      throw Exception('User not signed in to Google');
    }

    // Check if the project is linked to a calendar
    final calendarId = getCalendarIdForProject(task.projectId);
    if (calendarId == null) {
      debugPrint('Project ${task.projectId} not linked to any calendar');
      return null;
    }

    try {
      final calendarApi = _authService.calendarApi;
      if (calendarApi == null) {
        throw Exception('Calendar API not initialized');
      }

      // Convert task times to RFC3339 format
      final startDateTime = DateTime.fromMillisecondsSinceEpoch(task.startDate);
      final endDateTime = DateTime.fromMillisecondsSinceEpoch(task.endDate);

      // Create the event
      final event = calendar.Event()
        ..summary = task.title
        ..description = task.description ?? ''
        ..start = calendar.EventDateTime(
          dateTime: startDateTime,
          timeZone: 'UTC',
        )
        ..end = calendar.EventDateTime(
          dateTime: endDateTime,
          timeZone: 'UTC',
        );

      // Add custom property to identify this as a TicTask event
      event.extendedProperties = calendar.EventExtendedProperties()
        ..private = {
          'tictask_id': task.id,
          'tictask_status': task.status.toString(),
          'tictask_pomodoros': task.pomodorosCompleted.toString(),
        };

      // If this is a recurring task
      if (task.ongoing) {
        event.recurrence = ['RRULE:FREQ=DAILY'];
      }

      // Add reminder if set
      if (task.hasReminder && task.reminderTime != null) {
        final reminderMinutes = DateTime.fromMillisecondsSinceEpoch(
                task.startDate)
            .difference(DateTime.fromMillisecondsSinceEpoch(task.reminderTime!))
            .inMinutes;

        event.reminders = calendar.EventReminders()
          ..useDefault = false
          ..overrides = [
            calendar.EventReminder()
              ..method = 'popup'
              ..minutes = reminderMinutes.abs(),
          ];
      }

      // Insert the event
      final createdEvent = await calendarApi.events.insert(event, calendarId);
      return createdEvent.id;
    } catch (e) {
      debugPrint('Error creating event from task: $e');
      return null;
    }
  }

  // Update an existing Google Calendar event
  Future<bool> updateEventFromTask(Task task, String eventId) async {
    if (!_authService.isSignedIn) {
      throw Exception('User not signed in to Google');
    }

    // Check if the project is linked to a calendar
    final calendarId = getCalendarIdForProject(task.projectId);
    if (calendarId == null) {
      debugPrint('Project ${task.projectId} not linked to any calendar');
      return false;
    }

    try {
      final calendarApi = _authService.calendarApi;
      if (calendarApi == null) {
        throw Exception('Calendar API not initialized');
      }

      // Get existing event
      final existingEvent = await calendarApi.events.get(calendarId, eventId);

      // Convert task times to RFC3339 format
      final startDateTime = DateTime.fromMillisecondsSinceEpoch(task.startDate);
      final endDateTime = DateTime.fromMillisecondsSinceEpoch(task.endDate);

      // Update the event
      existingEvent.summary = task.title;
      existingEvent.description = task.description ?? '';
      existingEvent.start = calendar.EventDateTime(
        dateTime: startDateTime,
        timeZone: 'UTC',
      );
      existingEvent.end = calendar.EventDateTime(
        dateTime: endDateTime,
        timeZone: 'UTC',
      );

      // Update custom properties
      existingEvent.extendedProperties ??= calendar.EventExtendedProperties();
      existingEvent.extendedProperties!.private ??= {};
      existingEvent.extendedProperties!.private!['tictask_status'] =
          task.status.toString();
      existingEvent.extendedProperties!.private!['tictask_pomodoros'] =
          task.pomodorosCompleted.toString();

      // Update recurrence
      if (task.ongoing) {
        existingEvent.recurrence = ['RRULE:FREQ=DAILY'];
      } else {
        existingEvent.recurrence = [];
      }

      // Update reminder if set
      if (task.hasReminder && task.reminderTime != null) {
        final reminderMinutes = DateTime.fromMillisecondsSinceEpoch(
                task.startDate)
            .difference(DateTime.fromMillisecondsSinceEpoch(task.reminderTime!))
            .inMinutes;

        existingEvent.reminders = calendar.EventReminders()
          ..useDefault = false
          ..overrides = [
            calendar.EventReminder()
              ..method = 'popup'
              ..minutes = reminderMinutes.abs(),
          ];
      } else {
        existingEvent.reminders = calendar.EventReminders()..useDefault = true;
      }

      // Update the event
      await calendarApi.events.update(existingEvent, calendarId, eventId);
      return true;
    } catch (e) {
      debugPrint('Error updating event from task: $e');
      return false;
    }
  }

  // Delete an event from Google Calendar
  Future<bool> deleteEvent(String projectId, String eventId) async {
    if (!_authService.isSignedIn) {
      throw Exception('User not signed in to Google');
    }

    // Check if the project is linked to a calendar
    final calendarId = getCalendarIdForProject(projectId);
    if (calendarId == null) {
      debugPrint('Project $projectId not linked to any calendar');
      return false;
    }

    try {
      final calendarApi = _authService.calendarApi;
      if (calendarApi == null) {
        throw Exception('Calendar API not initialized');
      }

      await calendarApi.events.delete(calendarId, eventId);
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  // Get all events for a project
  Future<List<calendar.Event>> getEventsForProject(String projectId,
      {DateTime? from, DateTime? to}) async {
    if (!_authService.isSignedIn) {
      throw Exception('User not signed in to Google');
    }

    // Check if the project is linked to a calendar
    final calendarId = getCalendarIdForProject(projectId);
    if (calendarId == null) {
      debugPrint('Project $projectId not linked to any calendar');
      return [];
    }

    try {
      final calendarApi = _authService.calendarApi;
      if (calendarApi == null) {
        throw Exception('Calendar API not initialized');
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
      debugPrint('Error getting events for project: $e');
      return [];
    }
  }

  // Get all linked projects and their calendar IDs
  Map<String, String> getLinkedProjects() {
    return Map.from(_projectCalendarMap);
  }
}
