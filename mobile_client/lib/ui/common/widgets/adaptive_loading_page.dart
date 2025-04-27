import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_client/ui/common/theme/theme_provider.dart';
import 'adaptive_loading_indicator.dart';

/// Виджет-обертка для отображения загрузки на странице с учетом темы
class AdaptiveLoadingPage extends StatelessWidget {
  /// Показывать ли загрузку
  final bool isLoading;
  
  /// Основное содержимое
  final Widget child;
  
  /// Сообщение для отображения
  final String? message;
  
  /// Размер индикатора загрузки
  final AdaptiveLoadingSize size;
  
  /// Цвет индикатора (если null, используется primaryColor из темы)
  final Color? loadingColor;
  
  /// Непрозрачность затемнения фона
  final double barrierOpacity;
  
  /// Конструктор
  const AdaptiveLoadingPage({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.size = AdaptiveLoadingSize.large,
    this.loadingColor,
    this.barrierOpacity = 0.5,
  });
  
  @override
  Widget build(BuildContext context) {
    // Получаем провайдер темы
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Настройка цветов в зависимости от темы
    final barrierColor = isDarkMode 
        ? Colors.black.withOpacity(barrierOpacity)
        : Colors.grey.shade700.withOpacity(barrierOpacity);
    
    // Цвет контейнера индикатора учитывает тему
    final containerColor = isDarkMode
        ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9)
        : Theme.of(context).scaffoldBackgroundColor;
    
    // Настройка тени в зависимости от темы
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.15);
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Основное содержимое
        child,
        
        // Оверлей загрузки
        if (isLoading)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  // Затемняющий барьер
                  Positioned.fill(
                    child: Container(color: barrierColor),
                  ),
                  
                  // Центрированный индикатор с контейнером
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: shadowColor,
                            blurRadius: isDarkMode ? 16.0 : 12.0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdaptiveLoadingIndicator(
                            size: size,
                            color: loadingColor,
                          ),
                          if (message != null) ...[
                            const SizedBox(height: 16.0),
                            Text(
                              message!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 