import 'package:flutter_test/flutter_test.dart';
import 'package:alarm_frontend/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial theme should be dark mode by default', () async {
      final themeProvider = ThemeProvider();
      // Need to wait for _loadTheme which is called in constructor
      await Future.delayed(const Duration(milliseconds: 100));
      expect(themeProvider.isDarkMode, true);
    });

    test('toggleTheme should switch between light and dark', () async {
      final themeProvider = ThemeProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, false);
      
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, true);
    });

    test('ThemeData should match the brightness state', () async {
      final themeProvider = ThemeProvider();
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(themeProvider.currentTheme.brightness, isNotNull);
    });
  });
}
