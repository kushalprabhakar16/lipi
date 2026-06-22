enum ImportanceLevel {
  green,
  yellow,
  orange,
  red,
}

enum ReminderTiming {
  none,
  fiveMins,
  tenMins,
  thirtyMins,
  oneHour,
  oneDay,
}

class Task {
  final String id;
  final String title;
  final DateTime dueDateTime;
  final ImportanceLevel importanceLevel;
  final ReminderTiming reminderBefore;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.dueDateTime,
    this.importanceLevel = ImportanceLevel.green,
    this.reminderBefore = ReminderTiming.none,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dueDateTime': dueDateTime.toIso8601String(),
      'importanceLevel': importanceLevel.name,
      'reminderBefore': reminderBefore.name,
      'isCompleted': isCompleted,
    };
  }

  static Task? fromMap(Map<String, dynamic> map) {
    try {
      final id = map['id']?.toString() ?? '';
      if (id.isEmpty) return null; // ID is required

      final title = map['title']?.toString() ?? 'Untitled';
      
      final dueDateTimeStr = map['dueDateTime']?.toString();
      DateTime dueDateTime;
      if (dueDateTimeStr != null) {
        dueDateTime = DateTime.tryParse(dueDateTimeStr) ?? DateTime.now();
      } else {
        dueDateTime = DateTime.now();
      }

      final importanceLevelStr = map['importanceLevel']?.toString();
      final importanceLevel = ImportanceLevel.values.firstWhere(
        (e) => e.name == importanceLevelStr,
        orElse: () => ImportanceLevel.green,
      );

      final reminderBeforeStr = map['reminderBefore']?.toString();
      final reminderBefore = ReminderTiming.values.firstWhere(
        (e) => e.name == reminderBeforeStr,
        orElse: () => ReminderTiming.none,
      );

      // Explicitly check for true to handle nulls or type mismatch safely
      final isCompleted = map['isCompleted'] == true;

      return Task(
        id: id,
        title: title,
        dueDateTime: dueDateTime,
        importanceLevel: importanceLevel,
        reminderBefore: reminderBefore,
        isCompleted: isCompleted,
      );
    } catch (e) {
      print('Error parsing individual task: $e');
      return null;
    }
  }

  bool get isOverdue {
    if (isCompleted) return false;
    // Consider it overdue if the due date has passed
    return dueDateTime.isBefore(DateTime.now());
  }

  bool get isToday {
    if (isCompleted) return false;
    final now = DateTime.now();
    return !isOverdue && 
           dueDateTime.year == now.year &&
           dueDateTime.month == now.month &&
           dueDateTime.day == now.day;
  }

  bool get isUpcoming {
    if (isCompleted) return false;
    final now = DateTime.now();
    return dueDateTime.isAfter(now) &&
           (dueDateTime.year != now.year ||
            dueDateTime.month != now.month ||
            dueDateTime.day != now.day);
  }
}
