import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/bank_account.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

const _accountIcons = ['🏦', '💳', '💵', '🐷', '📱', '💼', '🪙', '💰'];

double? _parseAmount(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

class BankAccountsScreen extends StatelessWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final accounts = provider.bankAccounts;

        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_bank_account',
            onPressed: () => showAccountFormDialog(context),
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _TotalCard(provider: provider),
              const SizedBox(height: 18),
              if (accounts.isEmpty)
                const _EmptyAccounts()
              else
                ...accounts.map((account) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AccountCard(account: account),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  final FinanceProvider provider;

  const _TotalCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final canTransfer = provider.bankAccounts.length >= 2;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.35), AppTheme.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Saldo total en cuentas', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            provider.formatMoney(provider.totalAccountsBalance),
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 4),
          Text(
            '${provider.bankAccounts.length} cuenta(s) registrada(s)',
            style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: canTransfer ? () => showTransferDialog(context) : null,
            icon: const Icon(Icons.swap_horiz),
            label: Text(canTransfer ? 'Transferir entre cuentas' : 'Crea 2 cuentas para transferir'),
          ),
        ],
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.account_balance_outlined, color: AppTheme.textTertiary, size: 40),
          SizedBox(height: 12),
          Text('No tienes cuentas registradas', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text(
            'Toca + para agregar tu cuenta bancaria, billetera o efectivo con su saldo actual.',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final BankAccount account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final balance = provider.accountBalance(account);

    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AccountDetailScreen(accountId: account.id)),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.16),
                child: Text(account.icon, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    const Text('Ver historial', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                  ],
                ),
              ),
              Text(
                provider.formatMoney(balance),
                style: TextStyle(
                  color: balance < 0 ? AppTheme.expense : AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              _AccountMenu(account: account),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  final BankAccount account;
  final VoidCallback? onDeleted;

  const _AccountMenu({required this.account, this.onDeleted});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
      onSelected: (value) async {
        if (value == 'edit') {
          showAccountFormDialog(context, account: account);
        } else if (value == 'delete') {
          final deleted = await _confirmDeleteAccount(context, account);
          if (deleted) onDeleted?.call();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: AppTheme.expense))),
      ],
    );
  }
}

Future<bool> _confirmDeleteAccount(BuildContext context, BankAccount account) async {
  final provider = context.read<FinanceProvider>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Eliminar cuenta'),
      content: Text(
        '¿Eliminar "${account.name}"? Se borrarán sus transferencias. '
        'Los ingresos y gastos registrados se conservan, pero quedarán sin cuenta asignada.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar', style: TextStyle(color: AppTheme.expense)),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;
  await provider.deleteBankAccount(account);
  return true;
}

// ---------------------------------------------------------------------------
// Crear / editar cuenta
// ---------------------------------------------------------------------------

Future<void> showAccountFormDialog(BuildContext context, {BankAccount? account}) {
  final provider = context.read<FinanceProvider>();
  return showDialog(
    context: context,
    builder: (_) => _AccountFormDialog(provider: provider, account: account),
  );
}

class _AccountFormDialog extends StatefulWidget {
  final FinanceProvider provider;
  final BankAccount? account;

  const _AccountFormDialog({required this.provider, this.account});

  @override
  State<_AccountFormDialog> createState() => _AccountFormDialogState();
}

class _AccountFormDialogState extends State<_AccountFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late String _icon;

  bool get _isEditing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _nameController = TextEditingController(text: account?.name ?? '');
    _amountController = TextEditingController(
      text: account == null ? '' : account.initialBalance.toStringAsFixed(2),
    );
    _icon = account?.icon ?? _accountIcons.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final amount = _parseAmount(_amountController.text) ?? 0;

    if (_isEditing) {
      await widget.provider.updateBankAccount(
        widget.account!.copyWith(name: name, initialBalance: amount, icon: _icon),
      );
    } else {
      await widget.provider.addBankAccount(name: name, initialBalance: amount, icon: _icon);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar cuenta' : 'Nueva cuenta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Nombre de la cuenta', hintText: 'Ej. Banco Unión, Efectivo'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: _isEditing ? 'Saldo inicial' : 'Monto actual',
                  prefixText: 'Bs ',
                  hintText: '0.00',
                  helperText: _isEditing ? 'El saldo actual se recalcula con los movimientos' : null,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return null;
                  return _parseAmount(val) == null ? 'Monto inválido' : null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Ícono', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _accountIcons.map((icon) {
                  final selected = icon == _icon;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _icon = icon),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primary.withValues(alpha: 0.22) : AppTheme.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: selected ? AppTheme.primary : AppTheme.border),
                      ),
                      child: Text(icon, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Transferencias
// ---------------------------------------------------------------------------

Future<void> showTransferDialog(BuildContext context, {BankAccount? from}) {
  final provider = context.read<FinanceProvider>();
  return showDialog(
    context: context,
    builder: (_) => _TransferDialog(provider: provider, initialFrom: from),
  );
}

class _TransferDialog extends StatefulWidget {
  final FinanceProvider provider;
  final BankAccount? initialFrom;

  const _TransferDialog({required this.provider, this.initialFrom});

  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late String _fromId;
  late String _toId;
  DateTime _date = DateTime.now();

  FinanceProvider get _provider => widget.provider;

  @override
  void initState() {
    super.initState();
    final accounts = _provider.bankAccounts;
    _fromId = widget.initialFrom?.id ?? accounts.first.id;
    _toId = accounts.firstWhere((account) => account.id != _fromId).id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final now = DateTime.now();
    setState(() => _date = DateTime(date.year, date.month, date.day, now.hour, now.minute));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final note = _noteController.text.trim();
    await _provider.addTransfer(
      from: _provider.accountById(_fromId)!,
      to: _provider.accountById(_toId)!,
      amount: _parseAmount(_amountController.text)!,
      date: _date,
      note: note.isEmpty ? null : note,
    );
    if (mounted) Navigator.of(context).pop();
  }

  DropdownMenuItem<String> _accountItem(BankAccount account) {
    return DropdownMenuItem(
      value: account.id,
      child: Text(
        '${account.icon} ${account.name} (${_provider.formatMoney(_provider.accountBalance(account))})',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _provider.bankAccounts;
    final fromAccount = _provider.accountById(_fromId)!;
    final available = _provider.accountBalance(fromAccount);

    return AlertDialog(
      title: const Text('Transferir entre cuentas'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _fromId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Desde'),
                items: accounts.map(_accountItem).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _fromId = value;
                    if (_toId == value) {
                      _toId = accounts.firstWhere((account) => account.id != value).id;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('to_$_fromId'),
                initialValue: _toId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Hacia'),
                items: accounts.where((account) => account.id != _fromId).map(_accountItem).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _toId = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Monto',
                  prefixText: 'Bs ',
                  helperText: 'Disponible: ${_provider.formatMoney(available)}',
                ),
                validator: (val) {
                  final amount = _parseAmount(val ?? '');
                  if (amount == null) return 'Monto inválido';
                  if (amount <= 0) return 'Debe ser mayor a cero';
                  if (amount > available + 0.001) return 'Saldo insuficiente en la cuenta de origen';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Nota (opcional)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: Text('Fecha: ${DateFormat('dd MMM yyyy', 'es').format(_date)}')),
                  TextButton(onPressed: _pickDate, child: const Text('Cambiar')),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _save, child: const Text('Transferir')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Detalle e historial de una cuenta
// ---------------------------------------------------------------------------

enum _MovementFilter { all, income, expense, transfers }

class AccountDetailScreen extends StatefulWidget {
  final String accountId;

  const AccountDetailScreen({super.key, required this.accountId});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  _MovementFilter _filter = _MovementFilter.all;

  bool _matches(AccountMovement movement) {
    switch (_filter) {
      case _MovementFilter.all:
        return true;
      case _MovementFilter.income:
        return movement.kind == MovementKind.income;
      case _MovementFilter.expense:
        return movement.kind == MovementKind.expense;
      case _MovementFilter.transfers:
        return movement.transfer != null;
    }
  }

  String _filterLabel(_MovementFilter filter) {
    switch (filter) {
      case _MovementFilter.all:
        return 'Todos';
      case _MovementFilter.income:
        return 'Ingresos';
      case _MovementFilter.expense:
        return 'Egresos';
      case _MovementFilter.transfers:
        return 'Transferencias';
    }
  }

  Future<bool> _confirmDeleteMovement(AccountMovement movement) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text(
          movement.transfer != null
              ? '¿Eliminar esta transferencia? El saldo de ambas cuentas se restaurará.'
              : '¿Eliminar este movimiento? También se quitará del historial general.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    final account = provider.accountById(widget.accountId);
    if (account == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('La cuenta ya no existe.')));
    }

    final movements = provider.movementsForAccount(account);
    final inflow = movements.where((m) => m.isInflow).fold(0.0, (sum, m) => sum + m.amount);
    final outflow = movements.where((m) => !m.isInflow).fold(0.0, (sum, m) => sum + m.amount);
    final visible = movements.where(_matches).toList();
    final balance = provider.accountBalance(account);

    return Scaffold(
      appBar: AppBar(
        title: Text('${account.icon} ${account.name}'),
        actions: [
          _AccountMenu(account: account, onDeleted: () => Navigator.of(context).pop()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Text('Saldo actual', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            provider.formatMoney(balance),
            style: TextStyle(
              color: balance < 0 ? AppTheme.expense : AppTheme.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Saldo inicial: ${provider.formatMoney(account.initialBalance)}',
            style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatTile(label: 'Entradas', value: provider.formatMoney(inflow), color: AppTheme.income)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: 'Salidas', value: provider.formatMoney(outflow), color: AppTheme.expense)),
            ],
          ),
          const SizedBox(height: 12),
          if (provider.bankAccounts.length >= 2)
            OutlinedButton.icon(
              onPressed: () => showTransferDialog(context, from: account),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Transferir desde esta cuenta'),
            ),
          const SizedBox(height: 18),
          const Text('Historial', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _MovementFilter.values.map((filter) {
              final selected = filter == _filter;
              return ChoiceChip(
                label: Text(_filterLabel(filter)),
                selected: selected,
                onSelected: (_) => setState(() => _filter = filter),
                selectedColor: AppTheme.primary.withValues(alpha: 0.22),
                labelStyle: TextStyle(
                  color: selected ? AppTheme.primary : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
                side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('No hay movimientos para mostrar.', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...visible.map((movement) {
              final key = movement.transaction?.id ?? movement.transfer!.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: ValueKey('movement_$key'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.expense.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 18),
                    child: const Icon(Icons.delete_outline, color: AppTheme.expense),
                  ),
                  confirmDismiss: (_) => _confirmDeleteMovement(movement),
                  onDismissed: (_) {
                    if (movement.transfer != null) {
                      provider.deleteTransfer(movement.transfer!);
                    } else {
                      provider.deleteTransaction(movement.transaction!);
                    }
                  },
                  child: _MovementTile(movement: movement, formatMoney: provider.formatMoney),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  final AccountMovement movement;
  final String Function(double value) formatMoney;

  const _MovementTile({required this.movement, required this.formatMoney});

  @override
  Widget build(BuildContext context) {
    final isTransfer = movement.transfer != null;
    final color = isTransfer ? AppTheme.info : (movement.isInflow ? AppTheme.income : AppTheme.expense);
    final dateLabel = DateFormat('dd MMM yyyy • HH:mm', 'es').format(movement.date);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.16),
          child: Text(movement.icon, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(movement.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (movement.note != null && movement.note!.isNotEmpty)
              Text(
                movement.note!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            Text(dateLabel, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
          ],
        ),
        trailing: Text(
          '${movement.isInflow ? '+' : '-'}${formatMoney(movement.amount)}',
          style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
