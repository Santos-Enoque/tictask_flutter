import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:tictask/features/google_calendar/services/google_auth_service.dart';
import 'package:tictask/features/google_calendar/services/google_calendar_service.dart';
import 'package:tictask/app/theme/colors.dart';
import 'package:tictask/app/theme/dimensions.dart';
import 'package:tictask/app/widgets/app_scaffold.dart';
import 'package:tictask/features/projects/models/project.dart';
import 'package:tictask/features/projects/repositories/project_repository.dart';
import 'package:tictask/injection_container.dart' as di;


class CalendarSettingsScreen extends StatefulWidget {
  const CalendarSettingsScreen({Key? key}) : super(key: key);

  @override
  State<CalendarSettingsScreen> createState() => _CalendarSettingsScreenState();
}

class _CalendarSettingsScreenState extends State<CalendarSettingsScreen> {
  final GoogleAuthService _authService = di.sl<GoogleAuthService>();
  final GoogleCalendarService _calendarService = di.sl<GoogleCalendarService>();
  final ProjectRepository _projectRepository = di.sl<ProjectRepository>();
  
  bool _isLoading = false;
  List<Project> _projects = [];
  List<calendar.CalendarListEntry> _availableCalendars = [];
  Map<String, String> _projectCalendarMap = {};
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load projects
      _projects = await _projectRepository.getAllProjects();
      
      // Load current mappings
      _projectCalendarMap = _calendarService.getLinkedProjects();
      
      // Load available calendars if signed in
      if (_authService.isSignedIn) {
        _availableCalendars = await _calendarService.getAvailableCalendars();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final success = await _authService.signIn();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed in to Google')),
        );
        await _loadData();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign in to Google')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signOut();
      _availableCalendars = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out from Google')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _createCalendarForProject(Project project) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final calendarId = await _calendarService.createCalendarForProject(project);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Created calendar for ${project.name}')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating calendar: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _showCalendarSelectionDialog(Project project) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDarkMode ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Calendar for ${project.name}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              if (_availableCalendars.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No calendars available',
                    style: TextStyle(color: textColor),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _availableCalendars.length,
                    itemBuilder: (context, index) {
                      final calendar = _availableCalendars[index];
                      return ListTile(
                        leading: Icon(
                          Icons.event,
                          color: calendar.backgroundColor != null ? 
                            Color(int.parse('0xFF${calendar.backgroundColor!.substring(1)}')):
                            Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          calendar.summary ?? 'Unnamed Calendar',
                          style: TextStyle(color: textColor),
                        ),
                        subtitle: calendar.description != null ? 
                          Text(
                            calendar.description!,
                            style: TextStyle(color: textColor.withOpacity(0.7)),
                          ) : null,
                        onTap: () async {
                          Navigator.of(context).pop();
                          
                          if (calendar.id != null) {
                            setState(() {
                              _isLoading = true;
                            });
                            
                            try {
                              await _calendarService.linkCalendarToProject(
                                project.id, 
                                calendar.id!
                              );
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Linked ${project.name} to ${calendar.summary}'),
                                  ),
                                );
                                await _loadData();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error linking calendar: $e')),
                                );
                              }
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _createCalendarForProject(project);
                  },
                  child: const Text(
                    'Create New Calendar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _unlinkCalendar(Project project) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _calendarService.unlinkCalendarFromProject(project.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unlinked ${project.name} from calendar')),
        );
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unlinking calendar: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AppScaffold(
      title: 'Calendar Settings',
      showBottomNav: false,
      child: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          
          RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.md),
              children: [
                // Google Account Section
                _buildSectionHeader('Google Account'),
                Card(
                  margin: const EdgeInsets.only(bottom: AppDimensions.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_authService.isSignedIn && _authService.currentUser != null) ...[
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(_authService.currentUser!.photoUrl ?? ''),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              child: _authService.currentUser!.photoUrl == null
                                  ? Text(_authService.currentUser!.displayName?[0] ?? 'U')
                                  : null,
                            ),
                            title: Text(_authService.currentUser!.displayName ?? 'User'),
                            subtitle: Text(_authService.currentUser!.email),
                            trailing: TextButton(
                              onPressed: _signOut,
                              child: const Text('Sign Out'),
                            ),
                          ),
                        ] else ...[
                          ListTile(
                            leading: const Icon(Icons.account_circle),
                            title: const Text('Google Account'),
                            subtitle: const Text('Sign in to sync with Google Calendar'),
                            trailing: ElevatedButton(
                              onPressed: _signInWithGoogle,
                              child: const Text('Sign In'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Calendar Integration Section
                _buildSectionHeader('Calendar Integration'),
                const Card(
                  margin: EdgeInsets.only(bottom: AppDimensions.md),
                  child: Padding(
                    padding: EdgeInsets.all(AppDimensions.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Map your projects to Google Calendars to keep your tasks in sync. '
                          'Each project can be linked to a separate calendar for better organization.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Projects and Calendars Section
                _buildSectionHeader('Projects and Calendars'),
                if (!_authService.isSignedIn)
                  Card(
                    margin: const EdgeInsets.only(bottom: AppDimensions.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_month, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'Sign in to your Google account to manage calendar connections',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _signInWithGoogle,
                            child: const Text('Sign In with Google'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_projects.isEmpty)
                  const Card(
                    margin: EdgeInsets.only(bottom: AppDimensions.md),
                    child: Padding(
                      padding: EdgeInsets.all(AppDimensions.md),
                      child: Center(
                        child: Text('No projects available'),
                      ),
                    ),
                  )
                else
                  for (final project in _projects)
                    Card(
                      margin: const EdgeInsets.only(bottom: AppDimensions.md),
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.sm),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Color(project.color),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                project.emoji ?? '📅',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          title: Text(project.name),
                          subtitle: _projectCalendarMap.containsKey(project.id)
                              ? FutureBuilder<String>(
                                  future: _getCalendarName(_projectCalendarMap[project.id]!),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Text('Loading calendar...');
                                    }
                                    return Text(
                                      'Linked to: ${snapshot.data ?? "Unknown calendar"}',
                                      style: const TextStyle(fontStyle: FontStyle.italic),
                                    );
                                  },
                                )
                              : const Text(
                                  'Not linked to any calendar',
                                  style: TextStyle(fontStyle: FontStyle.italic),
                                ),
                          trailing: _projectCalendarMap.containsKey(project.id)
                              ? IconButton(
                                  icon: const Icon(Icons.link_off),
                                  tooltip: 'Unlink calendar',
                                  onPressed: () => _unlinkCalendar(project),
                                )
                              : ElevatedButton(
                                  onPressed: () => _showCalendarSelectionDialog(project),
                                  child: const Text('Link'),
                                ),
                        ),
                      ),
                    ),
                
                // Sync Settings Section
                _buildSectionHeader('Sync Settings'),
                Card(
                  margin: const EdgeInsets.only(bottom: AppDimensions.xl),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Auto-sync with Google Calendar'),
                        subtitle: const Text('Automatically sync tasks when they are created or updated'),
                        value: _getSyncPreference(),
                        onChanged: _authService.isSignedIn
                            ? (bool value) async {
                                await _setSyncPreference(value);
                                setState(() {});
                              }
                            : null,
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Sync Now'),
                        subtitle: const Text('Manually sync all tasks with Google Calendar'),
                        enabled: _authService.isSignedIn,
                        trailing: IconButton(
                          icon: const Icon(Icons.sync),
                          onPressed: _authService.isSignedIn
                              ? () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  
                                  try {
                                    await _performFullSync();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Successfully synced with Google Calendar')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error syncing: $e')),
                                      );
                                    }
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                  }
                                }
                              : null,
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        title: const Text('Two-Way Sync'),
                        subtitle: const Text('Import events from Google Calendar to the app'),
                        enabled: _authService.isSignedIn,
                        trailing: Switch(
                          value: _getTwoWaySyncPreference(),
                          onChanged: _authService.isSignedIn
                              ? (bool value) async {
                                  await _setTwoWaySyncPreference(value);
                                  setState(() {});
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.md,
        AppDimensions.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
  
  // Helper method to get calendar name by ID
  Future<String> _getCalendarName(String calendarId) async {
    try {
      for (final calendar in _availableCalendars) {
        if (calendar.id == calendarId) {
          return calendar.summary ?? 'Unnamed Calendar';
        }
      }
      
      // If not found in the loaded list, try to fetch it
      if (_authService.isSignedIn && _authService.calendarApi != null) {
        final calendar = await _authService.calendarApi!.calendarList.get(calendarId);
        return calendar.summary ?? 'Unnamed Calendar';
      }
      
      return 'Unknown Calendar';
    } catch (e) {
      debugPrint('Error getting calendar name: $e');
      return 'Unknown Calendar';
    }
  }
  
  // Preferences helpers
  bool _getSyncPreference() {
    return true; // Default to true, implement actual preference storage
  }
  
  Future<void> _setSyncPreference(bool value) async {
    // Implement preference storage
  }
  
  bool _getTwoWaySyncPreference() {
    return false; // Default to false, implement actual preference storage
  }
  
  Future<void> _setTwoWaySyncPreference(bool value) async {
    // Implement preference storage
  }
  
  // Perform full sync of all tasks
  Future<void> _performFullSync() async {
    // This would be implemented in a TaskSyncService
    // For now, just a placeholder
    await Future.delayed(const Duration(seconds: 2));
  }
}