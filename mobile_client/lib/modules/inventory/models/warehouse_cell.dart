import 'package:flutter/material.dart';

/// Уровень заполнения ячейки
enum FillingLevel {
  /// Пусто или меньше 25%
  empty,
  
  /// 25-50% заполнения
  low,
  
  /// 50-75% заполнения
  medium,
  
  /// 75-100% заполнения
  high,
}

/// Модель, представляющая ячейку склада
class WarehouseCell {
  /// Уникальный идентификатор ячейки (например, "A1-01")
  final String id;
  
  /// Секция ячейки (например, "A1")
  final String section;
  
  /// Позиция в секции (например, "01")
  final String position;
  
  /// Уровень заполнения ячейки
  final FillingLevel fillingLevel;
  
  /// Список товаров в ячейке
  final List<String> articleIds;
  
  /// Создание ячейки
  const WarehouseCell({
    required this.id,
    required this.section,
    required this.position,
    this.fillingLevel = FillingLevel.empty,
    this.articleIds = const [],
  });
  
  /// Получение цвета в зависимости от уровня заполнения
  Color getFillingColor() {
    switch (fillingLevel) {
      case FillingLevel.empty:
        return Colors.blue;
      case FillingLevel.low:
        return Colors.green;
      case FillingLevel.medium:
        return Colors.yellow;
      case FillingLevel.high:
        return Colors.red;
    }
  }
  
  /// Создание из JSON
  factory WarehouseCell.fromJson(Map<String, dynamic> json) {
    final FillingLevel level;
    
    final fillingPercentage = json['fillingPercentage'] as int? ?? 0;
    if (fillingPercentage < 25) {
      level = FillingLevel.empty;
    } else if (fillingPercentage < 50) {
      level = FillingLevel.low;
    } else if (fillingPercentage < 75) {
      level = FillingLevel.medium;
    } else {
      level = FillingLevel.high;
    }
    
    return WarehouseCell(
      id: json['id'] as String,
      section: json['section'] as String,
      position: json['position'] as String,
      fillingLevel: level,
      articleIds: (json['articleIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }
  
  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    int fillingPercentage;
    
    switch (fillingLevel) {
      case FillingLevel.empty:
        fillingPercentage = 0;
        break;
      case FillingLevel.low:
        fillingPercentage = 30;
        break;
      case FillingLevel.medium:
        fillingPercentage = 60;
        break;
      case FillingLevel.high:
        fillingPercentage = 90;
        break;
    }
    
    return {
      'id': id,
      'section': section,
      'position': position,
      'fillingPercentage': fillingPercentage,
      'articleIds': articleIds,
    };
  }
} 