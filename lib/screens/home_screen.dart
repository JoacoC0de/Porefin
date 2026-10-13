import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

import '../providers/finance_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/overview_cards.dart';
import '../widgets/quick_add_dialog.dart';
import '../widgets/transaction_card.dart';
import 'goals_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'accounts_screen.dart';
import '../services/notification_service.dart';
import '../services/background_worker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _fabExpanded = false;
  StreamSubscription? _widgetSubscription;

  @override
  void initState() {
    super.initState();
    _checkWidgetLaunch();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    final granted = await NotificationService().requestPermissions();
    if (granted) {
      BackgroundWorker.scheduleDailyReminder();
    }
  }

  void _checkWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then((uri) {
      if (uri != null) _handleWidgetUri(uri);
    });
    _widgetSubscription = HomeWidget.widgetClicked.listen((uri) {
      if (uri != null) _handleWidgetUri(uri);
    });
  }

  void _handleWidgetUri(Uri uri) {
    if (!mounted) return;
    final path = uri.toString();
    if (path.contains('addExpense')) {
      showQuickAddDialog(context, initialType: 'expense');
    } else if (path.contains('addIncome')) {
      showQuickAddDialog(context, initialType: 'income');
    }
  }

  @override
  void dispose() {
    _widgetSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const _DashboardTab(),
      const ReportsScreen(),
      const AccountsScreen(),
      const GoalsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: pages)),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () async {
          setState(() => _fabExpanded = true);
          await showQuickAddDialog(context);
          if (mounted) {
            setState(() => _fabExpanded = false);
          }
        },
        child: AnimatedRotation(
          turns: _fabExpanded ? 0.125 : 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: const Icon(Icons.add, size: 30),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph_outlined), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined), label: 'Cuentas'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes_outlined), label: 'Metas'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                provider.errorMessage!,
                style: const TextStyle(color: AppTheme.expense),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final summaries = provider.last7DaysSummary;
        final maxValue = summaries.fold<double>(0, (max, item) => item.income + item.expense > max ? item.income + item.expense : max).clamp(1, double.infinity);

        return RefreshIndicator(
          onRefresh: provider.refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 110),
            children: [
              const Text(
                'Finanzas Rápidas',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Controla gastos e ingresos en segundos',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 18),
              Text(
                provider.formatMoney(provider.totalBalance),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Balance ${provider.periodLabel(provider.selectedPeriod).toLowerCase()}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const OverviewCards(),
              const SizedBox(height: 18),
              _PeriodFilters(),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historial',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${provider.historyTransactions.length}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (provider.historyTransactions.isEmpty)
                _EmptyState()
              else
                ListView.separated(
                  itemCount: provider.historyTransactions.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final transaction = provider.historyTransactions[index];
                    return Dismissible(
                      key: ValueKey(transaction.id),
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.expense.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 18),
                        child: const Icon(Icons.delete_outline, color: AppTheme.expense),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => provider.deleteTransaction(transaction),
                      child: TransactionCard(
                        transaction: transaction,
                        formatMoney: provider.formatMoney,
                        accountName: provider.accountById(transaction.accountId)?.name,
                      ),
                    );
                  },
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
                      'Últimos 7 días',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 160,
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  if (index < 0 || index >= summaries.length) return const SizedBox.shrink();
                                  final day = summaries[index].day;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      '${day.day}/${day.month}',
                                      style: const TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: summaries.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value.expense);
                              }).toList(),
                              isCurved: true,
                              color: AppTheme.expense,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [AppTheme.expense.withValues(alpha: 0.35), Colors.transparent],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            LineChartBarData(
                              spots: summaries.asMap().entries.map((entry) {
                                return FlSpot(entry.key.toDouble(), entry.value.income);
                              }).toList(),
                              isCurved: true,
                              color: AppTheme.income,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                            ),
                          ],
                          lineTouchData: const LineTouchData(enabled: true),
                          clipData: const FlClipData.all(),
                          maxY: maxValue * 1.2,
                        ),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          labelStyle: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
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
          Icon(Icons.receipt_long_outlined, color: AppTheme.textTertiary, size: 40),
          SizedBox(height: 12),
          Text(
            'Todavía no hay transacciones',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Toca el botón + para registrar tu primer gasto o ingreso.',
            style: TextStyle(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}