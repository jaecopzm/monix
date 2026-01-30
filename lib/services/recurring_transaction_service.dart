import 'database_helper.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import 'smart_notification_service.dart';

class RecurringTransactionService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<void> processRecurringTransactions() async {
    final recurring = await _db.getRecurringTransactions();

    for (var r in recurring) {
      if (r.isDue()) {
        await _addTransactionFromRecurring(r);
        await _updateLastProcessed(r);
      }
    }
  }

  Future<void> _addTransactionFromRecurring(
    RecurringTransaction recurring,
  ) async {
    final transaction = Transaction(
      title: recurring.title,
      amount: recurring.amount,
      category: recurring.category,
      date: DateTime.now(),
      type: recurring.type,
      description: recurring.description,
    );
    await _db.insertTransaction(transaction);
  }

  Future<void> _updateLastProcessed(RecurringTransaction recurring) async {
    final updated = RecurringTransaction(
      id: recurring.id,
      title: recurring.title,
      amount: recurring.amount,
      category: recurring.category,
      type: recurring.type,
      frequency: recurring.frequency,
      startDate: recurring.startDate,
      endDate: recurring.endDate,
      lastProcessed: DateTime.now(),
      isActive: recurring.isActive,
      description: recurring.description,
    );
    await _db.updateRecurringTransaction(updated);
  }

  Future<List<RecurringTransaction>> getAll() {
    return _db.getRecurringTransactions();
  }

  Future<String> add(RecurringTransaction recurring) async {
    final id = await _db.insertRecurringTransaction(recurring);
    
    // Schedule notifications for the new recurring transaction
    try {
      final smartNotifications = SmartNotificationService();
      await smartNotifications.scheduleRecurringReminders();
    } catch (e) {
      // Silent fail for notifications - don't block transaction creation
      print('Recurring notification scheduling failed: $e');
    }
    
    return id;
  }

  Future<void> update(RecurringTransaction recurring) async {
    await _db.updateRecurringTransaction(recurring);
  }

  Future<void> delete(String id) async {
    await _db.deleteRecurringTransaction(id);
  }

  Future<void> toggleActive(RecurringTransaction recurring) async {
    final updated = RecurringTransaction(
      id: recurring.id,
      title: recurring.title,
      amount: recurring.amount,
      category: recurring.category,
      type: recurring.type,
      frequency: recurring.frequency,
      startDate: recurring.startDate,
      endDate: recurring.endDate,
      lastProcessed: recurring.lastProcessed,
      isActive: !recurring.isActive,
      description: recurring.description,
    );
    await _db.updateRecurringTransaction(updated);
  }

  DateTime getNextOccurrence(RecurringTransaction recurring) {
    final lastProcessed = recurring.lastProcessed ?? recurring.startDate;
    switch (recurring.frequency) {
      case 'daily':
        return lastProcessed.add(const Duration(days: 1));
      case 'weekly':
        return lastProcessed.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(
          lastProcessed.year,
          lastProcessed.month + 1,
          lastProcessed.day,
        );
      case 'yearly':
        return DateTime(
          lastProcessed.year + 1,
          lastProcessed.month,
          lastProcessed.day,
        );
      default:
        return lastProcessed;
    }
  }
}
