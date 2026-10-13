import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/receivable.dart';
import '../models/receivable_payment.dart';
import '../providers/finance_provider.dart';

class ReceivablesScreen extends StatelessWidget {
  const ReceivablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final receivables = provider.receivables;

        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddReceivableDialog(context, provider),
            child: const Icon(Icons.add),
          ),
          body: receivables.isEmpty
              ? const Center(child: Text('No hay cuentas por cobrar registradas.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: receivables.length,
                  itemBuilder: (context, index) {
                    final receivable = receivables[index];
                    return _ReceivableCard(receivable: receivable);
                  },
                ),
        );
      },
    );
  }

  void _showAddReceivableDialog(BuildContext context, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _AddReceivableDialog(provider: provider),
    );
  }
}

class _ReceivableCard extends StatelessWidget {
  final Receivable receivable;

  const _ReceivableCard({required this.receivable});

  void _confirmDelete(BuildContext context, FinanceProvider provider, Receivable receivable) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text('¿Estás seguro de que deseas eliminar la cuenta de ${receivable.personName} y todo su historial de abonos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              provider.deleteReceivable(receivable);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final isPaidOff = receivable.isPaidOff;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                receivable.personName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isPaidOff ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _confirmDelete(context, provider, receivable),
            ),
          ],
        ),
        subtitle: Text(
          'Saldo: ${provider.formatMoney(receivable.currentBalance)} / ${provider.formatMoney(receivable.initialAmount)}',
          style: TextStyle(color: isPaidOff ? Colors.green : Colors.orange),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (receivable.description != null && receivable.description!.isNotEmpty)
                  Text('Nota: ${receivable.description}'),
                const SizedBox(height: 8),
                Text('Fecha Préstamo: ${receivable.loanDate.toLocal().toString().split(' ')[0]}'),
                const SizedBox(height: 16),
                if (!isPaidOff)
                  ElevatedButton.icon(
                    onPressed: () => _showAddPaymentDialog(context, provider, receivable),
                    icon: const Icon(Icons.payment),
                    label: const Text('Registrar Abono'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showPaymentsHistory(context, provider, receivable),
                  icon: const Icon(Icons.history),
                  label: const Text('Ver Historial de Abonos'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, FinanceProvider provider, Receivable receivable) {
    showDialog(
      context: context,
      builder: (context) => _AddPaymentDialog(provider: provider, receivable: receivable),
    );
  }

  void _showPaymentsHistory(BuildContext context, FinanceProvider provider, Receivable receivable) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PaymentsHistorySheet(provider: provider, receivable: receivable),
    );
  }
}

class _AddReceivableDialog extends StatefulWidget {
  final FinanceProvider provider;

  const _AddReceivableDialog({required this.provider});

  @override
  State<_AddReceivableDialog> createState() => _AddReceivableDialogState();
}

class _AddReceivableDialogState extends State<_AddReceivableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuevo Préstamo'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la Persona'),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Monto'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  if (double.tryParse(val) == null) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Descripción (Opcional)'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text('Fecha: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                      }
                    },
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.provider.addReceivable(
                personName: _nameController.text,
                initialAmount: double.parse(_amountController.text),
                loanDate: _selectedDate,
                description: _descController.text,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _AddPaymentDialog extends StatefulWidget {
  final FinanceProvider provider;
  final Receivable receivable;

  const _AddPaymentDialog({required this.provider, required this.receivable});

  @override
  State<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<_AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  bool _useCurrentTime = true;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _useCurrentTime = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Abono a ${widget.receivable.personName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Saldo actual: ${widget.provider.formatMoney(widget.receivable.currentBalance)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Monto a abonar'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  final amount = double.tryParse(val);
                  if (amount == null) return 'Monto inválido';
                  if (amount <= 0) return 'Mayor a cero';
                  if (amount > widget.receivable.currentBalance) return 'Supera el saldo';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Nota (Opcional)'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Usar fecha y hora actual'),
                value: _useCurrentTime,
                onChanged: (val) {
                  setState(() {
                    _useCurrentTime = val;
                    if (val) _selectedDateTime = DateTime.now();
                  });
                },
              ),
              if (!_useCurrentTime)
                Row(
                  children: [
                    Expanded(
                      child: Text('Fecha/Hora:\n${_selectedDateTime.toLocal().toString().substring(0, 16)}'),
                    ),
                    TextButton(
                      onPressed: _pickDateTime,
                      child: const Text('Cambiar'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.provider.addReceivablePayment(
                receivable: widget.receivable,
                amount: double.parse(_amountController.text),
                paymentDate: _useCurrentTime ? DateTime.now() : _selectedDateTime,
                note: _noteController.text,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}

class _PaymentsHistorySheet extends StatelessWidget {
  final FinanceProvider provider;
  final Receivable receivable;

  const _PaymentsHistorySheet({required this.provider, required this.receivable});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReceivablePayment>>(
      future: provider.getPaymentsForReceivable(receivable.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final payments = snapshot.data ?? [];
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Historial de Abonos - ${receivable.personName}',
                  style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              if (payments.isEmpty)
                const Expanded(child: Center(child: Text('No hay abonos registrados.')))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return Dismissible(
                        key: ValueKey(payment.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar abono'),
                              content: const Text('¿Estás seguro de que deseas eliminar este abono? El saldo de la cuenta se restaurará.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          provider.deleteReceivablePayment(payment, receivable);
                        },
                        child: ListTile(
                          leading: const Icon(Icons.attach_money, color: Colors.green),
                          title: Text(provider.formatMoney(payment.amount)),
                          subtitle: Text(
                            '${payment.paymentDate.toLocal().toString().substring(0, 16)}${payment.note != null && payment.note!.isNotEmpty ? ' • ${payment.note}' : ''}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
