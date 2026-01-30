import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart' as model;
import '../models/category.dart';
import '../models/goal.dart';
import '../models/budget.dart';
import '../models/recurring_transaction.dart';
import '../models/account.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static String _databaseName = 'monixx.db';

  static void setTestDatabase(String name) {
    _databaseName = name;
    _database = null;
  }

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: 10,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date INTEGER NOT NULL,
        type TEXT NOT NULL,
        description TEXT,
        accountId TEXT,
        firestoreId TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL,
        firestoreId TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE goals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL DEFAULT 0,
        deadline TEXT NOT NULL,
        icon TEXT NOT NULL,
        firestoreId TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        firestoreId TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE recurring_transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        frequency TEXT NOT NULL,
        startDate INTEGER NOT NULL,
        endDate INTEGER,
        lastProcessed INTEGER,
        isActive INTEGER DEFAULT 1,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE accounts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL DEFAULT 0,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        isDefault INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isRead INTEGER DEFAULT 0,
        actionData TEXT
      )
    ''');

    await _insertDefaultAccounts(db);
    await _insertDefaultCategories(db);
  }

  Future<void> _insertDefaultAccounts(Database db) async {
    await db.insert('accounts', {
      'name': 'Cash',
      'type': 'cash',
      'balance': 0,
      'icon': '💵',
      'color': '4CAF50',
      'isDefault': 1,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE goals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          currentAmount REAL DEFAULT 0,
          deadline TEXT NOT NULL,
          icon TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE budgets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          month TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE recurring_transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          type TEXT NOT NULL,
          frequency TEXT NOT NULL,
          startDate INTEGER NOT NULL,
          endDate INTEGER,
          lastProcessed INTEGER,
          isActive INTEGER DEFAULT 1,
          description TEXT
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE accounts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          balance REAL DEFAULT 0,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          isDefault INTEGER DEFAULT 0
        )
      ''');
      await _insertDefaultAccounts(db);

      await db.execute('ALTER TABLE transactions ADD COLUMN accountId TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE transactions ADD COLUMN firestoreId TEXT');
      await db.execute('ALTER TABLE categories ADD COLUMN firestoreId TEXT');
      await db.execute('ALTER TABLE goals ADD COLUMN firestoreId TEXT');
      await db.execute('ALTER TABLE budgets ADD COLUMN firestoreId TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          message TEXT NOT NULL,
          type TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isRead INTEGER DEFAULT 0,
          actionData TEXT
        )
      ''');
    }
    if (oldVersion < 8) {
      // Ensure accounts table exists
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'",
      );
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE accounts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance REAL DEFAULT 0,
            icon TEXT NOT NULL,
            color TEXT NOT NULL,
            isDefault INTEGER DEFAULT 0
          )
        ''');
        await _insertDefaultAccounts(db);
      }
      
      // Ensure accountId and firestoreId columns exist
      final columns = await db.rawQuery('PRAGMA table_info(transactions)');
      final columnNames = columns.map((c) => c['name'] as String).toList();
      
      if (!columnNames.contains('accountId')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN accountId TEXT');
      }
      if (!columnNames.contains('firestoreId')) {
        await db.execute('ALTER TABLE transactions ADD COLUMN firestoreId TEXT');
      }
    }
    if (oldVersion < 9) {
      // Ensure accounts table exists for users who skipped version 8
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='accounts'",
      );
      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE accounts(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance REAL DEFAULT 0,
            icon TEXT NOT NULL,
            color TEXT NOT NULL,
            isDefault INTEGER DEFAULT 0
          )
        ''');
        await _insertDefaultAccounts(db);
      }
    }
    if (oldVersion < 10) {
      // Remove subscription services from expense categories
      await db.delete(
        'categories',
        where: 'name IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) AND type = ?',
        whereArgs: [
          'Adobe', 'Netflix', 'Spotify', 'YouTube', 'Amazon Prime',
          'Apple', 'Microsoft', 'Hulu', 'HBO', 'Twitch',
          'expense'
        ],
      );
      
      // Add more default categories if they don't exist
      final existingCategories = await db.query('categories');
      final existingNames = existingCategories.map((c) => c['name']).toSet();
      
      final newCategories = [
        {'name': 'Home', 'icon': '🏠', 'color': 'F8B500', 'type': 'expense'},
        {'name': 'Education', 'icon': '🎓', 'color': '786FA6', 'type': 'expense'},
        {'name': 'Fitness', 'icon': '💪', 'color': '26DE81', 'type': 'expense'},
        {'name': 'Travel', 'icon': '✈️', 'color': '45AAF2', 'type': 'expense'},
        {'name': 'Coffee', 'icon': '☕', 'color': '6F4E37', 'type': 'expense'},
        {'name': 'Gifts', 'icon': '🎁', 'color': 'FC5C65', 'type': 'expense'},
        {'name': 'Business', 'icon': '🏦', 'color': '786FA6', 'type': 'income'},
        {'name': 'Bonus', 'icon': '💵', 'color': '26DE81', 'type': 'income'},
        {'name': 'Gift', 'icon': '🎁', 'color': 'FC5C65', 'type': 'income'},
        {'name': 'Rental', 'icon': '🏠', 'color': 'F8B500', 'type': 'income'},
        {'name': 'Savings', 'icon': '🐷', 'color': '4ECDC4', 'type': 'income'},
      ];
      
      for (var category in newCategories) {
        if (!existingNames.contains(category['name'])) {
          await db.insert('categories', category);
        }
      }
    }
  }

  Future<void> _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      // Expense categories
      {'name': 'Food', 'icon': '🍔', 'color': 'FF6B6B', 'type': 'expense'},
      {'name': 'Transport', 'icon': '🚗', 'color': '4ECDC4', 'type': 'expense'},
      {'name': 'Shopping', 'icon': '🛍️', 'color': 'FFE66D', 'type': 'expense'},
      {'name': 'Bills', 'icon': '📄', 'color': 'FF8B94', 'type': 'expense'},
      {'name': 'Health', 'icon': '🏥', 'color': 'A8E6CF', 'type': 'expense'},
      {'name': 'Entertainment', 'icon': '🎬', 'color': 'C7CEEA', 'type': 'expense'},
      {'name': 'Home', 'icon': '🏠', 'color': 'F8B500', 'type': 'expense'},
      {'name': 'Education', 'icon': '🎓', 'color': '786FA6', 'type': 'expense'},
      {'name': 'Fitness', 'icon': '💪', 'color': '26DE81', 'type': 'expense'},
      {'name': 'Travel', 'icon': '✈️', 'color': '45AAF2', 'type': 'expense'},
      {'name': 'Coffee', 'icon': '☕', 'color': '6F4E37', 'type': 'expense'},
      {'name': 'Gifts', 'icon': '🎁', 'color': 'FC5C65', 'type': 'expense'},
      // Income categories
      {'name': 'Salary', 'icon': '💰', 'color': '26DE81', 'type': 'income'},
      {'name': 'Freelance', 'icon': '💻', 'color': '45AAF2', 'type': 'income'},
      {'name': 'Investment', 'icon': '📈', 'color': 'FEA47F', 'type': 'income'},
      {'name': 'Business', 'icon': '🏦', 'color': '786FA6', 'type': 'income'},
      {'name': 'Bonus', 'icon': '💵', 'color': '26DE81', 'type': 'income'},
      {'name': 'Gift', 'icon': '🎁', 'color': 'FC5C65', 'type': 'income'},
      {'name': 'Rental', 'icon': '🏠', 'color': 'F8B500', 'type': 'income'},
      {'name': 'Savings', 'icon': '🐷', 'color': '4ECDC4', 'type': 'income'},
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category);
    }
  }

  // Transaction methods
  Future<int> insertTransaction(model.Transaction transaction) async {
    final db = await database;
    return db.transaction((txn) async {
      // 1. Insert the transaction
      final id = await txn.insert('transactions', transaction.toMap());

      // 2. Update account balance
      final accountId =
          transaction.accountId ?? (await _getDefaultAccountIdTxn(txn));
      if (accountId != null) {
        final amount = transaction.type == 'income'
            ? transaction.amount
            : -transaction.amount;
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [amount, accountId],
        );
      }
      return id;
    });
  }

  Future<String?> _getDefaultAccountIdTxn(DatabaseExecutor txn) async {
    final List<Map<String, dynamic>> maps = await txn.query(
      'accounts',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    return maps.isNotEmpty ? maps.first['id'].toString() : null;
  }

  Future<List<model.Transaction>> getTransactions({String? month}) async {
    final db = await database;
    String? whereClause;
    List<dynamic>? whereArgs;

    if (month != null) {
      whereClause = "strftime('%Y-%m', datetime(date/1000, 'unixepoch')) = ?";
      whereArgs = [month];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return List.generate(
      maps.length,
      (i) => model.Transaction.fromMap(maps[i]),
    );
  }

  Future<void> updateTransaction(
    model.Transaction oldTransaction,
    model.Transaction newTransaction,
  ) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Revert old transaction balance
      final oldAccountId =
          oldTransaction.accountId ?? (await _getDefaultAccountIdTxn(txn));
      if (oldAccountId != null) {
        final oldAmount = oldTransaction.type == 'income'
            ? -oldTransaction.amount
            : oldTransaction.amount;
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [oldAmount, oldAccountId],
        );
      }

      // 2. Apply new transaction balance
      final newAccountId =
          newTransaction.accountId ?? (await _getDefaultAccountIdTxn(txn));
      if (newAccountId != null) {
        final newAmount = newTransaction.type == 'income'
            ? newTransaction.amount
            : -newTransaction.amount;
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [newAmount, newAccountId],
        );
      }

      // 3. Update the transaction
      await txn.update(
        'transactions',
        newTransaction.toMap(),
        where: 'id = ?',
        whereArgs: [newTransaction.id],
      );
    });
  }

  Future<void> deleteTransaction(model.Transaction transaction) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Revert balance
      final accountId =
          transaction.accountId ?? (await _getDefaultAccountIdTxn(txn));
      if (accountId != null) {
        final amount = transaction.type == 'income'
            ? -transaction.amount
            : transaction.amount;
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [amount, accountId],
        );
      }

      // 2. Delete the transaction
      await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
    });
  }

  // Category methods
  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<List<Category>> getCategoriesByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
    );
    return List.generate(maps.length, (i) => Category.fromMap(maps[i]));
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Goal methods
  Future<int> insertGoal(Goal goal) async {
    final db = await database;
    return db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('goals');
    return List.generate(maps.length, (i) => Goal.fromMap(maps[i]));
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await database;
    await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // Budget methods
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return db.insert('budgets', budget.toMap());
  }

  Future<List<Budget>> getBudgets(String month) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'month = ?',
      whereArgs: [month],
    );
    return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
  }

  Future<void> updateBudget(Budget budget) async {
    final db = await database;
    await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getCategorySpending(String category, String month) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(amount) as total FROM transactions 
      WHERE category = ? AND type = 'expense' 
      AND strftime('%Y-%m', datetime(date/1000, 'unixepoch')) = ?
    ''',
      [category, month],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Recurring Transactions
  Future<String> insertRecurringTransaction(
    RecurringTransaction recurring,
  ) async {
    final db = await database;
    final id = await db.insert('recurring_transactions', recurring.toMap());
    return id.toString();
  }

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'recurring_transactions',
    );
    return List.generate(
      maps.length,
      (i) => RecurringTransaction.fromMap(maps[i]),
    );
  }

  Future<void> updateRecurringTransaction(
    RecurringTransaction recurring,
  ) async {
    final db = await database;
    await db.update(
      'recurring_transactions',
      recurring.toMap(),
      where: 'id = ?',
      whereArgs: [recurring.id],
    );
  }

  Future<void> deleteRecurringTransaction(String id) async {
    final db = await database;
    await db.delete('recurring_transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Accounts
  Future<String> insertAccount(Account account) async {
    final db = await database;
    final id = await db.insert('accounts', account.toMap());
    return id.toString();
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');
    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }

  Future<Account?> getDefaultAccount() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'isDefault = ?',
      whereArgs: [1],
      limit: 1,
    );
    return maps.isNotEmpty ? Account.fromMap(maps.first) : null;
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteAccount(String id) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateAccountBalance(String accountId, double amount) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE accounts SET balance = balance + ? WHERE id = ?',
      [amount, accountId],
    );
  }

  // Clear all data for account isolation
  Future<void> clearAllData() async {
    final db = await database;
    
    // Delete all data from all tables
    await db.delete('transactions');
    await db.delete('categories');
    await db.delete('goals');
    await db.delete('budgets');
    await db.delete('recurring_transactions');
    await db.delete('accounts');
    await db.delete('notifications');
    
    // Reset auto-increment counters
    await db.delete('sqlite_sequence');
  }
}
