import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tictask/app/theme/colors.dart';
import 'package:tictask/features/tasks/bloc/task_bloc.dart';
import 'package:tictask/features/tasks/models/task.dart';

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
  late DateTime _startDate;
  late DateTime _endDate;
  late bool _ongoing;
  late bool _hasReminder;
  DateTime? _reminderTime;

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
      _ongoing = widget.task!.ongoing;
      _hasReminder = widget.task!.hasReminder;
      _reminderTime = widget.task!.reminderTime != null
          ? DateTime.fromMillisecondsSinceEpoch(widget.task!.reminderTime!)
          : null;
    }

    // Automatically focus the title field after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_titleFocus);
      }
    });
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
                                .requestFocus(_descriptionFocus);
                          },
                        ),
                        const SizedBox(height: 12),

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
                            // Optionally, open the date selector
                            // _showDateTimePicker(context);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Start date selector
                        GestureDetector(
                          onTap: () => _showDateTimePicker(context, true),
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
                                Text(
                                  DateFormat('EEE, MMM d, yyyy - hh:mm a')
                                      .format(_startDate),
                                  style: TextStyle(color: textColor),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: isDarkMode
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // End date selector
                        GestureDetector(
                          onTap: () => _showDateTimePicker(context, false),
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
                                Text(
                                  DateFormat('EEE, MMM d, yyyy - hh:mm a')
                                      .format(_endDate),
                                  style: TextStyle(color: textColor),
                                ),
                                Icon(
                                  Icons.calendar_today,
                                  color: isDarkMode
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Ongoing switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ongoing Task',
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
                        const SizedBox(height: 12),

                        // Reminder switch
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reminder',
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
                                });
                              },
                              activeColor: isDarkMode
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Reminder time selector
                        if (_hasReminder)
                          GestureDetector(
                            onTap: () => _showReminderPicker(context),
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
                                  Text(
                                    _reminderTime == null
                                        ? 'No reminder'
                                        : DateFormat(
                                            'EEE, MMM d, yyyy - hh:mm a',
                                          ).format(_reminderTime!),
                                    style: TextStyle(color: textColor),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: isDarkMode
                                        ? AppColors.darkPrimary
                                        : AppColors.lightPrimary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

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
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  void _showDateTimePicker(BuildContext context, bool isStartDate) {
    showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    ).then((selectedDate) {
      if (selectedDate != null) {
        // After choosing the date, show the time picker
        showTimePicker(
          context: context,
          initialTime:
              TimeOfDay.fromDateTime(isStartDate ? _startDate : _endDate),
        ).then((selectedTime) {
          if (selectedTime != null) {
            // Combine date and time
            setState(() {
              if (isStartDate) {
                _startDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
              } else {
                _endDate = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );
              }
            });
          }
        });
      }
    });
  }

  void _showReminderPicker(BuildContext context) {
    // Use current time if reminderTime is null
    final initialDateTime = _reminderTime ?? DateTime.now();

    showDatePicker(
      context: context,
      initialDate: initialDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    ).then((selectedDate) {
      if (selectedDate != null) {
        // After choosing the date, show the time picker
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initialDateTime),
        ).then((selectedTime) {
          if (selectedTime != null) {
            // Combine date and time
            setState(() {
              _reminderTime = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute,
              );
            });
          }
        });
      }
    });
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
            ),
          );
    }
  }
}
