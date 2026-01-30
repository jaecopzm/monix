import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart';
import '../models/goal.dart';
import '../models/budget.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  // User document reference
  DocumentReference get userDoc => _db.collection('users').doc(uid);

  // Transactions
  Stream<List<model.Transaction>> getTransactions() {
    return userDoc
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => model.Transaction.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addTransaction(model.Transaction transaction) {
    return userDoc.collection('transactions').add(transaction.toFirestore());
  }

  Future<void> updateTransaction(model.Transaction transaction) {
    return userDoc
        .collection('transactions')
        .doc(transaction.id!)
        .update(transaction.toFirestore());
  }

  Future<void> deleteTransaction(String transactionId) {
    return userDoc.collection('transactions').doc(transactionId).delete();
  }

  // Categories
  Stream<List<Category>> getCategories() {
    return userDoc
        .collection('categories')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Category.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addCategory(Category category) {
    return userDoc.collection('categories').add(category.toFirestore());
  }

  // Goals
  Stream<List<Goal>> getGoals() {
    return userDoc
        .collection('goals')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Goal.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addGoal(Goal goal) {
    return userDoc.collection('goals').add(goal.toFirestore());
  }

  Future<void> updateGoal(Goal goal) {
    return userDoc
        .collection('goals')
        .doc(goal.id!)
        .update(goal.toFirestore());
  }

  // Budgets
  Stream<List<Budget>> getBudgets(String month) {
    return userDoc
        .collection('budgets')
        .where('month', isEqualTo: month)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Budget.fromFirestore(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> addBudget(Budget budget) {
    return userDoc.collection('budgets').add(budget.toFirestore());
  }
}
