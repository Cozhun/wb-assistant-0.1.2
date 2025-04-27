import 'package:flutter/material.dart';

/// Константы цветов приложения с поддержкой темной темы
class AppColors {
  // Основные цвета
  static const primaryColor = Colors.blue;
  static const accentColor = Colors.amber;
  static const successColor = Colors.green;
  static const errorColor = Colors.red;
  static const warningColor = Colors.orange;
  
  // Получение цвета в зависимости от темы
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF121212) : Colors.white;
  }
  
  static Color getCardColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  }
  
  static Color getDividerColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF3D3D3D) : const Color(0xFFE0E0E0);
  }
  
  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : Colors.black87;
  }
  
  static Color getSecondaryTextColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFFB0B0B0) : const Color(0xFF757575);
  }
  
  static Color getIconColor(bool isDarkMode) {
    return isDarkMode ? Colors.white : const Color(0xFF616161);
  }
  
  // Цвета для статусов поставок
  static Color getCompletedStatusColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFF388E3C) : Colors.green;
  }
  
  static Color getPendingStatusColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFFFFA000) : Colors.amber;
  }
  
  static Color getCancelledStatusColor(bool isDarkMode) {
    return isDarkMode ? const Color(0xFFD32F2F) : Colors.red;
  }
  
  // Цвета для шаблонов карточек
  static Color getCardShadowColor(bool isDarkMode) {
    return isDarkMode 
        ? Colors.black.withOpacity(0.6) 
        : Colors.black.withOpacity(0.1);
  }
  
  static List<Color> getGradientColors(bool isDarkMode) {
    return isDarkMode 
        ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
        : [const Color(0xFF1565C0), const Color(0xFF1976D2)];
  }
  
  // Цвета для диаграмм
  static List<Color> getChartColors(bool isDarkMode) {
    return isDarkMode 
        ? [
            const Color(0xFF26A69A),
            const Color(0xFF5C6BC0),
            const Color(0xFFFFB74D),
            const Color(0xFFEF5350),
            const Color(0xFF66BB6A),
            const Color(0xFF42A5F5),
          ]
        : [
            const Color(0xFF00897B),
            const Color(0xFF3949AB),
            const Color(0xFFFFA000),
            const Color(0xFFE53935),
            const Color(0xFF43A047),
            const Color(0xFF1E88E5),
          ];
  }
} 