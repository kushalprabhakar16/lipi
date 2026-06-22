import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class AddTaskSheet extends StatefulWidget {
  final Task? existingTask;

  const AddTaskSheet({super.key, this.existingTask});

  static Future<Task?> show(BuildContext context, {Task? existingTask}) {
    return showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => AddTaskSheet(existingTask: existingTask),
    );
  }

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class ParsedData {
  final DateTime? date;
  final TimeOfDay? time;
  final ImportanceLevel? importance;
  final String cleanTitle;

  ParsedData({this.date, this.time, this.importance, required this.cleanTitle});
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  late final TextEditingController _titleController;
  DateTime? _manualDate;
  TimeOfDay? _manualTime;
  late ImportanceLevel _manualImportance;
  late ReminderTiming _selectedReminder;

  DateTime? _parsedDate;
  TimeOfDay? _parsedTime;
  ImportanceLevel? _parsedImportance;

  bool _userEditedDate = false;
  bool _userEditedTime = false;
  bool _userEditedImportance = false;

  DateTime? get _effectiveDate => _userEditedDate ? _manualDate : (_parsedDate ?? _manualDate);
  TimeOfDay? get _effectiveTime => _userEditedTime ? _manualTime : (_parsedTime ?? _manualTime);
  ImportanceLevel get _effectiveImportance => _userEditedImportance ? _manualImportance : (_parsedImportance ?? _manualImportance);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTask?.title ?? '');
    _titleController.addListener(_onTitleChanged);
    
    if (widget.existingTask != null) {
      final dt = widget.existingTask!.dueDateTime;
      _manualDate = dt;
      _manualTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _manualImportance = widget.existingTask!.importanceLevel;
      _selectedReminder = widget.existingTask!.reminderBefore;
    } else {
      _manualImportance = ImportanceLevel.green;
      _selectedReminder = ReminderTiming.none;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    final parsed = _parseInputText(_titleController.text);
    if (_parsedDate != parsed.date || _parsedTime != parsed.time || _parsedImportance != parsed.importance) {
      setState(() {
        _parsedDate = parsed.date;
        _parsedTime = parsed.time;
        _parsedImportance = parsed.importance;
      });
    }
  }

  Color _getImportanceColor(ImportanceLevel level, bool isDarkMode) {
    switch (level) {
      case ImportanceLevel.green:
        return isDarkMode ? const Color(0xFF4C8C64) : const Color(0xFFA5D6A7); // Pastel Green
      case ImportanceLevel.yellow:
        return isDarkMode ? const Color(0xFF9E8B4C) : const Color(0xFFFFF59D); // Pastel Yellow
      case ImportanceLevel.orange:
        return isDarkMode ? const Color(0xFFB57045) : const Color(0xFFFFCC80); // Pastel Orange
      case ImportanceLevel.red:
        return isDarkMode ? const Color(0xFFB54C4C) : const Color(0xFFEF9A9A); // Pastel Red
    }
  }

  String _getReminderText(ReminderTiming timing) {
    switch (timing) {
      case ReminderTiming.none: return 'None';
      case ReminderTiming.fiveMins: return '5 mins before';
      case ReminderTiming.tenMins: return '10 mins before';
      case ReminderTiming.thirtyMins: return '30 mins before';
      case ReminderTiming.oneHour: return '1 hour before';
      case ReminderTiming.oneDay: return '1 day before';
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _effectiveDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _userEditedDate = true;
        _manualDate = date;
        // Default to current time if no time is selected yet to make it easier
        _manualTime ??= _parsedTime ?? TimeOfDay.now();
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _effectiveTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _userEditedTime = true;
        _manualTime = time;
        _manualDate ??= _parsedDate ?? DateTime.now();
      });
    }
  }

  ParsedData _parseInputText(String input) {
    String rawTitle = input.trim();
    if (rawTitle.isEmpty) return ParsedData(cleanTitle: rawTitle);

    DateTime? parsedDate;
    TimeOfDay? parsedTime;
    ImportanceLevel? parsedImportance;
    
    // 0. Parse Importance Keywords with Context Rules
    final standaloneRegex = RegExp(r'^(red|orange|yellow|green)[.,!?]*$', caseSensitive: false);
    final punctuationRegex = RegExp(r'[-:,;/|]+\s*(red|orange|yellow|green)\b[.,!?]*', caseSensitive: false);
    final endRegex = RegExp(r'(?:\s+)(red|orange|yellow|green)[.,!?]*$', caseSensitive: false);

    RegExpMatch? importanceMatch;

    if ((importanceMatch = standaloneRegex.firstMatch(rawTitle)) != null) {
    } else if ((importanceMatch = punctuationRegex.firstMatch(rawTitle)) != null) {
    } else if ((importanceMatch = endRegex.firstMatch(rawTitle)) != null) {
    }

    if (importanceMatch != null) {
      final keyword = importanceMatch.group(1)!.toLowerCase();
      switch (keyword) {
        case 'red': parsedImportance = ImportanceLevel.red; break;
        case 'orange': parsedImportance = ImportanceLevel.orange; break;
        case 'yellow': parsedImportance = ImportanceLevel.yellow; break;
        case 'green': parsedImportance = ImportanceLevel.green; break;
      }
      rawTitle = rawTitle.replaceFirst(importanceMatch.group(0)!, '').trim();
    }
    
    // 1. Parse Date Keywords
    final dateRegex = RegExp(r'\b(today|tomorrow|tonight|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false);
    final dateMatch = dateRegex.firstMatch(rawTitle);
    
    if (dateMatch != null) {
      final keyword = dateMatch.group(1)!.toLowerCase();
      final now = DateTime.now();
      if (keyword == 'today' || keyword == 'tonight') {
        parsedDate = now;
        if (keyword == 'tonight') {
           parsedTime = const TimeOfDay(hour: 20, minute: 0); 
        }
      } else if (keyword == 'tomorrow') {
        parsedDate = now.add(const Duration(days: 1));
      } else {
        final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
        int targetWeekday = days.indexOf(keyword) + 1;
        int currentWeekday = now.weekday;
        int daysToAdd = targetWeekday - currentWeekday;
        if (daysToAdd <= 0) daysToAdd += 7; 
        parsedDate = now.add(Duration(days: daysToAdd));
      }
      rawTitle = rawTitle.replaceFirst(dateMatch.group(0)!, '').trim();
    }

    // 2. Parse Time Formats
    final timeRegex = RegExp(r'\b((1[0-2]|0?[1-9])(:([0-5][0-9]))?\s*(am|pm)|([01]?[0-9]|2[0-3]):([0-5][0-9]))\b', caseSensitive: false);
    final timeMatch = timeRegex.firstMatch(rawTitle);
    
    if (timeMatch != null) {
      String fullMatch = timeMatch.group(0)!;
      int hour = 0;
      int minute = 0;
      
      if (timeMatch.group(5) != null) { 
        hour = int.parse(timeMatch.group(2)!);
        if (timeMatch.group(4) != null) minute = int.parse(timeMatch.group(4)!);
        String ampm = timeMatch.group(5)!.toLowerCase();
        if (ampm == 'pm' && hour != 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
      } else if (timeMatch.group(6) != null && timeMatch.group(7) != null) { 
        hour = int.parse(timeMatch.group(6)!);
        minute = int.parse(timeMatch.group(7)!);
      }
      parsedTime = TimeOfDay(hour: hour, minute: minute);
      rawTitle = rawTitle.replaceFirst(fullMatch, '').trim();
    }

    rawTitle = rawTitle.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return ParsedData(
      date: parsedDate,
      time: parsedTime,
      importance: parsedImportance,
      cleanTitle: rawTitle,
    );
  }

  void _saveTask() {
    final parsed = _parseInputText(_titleController.text);
    String rawTitle = parsed.cleanTitle;
    if (rawTitle.isEmpty) rawTitle = 'Untitled';

    DateTime finalDate = _effectiveDate ?? DateTime.now();
    TimeOfDay? finalTime = _effectiveTime;

    DateTime dueDateTime;
    if (finalTime != null) {
      dueDateTime = DateTime(finalDate.year, finalDate.month, finalDate.day, finalTime.hour, finalTime.minute);
    } else {
      dueDateTime = DateTime(finalDate.year, finalDate.month, finalDate.day, 23, 59);
    }

    final task = Task(
      id: widget.existingTask?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: rawTitle,
      dueDateTime: dueDateTime,
      importanceLevel: _effectiveImportance,
      reminderBefore: _selectedReminder,
      isCompleted: widget.existingTask?.isCompleted ?? false,
    );

    Navigator.pop(context, task);
  }

  Widget _buildPreviewChip(IconData icon, String label, {Color? color}) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayColor = color ?? colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: displayColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: displayColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: displayColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Task Title Input
          TextField(
            controller: _titleController,
            autofocus: true,
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w400),
            decoration: InputDecoration(
              hintText: "What needs to be done?",
              hintStyle: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.35),
                fontWeight: FontWeight.w400,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          
          // Live Preview Row (Animated)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: (_parsedDate != null || _parsedTime != null || _parsedImportance != null)
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (_parsedDate != null)
                          _buildPreviewChip(Icons.calendar_today, DateFormat('MMM d, yyyy').format(_parsedDate!)),
                        if (_parsedTime != null)
                          _buildPreviewChip(Icons.access_time, _parsedTime!.format(context)),
                        if (_parsedImportance != null)
                          _buildPreviewChip(
                            Icons.flag, 
                            _parsedImportance!.name.toUpperCase(), 
                            color: _getImportanceColor(_parsedImportance!, isDarkMode),
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
          // Metadata Row (Date, Time, Reminder)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Date Chip
              ActionChip(
                onPressed: _pickDate,
                avatar: Icon(Icons.calendar_today_outlined, size: 16, color: colorScheme.primary),
                label: Text(_effectiveDate != null ? DateFormat('MMM d, yyyy').format(_effectiveDate!) : 'Date'),
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              // Time Chip
              ActionChip(
                onPressed: _pickTime,
                avatar: Icon(Icons.access_time_outlined, size: 16, color: colorScheme.primary),
                label: Text(_effectiveTime != null ? _effectiveTime!.format(context) : 'Time'),
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              // Reminder Dropdown (Styled like a chip)
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReminderTiming>(
                    value: _selectedReminder,
                    icon: Icon(Icons.notifications_none_outlined, size: 16, color: colorScheme.primary),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    items: ReminderTiming.values.map((timing) {
                      return DropdownMenuItem(
                        value: timing,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Text(_getReminderText(timing), style: const TextStyle(fontSize: 13)),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedReminder = val;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),

          // Bottom Row: Importance & Save Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Importance Selector Group
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Importance',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ImportanceLevel.values.map((level) {
                      final color = _getImportanceColor(level, isDarkMode);
                      final isSelected = _effectiveImportance == level;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _userEditedImportance = true;
                            _manualImportance = level;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 12),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isSelected ? 1.0 : 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? colorScheme.onSurface.withValues(alpha: 0.5) : Colors.transparent,
                              width: 1.5,
                            ),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ] : null,
                          ),
                          child: isSelected
                              ? Icon(Icons.check, size: 16, color: colorScheme.onSurface.withValues(alpha: 0.8))
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              
              // Save Button anchored at bottom right
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _titleController,
                builder: (context, value, child) {
                  return FilledButton.icon(
                    onPressed: value.text.trim().isNotEmpty ? _saveTask : null,
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
