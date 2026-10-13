import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import 'category_button.dart';

Future<void> showQuickAddDialog(BuildContext context, {String initialType = 'expense'}) {
  final provider = context.read<FinanceProvider>();
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _QuickAddDialog(provider: provider, initialType: initialType),
  );
}

class _QuickAddDialog extends StatefulWidget {
  final FinanceProvider provider;
  final String initialType;

  const _QuickAddDialog({required this.provider, this.initialType = 'expense'});

  @override
  State<_QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<_QuickAddDialog> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late String _type;
  String? _selectedCategoryId;
  String? _selectedAccountId;

  FinanceProvider get _provider => widget.provider;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedAccountId = _provider.defaultAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Category> _categoriesForType() {
    return _provider.categories.where((category) => category.type == _type).toList();
  }

  void _syncSelectedCategory(List<Category> categories) {
    if (categories.isEmpty) {
      _selectedCategoryId = null;
      return;
    }

    final exists = categories.any((category) => category.id == _selectedCategoryId);
    if (!exists) {
      _selectedCategoryId = categories.first.id;
    }
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    final categories = _categoriesForType();
    _syncSelectedCategory(categories);
    if (_selectedCategoryId == null) return;

    final selectedCategory = categories.firstWhere(
      (category) => category.id == _selectedCategoryId,
      orElse: () => categories.first,
    );

    await _provider.addTransaction(
      amount: amount,
      type: _type,
      category: selectedCategory,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      accountId: _selectedAccountId,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _accountChip({required String? id, required String label}) {
    final selected = _selectedAccountId == id;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedAccountId = id),
      selectedColor: AppTheme.primary.withValues(alpha: 0.22),
      labelStyle: TextStyle(
        color: selected ? AppTheme.primary : AppTheme.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categoriesForType();
    _syncSelectedCategory(categories);
    final hasCategories = categories.isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nueva transacción',
                        style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: AppTheme.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Registra un gasto o ingreso sin salir de la vista actual.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ChoiceChip(
                              label: const Text('Gasto'),
                              selected: _type == 'expense',
                              onSelected: (_) {
                                setState(() {
                                  _type = 'expense';
                                  _selectedCategoryId = null;
                                });
                              },
                              selectedColor: AppTheme.expense.withValues(alpha: 0.18),
                              labelStyle: TextStyle(
                                color: _type == 'expense' ? AppTheme.expense : AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                              side: BorderSide(color: _type == 'expense' ? AppTheme.expense : AppTheme.border),
                            ),
                            ChoiceChip(
                              label: const Text('Ingreso'),
                              selected: _type == 'income',
                              onSelected: (_) {
                                setState(() {
                                  _type = 'income';
                                  _selectedCategoryId = null;
                                });
                              },
                              selectedColor: AppTheme.income.withValues(alpha: 0.18),
                              labelStyle: TextStyle(
                                color: _type == 'income' ? AppTheme.income : AppTheme.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                              side: BorderSide(color: _type == 'income' ? AppTheme.income : AppTheme.border),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _amountController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Monto',
                            prefixText: 'Bs ',
                            hintText: '0.00',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [10, 20, 50, 100, 200].map((preset) {
                            return ActionChip(
                              label: Text('+$preset'),
                              backgroundColor: AppTheme.surface,
                              side: const BorderSide(color: AppTheme.border),
                              labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                              onPressed: () {
                                final current = double.tryParse(_amountController.text) ?? 0;
                                _amountController.text = (current + preset).toStringAsFixed(0);
                              },
                            );
                          }).toList(),
                        ),
                        if (_provider.bankAccounts.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            _type == 'expense' ? 'Debitar de la cuenta' : 'Depositar en la cuenta',
                            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ..._provider.bankAccounts.map((account) => _accountChip(
                                    id: account.id,
                                    label: '${account.icon} ${account.name} · ${_provider.formatMoney(_provider.accountBalance(account))}',
                                  )),
                              _accountChip(id: null, label: 'Sin cuenta'),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        TextField(
                          controller: _descriptionController,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            hintText: 'Opcional',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Categoría',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        hasCategories
                            ? GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 120,
                                  mainAxisExtent: 98,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final selected = category.id == _selectedCategoryId;
                                  return CategoryButton(
                                    category: category,
                                    selected: selected,
                                    onTap: () => setState(() => _selectedCategoryId = category.id),
                                  );
                                },
                              )
                            : const Center(
                                child: Text(
                                  'No hay categorías disponibles para este tipo.',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: hasCategories ? () => _save() : null,
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
