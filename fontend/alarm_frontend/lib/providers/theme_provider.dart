import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = "isDarkMode";
  bool _isDarkMode = true; // default to dark mode

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme {
    return _isDarkMode ? _darkTheme : _lightTheme;
  }

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    cardColor: AppColors.card,
    dividerColor: AppColors.border,
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.primary,
      surface: AppColors.card,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    ),
  );

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: const Color(0xFFF9FAFB),
    cardColor: Colors.white,
    dividerColor: const Color(0xFFE5E7EB),
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.primary,
      surface: Colors.white,
      onSurface: const Color(0xFF111827),
      outline: const Color(0xFFD1D5DB),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF9FAFB),
      foregroundColor: Color(0xFF111827),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Color(0xFF111827),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFF111827), fontSize: 16),
      bodyMedium: TextStyle(color: Color(0xFF374151), fontSize: 14),
      bodySmall: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
      labelLarge: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
    ),
  );
}
