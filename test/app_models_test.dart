import 'package:flutter_test/flutter_test.dart';

import 'package:finanzas_rapidas/models/transaction.dart';
import 'package:finanzas_rapidas/theme/app_theme.dart';

void main() {
  test('colorFromHex convierte colores hexadecimales', () {
    final color = AppTheme.colorFromHex('#FF6D00');
    expect(color.toARGB32(), equals(0xFFFF6D00));
  });

  test('Transaction se serializa y deserializa correctamente', () {
    final transaction = Transaction(
      id: 'id-1',
      amount: 42.5,
      type: 'expense',
      category: 'Comida',
      icon: '🍔',
      description: 'Almuerzo',
      date: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      isRecurring: true,
    );

    final restored = Transaction.fromMap(transaction.toMap());

    expect(restored.id, equals(transaction.id));
    expect(restored.amount, equals(transaction.amount));
    expect(restored.type, equals(transaction.type));
    expect(restored.category, equals(transaction.category));
    expect(restored.icon, equals(transaction.icon));
    expect(restored.description, equals(transaction.description));
    expect(restored.date, equals(transaction.date));
    expect(restored.isRecurring, isTrue);
  });
}