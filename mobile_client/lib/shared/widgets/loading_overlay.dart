import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../ui/common/theme/theme_provider.dart';
import 'loading_indicator.dart';

/// Виджет-оверлей для отображения индикатора загрузки
/// с поддержкой темной темы
class AdaptiveLoadingOverlay extends StatelessWidget {
  /// Показывать ли загрузку
  final bool isLoading;
  
  /// Основное содержимое
  final Widget child;
  
  /// Сообщение для отображения
  final String? message;
  
  /// Размер индикатора
  final double size;
  
  /// Цвет индикатора
  final Color? color;
  
  /// Цвет фона
  final Color? backgroundColor;
  
  /// Конструктор
  const AdaptiveLoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.message,
    this.size = 36.0,
    this.color,
    this.backgroundColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Проверяем доступность провайдера темы
    final hasThemeProvider = context.findAncestorWidgetOfExactType<Provider<ThemeProvider>>() != null;
    
    // Если провайдер темы доступен, используем его
    if (hasThemeProvider) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      final isDarkMode = themeProvider.isDarkMode;
      
      // Определяем цвета в зависимости от темы
      final barrierColor = backgroundColor ?? 
          (isDarkMode 
              ? Colors.black.withOpacity(0.5) 
              : Colors.black.withOpacity(0.3));
      
      return Stack(
        children: [
          child,
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: barrierColor,
                child: Center(
                  child: LoadingIndicator(
                    size: size,
                    color: color,
                    message: message,
                    isOverlay: true,
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      // Используем стандартный оверлей, если провайдер темы недоступен
      return Stack(
        children: [
          child,
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: backgroundColor ?? Colors.black.withOpacity(0.3),
                child: Center(
                  child: LoadingIndicator(
                    size: size,
                    color: color,
                    message: message,
                    isOverlay: true,
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }
} 