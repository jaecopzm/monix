import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';
import 'firestore_service.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart';
import '../models/goal.dart';
import '../models/budget.dart';

class DataService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  FirestoreService? _firestoreService;

  DataService() {
    _initFirestore();
  }

  void _initFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService = FirestoreService(uid: user.uid);
    }
  }

  // Real-time streams
  Stream<List<model.Transaction>> getTransactionsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _firestoreService != null) {
      return _firestoreService!.getTransactions();
    }
    return Stream.value([]);
  }

  Stream<List<Goal>> getGoalsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _firestoreService != null) {
      return _firestoreService!.getGoals();
    }
    return Stream.value([]);
  }

  // Transactions
  Future<int> insertTransaction(model.Transaction transaction) async {
    final id = await _dbHelper.insertTransaction(transaction);

    if (_firestoreService != null) {
      try {
        await _firestoreService!.addTransaction(transaction);
      } catch (e) {
        // Silent fail - offline mode
      }
    }

    return id;
  }

  Future<List<model.Transaction>> getTransactions({String? month}) async {
    return _dbHelper.getTransactions(month: month);
  }

  Future<void> updateTransaction(
    model.Transaction oldTransaction,
    model.Transaction newTransaction,
  ) async {
    await _dbHelper.updateTransaction(oldTransaction, newTransaction);

    if (_firestoreService != null && newTransaction.id != null) {
      try {
        await _firestoreService!.updateTransaction(newTransaction);
      } catch (e) {
        // Silent fail - offline mode
      }
    }
  }

  Future<void> deleteTransaction(model.Transaction transaction) async {
    await _dbHelper.deleteTransaction(transaction);

    if (_firestoreService != null && transaction.id != null) {
      try {
        await _firestoreService!.deleteTransaction(transaction.id!);
      } catch (e) {
        // Silent fail - offline mode
      }
    }
  }

  // Categories
  Future<List<Category>> getCategories() async {
    return _dbHelper.getCategories();
  }

  Future<List<Category>> getCategoriesByType(String type) async {
    return _dbHelper.getCategoriesByType(type);
  }

  Future<int> insertCategory(Category category) async {
    final id = await _dbHelper.insertCategory(category);

    if (_firestoreService != null) {
      try {
        await _firestoreService!.addCategory(category);
      } catch (e) {
        // Silent fail
      }
    }

    return id;
  }

  // Goals
  Future<int> insertGoal(Goal goal) async {
    final id = await _dbHelper.insertGoal(goal);

    if (_firestoreService != null) {
      try {
        await _firestoreService!.addGoal(goal);
      } catch (e) {
        // Silent fail
      }
    }

    return id;
  }

  Future<List<Goal>> getGoals() async {
    return _dbHelper.getGoals();
  }

  Future<void> updateGoal(Goal goal) async {
    await _dbHelper.updateGoal(goal);

    if (_firestoreService != null && goal.id != null) {
      try {
        await _firestoreService!.updateGoal(goal);
      } catch (e) {
        // Silent fail
      }
    }
  }

  Future<void> deleteGoal(String id) async {
    await _dbHelper.deleteGoal(id);
  }

  // Budgets
  Future<int> insertBudget(Budget budget) async {
    final id = await _dbHelper.insertBudget(budget);

    if (_firestoreService != null) {
      try {
        await _firestoreService!.addBudget(budget);
      } catch (e) {
        // Silent fail
      }
    }

    return id;
  }

  Future<List<Budget>> getBudgets(String month) async {
    return _dbHelper.getBudgets(month);
  }

  Future<void> updateBudget(Budget budget) async {
    await _dbHelper.updateBudget(budget);
  }

  Future<void> deleteBudget(String id) async {
    await _dbHelper.deleteBudget(id);
  }

  Future<double> getCategorySpending(String category, String month) async {
    return _dbHelper.getCategorySpending(category, month);
  }
}
