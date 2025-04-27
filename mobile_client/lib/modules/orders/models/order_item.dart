import 'package:equatable/equatable.dart';

/// Модель товара в заказе
class OrderItem extends Equatable {
  /// Идентификатор товара
  final String id;
  
  /// Название товара
  final String name;
  
  /// Штрихкод
  final String barcode;
  
  /// Артикул
  final String article;
  
  /// URL изображения товара
  final String imageUrl;
  
  /// Цена за единицу
  final double price;
  
  /// Количество
  final int quantity;
  
  /// Собрано товаров
  final int collectedQuantity;
  
  /// Флаг сбора товара (для совместимости со старым кодом)
  final bool isCollected;
  
  const OrderItem({
    required this.id,
    required this.name,
    required this.barcode,
    this.article = '',
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.collectedQuantity = 0,
    this.isCollected = false,
  });
  
  /// Создание объекта из JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Проверка наличия нового поля collectedQuantity
    final hasCollectedQuantity = json.containsKey('collectedQuantity');
    final bool isItemCollected = json['isCollected'] as bool? ?? false;
    
    return OrderItem(
      id: json['id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      article: json['article'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      // Используем новое поле, если есть, иначе вычисляем из isCollected
      collectedQuantity: hasCollectedQuantity
          ? json['collectedQuantity'] as int
          : (isItemCollected ? (json['quantity'] as int) : 0),
      isCollected: isItemCollected,
    );
  }
  
  /// Преобразование объекта в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'article': article,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'collectedQuantity': collectedQuantity,
      'isCollected': isCollected,
    };
  }
  
  @override
  List<Object?> get props => [
    id, 
    name, 
    barcode, 
    article, 
    imageUrl, 
    price, 
    quantity, 
    collectedQuantity, 
    isCollected
  ];
  
  /// Создание копии объекта с новыми свойствами
  OrderItem copyWith({
    String? id,
    String? name,
    String? barcode,
    String? article,
    String? imageUrl,
    double? price,
    int? quantity,
    int? collectedQuantity,
    bool? isCollected,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      article: article ?? this.article,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      collectedQuantity: collectedQuantity ?? this.collectedQuantity,
      isCollected: isCollected ?? this.isCollected,
    );
  }
  
  /// Полностью ли собран элемент
  bool get isFullyCollected => collectedQuantity >= quantity;
  
  /// Прогресс сборки (от 0.0 до 1.0)
  double get collectionProgress => 
      quantity > 0 ? (collectedQuantity / quantity).clamp(0.0, 1.0) : 0.0;
} 