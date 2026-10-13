import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'group.finanzas_rapidas';
  static const String quickActionWidgetProvider = 'QuickActionWidgetProvider';
  static const String balanceWidgetProvider = 'BalanceWidgetProvider';

  static Future<void> updateData({
    required String balance,
    required String income,
    required String expense,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('balance', balance);
      await HomeWidget.saveWidgetData<String>('income', income);
      await HomeWidget.saveWidgetData<String>('expense', expense);

      await HomeWidget.updateWidget(
        name: quickActionWidgetProvider,
        androidName: quickActionWidgetProvider,
      );
      await HomeWidget.updateWidget(
        name: balanceWidgetProvider,
        androidName: balanceWidgetProvider,
      );
    } catch (e) {
      // Ignorar errores si no está soportado en la plataforma actual
    }
  }
}
