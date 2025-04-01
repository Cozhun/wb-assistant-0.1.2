/// Модель элемента инвентаризации
class InventoryItem {
  /// Идентификатор элемента инвентаризации
  final String id;
  
  /// Артикул товара
  final String sku;
  
  /// Название товара
  final String name;
  
  /// Изображение товара (URL)
  final String? imageUrl;
  
  /// Штрих-код товара
  final String barcode;
  
  /// Ячейка хранения
  final String cellCode;
  
  /// Количество по системе
  final int systemQuantity;
  
  /// Фактическое количество
  final int? actualQuantity;
  
  /// Статус инвентаризации элемента
  InventoryStatus status;
  
  /// Комментарий при расхождении
  String? discrepancyComment;
  
  /// Создает элемент инвентаризации
  InventoryItem({
    required this.id,
    required this.sku,
    required this.name,
    this.imageUrl,
    required this.barcode,
    required this.cellCode,
    required this.systemQuantity,
    this.actualQuantity,
    this.status = InventoryStatus.pending,
    this.discrepancyComment,
  });
  
  /// Геттер для артикула (для совместимости с новым кодом)
  String get articleId => sku;
  
  /// Геттер для ячейки (для совместимости с новым кодом)
  String get cellId => cellCode;
  
  /// Геттер для ожидаемого количества (для совместимости с новым кодом)
  int get expectedQuantity => systemQuantity;
  
  /// Проверка завершенности инвентаризации элемента
  bool get isCompleted => status == InventoryStatus.completed || status == InventoryStatus.discrepancy;
  
  /// Проверка наличия расхождений
  bool get hasDiscrepancy => 
      actualQuantity != null && actualQuantity != systemQuantity;
  
  /// Создает копию с обновленными полями
  InventoryItem copyWith({
    String? id,
    String? sku,
    String? name,
    String? imageUrl,
    String? barcode,
    String? cellCode,
    int? systemQuantity,
    int? actualQuantity,
    InventoryStatus? status,
    String? discrepancyComment,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
      cellCode: cellCode ?? this.cellCode,
      systemQuantity: systemQuantity ?? this.systemQuantity,
      actualQuantity: actualQuantity ?? this.actualQuantity,
      status: status ?? this.status,
      discrepancyComment: discrepancyComment ?? this.discrepancyComment,
    );
  }
  
  /// Создает модель из JSON
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      sku: json['sku'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      barcode: json['barcode'] as String,
      cellCode: json['cellCode'] as String,
      systemQuantity: json['systemQuantity'] as int,
      actualQuantity: json['actualQuantity'] as int?,
      status: InventoryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InventoryStatus.pending,
      ),
      discrepancyComment: json['discrepancyComment'] as String?,
    );
  }
  
  /// Преобразует модель в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'imageUrl': imageUrl,
      'barcode': barcode,
      'cellCode': cellCode,
      'systemQuantity': systemQuantity,
      'actualQuantity': actualQuantity,
      'status': status.name,
      'discrepancyComment': discrepancyComment,
    };
  }
}

/// Статус инвентаризации элемента
enum InventoryStatus {
  /// Ожидает инвентаризации
  pending,
  
  /// В процессе инвентаризации
  inProgress,
  
  /// Инвентаризация завершена
  completed,
  
  /// Расхождение (требуется подтверждение)
  discrepancy,
} 