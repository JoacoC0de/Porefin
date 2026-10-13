import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../theme/app_theme.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final String Function(double value) formatMoney;
  final String? accountName;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.formatMoney,
    this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = transaction.type == 'income' ? AppTheme.income : AppTheme.expense;
    final dateLabel = DateFormat('dd MMM • HH:mm', 'es').format(transaction.date);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: amountColor.withValues(alpha: 0.16),
          child: Text(transaction.icon, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          transaction.category,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transaction.description != null && transaction.description!.isNotEmpty)
              Text(
                transaction.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            Text(
              accountName == null ? dateLabel : '$dateLabel • 🏦 $accountName',
              style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          '${transaction.type == 'income' ? '+' : '-'}${formatMoney(transaction.amount)}',
          style: TextStyle(
            color: amountColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}