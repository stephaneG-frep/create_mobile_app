import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED); // Purple/Violet
  static const Color primaryLight = Color(0xFF9D6BF5);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color secondary = Color(0xFFF59E0B); // Gold
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color background = Color(0xFF0A0A1A); // Deep dark blue-black
  static const Color surface = Color(0xFF12122A);
  static const Color surfaceVariant = Color(0xFF1E1E3A);
  static const Color onSurface = Color(0xFFE8E8FF);
  static const Color onSurfaceMuted = Color(0xFF9090B0);
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color userBubble = Color(0xFF5B21B6);
  static const Color aiBubble = Color(0xFF1E1E3A);
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.black,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
        onError: Colors.white,
        surfaceContainerHighest: AppColors.surfaceVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2A2A4A), width: 1),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A4A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.onSurfaceMuted),
        hintStyle: const TextStyle(color: AppColors.onSurfaceMuted),
        prefixIconColor: AppColors.onSurfaceMuted,
        suffixIconColor: AppColors.onSurfaceMuted,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withOpacity(0.3),
        labelStyle: const TextStyle(color: AppColors.onSurface),
        side: const BorderSide(color: Color(0xFF2A2A4A)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceMuted,
        indicatorColor: AppColors.primary,
        dividerColor: Color(0xFF2A2A4A),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: const TextStyle(color: AppColors.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A2A4A),
        thickness: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 32),
        displayMedium: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 28),
        headlineLarge: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 24),
        headlineMedium: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 20),
        titleLarge: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 18),
        titleMedium: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 16),
        bodyLarge:
            TextStyle(color: AppColors.onSurface, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(
            color: AppColors.onSurfaceMuted, fontSize: 14, height: 1.5),
        labelLarge: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 14),
      ),
    );
  }
}

class ThemeConfig {
  static const List<Map<String, dynamic>> navItems = [
    {'label': 'Projets', 'icon': Icons.folder_outlined, 'activeIcon': Icons.folder},
    {'label': 'Nouveau', 'icon': Icons.add_circle_outline, 'activeIcon': Icons.add_circle},
    {'label': 'Paramètres', 'icon': Icons.settings_outlined, 'activeIcon': Icons.settings},
  ];
}
