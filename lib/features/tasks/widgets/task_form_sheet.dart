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
  late DateTime _dueDate;
  bool _ongoing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _estimatedPomodorosController = TextEditingController();
    _dueDate = DateTime.now();

    // Set values if editing
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _estimatedPomodorosController.text =
          widget.task!.estimatedPomodoros?.toString() ?? '';
      _dueDate = DateTime.fromMillisecondsSinceEpoch(widget.task!.dueDate);
      _ongoing = widget.task!.ongoing;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedPomodorosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDarkMode ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    ),
                    const SizedBox(height: 12),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
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
                    ),
                    const SizedBox(height: 12),

                    // Pomodoros field
                    TextFormField(
                      controller: _estimatedPomodorosController,
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
                    ),
                    const SizedBox(height: 12),

                    // Due date selector
                    GestureDetector(
                      onTap: () => _showDateTimePicker(context),
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
                                  .format(_dueDate),
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
            ],
          ),
        ),
      ),
    );
  }

  void _showDateTimePicker(BuildContext context) {
    showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2030),
    ).then((selectedDate) {
      if (selectedDate != null) {
        // After choosing the date, show the time picker
        showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_dueDate),
        ).then((selectedTime) {
          if (selectedTime != null) {
            // Combine date and time
            setState(() {
              _dueDate = DateTime(
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
              dueDate: _dueDate,
              ongoing: _ongoing,
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
              dueDate: _dueDate,
              ongoing: _ongoing,
            ),
          );
    }
  }
}
