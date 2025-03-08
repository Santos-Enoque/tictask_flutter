import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tictask/app/theme/colors.dart';
import 'package:tictask/features/projects/models/project.dart';
import 'package:tictask/features/projects/repositories/project_repository.dart';
import 'package:tictask/features/projects/widgets/project_form_sheet.dart';
import 'package:tictask/features/tasks/bloc/task_bloc.dart';
import 'package:tictask/features/tasks/models/task.dart';
import 'package:tictask/injection_container.dart' as di;

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({
    required this.onComplete,
    super.key,
    this.task,
  });

  final Task? task;
  final VoidCallback onComplete;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedPomodorosController;
  late DateTime _taskDate;
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _ongoing;
  late bool _hasReminder;
  DateTime? _reminderTime;
  String _selectedProjectId = 'inbox';
  List<Project> _projects = [];
  bool _showAdvancedOptions = false;

  // Add focus nodes for better keyboard control
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _estimatedPomodorosFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _estimatedPomodorosController = TextEditingController();

    // Initialize with default values
    final now = DateTime.now();
    _taskDate = now;
    _startDate = now;
    _endDate = now.add(const Duration(hours: 1));
    _ongoing = false;
    _hasReminder = false;
    _reminderTime = null;

    // Set values if editing
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _estimatedPomodorosController.text =
          widget.task!.estimatedPomodoros?.toString() ?? '';
      _startDate = DateTime.fromMillisecondsSinceEpoch(widget.task!.startDate);
      _endDate = DateTime.fromMillisecondsSinceEpoch(widget.task!.endDate);
      _taskDate = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
      );
      _ongoing = widget.task!.ongoing;
      _hasReminder = widget.task!.hasReminder;
      _reminderTime = widget.task!.reminderTime != null
          ? DateTime.fromMillisecondsSinceEpoch(widget.task!.reminderTime!)
          : null;
      _selectedProjectId = widget.task!.projectId;
    }

    // Load available projects
    _loadProjects();

    // Automatically focus the title field after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_titleFocus);
      }
    });
  }

  Future<void> _loadProjects() async {
    try {
      // Access the project repository directly from the service locator
      final projectRepository = di.sl<ProjectRepository>();
      final projects = await projectRepository.getAllProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
      // Fallback to just having the inbox project
      if (mounted) {
        setState(() {
          _projects = [
            const Project(
              id: 'inbox',
              name: 'Inbox',
              color: 0xFF4A6572,
              createdAt: 0,
              updatedAt: 0,
              isDefault: true,
            ),
          ];
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedPomodorosController.dispose();
    _titleFocus.dispose();
    _descriptionFocus.dispose();
    _estimatedPomodorosFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDarkMode ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    // Determine available height with keyboard considerations
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final statusBarHeight = MediaQuery.of(context).padding.top;

    // Use full height minus status bar and a small margin
    final sheetHeight = screenHeight - statusBarHeight - 10;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar at top
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Form content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: keyboardHeight > 0
                          ? keyboardHeight + 16
                          : MediaQuery.of(context).padding.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task == null ? 'New Task' : 'Edit Task',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Always visible fields
                        // Title field
                        TextFormField(
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Task title',
                            filled: true,
                            fillColor: isDarkMode
                                ? AppColors.darkBackground
                                : AppColors.lightBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                          focusNode: _titleFocus,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context)
                                .requestFocus(_estimatedPomodorosFocus);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Pomodoros field
                        TextFormField(
                          controller: _estimatedPomodorosController,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Estimated pomodoros',
                            filled: true,
                            fillColor: isDarkMode
                                ? AppColors.darkBackground
                                : AppColors.lightBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          focusNode: _estimatedPomodorosFocus,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        const SizedBox(height: 12),

                        // Project selector
                        GestureDetector(
                          onTap: () => _showProjectSelectionDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.folder_outlined,
                                      color: isDarkMode
                                          ? AppColors.darkPrimary
                                          : AppColors.lightPrimary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _projects.isEmpty
                                          ? 'Loading projects...'
                                          : _projects
                                              .firstWhere(
                                                (p) =>
                                                    p.id == _selectedProjectId,
                                                orElse: () => const Project(
                                                  id: 'inbox',
                                                  name: 'Inbox',
                                                  color: 0xFF4A6572,
                                                  createdAt: 0,
                                                  updatedAt: 0,
                                                  isDefault: true,
                                                ),
                                              )
                                              .name,
                                      style: TextStyle(color: textColor),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: isDarkMode
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Date selector
                        GestureDetector(
                          onTap: () => _showCupertinoDatePicker(context),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: isDarkMode
                                          ? AppColors.darkPrimary
                                          : AppColors.lightPrimary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('EEE, MMM d, yyyy')
                                          .format(_taskDate),
                                      style: TextStyle(color: textColor),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: isDarkMode
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Start and end time side by side
                        Row(
                          children: [
                            // Start time selector
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _showCupertinoTimePicker(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? AppColors.darkBackground
                                        : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: isDarkMode
                                                ? AppColors.darkPrimary
                                                : AppColors.lightPrimary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('h:mm a')
                                                .format(_startDate),
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: isDarkMode
                                            ? AppColors.darkPrimary
                                            : AppColors.lightPrimary,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // End time selector
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _showCupertinoTimePicker(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? AppColors.darkBackground
                                        : AppColors.lightBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDarkMode
                                          ? AppColors.darkBorder
                                          : AppColors.lightBorder,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            color: isDarkMode
                                                ? AppColors.darkPrimary
                                                : AppColors.lightPrimary,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('h:mm a')
                                                .format(_endDate),
                                            style: TextStyle(
                                              color: textColor,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: isDarkMode
                                            ? AppColors.darkPrimary
                                            : AppColors.lightPrimary,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Show more button
                        Center(
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAdvancedOptions = !_showAdvancedOptions;
                              });
                            },
                            icon: Icon(
                              _showAdvancedOptions
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: isDarkMode
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                            ),
                            label: Text(
                              _showAdvancedOptions ? 'Show Less' : 'Show More',
                              style: TextStyle(
                                color: isDarkMode
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary,
                              ),
                            ),
                          ),
                        ),

                        // Advanced options section
                        if (_showAdvancedOptions) ...[
                          const SizedBox(height: 16),

                          // Description field
                          TextFormField(
                            controller: _descriptionController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Description (optional)',
                              filled: true,
                              fillColor: isDarkMode
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            maxLines: 2,
                            focusNode: _descriptionFocus,
                          ),
                          const SizedBox(height: 16),

                          // Ongoing switch
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Repeat Daily',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                Switch(
                                  value: _ongoing,
                                  onChanged: (value) {
                                    setState(() {
                                      _ongoing = value;
                                    });
                                  },
                                  activeColor: isDarkMode
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Reminder switch
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Enable Reminder',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                Switch(
                                  value: _hasReminder,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasReminder = value;
                                      if (value && _reminderTime == null) {
                                        _reminderTime = _startDate.subtract(
                                          const Duration(minutes: 30),
                                        );
                                      }
                                    });
                                  },
                                  activeColor: isDarkMode
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                              ],
                            ),
                          ),

                          // Reminder time selector
                          if (_hasReminder) ...[
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () =>
                                  _showCupertinoReminderPicker(context),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? AppColors.darkBackground
                                      : AppColors.lightBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isDarkMode
                                        ? AppColors.darkBorder
                                        : AppColors.lightBorder,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.notifications_active,
                                          color: isDarkMode
                                              ? AppColors.darkPrimary
                                              : AppColors.lightPrimary,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _reminderTime == null
                                              ? 'Set reminder time'
                                              : 'Remind at: ${DateFormat('h:mm a, MMM d').format(_reminderTime!)}',
                                          style: TextStyle(color: textColor),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: isDarkMode
                                          ? AppColors.darkPrimary
                                          : AppColors.lightPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 24),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: isDarkMode
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _saveTask,
                            child: Text(
                              widget.task == null ? 'Add Task' : 'Update Task',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCupertinoDatePicker(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDarkMode ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    var pickedDate = _taskDate;

    await showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 320,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _taskDate = pickedDate;

                        // Update both start and end times to keep the same time but on the new date
                        _startDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          _startDate.hour,
                          _startDate.minute,
                        );

                        _endDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          _endDate.hour,
                          _endDate.minute,
                        );
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: _taskDate,
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: DateTime.now().subtract(const Duration(days: 1)),
                  maximumDate: DateTime.now().add(const Duration(days: 365)),
                  onDateTimeChanged: (DateTime newDate) {
                    pickedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCupertinoTimePicker(
    BuildContext context,
    bool isStartTime,
  ) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDarkMode ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    final initialTime = isStartTime ? _startDate : _endDate;
    var pickedTime = initialTime;

    await showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 320,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isStartTime ? 'Select Start Time' : 'Select End Time',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Validate time selection before applying
                      if (!isStartTime && pickedTime.isBefore(_startDate)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('End time must be after start time'),
                          ),
                        );
                      } else {
                        setState(() {
                          if (isStartTime) {
                            _startDate = DateTime(
                              _taskDate.year,
                              _taskDate.month,
                              _taskDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );

                            // Adjust end time if needed
                            if (_endDate.isBefore(_startDate)) {
                              _endDate =
                                  _startDate.add(const Duration(hours: 1));
                            }
                          } else {
                            _endDate = DateTime(
                              _taskDate.year,
                              _taskDate.month,
                              _taskDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          }
                        });
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialTime,
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                  onDateTimeChanged: (DateTime newTime) {
                    pickedTime = newTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCupertinoReminderPicker(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDarkMode ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    final initialDateTime =
        _reminderTime ?? _startDate.subtract(const Duration(minutes: 30));
    var pickedTime = initialDateTime;

    await showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: 320,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set Reminder Time',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _reminderTime = pickedTime;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: isDarkMode
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialDateTime,
                  use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                  onDateTimeChanged: (DateTime newTime) {
                    pickedTime = newTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProjectSelectionDialog(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDarkMode ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    // Create a value notifier to force rebuilds
    final refreshNotifier = ValueNotifier<bool>(false);

    // Function to refresh projects
    Future<void> refreshProjects() async {
      final projectRepository = di.sl<ProjectRepository>();
      final projects = await projectRepository.getAllProjects();

      if (mounted) {
        setState(() {
          _projects = projects;
        });
        // Toggle notifier to force rebuild
        refreshNotifier.value = !refreshNotifier.value;
      }
    }

    Future<void> showProjectForm() async {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ProjectFormSheet(
          onComplete: () async {
            // Close the form sheet
            Navigator.of(context).pop();

            // Important: Wait a moment for the database to update
            await Future.delayed(const Duration(milliseconds: 300));

            // Refresh the projects list
            await refreshProjects();
          },
        ),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return ValueListenableBuilder(
          valueListenable: refreshNotifier,
          builder: (context, _, __) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Project',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          Row(
                            children: [
                              // Add Project Button (Plus Icon)
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: isDarkMode
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                                onPressed: showProjectForm,
                                tooltip: 'Add new project',
                              ),
                              // Close Button
                              IconButton(
                                icon: Icon(Icons.close, color: textColor),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: _projects.isEmpty
                            ? Center(
                                child: Text(
                                  'No projects found',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _projects.length,
                                itemBuilder: (context, index) {
                                  final project = _projects[index];
                                  return ListTile(
                                    leading: project.emoji != null &&
                                            project.emoji!.isNotEmpty
                                        ? Text(
                                            project.emoji!,
                                            style:
                                                const TextStyle(fontSize: 22),
                                          )
                                        : const Icon(
                                            Icons.folder_outlined,
                                            size: 22,
                                          ),
                                    title: Text(
                                      project.name,
                                      style: TextStyle(color: textColor),
                                    ),
                                    trailing: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: Color(project.color),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    selected: _selectedProjectId == project.id,
                                    selectedTileColor: isDarkMode
                                        ? AppColors.darkPrimary.withOpacity(0.1)
                                        : AppColors.lightPrimary
                                            .withOpacity(0.1),
                                    onTap: () {
                                      setState(() {
                                        _selectedProjectId = project.id;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _saveTask() {
    if (_titleController.text.isEmpty) {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    int? estimatedPomodoros;
    if (_estimatedPomodorosController.text.isNotEmpty) {
      estimatedPomodoros = int.tryParse(_estimatedPomodorosController.text);
    }

    // First, call onComplete to dismiss the sheet immediately
    widget.onComplete();

    // Then dispatch the appropriate event after the sheet is dismissed
    if (widget.task == null) {
      // Add new task
      context.read<TaskBloc>().add(
            AddTask(
              title: _titleController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              estimatedPomodoros: estimatedPomodoros,
              startDate: _startDate,
              endDate: _endDate,
              ongoing: _ongoing,
              hasReminder: _hasReminder,
              reminderTime: _reminderTime,
              projectId: _selectedProjectId,
            ),
          );
    } else {
      // Update existing task
      context.read<TaskBloc>().add(
            UpdateTask(
              id: widget.task!.id,
              title: _titleController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              estimatedPomodoros: estimatedPomodoros,
              startDate: _startDate,
              endDate: _endDate,
              ongoing: _ongoing,
              hasReminder: _hasReminder,
              reminderTime: _reminderTime,
              projectId: _selectedProjectId,
            ),
          );
    }
  }
}
