import 'database_helper.dart';
import 'firestore_service.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart';
import '../models/goal.dart';
import '../models/budget.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirestoreService _firestoreService;
  bool _isSyncing = false;

  SyncService({required String uid})
    : _firestoreService = FirestoreService(uid: uid);

  // Sync all data from local to cloud
  Future<void> syncToCloud() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _syncTransactionsToCloud();
      await _syncCategoriesToCloud();
      await _syncGoalsToCloud();
      await _syncBudgetsToCloud();
    } catch (e) {
      rethrow; // Propagate to caller for reporting
    } finally {
      _isSyncing = false;
    }
  }

  // Sync all data from cloud to local
  Future<void> syncFromCloud() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await _syncTransactionsFromCloud();
      await _syncCategoriesFromCloud();
      await _syncGoalsFromCloud();
      await _syncBudgetsFromCloud();
    } finally {
      _isSyncing = false;
    }
  }

  // Two-way sync with conflict resolution (cloud wins)
  Future<void> fullSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // First sync from cloud (cloud data takes priority)
      await syncFromCloud();
      // Then sync any local-only data to cloud
      await syncToCloud();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncTransactionsToCloud() async {
    final localTransactions = await _dbHelper.getTransactions();
    for (var transaction in localTransactions) {
      if (transaction.firestoreId == null) {
        try {
          await _firestoreService.addTransaction(transaction);
        } catch (e) {
          // Individual item failure should not stop the whole sync
        }
      }
    }
  }

  Future<void> _syncTransactionsFromCloud() async {
    final snapshot = await _firestoreService.userDoc
        .collection('transactions')
        .get();

    final localTransactions = await _dbHelper.getTransactions();
    final firestoreIds = localTransactions
        .map((t) => t.firestoreId)
        .whereType<String>()
        .toSet();

    for (var doc in snapshot.docs) {
      final transaction = model.Transaction.fromFirestore(doc.data(), doc.id);
      if (!firestoreIds.contains(transaction.firestoreId)) {
        await _dbHelper.insertTransaction(transaction);
      }
    }
  }

  // Categories sync
  Future<void> _syncCategoriesToCloud() async {
    final localCategories = await _dbHelper.getCategories();
    for (var category in localCategories) {
      if (category.firestoreId == null) {
        try {
          await _firestoreService.addCategory(category);
        } catch (e) {
          // Individual failure
        }
      }
    }
  }

  Future<void> _syncCategoriesFromCloud() async {
    final snapshot = await _firestoreService.userDoc
        .collection('categories')
        .get();

    final localCategories = await _dbHelper.getCategories();
    final firestoreIds = localCategories
        .map((c) => c.firestoreId)
        .whereType<String>()
        .toSet();

    for (var doc in snapshot.docs) {
      final category = Category.fromFirestore(doc.data(), doc.id);
      if (!firestoreIds.contains(category.firestoreId)) {
        await _dbHelper.insertCategory(category);
      }
    }
  }

  // Goals sync
  Future<void> _syncGoalsToCloud() async {
    final localGoals = await _dbHelper.getGoals();
    for (var goal in localGoals) {
      if (goal.firestoreId == null) {
        try {
          await _firestoreService.addGoal(goal);
        } catch (e) {
          // Individual failure
        }
      }
    }
  }

  Future<void> _syncGoalsFromCloud() async {
    final snapshot = await _firestoreService.userDoc.collection('goals').get();

    final localGoals = await _dbHelper.getGoals();
    final firestoreIds = localGoals
        .map((g) => g.firestoreId)
        .whereType<String>()
        .toSet();

    for (var doc in snapshot.docs) {
      final goal = Goal.fromFirestore(doc.data(), doc.id);
      if (!firestoreIds.contains(goal.firestoreId)) {
        await _dbHelper.insertGoal(goal);
      }
    }
  }

  // Budgets sync
  Future<void> _syncBudgetsToCloud() async {
    final localBudgets = await _dbHelper.getBudgets('');
    for (var budget in localBudgets) {
      if (budget.firestoreId == null) {
        try {
          await _firestoreService.addBudget(budget);
        } catch (e) {
          // Individual failure
        }
      }
    }
  }

  Future<void> _syncBudgetsFromCloud() async {
    final snapshot = await _firestoreService.userDoc
        .collection('budgets')
        .get();

    final localBudgets = await _dbHelper.getBudgets(
      '',
    ); // Get all budgets for comparison
    final firestoreIds = localBudgets
        .map((b) => b.firestoreId)
        .whereType<String>()
        .toSet();

    for (var doc in snapshot.docs) {
      final budget = Budget.fromFirestore(doc.data(), doc.id);
      if (!firestoreIds.contains(budget.firestoreId)) {
        await _dbHelper.insertBudget(budget);
      }
    }
  }
}
