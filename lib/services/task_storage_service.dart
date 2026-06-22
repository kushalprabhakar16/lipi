import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TaskStorageService {
  static const String _boxName = 'tasks_box';
  static late Box<dynamic> _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<dynamic>(_boxName);
    } else {
      _box = Hive.box<dynamic>(_boxName);
    }
  }

  static List<Task> getTasks() {
    print('--- Loading Tasks from Hive ---');
    final validTasks = <Task>[];
    int failureCount = 0;
    
    for (var value in _box.values) {
      try {
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          final task = Task.fromMap(map);
          if (task != null) {
            validTasks.add(task);
          } else {
            failureCount++;
            print('Skipped invalid task (parsed as null): $map');
          }
        } else {
          failureCount++;
          print('Skipped invalid task (not a Map): $value');
        }
      } catch (e) {
        failureCount++;
        print('Exception while loading task: $e\\nData: $value');
      }
    }
    
    print('Loaded ${validTasks.length} tasks successfully.');
    if (failureCount > 0) {
      print('WARNING: Failed to load $failureCount corrupted tasks.');
    }
    
    return validTasks;
  }

  static Future<void> saveTask(Task task) async {
    await _box.put(task.id, task.toMap());
  }

  static Future<void> deleteTask(String id) async {
    await _box.delete(id);
  }
}
