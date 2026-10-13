import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../services/database_service.dart';
import '../services/widget_service.dart';
import '../services/background_worker.dart';

enum TimePeriod { today, week, month, year, all, custom }

class DaySummary {
  final DateTime day;
  final double income;
  final double expense;

  const DaySummary({required this.day, required this.income, required this.expense});
}

class CategorySummary {
  final String category;
  final String icon;
  final double amount;
  final double percentage;

  const CategorySummary({required this.category, required this.icon, required this.amount, required this.percentage});
}

enum MovementKind { income, expense, transferIn, transferOut }

/// Movimiento unificado del historial de una cuenta bancaria.
class AccountMovement {
  final MovementKind kind;
  final double amount;
  final DateTime date;
  final String title;
  final String icon;
  final String? note;
  final Transaction? transaction;
  final AccountTransfer? transfer;

  const AccountMovement({
    required this.kind,
    required this.amount,
    required this.date,
    required this.title,
    required this.icon,
    this.note,
    this.transaction,
    this.transfer,
  });

  bool get isInflow => kind == MovementKind.income || kind == MovementKind.transferIn;
}

class FinanceProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = const Uuid();

  String formatMoney(double value) {
    final abs = value.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    final formatted = '${value < 0 ? '-' : ''}Bs $buffer,$decPart';
    return formatted;
  }

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  List<Goal> _goals = [];
  List<Receivable> _receivables = [];
  List<Payable> _payables = [];
  List<BankAccount> _bankAccounts = [];
  List<AccountTransfer> _transfers = [];
  String? _lastAccountId;
  
  TimePeriod _selectedPeriod = TimePeriod.month;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  
  bool _isLoading = true;
  String? _errorMessage;
  bool _initialized = false;
  bool _remindersEnabled = true;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TimePeriod get selectedPeriod => _selectedPeriod;
  DateTime? get customStartDate => _customStartDate;
  DateTime? get customEndDate => _customEndDate;
  bool get remindersEnabled => _remindersEnabled;
  
  List<Transaction> get transactions => List.unmodifiable(_transactions);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Goal> get goals => List.unmodifiable(_goals);
  List<Receivable> get receivables => List.unmodifiable(_receivables);
  List<Payable> get payables => List.unmodifiable(_payables);
  List<BankAccount> get bankAccounts => List.unmodifiable(_bankAccounts);
  List<AccountTransfer> get transfers => List.unmodifiable(_transfers);

  double get totalReceivables => _receivables.where((r) => !r.isPaidOff).fold(0.0, (sum, r) => sum + r.currentBalance);
  double get totalPayables => _payables.where((p) => !p.isPaidOff).fold(0.0, (sum, p) => sum + p.currentBalance);

  Future<void> initDatabase() async {
    if (_initialized) return;
    _initialized = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _databaseService.database;
      final prefs = await SharedPreferences.getInstance();
      final savedPeriod = prefs.getString('selected_period') ?? TimePeriod.month.name;
      _selectedPeriod = TimePeriod.values.firstWhere(
        (period) => period.name == savedPeriod,
        orElse: () => TimePeriod.month,
      );
      _remindersEnabled = prefs.getBool('reminders_enabled') ?? true;
      _lastAccountId = prefs.getString('last_account_id');
      await reloadData();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadData() async {
    _transactions = List<Transaction>.from(await _databaseService.getTransactions());
    _categories = await _databaseService.getCategories();
    _goals = await _databaseService.getGoals();
    _receivables = await _databaseService.getReceivables();
    _payables = await _databaseService.getPayables();
    _bankAccounts = await _databaseService.getBankAccounts();
    _transfers = await _databaseService.getAccountTransfers();
    notifyListeners();

    WidgetService.updateData(
      balance: formatMoney(totalBalance),
      income: formatMoney(monthIncome),
      expense: formatMoney(monthExpense),
    );
  }

  Future<void> setSelectedPeriod(TimePeriod period) async {
    _selectedPeriod = period;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_period', period.name);
    notifyListeners();
  }

  Future<void> toggleReminders(bool value) async {
    _remindersEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', value);
    if (value) {
      BackgroundWorker.scheduleDailyReminder();
    } else {
      BackgroundWorker.cancelReminders();
    }
    notifyListeners();
  }

  void setCustomPeriod(DateTime start, DateTime end) {
    _selectedPeriod = TimePeriod.custom;
    _customStartDate = start;
    _customEndDate = end;
    notifyListeners();
  }

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);
  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month);
  DateTime _startOfYear(DateTime date) => DateTime(date.year);

  DateTime _periodStart(TimePeriod period, DateTime now) {
    switch (period) {
      case TimePeriod.today:
        return _startOfDay(now);
      case TimePeriod.week:
        return _startOfDay(now.subtract(Duration(days: now.weekday - 1)));
      case TimePeriod.month:
        return _startOfMonth(now);
      case TimePeriod.year:
        return _startOfYear(now);
      case TimePeriod.all:
        return DateTime(1970);
      case TimePeriod.custom:
        return _customStartDate ?? DateTime(1970);
    }
  }

  DateTime? _periodEnd(TimePeriod period, DateTime now) {
    switch (period) {
      case TimePeriod.today:
        return _startOfDay(now).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      case TimePeriod.week:
        return _startOfDay(now).add(const Duration(days: 7)).subtract(const Duration(milliseconds: 1));
      case TimePeriod.month:
        return DateTime(now.year, now.month + 1).subtract(const Duration(milliseconds: 1));
      case TimePeriod.year:
        return DateTime(now.year + 1).subtract(const Duration(milliseconds: 1));
      case TimePeriod.all:
        return null;
      case TimePeriod.custom:
        return _customEndDate != null 
          ? _startOfDay(_customEndDate!).add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1))
          : null;
    }
  }

  List<Transaction> _transactionsForPeriod(TimePeriod period) {
    final now = DateTime.now();
    final start = _periodStart(period, now);
    final end = _periodEnd(period, now);
    return _transactions.where((transaction) {
      final date = transaction.date;
      final afterStart = !date.isBefore(start);
      final beforeEnd = end == null || !date.isAfter(end);
      return afterStart && beforeEnd;
    }).toList();
  }

  List<Transaction> get selectedTransactions => _transactionsForPeriod(_selectedPeriod);

  double get totalIncome => selectedTransactions.where((transaction) => transaction.type == 'income').fold(0, (sum, transaction) => sum + transaction.amount);
  double get totalExpense => selectedTransactions.where((transaction) => transaction.type == 'expense').fold(0, (sum, transaction) => sum + transaction.amount);
  double get totalBalance => totalIncome - totalExpense;

  double get overallIncome => _transactions.where((transaction) => transaction.type == 'income').fold(0, (sum, transaction) => sum + transaction.amount);
  double get overallExpense => _transactions.where((transaction) => transaction.type == 'expense').fold(0, (sum, transaction) => sum + transaction.amount);

  double get monthIncome {
    final month = _transactionsForPeriod(TimePeriod.month);
    return month.where((transaction) => transaction.type == 'income').fold(0, (sum, transaction) => sum + transaction.amount);
  }

  double get monthExpense {
    final month = _transactionsForPeriod(TimePeriod.month);
    return month.where((transaction) => transaction.type == 'expense').fold(0, (sum, transaction) => sum + transaction.amount);
  }

  double get todayExpense {
    final today = _transactionsForPeriod(TimePeriod.today);
    return today.where((transaction) => transaction.type == 'expense').fold(0, (sum, transaction) => sum + transaction.amount);
  }

  double get averageDailyExpense {
    final now = DateTime.now();
    final daysPassed = now.day;
    if (daysPassed == 0) return 0;
    return monthExpense / daysPassed;
  }

  double get monthComparison {
    final now = DateTime.now();
    final currentStart = _startOfMonth(now);
    final previousMonthStart = DateTime(now.year, now.month - 1);
    final previousMonthEnd = currentStart.subtract(const Duration(milliseconds: 1));

    final currentExpense = _transactions
        .where((transaction) => transaction.type == 'expense' && !transaction.date.isBefore(currentStart))
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    final previousExpense = _transactions
        .where(
          (transaction) =>
              transaction.type == 'expense' &&
              !transaction.date.isBefore(previousMonthStart) &&
              !transaction.date.isAfter(previousMonthEnd),
        )
        .fold(0.0, (sum, transaction) => sum + transaction.amount);

    if (previousExpense == 0) {
      return currentExpense == 0 ? 0 : 100;
    }
    return ((currentExpense - previousExpense) / previousExpense) * 100;
  }

  List<Transaction> get recentTransactions {
    final copy = List<Transaction>.from(_transactions);
    copy.sort((left, right) => right.date.compareTo(left.date));
    return copy.take(20).toList();
  }

  List<Transaction> get historyTransactions {
    final periodTransactions = List<Transaction>.from(selectedTransactions)
      ..sort((left, right) => right.date.compareTo(left.date));
    if (periodTransactions.isNotEmpty) {
      return periodTransactions;
    }
    return recentTransactions;
  }

  List<DaySummary> get last7DaysSummary {
    final now = DateTime.now();
    return List<DaySummary>.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
      final start = _startOfDay(day);
      final end = start.add(const Duration(days: 1));
      final transactions = _transactions.where((transaction) => !transaction.date.isBefore(start) && transaction.date.isBefore(end));
      final income = transactions.where((transaction) => transaction.type == 'income').fold(0.0, (sum, transaction) => sum + transaction.amount);
      final expense = transactions.where((transaction) => transaction.type == 'expense').fold(0.0, (sum, transaction) => sum + transaction.amount);
      return DaySummary(day: day, income: income, expense: expense);
    });
  }

  Map<String, double> get expenseByCategoryMonth {
    final expenses = _transactionsForPeriod(TimePeriod.month).where((transaction) => transaction.type == 'expense').toList();
    final map = <String, double>{};
    for (final transaction in expenses) {
      map[transaction.category] = (map[transaction.category] ?? 0) + transaction.amount;
    }
    return map;
  }

  List<CategorySummary> get topExpenseCategories {
    final total = monthExpense;
    if (total == 0) return const [];
    final entries = expenseByCategoryMonth.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));

    return entries.take(5).map((entry) {
      final icon = _categories.firstWhere(
        (category) => category.name == entry.key,
        orElse: () => Category(id: '', name: entry.key, icon: '💰', color: Colors.white, type: 'expense', sortOrder: 0),
      ).icon;
      return CategorySummary(
        category: entry.key,
        icon: icon,
        amount: entry.value,
        percentage: (entry.value / total) * 100,
      );
    }).toList();
  }

  Category? categoryByName(String name) {
    for (final category in _categories) {
      if (category.name == name) return category;
    }
    return null;
  }

  Future<void> addTransaction({
    required double amount,
    required String type,
    required Category category,
    String? description,
    bool isRecurring = false,
    String? accountId,
  }) async {
    final transaction = Transaction(
      id: _uuid.v4(),
      amount: amount,
      type: type,
      category: category.name,
      icon: category.icon,
      description: description,
      date: DateTime.now(),
      isRecurring: isRecurring,
      accountId: accountId,
    );
    await _databaseService.insertTransaction(transaction);
    _transactions = [transaction, ..._transactions];
    if (accountId != null && accountId != _lastAccountId) {
      _lastAccountId = accountId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_account_id', accountId);
    }
    notifyListeners();
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    await _databaseService.deleteTransaction(transaction.id);
    _transactions.removeWhere((item) => item.id == transaction.id);
    notifyListeners();
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    required DateTime deadline,
    required String icon,
  }) async {
    final goal = Goal(
      id: _uuid.v4(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0,
      deadline: deadline,
      icon: icon,
      isCompleted: false,
    );
    await _databaseService.insertGoal(goal);
    _goals = [..._goals, goal]..sort((left, right) => left.deadline.compareTo(right.deadline));
    notifyListeners();
  }

  Future<void> updateGoalProgress(Goal goal, double addedAmount) async {
    final updated = goal.copyWith(
      currentAmount: math.min(goal.targetAmount, goal.currentAmount + addedAmount),
      isCompleted: goal.currentAmount + addedAmount >= goal.targetAmount,
    );
    await _databaseService.updateGoal(updated);
    final index = _goals.indexWhere((item) => item.id == goal.id);
    if (index != -1) {
      _goals[index] = updated;
      notifyListeners();
    }
  }

  Future<void> deleteGoal(Goal goal) async {
    await _databaseService.deleteGoal(goal.id);
    _goals.removeWhere((item) => item.id == goal.id);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await _databaseService.clearAllData();
    await reloadData();
  }

  // ---- Cuentas Bancarias ----

  BankAccount? accountById(String? id) {
    if (id == null) return null;
    for (final account in _bankAccounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  /// Cuenta sugerida al registrar una transacción: la última usada o la primera.
  String? get defaultAccountId {
    if (accountById(_lastAccountId) != null) return _lastAccountId;
    return _bankAccounts.isEmpty ? null : _bankAccounts.first.id;
  }

  double accountBalance(BankAccount account) {
    var balance = account.initialBalance;
    for (final transaction in _transactions) {
      if (transaction.accountId != account.id) continue;
      balance += transaction.type == 'income' ? transaction.amount : -transaction.amount;
    }
    for (final transfer in _transfers) {
      if (transfer.toAccountId == account.id) balance += transfer.amount;
      if (transfer.fromAccountId == account.id) balance -= transfer.amount;
    }
    return balance;
  }

  double get totalAccountsBalance => _bankAccounts.fold(0.0, (sum, account) => sum + accountBalance(account));

  List<AccountMovement> movementsForAccount(BankAccount account) {
    final movements = <AccountMovement>[];
    for (final transaction in _transactions) {
      if (transaction.accountId != account.id) continue;
      movements.add(AccountMovement(
        kind: transaction.type == 'income' ? MovementKind.income : MovementKind.expense,
        amount: transaction.amount,
        date: transaction.date,
        title: transaction.category,
        icon: transaction.icon,
        note: transaction.description,
        transaction: transaction,
      ));
    }
    for (final transfer in _transfers) {
      if (transfer.fromAccountId == account.id) {
        movements.add(AccountMovement(
          kind: MovementKind.transferOut,
          amount: transfer.amount,
          date: transfer.date,
          title: 'Transferencia a ${accountById(transfer.toAccountId)?.name ?? 'otra cuenta'}',
          icon: '↗️',
          note: transfer.note,
          transfer: transfer,
        ));
      } else if (transfer.toAccountId == account.id) {
        movements.add(AccountMovement(
          kind: MovementKind.transferIn,
          amount: transfer.amount,
          date: transfer.date,
          title: 'Transferencia de ${accountById(transfer.fromAccountId)?.name ?? 'otra cuenta'}',
          icon: '↙️',
          note: transfer.note,
          transfer: transfer,
        ));
      }
    }
    movements.sort((left, right) => right.date.compareTo(left.date));
    return movements;
  }

  Future<void> addBankAccount({
    required String name,
    required double initialBalance,
    String icon = '🏦',
  }) async {
    final account = BankAccount(
      id: _uuid.v4(),
      name: name,
      initialBalance: initialBalance,
      icon: icon,
      createdAt: DateTime.now(),
    );
    await _databaseService.insertBankAccount(account);
    _bankAccounts = [..._bankAccounts, account];
    notifyListeners();
  }

  Future<void> updateBankAccount(BankAccount account) async {
    await _databaseService.updateBankAccount(account);
    final index = _bankAccounts.indexWhere((item) => item.id == account.id);
    if (index != -1) {
      _bankAccounts[index] = account;
      notifyListeners();
    }
  }

  Future<void> deleteBankAccount(BankAccount account) async {
    await _databaseService.deleteBankAccount(account.id);
    _bankAccounts.removeWhere((item) => item.id == account.id);
    _transfers.removeWhere((item) => item.fromAccountId == account.id || item.toAccountId == account.id);
    _transactions = _transactions.map((transaction) {
      if (transaction.accountId != account.id) return transaction;
      return Transaction(
        id: transaction.id,
        amount: transaction.amount,
        type: transaction.type,
        category: transaction.category,
        icon: transaction.icon,
        description: transaction.description,
        date: transaction.date,
        isRecurring: transaction.isRecurring,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> addTransfer({
    required BankAccount from,
    required BankAccount to,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    final transfer = AccountTransfer(
      id: _uuid.v4(),
      fromAccountId: from.id,
      toAccountId: to.id,
      amount: amount,
      date: date,
      note: note,
    );
    await _databaseService.insertAccountTransfer(transfer);
    _transfers = [transfer, ..._transfers];
    notifyListeners();
  }

  Future<void> deleteTransfer(AccountTransfer transfer) async {
    await _databaseService.deleteAccountTransfer(transfer.id);
    _transfers.removeWhere((item) => item.id == transfer.id);
    notifyListeners();
  }

  // ---- Cuentas por Cobrar (Receivables) ----

  Future<void> addReceivable({
    required String personName,
    required double initialAmount,
    required DateTime loanDate,
    String? description,
  }) async {
    final receivable = Receivable(
      id: _uuid.v4(),
      personName: personName,
      initialAmount: initialAmount,
      currentBalance: initialAmount, // Inicia con el total a pagar
      loanDate: loanDate,
      description: description,
    );
    await _databaseService.insertReceivable(receivable);
    _receivables = [receivable, ..._receivables];
    notifyListeners();
  }

  Future<void> addReceivablePayment({
    required Receivable receivable,
    required double amount,
    required DateTime paymentDate,
    String? note,
  }) async {
    final payment = ReceivablePayment(
      id: _uuid.v4(),
      receivableId: receivable.id,
      amount: amount,
      paymentDate: paymentDate,
      note: note,
    );
    await _databaseService.insertReceivablePayment(payment);

    // Actualizar balance de la cuenta
    final newBalance = receivable.currentBalance - amount;
    final isPaidOff = newBalance <= 0.01; // Tolerancia de decimales

    final updatedReceivable = receivable.copyWith(
      currentBalance: newBalance < 0 ? 0 : newBalance,
      isPaidOff: isPaidOff,
    );

    await _databaseService.updateReceivable(updatedReceivable);

    final index = _receivables.indexWhere((item) => item.id == receivable.id);
    if (index != -1) {
      _receivables[index] = updatedReceivable;
      notifyListeners();
    }
  }

  Future<List<ReceivablePayment>> getPaymentsForReceivable(String receivableId) async {
    return await _databaseService.getReceivablePayments(receivableId);
  }

  Future<void> deleteReceivable(Receivable receivable) async {
    await _databaseService.deleteReceivable(receivable.id);
    _receivables.removeWhere((item) => item.id == receivable.id);
    notifyListeners();
  }

  Future<void> deleteReceivablePayment(ReceivablePayment payment, Receivable receivable) async {
    await _databaseService.deleteReceivablePayment(payment.id);
    
    // Restaurar el balance
    final newBalance = receivable.currentBalance + payment.amount;
    final updatedReceivable = receivable.copyWith(
      currentBalance: newBalance,
      isPaidOff: false, // Al eliminar un pago, seguro ya no está 100% pagado
    );
    await _databaseService.updateReceivable(updatedReceivable);

    final index = _receivables.indexWhere((item) => item.id == receivable.id);
    if (index != -1) {
      _receivables[index] = updatedReceivable;
      notifyListeners();
    }
  }

  // Payables
  Future<void> addPayable({
    required String creditorName,
    required double initialAmount,
    required DateTime dueDate,
    String? description,
  }) async {
    final payable = Payable(
      id: _uuid.v4(),
      creditorName: creditorName,
      initialAmount: initialAmount,
      currentBalance: initialAmount,
      dueDate: dueDate,
      description: description,
    );
    await _databaseService.insertPayable(payable);
    _payables = [payable, ..._payables];
    notifyListeners();
  }

  Future<void> addPayablePayment({
    required Payable payable,
    required double amount,
    required DateTime paymentDate,
    String? note,
  }) async {
    final payment = PayablePayment(
      id: _uuid.v4(),
      payableId: payable.id,
      amount: amount,
      paymentDate: paymentDate,
      note: note,
    );
    await _databaseService.insertPayablePayment(payment);

    final newBalance = payable.currentBalance - amount;
    final isPaidOff = newBalance <= 0.01;

    final updatedPayable = payable.copyWith(
      currentBalance: newBalance < 0 ? 0 : newBalance,
      isPaidOff: isPaidOff,
    );

    await _databaseService.updatePayable(updatedPayable);

    final index = _payables.indexWhere((item) => item.id == payable.id);
    if (index != -1) {
      _payables[index] = updatedPayable;
      notifyListeners();
    }
  }

  Future<List<PayablePayment>> getPaymentsForPayable(String payableId) async {
    return await _databaseService.getPayablePayments(payableId);
  }

  Future<void> deletePayable(Payable payable) async {
    await _databaseService.deletePayable(payable.id);
    _payables.removeWhere((item) => item.id == payable.id);
    notifyListeners();
  }

  Future<void> deletePayablePayment(PayablePayment payment, Payable payable) async {
    await _databaseService.deletePayablePayment(payment.id);
    
    final newBalance = payable.currentBalance + payment.amount;
    final updatedPayable = payable.copyWith(
      currentBalance: newBalance,
      isPaidOff: false,
    );
    await _databaseService.updatePayable(updatedPayable);

    final index = _payables.indexWhere((item) => item.id == payable.id);
    if (index != -1) {
      _payables[index] = updatedPayable;
      notifyListeners();
    }
  }

  Future<String> exportCsv() async {
    final file = await _databaseService.exportTransactionsCsv(_transactions);
    return file.path;
  }

  String periodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.today:
        return 'Hoy';
      case TimePeriod.week:
        return 'Semana';
      case TimePeriod.month:
        return 'Mes';
      case TimePeriod.year:
        return 'Año';
      case TimePeriod.all:
        return 'Todo';
      case TimePeriod.custom:
        if (_customStartDate != null && _customEndDate != null) {
          return '${_customStartDate!.day}/${_customStartDate!.month} - ${_customEndDate!.day}/${_customEndDate!.month}';
        }
        return 'Personalizado';
    }
  }

  Future<void> refresh() async {
    await reloadData();
  }
}