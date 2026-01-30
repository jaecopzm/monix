import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'database_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  // Budget Alerts
  Future<void> checkBudgetAlerts() async {
    final db = DatabaseHelper();
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final budgets = await db.getBudgets(currentMonth);

    for (var budget in budgets) {
      if (budget.month == currentMonth) {
        final spent = await db.getCategorySpending(
          budget.category,
          currentMonth,
        );
        final percentage = (spent / budget.amount) * 100;

        if (percentage >= 100 && percentage < 105) {
          await _showNotification(
            id: budget.id.hashCode,
            title: '🚨 Budget Exceeded!',
            body:
                'You\'ve spent \$${spent.toStringAsFixed(2)} of \$${budget.amount.toStringAsFixed(2)} for ${budget.category}',
          );
        } else if (percentage >= 80 && percentage < 85) {
          await _showNotification(
            id: budget.id.hashCode + 1000,
            title: '⚠️ Budget Alert',
            body:
                'You\'ve used ${percentage.toStringAsFixed(0)}% of your ${budget.category} budget',
          );
        }
      }
    }
  }

  // Recurring Transaction Reminders
  Future<void> scheduleRecurringReminders() async {
    final db = DatabaseHelper();
    final recurring = await db.getRecurringTransactions();

    for (var r in recurring.where((r) => r.isActive)) {
      final nextDue = r.getNextDueDate();
      final now = DateTime.now();

      // Schedule notification 1 day before
      if (nextDue.difference(now).inHours > 0 &&
          nextDue.difference(now).inHours <= 24) {
        await _scheduleNotification(
          id: r.id.hashCode,
          title: '💳 Payment Reminder',
          body: '${r.title} (\$${r.amount.toStringAsFixed(2)}) is due tomorrow',
          scheduledDate: nextDue.subtract(const Duration(days: 1)),
        );
      }
    }
  }

  // Daily Spending Summary
  Future<void> scheduleDailySummary() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final scheduledTime = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      20,
      0,
    ); // 8 PM

    await _scheduleNotification(
      id: 999999,
      title: '📊 Daily Summary',
      body: 'Check your spending for today',
      scheduledDate: scheduledTime,
    );
  }

  // Goal Milestone Notifications
  Future<void> checkGoalMilestones() async {
    final db = DatabaseHelper();
    final goals = await db.getGoals();

    for (var goal in goals) {
      final percentage = (goal.currentAmount / goal.targetAmount) * 100;

      if (percentage >= 50 && percentage < 55) {
        await _showNotification(
          id: goal.id.hashCode,
          title: '🎯 Halfway There!',
          body: 'You\'re 50% to your ${goal.title} goal!',
        );
      } else if (percentage >= 75 && percentage < 80) {
        await _showNotification(
          id: goal.id.hashCode + 2000,
          title: '🎯 Almost There!',
          body: 'You\'re 75% to your ${goal.title} goal!',
        );
      } else if (percentage >= 100) {
        await _showNotification(
          id: goal.id.hashCode + 3000,
          title: '🎉 Goal Achieved!',
          body: 'Congratulations! You\'ve reached your ${goal.title} goal!',
        );
      }
    }
  }

  // Show immediate notification
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
    );
  }

  // Show immediate notification
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'monixx_alerts',
      'Financial Alerts',
      channelDescription: 'Budget alerts, reminders, and summaries',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  // Schedule notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'monixx_reminders',
      'Reminders',
      channelDescription: 'Scheduled reminders for bills and payments',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  // Request permissions (iOS)
  Future<bool> requestPermissions() async {
    final result = await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? true;
  }

  // Test all notification types
  Future<void> testNotifications() async {
    // Test budget alert
    await _showNotification(
      id: 1,
      title: '⚠️ Budget Alert (Test)',
      body: 'You\'ve used 85% of your Food budget this month',
    );

    await Future<void>.delayed(const Duration(seconds: 2));

    // Test recurring reminder
    await _showNotification(
      id: 2,
      title: '💳 Payment Reminder (Test)',
      body: 'Netflix subscription (\$15.99) is due tomorrow',
    );

    await Future<void>.delayed(const Duration(seconds: 2));

    // Test goal milestone
    await _showNotification(
      id: 3,
      title: '🎯 Goal Milestone (Test)',
      body: 'You\'re 75% to your Vacation goal! Keep it up!',
    );

    await Future<void>.delayed(const Duration(seconds: 2));

    // Test daily summary
    await _showNotification(
      id: 4,
      title: '📊 Daily Summary (Test)',
      body: 'You spent \$45.50 today across 5 transactions',
    );
  }
}
