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
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  bool _ongoing = false;
  bool _isLoading = true;
  Task? _task;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _estimatedPomodorosController = TextEditingController();
    _dueDate = DateTime.now();
    _dueTime = TimeOfDay.now();

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
        dueDate: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    setState(() {
      _task = task;
      _titleController.text = task.title;
      _descriptionController.text = task.description ?? '';
      _estimatedPomodorosController.text =
          task.estimatedPomodoros?.toString() ?? '';

      final dueDateTime = DateTime.fromMillisecondsSinceEpoch(task.dueDate);
      _dueDate = DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day);
      _dueTime = TimeOfDay(hour: dueDateTime.hour, minute: dueDateTime.minute);
      _ongoing = task.ongoing;
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
                    _buildDateTimeSelector(),
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

  Widget _buildDateTimeSelector() {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _dueDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (pickedDate != null) {
                setState(() {
                  _dueDate = pickedDate;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Due Date',
                border: OutlineInputBorder(),
              ),
              child: Text(dateFormat.format(_dueDate)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: _dueTime,
              );
              if (pickedTime != null) {
                setState(() {
                  _dueTime = pickedTime;
                });
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Due Time',
                border: OutlineInputBorder(),
              ),
              child: Text(_dueTime.format(context)),
            ),
          ),
        ),
      ],
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final dueDateTimeEpoch = DateTime(
        _dueDate.year,
        _dueDate.month,
        _dueDate.day,
        _dueTime.hour,
        _dueTime.minute,
      ).millisecondsSinceEpoch;

      int? estimatedPomodoros;
      if (_estimatedPomodorosController.text.isNotEmpty) {
        estimatedPomodoros = int.tryParse(_estimatedPomodorosController.text);
      }

      if (widget.taskId == null) {
        // Add new task
        context.read<TaskBloc>().add(
              AddTask(
                title: _titleController.text,
                description: _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                estimatedPomodoros: estimatedPomodoros,
                dueDate: DateTime.fromMillisecondsSinceEpoch(dueDateTimeEpoch),
                ongoing: _ongoing,
              ),
            );
      } else {
        // Update existing task
        context.read<TaskBloc>().add(
              UpdateTask(
                id: widget.taskId!,
                title: _titleController.text,
                description: _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                estimatedPomodoros: estimatedPomodoros,
                dueDate: DateTime.fromMillisecondsSinceEpoch(dueDateTimeEpoch),
                ongoing: _ongoing,
              ),
            );
      }
    }
  }
}
