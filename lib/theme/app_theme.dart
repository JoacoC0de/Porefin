import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color card = Color(0xFF252525);
  static const Color border = Color(0xFF3A3A3A);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textTertiary = Color(0xFF808080);

  static const Color primary = Color(0xFF7C4DFF);
  static const Color primaryVariant = Color(0xFF651FFF);
  static const Color income = Color(0xFF00E676);
  static const Color expense = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB300);
  static const Color info = Color(0xFF40C4FF);

  static const Map<String, Color> categoryColors = {
    'Comida': Color(0xFFFF6D00),
    'Transporte': Color(0xFFFF1744),
    'Entretenimiento': Color(0xFFE040FB),
    'Servicios': Color(0xFF00E5FF),
    'Salud': Color(0xFF76FF03),
    'Educación': Color(0xFFFFEA00),
    'Ropa': Color(0xFFFF4081),
    'Hogar': Color(0xFF18FFFF),
    'Café': Color(0xFFD2691E),
    'Compras': Color(0xFFD500F9),
    'Salario': Color(0xFF00E676),
    'Freelance': Color(0xFF69F0AE),
    'Inversiones': Color(0xFF1DE9B6),
    'Regalos': Color(0xFFB2FF59),
    'Otros Ingresos': Color(0xFF64FFDA),
    'Otros': Color(0xFF64FFDA),
  };

  static const Map<String, String> categoryIcons = {
    'Comida': '🍔',
    'Transporte': '🚗',
    'Entretenimiento': '🎮',
    'Servicios': '💡',
    'Salud': '💊',
    'Educación': '📚',
    'Ropa': '👕',
    'Hogar': '🏠',
    'Café': '☕',
    'Compras': '🛒',
    'Salario': '💼',
    'Freelance': '💻',
    'Inversiones': '📈',
    'Regalos': '🎁',
    'Otros Ingresos': '💰',
    'Otros': '💰',
  };

  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Comida', 'icon': '🍔', 'color': '#FF6D00', 'type': 'expense', 'sort': 1},
    {'name': 'Transporte', 'icon': '🚗', 'color': '#FF1744', 'type': 'expense', 'sort': 2},
    {'name': 'Café', 'icon': '☕', 'color': '#D2691E', 'type': 'expense', 'sort': 3},
    {'name': 'Servicios', 'icon': '💡', 'color': '#00E5FF', 'type': 'expense', 'sort': 4},
    {'name': 'Entretenimiento', 'icon': '🎮', 'color': '#E040FB', 'type': 'expense', 'sort': 5},
    {'name': 'Salud', 'icon': '💊', 'color': '#76FF03', 'type': 'expense', 'sort': 6},
    {'name': 'Educación', 'icon': '📚', 'color': '#FFEA00', 'type': 'expense', 'sort': 7},
    {'name': 'Ropa', 'icon': '👕', 'color': '#FF4081', 'type': 'expense', 'sort': 8},
    {'name': 'Hogar', 'icon': '🏠', 'color': '#18FFFF', 'type': 'expense', 'sort': 9},
    {'name': 'Compras', 'icon': '🛒', 'color': '#D500F9', 'type': 'expense', 'sort': 10},
    {'name': 'Otros', 'icon': '💰', 'color': '#64FFDA', 'type': 'expense', 'sort': 11},
    {'name': 'Salario', 'icon': '💼', 'color': '#00E676', 'type': 'income', 'sort': 12},
    {'name': 'Freelance', 'icon': '💻', 'color': '#69F0AE', 'type': 'income', 'sort': 13},
    {'name': 'Inversiones', 'icon': '📈', 'color': '#1DE9B6', 'type': 'income', 'sort': 14},
    {'name': 'Regalos', 'icon': '🎁', 'color': '#B2FF59', 'type': 'income', 'sort': 15},
    {'name': 'Otros Ingresos', 'icon': '💰', 'color': '#64FFDA', 'type': 'income', 'sort': 16},
  ];

  static Color colorFromHex(String hex) {
    final value = hex.replaceAll('#', '');
    final normalized = value.length == 6 ? 'FF$value' : value;
    return Color(int.parse(normalized, radix: 16));
  }

  static String hexFromColor(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Color categoryColor(String name) {
    return categoryColors[name] ?? primary;
  }

  static String categoryIcon(String name) {
    return categoryIcons[name] ?? '💰';
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        brightness: Brightness.dark,
        primary: primary,
        secondary: info,
        surface: surface,
        error: expense,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: textTertiary),
        labelStyle: const TextStyle(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      dividerColor: border,
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}