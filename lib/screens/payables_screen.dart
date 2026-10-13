import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/payable.dart';
import '../models/payable_payment.dart';
import '../providers/finance_provider.dart';

class PayablesScreen extends StatelessWidget {
  const PayablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final payables = provider.payables;

        return Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddPayableDialog(context, provider),
            child: const Icon(Icons.add),
          ),
          body: payables.isEmpty
              ? const Center(child: Text('No hay cuentas por pagar registradas.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payables.length,
                  itemBuilder: (context, index) {
                    final payable = payables[index];
                    return _PayableCard(payable: payable);
                  },
                ),
        );
      },
    );
  }

  void _showAddPayableDialog(BuildContext context, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _AddPayableDialog(provider: provider),
    );
  }
}

class _PayableCard extends StatelessWidget {
  final Payable payable;

  const _PayableCard({required this.payable});

  void _confirmDelete(BuildContext context, FinanceProvider provider, Payable payable) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Text('¿Estás seguro de que deseas eliminar la deuda con ${payable.creditorName} y todo su historial de pagos?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              provider.deletePayable(payable);
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
    final isPaidOff = payable.isPaidOff;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                payable.creditorName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isPaidOff ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _confirmDelete(context, provider, payable),
            ),
          ],
        ),
        subtitle: Text(
          'Saldo a pagar: ${provider.formatMoney(payable.currentBalance)} / ${provider.formatMoney(payable.initialAmount)}',
          style: TextStyle(color: isPaidOff ? Colors.green : Colors.redAccent),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (payable.description != null && payable.description!.isNotEmpty)
                  Text('Nota: ${payable.description}'),
                const SizedBox(height: 8),
                Text('Fecha Límite: ${payable.dueDate.toLocal().toString().split(' ')[0]}'),
                const SizedBox(height: 16),
                if (!isPaidOff)
                  ElevatedButton.icon(
                    onPressed: () => _showAddPaymentDialog(context, provider, payable),
                    icon: const Icon(Icons.payment),
                    label: const Text('Registrar Pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showPaymentsHistory(context, provider, payable),
                  icon: const Icon(Icons.history),
                  label: const Text('Ver Historial de Pagos'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, FinanceProvider provider, Payable payable) {
    showDialog(
      context: context,
      builder: (context) => _AddPaymentDialog(provider: provider, payable: payable),
    );
  }

  void _showPaymentsHistory(BuildContext context, FinanceProvider provider, Payable payable) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PaymentsHistorySheet(provider: provider, payable: payable),
    );
  }
}

class _AddPayableDialog extends StatefulWidget {
  final FinanceProvider provider;

  const _AddPayableDialog({required this.provider});

  @override
  State<_AddPayableDialog> createState() => _AddPayableDialogState();
}

class _AddPayableDialogState extends State<_AddPayableDialog> {
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
      title: const Text('Nueva Deuda (Por Pagar)'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Acreedor (A quién debes)'),
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Monto de la deuda'),
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
                    child: Text('Fecha límite: ${_selectedDate.toLocal().toString().split(' ')[0]}'),
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
              widget.provider.addPayable(
                creditorName: _nameController.text,
                initialAmount: double.parse(_amountController.text),
                dueDate: _selectedDate,
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
  final Payable payable;

  const _AddPaymentDialog({required this.provider, required this.payable});

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
      title: Text('Pagar a ${widget.payable.creditorName}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Saldo a pagar: ${widget.provider.formatMoney(widget.payable.currentBalance)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Monto a pagar'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Requerido';
                  final amount = double.tryParse(val);
                  if (amount == null) return 'Monto inválido';
                  if (amount <= 0) return 'Mayor a cero';
                  if (amount > widget.payable.currentBalance) return 'Supera la deuda restante';
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
              widget.provider.addPayablePayment(
                payable: widget.payable,
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
  final Payable payable;

  const _PaymentsHistorySheet({required this.provider, required this.payable});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PayablePayment>>(
      future: provider.getPaymentsForPayable(payable.id),
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
              Text('Historial de Pagos - ${payable.creditorName}',
                  style: Theme.of(context).textTheme.titleLarge),
              const Divider(),
              if (payments.isEmpty)
                const Expanded(child: Center(child: Text('No hay pagos registrados.')))
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
                              title: const Text('Eliminar pago'),
                              content: const Text('¿Estás seguro de que deseas eliminar este pago? La deuda aumentará.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          provider.deletePayablePayment(payment, payable);
                        },
                        child: ListTile(
                          leading: const Icon(Icons.money_off, color: Colors.redAccent),
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
