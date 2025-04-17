import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:tictask/features/projects/models/project.dart';
import 'package:tictask/features/projects/repositories/project_repository.dart';
import 'package:tictask/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:tictask/features/tasks/repositories/task_repository.dart';
import 'package:tictask/features/tasks/presentation/widgets/date_scroll_picker.dart';
import 'package:tictask/features/tasks/presentation/widgets/task_form_sheet.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key, this.showNavBar = true});

  final bool showNavBar;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskRepository _taskRepository = GetIt.I<TaskRepository>();
  final ProjectRepository _projectRepository = GetIt.I<ProjectRepository>();

  CalendarView _calendarView = CalendarView.day;
  final CalendarController _calendarController = CalendarController();

  // Maps to store projects by ID for quick lookup
  Map<String, Project> _projectsMap = {};

  // Flag to track if data is loading
  bool _isLoading = true;

  // Add this property to the _CalendarScreenState class
  List<Task> _tasks = [];

  // Selected date for the calendar
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadTasks(); // Add this line to load tasks when the screen initializes

    // Add a listener to the TaskBloc to reload tasks when they change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskBloc = context.read<TaskBloc>();
      taskBloc.stream.listen((state) {
        if (state is TaskLoaded || state is TaskActionSuccess) {
          _loadTasks();
        }
      });
    });
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projects = await _projectRepository.getAllProjects();

      // Create a map for quick project lookup by ID
      _projectsMap = {
        for (final project in projects) project.id: project,
      };

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load projects: $e')),
        );
      }
    }
  }

  // Add this method to load tasks
  Future<void> _loadTasks() async {
    print('Loading tasks...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Get tasks for a range around the selected date
      final startDate = _selectedDate.subtract(const Duration(days: 15));
      final endDate = _selectedDate.add(const Duration(days: 45));
      final tasks =
          await _taskRepository.getTasksInDateRange(startDate, endDate);

      print('Loaded ${tasks.length} tasks');
      for (final task in tasks) {
        print(
          'Task: ${task.id}, ${task.title}, ${DateTime.fromMillisecondsSinceEpoch(task.startDate)}',
        );
      }

      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    }
  }

  // Add this method to show the task form for editing
  void _showEditTaskForm(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskFormSheet(
        task: task,
        onComplete: () {
          Navigator.of(context).pop();
          _loadTasks(); // Reload tasks after editing
        },
      ),
    );
  }

  // Add this method to show the task form for creating a new task
  void _showCreateTaskForm(
    DateTime date,
    DateTime? startTime,
    DateTime? endTime,
  ) {
    // Create default start and end times if not provided
    final start = startTime ??
        DateTime(date.year, date.month, date.day, DateTime.now().hour);
    final end = endTime ?? start.add(const Duration(hours: 1));

    print('Creating new task with date: $date, start: $start, end: $end');

    // First create a task with the selected date and time
    final taskBloc = context.read<TaskBloc>();

    // Create a task with the BLoC
    final task = Task.create(
      title: 'New Task', // Default title that user can change
      startDate: start.millisecondsSinceEpoch,
      endDate: end.millisecondsSinceEpoch,
    );

    // Save the task to the database
    _taskRepository.saveTask(task).then((_) {
      // After the task is saved, open the form to edit it
      _showEditTaskForm(task);

      // Also reload the tasks to update the calendar
      _loadTasks();
    });
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Create a key that changes when the view changes to force a rebuild
    final calendarKey = ValueKey('calendar-$_calendarView');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _calendarView == CalendarView.day
              ? 'Calendar'
              : 'Calendar - ${_calendarView.toString().replaceAll('CalendarView.', '')} View',
        ),
        actions: [
          PopupMenuButton<CalendarView>(
            icon: const Icon(Icons.calendar_view_day),
            tooltip: 'Calendar View',
            onSelected: (CalendarView view) {
              setState(() {
                _calendarView = view;
                _calendarController.view = view;

                // When switching to day view, ensure the calendar shows the selected date
                if (view == CalendarView.day) {
                  _calendarController.displayDate = _selectedDate;
                }
              });
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<CalendarView>>[
              const PopupMenuItem<CalendarView>(
                value: CalendarView.day,
                child: Text('Day View'),
              ),
              const PopupMenuItem<CalendarView>(
                value: CalendarView.week,
                child: Text('Week View'),
              ),
              const PopupMenuItem<CalendarView>(
                value: CalendarView.month,
                child: Text('Month View'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Show date picker only for day view
          if (_calendarView == CalendarView.day)
            DateScrollPicker(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  // Update the calendar's display date
                  _calendarController.displayDate = date;
                });
                _loadTasks(); // Reload tasks for the new date
              },
            ),

          // Calendar view
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SfCalendar(
                    key: calendarKey,
                    controller: _calendarController,
                    view: _calendarView,
                    firstDayOfWeek: 1, // Monday
                    dataSource: _getCalendarDataSource(),
                    // Hide the header in day view
                    headerHeight: _calendarView == CalendarView.day ? 0 : 40,
                    // Hide the view header in day view (the row showing dates)
                    viewHeaderHeight:
                        _calendarView == CalendarView.day ? 0 : 60,
                    monthViewSettings: const MonthViewSettings(
                      showAgenda: true,
                      agendaViewHeight: 200,
                    ),
                    timeSlotViewSettings: const TimeSlotViewSettings(
                      timeFormat: 'h:mm a',
                      timeIntervalHeight: 60,
                      timeTextStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    appointmentBuilder: _buildAppointment,
                    onTap: _handleCalendarTap, // Add this line to handle taps
                  ),
          ),
        ],
      ),
    );
  }

  // Add this method to handle calendar taps
  void _handleCalendarTap(CalendarTapDetails details) {
    if (details.targetElement == CalendarElement.appointment) {
      // User tapped on an existing task
      final task = details.appointments![0] as Task;
      _showEditTaskForm(task);
    } else if (details.targetElement == CalendarElement.calendarCell) {
      // User tapped on an empty cell or time slot
      final date = details.date!;

      // Update the selected date to match the tapped date
      setState(() {
        _selectedDate = DateTime(date.year, date.month, date.day);
      });

      // Only show the task form in day and week views
      if (_calendarView == CalendarView.day ||
          _calendarView == CalendarView.week) {
        // For day or week view, we get the exact time slot
        final endTime = date.add(const Duration(hours: 1));
        _showCreateTaskForm(date, date, endTime);
      }
      // Do nothing for month view
    }
  }

  Widget _buildAppointment(
    BuildContext context,
    CalendarAppointmentDetails details,
  ) {
    final task = details.appointments.first as Task;
    final project = _projectsMap[task.projectId];
    final projectColor = project != null
        ? Color(project.color)
        : Theme.of(context).colorScheme.primary;

    return Container(
      width: details.bounds.width,
      height: details.bounds.height,
      decoration: BoxDecoration(
        color: projectColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (project != null && project.emoji != null)
                Text(
                  project.emoji!,
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (details.bounds.height > 40 && task.description != null)
            Expanded(
              child: Text(
                task.description!,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
        ],
      ),
    );
  }

  TaskDataSource _getCalendarDataSource() {
    return TaskDataSource(_tasks, _projectsMap);
  }

  // Helper method to get the first day of the week for a given date
  DateTime _getFirstDayOfWeek(DateTime date) {
    // Get the day of the week (1 = Monday, 7 = Sunday)
    final dayOfWeek = date.weekday;
    // Calculate the difference to the first day of the week (Monday)
    final difference = dayOfWeek - 1;
    // Subtract the difference to get the first day of the week
    return date.subtract(Duration(days: difference));
  }
}

class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Task> tasks, this._projectsMap) {
    appointments = tasks; // Set the appointments directly
  }

  final Map<String, Project> _projectsMap;

  @override
  DateTime getStartTime(int index) {
    final task = appointments![index] as Task;
    return DateTime.fromMillisecondsSinceEpoch(task.startDate);
  }

  @override
  DateTime getEndTime(int index) {
    final task = appointments![index] as Task;
    return DateTime.fromMillisecondsSinceEpoch(task.endDate);
  }

  @override
  String getSubject(int index) {
    final task = appointments![index] as Task;
    return task.title;
  }

  @override
  Color getColor(int index) {
    final task = appointments![index] as Task;
    final project = _projectsMap[task.projectId];

    if (project != null) {
      return Color(project.color);
    }

    // Fallback color if project not found
    return Colors.blue;
  }

  @override
  bool isAllDay(int index) {
    final task = appointments![index] as Task;
    return task.ongoing;
  }
}
