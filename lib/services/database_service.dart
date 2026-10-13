import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:uuid/uuid.dart';

import '../models/account_transfer.dart';
import '../models/bank_account.dart';
import '../models/category.dart';
import '../models/goal.dart';
import '../models/transaction.dart';
import '../models/receivable.dart';
import '../models/receivable_payment.dart';
import '../models/payable.dart';
import '../models/payable_payment.dart';
import '../theme/app_theme.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const Uuid _uuid = Uuid();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getDatabasesPath();
    final dbPath = '$directory/finanzas_rapidas.db';

    return openDatabase(
      dbPath,
      version: 4,
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createReceivablesTables(db);
        }
        if (oldVersion < 3) {
          await _createPayablesTables(db);
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE transactions ADD COLUMN account_id TEXT');
          await db.execute('CREATE INDEX idx_transactions_account ON transactions(account_id)');
          await _createBankAccountsTables(db);
        }
      },
      onOpen: (db) async {
        await _ensureDefaultCategories(db);
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        icon TEXT NOT NULL,
        description TEXT,
        date INTEGER NOT NULL,
        is_recurring INTEGER DEFAULT 0,
        account_id TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_transactions_date ON transactions(date DESC)');
    await db.execute('CREATE INDEX idx_transactions_type ON transactions(type)');
    await db.execute('CREATE INDEX idx_transactions_category ON transactions(category)');
    await db.execute('CREATE INDEX idx_transactions_account ON transactions(account_id)');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        type TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_categories_type_sort ON categories(type, sort_order)');

    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        deadline INTEGER NOT NULL,
        icon TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_goals_deadline ON goals(deadline)');

    await _createReceivablesTables(db);
    await _createPayablesTables(db);
    await _createBankAccountsTables(db);

    await _insertDefaultCategories(db);
  }

  Future<void> _createReceivablesTables(Database db) async {
    await db.execute('''
      CREATE TABLE receivables (
        id TEXT PRIMARY KEY,
        person_name TEXT NOT NULL,
        initial_amount REAL NOT NULL,
        current_balance REAL DEFAULT 0,
        loan_date INTEGER NOT NULL,
        description TEXT,
        is_paid_off INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_receivables_date ON receivables(loan_date)');

    await db.execute('''
      CREATE TABLE receivable_payments (
        id TEXT PRIMARY KEY,
        receivable_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY(receivable_id) REFERENCES receivables(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_receivable_payments_date ON receivable_payments(payment_date)');
  }

  Future<void> _createPayablesTables(Database db) async {
    await db.execute('''
      CREATE TABLE payables (
        id TEXT PRIMARY KEY,
        creditor_name TEXT NOT NULL,
        initial_amount REAL NOT NULL,
        current_balance REAL DEFAULT 0,
        due_date INTEGER NOT NULL,
        description TEXT,
        is_paid_off INTEGER DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_payables_date ON payables(due_date)');

    await db.execute('''
      CREATE TABLE payable_payments (
        id TEXT PRIMARY KEY,
        payable_id TEXT NOT NULL,
        amount REAL NOT NULL,
        payment_date INTEGER NOT NULL,
        note TEXT,
        FOREIGN KEY(payable_id) REFERENCES payables(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_payable_payments_date ON payable_payments(payment_date)');
  }

  Future<void> _createBankAccountsTables(Database db) async {
    await db.execute('''
      CREATE TABLE bank_accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        initial_balance REAL DEFAULT 0,
        icon TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE account_transfers (
        id TEXT PRIMARY KEY,
        from_account_id TEXT NOT NULL,
        to_account_id TEXT NOT NULL,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        note TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_account_transfers_date ON account_transfers(date DESC)');
  }

  Future<void> _ensureDefaultCategories(Database db) async {
    final result = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM categories')) ?? 0;
    if (result == 0) {
      await _insertDefaultCategories(db);
      return;
    }

    final existing = await db.query('categories', columns: ['name']);
    final existingNames = existing.map((row) => row['name'] as String).toSet();
    for (final item in AppTheme.defaultCategories) {
      if (!existingNames.contains(item['name'])) {
        await db.insert('categories', {
          'id': _uuid.v4(),
          'name': item['name'],
          'icon': item['icon'],
          'color': item['color'],
          'type': item['type'],
          'sort_order': item['sort'],
        });
      }
    }
  }

  Future<void> _insertDefaultCategories(DatabaseExecutor db) async {
    final batch = db.batch();
    for (final item in AppTheme.defaultCategories) {
      batch.insert('categories', {
        'id': _uuid.v4(),
        'name': item['name'],
        'icon': item['icon'],
        'color': item['color'],
        'type': item['type'],
        'sort_order': item['sort'],
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getCategories({String? type}) async {
    final db = await database;
    final rows = await db.query(
      'categories',
      where: type == null ? null : 'type = ?',
      whereArgs: type == null ? null : [type],
      orderBy: 'sort_order ASC, name ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Transaction>> getTransactions({
    String? type,
    DateTime? start,
    DateTime? end,
    int? limit,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (start != null) {
      where.add('date >= ?');
      args.add(start.millisecondsSinceEpoch);
    }
    if (end != null) {
      where.add('date <= ?');
      args.add(end.millisecondsSinceEpoch);
    }

    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map((row) => Transaction.fromMap(row)).toList();
  }

  Future<String> insertTransaction(Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return transaction.id;
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  Future<List<Goal>> getGoals() async {
    final db = await database;
    final rows = await db.query('goals', orderBy: 'deadline ASC');
    return rows.map(Goal.fromMap).toList();
  }

  Future<String> insertGoal(Goal goal) async {
    final db = await database;
    await db.insert('goals', goal.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return goal.id;
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await database;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearGoals() async {
    final db = await database;
    await db.delete('goals');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('goals');
      await txn.delete('receivables');
      await txn.delete('receivable_payments');
      await txn.delete('payables');
      await txn.delete('payable_payments');
      await txn.delete('account_transfers');
      await txn.delete('bank_accounts');
      await txn.delete('categories');
      await _insertDefaultCategories(txn);
    });
  }

  // Receivables CRUD
  Future<List<Receivable>> getReceivables() async {
    final db = await database;
    final rows = await db.query('receivables', orderBy: 'loan_date DESC');
    return rows.map(Receivable.fromMap).toList();
  }

  Future<String> insertReceivable(Receivable receivable) async {
    final db = await database;
    await db.insert('receivables', receivable.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return receivable.id;
  }

  Future<void> updateReceivable(Receivable receivable) async {
    final db = await database;
    await db.update('receivables', receivable.toMap(), where: 'id = ?', whereArgs: [receivable.id]);
  }

  Future<void> deleteReceivable(String id) async {
    final db = await database;
    await db.delete('receivable_payments', where: 'receivable_id = ?', whereArgs: [id]);
    await db.delete('receivables', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearReceivables() async {
    final db = await database;
    await db.delete('receivable_payments');
    await db.delete('receivables');
  }

  // Receivable Payments CRUD
  Future<List<ReceivablePayment>> getReceivablePayments(String receivableId) async {
    final db = await database;
    final rows = await db.query(
      'receivable_payments',
      where: 'receivable_id = ?',
      whereArgs: [receivableId],
      orderBy: 'payment_date DESC',
    );
    return rows.map(ReceivablePayment.fromMap).toList();
  }

  Future<String> insertReceivablePayment(ReceivablePayment payment) async {
    final db = await database;
    await db.insert('receivable_payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return payment.id;
  }

  Future<void> deleteReceivablePayment(String id) async {
    final db = await database;
    await db.delete('receivable_payments', where: 'id = ?', whereArgs: [id]);
  }

  // Payables CRUD
  Future<List<Payable>> getPayables() async {
    final db = await database;
    final rows = await db.query('payables', orderBy: 'due_date DESC');
    return rows.map(Payable.fromMap).toList();
  }

  Future<String> insertPayable(Payable payable) async {
    final db = await database;
    await db.insert('payables', payable.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return payable.id;
  }

  Future<void> updatePayable(Payable payable) async {
    final db = await database;
    await db.update('payables', payable.toMap(), where: 'id = ?', whereArgs: [payable.id]);
  }

  Future<void> deletePayable(String id) async {
    final db = await database;
    await db.delete('payable_payments', where: 'payable_id = ?', whereArgs: [id]);
    await db.delete('payables', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearPayables() async {
    final db = await database;
    await db.delete('payable_payments');
    await db.delete('payables');
  }

  // Payable Payments CRUD
  Future<List<PayablePayment>> getPayablePayments(String payableId) async {
    final db = await database;
    final rows = await db.query(
      'payable_payments',
      where: 'payable_id = ?',
      whereArgs: [payableId],
      orderBy: 'payment_date DESC',
    );
    return rows.map(PayablePayment.fromMap).toList();
  }

  Future<String> insertPayablePayment(PayablePayment payment) async {
    final db = await database;
    await db.insert('payable_payments', payment.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return payment.id;
  }

  Future<void> deletePayablePayment(String id) async {
    final db = await database;
    await db.delete('payable_payments', where: 'id = ?', whereArgs: [id]);
  }

  // Bank Accounts CRUD
  Future<List<BankAccount>> getBankAccounts() async {
    final db = await database;
    final rows = await db.query('bank_accounts', orderBy: 'created_at ASC');
    return rows.map(BankAccount.fromMap).toList();
  }

  Future<String> insertBankAccount(BankAccount account) async {
    final db = await database;
    await db.insert('bank_accounts', account.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return account.id;
  }

  Future<void> updateBankAccount(BankAccount account) async {
    final db = await database;
    await db.update('bank_accounts', account.toMap(), where: 'id = ?', whereArgs: [account.id]);
  }

  /// Elimina la cuenta y sus transferencias. Las transacciones se conservan
  /// pero quedan sin cuenta asignada.
  Future<void> deleteBankAccount(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('transactions', {'account_id': null}, where: 'account_id = ?', whereArgs: [id]);
      await txn.delete('account_transfers', where: 'from_account_id = ? OR to_account_id = ?', whereArgs: [id, id]);
      await txn.delete('bank_accounts', where: 'id = ?', whereArgs: [id]);
    });
  }

  // Account Transfers CRUD
  Future<List<AccountTransfer>> getAccountTransfers() async {
    final db = await database;
    final rows = await db.query('account_transfers', orderBy: 'date DESC');
    return rows.map(AccountTransfer.fromMap).toList();
  }

  Future<String> insertAccountTransfer(AccountTransfer transfer) async {
    final db = await database;
    await db.insert('account_transfers', transfer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return transfer.id;
  }

  Future<void> deleteAccountTransfer(String id) async {
    final db = await database;
    await db.delete('account_transfers', where: 'id = ?', whereArgs: [id]);
  }

  Future<File> exportTransactionsCsv(List<Transaction> transactions) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/finanzas_rapidas_${DateTime.now().millisecondsSinceEpoch}.csv');
    final buffer = StringBuffer();
    buffer.writeln('id,amount,type,category,icon,description,date,is_recurring');
    for (final transaction in transactions) {
      final description = transaction.description?.replaceAll('"', '""') ?? '';
      buffer.writeln(
        '${transaction.id},${transaction.amount},${transaction.type},${transaction.category},${transaction.icon},"$description",${transaction.date.toIso8601String()},${transaction.isRecurring ? 1 : 0}',
      );
    }
    await file.writeAsString(buffer.toString());
    return file;
  }

  Future<void> resetDatabaseCache() async {
    _database = null;
  }
}