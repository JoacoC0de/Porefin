import 'package:workmanager/workmanager.dart';
import 'database_service.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'daily_reminder_task') {
      try {
        final dbService = DatabaseService();
        final notifService = NotificationService();
        await notifService.init();

        final transactions = await dbService.getTransactions();
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        
        double todayExpense = 0.0;
        for (var t in transactions) {
          if (t.type == 'expense' && !t.date.isBefore(startOfDay)) {
            todayExpense += t.amount;
          }
        }

        final goals = await dbService.getGoals();
        int pendingGoals = goals.where((g) => !g.isCompleted && g.deadline.isAfter(now)).length;

        final payables = await dbService.getPayables();
        int pendingDebts = payables.where((p) => !p.isPaidOff).length;

        String body = 'Hoy has gastado Bs ${todayExpense.toStringAsFixed(2)}. ';
        if (pendingGoals > 0) body += 'Tienes $pendingGoals meta(s) en progreso. ';
        if (pendingDebts > 0) body += 'Recuerda tus $pendingDebts deuda(s) pendiente(s). ';

        await notifService.showNotification(
          id: 1,
          title: 'Resumen Financiero',
          body: body,
        );
      } catch (e) {
        print("Error en background task: $e");
      }
    }
    return Future.value(true);
  });
}

class BackgroundWorker {
  static void init() {
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  static void scheduleDailyReminder() {
    Workmanager().registerPeriodicTask(
      'daily_reminder_task_id',
      'daily_reminder_task',
      frequency: const Duration(days: 1), // O horas, dependiendo del requerimiento
      initialDelay: const Duration(minutes: 15), // Primer recordatorio en 15 mins o a una hora específica
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
    );
  }

  static void cancelReminders() {
    Workmanager().cancelByUniqueName('daily_reminder_task_id');
  }
}
