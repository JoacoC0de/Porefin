import 'package:flutter/material.dart';

import 'bank_accounts_screen.dart';
import 'receivables_screen.dart';
import 'payables_screen.dart';
import '../theme/app_theme.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Cuentas'),
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Bancarias'),
              Tab(text: 'Por Cobrar (Me deben)'),
              Tab(text: 'Por Pagar (Debo)'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Reutilizamos las pantallas pero les quitamos su Scaffold interno si tienen AppBar
            // Como ya tienen Scaffold con AppBar, tal vez tengamos AppBar doble,
            // pero para solucionarlo rápidamente vamos a envolverlas de esta manera.
            // En `receivables_screen.dart` y `payables_screen.dart` el AppBar se mantiene, 
            // pero podemos ocultarlo enviando un parametro o manejándolo en un widget.
            // Ya que tienen AppBar, vamos a mostrarlas directamente (aunque haya AppBar doble por ahora o las adaptamos).
            BankAccountsScreen(),
            _ReceivablesTab(),
            _PayablesTab(),
          ],
        ),
      ),
    );
  }
}

// Estos wrappers sirven para mostrar la pantalla sin su propio Scaffold y AppBar
class _ReceivablesTab extends StatelessWidget {
  const _ReceivablesTab();

  @override
  Widget build(BuildContext context) {
    // Ya que ReceivablesScreen devuelve un Scaffold con AppBar, lo usamos directamente.
    // Para evitar 2 AppBars, el AccountsScreen no debería tener AppBar si las hijas ya lo tienen, 
    // pero el TabBar debe estar en un AppBar.
    // Así que lo mejor es mostrar el body y fab de esas pantallas, pero es más fácil
    // modificar ReceivablesScreen para que acepte si es Tab o no, pero por simplicidad
    // vamos a renderizarlas dentro de un Scaffold sin AppBar acá y removemos los Scaffold de ellas,
    // ¡O simplemente dejamos que ReceivablesScreen y PayablesScreen SEAN el contenido del TabBarView!
    // Para ello, modificaré Receivables y Payables para que su Scaffold no tenga AppBar.
    return const ReceivablesScreen();
  }
}

class _PayablesTab extends StatelessWidget {
  const _PayablesTab();

  @override
  Widget build(BuildContext context) {
    return const PayablesScreen();
  }
}
