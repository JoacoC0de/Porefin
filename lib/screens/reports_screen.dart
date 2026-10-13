import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final topCategories = provider.topExpenseCategories;
        final expenseMap = provider.expenseByCategoryMonth;
        final categories = expenseMap.entries.toList()..sort((left, right) => right.value.compareTo(left.value));
        final totalExpense = provider.monthExpense;
        final chartSections = categories.map((entry) {
          final percentage = totalExpense == 0 ? 0 : (entry.value / totalExpense) * 100;
          return PieChartSectionData(
            value: entry.value,
            title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
            color: AppTheme.categoryColor(entry.key),
            radius: 70,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
          );
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
          children: [
            const Text(
              'Reportes',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Distribución de gastos y comparación de ingresos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            _PeriodFilters(),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen de Cuentas',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _AccountSummaryBox(
                          title: 'Por Cobrar',
                          amount: provider.totalReceivables,
                          color: Colors.green,
                          icon: Icons.call_received,
                          provider: provider,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccountSummaryBox(
                          title: 'Por Pagar',
                          amount: provider.totalPayables,
                          color: Colors.redAccent,
                          icon: Icons.call_made,
                          provider: provider,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gastos por categoría',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 240,
                    child: totalExpense == 0
                        ? const Center(child: Text('Sin gastos para mostrar', style: TextStyle(color: AppTheme.textSecondary)))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 45,
                              sections: chartSections,
                              pieTouchData: PieTouchData(enabled: true),
                            ),
                            swapAnimationDuration: const Duration(seconds: 1),
                            swapAnimationCurve: Curves.easeInOut,
                          ),
                  ),
                  const SizedBox(height: 10),
                  ...categories.take(5).map((entry) {
                    final percentage = totalExpense == 0 ? 0 : (entry.value / totalExpense) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.categoryColor(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(entry.key, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingresos vs gastos',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 260,
                    child: BarChart(
                      BarChartData(
                        maxY: [provider.monthIncome, provider.monthExpense].reduce((a, b) => a > b ? a : b) * 1.2 + 1,
                        alignment: BarChartAlignment.spaceAround,
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: provider.monthIncome,
                                width: 28,
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.income,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: provider.monthExpense,
                                width: 28,
                                borderRadius: BorderRadius.circular(8),
                                color: AppTheme.expense,
                              ),
                            ],
                          ),
                        ],
                      ),
                      swapAnimationDuration: const Duration(seconds: 1),
                      swapAnimationCurve: Curves.easeInOut,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LegendDot(color: AppTheme.income, label: 'Ingresos'),
                      _LegendDot(color: AppTheme.expense, label: 'Gastos'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top 5 categorías de gasto',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  if (topCategories.isEmpty)
                    const Text('Aún no hay datos', style: TextStyle(color: AppTheme.textSecondary))
                  else
                    ...topCategories.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppTheme.categoryColor(item.category).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(item.icon, style: const TextStyle(fontSize: 18)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.category, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                                  Text('${item.percentage.toStringAsFixed(1)}%', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              provider.formatMoney(item.amount),
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PeriodFilters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinanceProvider>();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: TimePeriod.values.map((period) {
        final selected = provider.selectedPeriod == period;
        return ChoiceChip(
          label: Text(provider.periodLabel(period)),
          selected: selected,
          onSelected: (_) async {
            if (period == TimePeriod.custom) {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDateRange: provider.customStartDate != null && provider.customEndDate != null
                    ? DateTimeRange(start: provider.customStartDate!, end: provider.customEndDate!)
                    : null,
              );
              if (picked != null) {
                provider.setCustomPeriod(picked.start, picked.end);
              }
            } else {
              provider.setSelectedPeriod(period);
            }
          },
          selectedColor: AppTheme.primary.withValues(alpha: 0.22),
          labelStyle: TextStyle(color: selected ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w700),
          side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
        );
      }).toList(),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _AccountSummaryBox extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;
  final FinanceProvider provider;

  const _AccountSummaryBox({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            provider.formatMoney(amount),
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}