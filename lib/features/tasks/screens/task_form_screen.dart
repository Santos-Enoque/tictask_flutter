import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tictask/app/widgets/app_scaffold.dart';
import 'package:tictask/features/tasks/bloc/task_bloc.dart';
import 'package:tictask/features/tasks/models/task.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.taskId});
  final String? taskId;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedPomodorosController;
  late DateTime _taskDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _ongoing = false;
  bool _hasReminder = false;
  DateTime? _reminderTime;
  bool _isLoading = true;
  Task? _task;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _estimatedPomodorosController = TextEditingController();
    final now = DateTime.now();
    _taskDate = now;
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay.fromDateTime(now.add(const Duration(hours: 1)));
    _ongoing = false;
    _hasReminder = false;

    // Load task if we're editing
    if (widget.taskId != null) {
      _loadTask();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadTask() async {
    final taskBloc = context.read<TaskBloc>();
    final tasks = await context.read<TaskBloc>().repository.getAllTasks();
    final task = tasks.firstWhere(
      (t) => t.id == widget.taskId,
      orElse: () => Task.create(
        title: '',
        startDate: DateTime.now().millisecondsSinceEpoch,
        endDate:
            DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch,
      ),
    );

    setState(() {
      _task = task;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _estimatedPomodorosController.text =
          task.estimatedPomodoros?.toString() ?? '';

      final startDateTime = DateTime.fromMillisecondsSinceEpoch(task.startDate);
      _taskDate =
          DateTime(startDateTime.year, startDateTime.month, startDateTime.day);
      _startTime =
          TimeOfDay(hour: startDateTime.hour, minute: startDateTime.minute);

      final endDateTime = DateTime.fromMillisecondsSinceEpoch(task.endDate);
      _endTime = TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute);

      _ongoing = task.ongoing;
      _hasReminder = task.hasReminder;
      _reminderTime = task.reminderTime != null
          ? DateTime.fromMillisecondsSinceEpoch(task.reminderTime!)
          : null;
      _isLoading = false;
    });
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
    return AppScaffold(
      title: widget.taskId == null ? 'Add Task' : 'Edit Task',
      showBottomNav: false,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : BlocListener<TaskBloc, TaskState>(
              listener: (context, state) {
                if (state is TaskActionSuccess) {
                  context.pop();
                } else if (state is TaskError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _estimatedPomodorosController,
                      decoration: const InputDecoration(
                        labelText: 'Estimated Pomodoros',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    _buildDateSelector(),
                    const SizedBox(height: 16),
                    _buildTimeRangeSelector(),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Ongoing Task'),
                      subtitle: const Text('Task repeats daily'),
                      value: _ongoing,
                      onChanged: (value) {
                        setState(() {
                          _ongoing = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Set Reminder'),
                      subtitle:
                          const Text('Get notified before the task starts'),
                      value: _hasReminder,
                      onChanged: (value) {
                        setState(() {
                          _hasReminder = value;
                          if (value && _reminderTime == null) {
                            final startDateTime = DateTime(
                              _taskDate.year,
                              _taskDate.month,
                              _taskDate.day,
                              _startTime.hour,
                              _startTime.minute,
                            );
                            _reminderTime = startDateTime
                                .subtract(const Duration(minutes: 30));
                          }
                        });
                      },
                    ),
                    if (_hasReminder) ...[
                      const SizedBox(height: 16),
                      _buildReminderSelector(),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveTask,
                      child: Text(
                        widget.taskId == null ? 'Add Task' : 'Update Task',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDateSelector() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            await _showCupertinoDatePicker();
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(dateFormat.format(_taskDate)),
              trailing: const Icon(Icons.arrow_drop_down),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCupertinoDatePicker() async {
    DateTime? pickedDate = _taskDate;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        setState(() {
                          _taskDate = pickedDate!;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: _taskDate,
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2030),
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

  Widget _buildTimeRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Duration (Same Day)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              children: [
                // Start Time
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Start Time'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _startTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time),
                    ],
                  ),
                  onTap: () async {
                    await _showCupertinoTimePicker(isStartTime: true);
                  },
                ),

                const Divider(height: 1),

                // End Time
                ListTile(
                  leading: const Icon(Icons.stop_circle_outlined),
                  title: const Text('End Time'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _endTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time),
                    ],
                  ),
                  onTap: () async {
                    await _showCupertinoTimePicker(isStartTime: false);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCupertinoTimePicker({required bool isStartTime}) async {
    final initialTime = isStartTime ? _startTime : _endTime;
    final initialDateTime = DateTime(
      _taskDate.year,
      _taskDate.month,
      _taskDate.day,
      initialTime.hour,
      initialTime.minute,
    );
    DateTime? pickedDateTime = initialDateTime;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        if (pickedDateTime != null) {
                          final newTimeOfDay = TimeOfDay(
                            hour: pickedDateTime!.hour,
                            minute: pickedDateTime!.minute,
                          );

                          setState(() {
                            if (isStartTime) {
                              _startTime = newTimeOfDay;
                              // Ensure end time is after start time
                              if (_endTime.hour < _startTime.hour ||
                                  (_endTime.hour == _startTime.hour &&
                                      _endTime.minute < _startTime.minute)) {
                                _endTime = TimeOfDay(
                                  hour: (_startTime.hour + 1) % 24,
                                  minute: _startTime.minute,
                                );
                              }
                            } else {
                              // Validate that end time is after start time
                              final startDateTime = DateTime(
                                _taskDate.year,
                                _taskDate.month,
                                _taskDate.day,
                                _startTime.hour,
                                _startTime.minute,
                              );
                              if (pickedDateTime!.isBefore(startDateTime)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'End time must be after start time',
                                    ),
                                  ),
                                );
                              } else {
                                _endTime = newTimeOfDay;
                              }
                            }
                          });
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialDateTime,
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                  onDateTimeChanged: (DateTime newDateTime) {
                    pickedDateTime = newDateTime;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReminderSelector() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final initialDateTime = _reminderTime ?? DateTime.now();
    final timeString = _reminderTime == null
        ? 'Select time'
        : TimeOfDay(
            hour: _reminderTime!.hour,
            minute: _reminderTime!.minute,
          ).format(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminder Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  await _showCupertinoReminderDatePicker();
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _reminderTime == null
                        ? 'Select date'
                        : dateFormat.format(_reminderTime!),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  await _showCupertinoReminderTimePicker();
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(timeString),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showCupertinoReminderDatePicker() async {
    final initialDateTime = _reminderTime ?? DateTime.now();
    DateTime? pickedDate = initialDateTime;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        if (_reminderTime != null) {
                          setState(() {
                            _reminderTime = DateTime(
                              pickedDate!.year,
                              pickedDate!.month,
                              pickedDate!.day,
                              _reminderTime!.hour,
                              _reminderTime!.minute,
                            );
                          });
                        } else {
                          final now = DateTime.now();
                          setState(() {
                            _reminderTime = DateTime(
                              pickedDate!.year,
                              pickedDate!.month,
                              pickedDate!.day,
                              now.hour,
                              now.minute,
                            );
                          });
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialDateTime,
                  mode: CupertinoDatePickerMode.date,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2030),
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

  Future<void> _showCupertinoReminderTimePicker() async {
    final initialDateTime = _reminderTime ?? DateTime.now();
    DateTime? pickedTime = initialDateTime;

    await showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    CupertinoButton(
                      child: const Text('Done'),
                      onPressed: () {
                        if (_reminderTime != null) {
                          setState(() {
                            _reminderTime = DateTime(
                              _reminderTime!.year,
                              _reminderTime!.month,
                              _reminderTime!.day,
                              pickedTime!.hour,
                              pickedTime!.minute,
                            );
                          });
                        } else {
                          final now = DateTime.now();
                          setState(() {
                            _reminderTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              pickedTime!.hour,
                              pickedTime!.minute,
                            );
                          });
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: initialDateTime,
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

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final startDateTime = DateTime(
        _taskDate.year,
        _taskDate.month,
        _taskDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _taskDate.year,
        _taskDate.month,
        _taskDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      int? estimatedPomodoros;
      if (_estimatedPomodorosController.text.isNotEmpty) {
        estimatedPomodoros = int.tryParse(_estimatedPomodorosController.text);
      }

      if (widget.taskId == null) {
        context.read<TaskBloc>().add(
              AddTask(
                title: _titleController.text,
                description: _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                estimatedPomodoros: estimatedPomodoros,
                startDate: startDateTime,
                endDate: endDateTime,
                ongoing: _ongoing,
                hasReminder: _hasReminder,
                reminderTime: _reminderTime,
              ),
            );
      } else {
        context.read<TaskBloc>().add(
              UpdateTask(
                id: widget.taskId!,
                title: _titleController.text,
                description: _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                estimatedPomodoros: estimatedPomodoros,
                startDate: startDateTime,
                endDate: endDateTime,
                ongoing: _ongoing,
                hasReminder: _hasReminder,
                reminderTime: _reminderTime,
              ),
            );
      }
    }
  }
}
