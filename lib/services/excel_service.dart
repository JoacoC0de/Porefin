import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/account_transfer.dart';
import '../models/bank_account.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/goal.dart';
import '../models/receivable.dart';
import '../models/receivable_payment.dart';
import '../models/payable.dart';
import '../models/payable_payment.dart';
import 'database_service.dart';

class ExcelService {
  final DatabaseService _db = DatabaseService();

  Future<File?> exportDataToExcel() async {
    final excel = Excel.createExcel();
    
    // Transactions
    final transactionsSheet = excel['Transacciones'];
    transactionsSheet.appendRow([
      TextCellValue('ID'), 
      TextCellValue('Monto'), 
      TextCellValue('Tipo'), 
      TextCellValue('Categoria'), 
      TextCellValue('Icono'), 
      TextCellValue('Descripcion'), 
      TextCellValue('Fecha'), 
      TextCellValue('Recurrente'),
      TextCellValue('Cuenta ID')
    ]);
    final transactions = await _db.getTransactions();
    for (final t in transactions) {
      transactionsSheet.appendRow([
        TextCellValue(t.id),
        DoubleCellValue(t.amount),
        TextCellValue(t.type),
        TextCellValue(t.category),
        TextCellValue(t.icon),
        TextCellValue(t.description ?? ''),
        TextCellValue(t.date.toIso8601String()),
        TextCellValue(t.isRecurring ? '1' : '0'),
        TextCellValue(t.accountId ?? ''),
      ]);
    }

    // Bank accounts
    final accountsSheet = excel['Cuentas_Bancarias'];
    accountsSheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Nombre'),
      TextCellValue('Saldo Inicial'),
      TextCellValue('Icono'),
      TextCellValue('Creada'),
    ]);
    for (final a in await _db.getBankAccounts()) {
      accountsSheet.appendRow([
        TextCellValue(a.id),
        TextCellValue(a.name),
        DoubleCellValue(a.initialBalance),
        TextCellValue(a.icon),
        TextCellValue(a.createdAt.toIso8601String()),
      ]);
    }

    // Transfers
    final transfersSheet = excel['Transferencias'];
    transfersSheet.appendRow([
      TextCellValue('ID'),
      TextCellValue('Desde'),
      TextCellValue('Hacia'),
      TextCellValue('Monto'),
      TextCellValue('Fecha'),
      TextCellValue('Nota'),
    ]);
    for (final tr in await _db.getAccountTransfers()) {
      transfersSheet.appendRow([
        TextCellValue(tr.id),
        TextCellValue(tr.fromAccountId),
        TextCellValue(tr.toAccountId),
        DoubleCellValue(tr.amount),
        TextCellValue(tr.date.toIso8601String()),
        TextCellValue(tr.note ?? ''),
      ]);
    }

    // Categories
    final categoriesSheet = excel['Categorias'];
    categoriesSheet.appendRow([
      TextCellValue('ID'), 
      TextCellValue('Nombre'), 
      TextCellValue('Icono'), 
      TextCellValue('Color'), 
      TextCellValue('Tipo'), 
      TextCellValue('Orden')
    ]);
    final categories = await _db.getCategories();
    for (final c in categories) {
      categoriesSheet.appendRow([
        TextCellValue(c.id),
        TextCellValue(c.name),
        TextCellValue(c.icon),
        TextCellValue(c.color.toString()),
        TextCellValue(c.type),
        IntCellValue(c.sortOrder),
      ]);
    }

    // Goals
    final goalsSheet = excel['Metas'];
    goalsSheet.appendRow([
      TextCellValue('ID'), 
      TextCellValue('Nombre'), 
      TextCellValue('Objetivo'), 
      TextCellValue('Actual'), 
      TextCellValue('Fecha Limite'), 
      TextCellValue('Icono'), 
      TextCellValue('Completada')
    ]);
    final goals = await _db.getGoals();
    for (final g in goals) {
      goalsSheet.appendRow([
        TextCellValue(g.id),
        TextCellValue(g.name),
        DoubleCellValue(g.targetAmount),
        DoubleCellValue(g.currentAmount),
        TextCellValue(g.deadline.toIso8601String()),
        TextCellValue(g.icon),
        TextCellValue(g.isCompleted ? '1' : '0'),
      ]);
    }

    // Receivables
    final receivablesSheet = excel['Cuentas_Por_Cobrar'];
    receivablesSheet.appendRow([
      TextCellValue('ID'), 
      TextCellValue('Nombre'), 
      TextCellValue('Monto Inicial'), 
      TextCellValue('Saldo Actual'), 
      TextCellValue('Fecha Prestamo'), 
      TextCellValue('Descripcion'), 
      TextCellValue('Pagado')
    ]);
    final receivables = await _db.getReceivables();
    for (final r in receivables) {
      receivablesSheet.appendRow([
        TextCellValue(r.id),
        TextCellValue(r.personName),
        DoubleCellValue(r.initialAmount),
        DoubleCellValue(r.currentBalance),
        TextCellValue(r.loanDate.toIso8601String()),
        TextCellValue(r.description ?? ''),
        TextCellValue(r.isPaidOff ? '1' : '0'),
      ]);
    }

    // Payables
    final payablesSheet = excel['Cuentas_Por_Pagar'];
    payablesSheet.appendRow([
      TextCellValue('ID'), 
      TextCellValue('Acreedor'), 
      TextCellValue('Monto Inicial'), 
      TextCellValue('Saldo Actual'), 
      TextCellValue('Fecha Limite'), 
      TextCellValue('Descripcion'), 
      TextCellValue('Pagado')
    ]);
    final payables = await _db.getPayables();
    for (final p in payables) {
      payablesSheet.appendRow([
        TextCellValue(p.id),
        TextCellValue(p.creditorName),
        DoubleCellValue(p.initialAmount),
        DoubleCellValue(p.currentBalance),
        TextCellValue(p.dueDate.toIso8601String()),
        TextCellValue(p.description ?? ''),
        TextCellValue(p.isPaidOff ? '1' : '0'),
      ]);
    }

    // Default sheet is removed
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/respaldo_finanzas_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      return file;
    }
    return null;
  }

  Future<bool> importDataFromExcel() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result.isNotEmpty && result.single.path != null) {
        final file = File(result.single.path!);
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        // Transactions
        if (excel.tables.containsKey('Transacciones')) {
          final sheet = excel.tables['Transacciones']!;
          for (var i = 1; i < sheet.maxRows; i++) {
            final row = sheet.row(i);
            if (row.isEmpty || row[0] == null) continue;
            
            final id = row[0]?.value.toString() ?? '';
            final amount = double.tryParse(row[1]?.value.toString() ?? '0') ?? 0;
            final type = row[2]?.value.toString() ?? 'expense';
            final category = row[3]?.value.toString() ?? '';
            final icon = row[4]?.value.toString() ?? '';
            final description = row[5]?.value.toString();
            final dateStr = row[6]?.value.toString() ?? '';
            final date = DateTime.tryParse(dateStr) ?? DateTime.now();
            final isRecurring = row[7]?.value.toString() == '1';
            final accountId = row.length > 8 ? row[8]?.value.toString() : null;

            if (id.isNotEmpty && category.isNotEmpty) {
              await _db.insertTransaction(Transaction(
                id: id,
                amount: amount,
                type: type,
                category: category,
                icon: icon,
                description: description,
                date: date,
                isRecurring: isRecurring,
                accountId: accountId == null || accountId.isEmpty ? null : accountId,
              ));
            }
          }
        }

        // Bank accounts
        if (excel.tables.containsKey('Cuentas_Bancarias')) {
          final sheet = excel.tables['Cuentas_Bancarias']!;
          for (var i = 1; i < sheet.maxRows; i++) {
            final row = sheet.row(i);
            if (row.isEmpty || row[0] == null) continue;

            final id = row[0]?.value.toString() ?? '';
            final name = row[1]?.value.toString() ?? '';
            final initialBalance = double.tryParse(row[2]?.value.toString() ?? '0') ?? 0;
            final icon = row[3]?.value.toString() ?? '🏦';
            final createdAt = DateTime.tryParse(row[4]?.value.toString() ?? '') ?? DateTime.now();

            if (id.isNotEmpty && name.isNotEmpty) {
              await _db.insertBankAccount(BankAccount(
                id: id,
                name: name,
                initialBalance: initialBalance,
                icon: icon,
                createdAt: createdAt,
              ));
            }
          }
        }

        // Transfers
        if (excel.tables.containsKey('Transferencias')) {
          final sheet = excel.tables['Transferencias']!;
          for (var i = 1; i < sheet.maxRows; i++) {
            final row = sheet.row(i);
            if (row.isEmpty || row[0] == null) continue;

            final id = row[0]?.value.toString() ?? '';
            final fromId = row[1]?.value.toString() ?? '';
            final toId = row[2]?.value.toString() ?? '';
            final amount = double.tryParse(row[3]?.value.toString() ?? '0') ?? 0;
            final date = DateTime.tryParse(row[4]?.value.toString() ?? '') ?? DateTime.now();
            final note = row[5]?.value.toString();

            if (id.isNotEmpty && fromId.isNotEmpty && toId.isNotEmpty) {
              await _db.insertAccountTransfer(AccountTransfer(
                id: id,
                fromAccountId: fromId,
                toAccountId: toId,
                amount: amount,
                date: date,
                note: note == null || note.isEmpty ? null : note,
              ));
            }
          }
        }
        
        // Goals
        if (excel.tables.containsKey('Metas')) {
          final sheet = excel.tables['Metas']!;
          for (var i = 1; i < sheet.maxRows; i++) {
            final row = sheet.row(i);
            if (row.isEmpty || row[0] == null) continue;
            
            final id = row[0]?.value.toString() ?? '';
            final name = row[1]?.value.toString() ?? '';
            final targetAmount = double.tryParse(row[2]?.value.toString() ?? '0') ?? 0;
            final currentAmount = double.tryParse(row[3]?.value.toString() ?? '0') ?? 0;
            final dateStr = row[4]?.value.toString() ?? '';
            final deadline = DateTime.tryParse(dateStr) ?? DateTime.now();
            final icon = row[5]?.value.toString() ?? '';
            final isCompleted = row[6]?.value.toString() == '1';

            if (id.isNotEmpty && name.isNotEmpty) {
              await _db.insertGoal(Goal(
                id: id,
                name: name,
                targetAmount: targetAmount,
                currentAmount: currentAmount,
                deadline: deadline,
                icon: icon,
                isCompleted: isCompleted,
              ));
            }
          }
        }

        // Receivables
        if (excel.tables.containsKey('Cuentas_Por_Cobrar')) {
          final sheet = excel.tables['Cuentas_Por_Cobrar']!;
          for (var i = 1; i < sheet.maxRows; i++) {
            final row = sheet.row(i);
            if (row.isEmpty || row[0] == null) continue;
            
            final id = row[0]?.value.toString() ?? '';
            final personName = row[1]?.value.toString() ?? '';
            final initialAmount = double.tryParse(row[2]?.value.toString() ?? '0') ?? 0;
            final currentBalance = double.tryParse(row[3]?.value.toString() ?? '0') ?? 0;
            final dateStr = row[4]?.value.toString() ?? '';
            final loanDate = DateTime.tryParse(dateStr) ?? DateTime.now();
            final description = row[5]?.value.toString();
            final isPaidOff = row[6]?.value.toString() == '1';

            if (id.isNotEmpty && personName.isNotEmpty) {
              await _db.insertReceivable(Receivable(
                id: id,
                personName: personName,
                initialAmount: initialAmount,
                currentBalance: currentBalance,
                loanDate: loanDate,
                description: description,
                isPaidOff: isPaidOff,
              ));
            }
          }
        }

        // Payables
        if (excel.tables.containsKey('Cuentas_Por_Pagar')) {
          final sheet = excel.tables['Cuentas_Por_Pagar']!;
          for (var i = 1; i < sheet.maxRows; i++) {
            final row = sheet.row(i);
            if (row.isEmpty || row[0] == null) continue;
            
            final id = row[0]?.value.toString() ?? '';
            final creditorName = row[1]?.value.toString() ?? '';
            final initialAmount = double.tryParse(row[2]?.value.toString() ?? '0') ?? 0;
            final currentBalance = double.tryParse(row[3]?.value.toString() ?? '0') ?? 0;
            final dateStr = row[4]?.value.toString() ?? '';
            final dueDate = DateTime.tryParse(dateStr) ?? DateTime.now();
            final description = row[5]?.value.toString();
            final isPaidOff = row[6]?.value.toString() == '1';

            if (id.isNotEmpty && creditorName.isNotEmpty) {
              await _db.insertPayable(Payable(
                id: id,
                creditorName: creditorName,
                initialAmount: initialAmount,
                currentBalance: currentBalance,
                dueDate: dueDate,
                description: description,
                isPaidOff: isPaidOff,
              ));
            }
          }
        }

        return true;
      }
    } catch (e) {
      print("Error importando Excel: $e");
    }
    return false;
  }
}
