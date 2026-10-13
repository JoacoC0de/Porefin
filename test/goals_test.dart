import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:finanzas_rapidas/providers/finance_provider.dart';
import 'package:finanzas_rapidas/screens/goals_screen.dart';
import 'package:finanzas_rapidas/models/goal.dart';

class FakeFinanceProvider extends FinanceProvider {
  final List<Goal> _fakeGoals = [];

  @override
  List<Goal> get goals => List.unmodifiable(_fakeGoals);

  @override
  Future<void> addGoal({
    required String name,
    required double targetAmount,
    required DateTime deadline,
    required String icon,
  }) async {
    _fakeGoals.add(Goal(
      id: '1',
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0,
      deadline: deadline,
      icon: icon,
    ));
    notifyListeners();
  }

  @override
  Future<void> updateGoalProgress(Goal goal, double addedAmount) async {
    final index = _fakeGoals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      final updated = _fakeGoals[index].copyWith(
        currentAmount: _fakeGoals[index].currentAmount + addedAmount,
      );
      _fakeGoals[index] = updated;
      notifyListeners();
    }
  }
}

void main() {
  testWidgets('Test de dialogo de creación de meta y abonar en GoalsScreen', (WidgetTester tester) async {
    final fakeProvider = FakeFinanceProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<FinanceProvider>.value(
        value: fakeProvider,
        child: const MaterialApp(
          home: Scaffold(
            body: GoalsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Abrir diálogo de nueva meta
    final addIcon = find.byIcon(Icons.add).first;
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Llenar datos
    final nameField = find.widgetWithText(TextField, 'Nombre');
    final amountField = find.widgetWithText(TextField, 'Monto objetivo');

    await tester.enterText(nameField, 'Fondo de emergencia');
    await tester.enterText(amountField, '500');
    await tester.pumpAndSettle();

    // Guardar
    final saveBtn = find.widgetWithText(FilledButton, 'Guardar');
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    expect(find.text('Fondo de emergencia'), findsOneWidget);

    // Probar abonar
    final abonarBtn = find.widgetWithText(OutlinedButton, 'Abonar');
    await tester.tap(abonarBtn);
    await tester.pumpAndSettle();

    final abonarAmountField = find.widgetWithText(TextField, 'Monto a abonar');
    await tester.enterText(abonarAmountField, '100');
    await tester.pumpAndSettle();

    final saveAbonarBtn = find.widgetWithText(FilledButton, 'Guardar');
    await tester.tap(saveAbonarBtn);
    await tester.pumpAndSettle();

    expect(find.text('Bs 100,00'), findsOneWidget);
  });
}
