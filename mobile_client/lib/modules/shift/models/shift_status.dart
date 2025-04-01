import 'package:flutter/foundation.dart';

/// Модель статуса смены
class ShiftStatus {
  /// Идентификатор смены
  final String? id;
  
  /// Флаг активности смены
  final bool isActive;
  
  /// Время начала смены
  final DateTime? startTime;
  
  /// Время окончания смены
  final DateTime? endTime;
  
  /// Количество собранных заказов
  final int completedOrders;
  
  /// Общее время смены в минутах
  int get totalMinutes {
    if (startTime == null) return 0;
    if (isActive) {
      return DateTime.now().difference(startTime!).inMinutes;
    } else if (endTime != null) {
      return endTime!.difference(startTime!).inMinutes;
    }
    return 0;
  }
  
  /// Форматированное время смены
  String get formattedDuration {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}ч ${minutes}м';
  }
  
  const ShiftStatus({
    this.id,
    this.isActive = false,
    this.startTime,
    this.endTime,
    this.completedOrders = 0,
  });
  
  /// Создание начальной смены
  factory ShiftStatus.initial() {
    return const ShiftStatus();
  }
  
  /// Создание активной смены
  factory ShiftStatus.active() {
    return ShiftStatus(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isActive: true,
      startTime: DateTime.now(),
      completedOrders: 0,
    );
  }
  
  /// Создание завершенной смены
  factory ShiftStatus.completed(ShiftStatus current) {
    return ShiftStatus(
      id: current.id,
      isActive: false,
      startTime: current.startTime,
      endTime: DateTime.now(),
      completedOrders: current.completedOrders,
    );
  }
  
  /// Копирование с заменой некоторых полей
  ShiftStatus copyWith({
    String? id,
    bool? isActive,
    DateTime? startTime,
    DateTime? endTime,
    int? completedOrders,
  }) {
    return ShiftStatus(
      id: id ?? this.id,
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      completedOrders: completedOrders ?? this.completedOrders,
    );
  }
  
  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isActive': isActive,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'completedOrders': completedOrders,
    };
  }
  
  /// Создание из JSON
  factory ShiftStatus.fromJson(Map<String, dynamic> json) {
    return ShiftStatus(
      id: json['id'] as String?,
      isActive: json['isActive'] as bool,
      startTime: json['startTime'] != null 
          ? DateTime.parse(json['startTime'] as String) 
          : null,
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime'] as String)
          : null,
      completedOrders: json['completedOrders'] as int,
    );
  }
  
  @override
  String toString() {
    return 'ShiftStatus(id: $id, isActive: $isActive, startTime: $startTime, endTime: $endTime, completedOrders: $completedOrders)';
  }
} 