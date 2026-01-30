import 'package:flutter_test/flutter_test.dart';
import 'package:monixx/models/transaction.dart' as model;
import 'package:monixx/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;

  setUp(() async {
    // Set a unique test database name for each test run
    DatabaseHelper.setTestDatabase(
      'test_monixx_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    dbHelper = DatabaseHelper();
  });

  group('DatabaseHelper Transactions', () {
    test('insertTransaction should update account balance', () async {
      // 1. Get default account
      final account = await dbHelper.getDefaultAccount();
      expect(account, isNotNull);
      final initialBalance = account!.balance;

      // 2. Insert an income transaction (don't provide ID)
      final transaction = model.Transaction(
        title: 'Freelance',
        amount: 1000.0,
        category: 'Income',
        date: DateTime.now(),
        type: 'income',
        accountId: account.id,
      );

      await dbHelper.insertTransaction(transaction);

      // 3. Verify balance updated
      final updatedAccount = await dbHelper.getDefaultAccount();
      expect(updatedAccount!.balance, initialBalance + 1000.0);
    });

    test('deleteTransaction should revert account balance', () async {
      final account = await dbHelper.getDefaultAccount();
      final initialBalance = account!.balance;

      // 1. Insert an expense
      final transaction = model.Transaction(
        title: 'Lunch',
        amount: 20.0,
        category: 'Food',
        date: DateTime.now(),
        type: 'expense',
        accountId: account.id,
      );

      final id = await dbHelper.insertTransaction(transaction);
      final transactionWithId = transaction.copyWith(id: id.toString());

      final afterInsertAccount = await dbHelper.getDefaultAccount();
      expect(afterInsertAccount!.balance, initialBalance - 20.0);

      // 2. Delete the transaction
      await dbHelper.deleteTransaction(transactionWithId);

      // 3. Verify balance reverted
      final afterDeleteAccount = await dbHelper.getDefaultAccount();
      expect(afterDeleteAccount!.balance, initialBalance);
    });

    test('updateTransaction should correctly adjust balance', () async {
      final account = await dbHelper.getDefaultAccount();
      final initialBalance = account!.balance;

      // 1. Insert original transaction ($50 expense)
      final oldTx = model.Transaction(
        title: 'Old',
        amount: 50.0,
        category: 'Misc',
        date: DateTime.now(),
        type: 'expense',
        accountId: account.id,
      );
      final id = await dbHelper.insertTransaction(oldTx);
      final oldTxWithId = oldTx.copyWith(id: id.toString());

      // 2. Update to a $30 expense
      final newTx = oldTxWithId.copyWith(amount: 30.0);
      await dbHelper.updateTransaction(oldTxWithId, newTx);

      // 3. Verify balance (should be initial - 30)
      final updatedAccount = await dbHelper.getDefaultAccount();
      expect(updatedAccount!.balance, initialBalance - 30.0);
    });
  });
}
