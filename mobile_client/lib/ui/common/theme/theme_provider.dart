import 'package:flutter/material.dart';
import 'package:mobile_client/ui/common/theme/app_theme.dart';

/// Провайдер состояния темы приложения
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _isLoading = true;

  /// Конструктор
  ThemeProvider() {
    _loadSavedTheme();
  }

  /// Текущий режим темы (темный/светлый)
  bool get isDarkMode => _isDarkMode;
  
  /// Загружены ли настройки темы
  bool get isLoading => _isLoading;

  /// Загрузка сохраненной темы из хранилища
  Future<void> _loadSavedTheme() async {
    _isLoading = true;
    _isDarkMode = await AppTheme.isDarkMode();
    _isLoading = false;
    notifyListeners();
  }

  /// Переключение между темным и светлым режимами
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await AppTheme.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  /// Установка конкретного режима темы
  Future<void> setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await AppTheme.setDarkMode(_isDarkMode);
    notifyListeners();
  }
} 