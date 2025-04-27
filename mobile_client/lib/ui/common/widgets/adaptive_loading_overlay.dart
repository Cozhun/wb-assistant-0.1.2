import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_client/ui/common/theme/theme_provider.dart';
import 'adaptive_loading_indicator.dart';

/// Виджет-оверлей для отображения загрузки поверх содержимого с учетом темы
class AdaptiveLoadingOverlay extends StatelessWidget {
  /// Показывать ли индикатор загрузки
  final bool isLoading;
  
  /// Основное содержимое
  final Widget child;
  
  /// Сообщение для отображения во время загрузки
  final String? message;
  
  /// Размер индикатора загрузки
  final AdaptiveLoadingSize size;
  
  /// Цвет индикатора (если null, используется primaryColor из темы)
  final Color? loadingColor;
  
  /// Конструктор
  const AdaptiveLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.size = AdaptiveLoadingSize.medium,
    this.loadingColor,
  });
  
  @override
  Widget build(BuildContext context) {
    // Получаем провайдер темы
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Stack(
      children: [
        // Основное содержимое
        child,
        
        // Индикатор загрузки
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AdaptiveLoadingIndicator(
                      size: size,
                      color: loadingColor,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 12.0),
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
          ),
      ],
    );
  }
} 