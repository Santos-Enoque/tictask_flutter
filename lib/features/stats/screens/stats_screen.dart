import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:tictask/app/constants/enums.dart';
import 'package:tictask/features/tasks/domain/entities/task_entity.dart';
import 'package:tictask/features/tasks/domain/repositories/i_task_repository.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/domain/repositories/i_project_repository.dart';
import 'package:tictask/injection_container.dart' as di;

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, this.showNavBar = true});

  final bool showNavBar;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final ITaskRepository _taskRepository = di.sl<ITaskRepository>();
  final IProjectRepository _projectRepository = di.sl<IProjectRepository>();

  // Data for charts
  List<TaskEntity> _tasks = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Date range for stats
  final DateTime _endDate = DateTime.now();
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));

  // Add this field to the state class
  Map<String, String> _projectNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
    _loadProjectNames();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasks =
          await _taskRepository.getTasksInDateRange(_startDate, _endDate);
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
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

  // Add this method to load project names
  Future<void> _loadProjectNames() async {
    final projects = await _projectRepository.getAllProjects();
    setState(() {
      _projectNames = {for (var p in projects) p.id: p.name};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Focus'),
            Tab(text: 'Tasks'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildFocusTab(),
                _buildTasksTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    // Calculate stats
    final totalTasks = _tasks.length;
    final completedTasks =
        _tasks.where((task) => task.status == TaskStatus.completed).length;
    final completionRate = totalTasks > 0
        ? (completedTasks / totalTasks * 100).toStringAsFixed(1)
        : '0';
    final totalPomodoros =
        _tasks.fold<int>(0, (sum, task) => sum + task.pomodorosCompleted);

    // Get screen width to calculate card width
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        (screenWidth - 48) / 2; // 48 = padding (16*2) + spacing (16)
    final cardHeight = cardWidth * 0.45; // Further reduced aspect ratio

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards in a grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Total Tasks',
                  totalTasks.toString(),
                  Icons.task_alt,
                  Colors.blue,
                ),
              ),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Completed',
                  '$completedTasks',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Completion Rate',
                  '$completionRate%',
                  Icons.percent,
                  Colors.orange,
                ),
              ),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Focus Sessions',
                  totalPomodoros.toString(),
                  Icons.timer,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Task Completion Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: _buildCompletionTrendChart(),
          ),

          const SizedBox(height: 24),
          const Text(
            'Focus Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildContributionGrid(),
        ],
      ),
    );
  }

  Widget _buildFocusTab() {
    // Calculate focus stats
    final totalPomodoros =
        _tasks.fold<int>(0, (sum, task) => sum + task.pomodorosCompleted);
    final totalFocusMinutes = totalPomodoros * 25; // 25 minutes per pomodoro

    // Calculate hours and remaining minutes for better readability
    final hours = totalFocusMinutes ~/ 60;
    final minutes = totalFocusMinutes % 60;

    // Calculate average daily focus sessions
    final uniqueDays = _tasks
        .where((task) => task.pomodorosCompleted > 0)
        .map((task) => DateTime.fromMillisecondsSinceEpoch(task.updatedAt))
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet()
        .length;

    final averageDailySessions =
        uniqueDays > 0 ? (totalPomodoros / uniqueDays).toStringAsFixed(1) : '0';

    // Get screen width to calculate card width
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 48) / 2;
    final cardHeight = cardWidth * 0.45;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Total Focus Sessions',
                  totalPomodoros.toString(),
                  Icons.timer,
                  Colors.purple,
                ),
              ),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Total Focus Time',
                  '${hours}h ${minutes}m',
                  Icons.hourglass_bottom,
                  Colors.indigo,
                ),
              ),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Active Days',
                  uniqueDays.toString(),
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Avg. Daily Sessions',
                  averageDailySessions,
                  Icons.auto_graph,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Daily Focus Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: _buildDailyFocusChart(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Focus Distribution by Day of Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: _buildWeekdayDistributionChart(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Focus Activity Heatmap',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildContributionGrid(),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    // Calculate task stats
    final totalTasks = _tasks.length;
    final completedTasks =
        _tasks.where((task) => task.status == TaskStatus.completed).length;
    final inProgressTasks =
        _tasks.where((task) => task.status == TaskStatus.inProgress).length;
    final todoTasks =
        _tasks.where((task) => task.status == TaskStatus.todo).length;

    // Group tasks by project
    final tasksByProject = <String, int>{};
    for (final task in _tasks) {
      tasksByProject[task.projectId] =
          (tasksByProject[task.projectId] ?? 0) + 1;
    }

    // Get screen width to calculate card width
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth =
        (screenWidth - 48) / 2; // 48 = padding (16*2) + spacing (16)
    final cardHeight = cardWidth * 0.45; // Further reduced aspect ratio

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards in a grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Total Tasks',
                  totalTasks.toString(),
                  Icons.task_alt,
                  Colors.blue,
                ),
              ),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'Completed',
                  completedTasks.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'In Progress',
                  inProgressTasks.toString(),
                  Icons.pending_actions,
                  Colors.orange,
                ),
              ),
              SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildStatCard(
                  'To Do',
                  todoTasks.toString(),
                  Icons.assignment,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Task Status Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 250,
            child: _buildTaskStatusChart(),
          ),

          const SizedBox(height: 24),
          const Text(
            'Tasks by Project',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: _buildTasksByProjectChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon and title in a row
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Value (large and bold)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionTrendChart() {
    // Group tasks by day
    final tasksByDay = <DateTime, int>{};
    final completedByDay = <DateTime, int>{};

    // Create a list of all days in the range
    final days = <DateTime>[];
    for (var i = 0; i <= _endDate.difference(_startDate).inDays; i++) {
      final day = _startDate.add(Duration(days: i));
      final dateOnly = DateTime(day.year, day.month, day.day);
      days.add(dateOnly);
      tasksByDay[dateOnly] = 0;
      completedByDay[dateOnly] = 0;
    }

    // Count tasks and completed tasks by day
    for (final task in _tasks) {
      final date = DateTime.fromMillisecondsSinceEpoch(task.startDate);
      final dateOnly = DateTime(date.year, date.month, date.day);

      if (tasksByDay.containsKey(dateOnly)) {
        tasksByDay[dateOnly] = (tasksByDay[dateOnly] ?? 0) + 1;

        if (task.status == TaskStatus.completed) {
          completedByDay[dateOnly] = (completedByDay[dateOnly] ?? 0) + 1;
        }
      }
    }

    // Create chart data
    final chartData = days.map((day) {
      return CompletionData(
        day,
        tasksByDay[day] ?? 0,
        completedByDay[day] ?? 0,
      );
    }).toList();

    // Only keep the last 30 days for better visualization
    final last30Days = chartData.length > 30
        ? chartData.sublist(chartData.length - 30)
        : chartData;

    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('MMM d'),
        intervalType: DateTimeIntervalType.days,
        interval: 5,
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: const NumericAxis(
        minimum: 0,
        interval: 2,
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0),
      ),
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<CompletionData, DateTime>>[
        ColumnSeries<CompletionData, DateTime>(
          name: 'Total Tasks',
          dataSource: last30Days,
          xValueMapper: (CompletionData data, _) => data.date,
          yValueMapper: (CompletionData data, _) => data.total,
          color: Colors.blue.withOpacity(0.7),
        ),
        ColumnSeries<CompletionData, DateTime>(
          name: 'Completed',
          dataSource: last30Days,
          xValueMapper: (CompletionData data, _) => data.date,
          yValueMapper: (CompletionData data, _) => data.completed,
          color: Colors.green.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildDailyFocusChart() {
    // Group pomodoros by day
    final pomodorosByDay = <DateTime, int>{};

    // Create a list of all days in the range
    final days = <DateTime>[];
    for (var i = 0; i <= _endDate.difference(_startDate).inDays; i++) {
      final day = _startDate.add(Duration(days: i));
      final dateOnly = DateTime(day.year, day.month, day.day);
      days.add(dateOnly);
      pomodorosByDay[dateOnly] = 0;
    }

    // Count pomodoros by day
    for (final task in _tasks) {
      if (task.pomodorosCompleted > 0) {
        final date = DateTime.fromMillisecondsSinceEpoch(task.updatedAt);
        final dateOnly = DateTime(date.year, date.month, date.day);

        if (pomodorosByDay.containsKey(dateOnly)) {
          pomodorosByDay[dateOnly] =
              (pomodorosByDay[dateOnly] ?? 0) + task.pomodorosCompleted;
        }
      }
    }

    // Create chart data
    final chartData = days.map((day) {
      return FocusData(
        day,
        pomodorosByDay[day] ?? 0,
      );
    }).toList();

    // Only keep the last 30 days for better visualization
    final last30Days = chartData.length > 30
        ? chartData.sublist(chartData.length - 30)
        : chartData;

    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('MMM d'),
        intervalType: DateTimeIntervalType.days,
        interval: 5,
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: const NumericAxis(
        minimum: 0,
        interval: 2,
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<FocusData, DateTime>>[
        SplineAreaSeries<FocusData, DateTime>(
          name: 'Focus Sessions',
          dataSource: last30Days,
          xValueMapper: (FocusData data, _) => data.date,
          yValueMapper: (FocusData data, _) => data.sessions,
          color: Colors.purple.withOpacity(0.7),
          borderColor: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildWeekdayDistributionChart() {
    // Group pomodoros by weekday
    final pomodorosByWeekday = List<int>.filled(7, 0); // 0 = Monday, 6 = Sunday

    // Count pomodoros by weekday
    for (final task in _tasks) {
      if (task.pomodorosCompleted > 0) {
        final date = DateTime.fromMillisecondsSinceEpoch(task.updatedAt);
        final weekday = date.weekday - 1; // Convert to 0-based index
        pomodorosByWeekday[weekday] += task.pomodorosCompleted;
      }
    }

    // Create chart data
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final chartData = List<WeekdayData>.generate(
      7,
      (index) => WeekdayData(weekdays[index], pomodorosByWeekday[index]),
    );

    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
      ),
      primaryYAxis: const NumericAxis(
        minimum: 0,
        interval: 5,
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries<WeekdayData, String>>[
        ColumnSeries<WeekdayData, String>(
          dataSource: chartData,
          xValueMapper: (WeekdayData data, _) => data.weekday,
          yValueMapper: (WeekdayData data, _) => data.sessions,
          pointColorMapper: (WeekdayData data, _) {
            // Weekend days in a different color
            return data.weekday == 'Sat' || data.weekday == 'Sun'
                ? Colors.orange
                : Colors.purple;
          },
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildTaskStatusChart() {
    // Count tasks by status
    final completedTasks =
        _tasks.where((task) => task.status == TaskStatus.completed).length;
    final inProgressTasks =
        _tasks.where((task) => task.status == TaskStatus.inProgress).length;
    final todoTasks =
        _tasks.where((task) => task.status == TaskStatus.todo).length;

    // Create chart data
    final chartData = [
      StatusData('Completed', completedTasks, Colors.green),
      StatusData('In Progress', inProgressTasks, Colors.orange),
      StatusData('To Do', todoTasks, Colors.red),
    ];

    return SfCircularChart(
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CircularSeries>[
        DoughnutSeries<StatusData, String>(
          dataSource: chartData,
          xValueMapper: (StatusData data, _) => data.status,
          yValueMapper: (StatusData data, _) => data.count,
          pointColorMapper: (StatusData data, _) => data.color,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
          ),
          innerRadius: '60%',
        ),
      ],
    );
  }

  Widget _buildTasksByProjectChart() {
    final tasksByProject = <String, Map<String, int>>{};

    for (final task in _tasks) {
      final projectName = _projectNames[task.projectId] ?? 'Unknown Project';
      final projectData = tasksByProject[task.projectId] ??
          {
            'count': 0,
            'completed': 0,
          };

      projectData['count'] = (projectData['count'] ?? 0) + 1;
      if (task.status == TaskStatus.completed) {
        projectData['completed'] = (projectData['completed'] ?? 0) + 1;
      }

      tasksByProject[task.projectId] = projectData;
    }

    // Sort projects by task count
    final sortedProjects = tasksByProject.entries.toList()
      ..sort(
          (a, b) => (b.value['count'] ?? 0).compareTo(a.value['count'] ?? 0));

    // Create chart data (limit to top 8 projects for better readability)
    final chartData = sortedProjects.take(8).map((entry) {
      final projectName = entry.key == 'inbox'
          ? 'Inbox'
          : _projectNames[entry.key] ?? 'Unknown Project';
      final displayName = projectName.length > 15
          ? '${projectName.substring(0, 12)}...'
          : projectName;

      return ProjectData(
        displayName,
        entry.value['count'] ?? 0,
        entry.value['completed'] ?? 0,
      );
    }).toList();

    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(
        majorGridLines: MajorGridLines(width: 0),
        labelIntersectAction: AxisLabelIntersectAction.rotate45,
        labelStyle: TextStyle(fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        interval: chartData.isEmpty ? 1 : null,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
      ),
      legend: const Legend(
        isVisible: true,
        position: LegendPosition.bottom,
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        // Add custom tooltip format to show full project name
        format: 'Project: point.x\nTotal: point.y',
      ),
      series: <CartesianSeries<ProjectData, String>>[
        ColumnSeries<ProjectData, String>(
          name: 'Total Tasks',
          dataSource: chartData,
          xValueMapper: (ProjectData data, _) => data.projectId,
          yValueMapper: (ProjectData data, _) => data.count,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          color: Colors.blue.withOpacity(0.7),
        ),
        ColumnSeries<ProjectData, String>(
          name: 'Completed',
          dataSource: chartData,
          xValueMapper: (ProjectData data, _) => data.projectId,
          yValueMapper: (ProjectData data, _) => data.completed,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
          color: Colors.green.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildContributionGrid() {
    // Calculate the number of weeks to display (13 weeks = ~3 months)
    const weeksToShow = 13;
    const daysPerWeek = 7;

    // Group pomodoros by day
    final pomodorosByDay = <DateTime, int>{};

    // Create a grid of all days in the range
    final days = <DateTime>[];
    final endDate = DateTime.now();
    final startDate = DateTime.now()
        .subtract(const Duration(days: weeksToShow * daysPerWeek - 1));

    for (var i = 0; i <= endDate.difference(startDate).inDays; i++) {
      final day = startDate.add(Duration(days: i));
      final dateOnly = DateTime(day.year, day.month, day.day);
      days.add(dateOnly);
      pomodorosByDay[dateOnly] = 0;
    }

    // Count pomodoros by day
    for (final task in _tasks) {
      if (task.pomodorosCompleted > 0) {
        final date = DateTime.fromMillisecondsSinceEpoch(task.updatedAt);
        final dateOnly = DateTime(date.year, date.month, date.day);

        if (pomodorosByDay.containsKey(dateOnly)) {
          pomodorosByDay[dateOnly] =
              (pomodorosByDay[dateOnly] ?? 0) + task.pomodorosCompleted;
        }
      }
    }

    // Organize days into weeks
    final weeks = <List<DateTime>>[];
    for (var i = 0; i < days.length; i += daysPerWeek) {
      final end = i + daysPerWeek;
      weeks.add(days.sublist(i, end > days.length ? days.length : end));
    }

    // Function to get color based on pomodoro count
    Color getColorForCount(int count) {
      if (count == 0) return Colors.grey.shade200;
      if (count < 3) return Colors.green.shade100;
      if (count < 5) return Colors.green.shade300;
      if (count < 8) return Colors.green.shade500;
      return Colors.green.shade700;
    }

    // Build the grid
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day labels
        const Padding(
          padding: EdgeInsets.only(left: 32, bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Mon', style: TextStyle(fontSize: 10)),
              Text('Wed', style: TextStyle(fontSize: 10)),
              Text('Fri', style: TextStyle(fontSize: 10)),
              Text('Sun', style: TextStyle(fontSize: 10)),
            ],
          ),
        ),

        // Grid
        SizedBox(
          height: 140,
          child: Row(
            children: [
              // Month labels
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('MMM').format(startDate),
                    style: const TextStyle(fontSize: 10),
                  ),
                  if (startDate.month != endDate.month)
                    Text(
                      DateFormat('MMM').format(endDate),
                      style: const TextStyle(fontSize: 10),
                    ),
                ],
              ),
              const SizedBox(width: 4),

              // Contribution grid
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: weeks.map((week) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: week.map((day) {
                        final count = pomodorosByDay[day] ?? 0;
                        return Tooltip(
                          message:
                              '${DateFormat('MMM d').format(day)}: $count sessions',
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: getColorForCount(count),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Less', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green.shade500,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 2),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              const Text('More', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

// Data classes for charts
class CompletionData {
  CompletionData(this.date, this.total, this.completed);
  final DateTime date;
  final int total;
  final int completed;
}

class FocusData {
  FocusData(this.date, this.sessions);
  final DateTime date;
  final int sessions;
}

class WeekdayData {
  WeekdayData(this.weekday, this.sessions);
  final String weekday;
  final int sessions;
}

class StatusData {
  StatusData(this.status, this.count, this.color);
  final String status;
  final int count;
  final Color color;
}

class ProjectData {
  ProjectData(this.projectId, this.count, this.completed);
  final String projectId;
  final int count;
  final int completed;
}
