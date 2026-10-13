import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_rapidas/models/account_transfer.dart';
import 'package:finanzas_rapidas/models/bank_account.dart';
import 'package:finanzas_rapidas/models/transaction.dart';

void main() {
  test('BankAccount se serializa y deserializa correctamente', () {
    final account = BankAccount(
      id: 'acc-1',
      name: 'Banco Unión',
      initialBalance: 1500.75,
      icon: '💳',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
    );

    final restored = BankAccount.fromMap(account.toMap());

    expect(restored.id, equals(account.id));
    expect(restored.name, equals(account.name));
    expect(restored.initialBalance, equals(account.initialBalance));
    expect(restored.icon, equals(account.icon));
    expect(restored.createdAt, equals(account.createdAt));
  });

  test('AccountTransfer se serializa y deserializa correctamente', () {
    final transfer = AccountTransfer(
      id: 'tr-1',
      fromAccountId: 'acc-1',
      toAccountId: 'acc-2',
      amount: 200,
      date: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      note: 'Ahorro',
    );

    final restored = AccountTransfer.fromMap(transfer.toMap());

    expect(restored.fromAccountId, equals('acc-1'));
    expect(restored.toAccountId, equals('acc-2'));
    expect(restored.amount, equals(200));
    expect(restored.note, equals('Ahorro'));
  });

  test('Transaction conserva la cuenta asociada y acepta filas antiguas sin cuenta', () {
    final transaction = Transaction(
      id: 'id-1',
      amount: 50,
      type: 'expense',
      category: 'Comida',
      icon: '🍔',
      date: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      accountId: 'acc-1',
    );

    expect(Transaction.fromMap(transaction.toMap()).accountId, equals('acc-1'));

    final legacy = transaction.toMap()..remove('account_id');
    expect(Transaction.fromMap(legacy).accountId, isNull);
  });
}
