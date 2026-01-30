import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _budgetAlerts = true;
  bool _recurringReminders = true;
  bool _dailySummary = false;
  bool _goalMilestones = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _budgetAlerts = prefs.getBool('notif_budget') ?? true;
      _recurringReminders = prefs.getBool('notif_recurring') ?? true;
      _dailySummary = prefs.getBool('notif_daily') ?? false;
      _goalMilestones = prefs.getBool('notif_goals') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Notifications')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Stay on top of your finances with smart alerts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 24),
                _buildSettingCard(
                  icon: Icons.account_balance_wallet,
                  title: 'Budget Alerts',
                  subtitle:
                      'Get notified when you reach 80% or 100% of your budget',
                  value: _budgetAlerts,
                  onChanged: (value) async {
                    setState(() => _budgetAlerts = value);
                    await _saveSetting('notif_budget', value);
                    HapticService.light();
                  },
                  delay: 0,
                ),
                _buildSettingCard(
                  icon: Icons.repeat,
                  title: 'Recurring Reminders',
                  subtitle: 'Reminders for upcoming bills and subscriptions',
                  value: _recurringReminders,
                  onChanged: (value) async {
                    setState(() => _recurringReminders = value);
                    await _saveSetting('notif_recurring', value);
                    HapticService.light();
                  },
                  delay: 50,
                ),
                _buildSettingCard(
                  icon: Icons.calendar_today,
                  title: 'Daily Summary',
                  subtitle: 'Daily spending summary at 8 PM',
                  value: _dailySummary,
                  onChanged: (value) async {
                    setState(() => _dailySummary = value);
                    await _saveSetting('notif_daily', value);
                    HapticService.light();

                    if (value) {
                      await _notificationService.scheduleDailySummary();
                    }
                  },
                  delay: 100,
                ),
                _buildSettingCard(
                  icon: Icons.flag,
                  title: 'Goal Milestones',
                  subtitle:
                      'Celebrate when you reach 50%, 75%, and 100% of your goals',
                  value: _goalMilestones,
                  onChanged: (value) async {
                    setState(() => _goalMilestones = value);
                    await _saveSetting('notif_goals', value);
                    HapticService.light();
                  },
                  delay: 150,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Notifications help you stay on track with your financial goals',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 24),
                _buildTestButton(),
              ],
            ),
    );
  }

  Widget _buildTestButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        HapticService.medium();

        // Test all notification types
        await _notificationService.testNotifications();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Test notifications sent! Check your notification tray',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      icon: const Icon(Icons.notifications_active, color: Colors.white),
      label: const Text(
        'Test All Notifications',
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ).animate().fadeIn(delay: 250.ms).scale();
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required int delay,
  }) {
    return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: AppTheme.primaryColor,
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn()
        .slideX(begin: 0.2, end: 0);
  }
}
