

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tictask/app/theme/colors.dart';
import 'package:tictask/features/projects/domain/entities/project_entity.dart';
import 'package:tictask/features/projects/presentation/bloc/project_bloc.dart';

class ProjectFormWidget extends StatefulWidget {
  const ProjectFormWidget({
    required this.onComplete,
    super.key,
    this.project,
  });

  final ProjectEntity? project;
  final VoidCallback onComplete;

  @override
  State<ProjectFormWidget> createState() => _ProjectFormWidgetState();
}

class _ProjectFormWidgetState extends State<ProjectFormWidget> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedEmoji;
  int _selectedColorIndex = 0;

  // Predefined colors for projects
  final List<Color> _projectColors = [
    const Color(0xFF4A6572), // Default gray
    const Color(0xFFE57373), // Red
    const Color(0xFFF06292), // Pink
    const Color(0xFFBA68C8), // Purple
    const Color(0xFF9575CD), // Deep Purple
    const Color(0xFF7986CB), // Indigo
    const Color(0xFF64B5F6), // Blue
    const Color(0xFF4FC3F7), // Light Blue
    const Color(0xFF4DD0E1), // Cyan
    const Color(0xFF4DB6AC), // Teal
    const Color(0xFF81C784), // Green
    const Color(0xFFAED581), // Light Green
    const Color(0xFFDCE775), // Lime
    const Color(0xFFFFD54F), // Yellow
    const Color(0xFFFFB74D), // Orange
    const Color(0xFFFF8A65), // Deep Orange
  ];

  // Common emojis for projects
  final List<String> _commonEmojis = [
    '📝',
    '📚',
    '💼',
    '🏠',
    '🛒',
    '🍔',
    '💪',
    '🎮',
    '🎯',
    '✈️',
    '🏋️',
    '🎨',
    '🎬',
    '🎵',
    '👨‍💻',
    '🌱',
    '💰',
    '🔧',
    '🎓',
    '🎁',
    '📅',
    '📌',
    '🔖',
    '📊',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();

    // Set initial values if editing
    if (widget.project != null) {
      _nameController.text = widget.project!.name;
      _descriptionController.text = widget.project!.description ?? '';
      _selectedEmoji = widget.project!.emoji;

      // Find the color index
      final colorValue = widget.project!.color;
      final colorIndex =
          _projectColors.indexWhere((color) => color.value == colorValue);
      if (colorIndex != -1) {
        _selectedColorIndex = colorIndex;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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

    // Use a reasonable height for the sheet
    final sheetHeight = screenHeight * 0.7;

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
                          widget.project == null
                              ? 'New Project'
                              : 'Edit Project',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Project name field with emoji
                        Row(
                          children: [
                            // Emoji selector
                            GestureDetector(
                              onTap: _showEmojiPicker,
                              child: Container(
                                width: 60,
                                height: 60,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: _projectColors[_selectedColorIndex],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    _selectedEmoji ?? '📁',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            ),

                            // Name field
                            Expanded(
                              child: SizedBox(
                                height: 60,
                                child: TextFormField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Project name',
                                    filled: true,
                                    fillColor: isDarkMode
                                        ? AppColors.darkBackground
                                        : AppColors.lightBackground,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a project name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Description field
                        TextFormField(
                          controller: _descriptionController,
                          textInputAction: TextInputAction.done,
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
                        const SizedBox(height: 24),

                        // Color selection
                        Text(
                          'Project Color',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(
                            _projectColors.length,
                            (index) => GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColorIndex = index;
                                });
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _projectColors[index],
                                  shape: BoxShape.circle,
                                  border: _selectedColorIndex == index
                                      ? Border.all(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black,
                                          width: 2,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

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
                            onPressed: _saveProject,
                            child: Text(
                              widget.project == null
                                  ? 'Add Project'
                                  : 'Update Project',
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

  void _showEmojiPicker() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor =
        isDarkMode ? AppColors.darkOnSurface : AppColors.lightOnSurface;

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Emoji',
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
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _commonEmojis.map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedEmoji = emoji;
                      });
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      // Get current project bloc
      final projectBloc = context.read<ProjectBloc>();

      // Ensure a default emoji is set
      final emoji = _selectedEmoji ?? '📁';

      // Create or update project
      if (widget.project == null) {
        // Create new project
        projectBloc.add(
          AddProject(
            name: _nameController.text.trim(),
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text.trim(),
            color: _projectColors[_selectedColorIndex].value,
            emoji: emoji,
          ),
        );
      } else {
        // Update existing project
        projectBloc.add(
          UpdateProject(
            id: widget.project!.id,
            name: _nameController.text.trim(),
            description: _descriptionController.text.isEmpty
                ? null
                : _descriptionController.text.trim(),
            color: _projectColors[_selectedColorIndex].value,
            emoji: emoji,
          ),
        );
      }

      // Call onComplete to dismiss the sheet
      widget.onComplete();
    }
  }
}
