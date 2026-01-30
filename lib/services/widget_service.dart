import 'package:home_widget/home_widget.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';

class WidgetService {
  static const String _widgetName = 'MonixxWidget';
  
  final DataService _dataService = DataService();
  final SettingsService _settings = SettingsService();

  Future<void> initializeWidget() async {
    try {
      await HomeWidget.setAppGroupId('group.monixx.widget');
      await updateWidget();
    } catch (e) {
      print('Widget initialization failed: $e');
    }
  }

  Future<void> updateWidget() async {
    try {
      // Get current balance
      final transactions = await _dataService.getTransactions();
      final income = transactions
          .where((t) => t.type == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);
      final expenses = transactions
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);
      final balance = income - expenses;

      // Get currency
      final currency = await _settings.getCurrency();
      final currencySymbol = _getCurrencySymbol(currency);

      // Get recent transactions count
      final today = DateTime.now();
      final todayTransactions = transactions.where((t) => 
        t.date.year == today.year &&
        t.date.month == today.month &&
        t.date.day == today.day
      ).length;

      // Update widget data
      await HomeWidget.saveWidgetData<String>('balance', '${currencySymbol}${balance.toStringAsFixed(0)}');
      await HomeWidget.saveWidgetData<String>('currency', currencySymbol);
      await HomeWidget.saveWidgetData<int>('todayTransactions', todayTransactions);
      await HomeWidget.saveWidgetData<String>('lastUpdate', DateTime.now().toIso8601String());

      // Update the widget
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: 'MonixxWidgetProvider',
        iOSName: 'MonixxWidget',
      );
    } catch (e) {
      print('Widget update failed: $e');
    }
  }

  Future<void> handleWidgetClick(String action) async {
    switch (action) {
      case 'add_expense':
        // This would be handled by the main app when opened
        await HomeWidget.saveWidgetData<String>('widget_action', 'add_expense');
        break;
      case 'add_income':
        await HomeWidget.saveWidgetData<String>('widget_action', 'add_income');
        break;
      case 'view_balance':
        await HomeWidget.saveWidgetData<String>('widget_action', 'view_balance');
        break;
    }
  }

  Future<String?> getWidgetAction() async {
    try {
      final action = await HomeWidget.getWidgetData<String>('widget_action');
      if (action != null) {
        // Clear the action after reading
        await HomeWidget.saveWidgetData<String>('widget_action', '');
      }
      return action;
    } catch (e) {
      return null;
    }
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
}
