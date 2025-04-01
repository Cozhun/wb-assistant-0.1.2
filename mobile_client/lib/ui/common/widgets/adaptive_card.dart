import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Адаптивная карточка, которая корректно отображается на разных платформах
class AdaptiveCard extends StatelessWidget {
  /// Содержимое карточки
  final Widget child;
  
  /// Отступы вокруг карточки
  final EdgeInsetsGeometry? margin;
  
  /// Цвет карточки
  final Color? color;
  
  /// Радиус скругления углов
  final double? borderRadius;
  
  /// Тень карточки
  final double? elevation;
  
  /// Callback при нажатии на карточку
  final VoidCallback? onTap;
  
  const AdaptiveCard({
    super.key,
    required this.child,
    this.margin,
    this.color,
    this.borderRadius,
    this.elevation,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWeb = Theme.of(context).platform == TargetPlatform.macOS || 
                 Theme.of(context).platform == TargetPlatform.windows || 
                 Theme.of(context).platform == TargetPlatform.linux;
    
    final actualElevation = elevation ?? (isWeb ? 1.0 : 2.0);
    final actualBorderRadius = borderRadius ?? (isWeb ? 8.0 : 12.0);
    
    if (onTap != null) {
      return Card(
        margin: margin,
        color: color ?? theme.cardColor,
        elevation: actualElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(actualBorderRadius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(actualBorderRadius),
          child: child,
        ),
      );
    }
    
    return Card(
      margin: margin,
      color: color ?? theme.cardColor,
      elevation: actualElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(actualBorderRadius),
      ),
      child: child,
    );
  }
} 