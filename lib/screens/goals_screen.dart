import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/goal.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Metas',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton.filled(
                  onPressed: () => _showGoalDialog(context),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Progreso de ahorro y objetivos financieros.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            if (provider.goals.isEmpty)
              _EmptyGoals(onAdd: () => _showGoalDialog(context))
            else
              ...provider.goals.map((goal) {
                final percent = goal.targetAmount == 0 ? 0.0 : (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(goal.icon, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(goal.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  'Meta para ${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${(percent * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
                              Text(goal.isCompleted ? 'Completada' : 'En progreso', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: percent.toDouble(),
                          backgroundColor: AppTheme.surface,
                          valueColor: const AlwaysStoppedAnimation(
                            AppTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(provider.formatMoney(goal.currentAmount), style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                          Text('de ${provider.formatMoney(goal.targetAmount)}', style: const TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OverflowBar(
                        alignment: MainAxisAlignment.start,
                        spacing: 10,
                        overflowSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showProgressDialog(context, goal),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Abonar'),
                          ),
                          IconButton(
                            onPressed: () => provider.deleteGoal(goal),
                            icon: const Icon(Icons.delete_outline),
                            color: AppTheme.expense,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  void _showGoalDialog(BuildContext context) {
    final provider = context.read<FinanceProvider>();
    showDialog(
      context: context,
      builder: (_) => _GoalDialog(provider: provider),
    );
  }

  void _showProgressDialog(BuildContext context, Goal goal) {
    final provider = context.read<FinanceProvider>();
    showDialog(
      context: context,
      builder: (_) => _ProgressDialog(provider: provider, goal: goal),
    );
  }
}

class _GoalDialog extends StatefulWidget {
  final FinanceProvider provider;

  const _GoalDialog({required this.provider});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _iconController;
  late DateTime _deadline;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _amountController = TextEditingController();
    _iconController = TextEditingController(text: '🎯');
    _deadline = DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    final icon = _iconController.text.trim().isEmpty ? '🎯' : _iconController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para la meta.')),
      );
      return;
    }
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto objetivo válido.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.provider.addGoal(
        name: name,
        targetAmount: amount,
        deadline: _deadline,
        icon: icon,
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo crear la meta: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AlertDialog(
      title: const Text('Nueva meta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto objetivo', prefixText: 'Bs '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _iconController,
              decoration: const InputDecoration(labelText: 'Icono'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha límite'),
              subtitle: Text('${_deadline.day}/${_deadline.month}/${_deadline.year}'),
              trailing: const Icon(Icons.date_range),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(now.year, now.month, now.day),
                  lastDate: now.add(const Duration(days: 3650)),
                  initialDate: _deadline.isBefore(now) ? now : _deadline,
                );
                if (picked != null) {
                  setState(() => _deadline = picked);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ProgressDialog extends StatefulWidget {
  final FinanceProvider provider;
  final Goal goal;

  const _ProgressDialog({required this.provider, required this.goal});

  @override
  State<_ProgressDialog> createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  late final TextEditingController _amountController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido para abonar.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.provider.updateGoalProgress(widget.goal, amount);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar la meta: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Abonar a "${widget.goal.name}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _amountController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Monto a abonar',
              prefixText: 'Bs ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyGoals({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.flag_outlined, color: AppTheme.textTertiary, size: 42),
          const SizedBox(height: 12),
          const Text('No hay metas creadas', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Crea una meta para seguir tu ahorro.', style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Nueva meta')),
        ],
      ),
    );
  }
}