import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Адаптивный индикатор загрузки, который адаптируется в зависимости от платформы
class LoadingIndicator extends StatelessWidget {
  /// Цвет индикатора
  final Color? color;
  
  /// Размер индикатора
  final double size;
  
  /// Толщина линии индикатора (только для CircularProgressIndicator)
  final double strokeWidth;
  
  /// Сообщение, отображаемое вместе с индикатором
  final String? message;
  
  /// Признак того, что индикатор отображается поверх содержимого
  final bool isOverlay;
  
  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 4.0,
    this.message,
    this.isOverlay = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final platform = theme.platform;
    final isIOS = platform == TargetPlatform.iOS;
    final indicatorColor = color ?? theme.colorScheme.primary;
    
    Widget indicator;
    
    if (isIOS) {
      indicator = CupertinoActivityIndicator(
        radius: size / 2,
        color: indicatorColor,
      );
    } else {
      indicator = SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: indicatorColor,
        ),
      );
    }
    
    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          indicator,
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    
    return indicator;
  }
}

/// Виджет для отображения индикатора загрузки над контентом
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: backgroundColor ?? Colors.black.withOpacity(0.3),
              child: Center(
                child: LoadingIndicator(
                  isOverlay: true,
                  message: message,
                ),
              ),
            ),
          ),
      ],
    );
  }
} 