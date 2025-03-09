import 'package:equatable/equatable.dart';

/// Модель товара в заказе
class OrderItem extends Equatable {
  final String id;
  final String name;
  final String barcode;
  final String imageUrl;
  final double price;
  final int quantity;
  final bool isCollected;
  
  const OrderItem({
    required this.id,
    required this.name,
    required this.barcode,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.isCollected = false,
  });
  
  /// Создание объекта из JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      isCollected: json['isCollected'] as bool? ?? false,
    );
  }
  
  /// Преобразование объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'isCollected': isCollected,
    };
  }
  
  @override
  List<Object?> get props => [id, name, barcode, imageUrl, price, quantity, isCollected];
  
  /// Создание копии объекта с новыми свойствами
  OrderItem copyWith({
    String? id,
    String? name,
    String? barcode,
    String? imageUrl,
    double? price,
    int? quantity,
    bool? isCollected,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      isCollected: isCollected ?? this.isCollected,
    );
  }
} 