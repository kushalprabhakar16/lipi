import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/task.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (!_isInitialized) await init();

    // Aggressively cancel any existing notifications for this task to prevent ghost offset schedules when importance drops.
    await cancelNotification(task.id);

    if (task.reminderBefore == ReminderTiming.none || task.isCompleted) {
      return;
    }

    final bool isHighPriority = task.importanceLevel != ImportanceLevel.green;
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'lipi_reminders',
      'Lipi Task Reminders',
      channelDescription: 'Notifications for scheduled tasks',
      importance: isHighPriority ? Importance.max : Importance.defaultImportance,
      priority: isHighPriority ? Priority.high : Priority.defaultPriority,
      styleInformation: const DefaultStyleInformation(true, true),
    );
    final NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    final int baseId = task.id.hashCode;

    Future<void> scheduleSingle(int notificationId, String bodyPrefix, DateTime scheduledTime, String logMessage) async {
      if (scheduledTime.isBefore(DateTime.now())) {
        print('$logMessage skipped (time is in the past).');
        return;
      }
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);
      final body = '$bodyPrefix Due at ${task.dueDateTime.hour.toString().padLeft(2, '0')}:${task.dueDateTime.minute.toString().padLeft(2, '0')}';

      try {
        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: task.title,
          body: body,
          scheduledDate: tzScheduledTime,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        print('EXACT $logMessage scheduled for ${task.title} at $tzScheduledTime (ID: $notificationId)');
      } catch (e) {
        try {
          await _notificationsPlugin.zonedSchedule(
            id: notificationId,
            title: task.title,
            body: body,
            scheduledDate: tzScheduledTime,
            notificationDetails: notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
          print('INEXACT $logMessage scheduled for ${task.title} at $tzScheduledTime (ID: $notificationId)');
        } catch (fallbackError) {
          print('Failed to schedule $logMessage: $fallbackError');
        }
      }
    }

    Duration? userOffset;
    switch (task.reminderBefore) {
      case ReminderTiming.fiveMins: userOffset = const Duration(minutes: 5); break;
      case ReminderTiming.tenMins: userOffset = const Duration(minutes: 10); break;
      case ReminderTiming.thirtyMins: userOffset = const Duration(minutes: 30); break;
      case ReminderTiming.oneHour: userOffset = const Duration(hours: 1); break;
      case ReminderTiming.oneDay: userOffset = const Duration(days: 1); break;
      case ReminderTiming.none: break;
    }

    DateTime? userTriggerTime;
    if (userOffset != null) {
      userTriggerTime = task.dueDateTime.subtract(userOffset);
    }

    if (task.importanceLevel == ImportanceLevel.red) {
      final red1Day = task.dueDateTime.subtract(const Duration(days: 1));
      await scheduleSingle(baseId, '[RED]', red1Day, 'RED notification #1');
      
      final red1Hour = task.dueDateTime.subtract(const Duration(hours: 1));
      await scheduleSingle(baseId + 1, '[RED]', red1Hour, 'RED notification #2');

    } else if (task.importanceLevel == ImportanceLevel.orange) {
      if (userTriggerTime != null) {
        await scheduleSingle(baseId, '[ORANGE]', userTriggerTime, 'ORANGE notification #1');
      }
      final orange1Hour = task.dueDateTime.subtract(const Duration(hours: 1));
      await scheduleSingle(baseId + 1, '[ORANGE]', orange1Hour, 'ORANGE bonus reminder');

    } else if (task.importanceLevel == ImportanceLevel.yellow) {
      if (userTriggerTime != null) {
        await scheduleSingle(baseId, '[YELLOW]', userTriggerTime, 'YELLOW notification #1');
      }
    } else {
      if (userTriggerTime != null) {
        await scheduleSingle(baseId, '[GREEN]', userTriggerTime, 'GREEN notification #1');
      }
    }
  }

  Future<void> cancelNotification(String taskId) async {
    final int baseId = taskId.hashCode;
    for (int i = 0; i <= 2; i++) {
      await _notificationsPlugin.cancel(id: baseId + i);
    }
    print('ALL notifications canceled for Task ID: $taskId (Base ID: $baseId to ${baseId + 2})');
  }
}
