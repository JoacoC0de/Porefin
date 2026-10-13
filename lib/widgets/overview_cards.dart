import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import 'summary_card.dart';

class OverviewCards extends StatelessWidget {
  const OverviewCards({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 420 ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

        return Consumer<FinanceProvider>(
          builder: (context, provider, _) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    title: 'Ingresos',
                    amount: provider.formatMoney(provider.totalIncome),
                    icon: Icons.arrow_upward_rounded,
                    accentColor: AppTheme.income,
                    subtitle: 'Periodo',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: SummaryCard(
                    title: 'Gastos',
                    amount: provider.formatMoney(provider.totalExpense),
                    icon: Icons.arrow_downward_rounded,
                    accentColor: AppTheme.expense,
                    subtitle: 'Periodo',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}