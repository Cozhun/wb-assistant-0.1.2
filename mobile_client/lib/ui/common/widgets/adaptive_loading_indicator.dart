import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

enum AdaptiveLoadingSize {
  small,
  medium,
  large,
}

class AdaptiveLoadingIndicator extends StatelessWidget {
  final AdaptiveLoadingSize size;
  final Color? color;
  final String? label;
  final TextStyle? labelStyle;
  final double? value;
  
  const AdaptiveLoadingIndicator({
    Key? key,
    this.size = AdaptiveLoadingSize.medium,
    this.color,
    this.label,
    this.labelStyle,
    this.value,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final themeColor = color ?? Theme.of(context).primaryColor;
    
    // Определяем размер в зависимости от платформы и указанного размера
    double indicatorSize;
    if (platform == TargetPlatform.iOS) {
      switch (size) {
        case AdaptiveLoadingSize.small:
          indicatorSize = 16.0;
          break;
        case AdaptiveLoadingSize.medium:
          indicatorSize = 30.0;
          break;
        case AdaptiveLoadingSize.large:
          indicatorSize = 45.0;
          break;
      }
    } else {
      switch (size) {
        case AdaptiveLoadingSize.small:
          indicatorSize = 18.0;
          break;
        case AdaptiveLoadingSize.medium:
          indicatorSize = 36.0;
          break;
        case AdaptiveLoadingSize.large:
          indicatorSize = 56.0;
          break;
      }
    }
    
    // Создаем соответствующий индикатор в зависимости от платформы
    Widget indicator;
    if (platform == TargetPlatform.iOS) {
      indicator = CupertinoActivityIndicator(
        radius: indicatorSize / 2,
        color: color,
      );
    } else {
      if (value != null) {
        indicator = SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            value: value,
            color: themeColor,
            strokeWidth: size == AdaptiveLoadingSize.small ? 2.0 : 4.0,
          ),
        );
      } else {
        indicator = SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: CircularProgressIndicator(
            color: themeColor,
            strokeWidth: size == AdaptiveLoadingSize.small ? 2.0 : 4.0,
          ),
        );
      }
    }
    
    // Если указан текст, добавляем его под индикатором
    if (label != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          indicator,
          const SizedBox(height: 12.0),
          Text(
            label!,
            style: labelStyle ?? 
                (platform == TargetPlatform.iOS
                    ? const TextStyle(fontSize: 14.0)
                    : Theme.of(context).textTheme.bodyMedium),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    
    return indicator;
  }
}

/// Центрированный индикатор загрузки, занимающий все доступное пространство
class CenteredLoadingIndicator extends StatelessWidget {
  final String? label;
  final Color? color;
  final AdaptiveLoadingSize size;
  
  const CenteredLoadingIndicator({
    Key? key,
    this.label,
    this.color,
    this.size = AdaptiveLoadingSize.medium,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AdaptiveLoadingIndicator(
        size: size,
        color: color,
        label: label,
      ),
    );
  }
} 