import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const _channelId = 'expensetra_general';
  static const _channelName = 'ExpensTra Notifications';
  static const _channelDescription = 'General notifications and reminders';
  static const _dailyReminderId = 9001;

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> scheduleDailyReminder({required bool enabled}) async {
    if (!enabled) {
      await _plugin.cancel(_dailyReminderId);
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.periodicallyShow(
      _dailyReminderId,
      'Expense check-in',
      'Are you tracking your expenses? Open ExpensTra to manage them.',
      RepeatInterval.daily,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> showBudgetWarning({
    required String budgetId,
    required String budgetName,
    required String status,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'budget_warn_${budgetId}_$status';
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    final last = prefs.getString(key);

    if (last == todayKey) {
      return;
    }

    await prefs.setString(key, todayKey);
    await showNotification('Budget Alert: $budgetName', status);
  }
}
