import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/finance_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/background_worker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  
  await NotificationService().init();
  BackgroundWorker.init();
  
  runApp(const FinanzasRapidasApp());
}

class FinanzasRapidasApp extends StatelessWidget {
  const FinanzasRapidasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FinanceProvider()..initDatabase(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Finanzas Rápidas',
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
