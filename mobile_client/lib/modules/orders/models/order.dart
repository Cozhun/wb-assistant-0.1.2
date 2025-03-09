import 'package:equatable/equatable.dart';
import 'order_item.dart';

/// Модель заказа
class Order extends Equatable {
  final String id;
  final String status;
  final DateTime createdAt;
  final List<OrderItem> items;
  
  const Order({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.items,
  });
  
  /// Создание объекта из JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
  
  /// Преобразование объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
  
  /// Подсчет общей стоимости заказа
  double get totalAmount {
    return items.fold(0, (total, item) => total + (item.price * item.quantity));
  }
  
  /// Подсчет общего количества товаров
  int get totalQuantity {
    return items.fold(0, (total, item) => total + item.quantity);
  }
  
  /// Подсчет собранных товаров
  int get collectedQuantity {
    return items.fold(0, (total, item) => total + (item.isCollected ? item.quantity : 0));
  }
  
  /// Проверка, что заказ полностью собран
  bool get isFullyCollected {
    return collectedQuantity == totalQuantity;
  }
  
  /// Получение прогресса сборки (от 0 до 1)
  double get collectionProgress {
    if (totalQuantity == 0) return 0;
    return collectedQuantity / totalQuantity;
  }
  
  @override
  List<Object?> get props => [id, status, createdAt, items];
  
  /// Создание копии объекта с новыми свойствами
  Order copyWith({
    String? id,
    String? status,
    DateTime? createdAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
  
  /// Создание нового заказа с обновленным статусом товара
  Order updateItemCollectionStatus(String itemId, bool isCollected) {
    final updatedItems = items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCollected: isCollected);
      }
      return item;
    }).toList();
    
    return copyWith(items: updatedItems);
  }
} 