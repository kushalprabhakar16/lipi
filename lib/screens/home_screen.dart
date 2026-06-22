import 'dart:async';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../widgets/section_container.dart';
import '../widgets/task_card.dart';
import '../widgets/empty_state_card.dart';
import '../widgets/add_task_sheet.dart';
import '../services/task_storage_service.dart';
import '../services/notification_service.dart';

class LipiHomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const LipiHomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<LipiHomeScreen> createState() => _LipiHomeScreenState();
}

class _LipiHomeScreenState extends State<LipiHomeScreen> {
  // Flag to let user switch between populated demo data and empty states
  bool _useDemoData = true;

  // Local interactive memory list for the home screen UI
  late List<Task> _tasks;

  OverlayEntry? _undoOverlayEntry;
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    _tasks = TaskStorageService.getTasks();
    if (_useDemoData && _tasks.isEmpty) {
      _seedDemoData();
    } else {
      _sortTasks();
    }
  }

  @override
  void dispose() {
    _undoTimer?.cancel();
    _undoOverlayEntry?.remove();
    super.dispose();
  }

  void _sortTasks() {
    // Sort tasks by nearest due date/time first
    _tasks.sort((a, b) => a.dueDateTime.compareTo(b.dueDateTime));
  }

  void _seedDemoData() {
    final now = DateTime.now();
    final demoTasks = [
      Task(
        id: '1',
        title: 'Draft proposal review',
        dueDateTime: now.subtract(const Duration(days: 1)),
        importanceLevel: ImportanceLevel.red,
      ),
      Task(
        id: '2',
        title: 'Outline chapter 3 notes',
        dueDateTime: now,
        importanceLevel: ImportanceLevel.yellow,
      ),
      Task(
        id: '3',
        title: 'Deep breathing & screen break',
        dueDateTime: now,
        isCompleted: true,
        importanceLevel: ImportanceLevel.green,
      ),
      Task(
        id: '4',
        title: 'Gym session',
        dueDateTime: now.add(const Duration(days: 1)),
        importanceLevel: ImportanceLevel.orange,
      ),
      Task(
        id: '5',
        title: 'Submit weekly retrospective',
        dueDateTime: now.add(const Duration(days: 3)),
        importanceLevel: ImportanceLevel.green,
      ),
    ];

    // Synchronously add tasks to memory so the very first build() renders them instantly without layout shifts
    _tasks.addAll(demoTasks);
    _sortTasks();
    
    // Asynchronously save to Hive in the background without awaiting or causing setState loops
    for (var task in demoTasks) {
      TaskStorageService.saveTask(task);
    }
  }

  Future<void> _toggleItemCompletion(String id) async {
    print('DELETE CALLED: $id');
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final task = _tasks[index];
      task.isCompleted = !task.isCompleted;
      await TaskStorageService.saveTask(task);
      
      if (task.isCompleted) {
        await NotificationService().cancelNotification(task.id);
      } else {
        await NotificationService().scheduleTaskNotification(task);
      }
      
      setState(() {});
    }
  }

  Future<void> _deleteItem(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) return;
    
    final deletedTask = _tasks[index];

    await TaskStorageService.deleteTask(id);
    await NotificationService().cancelNotification(id);
    
    setState(() {
      _tasks.removeAt(index);
    });

    if (!mounted) return;

    _showCustomUndoToast(deletedTask);
  }

  void _showCustomUndoToast(Task deletedTask) {
    _undoTimer?.cancel();
    _undoOverlayEntry?.remove();
    _undoOverlayEntry = null;

    final overlayState = Overlay.of(context);
    
    _undoOverlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        return Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Task deleted',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      _undoTimer?.cancel();
                      _undoOverlayEntry?.remove();
                      _undoOverlayEntry = null;
                      
                      await TaskStorageService.saveTask(deletedTask);
                      await NotificationService().scheduleTaskNotification(deletedTask);
                      setState(() {
                        _tasks.add(deletedTask);
                        _sortTasks();
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.inversePrimary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Undo', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_undoOverlayEntry!);
    
    _undoTimer = Timer(const Duration(seconds: 4), () {
      _undoOverlayEntry?.remove();
      _undoOverlayEntry = null;
    });
  }

  Future<void> _openAddTaskSheet([Task? existingTask]) async {
    final newTask = await AddTaskSheet.show(context, existingTask: existingTask);
    if (newTask != null) {
      await TaskStorageService.saveTask(newTask);
      await NotificationService().scheduleTaskNotification(newTask);
      setState(() {
        if (existingTask != null) {
          final index = _tasks.indexWhere((t) => t.id == existingTask.id);
          if (index != -1) {
            _tasks[index] = newTask;
          } else {
            _tasks.add(newTask);
          }
        } else {
          _tasks.add(newTask);
        }
        _sortTasks();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Filter items depending on if we are in demo data mode or showing the clean empty states
    final activeTasks = _useDemoData ? _tasks : <Task>[];

    final overdueTasks = activeTasks.where((task) => task.isOverdue).toList();
    final todayTasks = activeTasks.where((task) => task.isToday).toList();
    final upcomingTasks = activeTasks.where((task) => task.isUpcoming).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Elegant, minimalist app header instead of a heavy AppBar
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'lipi',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontFamily: 'serif', // Gives a classic literary calm look
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: [
                        // Subtle toggle for empty states vs populated lists
                        IconButton(
                          icon: Icon(
                            _useDemoData ? Icons.filter_vintage_outlined : Icons.filter_vintage,
                            size: 20,
                            color: _useDemoData
                                ? colorScheme.onSurface.withValues(alpha: 0.4)
                                : colorScheme.primary,
                          ),
                          tooltip: _useDemoData ? 'Show empty states' : 'Show demo items',
                          onPressed: () {
                            setState(() {
                              _useDemoData = !_useDemoData;
                              if (_useDemoData && _tasks.isEmpty) {
                                _seedDemoData();
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        // Sleek, minimal theme toggle
                        IconButton(
                          icon: Icon(
                            widget.isDarkMode ? Icons.wb_sunny_outlined : Icons.mode_night_outlined,
                            size: 20,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          tooltip: 'Toggle Theme',
                          onPressed: widget.onToggleTheme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // Overdue Section (Renders gently at the top when items exist or when empty state is active)
            if (overdueTasks.isNotEmpty || !_useDemoData)
              SliverToBoxAdapter(
                child: SectionContainer(
                  title: 'Overdue',
                  icon: Icons.hourglass_empty_rounded,
                  titleColor: colorScheme.error.withValues(alpha: 0.85),
                  backgroundColor: colorScheme.errorContainer.withValues(alpha: widget.isDarkMode ? 0.05 : 0.1),
                  borderColor: colorScheme.error.withValues(alpha: widget.isDarkMode ? 0.12 : 0.18),
                  isDarkMode: widget.isDarkMode,
                  children: overdueTasks.isNotEmpty
                      ? overdueTasks.map((task) => TaskCard(
                            item: task,
                            isDarkMode: widget.isDarkMode,
                            onToggleCompletion: _toggleItemCompletion,
                            onDelete: _deleteItem,
                            onTap: () => _openAddTaskSheet(task),
                          )).toList()
                      : [
                          EmptyStateCard(
                            icon: Icons.done_all_rounded,
                            message: 'Nothing overdue. Your mind is clear.',
                            isDarkMode: widget.isDarkMode,
                          )
                        ],
                ),
              ),

            // Today Section (Always shown)
            SliverToBoxAdapter(
              child: SectionContainer(
                title: 'Today',
                icon: Icons.today_rounded,
                titleColor: colorScheme.primary,
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: widget.isDarkMode ? 0.08 : 0.14),
                borderColor: colorScheme.primary.withValues(alpha: widget.isDarkMode ? 0.18 : 0.28),
                isProminent: true,
                isDarkMode: widget.isDarkMode,
                children: todayTasks.isNotEmpty
                    ? todayTasks.map((task) => TaskCard(
                          item: task,
                          isDarkMode: widget.isDarkMode,
                          onToggleCompletion: _toggleItemCompletion,
                          onDelete: _deleteItem,
                          onTap: () => _openAddTaskSheet(task),
                        )).toList()
                    : [
                        EmptyStateCard(
                          icon: Icons.calendar_today_outlined,
                          message: 'All clear today. Rest, write, or plan.',
                          isDarkMode: widget.isDarkMode,
                          actionLabel: 'Capture a thought',
                          onAction: _openAddTaskSheet,
                        )
                      ],
              ),
            ),

            // Upcoming Section (Always shown)
            SliverToBoxAdapter(
              child: SectionContainer(
                title: 'Upcoming',
                icon: Icons.next_plan_outlined,
                titleColor: colorScheme.onSurface.withValues(alpha: 0.65),
                backgroundColor: colorScheme.onSurface.withValues(alpha: widget.isDarkMode ? 0.03 : 0.05),
                borderColor: colorScheme.onSurface.withValues(alpha: widget.isDarkMode ? 0.08 : 0.12),
                isDarkMode: widget.isDarkMode,
                children: upcomingTasks.isNotEmpty
                    ? upcomingTasks.map((task) => TaskCard(
                          item: task,
                          isDarkMode: widget.isDarkMode,
                          onToggleCompletion: _toggleItemCompletion,
                          onDelete: _deleteItem,
                          onTap: () => _openAddTaskSheet(task),
                        )).toList()
                    : [
                        EmptyStateCard(
                          icon: Icons.wb_twilight_outlined,
                          message: 'No upcoming reminders. Quiet ahead.',
                          isDarkMode: widget.isDarkMode,
                        )
                      ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for FAB
          ],
        ),
      ),

      // Minimalist M3 Circular Floating Action Button
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: widget.isDarkMode ? 0.15 : 0.25),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openAddTaskSheet,
          elevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: colorScheme.primary.withValues(alpha: widget.isDarkMode ? 0.25 : 0.15),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            size: 26,
          ),
        ),
      ),
    );
  }
}
