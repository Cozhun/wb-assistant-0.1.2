import 'package:equatable/equatable.dart';

/// Константы для статусов заказа
class OrderStatus {
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String impossibleToCollect = 'impossible_to_collect';
  static const String fulfilled = 'fulfilled'; // Списанный ранее невозможный к сборке заказ
  static const String verified = 'verified'; // Товары проверены сканером
  static const String packed = 'packed'; // Заказ упакован
  static const String readyToShip = 'ready_to_ship'; // Заказ готов к отправке
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
}

/// Модель продукта в товаре (компонент товара)
class ProductItem {
  /// Идентификатор продукта
  final String id;
  
  /// Название продукта
  final String name;
  
  /// Штрихкод
  final String barcode;
  
  /// Артикул
  final String article;
  
  /// Количество
  final int quantity;
  
  /// Цена за единицу
  final double price;
  
  /// URL изображения продукта
  final String? imageUrl;
  
  /// Флаг, указывающий, что продукт верифицирован сканером
  final bool isVerified;
  
  /// Флаг, указывающий, что продукт добавлен в заказ
  final bool isPacked;
  
  const ProductItem({
    required this.id,
    required this.name,
    required this.barcode,
    required this.article,
    required this.quantity,
    required this.price,
    this.imageUrl,
    this.isVerified = false,
    this.isPacked = false,
  });
  
  /// Создание из JSON
  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as String,
      name: json['name'] as String,
      barcode: json['barcode'] as String,
      article: json['article'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isPacked: json['isPacked'] as bool? ?? false,
    );
  }
  
  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'article': article,
      'quantity': quantity,
      'price': price,
      'isVerified': isVerified,
      'isPacked': isPacked,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
  
  /// Создание копии с изменением отдельных полей
  ProductItem copyWith({
    String? id,
    String? name,
    String? barcode,
    String? article,
    int? quantity,
    double? price,
    String? imageUrl,
    bool? isVerified,
    bool? isPacked,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      article: article ?? this.article,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
      isPacked: isPacked ?? this.isPacked,
    );
  }
}

/// Модель товара в заказе WB FBS
class OrderItem {
  /// Идентификатор товара
  final String id;
  
  /// Название товара
  final String name;
  
  /// Список продуктов, составляющих товар
  final List<ProductItem> products;
  
  /// Артикул основного товара
  final String article;
  
  /// Штрихкод основного товара
  final String barcode;
  
  /// Общая цена товара
  final double totalPrice;
  
  /// URL изображения товара
  final String? imageUrl;
  
  /// Флаг, указывающий, что все продукты верифицированы
  final bool isVerified;
  
  /// Флаг, указывающий, что товар полностью упакован
  final bool isPacked;
  
  const OrderItem({
    required this.id,
    required this.name,
    required this.products,
    required this.article,
    required this.barcode,
    required this.totalPrice,
    this.imageUrl,
    this.isVerified = false,
    this.isPacked = false,
  });
  
  /// Создание из JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      name: json['name'] as String,
      article: json['article'] as String,
      barcode: json['barcode'] as String,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      products: (json['products'] as List<dynamic>)
          .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isPacked: json['isPacked'] as bool? ?? false,
    );
  }
  
  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'article': article,
      'barcode': barcode,
      'totalPrice': totalPrice,
      'products': products.map((e) => e.toJson()).toList(),
      'isVerified': isVerified,
      'isPacked': isPacked,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
  
  /// Создание копии с изменением отдельных полей
  OrderItem copyWith({
    String? id,
    String? name,
    String? article,
    String? barcode,
    double? totalPrice,
    List<ProductItem>? products,
    String? imageUrl,
    bool? isVerified,
    bool? isPacked,
  }) {
    return OrderItem(
      id: id ?? this.id,
      name: name ?? this.name,
      article: article ?? this.article,
      barcode: barcode ?? this.barcode,
      totalPrice: totalPrice ?? this.totalPrice,
      products: products ?? this.products,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
      isPacked: isPacked ?? this.isPacked,
    );
  }
  
  /// Количество продуктов в товаре
  int get productCount => products.length;
  
  /// Количество верифицированных продуктов
  int get verifiedProductCount => products.where((p) => p.isVerified).length;
  
  /// Количество упакованных продуктов
  int get packedProductCount => products.where((p) => p.isPacked).length;
  
  /// Полностью ли верифицирован товар
  bool get isFullyVerified => verifiedProductCount == productCount;
  
  /// Полностью ли упакован товар
  bool get isFullyPacked => packedProductCount == productCount;
  
  /// Прогресс верификации товара (от 0.0 до 1.0)
  double get verificationProgress => 
      productCount > 0 ? (verifiedProductCount / productCount).clamp(0.0, 1.0) : 0.0;
      
  /// Прогресс упаковки товара (от 0.0 до 1.0)
  double get packingProgress => 
      productCount > 0 ? (packedProductCount / productCount).clamp(0.0, 1.0) : 0.0;
  
  /// Геттер-алиас для isFullyPacked (для обратной совместимости)
  bool get isCollected => isFullyPacked;
  
  /// Геттер для получения общего количества продуктов (для обратной совместимости)
  int get quantity => productCount;
  
  /// Геттер для получения общей цены товара (для обратной совместимости)
  double get price => totalPrice;
}

/// Модель заказа WB FBS
class Order extends Equatable {
  /// Идентификатор заказа
  final String id;
  
  /// Номер заказа в системе WB
  final String wbOrderNumber;
  
  /// Статус заказа
  final String status;
  
  /// Дата создания
  final DateTime createdAt;
  
  /// Срок выполнения
  final DateTime dueDate;
  
  /// Клиент
  final String customer;
  
  /// Адрес доставки
  final String? address;
  
  /// Товар в заказе (в FBS всегда один товар в заказе)
  final OrderItem item;
  
  /// Идентификатор поставки (если заказ добавлен в поставку)
  final String? supplyId;
  
  /// Примечания к заказу
  final String? notes;
  
  /// Ответственный за сборку
  final String? assignedTo;
  
  /// Невозможность сборки, проверено автоматически
  final bool impossibleToCollect;
  
  /// Причина невозможности сборки (если есть)
  final String? impossibilityReason;
  
  /// Дата, когда заказ был отмечен как невозможный для сборки
  final DateTime? impossibilityDate;
  
  /// Этикетка распечатана
  final bool isLabelPrinted;
  
  /// Стикер заказа распечатан
  final bool isOrderStickerPrinted;
  
  /// Максимальное время в часах для сборки невозможного заказа с момента его создания
  static const int maxHoursForCollection = 48;
  
  const Order({
    required this.id,
    required this.wbOrderNumber,
    required this.status,
    required this.createdAt,
    required this.dueDate,
    required this.customer,
    this.address,
    required this.item,
    this.supplyId,
    this.notes,
    this.assignedTo,
    this.impossibleToCollect = false,
    this.impossibilityReason,
    this.impossibilityDate,
    this.isLabelPrinted = false,
    this.isOrderStickerPrinted = false,
  });
  
  /// Создание из JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      wbOrderNumber: json['wbOrderNumber'] as String? ?? 'WB-000000',
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate'] as String) 
          : DateTime.now().add(const Duration(days: 3)),
      customer: json['customer'] as String? ?? 'Неизвестный клиент',
      address: json['address'] as String?,
      item: OrderItem.fromJson(json['item'] as Map<String, dynamic>),
      supplyId: json['supplyId'] as String?,
      notes: json['notes'] as String?,
      assignedTo: json['assignedTo'] as String?,
      impossibleToCollect: json['impossibleToCollect'] as bool? ?? false,
      impossibilityReason: json['impossibilityReason'] as String?,
      impossibilityDate: json['impossibilityDate'] != null 
          ? DateTime.parse(json['impossibilityDate'] as String) 
          : null,
      isLabelPrinted: json['isLabelPrinted'] as bool? ?? false,
      isOrderStickerPrinted: json['isOrderStickerPrinted'] as bool? ?? false,
    );
  }
  
  /// Преобразование в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wbOrderNumber': wbOrderNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'customer': customer,
      if (address != null) 'address': address,
      'item': item.toJson(),
      if (supplyId != null) 'supplyId': supplyId,
      if (notes != null) 'notes': notes,
      if (assignedTo != null) 'assignedTo': assignedTo,
      'impossibleToCollect': impossibleToCollect,
      if (impossibilityReason != null) 'impossibilityReason': impossibilityReason,
      if (impossibilityDate != null) 'impossibilityDate': impossibilityDate!.toIso8601String(),
      'isLabelPrinted': isLabelPrinted,
      'isOrderStickerPrinted': isOrderStickerPrinted,
    };
  }
  
  @override
  List<Object?> get props => [
    id, 
    wbOrderNumber,
    status, 
    createdAt, 
    dueDate, 
    customer, 
    address, 
    item, 
    supplyId, 
    notes, 
    assignedTo,
    impossibleToCollect,
    impossibilityReason,
    impossibilityDate,
    isLabelPrinted,
    isOrderStickerPrinted,
  ];
  
  /// Создание копии с изменением отдельных полей
  Order copyWith({
    String? id,
    String? wbOrderNumber,
    String? status,
    DateTime? createdAt,
    DateTime? dueDate,
    String? customer,
    String? address,
    OrderItem? item,
    String? supplyId,
    String? notes,
    String? assignedTo,
    bool? impossibleToCollect,
    String? impossibilityReason,
    DateTime? impossibilityDate,
    bool? isLabelPrinted,
    bool? isOrderStickerPrinted,
  }) {
    return Order(
      id: id ?? this.id,
      wbOrderNumber: wbOrderNumber ?? this.wbOrderNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      customer: customer ?? this.customer,
      address: address ?? this.address,
      item: item ?? this.item,
      supplyId: supplyId ?? this.supplyId,
      notes: notes ?? this.notes,
      assignedTo: assignedTo ?? this.assignedTo,
      impossibleToCollect: impossibleToCollect ?? this.impossibleToCollect,
      impossibilityReason: impossibilityReason ?? this.impossibilityReason,
      impossibilityDate: impossibilityDate ?? this.impossibilityDate,
      isLabelPrinted: isLabelPrinted ?? this.isLabelPrinted,
      isOrderStickerPrinted: isOrderStickerPrinted ?? this.isOrderStickerPrinted,
    );
  }
  
  /// Проверка, что все продукты верифицированы
  bool get isVerified => item.isFullyVerified;
  
  /// Проверка, что все продукты упакованы
  bool get isPacked => item.isFullyPacked;
  
  /// Прогресс верификации заказа (от 0.0 до 1.0)
  double get verificationProgress => item.verificationProgress;
  
  /// Прогресс упаковки заказа (от 0.0 до 1.0)
  double get packingProgress => item.packingProgress;
  
  /// Можно ли печатать этикетку (если все продукты верифицированы)
  bool get canPrintLabel => isVerified && !isLabelPrinted;
  
  /// Можно ли печатать стикер заказа (если все продукты упакованы)
  bool get canPrintOrderSticker => isPacked && !isOrderStickerPrinted;
  
  /// Заказ готов к отправке
  bool get isReadyToShip => isPacked && isLabelPrinted && isOrderStickerPrinted;
  
  /// Общая стоимость заказа
  double get totalAmount => item.totalPrice;
  
  /// Количество продуктов в заказе
  int get productCount => item.productCount;
  
  /// Геттеры для обратной совместимости
  /// Список товаров для обратной совместимости
  List<OrderItem> get items => [item];
  
  /// Проверка полной сборки заказа
  bool get isFullyCollected => isPacked;
  
  /// Количество собранных товаров
  int get collectedQuantity => isFullyCollected ? 1 : 0;
  
  /// Общее количество товаров
  int get totalQuantity => 1;
  
  /// Прогресс сборки (от 0.0 до 1.0)
  double get collectionProgress => packingProgress;
  
  /// Оставшееся время для сборки невозможного заказа (в часах)
  int get remainingHours {
    if (!impossibleToCollect || impossibilityDate == null) {
      return maxHoursForCollection;
    }
    
    final DateTime now = DateTime.now();
    final DateTime deadline = impossibilityDate!.add(Duration(hours: maxHoursForCollection));
    
    if (now.isAfter(deadline)) {
      return 0;
    }
    
    return deadline.difference(now).inHours + 1;
  }
  
  /// Процент прошедшего времени для сборки невозможного заказа
  double get timeProgressPercentage {
    if (!impossibleToCollect || impossibilityDate == null) {
      return 0.0;
    }
    
    final DateTime now = DateTime.now();
    final Duration elapsed = now.difference(impossibilityDate!);
    final double percentage = (elapsed.inMinutes / (maxHoursForCollection * 60)) * 100;
    
    return percentage.clamp(0.0, 100.0);
  }
  
  /// Проверка, находится ли невозможный заказ в окне сборки
  bool get isWithinCollectionWindow {
    if (!impossibleToCollect || impossibilityDate == null) {
      return false;
    }
    
    final DateTime now = DateTime.now();
    final DateTime deadline = impossibilityDate!.add(Duration(hours: maxHoursForCollection));
    
    return now.isBefore(deadline);
  }
  
  /// Проверка, является ли невозможный заказ просроченным
  bool get isOverdueImpossibleOrder {
    if (!impossibleToCollect || impossibilityDate == null) {
      return false;
    }
    
    final DateTime now = DateTime.now();
    final DateTime deadline = impossibilityDate!.add(Duration(hours: maxHoursForCollection));
    
    return now.isAfter(deadline);
  }
  
  /// Геттер-алиас для свойства impossibleToCollect (для обратной совместимости)
  bool get isImpossibleToCollect => impossibleToCollect;
} 