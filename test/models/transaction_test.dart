import 'package:flutter_test/flutter_test.dart';
import 'package:monixx/models/transaction.dart';

void main() {
  group('Transaction Model', () {
    final testDate = DateTime(2023, 1, 1);

    final testTransaction = Transaction(
      id: '1',
      title: 'Food',
      amount: 50.0,
      category: 'Dining',
      date: testDate,
      type: 'expense',
      description: 'Lunches',
      accountId: 'acc1',
    );

    test('toMap() should return a valid map', () {
      final map = testTransaction.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Food');
      expect(map['amount'], 50.0);
      expect(map['category'], 'Dining');
      expect(map['date'], testDate.millisecondsSinceEpoch);
      expect(map['type'], 'expense');
      expect(map['description'], 'Lunches');
      expect(map['accountId'], 'acc1');
    });

    test('fromMap() should create a valid Transaction', () {
      final map = {
        'id': 1,
        'title': 'Salary',
        'amount': 5000.0,
        'category': 'Job',
        'date': testDate.millisecondsSinceEpoch,
        'type': 'income',
        'description': 'Monthly salary',
        'accountId': 'acc2',
      };

      final transaction = Transaction.fromMap(map);

      expect(transaction.id, '1');
      expect(transaction.title, 'Salary');
      expect(transaction.amount, 5000.0);
      expect(transaction.category, 'Job');
      expect(transaction.date, testDate);
      expect(transaction.type, 'income');
      expect(transaction.description, 'Monthly salary');
      expect(transaction.accountId, 'acc2');
    });

    test('copyWith() should return a new instance with updated values', () {
      final updated = testTransaction.copyWith(amount: 100.0, title: 'Dinner');

      expect(updated.amount, 100.0);
      expect(updated.title, 'Dinner');
      expect(updated.id, testTransaction.id);
      expect(updated.category, testTransaction.category);
    });

    test('toFirestore() and fromFirestore() consistency', () {
      final firestoreData = testTransaction.toFirestore();
      final fromFirestore = Transaction.fromFirestore(firestoreData, '1');

      expect(fromFirestore.title, testTransaction.title);
      expect(fromFirestore.amount, testTransaction.amount);
      expect(fromFirestore.category, testTransaction.category);
      expect(
        fromFirestore.date.millisecondsSinceEpoch,
        testTransaction.date.millisecondsSinceEpoch,
      );
      expect(fromFirestore.type, testTransaction.type);
      expect(fromFirestore.description, testTransaction.description);
      expect(fromFirestore.accountId, testTransaction.accountId);
    });
  });
}
