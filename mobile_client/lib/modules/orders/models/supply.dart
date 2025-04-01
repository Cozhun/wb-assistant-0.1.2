import 'package:flutter/foundation.dart';
import 'order.dart';

/// Статусы поставки
enum SupplyStatus {
  /// В процессе сборки
  collecting,
  
  /// Ожидает отгрузки
  waitingShipment,
  
  /// Отгружена
  shipped,
  
  /// Доставлена
  delivered,
  
  /// Отменена
  cancelled,
}

/// Модель поставки
class Supply {
  /// Уникальный идентификатор поставки
  final String id;
  
  /// Название поставки
  final String name;
  
  /// Описание поставки (опционально)
  final String? description;
  
  /// Статус поставки
  final SupplyStatus status;
  
  /// Дата создания
  final DateTime createdAt;
  
  /// Плановая дата отгрузки
  final DateTime shipmentDate;
  
  /// Список заказов в поставке
  final List<Order> orders;
  
  /// Прогресс сборки (от 0.0 до 1.0)
  final double progress;
  
  /// Общее количество заказов
  final int totalOrders;
  
  /// Количество собранных заказов
  final int completedOrders;
  
  /// ID сотрудника, назначенного на сборку поставки (опционально)
  final String? assignedTo;
  
  const Supply({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.createdAt,
    required this.shipmentDate,
    required this.orders,
    required this.progress,
    required this.totalOrders,
    required this.completedOrders,
    this.assignedTo,
  });
  
  /// Создание копии объекта с возможностью изменения отдельных полей
  Supply copyWith({
    String? id,
    String? name,
    String? description,
    SupplyStatus? status,
    DateTime? createdAt,
    DateTime? shipmentDate,
    List<Order>? orders,
    double? progress,
    int? totalOrders,
    int? completedOrders,
    String? assignedTo,
  }) {
    return Supply(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      shipmentDate: shipmentDate ?? this.shipmentDate,
      orders: orders ?? this.orders,
      progress: progress ?? this.progress,
      totalOrders: totalOrders ?? this.totalOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
  
  /// Создание объекта из JSON
  factory Supply.fromJson(Map<String, dynamic> json) {
    return Supply(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: _statusFromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      shipmentDate: DateTime.parse(json['shipmentDate'] as String),
      orders: (json['orders'] as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      progress: json['progress'] as double,
      totalOrders: json['totalOrders'] as int,
      completedOrders: json['completedOrders'] as int,
      assignedTo: json['assignedTo'] as String?,
    );
  }
  
  /// Преобразование объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'status': _statusToString(status),
      'createdAt': createdAt.toIso8601String(),
      'shipmentDate': shipmentDate.toIso8601String(),
      'orders': orders.map((e) => e.toJson()).toList(),
      'progress': progress,
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      if (assignedTo != null) 'assignedTo': assignedTo,
    };
  }
  
  /// Преобразование строки в статус поставки
  static SupplyStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'collecting':
        return SupplyStatus.collecting;
      case 'waitingshipment':
      case 'waiting_shipment':
        return SupplyStatus.waitingShipment;
      case 'shipped':
        return SupplyStatus.shipped;
      case 'delivered':
        return SupplyStatus.delivered;
      case 'cancelled':
        return SupplyStatus.cancelled;
      default:
        return SupplyStatus.collecting;
    }
  }
  
  /// Преобразование статуса поставки в строку
  static String _statusToString(SupplyStatus status) {
    switch (status) {
      case SupplyStatus.collecting:
        return 'collecting';
      case SupplyStatus.waitingShipment:
        return 'waiting_shipment';
      case SupplyStatus.shipped:
        return 'shipped';
      case SupplyStatus.delivered:
        return 'delivered';
      case SupplyStatus.cancelled:
        return 'cancelled';
    }
  }
  
  /// Проверяет, просрочена ли поставка
  bool get isOverdue => status != SupplyStatus.delivered && 
                        status != SupplyStatus.cancelled && 
                        shipmentDate.isBefore(DateTime.now());
  
  /// Проверяет, запланирована ли поставка на сегодня
  bool get isToday {
    final now = DateTime.now();
    return shipmentDate.year == now.year && 
           shipmentDate.month == now.month && 
           shipmentDate.day == now.day;
  }
  
  /// Проверяет, запланирована ли поставка на завтра
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return shipmentDate.year == tomorrow.year && 
           shipmentDate.month == tomorrow.month && 
           shipmentDate.day == tomorrow.day;
  }
  
  /// Проверяет, активна ли поставка (не доставлена и не отменена)
  bool get isActive => status != SupplyStatus.delivered && 
                      status != SupplyStatus.cancelled;
} 