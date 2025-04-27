import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

/// Ключ для хранения настроек темы
const String _themePreferenceKey = 'theme_preference';

/// Менеджер темы приложения
class AppTheme {
  /// Получение текущей темы приложения
  static ThemeData getTheme(BuildContext context, {bool? isDark}) {
    // Если isDark не передан, используем сохраненное значение из контекста
    isDark ??= _isDarkModeEnabled(context);
    
    final platform = Theme.of(context).platform;
    final isIOS = platform == TargetPlatform.iOS;
    
    // Основные цвета
    final primaryColor = AppColors.primaryColor;
    final accentColor = AppColors.accentColor;
    final errorColor = AppColors.errorColor;
    
    if (isIOS) {
      // iOS-специфичная тема
      return ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: isDark 
            ? CupertinoColors.black
            : CupertinoColors.systemBackground,
        appBarTheme: AppBarTheme(
          backgroundColor: isDark 
              ? CupertinoColors.darkBackgroundGray 
              : CupertinoColors.systemBackground,
          foregroundColor: isDark ? Colors.white : primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        tabBarTheme: TabBarTheme(
          labelColor: isDark ? Colors.white : primaryColor,
          unselectedLabelColor: isDark 
              ? Colors.white.withOpacity(0.7) 
              : Colors.grey.shade600,
          indicator: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: primaryColor,
                width: 2.0,
              ),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: BorderSide(color: primaryColor),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: isDark 
              ? Colors.grey.shade900 
              : Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: isDark 
              ? Colors.grey.shade400 
              : Colors.grey.shade600,
        ),
        brightness: isDark ? Brightness.dark : Brightness.light,
        cardTheme: CardTheme(
          color: AppColors.getCardColor(isDark),
          shadowColor: AppColors.getCardShadowColor(isDark),
          elevation: 2.0,
        ),
        textTheme: _getTextTheme(isDark),
        dividerTheme: DividerThemeData(
          color: AppColors.getDividerColor(isDark),
          thickness: 1.0,
        ),
      );
    }
    
    // Material тема
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: isDark ? Brightness.dark : Brightness.light,
        secondary: accentColor,
        error: errorColor,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.getBackgroundColor(isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? Colors.grey.shade900 : primaryColor,
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor),
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.getCardColor(isDark),
        shadowColor: AppColors.getCardShadowColor(isDark),
        elevation: 2.0,
      ),
      iconTheme: IconThemeData(
        color: AppColors.getIconColor(isDark),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        elevation: 8.0,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: isDark ? Colors.white : primaryColor,
        unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: isDark ? Colors.white : primaryColor,
            width: 2.0,
          ),
        ),
      ),
      textTheme: _getTextTheme(isDark),
      dividerTheme: DividerThemeData(
        color: AppColors.getDividerColor(isDark),
        thickness: 1.0,
      ),
    );
  }
  
  /// Возвращает настроенную текстовую тему в зависимости от режима темы
  static TextTheme _getTextTheme(bool isDark) {
    final baseTextColor = AppColors.getTextColor(isDark);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDark);
    
    return TextTheme(
      displayLarge: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.bold,
      ),
      headlineLarge: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: baseTextColor,
      ),
      bodyMedium: TextStyle(
        color: baseTextColor,
      ),
      bodySmall: TextStyle(
        color: secondaryTextColor,
      ),
      labelLarge: TextStyle(
        color: baseTextColor,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: baseTextColor,
      ),
      labelSmall: TextStyle(
        color: secondaryTextColor,
      ),
    );
  }
  
  /// Проверяет, включен ли темный режим
  static bool _isDarkModeEnabled(BuildContext context) {
    // По умолчанию используем системную настройку
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    final isSystemDarkMode = platformBrightness == Brightness.dark;
    
    // Если есть сохраненное значение, используем его
    final savedMode = _getSavedThemeMode();
    if (savedMode != null) {
      return savedMode == ThemeMode.dark;
    }
    
    // Иначе используем системную настройку
    return isSystemDarkMode;
  }
  
  /// Получает сохраненный режим темы из хранилища
  static ThemeMode? _getSavedThemeMode() {
    final prefs = SharedPreferences.getInstance().then((prefs) {
      final themeString = prefs.getString(_themePreferenceKey);
      if (themeString == 'dark') {
        return ThemeMode.dark;
      } else if (themeString == 'light') {
        return ThemeMode.light;
      }
      return null;
    });
    
    return null; // Возвращаем null, так как метод асинхронный
  }
  
  /// Получает текущее состояние темы из хранилища
  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themePreferenceKey);
    
    if (themeString == 'dark') {
      return true;
    } else if (themeString == 'light') {
      return false;
    }
    
    // По умолчанию используем системную настройку
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }
  
  /// Сохраняет выбранный режим темы
  static Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, isDark ? 'dark' : 'light');
  }
} 