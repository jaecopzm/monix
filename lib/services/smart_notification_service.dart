import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/goal.dart';
import '../models/recurring_transaction.dart';
import 'database_helper.dart';
import 'settings_service.dart';

class SmartNotificationService {
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final SettingsService _settings = SettingsService();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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
  }

  // Goal Notifications
  Future<void> scheduleGoalDeadlineReminder(Goal goal) async {
    final daysUntilDeadline = goal.deadline.difference(DateTime.now()).inDays;
    
    if (daysUntilDeadline <= 0) return;

    // Schedule reminders at 7 days, 3 days, and 1 day before deadline
    final reminderDays = [7, 3, 1];
    
    for (final days in reminderDays) {
      if (daysUntilDeadline > days) {
        final reminderDate = goal.deadline.subtract(Duration(days: days));
        
        await _notifications.zonedSchedule(
          goal.id.hashCode + days,
          '🎯 Goal Deadline Reminder',
          '${goal.title} deadline is in $days day${days > 1 ? 's' : ''}!',
          tz.TZDateTime.from(reminderDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'goal_reminders',
              'Goal Reminders',
              channelDescription: 'Reminders for goal deadlines',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> scheduleGoalMilestoneCheck(Goal goal) async {
    // Check for milestone achievements (25%, 50%, 75%, 100%)
    final milestones = [0.25, 0.5, 0.75, 1.0];
    
    for (final milestone in milestones) {
      if (goal.progress >= milestone) {
        String message;
        String emoji;
        
        if (milestone == 1.0) {
          message = '🎉 Congratulations! You\'ve completed your ${goal.title} goal!';
          emoji = '🎉';
        } else {
          final percentage = (milestone * 100).toInt();
          message = '🌟 Great progress! You\'re $percentage% towards your ${goal.title} goal!';
          emoji = '🌟';
        }

        await _showInstantNotification(
          goal.id.hashCode + (milestone * 1000).toInt(),
          '$emoji Goal Milestone',
          message,
        );
      }
    }
  }

  // Recurring Transaction Notifications
  Future<void> scheduleRecurringReminders() async {
    final recurringTransactions = await _dbHelper.getRecurringTransactions();
    
    for (final recurring in recurringTransactions) {
      if (recurring.isActive) {
        await _scheduleRecurringNotification(recurring);
      }
    }
  }

  Future<void> _scheduleRecurringNotification(RecurringTransaction recurring) async {
    final nextDate = _getNextOccurrence(recurring);
    
    // Schedule notification 1 day before
    final reminderDate = nextDate.subtract(const Duration(days: 1));
    
    if (reminderDate.isAfter(DateTime.now())) {
      await _notifications.zonedSchedule(
        recurring.id.hashCode,
        '💳 Upcoming ${recurring.type == 'income' ? 'Income' : 'Payment'}',
        '${recurring.title} (${recurring.amount}) is due tomorrow',
        tz.TZDateTime.from(reminderDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'recurring_reminders',
            'Recurring Transaction Reminders',
            channelDescription: 'Reminders for recurring transactions',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  DateTime _getNextOccurrence(RecurringTransaction recurring) {
    final now = DateTime.now();
    DateTime next = recurring.startDate;

    while (next.isBefore(now)) {
      switch (recurring.frequency) {
        case 'daily':
          next = next.add(const Duration(days: 1));
          break;
        case 'weekly':
          next = next.add(const Duration(days: 7));
          break;
        case 'monthly':
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case 'yearly':
          next = DateTime(next.year + 1, next.month, next.day);
          break;
      }
    }

    return next;
  }

  // Budget Notifications
  Future<void> checkBudgetAlerts() async {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final budgets = await _dbHelper.getBudgets(currentMonth);
    final currency = await _settings.getCurrency();
    final currencySymbol = _getCurrencySymbol(currency);

    for (final budget in budgets) {
      final spent = await _dbHelper.getCategorySpending(budget.category, currentMonth);
      final percentage = spent / budget.amount;

      if (percentage >= 0.8 && percentage < 1.0) {
        await _showInstantNotification(
          budget.category.hashCode,
          '⚠️ Budget Alert',
          'You\'ve spent ${(percentage * 100).toInt()}% of your ${budget.category} budget ($currencySymbol${spent.toStringAsFixed(0)}/$currencySymbol${budget.amount.toStringAsFixed(0)})',
        );
      } else if (percentage >= 1.0) {
        await _showInstantNotification(
          budget.category.hashCode + 1000,
          '🚨 Budget Exceeded',
          'You\'ve exceeded your ${budget.category} budget by $currencySymbol${(spent - budget.amount).toStringAsFixed(0)}!',
        );
      }
    }
  }

  // Savings Motivation
  Future<void> scheduleSavingsMotivation() async {
    final goals = await _dbHelper.getGoals();
    final activeGoals = goals.where((g) => g.progress < 1.0).toList();

    if (activeGoals.isNotEmpty) {
      // Schedule weekly motivation on Sundays at 6 PM
      final now = DateTime.now();
      final nextSunday = now.add(Duration(days: 7 - now.weekday));
      final motivationTime = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 18);

      await _notifications.zonedSchedule(
        'savings_motivation'.hashCode,
        '💪 Weekly Savings Check-in',
        'How are your financial goals coming along? Add some funds to stay on track!',
        tz.TZDateTime.from(motivationTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'motivation',
            'Savings Motivation',
            channelDescription: 'Weekly motivation for savings goals',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> _showInstantNotification(int id, String title, String body) async {
    await _notifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Immediate notifications for important events',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  String _getCurrencySymbol(String currency) {
    const symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'ZMW': 'K',
    };
    return symbols[currency] ?? '\$';
  }

  // Cancel notifications
  Future<void> cancelGoalNotifications(String goalId) async {
    final id = goalId.hashCode;
    await _notifications.cancel(id + 1);
    await _notifications.cancel(id + 3);
    await _notifications.cancel(id + 7);
  }

  Future<void> cancelRecurringNotifications(String recurringId) async {
    await _notifications.cancel(recurringId.hashCode);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
